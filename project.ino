#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <DHT.h>
#include <WiFi.h>
#include <PubSubClient.h>  // MQTT client

// ---- WIFI & MQTT CONFIG ----
const char* ssid = "Mahasiswa";
const char* password = "@Keretacepat2023";
const char* mqttServer = "10.0.170.27"; // IP broker MQTT di PC/laptop
const int mqttPort = 1883;
const char* mqttTopic = "home/plant/sensor";

WiFiClient espClient;
PubSubClient client(espClient);

// ---- PINS ----
#define LDR_PIN      34
#define SOIL_PIN     35
#define RELAY_UV_PIN 17
#define RELAY_PUMP_PIN 32
#define LCD_ADDR     0x27
#define DHT_PIN      27
#define DHT_TYPE     DHT22

LiquidCrystal_I2C lcd(LCD_ADDR, 16, 2);
DHT dht(DHT_PIN, DHT_TYPE);

// ---- CONFIG ----
const bool RELAY_ACTIVE_LOW = true;
const int LDR_THRESHOLD = 2000;   
const int SOIL_THRESHOLD = 3000;  
const int HUMIDITY_THRESHOLD = ; 

int relayOnState, relayOffState;
unsigned long lastSwitch = 0;
bool showMainScreen = true;
bool uvLatched = false;

void setup() {
  Serial.begin(115200);
  Wire.begin();
  dht.begin();
  lcd.init();
  lcd.backlight();
  lcd.clear();
  lcd.print("System Ready");
  delay(800);
  lcd.clear();

  pinMode(RELAY_UV_PIN, OUTPUT);
  pinMode(RELAY_PUMP_PIN, OUTPUT);
  if (RELAY_ACTIVE_LOW) {
    relayOnState = LOW;
    relayOffState = HIGH;
  } else {
    relayOnState = HIGH;
    relayOffState = LOW;
  }
  digitalWrite(RELAY_UV_PIN, relayOffState);
  digitalWrite(RELAY_PUMP_PIN, relayOffState);

  // ---- WIFI ----
  WiFi.begin(ssid, password);
  lcd.print("Connecting WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("WiFi connected");
  lcd.clear();
  lcd.print("WiFi Connected");

  // ---- MQTT ----
  client.setServer(mqttServer, mqttPort);
  while (!client.connected()) {
    Serial.println("Connecting MQTT...");
    if (client.connect("ESP32Plant")) {
      Serial.println("MQTT Connected");
    } else {
      Serial.print("Failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 2s");
      delay(2000);
    }
  }
}

void loop() {
  if (!client.connected()) {
    while (!client.connected()) {
      Serial.println("Reconnecting MQTT...");
      if (client.connect("ESP32Plant")) {
        Serial.println("MQTT Connected");
      } else {
        delay(2000);
      }
    }
  }
  client.loop();

  // ---- SENSOR READ ----
  int ldr  = analogRead(LDR_PIN);
  int soil = analogRead(SOIL_PIN);
  float h = dht.readHumidity();
  float t = dht.readTemperature();

  // ---- UV Control (AND + latch) ----
  bool isGelap = (ldr >= LDR_THRESHOLD);
  bool isLembab = (!isnan(h) && h > HUMIDITY_THRESHOLD);
  bool uvTrigger = isGelap && isLembab;
  if (uvTrigger) uvLatched = true;
  else if (!isGelap && !isLembab) uvLatched = false;
  digitalWrite(RELAY_UV_PIN, uvLatched ? relayOnState : relayOffState);
  bool uvIsOn = (digitalRead(RELAY_UV_PIN) == relayOnState);

  // ---- Pump Control ----
  bool isKering = (soil > SOIL_THRESHOLD);
  digitalWrite(RELAY_PUMP_PIN, isKering ? relayOnState : relayOffState);
  bool pumpIsOn = (digitalRead(RELAY_PUMP_PIN) == relayOnState);

  // ---- LCD UPDATE ----
  if (millis() - lastSwitch >= 1500) {
    lastSwitch = millis();
    showMainScreen = !showMainScreen;
    lcd.clear();
  }
  if (showMainScreen) {
    lcd.setCursor(0,0);
    lcd.print(isGelap ? "C:GELAP " : "C:TERANG");
    lcd.setCursor(9,0);
    lcd.print(uvIsOn ? "UV:ON" : "UV:OFF");
    lcd.setCursor(0,1);
    lcd.print(isKering ? "T:KERING" : "T:BASAH ");
    lcd.setCursor(9,1);
    lcd.print(pumpIsOn ? "P:ON " : "P:OFF");
  } else {
    lcd.setCursor(0,0);
    lcd.print("Temp:");
    lcd.print(!isnan(t) ? t : 0);
    lcd.print("C");
    lcd.setCursor(0,1);
    lcd.print("Humi:");
    lcd.print(!isnan(h) ? h : 0);
    lcd.print("%");
  }

  // ---- SERIAL DEBUG ----
  Serial.print("LDR="); Serial.print(ldr);
  Serial.print(" | Soil="); Serial.print(soil);
  Serial.print(" | Temp="); Serial.print(t);
  Serial.print(" | Humi="); Serial.print(h);
  Serial.print(" | UV="); Serial.print(uvIsOn);
  Serial.print(" | Pump="); Serial.println(pumpIsOn);

  // ---- KIRIM DATA KE MQTT ----
  String payload = "{";
  payload += "\"ldr\":" + String(ldr) + ",";
  payload += "\"soil\":" + String(soil) + ",";
  payload += "\"temp\":" + String(t) + ",";
  payload += "\"humi\":" + String(h) + ",";
  payload += "\"uv\":" + String(uvIsOn ? 1 : 0) + ",";
  payload += "\"pump\":" + String(pumpIsOn ? 1 : 0);
  payload += "}";
  client.publish(mqttTopic, payload.c_str());

  delay(1000);
}
