// lib/models/book.dart
class Book {
  final String id;
  final String title;
  final String author;
  final String imageUrl;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.imageUrl,
  });

  // Factory constructor to create a Book object from JSON (API response)
  factory Book.fromJson(Map<String, dynamic> json) {
    // Safely extract data, providing default empty strings if null
    final volumeInfo = json['volumeInfo'] ?? {};
    final imageLinks = volumeInfo['imageLinks'] ?? {};

    return Book(
      id: json['id'] ?? '',
      title: volumeInfo['title'] ?? 'No Title',
      author: (volumeInfo['authors'] as List?)?.join(', ') ?? 'Unknown Author',
      imageUrl: imageLinks['thumbnail'] ?? 'https://placehold.co/128x196/cccccc/333333?text=No+Image', // Placeholder if no image
    );
  }

  // Convert a Book object to a Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'imageUrl': imageUrl,
    };
  }

  // Factory constructor to create a Book object from a Map (SQLite retrieval)
  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'],
      title: map['title'],
      author: map['author'],
      imageUrl: map['imageUrl'],
    );
  }
}
