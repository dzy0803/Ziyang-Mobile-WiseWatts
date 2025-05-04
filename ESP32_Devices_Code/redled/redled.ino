#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

const char* WIFI_SSID = "9CD0 Hyperoptic 1Gb Fibre 2.4Ghz";
const char* WIFI_PASSWORD = "UaAxhKazjqbN";
const char* FIREBASE_API_KEY = "AIzaSyDenddHJArtBE-VPg4nyoSnzvpyZBnD6pY";
const char* USER_EMAIL = "dengziyang84@gmail.com";
const char* USER_PASSWORD = "123456";
const char* DEVICE_ID = "000000";

const int LED_PIN = 4;

String idToken = "";

void fetchDeviceStatus(const String& deviceId) {
  if (idToken == "") {
    Serial.println("❌ No ID token.");
    return;
  }

  WiFiClientSecure client;
  client.setInsecure();

  HTTPClient http;
  String url = "https://firestore.googleapis.com/v1/projects/wisewatts-5a0fa/databases/(default)/documents/devices/" + deviceId;
  http.begin(client, url);
  http.addHeader("Authorization", "Bearer " + idToken);

  int code = http.GET();
  String res = http.getString();

  Serial.printf("📥 Firestore GET Code: %d\n📦 Response: %s\n", code, res.c_str());

  if (code == 200) {
    StaticJsonDocument<2048> doc;
    DeserializationError error = deserializeJson(doc, res);
    if (!error) {
      bool isOnline = doc["fields"]["isOnline"]["booleanValue"];
      Serial.println(isOnline ? "💡 ONLINE (LED ON)" : "💤 OFFLINE (LED OFF)");
      digitalWrite(LED_PIN, isOnline ? HIGH : LOW);
    } else {
      Serial.println("❌ JSON parse error");
    }
  } else {
    Serial.println("❌ Firestore GET failed");
  }

  http.end();
}

void setup() {
  Serial.begin(115200);
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW); // 默认熄灭

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500); Serial.print(".");
  }
  Serial.println("\n✅ Connected to WiFi");

  WiFiClientSecure client;
  client.setInsecure();

  HTTPClient http;
  String url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=" + String(FIREBASE_API_KEY);
  http.begin(client, url);
  http.addHeader("Content-Type", "application/json");

  StaticJsonDocument<256> doc;
  doc["email"] = USER_EMAIL;
  doc["password"] = USER_PASSWORD;
  doc["returnSecureToken"] = true;

  String requestBody;
  serializeJson(doc, requestBody);

  Serial.println("📤 Sending login request...");
  int code = http.POST(requestBody);
  String res = http.getString();

  Serial.printf("🔁 HTTP Code: %d\n📨 Response: %s\n", code, res.c_str());

  if (code == 200) {
    StaticJsonDocument<1024> resDoc;
    deserializeJson(resDoc, res);
    idToken = resDoc["idToken"].as<String>();
    Serial.println("✅ Login successful, now fetching Firestore device status...");
    fetchDeviceStatus(DEVICE_ID);
  } else {
    Serial.println("❌ Login failed.");
  }

  http.end();
}

void loop() {
  // 可选：每隔一段时间自动查询状态
  delay(2000); // 10秒轮询
  fetchDeviceStatus(DEVICE_ID);
}

