// ignore_for_file: unnecessary_const

import 'package:flutter/material.dart';
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search services...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
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
                                      color: const Color(0xFF0B5CFF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text('${index + 1}',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Inter',
                                              color: const Color(0xFF0B5CFF))),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(filteredServices[index],
                                        style: const TextStyle(
                                            fontSize: 14, fontFamily: 'Inter')),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        size: 18,
                                        color: const Color(0xFF0B5CFF)),
                                    onPressed: () {},
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        size: 18, color: Colors.red),
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
      ),
    );
  }
}
