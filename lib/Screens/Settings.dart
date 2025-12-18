import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:water_quality/SettingsSubScreen/Calibration.dart';
import 'package:water_quality/SettingsSubScreen/ConnectionMode.dart';
import 'package:water_quality/SettingsSubScreen/Tutorials.dart';
import 'package:water_quality/SettingsSubScreen/Wifi.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final _dbRef =
      FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            "https://waterpotability-23eb7-default-rtdb.asia-southeast1.firebasedatabase.app",
      ).ref();

  // Show input dialog for WiFi credentials
  Future<void> updateWiFiCredentials() async {
    final ssidController = TextEditingController();
    final passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Enter WiFi Credentials"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ssidController,
                  decoration: const InputDecoration(labelText: 'SSID'),
                ),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text("Save"),
                onPressed: () async {
                  final ssid = ssidController.text.trim();
                  final password = passwordController.text.trim();

                  if (ssid.isNotEmpty && password.isNotEmpty) {
                    await _dbRef.child('settings/wifi').update({
                      'ssid': ssid,
                      'password': password,
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('WiFi credentials updated')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in all fields'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              'SETTINGS',
              style: GoogleFonts.poppins(
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PHCalibrationScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFFCDFFDD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ).copyWith(
                  elevation: WidgetStateProperty.all(0), // pressed state
                  shadowColor: WidgetStateProperty.all(Colors.transparent),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Calibrate sensor.',
                      style: TextStyle(color: Colors.black),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.black),
                  ],
                ),
              ),
            ),
            const Divider(height: 5, color: Colors.black),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Tutorials()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFFCDFFDD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ).copyWith(
                  elevation: WidgetStateProperty.all(0), // pressed state
                  shadowColor: WidgetStateProperty.all(Colors.transparent),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tutorials for calibration.',
                      style: TextStyle(color: Colors.black),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.black),
                  ],
                ),
              ),
            ),
            const Divider(height: 5, color: Colors.black),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WiFiConfigScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCDFFDD),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ).copyWith(
                  elevation: WidgetStateProperty.all(0),
                  shadowColor: WidgetStateProperty.all(Colors.transparent),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Change WIFI credentials.',
                      style: TextStyle(color: Colors.black),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.black),
                  ],
                ),
              ),
            ),
            const Divider(height: 5, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
