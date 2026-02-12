import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/sensor_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant IoT Dashboard'),
        centerTitle: true,
      ),
      body: Consumer<SensorProvider>(
        builder: (context, sensorProvider, child) {
          final sensor = sensorProvider.sensor;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Sensor Status ----
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statusTile('LDR', sensor.ldr.toString(), sensor.ldr > 2000 ? Colors.red : Colors.green),
                            _statusTile('Soil', sensor.soil.toString(), sensor.soil > 3000 ? Colors.red : Colors.green),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statusTile('Temp', '${sensor.temp.toStringAsFixed(1)}°C', Colors.orange),
                            _statusTile('Humi', '${sensor.humi.toStringAsFixed(1)}%', Colors.blue),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statusTile('UV', sensor.uv ? 'ON' : 'OFF', sensor.uv ? Colors.green : Colors.grey),
                            _statusTile('Pump', sensor.pump ? 'ON' : 'OFF', sensor.pump ? Colors.green : Colors.grey),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ---- Charts ----
                Text('Charts (Last 20 values)', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),

                _buildLineChart('Temperature', sensorProvider.tempHistory, Colors.orange),
                const SizedBox(height: 12),
                _buildLineChart('Humidity', sensorProvider.humiHistory, Colors.blue),
                const SizedBox(height: 12),
                _buildLineChart('LDR', sensorProvider.ldrHistory, Colors.red),
                const SizedBox(height: 12),
                _buildLineChart('Soil', sensorProvider.soilHistory, Colors.green),

                const SizedBox(height: 20),

                // ---- Control Switches ----
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Control', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text('UV Light'),
                                Switch(
                                  value: sensor.uv,
                                  onChanged: (val) => sensorProvider.toggleUv(val),
                                  activeColor: Colors.green,
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Text('Pump'),
                                Switch(
                                  value: sensor.pump,
                                  onChanged: (val) => sensorProvider.togglePump(val),
                                  activeColor: Colors.green,
                                ),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---- Helper Widget: Status Tile ----
  Widget _statusTile(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ),
      ],
    );
  }

  // ---- Helper Widget: Line Chart ----
  Widget _buildLineChart(String title, List<double> values, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 19,
                  minY: values.isEmpty ? 0 : values.reduce((a,b) => a<b?a:b) - 5,
                  maxY: values.isEmpty ? 100 : values.reduce((a,b) => a>b?a:b) + 5,
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: values.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
