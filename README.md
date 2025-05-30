### Diagramme de classe du projet:

```mermaid
classDiagram
    class Book {
        +String id
        +String title
        +String author
        +String imageUrl
        +Book.fromJson(Map<String, dynamic> json)
        +Map<String, dynamic> toMap()
        +Book.fromMap(Map<String, dynamic> map)
    }

    class ApiService {
        +Future<List<Book>> searchBooks(String query)
    }

    class DbService {
        +Future<void> insertItem(Book item)
        +Future<List<Book>> getItems()
        +Future<void> deleteItem(String id)
        +Future<bool> isFavorite(String id)
    }

    class HomePage {
        -ApiService apiService
        +void searchBooks(String query)
        +void navigateToDetail(Book book)
    }

    class DetailPage {
        -DbService dbService
        +void toggleFavorite(Book book)
    }

    class FavoritesPage {
        -DbService dbService
        +void loadFavorites()
        +void deleteFavorite(String id)
    }

    HomePage --> ApiService : uses
    DetailPage --> DbService : uses
    FavoritesPage --> DbService : uses
    ApiService ..> Book : returns list of
    DbService ..> Book : stores/retrieves