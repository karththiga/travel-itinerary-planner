import '../../auth/data/auth_repository.dart';

class BookmarkRepository {
  const BookmarkRepository(this._auth);

  final AuthRepository _auth;

  Future<Set<String>> load() async {
    final result = await _auth.accountRequest('GET', '/bookmarks');
    final bookmarks = result['bookmarks'];
    if (bookmarks is! List) {
      throw const AuthException('Could not load your saved destinations.');
    }
    return bookmarks.whereType<String>().toSet();
  }

  Future<void> setSaved(String key, bool saved) async {
    await _auth.accountRequest(
      'PUT',
      '/bookmarks',
      body: {'key': key, 'saved': saved},
    );
  }
}
