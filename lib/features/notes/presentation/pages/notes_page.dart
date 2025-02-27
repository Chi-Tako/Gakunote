// lib/features/notes/presentation/pages/notes_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/note.dart';
import '../widgets/note_card.dart';
import '../../../shared/widgets/app_drawer.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({Key? key}) : super(key: key);

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  // ダミーデータの作成（後で実際のデータソースに置き換える）
  final List<Note> _notes = [
    Note(
      id: '1',
      title: '物理学の基本概念',
      blocks: [
        NoteBlock(
          type: BlockType.heading1,
          content: '物理学の基本概念',
        ),
        NoteBlock(
          type: BlockType.text,
          content: 'ニュートン力学の基本法則と応用例について',
        ),
      ],
      tags: ['物理', '学習'],
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Note(
      id: '2',
      title: '週間タスク計画',
      blocks: [
        NoteBlock(
          type: BlockType.heading1,
          content: '週間タスク計画',
        ),
        NoteBlock(
          type: BlockType.text,
          content: '今週の優先タスクと締め切り',
        ),
      ],
      tags: ['タスク', '計画'],
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      isFavorite: true,
    ),
    Note(
      id: '3',
      title: 'プログラミング学習ノート',
      blocks: [
        NoteBlock(
          type: BlockType.heading1,
          content: 'プログラミング学習ノート',
        ),
        NoteBlock(
          type: BlockType.text,
          content: 'Dartの基本文法とFlutterウィジェットの使い方',
        ),
      ],
      tags: ['プログラミング', 'Flutter'],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  // 検索クエリ
  String _searchQuery = '';

  // フィルタリングされたノートのリスト
  List<Note> get _filteredNotes {
    if (_searchQuery.isEmpty) {
      return _notes;
    }
    return _notes.where((note) {
      final titleMatches = note.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final tagMatches = note.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
      return titleMatches || tagMatches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gakunote'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: NoteSearchDelegate(_notes),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              _showSortOptions(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // メニューオプションを表示
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _buildNotesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 新規ノート作成画面に遷移
          _createNewNote();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNotesList() {
    if (_filteredNotes.isEmpty) {
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
              onPressed: _createNewNote,
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
      itemCount: _filteredNotes.length,
      itemBuilder: (context, index) {
        final note = _filteredNotes[index];
        return NoteCard(
          note: note,
          onTap: () {
            // ノート詳細画面に遷移
            context.go('/notes/${note.id}');
          },
          onFavoriteToggle: () {
            setState(() {
              note.isFavorite = !note.isFavorite;
            });
          },
        );
      },
    );
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('最終更新日'),
              onTap: () {
                setState(() {
                  _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.title),
              title: const Text('タイトル'),
              onTap: () {
                setState(() {
                  _notes.sort((a, b) => a.title.compareTo(b.title));
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('お気に入り'),
              onTap: () {
                setState(() {
                  _notes.sort((a, b) => b.isFavorite ? 1 : -1);
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _createNewNote() {
    final newNote = Note(
      title: '新規ノート',
      blocks: [
        NoteBlock(
          type: BlockType.heading1,
          content: '新規ノート',
        ),
        NoteBlock(
          type: BlockType.text,
          content: '',
        ),
      ],
    );
    
    setState(() {
      _notes.add(newNote);
    });
    
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