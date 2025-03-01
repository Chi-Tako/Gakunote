// lib/features/notes/presentation/pages/notes_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/note.dart';
import '../../../../core/services/note_service.dart';
import '../../../../core/services/auth_service.dart';
import '../widgets/note_card.dart';
import '../../../shared/widgets/app_drawer.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({Key? key}) : super(key: key);

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  // 検索クエリ
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    
    // NoteServiceに自動的にロードするようにProviderで設定したので、
    // ここでの明示的なロード処理は不要になりました
  }

  @override
  Widget build(BuildContext context) {
    final noteService = Provider.of<NoteService>(context);
    final authService = Provider.of<AuthService>(context);
    
    // サービスから取得したノート一覧
    final notes = noteService.notes;
    
    // フィルタリングされたノートのリスト
    List<Note> filteredNotes = _searchQuery.isEmpty
        ? notes
        : notes.where((note) {
            final titleMatches = note.title.toLowerCase().contains(_searchQuery.toLowerCase());
            final tagMatches = note.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
            return titleMatches || tagMatches;
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gakunote'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: NoteSearchDelegate(notes),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              _showSortOptions(context);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'settings',
                child: Text('設定'),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('ログアウト'),
              ),
            ],
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: noteService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildNotesList(filteredNotes),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _createNewNote(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNotesList(List<Note> notes) {
    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'ノートがありません',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _createNewNote(context),
              child: const Text('ノートを作成'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return NoteCard(
          note: note,
          onTap: () {
            // ノート詳細画面に遷移
            context.go('/notes/${note.id}');
          },
          onFavoriteToggle: () {
            // お気に入り状態を切り替え
            final noteService = Provider.of<NoteService>(context, listen: false);
            noteService.toggleFavorite(note.id);
          },
        );
      },
    );
  }

  void _showSortOptions(BuildContext context) {
    final noteService = Provider.of<NoteService>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '並び替え',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('最終更新日'),
              onTap: () {
                setState(() {
                  // 最新順に並び替え（NoteServiceで既に実装されているはず）
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.title),
              title: const Text('タイトル'),
              onTap: () {
                setState(() {
                  // タイトル順に並び替え（こちらはローカルでのみ行う）
                  noteService.notes.sort((a, b) => a.title.compareTo(b.title));
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('お気に入り'),
              onTap: () {
                setState(() {
                  // お気に入り順に並び替え（こちらはローカルでのみ行う）
                  noteService.notes.sort((a, b) => b.isFavorite ? 1 : -1);
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ログアウト'),
          content: const Text('本当にログアウトしますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                final authService = Provider.of<AuthService>(context, listen: false);
                authService.signOut();
              },
              child: const Text('ログアウト'),
            ),
          ],
        );
      },
    );
  }

  void _createNewNote(BuildContext context) {
    final noteService = Provider.of<NoteService>(context, listen: false);
    
    // 新規ノートを作成
    final newNote = noteService.createNewNote();
    
    // 保存
    noteService.saveNote(newNote);
    
    // 新しいノートの詳細画面に移動
    context.go('/notes/${newNote.id}');
  }
}

// 検索機能の実装
class NoteSearchDelegate extends SearchDelegate<String> {
  final List<Note> notes;

  NoteSearchDelegate(this.notes);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return Center(
        child: Text(
          '検索キーワードを入力してください',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      );
    }

    final filteredNotes = notes.where((note) {
      final titleMatches = note.title.toLowerCase().contains(query.toLowerCase());
      final tagMatches = note.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
      return titleMatches || tagMatches;
    }).toList();

    if (filteredNotes.isEmpty) {
      return Center(
        child: Text(
          '「$query」に一致するノートが見つかりませんでした',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredNotes.length,
      itemBuilder: (context, index) {
        final note = filteredNotes[index];
        return ListTile(
          title: Text(note.title),
          subtitle: Text(note.tags.join(', ')),
          leading: const Icon(Icons.note),
          onTap: () {
            close(context, note.id);
            context.go('/notes/${note.id}');
          },
        );
      },
    );
  }
}