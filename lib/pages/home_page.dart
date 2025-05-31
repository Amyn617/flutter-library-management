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

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  Future<List<Book>>? _booksFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Perform an initial search to show some books when the app loads
    _searchController.text = 'flutter';
    _searchBooks();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Discover Books'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.favorite_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FavoritesPage(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF6366F1),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Find your next great read',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for books, authors, genres...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.grey[600],
                      ),
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.search_rounded,
                            color: Colors.white,
                          ),
                          onPressed: _searchBooks,
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    onSubmitted: (_) => _searchBooks(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _booksFuture == null
                    ? _buildEmptyState()
                    : FutureBuilder<List<Book>>(
                      future: _booksFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildLoadingState();
                        } else if (snapshot.hasError) {
                          return _buildErrorState(snapshot.error.toString());
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return _buildNoResultsState();
                        } else {
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildBookGrid(snapshot.data!),
                          );
                        }
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Start your book journey',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a keyword to discover amazing books',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF6366F1)),
          SizedBox(height: 16),
          Text('Searching for books...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Please try again later',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _searchBooks,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No books found', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildBookGrid(List<Book> books) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      padding: const EdgeInsets.all(20),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return _buildBookCard(book, index);
      },
    );
  }

  Widget _buildBookCard(Book book, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailPage(book: book),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Hero(
                        tag: book.id,
                        child: Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: _buildBookImage(book),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: Text(
                                book.author,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF6366F1),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookImage(Book book) {
    List<String> urlsToTry = [];

    // 1. Primary URL from book model
    if (book.imageUrl.isNotEmpty &&
        !book.imageUrl.contains(
          'via.placeholder.com',
        ) && // Avoid if it's already a generic fallback
        !book.imageUrl.contains('dummyimage.com') &&
        !book.imageUrl.contains('picsum.photos')) {
      urlsToTry.add(book.imageUrl);

      // Add Google Books variations if the primary URL is from Google
      if (book.imageUrl.contains('books.google.com/books/content')) {
        String baseGoogleUrl = book.imageUrl.split('?')[0];
        String queryParams =
            book.imageUrl.split('?').length > 1
                ? book.imageUrl.split('?')[1]
                : '';
        Map<String, String> params = Uri.splitQueryString(queryParams);
        String googleId = params['id'] ?? book.id;

        urlsToTry.add(
          '$baseGoogleUrl?id=$googleId&printsec=frontcover&img=1&zoom=0&source=gbs_api',
        );
        urlsToTry.add(
          '$baseGoogleUrl?id=$googleId&printsec=frontcover&img=1&zoom=5&source=gbs_api',
        );
        urlsToTry.add(
          '$baseGoogleUrl?id=$googleId&printsec=frontcover&img=1&zoom=2&source=gbs_api',
        );
      }
    }

    // 2. Open Library covers using ISBNs
    if (book.isbn13.isNotEmpty) {
      urlsToTry.add(
        'https://covers.openlibrary.org/b/isbn/${book.isbn13}-L.jpg',
      );
      urlsToTry.add(
        'https://covers.openlibrary.org/b/isbn/${book.isbn13}-M.jpg',
      );
    }
    if (book.isbn10.isNotEmpty) {
      urlsToTry.add(
        'https://covers.openlibrary.org/b/isbn/${book.isbn10}-L.jpg',
      );
      urlsToTry.add(
        'https://covers.openlibrary.org/b/isbn/${book.isbn10}-M.jpg',
      );
    }

    // 3. Generic placeholders as final fallbacks
    final bookIdHashed = book.id.hashCode.abs();
    String titleForPlaceholder =
        book.title.isNotEmpty && book.title != "No Title"
            ? book.title.split(' ').take(2).join('+')
            : "Book";
    titleForPlaceholder = Uri.encodeComponent(titleForPlaceholder);

    urlsToTry.add(
      'https://via.placeholder.com/300x450/A0A0C0/FFFFFF?text=$titleForPlaceholder',
    );
    urlsToTry.add(
      'https://dummyimage.com/300x450/a0a0c0/ffffff.png&text=$titleForPlaceholder',
    );
    urlsToTry.add('https://picsum.photos/seed/$bookIdHashed/300/450');

    // Remove duplicates and ensure all are valid URLs
    urlsToTry =
        urlsToTry
            .where((url) => Uri.tryParse(url)?.hasAbsolutePath ?? false)
            .toSet()
            .toList();

    if (urlsToTry.isEmpty) {
      urlsToTry.add(
        'https://via.placeholder.com/300x450/E0E0E0/000000?text=No+Image',
      );
    }

    return _ImageWithFallback(imageUrls: urlsToTry, bookTitle: book.title);
  }
}

class _ImageWithFallback extends StatefulWidget {
  final List<String> imageUrls;
  final String bookTitle;

  const _ImageWithFallback({required this.imageUrls, required this.bookTitle});

  @override
  State<_ImageWithFallback> createState() => _ImageWithFallbackState();
}

class _ImageWithFallbackState extends State<_ImageWithFallback> {
  int currentIndex = 0;
  bool _hasTriedAll = false;

  @override
  void initState() {
    super.initState();
    // Filter out empty or invalid URLs upfront
    widget.imageUrls.removeWhere(
      (url) =>
          url.isEmpty || (Uri.tryParse(url)?.hasAbsolutePath ?? false) == false,
    );
    if (widget.imageUrls.isEmpty) {
      _hasTriedAll = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasTriedAll || currentIndex >= widget.imageUrls.length) {
      return _buildPlaceholder();
    }

    return Image.network(
      widget.imageUrls[currentIndex],
      fit: BoxFit.cover,
      headers: const {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Accept':
            'image/webp,image/apng,image/jpeg,image/png,image/*,*/*;q=0.8',
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          decoration: const BoxDecoration(color: Color(0xFFF3F4F6)),
          child: Center(
            child: CircularProgressIndicator(
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
              strokeWidth: 2,
              color: const Color(0xFF6366F1),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint(
          'Image load failed (${currentIndex + 1}/${widget.imageUrls.length}): ${widget.imageUrls[currentIndex]} - Error: $error',
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            if (currentIndex < widget.imageUrls.length - 1) {
              setState(() {
                currentIndex++;
              });
            } else {
              setState(() {
                _hasTriedAll = true;
              });
            }
          }
        });

        if (currentIndex < widget.imageUrls.length - 1 && mounted) {
          // Show loading indicator while trying next URL
          return Container(
            decoration: const BoxDecoration(color: Color(0xFFF3F4F6)),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF6366F1),
              ),
            ),
          );
        }
        return _buildPlaceholder(); // Fallback to placeholder if last attempt or not mounted
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(
          0xFF6366F1,
        ).withAlpha((0.05 * 255).round()), // Softer background
        border: Border.all(
          color: const Color(0xFF6366F1).withAlpha((0.2 * 255).round()),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12), // Hardcoded padding
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(8), // Hardcoded border radius
            ),
            child: const Icon(
              Icons.auto_stories_rounded, // Changed icon
              color: Color(0xFF6366F1),
              size: 28, // Hardcoded size
            ),
          ),
          SizedBox(height: 6), // Hardcoded height
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              widget.bookTitle.isNotEmpty && widget.bookTitle != "No Title"
                  ? widget.bookTitle
                  : "Book Cover",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF6366F1).withAlpha((0.8 * 255).round()),
                fontSize: 10, // Hardcoded font size
                fontWeight: FontWeight.w500, // Slightly less bold
                height: 1.3,
              ),
              maxLines: 2, // Hardcoded max lines
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
