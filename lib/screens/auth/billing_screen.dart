import 'package:flutter/material.dart';

class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Billing',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Billing Details',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        ),
                        child: const Text('Back to Dashboard',
                            style:
                                TextStyle(fontSize: 12, fontFamily: 'Inter')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                      'Your subscription, invoices, and payment history.',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          fontFamily: 'Inter')),
                  const SizedBox(height: 24),
                  const Text('Current Subscription',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter')),
                  const SizedBox(height: 16),
                  _buildInfoRow('Plan:', 'Free Trial (30 Days)',
                      trailingWidget: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('TRIAL',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter')),
                      )),
                  const SizedBox(height: 4),
                  const Text('  Free trial plan valid for 30 days',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontFamily: 'Inter')),
                  const SizedBox(height: 12),
                  _buildInfoRow('Status:', '',
                      trailingWidget: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('TRIAL',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter')),
                      )),
                  const SizedBox(height: 12),
                  _buildInfoRow('Price:', 'USD 0.00'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Billing Period:', '60 days'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Start Date:', '2026-02-27 05:24:29'),
                  const SizedBox(height: 12),
                  _buildInfoRow('End Date:', '2026-03-29 05:24:29'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Auto Renew:', 'Disabled',
                      valueColor: Colors.red),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invoices',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter')),
                  SizedBox(height: 16),
                  Text('No invoices available.',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontFamily: 'Inter')),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payments',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter')),
                  SizedBox(height: 16),
                  Text('No payments recorded yet.',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontFamily: 'Inter')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {Color? valueColor, Widget? trailingWidget}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  fontFamily: 'Inter')),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 14,
                  color: valueColor ?? Colors.black87,
                  fontFamily: 'Inter')),
        ),
        if (trailingWidget != null) trailingWidget,
      ],
    );
  }
}

