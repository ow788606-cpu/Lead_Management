import 'package:flutter/material.dart';

class RichTextEditor extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final int? maxLines;

  const RichTextEditor({
    super.key,
    required this.controller,
    this.hintText,
    this.maxLines = 6,
  });

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  final FocusNode _focusNode = FocusNode();
  final List<_TextSegment> _segments = [];
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  int _lastTextLength = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleTextChange() {
    final text = widget.controller.text;
    final currentLength = text.length;
    
    if (currentLength > _lastTextLength) {
      final addedText = text.substring(_lastTextLength, currentLength);
      _segments.add(_TextSegment(
        text: addedText,
        isBold: _isBold,
        isItalic: _isItalic,
        isUnderline: _isUnderline,
      ));
    } else if (currentLength < _lastTextLength) {
      _rebuildSegments(text);
    }
    
    _lastTextLength = currentLength;
    setState(() {});
  }

  void _rebuildSegments(String text) {
    int charCount = 0;
    _segments.removeWhere((segment) {
      charCount += segment.text.length;
      return charCount > text.length;
    });
    
    if (_segments.isNotEmpty && charCount > text.length) {
      final lastSegment = _segments.last;
      final overflow = charCount - text.length;
      _segments[_segments.length - 1] = _TextSegment(
        text: lastSegment.text.substring(0, lastSegment.text.length - overflow),
        isBold: lastSegment.isBold,
        isItalic: lastSegment.isItalic,
        isUnderline: lastSegment.isUnderline,
      );
    }
  }

  void _toggleFormat(String type) {
    setState(() {
      if (type == 'bold') _isBold = !_isBold;
      if (type == 'italic') _isItalic = !_isItalic;
      if (type == 'underline') _isUnderline = !_isUnderline;
    });
    _focusNode.requestFocus();
  }

  void _insertList(String prefix) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final start = selection.start;

    if (start < 0) return;

    final beforeCursor = text.substring(0, start);
    final lastNewline = beforeCursor.lastIndexOf('\n');
    final lineStart = lastNewline == -1 ? 0 : lastNewline + 1;
    
    final currentLine = text.substring(lineStart, start);
    if (currentLine.startsWith(prefix)) {
      _focusNode.requestFocus();
      return;
    }
    
    final newText = text.substring(0, lineStart) + prefix + text.substring(lineStart);
    final newCursorPos = start + prefix.length;
    
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildToolbarButton(
                  icon: Icons.format_bold,
                  isActive: _isBold,
                  onPressed: () => _toggleFormat('bold'),
                  tooltip: 'Bold',
                ),
                _buildToolbarButton(
                  icon: Icons.format_italic,
                  isActive: _isItalic,
                  onPressed: () => _toggleFormat('italic'),
                  tooltip: 'Italic',
                ),
                _buildToolbarButton(
                  icon: Icons.format_underline,
                  isActive: _isUnderline,
                  onPressed: () => _toggleFormat('underline'),
                  tooltip: 'Underline',
                ),
                _buildToolbarButton(
                  icon: Icons.link,
                  onPressed: () {},
                  tooltip: 'Insert Link',
                ),
                _buildToolbarButton(
                  icon: Icons.format_list_bulleted,
                  onPressed: () => _insertList('• '),
                  tooltip: 'Bullet List',
                ),
                _buildToolbarButton(
                  icon: Icons.format_list_numbered,
                  onPressed: () => _insertList('1. '),
                  tooltip: 'Numbered List',
                ),
                _buildToolbarButton(
                  icon: Icons.text_fields,
                  onPressed: () {
                    showMenu(
                      context: context,
                      position: const RelativeRect.fromLTRB(0, 50, 0, 0),
                      items: [
                        PopupMenuItem(
                          child: const Text('Heading 1'),
                          onTap: () => Future.delayed(Duration.zero, () => _insertList('# ')),
                        ),
                        PopupMenuItem(
                          child: const Text('Heading 2'),
                          onTap: () => Future.delayed(Duration.zero, () => _insertList('## ')),
                        ),
                        PopupMenuItem(
                          child: const Text('Heading 3'),
                          onTap: () => Future.delayed(Duration.zero, () => _insertList('### ')),
                        ),
                      ],
                    );
                  },
                  tooltip: 'Text Format',
                ),
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
          ),
          padding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                maxLines: widget.maxLines,
                style: const TextStyle(color: Colors.transparent),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                cursorColor: const Color(0xFF0B5CFF),
              ),
              if (_segments.isNotEmpty)
                Positioned.fill(
                  child: IgnorePointer(
                    child: RichText(
                      text: TextSpan(
                        children: _segments.map((segment) {
                          return TextSpan(
                            text: segment.text,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: segment.isBold ? FontWeight.bold : FontWeight.normal,
                              fontStyle: segment.isItalic ? FontStyle.italic : FontStyle.normal,
                              decoration: segment.isUnderline ? TextDecoration.underline : TextDecoration.none,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: IconButton(
        icon: Icon(icon, size: 20),
        color: isActive ? const Color(0xFF0B5CFF) : Colors.black87,
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }
}

class _TextSegment {
  final String text;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;

  _TextSegment({
    required this.text,
    required this.isBold,
    required this.isItalic,
    required this.isUnderline,
  });
}
