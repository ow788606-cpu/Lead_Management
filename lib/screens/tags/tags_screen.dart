import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:hugeicons/hugeicons.dart';
import 'tag_api.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  List<TagItem> _tags = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final tags = await TagApi.fetchTags();
      if (!mounted) return;
      setState(() => _tags = tags);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Unable to load tags: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _parseColor(String hex) {
    final normalized = hex.replaceFirst('#', '').toUpperCase();
    if (normalized.length != 6) return const Color(0xFF131416);
    return Color(int.parse('FF$normalized', radix: 16));
  }

  Future<void> _deleteTag(TagItem tag) async {
    try {
      await TagApi.deleteTag(tag.id);
      await _loadTags();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delete failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTags = _tags.where((tag) {
      if (_searchQuery.trim().isEmpty) return true;
      final query = _searchQuery.trim().toLowerCase();
      final name = tag.name.toLowerCase();
      final description = tag.description.toLowerCase();
      return name.contains(query) || description.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Icon(
                      Icons.search,
                      color: Colors.grey,
                      size: 24.0,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: const InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Icon(
                      Icons.tune,
                      color: Colors.grey,
                      size: 24.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(fontFamily: 'Inter'),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadTags,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: filteredTags.length,
                            itemBuilder: (context, index) {
                              final tag = filteredTags[index];
                              final tagColor = _parseColor(tag.colorHex);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: tagColor.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.label,
                                        color: tagColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(tag.name,
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'Inter'),
                                              overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 4),
                                          Text(tag.description,
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  fontFamily: 'Inter',
                                                  color: Colors.grey[600]),
                                              overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap:
                                          () async {
                                        if (!mounted) return;
                                        final messenger = ScaffoldMessenger.of(context);
                                        final nameController = TextEditingController(text: tag.name);
                                        final descController = TextEditingController(text: tag.description);
                                        Color selectedColor = _parseColor(tag.colorHex);
                                        
                                        final result = await showDialog<Map<String, dynamic>>(
                                          context: context,
                                          builder: (context) => StatefulBuilder(
                                            builder: (context, setState) => AlertDialog(
                                              title: const Text('Edit Tag'),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  TextField(
                                                    controller: nameController,
                                                    decoration: const InputDecoration(
                                                      labelText: 'Name',
                                                      border: OutlineInputBorder(),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  TextField(
                                                    controller: descController,
                                                    decoration: const InputDecoration(
                                                      labelText: 'Description',
                                                      border: OutlineInputBorder(),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  GestureDetector(
                                                    onTap: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) => AlertDialog(
                                                          title: const Text('Pick Color'),
                                                          content: BlockPicker(
                                                            pickerColor: selectedColor,
                                                            onColorChanged: (color) {
                                                              selectedColor = color;
                                                              setState(() {});
                                                            },
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () => Navigator.pop(context),
                                                              child: const Text('Done'),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          width: 30,
                                                          height: 30,
                                                          decoration: BoxDecoration(
                                                            color: selectedColor,
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: Colors.grey),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text('#${selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}'),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, {
                                                    'name': nameController.text,
                                                    'description': descController.text,
                                                    'color': '#${selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                                                  }),
                                                  child: const Text('Save'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                        
                                        if (result != null && result['name']?.trim().isNotEmpty == true) {
                                          if (!mounted) return;
                                          try {
                                            await TagApi.updateTag(
                                              id: tag.id,
                                              name: result['name'],
                                              description: result['description'] ?? '',
                                              colorHex: result['color'],
                                            );
                                            await _loadTags();
                                          } catch (e) {
                                            if (!mounted) return;
                                            messenger.showSnackBar(
                                              const SnackBar(content: Text('Update failed')),
                                            );
                                          }
                                        }
                                        nameController.dispose();
                                        descController.dispose();
                                          },
                                          child: const HugeIcon(
                                            icon: HugeIcons.strokeRoundedPencilEdit02,
                                            color: Color(0xFF131416),
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () => _deleteTag(tag),
                                          child: const HugeIcon(
                                            icon: HugeIcons.strokeRoundedDelete02,
                                            color: Colors.red,
                                            size: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
          ),
        ],
      ),
    );
  }
}
