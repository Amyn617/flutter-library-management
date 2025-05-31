import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/db_service.dart';
import 'detail_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with TickerProviderStateMixin {
  late Future<List<Book>> _favoriteBooks;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadFavorites();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadFavorites() {
    setState(() {
      _favoriteBooks = DbService().getItems();
    });
    _animationController.forward(from: 0.0);
  }

  void _removeFavorite(String bookId) async {
    await DbService().deleteItem(bookId);
    _loadFavorites();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Book removed from favorites'),
        backgroundColor: const Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Favorites'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Book>>(
        future: _favoriteBooks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          } else if (snapshot.hasError) {
            return _buildErrorState();
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          } else {
            return _buildFavoritesList(snapshot.data!);
          }
        },
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
          Text('Loading your favorites...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Unable to load favorites',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Please try again later',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadFavorites,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              size: 64,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No favorites yet',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Start adding books to your favorites\nto see them here',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.search_rounded),
            label: const Text('Discover Books'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(List<Book> books) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: Color(0xFF6366F1),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '${books.length} ${books.length == 1 ? 'book' : 'books'} saved',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF6366F1),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.6,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return _buildFavoriteCard(book, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteCard(Book book, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailPage(book: book),
                          ),
                        );
                      },
                      child: Hero(
                        tag: book.id,
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
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _showRemoveDialog(book),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 16,
                                color: Colors.red,
                              ),
                              label: const Text(
                                'Remove',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Colors.red,
                                  width: 1,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
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
        );
      },
    );
  }

  Widget _buildBookImage(Book book) {
    List<String> urlsToTry = [];

    // 1. Primary URL from book model
    if (book.imageUrl.isNotEmpty &&
        !book.imageUrl.contains('via.placeholder.com') &&
        !book.imageUrl.contains('dummyimage.com') &&
        !book.imageUrl.contains('picsum.photos')) {
      urlsToTry.add(book.imageUrl);

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

    // 3. Generic placeholders
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

  void _showRemoveDialog(Book book) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Remove from Favorites'),
          content: Text(
            'Are you sure you want to remove "${book.title}" from your favorites?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeFavorite(book.id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
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
          const SizedBox(height: 6), // Hardcoded height
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
