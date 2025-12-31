import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Full Screen Background Gradient (Your Original Colors)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              ),
            ),
          ),

          // --- NEW: AMBIENT PARTICLE ANIMATION (Behind the Glass) ---
          Positioned(
            top: -50,
            left: -30,
            child: _buildAmbientOrb(Colors.white10, 200),
          ),
          Positioned(
            bottom: 100,
            right: -20,
            child: _buildAmbientOrb(Colors.blueAccent.withOpacity(0.1), 150),
          ),

          // 2. Large Centered Glass Card (Your Original Layout)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.75, // Covers 75% of height
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Branding Section
                        const Icon(
                          Icons.format_quote_rounded,
                          size: 110,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 30),
                        Text(
                          "ZenQuotes",
                          style: GoogleFonts.poppins(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "Your Journey Begins Here",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                        const Spacer(), // Pushes the bottom content down

                        // Loading Indicator
                        const SpinKitDoubleBounce(
                          color: Colors.white,
                          size: 50.0,
                        ),

                        const Spacer(),

                        // The Action Button (Your Original Logic)
                        GestureDetector(
                          onTap: _navigateToHome,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "GET STARTED",
                                  style: GoogleFonts.poppins(
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.deepPurple,
                                ),
                              ],
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
        ],
      ),
    );
  }

  // --- PARTICLE HELPER ---
  Widget _buildAmbientOrb(Color color, double size) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(seconds: 4),
      curve: Curves.easeInOut,
      builder: (context, double value, child) {
        return Opacity(
          opacity: 0.5,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color,
                  blurRadius: 50 + (value * 20),
                  spreadRadius: 20 + (value * 10),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}