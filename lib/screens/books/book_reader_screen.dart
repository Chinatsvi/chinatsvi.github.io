import 'package:flutter/material.dart';
import '../../../models/books/book_model.dart';
import 'package:agribased/app/utils/formatters.dart';

class BookReaderScreen extends StatefulWidget {
  final BookModel book;

  const BookReaderScreen({super.key, required this.book});

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  double fontSize = 16;
  int currentChapter = 0;

  @override
  Widget build(BuildContext context) {
    final pages = widget.book.fullPages.isNotEmpty
        ? widget.book.fullPages
        : widget.book.description.split('\n\n');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.text_increase),
            onPressed: () {
              setState(() {
                fontSize += 2;
              });
            },
            tooltip: 'Increase font',
          ),
          IconButton(
            icon: const Icon(Icons.text_decrease),
            onPressed: () {
              setState(() {
                if (fontSize > 10) fontSize -= 2;
              });
            },
            tooltip: 'Decrease font',
          ),
          IconButton(
            icon: const Icon(Icons.book),
            onPressed: () {
              setState(() {
                currentChapter = -1; // -1 means show full book
              });
            },
            tooltip: currentChapter == -1 ? 'Show Chapters' : 'Read Full Book',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'By ${widget.book.author}',
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Category: ${widget.book.category}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            if (pages.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Table of Contents',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(pages.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            currentChapter = index;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: currentChapter == index
                                ? Colors.green.shade100
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chapter ${index + 1}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: currentChapter == index
                                      ? Colors.green
                                      : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                pages[index],
                                style: TextStyle(
                                  fontSize: fontSize,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              )
            else
              Text(
                widget.book.description.isNotEmpty
                    ? widget.book.description
                    : 'This is a comprehensive guide about ${widget.book.title}. Learn the best practices for planting, growing, and harvesting ${widget.book.title.toLowerCase()}.',
                style: TextStyle(fontSize: fontSize, height: 1.5),
              ),
            const SizedBox(height: 16),
            if (!widget.book.isFree)
              Text(
                'Price: ${Formatter.formatCurrency(widget.book.price.toDouble())}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              )
            else
              Text(
                'FREE',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
