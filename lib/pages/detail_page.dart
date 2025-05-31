import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/db_service.dart';

class DetailPage extends StatefulWidget {
  final Book book;
  const DetailPage({super.key, required this.book});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorited();
  }

  Future<void> _checkIfFavorited() async {
    final isFavorited = await DbService().isItemFavorite(widget.book.id);
    if (mounted) {
      setState(() {
        _isFavorited = isFavorited;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorited) {
      await DbService().deleteItem(widget.book.id);
    } else {
      await DbService().insertItem(widget.book);
    }
    if (mounted) {
      setState(() {
        _isFavorited = !_isFavorited;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorited ? Icons.favorite : Icons.favorite_border,
              color: _isFavorited ? Colors.red : null,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Hero(
                tag: widget.book.id, // Same unique tag as in HomePage
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      widget.book.imageUrl,
                      fit: BoxFit.contain,
                      height: 300, // Adjust height as needed
                      headers: const {
                        'User-Agent':
                            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Image.network(
                          'https://placehold.co/200x300/cccccc/333333?text=No+Image',
                          fit: BoxFit.contain,
                          height: 300,
                          headers: const {
                            'User-Agent':
                                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.book.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'By ${widget.book.author}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Text(
              widget.book.description,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.justify,
            ),
            // Add more details as needed, e.g., publisher, publishedDate
          ],
        ),
      ),
    );
  }
}
