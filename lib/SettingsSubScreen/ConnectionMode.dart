import 'package:flutter/material.dart';
import 'package:water_quality/SettingsSubScreen/Calibration.dart';


class ConnectionModeScreen extends StatelessWidget {
  const ConnectionModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Connection Mode'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PHCalibrationScreen(
                        forcedMode: ConnectionMode.bluetooth,
                      ),
                    ),
                  );
                },
                child: const Text("Bluetooth Mode"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PHCalibrationScreen(
                        forcedMode: ConnectionMode.wifi,
                      ),
                    ),
                  );
                },
                child: const Text("WiFi Mode"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum ConnectionMode { bluetooth, wifi }
