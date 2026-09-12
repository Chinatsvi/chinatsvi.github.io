import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/books/book_model.dart';
import 'book_upload_screen.dart';
import 'cloudinary_book_reader_screen.dart';

class GuidebookScreen extends StatefulWidget {
  const GuidebookScreen({super.key});

  @override
  State<GuidebookScreen> createState() => _GuidebookScreenState();
}

class _GuidebookScreenState extends State<GuidebookScreen> {
  List<BookModel> books = [];
  bool isLoading = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _loadBooks();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(currentUserId)
          .get();
      final isAdmin = doc.exists && doc.data()?['role'] == 'admin';
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
        });
      }
      if (kDebugMode) {
        print('🔐 Admin status: $_isAdmin');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking admin status: $e');
      }
    }
  }

  void _loadBooks() async {
    if (kDebugMode) {
      print('🔄 _loadBooks called - Loading only Cloudinary books from Firestore');
    }

    setState(() {
      isLoading = true;
      books = [];
    });

    _loadFirestoreBooks();
  }

  void _loadFirestoreBooks() async {
    try {
      if (kDebugMode) {
        print('🔍 Querying Firestore collection: books');
      }
      final snapshot = await FirebaseFirestore.instance
          .collection('books')
          .where('isFree', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      if (kDebugMode) {
        print('🔍 Snapshot received: ${snapshot.docs.length} documents');
      }

      final List<BookModel> firestoreBooks = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        firestoreBooks.add(
          BookModel(
            id: doc.id,
            title: data['title'] ?? 'Untitled Book',
            author: data['author'] ?? 'Unknown Author',
            description: data['description'] ?? '',
            coverImage: data['coverImage'] ?? '',
            category: data['category'] ?? 'General',
            price: (data['price'] as num?)?.toDouble() ?? 0.0,
            isFree: data['isFree'] ?? true,
            previewPages: List<String>.from(data['previewPages'] ?? []),
            fullPages: List<String>.from(data['fullPages'] ?? []),
            isLocal: false,
          ),
        );
      }

      if (mounted) {
        setState(() {
          books = firestoreBooks;
          isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading Firestore books: $e');
      }
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _editBook(BookModel book) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookUploadScreen(book: book),
      ),
    );

    if (updated == true && mounted) {
      _loadBooks();
    }
  }

  void _showBookActions(BuildContext context, BookModel book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(book.title),
        content: const Text('Choose an action for this guidebook.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _editBook(book);
            },
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteBook(book);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print(
        '🔍 Build called - isLoading: $isLoading, books.length: ${books.length}',
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Farming Guidebooks'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : books.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.book, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No guidebooks available',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final BookModel book = books[index];

                    return BookCard(
                      book: book,
                      isAdmin: _isAdmin,
                      onTap: () {
                        if (book.fullPages.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CloudinaryBookReaderScreen(
                                fileUrl: book.fullPages.first,
                                title: book.title,
                              ),
                            ),
                          );
                        }
                      },
                      onLongPress: _isAdmin
                          ? () => _showBookActions(context, book)
                          : null,
                    );
                  },
                ),
    );
  }

  Future<void> _deleteBook(BookModel book) async {
    try {
      if (kDebugMode) {
        print('🗑️ Deleting book: ${book.id}');
      }
      await FirebaseFirestore.instance.collection('books').doc(book.id).delete();
      if (mounted) {
        setState(() {
          books.removeWhere((b) => b.id == book.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${book.title}" deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting book: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting book: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class BookCard extends StatelessWidget {
  final BookModel book;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const BookCard({
    super.key,
    required this.book,
    required this.isAdmin,
    required this.onTap,
    this.onLongPress,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onLongPress: isAdmin
            ? (onLongPress ?? () {
                if (onEdit == null && onDelete == null) return;
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(book.title),
                    content: const Text('Choose an action for this guidebook.'),
                    actions: [
                      if (onEdit != null)
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onEdit!();
                          },
                          child: const Text('Edit'),
                        ),
                      if (onDelete != null)
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onDelete!();
                          },
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Delete'),
                        ),
                    ],
                  ),
                );
              })
            : null,
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 90,
              height: 120,
              decoration: BoxDecoration(
                color: book.coverImage.isNotEmpty
                    ? Colors.blue.shade100
                    : Colors.grey.shade300,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: book.coverImage.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      child: Image.network(
                        book.coverImage,
                        width: 90,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.book,
                            size: 40,
                            color: Colors.grey.shade600,
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.book,
                      size: 40,
                      color: Colors.grey.shade600,
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By ${book.author}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      book.category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (book.description.trim().isNotEmpty) ...[
                      Text(
                        book.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade800,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      book.isFree ? 'FREE' : 'USD ${book.price}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: book.isFree ? Colors.green : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
