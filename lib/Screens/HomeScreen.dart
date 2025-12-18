import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gauge_indicator/gauge_indicator.dart';
import 'package:lottie/lottie.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:convert';
import 'dart:async';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String _connectionStatus = 'Checking network...';
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  // Bluetooth Classic
  BluetoothConnection? _connection;
  String _btBuffer = "";

  bool isWaterPotable(double temp, double tds, double ph, double turbidity) {
    if (temp < 10 || temp > 40) return false;
    if (tds > 300) return false;
    if (ph < 6.5 || ph > 8.5) return false;
    if (turbidity > 5) return false;
    return true;
  }

  Future<void> _connectToBluetooth() async {
  try {
    
    List<BluetoothDevice> devices =
        await FlutterBluetoothSerial.instance.getBondedDevices();

   
    BluetoothDevice? esp32 = devices.firstWhere(
      (d) => d.name == "ESP32-Water", 
      orElse: () => throw Exception("ESP32 not found"),
    );

    
    _connection = await BluetoothConnection.toAddress(esp32.address);
    print("✅ Connected to ESP32");
    setState(() {
      _connectionStatus = "Connected via Bluetooth to ESP32";
    });

    _connection!.input!.listen((data) {
      _btBuffer += utf8.decode(data);

      if (_btBuffer.trim().endsWith("}")) {
        try {
          Map<String, dynamic> parsed = jsonDecode(_btBuffer.trim());
          _btBuffer = "";

          setState(() {
            _temperature =
                double.tryParse(parsed['temperature'].toString()) ?? 0.0;
            _tds = double.tryParse(parsed['tds'].toString()) ?? 0.0;
            _ph = double.tryParse(parsed['ph'].toString()) ?? 0.0;
            _turbidity =
                double.tryParse(parsed['turbidity'].toString()) ?? 0.0;
            _orp = double.tryParse(parsed['orp'].toString()) ?? 0.0;
          });
        } catch (e) {
          print("Parse error: $e");
          _btBuffer = "";
        }
      }
    }).onDone(() async {
      print(" Disconnected from ESP32");
      setState(() {
        _connectionStatus = "Bluetooth disconnected. Reconnecting...";
      });

      
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        _connectToBluetooth();
      }
    });
  } catch (e) {
    print("⚠️ Bluetooth error: $e");
    setState(() {
      _connectionStatus = "Bluetooth connection failed. Retrying...";
    });

    // Retry after 5 seconds
    await Future.delayed(const Duration(seconds: 5));
    if (mounted) _connectToBluetooth();
  }
}


  void showTestDialog() {
    int currentIndex = 0;
    bool? isPotable;
    bool testStarted = false;
    bool testComplete = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> startTest() async {
              for (int i = 0; i < sensorValues.length; i++) {
                if (!context.mounted) return;
                await Future.delayed(const Duration(seconds: 1));
                setState(() {
                  currentIndex = i;
                });
              }

              if (!context.mounted) return;
              setState(() {
                isPotable = isWaterPotable(_temperature, _tds, _ph, _turbidity);
                testComplete = true;
              });
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!testStarted) {
                testStarted = true;
                startTest();
              }
            });

            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: const Text('Water Quality Test'),
              content: SizedBox(
                height: 250,
                child: Center(
                  child: testComplete
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Lottie.asset(
                              isPotable!
                                  ? 'assets/dialog/Success.json'
                                  : 'assets/dialog/Errorfailure.json',
                              width: 200,
                              height: 200,
                              repeat: false,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              isPotable!
                                  ? 'Water is potable.'
                                  : 'Water is NOT potable.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Testing ${labels[currentIndex]}...',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 20),
                            AnimatedRadialGauge(
                              key: ValueKey(currentIndex),
                              initialValue: 0,
                              value: sensorValues[currentIndex],
                              duration: const Duration(milliseconds: 1200),
                              curve: Curves.easeInOutCubic,
                              radius: 90,
                              axis: GaugeAxis(
                                min: minValues[currentIndex],
                                max: maxValues[currentIndex],
                                degrees: 260,
                                style: const GaugeAxisStyle(
                                  thickness: 40,
                                  background: Colors.grey,
                                ),
                                progressBar: GaugeProgressBar.rounded(
                                  color: Colors.green,
                                ),
                                pointer: GaugePointer.needle(
                                  borderRadius: 8,
                                  width: 10,
                                  height: 40,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              actions: [
                Align(
                  alignment: Alignment.center,
                  child: testComplete
                      ? TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        )
                      : const SizedBox(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  double _previousValue = 0.0;

  
  double _temperature = 0.0;
  double _tds = 0.0;
  double _ph = 0.0;
  double _turbidity = 0.0;
  double _orp = 0.0;

  late DatabaseReference _database;

  @override
  void initState() {
    super.initState();

    _database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://waterpotability-23eb7-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).ref();
    _listenToSensorValues();

    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      setState(() {
        switch (result) {
          case ConnectivityResult.wifi:
            _connectionStatus = 'Connected via Wi-Fi';
            _listenToSensorValues(); 
            break;
          case ConnectivityResult.mobile:
            _connectionStatus = 'Connected via Mobile Data';
            _listenToSensorValues(); 
            break;
          case ConnectivityResult.none:
            _connectionStatus = 'No internet. Switching to Bluetooth...';
            _connectToBluetooth(); 
            break;
          default:
            _connectionStatus = 'Checking connection...';
        }
      });
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _connection?.dispose();
    super.dispose();
  }

  void _listenToSensorValues() {
    _database.child('sensors').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _temperature = double.tryParse(data['temperature'].toString()) ?? 0.0;
        _tds = double.tryParse(data['tds'].toString()) ?? 0.0;
        _ph = double.tryParse(data['ph'].toString()) ?? 0.0;
        _turbidity = double.tryParse(data['turbidity'].toString()) ?? 0.0;
        _orp = double.tryParse(data['orp'].toString()) ?? 0.0;
      });
    });
  }

  
  String getWaterQualityStatus(int index, double value) {
    switch (index) {
      case 0:
        if (value < 10 || value > 40) return "Poor";
        return "Good";
      case 1:
        if (value > 300) return "Poor";
        return "Good";
      case 2:
        if (value < 6.5 || value > 8.5) return "Poor";
        return "Good";
      case 3:
        if (value > 5) return "Poor";
        return "Good";
      default:
        return "Unknown";
    }
  }

  final List<IconData> icons = [
    Icons.water,
    Icons.thermostat,
    Icons.eco,
    Icons.opacity,
    Icons.bolt,
  ];
  final List<String> labels = [
    'Temp(°C)',
    'TDS(PPM)',
    'PH Level',
    'Turbidity',
    'ORP(mV)',
  ];
  List<double> get sensorValues =>
      [_temperature, _tds, _ph, _turbidity, _orp];

  final List<double> minValues = [0, 0, 0, 0, 0];
  final List<double> maxValues = [50, 500, 14, 1000, 1000];

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    String currentLabel = labels[_selectedIndex];
    double currentValue = sensorValues[_selectedIndex];
    String status = getWaterQualityStatus(_selectedIndex, currentValue);
    Color statusColor = status == "Good" ? const Color(0xFF005913) : Colors.red;

    double minValue = minValues[_selectedIndex];
    double maxValue = maxValues[_selectedIndex];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Text(
              'HOME',
              style: GoogleFonts.poppins(
                textStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 50),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Project MALINAW PAGDANUM',
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Text(
                    _connectionStatus,
                    style: GoogleFonts.poppins(
                      textStyle: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        color: Theme.of(context).secondaryHeaderColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                AnimatedRadialGauge(
                  key: ValueKey(_selectedIndex),
                  initialValue: _previousValue,
                  duration: const Duration(milliseconds: 1500),
                  alignment: Alignment.center,
                  value: currentValue,
                  debug: false,
                  radius: 150,
                  curve: Curves.fastOutSlowIn,
                  axis: GaugeAxis(
                    min: minValue,
                    max: maxValue,
                    degrees: 270,
                    style: const GaugeAxisStyle(
                      thickness: 55,
                      background: Colors.white60,
                      blendColors: true,
                      cornerRadius: Radius.circular(50),
                      segmentSpacing: 4,
                    ),
                    progressBar: GaugeProgressBar.rounded(
                      color: const Color(0xFF2A7F3C),
                    ),
                    pointer: GaugePointer.needle(
                      borderRadius: 16,
                      width: 30,
                      height: 70,
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      currentValue.toStringAsFixed(2),
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      ' $currentLabel',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  text: '$currentLabel Quality :',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(fontWeight: FontWeight.w300),
                  ),
                  children: [
                    TextSpan(
                      text: ' $status',
                      style: GoogleFonts.poppins(
                        textStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(5, (index) {
                    bool isSelected = _selectedIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _previousValue = sensorValues[_selectedIndex];
                          _selectedIndex = index;
                        });
                      },
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.18,
                        width: MediaQuery.of(context).size.width * 0.27,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 1,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.green,
                                  ),
                                  height: 43,
                                  width: 40,
                                  child: Icon(
                                    icons[index],
                                    color: isSelected
                                        ? Colors.green
                                        : Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                Text(
                                  labels[index],
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  sensorValues[index].toStringAsFixed(2),
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.45,
              height: 45,
              child: ElevatedButton(
                onPressed: () {
                  showTestDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Test water quality',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
