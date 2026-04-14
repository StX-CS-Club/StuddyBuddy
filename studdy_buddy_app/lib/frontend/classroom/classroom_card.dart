import 'package:flutter/material.dart';
import 'package:studdy_buddy_app/backend/data/classroom.dart';
import 'package:studdy_buddy_app/extensions/build_context_extension.dart';
import 'package:studdy_buddy_app/extensions/color_extension.dart';
import 'package:studdy_buddy_app/frontend/classroom/classroom_page.dart';
import 'package:studdy_buddy_app/frontend/startup/theme.dart';

class ClassroomCard extends StatelessWidget {
  const ClassroomCard({super.key, required this.classroom});

  final Classroom classroom;

  Color get _color => classroom.colorId != null
      ? ColorExtension.fromHex(classroom.colorId!)
      : StuddyBuddyTheme.teal;

  void _enter(BuildContext context) =>
      context.pushSwipePage(ClassroomPage(classroom: classroom));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: _color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _enter(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _color.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Emoji + color box
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      classroom.emoji ?? '📚',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Name + student count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classroom.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${classroom.studentIds.length} students',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                // Enter button
                Icon(
                  Icons.chevron_right_rounded,
                  color: _color,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
