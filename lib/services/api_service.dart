import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';
import 'package:flutter/foundation.dart'; // Add this import

class ApiService {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';
  static final Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
  };

  Future<List<Book>> searchBooks(String query) async {
    final response = await http.get(
      Uri.parse('$_baseUrl?q=$query'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> items = data['items'] ?? [];
      return items.map((json) => Book.fromJson(json)).toList();
    } else {
      // Handle API errors
      debugPrint(
        'Failed to load books: ${response.statusCode}',
      ); // Changed from print
      throw Exception('Failed to load books');
    }
  }
}
