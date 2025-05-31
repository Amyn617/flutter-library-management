// lib/models/book.dart
class Book {
  final String id;
  final String title;
  final String author;
  final String imageUrl;
  final String description; // Added description

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.description, // Added description
  });

  // Factory constructor to create a Book object from JSON (API response)
  factory Book.fromJson(Map<String, dynamic> json) {
    // Safely extract data, providing default empty strings if null
    final volumeInfo = json['volumeInfo'] ?? {};
    final imageLinks = volumeInfo['imageLinks'] ?? {};
    final industryIdentifiers =
        volumeInfo['industryIdentifiers'] as List<dynamic>?;

    String? bookISBN;
    if (industryIdentifiers != null) {
      for (var identifier in industryIdentifiers) {
        if (identifier['type'] == 'ISBN_13' ||
            identifier['type'] == 'ISBN_10') {
          bookISBN = identifier['identifier'];
          break;
        }
      }
    }

    String imageUrl;
    // Prioritize Open Library image if ISBN is available
    if (bookISBN != null && bookISBN.isNotEmpty) {
      imageUrl = 'https://covers.openlibrary.org/b/isbn/$bookISBN-M.jpg';
    } else {
      // Fallback to Google Books thumbnail
      imageUrl =
          imageLinks['thumbnail'] ??
          'https://placehold.co/128x196/cccccc/333333?text=No+Image';
    }

    // Check if the image URL might be an SVG, which Image.network cannot handle directly.
    // If it's an SVG, force the placeholder image to prevent ImageCodecException.
    if (imageUrl.toLowerCase().contains('.svg')) {
      imageUrl = 'https://placehold.co/128x196/cccccc/333333?text=No+Image';
    }

    return Book(
      id: json['id'] ?? '',
      title: volumeInfo['title'] ?? 'No Title',
      author: (volumeInfo['authors'] as List?)?.join(', ') ?? 'Unknown Author',
      imageUrl: imageUrl,
      description:
          volumeInfo['description'] ??
          'No description available.', // Added description
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
          'https://placehold.co/128x196/cccccc/333333?text=No+Image',
      description:
          map['description'] ??
          'No description available.', // Added description
    );
  }
}
