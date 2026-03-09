import 'package:flutter/material.dart';

class MarkdownRenderer extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;

  const MarkdownRenderer({
    super.key,
    required this.text,
    this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    return _buildRichText(context);
  }

  Widget _buildRichText(BuildContext context) {
    final spans = <InlineSpan>[];
    final lines = text.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      if (line.startsWith('# ')) {
        spans.add(TextSpan(
          text: line.substring(2),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
        ));
      } else if (line.startsWith('## ')) {
        spans.add(TextSpan(
          text: line.substring(3),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
        ));
      } else if (line.startsWith('### ')) {
        spans.add(TextSpan(
          text: line.substring(4),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
        ));
      } else {
        spans.addAll(_parseInlineMarkdown(line));
      }
      
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return RichText(
      text: TextSpan(
        style: baseStyle ?? const TextStyle(fontSize: 14, color: Colors.black87, fontFamily: 'Inter'),
        children: spans,
      ),
    );
  }

  List<InlineSpan> _parseInlineMarkdown(String text) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|<u>(.+?)</u>|\[(.+?)\]\((.+?)\)|•\s|(\d+\.\s)');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }

      if (match.group(1) != null) {
        // Bold
        spans.add(TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ));
      } else if (match.group(2) != null) {
        // Italic
        spans.add(TextSpan(
          text: match.group(2),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ));
      } else if (match.group(3) != null) {
        // Underline
        spans.add(TextSpan(
          text: match.group(3),
          style: const TextStyle(decoration: TextDecoration.underline),
        ));
      } else if (match.group(4) != null && match.group(5) != null) {
        // Link
        spans.add(TextSpan(
          text: match.group(4),
          style: const TextStyle(
            color: Color(0xFF0B5CFF),
            decoration: TextDecoration.underline,
          ),
        ));
      } else {
        // Bullet or number
        spans.add(TextSpan(text: match.group(0)));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return spans.isEmpty ? [TextSpan(text: text)] : spans;
  }
}
