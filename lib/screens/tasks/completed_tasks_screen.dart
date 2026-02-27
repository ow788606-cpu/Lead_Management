import 'package:flutter/material.dart';

class CompletedTasksScreen extends StatelessWidget {
  const CompletedTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Completed Tasks', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 2),
            Text('Tasks that have been completed', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.blue),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 50, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      Expanded(flex: 2, child: Text('Task', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      Expanded(flex: 2, child: Text('Assigned To', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      Expanded(flex: 2, child: Text('Completed Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      Expanded(flex: 1, child: Text('Priority', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      Expanded(flex: 1, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    ],
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text('No completed tasks found.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const IconButton(
                        onPressed: null,
                        icon: Icon(Icons.chevron_left, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                      const SizedBox(width: 8),
                      const IconButton(
                        onPressed: null,
                        icon: Icon(Icons.chevron_right, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                      const SizedBox(width: 16),
                      const Text('Page 1 of 1 - 0 total', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
