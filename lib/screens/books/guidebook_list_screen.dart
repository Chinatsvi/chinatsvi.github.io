import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/books/book_controller.dart';
import 'book_reader_screen.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BookController>().listenBooks();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BookController>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Farming Books'),
      ),
      body: controller.books.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: controller.books.length,
              itemBuilder: (context, index) {
                final book = controller.books[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.menu_book, color: Colors.green),
                    title: Text(book.title),
                    subtitle: Text('USD ${book.price}'),
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
            ),
    );
  }
}
