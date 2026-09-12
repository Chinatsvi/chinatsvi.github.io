import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_pdf_text/flutter_pdf_text.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../badge/verification_intro_screen.dart';
import '../badge/renewal_payment_screen.dart';
import 'dart:async';

class LocalBookReaderScreen extends StatefulWidget {
  final String assetPath;
  final String title;

  const LocalBookReaderScreen({
    super.key,
    required this.assetPath,
    required this.title,
  });

  @override
  State<LocalBookReaderScreen> createState() => _LocalBookReaderScreenState();
}

class _LocalBookReaderScreenState extends State<LocalBookReaderScreen> {
  List<String> pages = [];
  double fontSize = 10; // Smaller initial font size
  bool isLoading = true;
  bool isVerifiedFarmer = false;
  bool isCheckingVerification = true;
  int currentPageIndex = 0;
  bool shouldShowBanner = false;
  bool wasPreviouslyVerified = false; // Track if user had verification before
  Timer? _verificationCheckTimer;

  // Add caching
  static final Map<String, List<String>> _bookCache = {};

  @override
  void initState() {
    super.initState();
    _checkFarmerVerification();
    loadBook();
    _startVerificationStatusCheck();
  }

  @override
  void dispose() {
    _verificationCheckTimer?.cancel();
    super.dispose();
  }

  /// Periodically check verification status to update UI in real-time
  void _startVerificationStatusCheck() {
    _verificationCheckTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) async {
      if (mounted) {
        await _checkFarmerVerification(); // This will refresh verification status
      }
    });
  }

  void _onPageChanged(int pageIndex) async {
    if (kDebugMode) {
      print('📖 Page changed to: ${pageIndex + 1} (0-based: $pageIndex)');
      print('📖 Total pages viewed: ${pageIndex + 1}');
      print('📖 isVerifiedFarmer: $isVerifiedFarmer');
      print('📖 shouldShowBanner: $shouldShowBanner');
    }

    // Refresh verification status when user changes pages
    await _checkFarmerVerification();

    setState(() {
      currentPageIndex = pageIndex;

      // Show banner when farmer reaches page 3 (index 2)
      if (pageIndex >= 2 && !shouldShowBanner) {
        shouldShowBanner = true;
        if (kDebugMode) {
          print('🎯 Banner triggered: Farmer reached page ${pageIndex + 1}');
        }
      }
    });
  }

  Future<void> _checkFarmerVerification() async {
    final user = AuthService.currentUserStatic;
    if (user != null) {
      try {
        // Always fetch fresh data from Firestore to avoid stale cache issues
        final doc = await FirebaseFirestore.instance
            .collection('farmers')
            .doc(user.uid)
            .get();
        final userData = doc.data();

        if (kDebugMode) {
          print('🔍 User data: $userData');
          print('🔍 Available fields: ${userData?.keys.toList()}');
        }

        // Check if user was previously verified (has verification status but expired)
        final verificationStatus = userData?['verificationStatus'] as String?;
        final isPaid = userData?['verificationPaid'] as bool? ?? false;
        final verificationExpiresAt =
            userData?['verificationExpiresAt'] as Timestamp?;

        wasPreviouslyVerified =
            verificationStatus != null &&
            verificationStatus.isNotEmpty &&
            isPaid &&
            verificationExpiresAt != null &&
            DateTime.now().isAfter(verificationExpiresAt.toDate());

        // Use the same verification logic as AiService._calculateVerificationStatus
        isVerifiedFarmer = _calculateVerificationStatus(userData);

        if (kDebugMode) {
          print('🔍 Final isVerifiedFarmer: $isVerifiedFarmer');
          print('🔍 wasPreviouslyVerified: $wasPreviouslyVerified');
        }
      } catch (e) {
        print('Error checking verification: $e');
        isVerifiedFarmer = false;
        wasPreviouslyVerified = false;
      }
    }
    isCheckingVerification = false;
    if (mounted) {
      setState(() {});
    }
  }

  /// Calculate verification status based on user data (matches AiService logic)
  bool _calculateVerificationStatus(Map<String, dynamic>? userData) {
    if (userData == null) return false;

    final verificationStatus = userData['verificationStatus'] as String?;
    final isPaid = userData['verificationPaid'] as bool? ?? false;
    final verificationExpiresAt =
        userData['verificationExpiresAt'] as Timestamp?;

    // Check if verification has expired
    if (verificationExpiresAt != null) {
      final expiryDate = verificationExpiresAt.toDate();
      if (DateTime.now().isAfter(expiryDate)) {
        debugPrint('Verification expired on $expiryDate');
        return false; // Verification expired
      }
    }

    // User is verified only if they have active verification status AND it's paid AND not expired
    final isActive =
        verificationStatus != null &&
        verificationStatus.isNotEmpty &&
        isPaid &&
        (verificationExpiresAt == null ||
            DateTime.now().isBefore(verificationExpiresAt.toDate()));

    return isActive;
  }

  Future<void> loadBook() async {
    // Check cache first
    final cacheKey = widget.assetPath;
    if (_bookCache.containsKey(cacheKey)) {
      if (kDebugMode) {
        print('📚 Loading from cache: $cacheKey');
      }
      pages = _bookCache[cacheKey]!;
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (widget.assetPath.toLowerCase().endsWith('.pdf')) {
      await loadPdfBook(widget.assetPath);
    } else {
      await loadTxtBook(widget.assetPath);
    }

    // Cache the loaded pages
    _bookCache[cacheKey] = pages;

    // Check verification status after book loads
    await _checkFarmerVerification();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> loadTxtBook(String path) async {
    final rawText = await rootBundle.loadString(path);
    pages = _splitIntoPages(rawText);
  }

  List<String> _splitIntoPages(String text, {int maxCharsPerPage = 3000}) {
    return _fastSplitIntoPages(text, maxCharsPerPage: maxCharsPerPage);
  }

  Future<void> loadPdfBook(String path) async {
    try {
      print('🔄 Loading PDF from: $path');

      // Copy asset PDF to a temporary file (pdf_text requires a File)
      final bytes = await rootBundle.load(path);
      print('✅ PDF loaded from assets, size: ${bytes.lengthInBytes} bytes');

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${path.split('/').last}');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      print('✅ PDF copied to temp file: ${file.path}');

      // Load PDF and extract text
      PDFDoc doc = await PDFDoc.fromFile(file);
      final fullText = await doc.text;
      print('✅ PDF text extracted, length: ${fullText.length} characters');

      if (fullText.isEmpty) {
        print('⚠️ Warning: PDF text is empty');
        pages = [
          'No text could be extracted from this PDF. The PDF might be image-based or encrypted.',
        ];
      } else {
        // Use lighter processing for faster loading
        pages = _fastSplitIntoPages(fullText);
        print('✅ Text split into ${pages.length} pages');
        print(
          '📄 First 100 characters: ${fullText.substring(0, fullText.length > 100 ? 100 : fullText.length)}...',
        );
      }
    } catch (e) {
      print('❌ Error loading PDF: $e');
      pages = [
        'Error loading PDF: $e. Please check if the file exists and is readable.',
      ];
    }
  }

  List<String> _fastSplitIntoPages(
    String fullText, {
    int maxCharsPerPage = 3000,
  }) {
    final List<String> pages = [];

    print(
      '📖 Fast splitting text into pages (max ${maxCharsPerPage} chars per page)',
    );

    // Simple and fast text splitting
    String cleanedText = _fastCleanText(fullText);

    // Split by paragraphs first
    final paragraphs = cleanedText.split('\n\n');

    String currentPage = '';
    for (final paragraph in paragraphs) {
      if (currentPage.length + paragraph.length > maxCharsPerPage) {
        if (currentPage.isNotEmpty) {
          pages.add(currentPage.trim());
          currentPage = paragraph + '\n\n';
        } else {
          // Paragraph is too long, split it
          final words = paragraph.split(' ');
          String tempPage = '';
          for (final word in words) {
            if (tempPage.length + word.length > maxCharsPerPage) {
              if (tempPage.isNotEmpty) {
                pages.add(tempPage.trim());
                tempPage = word + ' ';
              }
            } else {
              tempPage += word + ' ';
            }
          }
          if (tempPage.isNotEmpty) {
            currentPage = tempPage;
          }
        }
      } else {
        currentPage += paragraph + '\n\n';
      }
    }

    if (currentPage.isNotEmpty) {
      pages.add(currentPage.trim());
    }

    print('✅ Total pages created: ${pages.length}');
    return pages;
  }

  String _fastCleanText(String text) {
    // Clean text while preserving paragraph structure
    return text
        .replaceAll(
          RegExp(r'[ \t]+'),
          ' ',
        ) // Multiple spaces/tabs to single space
        .replaceAll(RegExp(r'\n{3,}'), '\n\n') // Multiple newlines to double
        .replaceAll(RegExp(r'\f'), '\n\n') // Form feed to paragraph break
        .replaceAll(
          RegExp(r' +\n'),
          '\n',
        ) // Space before newline to just newline
        .replaceAll(
          RegExp(r'\n +'),
          '\n',
        ) // Newline before spaces to just newline
        .trim();
  }

  List<Widget> _buildParagraphs(String pageText) {
    final paragraphs = pageText.split('\n\n');
    List<Widget> widgets = [];

    print('🔍 Debug: Processing ${paragraphs.length} paragraphs');
    for (int i = 0; i < paragraphs.length; i++) {
      String paragraph = paragraphs[i].trim();
      print('🔍 Debug: Paragraph $i: "$paragraph"');

      if (paragraph.isEmpty) {
        widgets.add(const SizedBox(height: 12));
        continue;
      }

      // Check if this is a chapter or section heading
      final isChapter =
          RegExp(r'^Chapter\s+\d+', caseSensitive: false).hasMatch(paragraph) ||
          RegExp(
            r'^\d+\.\s*Chapter',
            caseSensitive: false,
          ).hasMatch(paragraph) ||
          RegExp(r'^CHAPTER\s+\d+', caseSensitive: false).hasMatch(paragraph) ||
          RegExp(
            r'^Chapter\s+\d+\s*:',
            caseSensitive: false,
          ).hasMatch(paragraph) ||
          RegExp(
            r'^\d+\.\d+\s+',
            caseSensitive: false,
          ).hasMatch(paragraph); // For "1.1", "2.3", etc.
      final isSection =
          RegExp(r'^Section\s+\d+', caseSensitive: false).hasMatch(paragraph) ||
          RegExp(
            r'^\d+\.\s*Section',
            caseSensitive: false,
          ).hasMatch(paragraph) ||
          RegExp(r'^SECTION\s+\d+', caseSensitive: false).hasMatch(paragraph);

      print('🔍 Debug: isChapter: $isChapter, isSection: $isSection');

      if (isChapter || isSection) {
        // Chapter/Section heading with normal text styling
        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 24, top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              paragraph,
              style: TextStyle(
                fontSize: fontSize,
                height: 1.8,
                letterSpacing: 0.4,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
                wordSpacing: 1.2,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        );
      } else {
        // Regular paragraph - improve formatting with more spacing
        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 32, left: 8, right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              paragraph,
              style: TextStyle(
                fontSize: fontSize,
                height: 1.8,
                letterSpacing: 0.4,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
                wordSpacing: 1.2,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        );
      }
    }

    return widgets;
  }

  void increaseFont() {
    setState(() {
      fontSize += 2;
    });
  }

  void decreaseFont() {
    setState(() {
      if (fontSize > 10) fontSize -= 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || isCheckingVerification) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} (${pages.length} pages)'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.text_increase),
            onPressed: increaseFont,
            tooltip: 'Increase font',
          ),
          IconButton(
            icon: const Icon(Icons.text_decrease),
            onPressed: decreaseFont,
            tooltip: 'Decrease font',
          ),
        ],
      ),
      body: Column(
        children: [
          // Book content
          Expanded(
            child: pages.isEmpty
                ? const Center(child: Text('No content available'))
                : NotificationListener<ScrollNotification>(
                    onNotification: (scrollNotification) {
                      if (scrollNotification is ScrollUpdateNotification) {
                        // Calculate visible page based on scroll position
                        final scrollPosition =
                            scrollNotification.metrics.pixels;

                        // Estimate which page is most visible
                        final estimatedPageHeight =
                            scrollNotification.metrics.maxScrollExtent /
                            (isVerifiedFarmer ? pages.length : pages.length);
                        final currentPage =
                            (scrollPosition / estimatedPageHeight).floor();

                        // Ensure page is within bounds
                        final validPage = currentPage.clamp(
                          0,
                          pages.length - 1,
                        );

                        if (kDebugMode) {
                          print(
                            '🔍 Scroll: pos=$scrollPosition, page=$validPage, current=$currentPageIndex',
                          );
                        }

                        // Trigger page change detection
                        if (validPage != currentPageIndex && validPage >= 0) {
                          _onPageChanged(validPage);
                        }
                      }
                      return false;
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: pages.length,
                      itemBuilder: (context, index) {
                        // Trigger banner when reaching page 3 (index 2)
                        if (index == 2 &&
                            !shouldShowBanner &&
                            !isVerifiedFarmer) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && !shouldShowBanner) {
                              setState(() {
                                shouldShowBanner = true;
                              });
                              if (kDebugMode) {
                                print(
                                  '🎯 Banner triggered: Farmer reached page 3',
                                );
                              }
                            }
                          });
                        }

                        // Block content for pages 4+ (index 3+) for unverified users
                        if (index >= 3 &&
                            !isVerifiedFarmer &&
                            shouldShowBanner) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock,
                                  color: Colors.orange.shade600,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Content Locked',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Get verified to access page ${index + 1} and beyond',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Page ${index + 1} of ${pages.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade100,
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _buildParagraphs(pages[index]),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),
                  ),
          ),

          // Gentle banner at bottom for unverified users (after 3 pages)
          if (!isVerifiedFarmer && shouldShowBanner)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: wasPreviouslyVerified
                    ? Colors.orange.shade50
                    : Colors.green.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                border: Border.all(
                  color: wasPreviouslyVerified
                      ? Colors.orange.shade200
                      : Colors.green.shade200,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        wasPreviouslyVerified
                            ? Icons.warning_amber
                            : Icons.favorite,
                        color: wasPreviouslyVerified
                            ? Colors.orange.shade600
                            : Colors.green.shade600,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          wasPreviouslyVerified
                              ? 'Your verification has expired!'
                              : 'Enjoying this guide?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: wasPreviouslyVerified
                                ? Colors.orange.shade800
                                : Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    wasPreviouslyVerified
                        ? 'Renew your verification to continue accessing premium farming guides and resources.'
                        : 'Get verified to access the complete guide and unlock more farming resources.',
                    style: TextStyle(
                      fontSize: 14,
                      color: wasPreviouslyVerified
                          ? Colors.orange.shade700
                          : Colors.green.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to appropriate screen based on verification history
                      if (wasPreviouslyVerified) {
                        // Navigate to renewal payment screen for expired users
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RenewalPaymentScreen(),
                          ),
                        );
                      } else {
                        // Navigate to verification intro screen for new users
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const VerificationIntroScreen(),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: wasPreviouslyVerified
                          ? Colors.orange.shade600
                          : Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      wasPreviouslyVerified ? 'Renew Now' : 'Get Full Access',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
