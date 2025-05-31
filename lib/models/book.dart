// lib/models/book.dart
class Book {
  final String id;
  final String title;
  final String author;
  final String imageUrl;
  final String description; // Added description
  final String isbn10;
  final String isbn13;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.description, // Added description
    this.isbn10 = '',
    this.isbn13 = '',
  });

  // Factory constructor to create a Book object from JSON (API response)
  factory Book.fromJson(Map<String, dynamic> json) {
    // Safely extract data, providing default empty strings if null
    final volumeInfo = json['volumeInfo'] ?? {};
    final imageLinks = volumeInfo['imageLinks'] ?? {};

    String imageUrl = '';

    // Priority order for image sources from Google Books API
    // Prefer higher resolution images
    if (imageLinks['extraLarge'] != null) {
      imageUrl = imageLinks['extraLarge'];
    } else if (imageLinks['large'] != null) {
      imageUrl = imageLinks['large'];
    } else if (imageLinks['medium'] != null) {
      imageUrl = imageLinks['medium'];
    } else if (imageLinks['small'] != null) {
      imageUrl = imageLinks['small'];
    } else if (imageLinks['thumbnail'] != null) {
      imageUrl = imageLinks['thumbnail'];
    } else if (imageLinks['smallThumbnail'] != null) {
      imageUrl = imageLinks['smallThumbnail'];
    }

    if (imageUrl.isNotEmpty) {
      // Convert HTTP to HTTPS for better compatibility
      imageUrl = imageUrl.replaceFirst('http://', 'https://');
      // Remove edge=curl parameter which can cause issues
      imageUrl = imageUrl.replaceAll(RegExp(r'&edge=curl'), '');
      // Attempt to set zoom=0 for potentially better quality if zoom parameter exists
      if (imageUrl.contains('zoom=')) {
        imageUrl = imageUrl.replaceAll(RegExp(r'zoom=\d+'), 'zoom=0');
      }
      // Remove source=gbs_api as it's not always needed and can sometimes be part of problematic URLs
      imageUrl = imageUrl.replaceAll(RegExp(r'&source=gbs_api'), '');
    }

    // Fallback to a reliable placeholder if no image or invalid format
    if (imageUrl.isEmpty ||
        imageUrl.toLowerCase().contains('.svg') ||
        imageUrl.contains('placehold.co')) {
      // Using a more descriptive placeholder service
      String titlePlaceholder = Uri.encodeComponent(
        (volumeInfo['title'] ?? 'Book').split(' ').take(2).join('+'),
      );
      imageUrl =
          'https://via.placeholder.com/300x450/6366F1/FFFFFF?text=$titlePlaceholder';
    }

    String isbn10 = '';
    String isbn13 = '';
    if (volumeInfo['industryIdentifiers'] != null) {
      for (var identifier in volumeInfo['industryIdentifiers']) {
        if (identifier['type'] == 'ISBN_10') {
          isbn10 = identifier['identifier'] ?? '';
        } else if (identifier['type'] == 'ISBN_13') {
          isbn13 = identifier['identifier'] ?? '';
        }
      }
    }

    return Book(
      id:
          json['id'] ??
          DateTime.now().millisecondsSinceEpoch
              .toString(), // Ensure ID is never empty
      title: volumeInfo['title'] ?? 'No Title',
      author: (volumeInfo['authors'] as List?)?.join(', ') ?? 'Unknown Author',
      imageUrl: imageUrl,
      description:
          volumeInfo['description'] ??
          'No description available.', // Added description
      isbn10: isbn10,
      isbn13: isbn13,
    );
  }

  // Convert a Book object into a Map object for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'imageUrl': imageUrl,
      'description': description, // Added description
      'isbn10': isbn10,
      'isbn13': isbn13,
    };
  }

  // Create a Book object from a Map object (database result)
  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] ?? '',
      title: map['title'] ?? 'No Title',
      author: map['author'] ?? 'Unknown Author',
      imageUrl:
          map['imageUrl'] ??
          'https://via.placeholder.com/300x450/E0E0E0/000000?text=No+Cover',
      description:
          map['description'] ??
          'No description available.', // Added description
      isbn10: map['isbn10'] ?? '',
      isbn13: map['isbn13'] ?? '',
    );
  }
}
