import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class SensorGraphScreen extends StatefulWidget {
  const SensorGraphScreen({super.key});

  @override
  State<SensorGraphScreen> createState() => _SensorGraphScreenState();
}

class _SensorGraphScreenState extends State<SensorGraphScreen> {
  final FirebaseApp _firebaseApp = Firebase.app();
  late final DatabaseReference _database;

  List<FlSpot> temperaturePoints = [];
  List<FlSpot> tdsPoints = [];
  List<FlSpot> phPoints = [];
  List<FlSpot> turbidityPoints = [];

  int timeIndex = 0;

  String? selectedSensor;

  final List<String> sensors = ['Temperature', 'TDS', 'pH', 'Turbidity'];

  @override
  void initState() {
    super.initState();
    _database = FirebaseDatabase.instanceFor(
      app: _firebaseApp,
      databaseURL:
          'https://waterpotability-23eb7-default-rtdb.asia-southeast1.firebasedatabase.app/',
    ).ref('sensors');

    _database.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;

      setState(() {
        double temp = double.tryParse(data['temperature'].toString()) ?? 0;
        double tds = double.tryParse(data['tds'].toString()) ?? 0;
        double ph = double.tryParse(data['ph'].toString()) ?? 0;
        double turbidity = double.tryParse(data['turbidity'].toString()) ?? 0;

        temperaturePoints.add(FlSpot(timeIndex.toDouble(), temp));
        tdsPoints.add(FlSpot(timeIndex.toDouble(), tds));
        phPoints.add(FlSpot(timeIndex.toDouble(), ph));
        turbidityPoints.add(FlSpot(timeIndex.toDouble(), turbidity));

        if (temperaturePoints.length > 20) temperaturePoints.removeAt(0);
        if (tdsPoints.length > 20) tdsPoints.removeAt(0);
        if (phPoints.length > 20) phPoints.removeAt(0);
        if (turbidityPoints.length > 20) turbidityPoints.removeAt(0);

        timeIndex++;
      });
    });
  }

  List<FlSpot> getSelectedPoints() {
    switch (selectedSensor) {
      case 'Temperature':
        return temperaturePoints;
      case 'TDS':
        return tdsPoints;
      case 'pH':
        return phPoints;
      case 'Turbidity':
        return turbidityPoints;
      default:
        return [];
    }
  }

  Color getSelectedColor() {
    switch (selectedSensor) {
      case 'Temperature':
        return Colors.red;
      case 'TDS':
        return Colors.blue;
      case 'pH':
        return Colors.green;
      case 'Turbidity':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = getSelectedPoints();
    final lineColor = getSelectedColor();

    double minY =
        points.isNotEmpty
            ? points.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 2
            : 0;
    double maxY =
        points.isNotEmpty
            ? points.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 2
            : 10;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 10),

              Text(
                'GRAPH',
                style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(height: 30),
              Align(
                alignment: Alignment.centerLeft,
                child: DropdownButton<String>(
                  autofocus: true,
                  underline: Container(height: 2, color: Colors.green),
                  borderRadius: BorderRadius.circular(15),
                  hint: Text("Select sensors"),
                  value: selectedSensor,
                  items:
                      sensors.map((sensor) {
                        return DropdownMenuItem(
                          value: sensor,
                          child: Text(sensor),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedSensor = value;
                      });
                    }
                  },
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 80, 80, 80),
                    fontWeight: FontWeight.w700,
                  ),
                  iconEnabledColor: Colors.black,
                  dropdownColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: MediaQuery.of(context).size.height * 0.27,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: LineChart(
                  LineChartData(
                    minX: points.isNotEmpty ? points.first.x : 0,
                    maxX: points.isNotEmpty ? points.last.x : 10,
                    minY: minY < 0 ? 0 : minY,
                    maxY: maxY,

                    backgroundColor: Colors.transparent,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      drawHorizontalLine: true,
                      getDrawingHorizontalLine:
                          (value) => FlLine(
                            color: Colors.grey.shade300,
                            strokeWidth: 1,
                          ),
                      getDrawingVerticalLine:
                          (value) => FlLine(
                            color: Colors.grey.shade300,
                            strokeWidth: 1,
                          ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: 22,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 5,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: points,
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: lineColor,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              lineColor.withOpacity(0.4),
                              lineColor.withOpacity(0.05),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBorderRadius: BorderRadius.circular(8),
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        getTooltipColor: (spot) {
                          return Colors.black.withOpacity(0.8);
                        },
                        getTooltipItems: (spots) {
                          return spots.map((spot) {
                            return LineTooltipItem(
                              '${spot.y.toStringAsFixed(2)}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
