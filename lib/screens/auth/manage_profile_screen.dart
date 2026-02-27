import 'package:flutter/material.dart';

class ManageProfileScreen extends StatelessWidget {
  const ManageProfileScreen({super.key});

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
            Text('Manage Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 2),
            Text('Update your profile information', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: const SafeArea(
        child: Center(
          child: Text('Manage Profile Screen', style: TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}
