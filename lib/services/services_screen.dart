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
            const Text('All Services',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter')),
            const SizedBox(height: 12),
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
              child: ListView.builder(
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
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text('${index + 1}',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Inter',
                                    color: Colors.blue)),
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
                              size: 18, color: Colors.blue),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              size: 18, color: Colors.red),
                          onPressed: () {
                            final originalIndex = _serviceManager.services
                                .indexOf(filteredServices[index]);
                            if (originalIndex != -1) {
                              setState(() =>
                                  _serviceManager.removeService(originalIndex));
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
