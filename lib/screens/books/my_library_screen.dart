import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/books/book_controller.dart';
import '../../../services/books/purchase_service.dart';
import 'book_reader_screen.dart';

class MyLibraryScreen extends StatelessWidget {
  const MyLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BookController>();
    final purchaseService = PurchaseService();

    final userId = controller.currentUserId;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view your library')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('My Library'),
      ),
      body: StreamBuilder<List<String>>(
        stream: purchaseService.purchasedBookIds(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final purchasedIds = snapshot.data!;

          // Include free books automatically
          final libraryBooks = controller.books.where((book) {
            return book.isFree || purchasedIds.contains(book.id);
          }).toList();

          if (libraryBooks.isEmpty) {
            return const Center(child: Text('No books in your library yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: libraryBooks.length,
            itemBuilder: (context, index) {
              final book = libraryBooks[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: book.coverImage.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            book.coverImage,
                            width: 45,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.menu_book, color: Colors.green),
                  title: Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookReaderScreen(book: book),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
