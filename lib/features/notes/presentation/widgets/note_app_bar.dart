// lib/features/notes/presentation/widgets/note_app_bar.dart
import 'package:flutter/material.dart';

/// ノート詳細画面のAppBar
class NoteAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isEditing;
  final TextEditingController titleController;
  final FocusNode titleFocusNode;
  final VoidCallback onEditToggle;
  final VoidCallback onOptionsPressed;

  const NoteAppBar({
    Key? key,
    required this.title,
    required this.isEditing,
    required this.titleController,
    required this.titleFocusNode,
    required this.onEditToggle,
    required this.onOptionsPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: isEditing
          ? TextField(
              controller: titleController,
              focusNode: titleFocusNode,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'タイトルを入力',
                hintStyle: TextStyle(color: Colors.white70),
              ),
            )
          : Text(title),
      actions: [
        IconButton(
          icon: Icon(isEditing ? Icons.check : Icons.edit),
          onPressed: onEditToggle,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: onOptionsPressed,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}