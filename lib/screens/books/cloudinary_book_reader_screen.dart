import 'package:flutter/material.dart';
import 'package:flutter_pdf_text/flutter_pdf_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../badge/verification_intro_screen.dart';
import '../badge/renewal_payment_screen.dart';
import '../../controllers/books/guidebook_unlock_controller.dart';
import 'dart:async';

class CloudinaryBookReaderScreen extends ConsumerWidget {
  final String fileUrl;
  final String title;

  const CloudinaryBookReaderScreen({
    super.key,
    required this.fileUrl,
    required this.title,
  });

  static String getGuidebookId(String fileUrl) {
    // Generate a consistent ID from the file URL
    return fileUrl.hashCode.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guidebookId = getGuidebookId(fileUrl);
    final unlockController = ref.watch(guidebookUnlockProvider(guidebookId));
    final unlockState = unlockController.state;
    
    return BookReaderContent(
      fileUrl: fileUrl,
      title: title,
      guidebookId: guidebookId,
      unlockState: unlockState,
      unlockController: unlockController,
    );
  }
}

class BookReaderContent extends ConsumerStatefulWidget {
  final String fileUrl;
  final String title;
  final String guidebookId;
  final GuidebookUnlockState unlockState;
  final GuidebookUnlockController unlockController;

  const BookReaderContent({
    super.key,
    required this.fileUrl,
    required this.title,
    required this.guidebookId,
    required this.unlockState,
    required this.unlockController,
  });

  @override
  ConsumerState<BookReaderContent> createState() => _BookReaderContentState();
}

class _BookReaderContentState extends ConsumerState<BookReaderContent> {
  List<String> pages = [];
  double fontSize = 10;
  bool isLoading = true;
  bool isVerifiedFarmer = false;
  bool isCheckingVerification = true;
  int currentPageIndex = 0;
  bool shouldShowBanner = false;
  bool wasPreviouslyVerified = false;
  Timer? _verificationCheckTimer;

  // Cache for book pages
  static final Map<String, List<String>> _bookCache = {};

  @override
  void initState() {
    super.initState();
    widget.unlockController.addListener(_onControllerChanged);
    _checkFarmerVerification();
    loadBook();
    _startVerificationStatusCheck();
  }

  @override
  void dispose() {
    widget.unlockController.removeListener(_onControllerChanged);
    _verificationCheckTimer?.cancel();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _startVerificationStatusCheck() {
    _verificationCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (mounted) {
        await _checkFarmerVerification();
      }
    });
  }

  void _onPageChanged(int pageIndex) async {
    if (kDebugMode) {
      print('📖 Page changed to: ${pageIndex + 1} (0-based: $pageIndex)');
      print('📖 isVerifiedFarmer: $isVerifiedFarmer');
      print('📖 shouldShowBanner: $shouldShowBanner');
    }

    await _checkFarmerVerification();

    setState(() {
      currentPageIndex = pageIndex;

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
        final doc = await FirebaseFirestore.instance
            .collection('farmers')
            .doc(user.uid)
            .get();
        final userData = doc.data();

        final verificationStatus = userData?['verificationStatus'] as String?;
        final isPaid = userData?['verificationPaid'] as bool? ?? false;
        final verificationExpiresAt = userData?['verificationExpiresAt'] as Timestamp?;

        wasPreviouslyVerified =
            verificationStatus != null &&
            verificationStatus.isNotEmpty &&
            isPaid &&
            verificationExpiresAt != null &&
            DateTime.now().isAfter(verificationExpiresAt.toDate());

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

  bool _calculateVerificationStatus(Map<String, dynamic>? userData) {
    if (userData == null) return false;

    final verificationStatus = userData['verificationStatus'] as String?;
    final isPaid = userData['verificationPaid'] as bool? ?? false;
    final verificationExpiresAt = userData['verificationExpiresAt'] as Timestamp?;

    if (verificationExpiresAt != null) {
      final expiryDate = verificationExpiresAt.toDate();
      if (DateTime.now().isAfter(expiryDate)) {
        debugPrint('Verification expired on $expiryDate');
        return false;
      }
    }

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
    final cacheKey = widget.fileUrl;
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

    try {
      final lower = widget.fileUrl.toLowerCase();

      if (lower.endsWith('.pdf')) {
        print('🔄 Loading PDF from Cloudinary: ${widget.fileUrl}');

        // Generate a hash for the URL to use as filename
        final urlHash = widget.fileUrl.hashCode.toString();
        final dir = await getApplicationDocumentsDirectory();
        final cachedFile = File('${dir.path}/book_$urlHash.pdf');

        // Check if PDF is already cached locally
        if (await cachedFile.exists()) {
          print('✅ Using cached PDF file: ${cachedFile.path}');
        } else {
          // Download PDF from Cloudinary
          print('📥 Downloading PDF from Cloudinary...');
          final response = await http.get(Uri.parse(widget.fileUrl));
          if (response.statusCode != 200) {
            throw Exception('Failed to download PDF: ${response.statusCode}');
          }

          final bytes = response.bodyBytes;
          print('✅ PDF downloaded, size: ${bytes.length} bytes');

          // Save to local cache
          await cachedFile.writeAsBytes(bytes);
          print('✅ PDF cached locally: ${cachedFile.path}');
        }

        // Load PDF and extract text
        PDFDoc doc = await PDFDoc.fromFile(cachedFile);
        final fullText = await doc.text;
        print('✅ PDF text extracted, length: ${fullText.length} characters');

        if (fullText.isEmpty) {
          print('⚠️ Warning: PDF text is empty');
          pages = [
            'No text could be extracted from this PDF. The PDF might be image-based or encrypted.',
          ];
        } else {
          pages = _fastSplitIntoPages(fullText);
          print('✅ Text split into ${pages.length} pages');
        }
      } else if (lower.endsWith('.txt')) {
        print('🔄 Loading TXT from Cloudinary: ${widget.fileUrl}');

        final response = await http.get(Uri.parse(widget.fileUrl));
        if (response.statusCode != 200) {
          throw Exception('Failed to download TXT: ${response.statusCode}');
        }

        final fullText = utf8.decode(response.bodyBytes);
        print('✅ TXT decoded with UTF-8 encoding, size: ${fullText.length} characters');
        if (fullText.isEmpty) {
          pages = ['No text content found in this document.'];
        } else {
          pages = _fastSplitIntoPages(fullText);
        }
      } else if (lower.endsWith('.doc') || lower.endsWith('.docx')) {
        // DOC/DOCX are not supported for in-app rendering. Ask admin to re-upload as .docx converted to TXT or PDF.
        pages = ['This document format is not supported for in-app reading. Please request the admin to upload as PDF or TXT.'];
      } else {
        // Fallback: try to download and treat as text
        print('🔄 Loading unknown file type from Cloudinary: ${widget.fileUrl}');
        final response = await http.get(Uri.parse(widget.fileUrl));
        if (response.statusCode != 200) {
          throw Exception('Failed to download file: ${response.statusCode}');
        }
        final bodyText = utf8.decode(response.bodyBytes);
        print('✅ Unknown format decoded with UTF-8 encoding, size: ${bodyText.length} characters');
        pages = _fastSplitIntoPages(bodyText);
      }

      // Cache the pages
      _bookCache[cacheKey] = pages;
    } catch (e) {
      print('❌ Error loading PDF: $e');
      pages = [
        'Error loading PDF: $e. Please check your internet connection and try again.',
      ];
    }

    await _checkFarmerVerification();

    setState(() {
      isLoading = false;
    });
  }

  List<String> _fastSplitIntoPages(String fullText, {int maxCharsPerPage = 3000}) {
    final List<String> pages = [];
    String cleanedText = _fastCleanText(fullText);
    final paragraphs = cleanedText.split('\n\n');

    String currentPage = '';
    for (final paragraph in paragraphs) {
      if (currentPage.length + paragraph.length > maxCharsPerPage) {
        if (currentPage.isNotEmpty) {
          pages.add(currentPage.trim());
          currentPage = paragraph + '\n\n';
        } else {
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

    return pages;
  }

  String _fastCleanText(String text) {
    return text
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .replaceAll(RegExp(r'\f'), '\n\n')
        .replaceAll(RegExp(r' +\n'), '\n')
        .replaceAll(RegExp(r'\n +'), '\n')
        .trim();
  }

  List<Widget> _buildParagraphs(String pageText) {
    final paragraphs = pageText.split('\n\n');
    List<Widget> widgets = [];

    for (int i = 0; i < paragraphs.length; i++) {
      String paragraph = paragraphs[i].trim();

      if (paragraph.isEmpty) {
        widgets.add(const SizedBox(height: 12));
        continue;
      }

      final isChapter =
          RegExp(r'^Chapter\s+\d+', caseSensitive: false).hasMatch(paragraph) ||
          RegExp(r'^\d+\.\s*Chapter', caseSensitive: false).hasMatch(paragraph) ||
          RegExp(r'^CHAPTER\s+\d+', caseSensitive: false).hasMatch(paragraph) ||
          RegExp(r'^Chapter\s+\d+\s*:', caseSensitive: false).hasMatch(paragraph) ||
          RegExp(r'^\d+\.\d+\s+', caseSensitive: false).hasMatch(paragraph);
      final isSection =
          RegExp(r'^Section\s+\d+', caseSensitive: false).hasMatch(paragraph) ||
          RegExp(r'^\d+\.\s*Section', caseSensitive: false).hasMatch(paragraph) ||
          RegExp(r'^SECTION\s+\d+', caseSensitive: false).hasMatch(paragraph);

      if (isChapter || isSection) {
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

  bool get hasFullAccess => isVerifiedFarmer || widget.unlockController.state.isUnlocked;

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
          Expanded(
            child: pages.isEmpty
                ? const Center(child: Text('No content available'))
                : NotificationListener<ScrollNotification>(
                    onNotification: (scrollNotification) {
                      if (scrollNotification is ScrollUpdateNotification) {
                        final scrollPosition = scrollNotification.metrics.pixels;
                        final estimatedPageHeight =
                            scrollNotification.metrics.maxScrollExtent / pages.length;
                        final currentPage = (scrollPosition / estimatedPageHeight).floor();
                        final validPage = currentPage.clamp(0, pages.length - 1);

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
                        if (index == 2 && !shouldShowBanner && !hasFullAccess) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && !shouldShowBanner) {
                              setState(() {
                                shouldShowBanner = true;
                              });
                            }
                          });
                        }

                        if (index >= 3 && !hasFullAccess && shouldShowBanner) {
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
                                Icon(Icons.lock, color: Colors.orange.shade600, size: 48),
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
                                  'Get verified or watch ads to access page ${index + 1} and beyond',
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          if (!hasFullAccess && shouldShowBanner)
            _buildUnlockBanner(context),
        ],
      ),
    );
  }

  Widget _buildUnlockBanner(BuildContext context) {
    if (widget.unlockController.state.isUnlocked) {
      final h = widget.unlockController.state.timeRemaining!.inHours;
      final m = widget.unlockController.state.timeRemaining!.inMinutes % 60;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ad Unlocked for ${h}h ${m}m',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Get verified for permanent access to all farming guides',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VerificationIntroScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Get Permanent Access'),
            ),
          ],
        ),
      );
    }

    final remaining = 2 - widget.unlockController.state.adsWatched;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: wasPreviouslyVerified ? Colors.orange.shade50 : Colors.green.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        border: Border.all(
          color: wasPreviouslyVerified ? Colors.orange.shade200 : Colors.green.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                wasPreviouslyVerified ? Icons.warning_amber : Icons.favorite,
                color: wasPreviouslyVerified ? Colors.orange.shade600 : Colors.green.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  wasPreviouslyVerified
                      ? 'Your verification has expired!'
                      : 'Continue reading this guide?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: wasPreviouslyVerified ? Colors.orange.shade800 : Colors.green.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            wasPreviouslyVerified
                ? 'Renew your verification or watch ads to continue accessing premium farming guides.'
                : 'Get verified for permanent access or unlock for 24 hours by watching ads.',
            style: TextStyle(
              fontSize: 14,
              color: wasPreviouslyVerified ? Colors.orange.shade700 : Colors.green.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (wasPreviouslyVerified) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RenewalPaymentScreen()),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const VerificationIntroScreen()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: wasPreviouslyVerified ? Colors.orange.shade600 : Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(wasPreviouslyVerified ? 'Renew Now' : 'Get Verified'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.unlockController.watchAdToUnlock(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                    side: BorderSide(color: Colors.blue.shade300),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.play_circle_outline, size: 20),
                      const SizedBox(height: 4),
                      Text('Watch Ad ${widget.unlockController.state.adsWatched + 1}/2'),
                      const SizedBox(height: 2),
                      Text(
                        'Unlock 24h',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
