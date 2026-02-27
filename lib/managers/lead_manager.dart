import '../models/lead.dart';

class LeadManager {
  static final LeadManager _instance = LeadManager._internal();
  factory LeadManager() => _instance;
  LeadManager._internal();

  final List<Lead> _leads = [];

  List<Lead> get allLeads => _leads;
  List<Lead> get freshLeads => _leads.where((lead) => lead.isFresh).toList();
  List<Lead> get overdueLeads => _leads.where((lead) => lead.isOverdue).toList();
  List<Lead> get completedLeads => _leads.where((lead) => lead.isCompleted).toList();

  void addLead(Lead lead) {
    _leads.add(lead);
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
}
