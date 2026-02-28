import '../models/lead.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LeadManager {
  static final LeadManager _instance = LeadManager._internal();
  factory LeadManager() => _instance;
  LeadManager._internal() {
    _loadLeads();
  }

  final List<Lead> _leads = [];

  List<Lead> get allLeads => _leads;
  List<Lead> get freshLeads => _leads.where((lead) => lead.isFresh).toList();
  List<Lead> get overdueLeads => _leads.where((lead) => lead.isOverdue).toList();
  List<Lead> get completedLeads => _leads.where((lead) => lead.isCompleted).toList();

  Future<void> _loadLeads() async {
    final prefs = await SharedPreferences.getInstance();
    final leadsJson = prefs.getStringList('leads') ?? [];
    _leads.clear();
    _leads.addAll(leadsJson.map((json) => _leadFromJson(jsonDecode(json))));
  }

  Future<void> _saveLeads() async {
    final prefs = await SharedPreferences.getInstance();
    final leadsJson = _leads.map((lead) => jsonEncode(_leadToJson(lead))).toList();
    await prefs.setStringList('leads', leadsJson);
  }

  void addLead(Lead lead) {
    _leads.add(lead);
    _saveLeads();
  }

  void updateLead(String id, Lead updatedLead) {
    final index = _leads.indexWhere((lead) => lead.id == id);
    if (index != -1) {
      _leads[index] = updatedLead;
      _saveLeads();
    }
  }

  void deleteLead(String id) {
    _leads.removeWhere((lead) => lead.id == id);
    _saveLeads();
  }

  void markAsCompleted(String id) {
    final index = _leads.indexWhere((lead) => lead.id == id);
    if (index != -1) {
      _leads[index].isCompleted = true;
      _saveLeads();
    }
  }

  Map<String, dynamic> _leadToJson(Lead lead) => {
    'id': lead.id,
    'contactName': lead.contactName,
    'email': lead.email,
    'phone': lead.phone,
    'service': lead.service,
    'tags': lead.tags,
    'notes': lead.notes,
    'address': lead.address,
    'country': lead.country,
    'state': lead.state,
    'city': lead.city,
    'zip': lead.zip,
    'followUpDate': lead.followUpDate?.toIso8601String(),
    'followUpTime': lead.followUpTime,
    'createdAt': lead.createdAt.toIso8601String(),
    'isCompleted': lead.isCompleted,
  };

  Lead _leadFromJson(Map<String, dynamic> json) => Lead(
    id: json['id'],
    contactName: json['contactName'],
    email: json['email'],
    phone: json['phone'],
    service: json['service'],
    tags: json['tags'],
    notes: json['notes'],
    address: json['address'],
    country: json['country'],
    state: json['state'],
    city: json['city'],
    zip: json['zip'],
    followUpDate: json['followUpDate'] != null ? DateTime.parse(json['followUpDate']) : null,
    followUpTime: json['followUpTime'],
    createdAt: DateTime.parse(json['createdAt']),
    isCompleted: json['isCompleted'] ?? false,
  );
}
