import 'package:flutter/material.dart';

class NoteAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isEditing;
  final TextEditingController titleController;
  final String noteTitle;
  final FocusNode titleFocusNode;
  final VoidCallback onEditPressed;
  final VoidCallback onMoreVertPressed;

  const NoteAppBar({
    Key? key,
    required this.isEditing,
    required this.titleController,
    required this.noteTitle,
    required this.titleFocusNode,
    required this.onEditPressed,
    required this.onMoreVertPressed,
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
          : Text(noteTitle),
      actions: [
        IconButton(
          icon: Icon(isEditing ? Icons.check : Icons.edit),
          onPressed: onEditPressed,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: onMoreVertPressed,
        ),
      ],
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
