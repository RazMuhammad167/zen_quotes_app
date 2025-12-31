// 1. Import the library
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

// 2. Use it in your saving logic
Future<void> _saveImageLocally(String imageUrl) async {
  try {
    // Get the response from the URL
    final response = await http.get(Uri.parse(imageUrl));

    // Find the safe folder on the phone
    final Directory directory = await getApplicationDocumentsDirectory();

    // Create a unique name for the image
    final String filePath = '${directory.path}/image_${DateTime.now().millisecondsSinceEpoch}.png';

    // Save the bytes to that path
    File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    print("Saved to: $filePath");
  } catch (e) {
    print("Error saving image: $e");
  }
}