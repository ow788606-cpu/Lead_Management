import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/note.dart';
import '../services/api_config.dart';
import 'auth_manager.dart';

class NoteManager {
  static final NoteManager _instance = NoteManager._internal();
  factory NoteManager() => _instance;
  NoteManager._internal();

  Future<List<Note>> getNotesByLeadId(String leadId) async {
    final userId = await AuthManager().getUserId() ?? 0;
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/notes.php?lead_id=$leadId&user_id=$userId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((item) => Note.fromJson(item))
            .toList();
      }
    }
    return [];
  }

  Future<bool> addNote(Note note) async {
    final userId = await AuthManager().getUserId() ?? 0;
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/notes.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        ...note.toJson(),
        'user_id': userId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }
}