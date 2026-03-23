// ignore_for_file: unnecessary_const

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'service_manager.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final _serviceManager = ServiceManager();
  String _searchQuery = '';
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _serviceManager.addListener(_onServicesChanged);
    _loadServices();
  }

  @override
  void dispose() {
    _serviceManager.removeListener(_onServicesChanged);
    super.dispose();
  }

  void _onServicesChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      await _serviceManager.refreshServices();
    } catch (e) {
      _loadError = e.toString();
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final filteredServices = _serviceManager.services.where((service) {
      if (_searchQuery.trim().isEmpty) return true;
      return service.toLowerCase().contains(_searchQuery.trim().toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
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
                  : _loadError != null
                      ? Center(
                          child: Text(
                            _loadError!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.red,
                              fontFamily: 'Inter',
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredServices.length,
                          itemBuilder: (context, index) {
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
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF131416),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text('${index + 1}',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Inter',
                                              color: const Color(0xFF131416))),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(filteredServices[index],
                                        style: const TextStyle(
                                            fontSize: 14, fontFamily: 'Inter')),
                                  ),
                                  IconButton(
                                    icon: const HugeIcon(
                                      icon: HugeIcons.strokeRoundedPencilEdit02,
                                      color: Color(0xFF131416),
                                      size: 18,
                                    ),
                                    onPressed: () async {
                                      final controller = TextEditingController(
                                          text: filteredServices[index]);
                                      final result = await showDialog<String>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Edit Service'),
                                          content: TextField(
                                            controller: controller,
                                            decoration: const InputDecoration(
                                              hintText: 'Service name',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(
                                                  context, controller.text),
                                              child: const Text('Save'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (result != null && result.trim().isNotEmpty) {
                                        final originalIndex = _serviceManager
                                            .services
                                            .indexOf(filteredServices[index]);
                                        if (originalIndex != -1) {
                                          await _serviceManager.updateService(
                                              originalIndex, result.trim());
                                        }
                                      }
                                      controller.dispose();
                                    },
                                  ),
                                  IconButton(
                                    icon: const HugeIcon(
                                      icon: HugeIcons.strokeRoundedDelete02,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    onPressed: () async {
                                      final originalIndex = _serviceManager
                                          .services
                                          .indexOf(filteredServices[index]);
                                      if (originalIndex != -1) {
                                        await _serviceManager
                                            .removeService(originalIndex);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
          ),
        ],
      ),
    );
  }
}
