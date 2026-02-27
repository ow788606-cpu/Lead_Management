import 'package:flutter/material.dart';

class LeadReportsScreen extends StatelessWidget {
  const LeadReportsScreen({super.key});

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
            Text('Lead Reports', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 2),
            Text('View and analyze lead reports', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: const SafeArea(
        child: Center(
          child: Text('Lead Reports Screen', style: TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}
