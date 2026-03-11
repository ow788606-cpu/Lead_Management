import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

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
  late quill.QuillController _quillController;
  final FocusNode _focusNode = FocusNode();
  bool _showStyleMenu = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _quillController = quill.QuillController.basic();
    _quillController.addListener(_onQuillTextChanged);
  }

  void _onQuillTextChanged() {
    final html = _quillToHtml(_quillController.document);
    widget.controller.text = html;
  }

  String _quillToHtml(quill.Document doc) {
    final delta = doc.toDelta();
    final buffer = StringBuffer();
    String? currentListType;
    bool inList = false;

    for (var op in delta.toList()) {
      if (op.data is String) {
        String text = op.data as String;
        final attrs = op.attributes;

        // Handle line breaks
        if (text == '\n') {
          if (attrs != null) {
            // Handle headers
            if (attrs.containsKey('header')) {
              final level = attrs['header'];
              if (level != null) {
                buffer.write('</h$level>');
                buffer.write('\n');
                continue;
              }
            }
            // Handle lists
            if (attrs.containsKey('list')) {
              buffer.write('</li>');
              buffer.write('\n');
              inList = true;
              continue;
            }
          }
          // Close any open list
          if (inList && (attrs == null || !attrs.containsKey('list'))) {
            if (currentListType != null) {
              buffer.write('</$currentListType>');
              buffer.write('\n');
              currentListType = null;
            }
            inList = false;
          }
          if (!inList) {
            buffer.write('\n');
          }
          continue;
        }

        // Skip empty text
        if (text.trim().isEmpty && text != ' ') continue;

        // Handle block-level formatting (headers and lists)
        bool isBlockLevel = false;
        if (attrs != null && attrs.containsKey('header')) {
          final level = attrs['header'];
          buffer.write('<h$level>');
          isBlockLevel = true;
        } else if (attrs != null && attrs.containsKey('list')) {
          final listType = attrs['list'];
          if (listType == 'bullet') {
            if (currentListType != 'ul') {
              if (currentListType != null) {
                buffer.write('</$currentListType>');
                buffer.write('\n');
              }
              buffer.write('<ul>');
              buffer.write('\n');
              currentListType = 'ul';
            }
          } else if (listType == 'ordered') {
            if (currentListType != 'ol') {
              if (currentListType != null) {
                buffer.write('</$currentListType>');
                buffer.write('\n');
              }
              buffer.write('<ol>');
              buffer.write('\n');
              currentListType = 'ol';
            }
          }
          buffer.write('<li>');
          isBlockLevel = true;
        }

        // Handle inline formatting only if not block-level
        String formattedText = text;
        if (attrs != null && !isBlockLevel) {
          if (attrs['bold'] == true) {
            formattedText = '<strong>$formattedText</strong>';
          }
          if (attrs['italic'] == true) {
            formattedText = '<em>$formattedText</em>';
          }
          if (attrs['underline'] == true) {
            formattedText = '<u>$formattedText</u>';
          }
        }

        buffer.write(formattedText);
      }
    }

    // Close any remaining open list
    if (currentListType != null) {
      buffer.write('</$currentListType>');
      buffer.write('\n');
    }

    return buffer.toString();
  }

  @override
  void dispose() {
    _removeOverlay();
    _quillController.removeListener(_onQuillTextChanged);
    _quillController.dispose();
    _focusNode.dispose();
    super.dispose();
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: CompositedTransformTarget(
            link: _layerLink,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStyleDropdown(),
                  const SizedBox(width: 8),
                  _buildToolbarButton(
                    icon: Icons.format_bold,
                    onPressed: () => _quillController.formatSelection(quill.Attribute.bold),
                    tooltip: 'Bold',
                  ),
                  _buildToolbarButton(
                    icon: Icons.format_italic,
                    onPressed: () => _quillController.formatSelection(quill.Attribute.italic),
                    tooltip: 'Italic',
                  ),
                  _buildToolbarButton(
                    icon: Icons.format_underline,
                    onPressed: () => _quillController.formatSelection(quill.Attribute.underline),
                    tooltip: 'Underline',
                  ),
                  _buildToolbarButton(
                    icon: Icons.link,
                    onPressed: () {},
                    tooltip: 'Link',
                  ),
                  _buildToolbarButton(
                    icon: Icons.format_list_bulleted,
                    onPressed: () => _quillController.formatSelection(quill.Attribute.ul),
                    tooltip: 'Bullet List',
                  ),
                  _buildToolbarButton(
                    icon: Icons.format_list_numbered,
                    onPressed: () => _quillController.formatSelection(quill.Attribute.ol),
                    tooltip: 'Numbered List',
                  ),
                  _buildToolbarButton(
                    icon: Icons.format_clear,
                    onPressed: () => _quillController.formatSelection(quill.Attribute.clone(quill.Attribute.bold, null)),
                    tooltip: 'Clear Format',
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(8)),
          ),
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(
            minHeight: (widget.maxLines ?? 6) * 20.0,
            maxHeight: (widget.maxLines ?? 6) * 24.0,
          ),
          child: quill.QuillEditor.basic(
            controller: _quillController,
            focusNode: _focusNode,
          ),
        ),
      ],
    );
  }

  Widget _buildStyleDropdown() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showStyleMenu = !_showStyleMenu;
        });
        if (_showStyleMenu) {
          _showOverlay();
        } else {
          _removeOverlay();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getCurrentStyleName(),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey[700]),
          ],
        ),
      ),
    );
  }

  String _getCurrentStyleName() {
    final attrs = _quillController.getSelectionStyle().attributes;
    if (attrs.containsKey('header')) {
      final level = attrs['header']?.value;
      if (level == 1) return 'Heading 1';
      if (level == 2) return 'Heading 2';
      if (level == 3) return 'Heading 3';
    }
    return 'Normal';
  }

  void _showOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 200,
        child: CompositedTransformFollower(
          link: _layerLink,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 8),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStyleOption('Heading 1', quill.Attribute.h1, 24, FontWeight.bold),
                  _buildStyleOption('Heading 2', quill.Attribute.h2, 20, FontWeight.bold),
                  _buildStyleOption('Heading 3', quill.Attribute.h3, 18, FontWeight.w600),
                  _buildStyleOption('Normal', quill.Attribute.header, 14, FontWeight.normal, isNormal: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _showStyleMenu = false;
  }

  Widget _buildStyleOption(String label, quill.Attribute attribute, double fontSize, FontWeight fontWeight, {bool isNormal = false}) {
    return InkWell(
      onTap: () {
        if (isNormal) {
          _quillController.formatSelection(quill.Attribute.clone(quill.Attribute.header, null));
        } else {
          _quillController.formatSelection(attribute);
        }
        _removeOverlay();
        setState(() {});
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: label == 'Normal' ? const Color(0xFF0B5CFF) : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20),
      color: Colors.black87,
      onPressed: onPressed,
      tooltip: tooltip,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}
