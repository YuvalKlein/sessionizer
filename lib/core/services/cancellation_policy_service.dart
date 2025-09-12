import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CancellationPolicyService {
  static const String _agreementsKey = 'cancellation_policy_agreements';
  
  /// Save a cancellation policy agreement for a specific session type
  static Future<void> saveAgreement(String sessionTypeId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final agreements = await getAgreements(userId);
    agreements.add(sessionTypeId);
    await prefs.setString('${_agreementsKey}_$userId', jsonEncode(agreements.toList()));
  }
  
  /// Check if user has already agreed to cancellation policy for a session type
  static Future<bool> hasAgreed(String sessionTypeId, String userId) async {
    final agreements = await getAgreements(userId);
    return agreements.contains(sessionTypeId);
  }
  
  /// Get all session types the user has agreed to cancellation policy for
  static Future<Set<String>> getAgreements(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final agreementsJson = prefs.getString('${_agreementsKey}_$userId');
    if (agreementsJson == null) {
      return <String>{};
    }
    
    try {
      final List<dynamic> agreementsList = jsonDecode(agreementsJson);
      return agreementsList.map((e) => e.toString()).toSet();
    } catch (e) {
      return <String>{};
    }
  }
  
  /// Remove an agreement (if user wants to see the modal again)
  static Future<void> removeAgreement(String sessionTypeId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final agreements = await getAgreements(userId);
    agreements.remove(sessionTypeId);
    await prefs.setString('${_agreementsKey}_$userId', jsonEncode(agreements.toList()));
  }
  
  /// Clear all agreements for a user
  static Future<void> clearAllAgreements(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_agreementsKey}_$userId');
  }
}



