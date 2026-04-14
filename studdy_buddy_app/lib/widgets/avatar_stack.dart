import 'package:flutter/material.dart';

class AvatarStack extends StatelessWidget {
  const AvatarStack({super.key});

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFF8DD8E0),
      Color(0xFF6ECDD6),
      Color(0xFF7BBF8A),
      Color(0xFF5A9E6F),
    ];

    return SizedBox(
      width: 66,
      height: 24,
      child: Stack(
        children: [
          for (int i = 0; i < colors.length; i++)
            Positioned(
              left: i * 14.0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: colors[i],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}