import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MailService {
  // Backend-URL für den E-Mail-Versand
  static const String _backendUrl =
      'https://mailteg-q70kb81kq-olivers-projects-a52ebdf6.vercel.app/api/send-email';

  static Future<bool> sendEmail({
    required String to,
    required String subject,
    required String htmlContent,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'to': to,
          'subject': subject,
          'html': htmlContent,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        debugPrint('📧 E-Mail an $to erfolgreich über Backend gesendet!');
        return true;
      } else {
        debugPrint('❌ Backend-Fehler: ${response.statusCode}');
        debugPrint('Antwortbody: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Fehler beim E-Mail-Versand: $e');
      return false;
    }
  }
}
