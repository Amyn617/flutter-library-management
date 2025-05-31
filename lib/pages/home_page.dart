// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/api_service.dart';
import 'detail_page.dart';
import 'favorites_page.dart'; // Import FavoritesPage

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  Future<List<Book>>? _booksFuture;

  @override
  void initState() {
    super.initState();
    // Perform an initial search to show some books when the app loads
    _searchController.text = 'flutter';
    _searchBooks();
  }

  void _searchBooks() {
    if (_searchController.text.trim().isEmpty) {
      setState(() {
        _booksFuture = null;
      });
      return;
    }
    setState(() {
      _booksFuture = _apiService.searchBooks(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Search'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoritesPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for books',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchBooks,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onSubmitted: (_) => _searchBooks(), // Search on pressing enter
            ),
          ),
          Expanded(
            child:
                _booksFuture == null
                    ? const Center(
                      child: Text('Enter a keyword to search for books'),
                    )
                    : FutureBuilder<List<Book>>(
                      future: _booksFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(child: Text('No books found.'));
                        } else {
                          return GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      2, // Display two cards per row
                                  childAspectRatio:
                                      0.7, // Adjust aspect ratio as needed
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                            padding: const EdgeInsets.all(10),
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              final book = snapshot.data![index];
                              return Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => DetailPage(book: book),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: Hero(
                                          tag:
                                              book.id, // Unique tag for Hero animation
                                          child: ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(10),
                                                ),
                                            child: Image.network(
                                              book.imageUrl,
                                              fit: BoxFit.cover,
                                              headers: const {
                                                'User-Agent':
                                                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                                              },
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                return Image.network(
                                                  'https://placehold.co/128x196/cccccc/333333?text=No+Image',
                                                  fit: BoxFit.cover,
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
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          book.title,
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8.0,
                                          left: 8.0,
                                          right: 8.0,
                                        ),
                                        child: Text(
                                          book.author,
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
