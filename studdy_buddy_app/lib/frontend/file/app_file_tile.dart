import 'package:flutter/material.dart';
import 'package:studdy_buddy_app/frontend/startup/theme.dart';

import '../../backend/files/app_file.dart';

class AppFileTile extends StatelessWidget {
  const AppFileTile({
    super.key,
    required this.file,
    this.onRemove,
    this.onView,
  });

  final AppFile file;
  final VoidCallback? onRemove;
  final VoidCallback? onView;

  IconData get _fileIcon {
    if (file.isImage) return Icons.image_outlined;
    if (file.isPdf) return Icons.picture_as_pdf_outlined;
    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: file.canView ? onView : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: StuddyBuddyTheme.surfaceBase,
        foregroundColor: StuddyBuddyTheme.teal,
        disabledBackgroundColor: StuddyBuddyTheme.surfaceBase,
        elevation: 0,
        padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4, right: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Icon(_fileIcon, size: 18, color: StuddyBuddyTheme.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              file.fileName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (file.canView) ...[
            const SizedBox(width: 8),
            Icon(Icons.visibility_outlined,
                size: 18, color: StuddyBuddyTheme.teal),
          ],
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: Icon(Icons.close, size: 18, color: Colors.grey.shade400),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}