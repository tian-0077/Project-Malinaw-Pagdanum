import 'dart:convert';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothManager {
  static final BluetoothManager _instance = BluetoothManager._internal();
  factory BluetoothManager() => _instance;
  BluetoothManager._internal();

  BluetoothConnection? _connection;
  Function(String)? _onDataReceived;

  bool get isConnected => _connection != null;

  Future<bool> connect() async {
    final bondedDevices =
        await FlutterBluetoothSerial.instance.getBondedDevices();
    final esp32 = bondedDevices.firstWhere((d) => d.name == "ESP32-Water",
        orElse: () => throw Exception("ESP32 not paired"));

    _connection = await BluetoothConnection.toAddress(esp32.address);
    _connection!.input!.listen((data) {
      final message = String.fromCharCodes(data).trim();
      if (_onDataReceived != null) _onDataReceived!(message);
    });
    return true;
  }

  void listen(Function(String) callback) {
    _onDataReceived = callback;
  }

  Future<void> send(String message) async {
    if (_connection != null) {
      _connection!.output.add(utf8.encode(message + "\n"));
      await _connection!.output.allSent;
    }
  }

  void disconnect() {
    _connection?.dispose();
    _connection = null;
  }
}
