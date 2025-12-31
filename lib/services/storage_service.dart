import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class StorageService {
  static const String _historyKey = 'quote_history';

  // Saves a quote and its image locally
  static Future<void> saveQuoteOffline(Map<String, dynamic> quoteData, String imageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_historyKey) ?? [];

    try {
      // 1. Download image bytes
      final response = await http.get(Uri.parse(imageUrl));

      // 2. Get local path using path_provider
      final directory = await getApplicationDocumentsDirectory();
      String filePath = '${directory.path}/img_${DateTime.now().millisecondsSinceEpoch}.png';

      // 3. Save image to disk
      File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // 4. Create record: "quoteText|authorName|localPath"
      String entry = "${quoteData['q']}|${quoteData['a']}|$filePath";
      history.insert(0, entry);

      // Inside saveQuoteOffline
      if (history.length >= 6) { // Use >= 6
        // Only delete if we actually have more than 6
        String oldPath = history.last.split('|')[2];
        File(oldPath).deleteSync();
        history.removeLast();
      }
      history.insert(0, entry); // Always insert at the top

      await prefs.setStringList(_historyKey, history);
    } catch (e) {
      print("Error in StorageService: $e");
    }
  }

  // Returns a random saved quote from the local storage
  static Future<Map<String, dynamic>?> getRandomOfflineQuote() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? history = prefs.getStringList(_historyKey);

    if (history != null && history.isNotEmpty) {
      final randomEntry = (history..shuffle()).first;
      final parts = randomEntry.split('|');
      return {
        'q': parts[0],
        'a': parts[1],
        'img': parts[2], // This is the local file path
      };
    }
    return null;
  }
}