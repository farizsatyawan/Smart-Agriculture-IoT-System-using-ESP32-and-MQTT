import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';

class Sensor {
  double temp;
  double humi;
  int ldr;
  int soil;
  bool uv;
  bool pump;

  Sensor({
    this.temp = 0,
    this.humi = 0,
    this.ldr = 0,
    this.soil = 0,
    this.uv = false,
    this.pump = false,
  });

  factory Sensor.fromJson(Map<String, dynamic> json) => Sensor(
        temp: (json['temp'] ?? 0).toDouble(),
        humi: (json['humi'] ?? 0).toDouble(),
        ldr: json['ldr'] ?? 0,
        soil: json['soil'] ?? 0,
        uv: (json['uv'] ?? 0) == 1,
        pump: (json['pump'] ?? 0) == 1,
      );

  Map<String, dynamic> toJson() => {
        'temp': temp,
        'humi': humi,
        'ldr': ldr,
        'soil': soil,
        'uv': uv ? 1 : 0,
        'pump': pump ? 1 : 0,
      };
}

class SensorProvider extends ChangeNotifier {
  // ---- Sensor Data ----
  Sensor sensor = Sensor();

  // ---- History for chart (last 20 values) ----
  final List<double> tempHistory = [];
  final List<double> humiHistory = [];
  final List<double> ldrHistory = [];
  final List<double> soilHistory = [];

  // ---- MQTT ----
  late MqttServerClient client;

  final String broker = '10.0.170.27';   
  final int port = 1883;
  final String topic = 'home/plant/sensor';

  bool connected = false;

  SensorProvider() {
    _connectMqtt();
  }

  // ---------------- MQTT CONNECT ----------------
  Future<void> _connectMqtt() async {
    client = MqttServerClient(broker, 'flutter_client');
    client.port = port;
    client.keepAlivePeriod = 20;
    client.logging(on: true);

    client.onDisconnected = _onDisconnected;

    final connMess = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    client.connectionMessage = connMess;

    try {
      await client.connect();
      connected = true;
      print("MQTT Connected");
    } catch (e) {
      print("MQTT Error: $e");
      client.disconnect();
      connected = false;
      return;
    }

    client.subscribe(topic, MqttQos.atMostOnce);

    // ---- Listen for data ----
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      try {
        final data = jsonDecode(payload);
        sensor = Sensor.fromJson(data);
        _addHistory(sensor);
        notifyListeners();
      } catch (e) {
        print("JSON Error: $e");
      }
    });
  }

  // ---------------- MQTT DISCONNECT ----------------
  void _onDisconnected() {
    connected = false;
    print('MQTT Disconnected');
  }

  // ---------------- HISTORY CHART ----------------
  void _addHistory(Sensor s) {
    tempHistory.add(s.temp);
    humiHistory.add(s.humi);
    ldrHistory.add(s.ldr.toDouble());
    soilHistory.add(s.soil.toDouble());

    if (tempHistory.length > 20) tempHistory.removeAt(0);
    if (humiHistory.length > 20) humiHistory.removeAt(0);
    if (ldrHistory.length > 20) ldrHistory.removeAt(0);
    if (soilHistory.length > 20) soilHistory.removeAt(0);
  }

  // ---------------- CONTROL UV & PUMP ----------------
  void toggleUv(bool val) {
    sensor.uv = val;
    _publish();
    notifyListeners();
  }

  void togglePump(bool val) {
    sensor.pump = val;
    _publish();
    notifyListeners();
  }

  // ---------------- PUBLISH COMMAND ----------------
  void _publish() {
    if (!connected) {
      print("MQTT Not Connected — cannot publish");
      return;
    }

    final message = jsonEncode(sensor.toJson());
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);

    print("Publish → $message");
  }
}
