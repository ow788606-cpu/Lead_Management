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
    return _buildHtmlText(context);
  }

  Widget _buildHtmlText(BuildContext context) {
    final spans = _parseHtml(text);
    return RichText(
      text: TextSpan(
        style: baseStyle ??
            const TextStyle(
                fontSize: 14, color: Colors.black87, fontFamily: 'Inter'),
        children: spans,
      ),
    );
  }

  List<InlineSpan> _parseHtml(String html) {
    final spans = <InlineSpan>[];
    int index = 0;

    while (index < html.length) {
      // Check for h1
      if (html.substring(index).startsWith('<h1>')) {
        final endIndex = html.indexOf('</h1>', index);
        if (endIndex != -1) {
          final content = html.substring(index + 4, endIndex);
          spans.add(TextSpan(
            text: content,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
          ));
          index = endIndex + 5;
          continue;
        }
      }

      // Check for h2
      if (html.substring(index).startsWith('<h2>')) {
        final endIndex = html.indexOf('</h2>', index);
        if (endIndex != -1) {
          final content = html.substring(index + 4, endIndex);
          spans.add(TextSpan(
            text: content,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
          ));
          index = endIndex + 5;
          continue;
        }
      }

      // Check for h3
      if (html.substring(index).startsWith('<h3>')) {
        final endIndex = html.indexOf('</h3>', index);
        if (endIndex != -1) {
          final content = html.substring(index + 4, endIndex);
          spans.add(TextSpan(
            text: content,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
          ));
          index = endIndex + 5;
          continue;
        }
      }

      // Check for strong
      if (html.substring(index).startsWith('<strong>')) {
        final endIndex = html.indexOf('</strong>', index);
        if (endIndex != -1) {
          final content = html.substring(index + 8, endIndex);
          spans.add(TextSpan(
            text: content,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ));
          index = endIndex + 9;
          continue;
        }
      }

      // Check for em
      if (html.substring(index).startsWith('<em>')) {
        final endIndex = html.indexOf('</em>', index);
        if (endIndex != -1) {
          final content = html.substring(index + 4, endIndex);
          spans.add(TextSpan(
            text: content,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ));
          index = endIndex + 5;
          continue;
        }
      }

      // Check for u
      if (html.substring(index).startsWith('<u>')) {
        final endIndex = html.indexOf('</u>', index);
        if (endIndex != -1) {
          final content = html.substring(index + 3, endIndex);
          spans.add(TextSpan(
            text: content,
            style: const TextStyle(decoration: TextDecoration.underline),
          ));
          index = endIndex + 4;
          continue;
        }
      }

      // Check for ul/ol lists
      if (html.substring(index).startsWith('<ul>') ||
          html.substring(index).startsWith('<ol>')) {
        final isOrdered = html.substring(index).startsWith('<ol>');
        final closeTag = isOrdered ? '</ol>' : '</ul>';
        final endIndex = html.indexOf(closeTag, index);
        if (endIndex != -1) {
          final listContent =
              html.substring(index + (isOrdered ? 4 : 4), endIndex);
          final items =
              listContent.split('<li>').where((s) => s.isNotEmpty).toList();
          for (int i = 0; i < items.length; i++) {
            final item = items[i].replaceAll('</li>', '').trim();
            if (item.isNotEmpty) {
              spans.add(const TextSpan(text: '\n• '));
              spans.addAll(_parseHtml(item));
            }
          }
          index = endIndex + closeTag.length;
          continue;
        }
      }

      // Check for br
      if (html.substring(index).startsWith('<br>')) {
        spans.add(const TextSpan(text: '\n'));
        index += 4;
        continue;
      }

      // Regular text
      int nextTag = html.length;
      final tags = [
        '<h1>',
        '<h2>',
        '<h3>',
        '<strong>',
        '<em>',
        '<u>',
        '<ul>',
        '<ol>',
        '<br>'
      ];
      for (final tag in tags) {
        final pos = html.indexOf(tag, index);
        if (pos != -1 && pos < nextTag) {
          nextTag = pos;
        }
      }

      if (nextTag > index) {
        final text = html.substring(index, nextTag);
        if (text.isNotEmpty) {
          spans.add(TextSpan(text: text));
        }
        index = nextTag;
      } else {
        index++;
      }
    }

    return spans.isEmpty ? [const TextSpan(text: '')] : spans;
  }
}
