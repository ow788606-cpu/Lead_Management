import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_manager.dart';
import '../models/lead.dart';
import '../services/api_config.dart';

class LeadManager {
  static final LeadManager _instance = LeadManager._internal();
  factory LeadManager() => _instance;
  LeadManager._internal();

  final List<Lead> _leads = [];
  bool _isLoaded = false;

  List<Lead> get allLeads => _leads;
  List<Lead> get freshLeads {
    final list = _leads.where((lead) => lead.isFresh).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<Lead> get overdueLeads {
    final now = DateTime.now();
    final list = _leads
        .where((lead) =>
            !lead.isCompleted &&
            lead.followUpDate != null &&
            lead.followUpDate!.isBefore(now))
        .toList();
    list.sort((a, b) => a.followUpDate!.compareTo(b.followUpDate!));
    return list;
  }

  List<Lead> get completedLeads {
    final list = _leads.where((lead) => lead.isCompleted).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> loadLeads({bool forceRefresh = false}) async {
    if (_isLoaded && !forceRefresh) return;
    final userId = await AuthManager().getUserId() ?? 0;
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/leads.php?user_id=$userId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load leads');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
      throw Exception('Invalid leads response');
    }

    final rows = (decoded['data'] as List<dynamic>? ?? [])
        .map((item) => item as Map<String, dynamic>)
        .map(_leadFromApi)
        .toList();
    _leads.clear();
    _leads.addAll(rows);
    _isLoaded = true;
  }

  Future<void> createLead({
    required String contactId,
    String? serviceName,
    String? tags,
    String? description,
    DateTime? nextFollowUpAt,
  }) async {
    final userId = await AuthManager().getUserId() ?? 0;
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/leads.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'contact_id': int.tryParse(contactId) ?? 0,
        'service_name': serviceName?.trim(),
        'tags': tags?.trim(),
        'description': description?.trim(),
        'next_followup_at': nextFollowUpAt?.toIso8601String(),
        'status_id': 1,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create lead');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
      throw Exception((decoded['message'] ?? 'Invalid lead response').toString());
    }

    await loadLeads(forceRefresh: true);
  }

  void addLead(Lead lead) {
    _leads.add(lead);
    _isLoaded = true;
  }

  void updateLead(String id, Lead updatedLead) {
    final index = _leads.indexWhere((lead) => lead.id == id);
    if (index != -1) {
      _leads[index] = updatedLead;
    }
  }

  void deleteLead(String id) {
    _leads.removeWhere((lead) => lead.id == id);
  }

  void markAsCompleted(String id) {
    final index = _leads.indexWhere((lead) => lead.id == id);
    if (index != -1) {
      _leads[index].isCompleted = true;
    }
  }

  Lead _leadFromApi(Map<String, dynamic> json) {
    final followUp =
        DateTime.tryParse((json['next_followup_at'] ?? '').toString());
    final createdAt =
        DateTime.tryParse((json['created_at'] ?? '').toString()) ??
            DateTime.now();
    final statusId = int.tryParse((json['status'] ?? '0').toString()) ?? 0;
    final followUpTime = followUp == null
        ? null
        : '${((followUp.hour % 12 == 0) ? 12 : followUp.hour % 12)}:${followUp.minute.toString().padLeft(2, '0')} ${followUp.hour >= 12 ? 'PM' : 'AM'}';

    return Lead(
      id: (json['id'] ?? '').toString(),
      contactName: (json['contact_name'] ?? '').toString(),
      email: _nullableString(json['email']),
      phone: _nullableString(json['phone']),
      service: _nullableString(json['service_name']),
      tags: _nullableString(json['tags']),
      notes: _nullableString(json['description']),
      followUpDate: followUp,
      followUpTime: followUpTime,
      createdAt: createdAt,
      isCompleted: statusId == 4,
    );
  }

  String? _nullableString(dynamic value) {
    if (value == null) return null;
    final v = value.toString().trim();
    return v.isEmpty ? null : v;
  }
}
