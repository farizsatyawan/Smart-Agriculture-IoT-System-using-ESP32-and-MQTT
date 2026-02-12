class SensorData {
  int ldr;
  int soil;
  double temp;
  double humi;
  bool uv;
  bool pump;

  SensorData({
    required this.ldr,
    required this.soil,
    required this.temp,
    required this.humi,
    required this.uv,
    required this.pump,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      ldr: json['ldr'],
      soil: json['soil'],
      temp: json['temp'].toDouble(),
      humi: json['humi'].toDouble(),
      uv: json['uv'] == 1,
      pump: json['pump'] == 1,
    );
  }
}
