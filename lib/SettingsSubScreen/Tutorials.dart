import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class Tutorials extends StatefulWidget {
  const Tutorials({super.key});

  @override
  State<Tutorials> createState() => _TutorialsState();
}

class _TutorialsState extends State<Tutorials> {
  final List<Map<String, String>> steps = [
    {
      "title": "Navigate to Calibration",
      "desc": "Go to Calibrate Sensor in the Mobile App under Settings.",
    },
    {
      "title": "Prepare",
      "desc": "Rinse probe with distilled water and keep it wet at all times.",
    },
    {
      "title": "pH 7.0 Calibration",
      "desc":
          "Immerse in pH 7.0 buffer. Wait for the current pH voltage reading to stabilize, then click the Record pH 7.0 button.",
    },
    {
      "title": "pH 4.0 Calibration",
      "desc":
          "Rinse probe, immerse in pH 4.0 buffer. Wait for the current pH voltage reading to stabilize, then click the Record pH 4.0 button.",
    },
    {
      "title": "Save & Apply",
      "desc":
          "ESP32 calculates slope and intercept automatically and saves the settings. After that, click the Save Calibration button.",
    },
    {
      "title": "Verify",
      "desc": "Test again in buffers. Repeat calibration if readings are off.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "pH Sensor Calibration",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Lottie Animation
                // Lottie Animation (No Card)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.white],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  height: MediaQuery.of(context).size.height * 0.3,
                  width: double.infinity,
                  child: Lottie.asset(
                    "assets/Thinking.json",
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 20),

                Column(
                  children:
                      steps.asMap().entries.map((entry) {
                        int index = entry.key + 1;
                        var step = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.blueAccent,
                                child: Text(
                                  "$index",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                step["title"]!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                step["desc"]!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
