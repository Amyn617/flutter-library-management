// lib/services/db_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/book.dart';

class DbService {
  static Database? _database;
  static const String _tableName = 'favorites';
  static const String _prefsKey = 'favorite_books';

  // Check if we're running on web
  bool get isWeb => kIsWeb;

  Future<Database> get database async {
    if (isWeb) {
      throw UnsupportedError(
        'SQLite not supported on web, use SharedPreferences methods',
      );
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'book_favorites.db');

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $_tableName(
              id TEXT PRIMARY KEY,
              title TEXT,
              author TEXT,
              imageUrl TEXT,
              description TEXT // Added description column
            )
          ''');
        },
      ),
    );
  }

  Future<void> insertItem(Book item) async {
    if (isWeb) {
      await _insertItemWeb(item);
    } else {
      final db = await database;
      await db.insert(
        _tableName,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // Add alias method for compatibility
  Future<void> addItem(Book item) async {
    await insertItem(item);
  }

  Future<List<Book>> getItems() async {
    if (isWeb) {
      return await _getItemsWeb();
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName);
      return List.generate(maps.length, (i) {
        return Book.fromMap(maps[i]);
      });
    }
  }

  Future<void> deleteItem(String id) async {
    if (isWeb) {
      await _deleteItemWeb(id);
    } else {
      final db = await database;
      await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<bool> isItemFavorite(String id) async {
    // Renamed from isFavorite
    if (isWeb) {
      return await _isFavoriteWeb(id);
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      return maps.isNotEmpty;
    }
  }

  // Web-specific methods using SharedPreferences
  Future<void> _insertItemWeb(Book item) async {
    final prefs = await SharedPreferences.getInstance();
    final books = await _getItemsWeb();

    // Remove existing book with same ID if exists
    books.removeWhere((book) => book.id == item.id);

    // Add the new/updated book
    books.add(item);

    // Convert to JSON and save
    final booksJson = books.map((book) => book.toMap()).toList();
    await prefs.setString(_prefsKey, json.encode(booksJson));
  }

  Future<List<Book>> _getItemsWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final booksJson = prefs.getString(_prefsKey);

    if (booksJson == null) return [];

    final List<dynamic> decoded = json.decode(booksJson);
    return decoded.map((item) => Book.fromMap(item)).toList();
  }

  Future<void> _deleteItemWeb(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final books = await _getItemsWeb();

    books.removeWhere((book) => book.id == id);

    final booksJson = books.map((book) => book.toMap()).toList();
    await prefs.setString(_prefsKey, json.encode(booksJson));
  }

  Future<bool> _isFavoriteWeb(String id) async {
    final books = await _getItemsWeb();
    return books.any((book) => book.id == id);
  }
}
