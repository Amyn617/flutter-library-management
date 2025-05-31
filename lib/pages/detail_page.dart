import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/db_service.dart';

class DetailPage extends StatefulWidget {
  final Book book;
  const DetailPage({super.key, required this.book});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> with TickerProviderStateMixin {
  bool _isFavorited = false;
  late AnimationController _heartAnimationController;
  late Animation<double> _heartScaleAnimation;
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heartScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _heartAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _checkIfFavorited();
    _fadeAnimationController.forward();
  }

  @override
  void dispose() {
    _heartAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
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
    _heartAnimationController.forward().then((_) {
      _heartAnimationController.reverse();
    });

    if (_isFavorited) {
      await DbService().deleteItem(widget.book.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Removed from favorites'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } else {
      await DbService().insertItem(widget.book);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Added to favorites'),
            backgroundColor: const Color(0xFF6366F1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildBookDetails(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: const Color(0xFF6366F1),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: AnimatedBuilder(
            animation: _heartScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _heartScaleAnimation.value,
                child: IconButton(
                  icon: Icon(
                    _isFavorited
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: _isFavorited ? Colors.red : Colors.white,
                  ),
                  onPressed: _toggleFavorite,
                ),
              );
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Hero(
              tag: widget.book.id,
              child: Container(
                margin: const EdgeInsets.only(top: 60),
                height: 280,
                width: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _buildBookImage(widget.book),
                ),
              ),
            ),
          ),
        ),
      ),
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

    // For detail page, request larger placeholder images
    urlsToTry.add(
      'https://via.placeholder.com/400x600/A0A0C0/FFFFFF?text=$titleForPlaceholder',
    );
    urlsToTry.add(
      'https://dummyimage.com/400x600/a0a0c0/ffffff.png&text=$titleForPlaceholder',
    );
    urlsToTry.add('https://picsum.photos/seed/$bookIdHashed/400/600');

    urlsToTry =
        urlsToTry
            .where((url) => Uri.tryParse(url)?.hasAbsolutePath ?? false)
            .toSet()
            .toList();

    if (urlsToTry.isEmpty) {
      urlsToTry.add(
        'https://via.placeholder.com/400x600/E0E0E0/000000?text=No+Image',
      );
    }

    return _ImageWithFallback(
      imageUrls: urlsToTry,
      bookTitle: book.title,
      isDetailPage: true,
    );
  }

  Widget _buildBookDetails() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.book.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'By ${widget.book.author}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF6366F1),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Icon(
                  Icons.description_rounded,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              ),
              child: Text(
                widget.book.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  color: const Color(0xFF4B5563),
                ),
                textAlign: TextAlign.justify,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _toggleFavorite,
                icon: Icon(
                  _isFavorited
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                ),
                label: Text(
                  _isFavorited ? 'Remove from Favorites' : 'Add to Favorites',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isFavorited ? Colors.red : const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ImageWithFallback extends StatefulWidget {
  final List<String> imageUrls;
  final String bookTitle;
  final bool isDetailPage;

  const _ImageWithFallback({
    required this.imageUrls,
    required this.bookTitle,
    this.isDetailPage = false,
  });

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
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius:
                widget.isDetailPage ? BorderRadius.circular(16) : null,
          ),
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
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius:
                  widget.isDetailPage ? BorderRadius.circular(16) : null,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF6366F1),
              ),
            ),
          );
        }
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(
          0xFF6366F1,
        ).withAlpha((0.05 * 255).round()), // Softer background
        borderRadius: widget.isDetailPage ? BorderRadius.circular(16) : null,
        border: Border.all(
          color: const Color(0xFF6366F1).withAlpha((0.2 * 255).round()),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(widget.isDetailPage ? 20 : 12),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(widget.isDetailPage ? 12 : 8),
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              color: const Color(0xFF6366F1),
              size: widget.isDetailPage ? 48 : 28,
            ),
          ),
          SizedBox(height: widget.isDetailPage ? 12 : 6),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
            ), // Reduced horizontal padding for placeholder text
            child: Text(
              widget.bookTitle.isNotEmpty && widget.bookTitle != "No Title"
                  ? widget.bookTitle
                  : "Book Cover",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF6366F1).withAlpha((0.8 * 255).round()),
                fontSize: widget.isDetailPage ? 14 : 10,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
              maxLines: widget.isDetailPage ? 3 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
