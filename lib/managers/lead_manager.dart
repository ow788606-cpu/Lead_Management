import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_manager.dart';
import '../models/lead.dart';
import '../services/api_config.dart';
import '../services/notification_service.dart';

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

  List<Lead> get followUpLeads {
    final list = _leads
        .where((lead) => lead.followUpDate != null)
        .toList();
    list.sort((a, b) => a.followUpDate!.compareTo(b.followUpDate!));
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
    
    try {
      final headers = await AuthManager().authHeaders(includeContentType: false);
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/leads.php?user_id=$userId'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
        throw Exception('Invalid leads response: ${response.body}');
      }

      final rows = <Lead>[];
      final data = decoded['data'] as List<dynamic>? ?? [];
      for (final item in data) {
        if (item is Map) {
          final map = <String, dynamic>{};
          item.forEach((key, value) {
            map[key.toString()] = value;
          });
          rows.add(_leadFromApi(map));
        }
      }
      _leads.clear();
      _leads.addAll(rows);
      _isLoaded = true;
    } catch (e) {
      _isLoaded = true; // Mark as loaded to prevent retry loops
      throw Exception('Failed to load leads: $e');
    }
  }

  Future<void> createLead({
    required String contactId,
    String? serviceName,
    String? tags,
    String? description,
    DateTime? nextFollowUpAt,
  }) async {
    final userId = await AuthManager().getUserId() ?? 0;
    
    try {
      final headers = await AuthManager().authHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/leads.php'),
        headers: headers,
        body: jsonEncode({
          'user_id': userId,
          'contact_id': int.tryParse(contactId) ?? 0,
          'service_name': serviceName?.trim(),
          'tags': tags?.trim(),
          'description': description?.trim(),
          'next_followup_at': nextFollowUpAt?.toIso8601String(),
          'status_id': 1,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      // Debug: Print response body
      
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
        throw Exception((decoded['message'] ?? 'Invalid lead response: ${response.body}').toString());
      }

      await loadLeads(forceRefresh: true);
    } catch (e) {
      throw Exception('Failed to create lead: $e');
    }
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

  Future<void> markAsCompleted(String id) async {
    final userId = await AuthManager().getUserId() ?? 0;
    final headers = await AuthManager().authHeaders();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/leads.php'),
      headers: headers,
      body: jsonEncode({
        'action': 'update_status',
        'lead_id': int.tryParse(id) ?? 0,
        'user_id': userId,
        'status_id': 4, // 4 = completed status
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to mark lead as completed');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
      throw Exception('Failed to update lead status');
    }

    // Update local data
    final index = _leads.indexWhere((lead) => lead.id == id);
    if (index != -1) {
      _leads[index].isCompleted = true;
    }
    
    // Cancel notification for this lead
    NotificationService().cancelNotification(id);
  }

  Lead _leadFromApi(Map<String, dynamic> json) {
    try {
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
    } catch (e) {
      throw Exception('Error parsing lead: $e');
    }
  }

  String? _nullableString(dynamic value) {
    if (value == null) return null;
    final v = value.toString().trim();
    return v.isEmpty ? null : v;
  }
}
