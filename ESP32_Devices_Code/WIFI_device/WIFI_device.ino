#include <WiFi.h>
#include <WebServer.h>

WebServer server(80);

void setup() {
  Serial.begin(115200);
  WiFi.softAP("Arduino_Nano_ESP32");

  server.on("/register", HTTP_POST, []() {
    if (server.hasArg("name")) {
      String name = server.arg("name");
      Serial.println("Device name: " + name);
      server.send(200, "application/json", "{\"status\":\"success\"}");
    } else {
      server.send(400, "application/json", "{\"status\":\"missing_name\"}");
    }
  });

  server.begin();
}

void loop() {
  server.handleClient();
}
