import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for Copy
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart'; // Added for Share
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Added for Notifications
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../services/storage_service.dart'; // For storage path

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Store the future so we can reset it easily
  late Future<Map<String, dynamic>> _quoteFuture;

  // Added this variable to change the image dynamically
  String _currentImageUrl = 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?q=80&w=2074';

  // Notification Plugin Instance
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _quoteFuture = fetchQuote();
    _initNotifications(); // Initialize 8 AM Notification
  }

  // --- NEW: NOTIFICATION LOGIC ---
  Future<void> _initNotifications() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notificationsPlugin.initialize(const InitializationSettings(android: androidSettings));
    _scheduleDailyNotification();
  }

  Future<void> _scheduleDailyNotification() async {
    await _notificationsPlugin.zonedSchedule(
      0,
      'Daily Wisdom',
      'Your daily quote is ready!',
      _nextInstanceOfEightAM(),
      const NotificationDetails(
        android: AndroidNotificationDetails('zen_quotes_id', 'Daily Quotes',
            importance: Importance.max, priority: Priority.high),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfEightAM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 8);
    if (scheduledDate.isBefore(now)) scheduledDate = scheduledDate.add(const Duration(days: 1));
    return scheduledDate;
  }

  // --- CACHE LOGIC ---
  // Saves the quote to local storage
  Future<void> _saveQuoteToCache(Map<String, dynamic> quoteData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_q', quoteData['q']);
    await prefs.setString('cached_a', quoteData['a']);

    // INTEGRATED: Save to StorageService for the 5-6 quote logic
    await StorageService.saveQuoteOffline(quoteData, _currentImageUrl);
  }

  // Loads the quote from local storage if internet fails
  Future<Map<String, dynamic>> _loadQuoteFromCache() async {
    // INTEGRATED: Try loading one of the 5-6 saved quotes with images first
    final offlineData = await StorageService.getRandomOfflineQuote();

    if (offlineData != null) {
      setState(() {
        _currentImageUrl = offlineData['img']; // This is the local file path
      });
      return {'q': offlineData['q'], 'a': offlineData['a']};
    }

    // Original fallback logic if StorageService is empty
    final prefs = await SharedPreferences.getInstance();
    final String? q = prefs.getString('cached_q');
    final String? a = prefs.getString('cached_a');

    if (q != null && a != null) {
      return {'q': q, 'a': a};
    }
    throw Exception('No Internet and No Cache Available');
  }

  // High-level API call with Timeout, Error Handling, and Cache Fallback
  Future<Map<String, dynamic>> fetchQuote() async {
    try {
      // 1. Try to get new quote from Internet
      final response = await http
          .get(Uri.parse('https://zenquotes.io/api/random'))
          .timeout(const Duration(seconds: 5)); // Short timeout for faster offline switch

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final quoteData = data[0] as Map<String, dynamic>;

        // Save it to your 6-item cache
        await StorageService.saveQuoteOffline(quoteData, _currentImageUrl);

        return quoteData;
      } else {
        throw Exception("Server Error");
      }
    } catch (e) {
      // 2. INTERNET FAILED -> Go to Offline Cache
      debugPrint("Network failed, looking for offline data...");

      final offlineData = await StorageService.getRandomOfflineQuote();

      if (offlineData != null) {
        // Very Important: Update the UI variable to the local file path
        setState(() {
          _currentImageUrl = offlineData['img'];
        });
        return {'q': offlineData['q'], 'a': offlineData['a']};
      } else {
        throw Exception('Connect to internet once to save quotes!');
      }
    }
  }
  void _refresh() {
    setState(() {
      _quoteFuture = fetchQuote();
      // FIX: Using a random integer between 1 and 1000 for the ID
      // This forces the server to pick a different image from its library
      int randomId = DateTime.now().millisecond;
      _currentImageUrl = 'https://picsum.photos/id/$randomId/1080/1920';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image (Updated to handle local files and network)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: _currentImageUrl.startsWith('http')
                    ? NetworkImage(_currentImageUrl) // Use Internet
                    : FileImage(File(_currentImageUrl)) as ImageProvider, // Use Saved File
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 2. Dark Layer for Contrast
          Container(color: Colors.black.withOpacity(0.4)),

          // 3. Main Content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                // --- NEW OUTER GLASS CARD FOR WHOLE CONTENT ---
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Keeps the container compact
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // --- 1. MAIN QUOTE CARD (With Fixed Size SizedBox) ---
                          ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Container(
                                // FIXING THE SIZE HERE so it doesn't move
                                width: double.infinity,
                                height: 280,
                                padding: const EdgeInsets.all(35),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: FutureBuilder<Map<String, dynamic>>(
                                  future: _quoteFuture,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                                    } else if (snapshot.hasError) {
                                      return Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 50),
                                          const SizedBox(height: 15),
                                          Text("Oops! No Internet", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                                          TextButton(onPressed: _refresh, child: const Text("Try Again", style: TextStyle(color: Colors.cyanAccent))),
                                        ],
                                      );
                                    } else {
                                      final String q = snapshot.data!['q'];
                                      final String a = snapshot.data!['a'];
                                      return Column(
                                        mainAxisAlignment: MainAxisAlignment.center, // Center text inside the fixed box
                                        children: [
                                          const Icon(Icons.format_quote_rounded, color: Colors.white54, size: 40),
                                          const SizedBox(height: 10),
                                          // SingleChildScrollView ensures long quotes don't break the fixed height
                                          Expanded(
                                            child: SingleChildScrollView(
                                              child: Text(
                                                q,
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          Text("- $a", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70, fontStyle: FontStyle.italic)),
                                        ],
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // --- 2. ALONE ACTION CARD ---
                          FutureBuilder<Map<String, dynamic>>(
                            future: _quoteFuture,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const SizedBox.shrink();
                              final String q = snapshot.data!['q'];
                              final String a = snapshot.data!['a'];
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 55, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.copy, color: Colors.white70),
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: "$q - $a"));
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quote copied!")));
                                          },
                                        ),
                                        const SizedBox(width: 10),
                                        IconButton(
                                          icon: const Icon(Icons.share, color: Colors.white70),
                                          onPressed: () => Share.share('"$q" - $a'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 30),

                          // --- 3. GLASS REFRESH BUTTON ---
                          ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: GestureDetector(
                                onTap: _refresh,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(50),
                                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.refresh, color: Colors.white),
                                      const SizedBox(width: 10),
                                      Text("FRESH RELOAD", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}