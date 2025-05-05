#include <WiFi.h>
#include <HTTPClient.h>
#include <DHT.h>

// WiFi credentials
const char* ssid = "9CD0 Hyperoptic 1Gb Fibre 2.4Ghz";
const char* password = "UaAxhKazjqbN";

// Firebase Realtime Database (use your full URL + .json)
const char* firebaseHost = "https://wisewatts-5a0fa-default-rtdb.firebaseio.com/sensors/dht11_sensor.json";

// DHT settings
#define DHTPIN 4  // GPIO4 (D4)
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

void setup() {
  Serial.begin(115200);
  dht.begin();

  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\n✅ WiFi connected!");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
}

void loop() {
  float temperature = dht.readTemperature();
  float humidity = dht.readHumidity();

  if (isnan(temperature) || isnan(humidity)) {
    Serial.println("❌ Failed to read from DHT sensor!");
    delay(5000);
    return;
  }

  // Construct JSON payload
  String jsonPayload = "{\"temperature\": " + String(temperature) +
                       ", \"humidity\": " + String(humidity) + "}";

  // Send HTTP request
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(firebaseHost);  // HTTPS supported by ESP32
    http.addHeader("Content-Type", "application/json");

    int httpResponseCode = http.PUT(jsonPayload);
    Serial.print("HTTP Response code: ");
    Serial.println(httpResponseCode);

    String response = http.getString();
    Serial.println("Firebase Response: " + response);

    http.end();
  } else {
    Serial.println("WiFi Disconnected");
  }

  delay(5000);  // Upload every 5 sec
}
