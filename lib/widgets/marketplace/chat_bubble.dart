// chat_bubble.dart
import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool mine;

  const ChatBubble({super.key, required this.text, this.mine = false});

  @override
  Widget build(BuildContext context) {
    final bg = mine ? Colors.blue.shade600 : Colors.grey.shade200;
    final align = mine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = mine
        ? const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12), bottomLeft: Radius.circular(12))
        : const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12), bottomRight: Radius.circular(12));
    final textColor = mine ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(color: bg, borderRadius: radius),
          child: Text(text, style: TextStyle(color: textColor)),
        ),
      ],
    );
  }
}