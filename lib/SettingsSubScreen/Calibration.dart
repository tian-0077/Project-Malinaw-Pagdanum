import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:water_quality/SettingsSubScreen/ConnectionMode.dart';
import 'dart:typed_data';
import 'BT.dart';

import 'package:shared_preferences/shared_preferences.dart';

class PHCalibrationScreen extends StatefulWidget {
  final ConnectionMode? forcedMode; 

  const PHCalibrationScreen({super.key, this.forcedMode});

  @override
  State<PHCalibrationScreen> createState() => _PHCalibrationScreenState();
}


class _PHCalibrationScreenState extends State<PHCalibrationScreen> {

  final _dbRef =
      FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            "https://waterpotability-23eb7-default-rtdb.asia-southeast1.firebasedatabase.app",
      ).ref();

  late DatabaseReference _phVoltageRef;
  StreamSubscription<DatabaseEvent>? _phVoltageSubscription;

 
  double? phVoltage;
  bool _loading = true;
  bool _useBluetooth = false;

  double? v7;
  double? v4;

  final slopeController = TextEditingController();
  final interceptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initDataSource();
  }

 
  Future<void> _initDataSource() async {
  setState(() => _loading = true);

  if (widget.forcedMode == ConnectionMode.bluetooth) {
    try {
      await _connectBluetooth();
    } catch (_) {
      setState(() {
        _loading = false;
        _useBluetooth = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bluetooth connection failed")));
    }
    return;
  }

  if (widget.forcedMode == ConnectionMode.wifi) {
    try {
      await _connectFirebase();
    } catch (_) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("WiFi connection failed")));
    }
    return;
  }

  
  try {
    await _connectBluetooth();
  } catch (_) {
    await _connectFirebase();
  }
}

Future<void> _connectFirebase() async {
  try {
    final snap = await _dbRef.child('sensors/ph_voltage').get().timeout(
          const Duration(seconds: 2),
        );

    if (snap.exists) {
      _phVoltageRef = _dbRef.child('sensors/ph_voltage');
      _phVoltageSubscription?.cancel();
      _phVoltageSubscription = _phVoltageRef.onValue.listen((event) {
        final value = event.snapshot.value;
        setState(() {
          phVoltage =
              value != null ? double.tryParse(value.toString()) : null;
          _useBluetooth = false;
          _loading = false;
        });
      });

      await fetchCalibrationValues();
    } else {
      throw Exception("No Firebase data found");
    }
  } catch (err) {
    print(" Firebase unavailable: $err");
    setState(() => _loading = false);
  }
}


Future<void> _connectBluetooth() async {
  bool connected = await BluetoothManager().connect();

  if (!connected) throw Exception("Bluetooth connection failed");

  
  setState(() {
    _useBluetooth = true;
    _loading = false;
  });

  final prefs = await SharedPreferences.getInstance();
  final savedSlope = prefs.getDouble("ph_slope");
  final savedIntercept = prefs.getDouble("ph_intercept");

  if (savedSlope != null && savedIntercept != null) {
    slopeController.text = savedSlope.toStringAsFixed(6);
    interceptController.text = savedIntercept.toStringAsFixed(6);

    
    await BluetoothManager().send(
      jsonEncode({"slope": savedSlope, "intercept": savedIntercept}),
    );
  }

 
  BluetoothManager().listen((message) {
    try {
      final decoded = jsonDecode(message);
      setState(() {
        phVoltage = decoded["ph_voltage"] != null
            ? decoded["ph_voltage"] * 1.0
            : null;
      });
    } catch (_) {}
  });
}





  Future<void> fetchCalibrationValues() async {
    final slopeSnap = await _dbRef.child('settings/ph_calibration/slope').get();
    final interceptSnap =
        await _dbRef.child('settings/ph_calibration/intercept').get();

    if (slopeSnap.exists && interceptSnap.exists) {
      setState(() {
        slopeController.text = slopeSnap.value.toString();
        interceptController.text = interceptSnap.value.toString();
      });
    }
  }

  void recordV7() {
    if (phVoltage != null) {
      setState(() => v7 = phVoltage);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('pH 7.0 voltage recorded')));
    }
  }

  void recordV4() {
    if (phVoltage != null) {
      setState(() {
        v4 = phVoltage;
        if (v7 != null) {
          final slope = (4.0 - 7.0) / (v4! - v7!);
          final intercept = 7.0 - slope * v7!;
          slopeController.text = slope.toStringAsFixed(6);
          interceptController.text = intercept.toStringAsFixed(6);
        }
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('pH 4.0 voltage recorded')));
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.black.withOpacity(0.2)),
              ),
              Center(
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: SizedBox(
                    height: 300,
                    width: 300,
                    child: Lottie.asset(
                      'assets/Updateapp.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

Future<void> saveCalibration() async {
  final slope = double.tryParse(slopeController.text);
  final intercept = double.tryParse(interceptController.text);

  if (slope != null && intercept != null) {
    _showLoadingDialog();

    if (_useBluetooth && BluetoothManager().isConnected) {
    
      final jsonData = jsonEncode({"slope": slope, "intercept": intercept});
      await BluetoothManager().send(jsonData); 

      print("Sent via BT: $jsonData");

    
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble("ph_slope", slope);
      await prefs.setDouble("ph_intercept", intercept);
      print("Saved locally: slope=$slope, intercept=$intercept");
    } else {
     
      await _dbRef.child('settings/ph_calibration').update({
        'slope': slope,
        'intercept': intercept,
      });
    }

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('pH calibration updated')));
      Navigator.pop(context);
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid input')));
  }
}


 @override
void dispose() {
  slopeController.dispose();
  interceptController.dispose();
  _phVoltageSubscription?.cancel();

  super.dispose();
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _useBluetooth ? "Calibration (BT Mode)" : "Calibration (WiFi Mode)",
          style: GoogleFonts.poppins(color: Colors.black),
        ),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Lottie.asset(
                      'assets/GreyRepairman.json',
                      width: MediaQuery.of(context).size.width * 0.90,
                      height: MediaQuery.of(context).size.height * 0.40,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Current pH Voltage: ${phVoltage != null ? "${phVoltage!.toStringAsFixed(3)} V" : "Unavailable"}",
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: recordV7,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Record pH 7.0',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: recordV4,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Record pH 4.0',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    _buildRoundedTextField(
                      controller: slopeController,
                      label: "Slope",
                      readOnly: true,
                    ),
                    const SizedBox(height: 20),
                    _buildRoundedTextField(
                      controller: interceptController,
                      label: "Intercept",
                      readOnly: true,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: saveCalibration,
                        child: Text(
                          'Save Calibration',
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildRoundedTextField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 13,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.grey, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
      ),
    );
  }
}
