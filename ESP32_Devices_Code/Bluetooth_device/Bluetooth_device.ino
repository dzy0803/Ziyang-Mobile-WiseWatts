#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

#define SERVICE_UUID        "12345678-1234-5678-1234-56789abcdef0"
#define CHARACTERISTIC_UUID "abcd1234-abcd-1234-abcd-123456789abc"

BLEServer* pServer = nullptr;
BLECharacteristic* pCharacteristic = nullptr;
bool deviceConnected = false;

// Global variables to store received data
String receivedDeviceId = "";
String receivedCustomName = "";
bool dataReceived = false;

class MyCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pCharacteristic) override {
    String value = pCharacteristic->getValue();

    if (value.length() > 0) {
      Serial.println("Received BLE Data:");
      Serial.println(value);  // Expected: deviceId::customName

      int sepIndex = value.indexOf("::");
      if (sepIndex != -1) {
        receivedDeviceId = value.substring(0, sepIndex);
        receivedCustomName = value.substring(sepIndex + 2);
        dataReceived = true;  // Trigger for loop()
      }
    }
  }
};

void setup() {
  Serial.begin(115200);

  BLEDevice::init("ESP32_Device");
  pServer = BLEDevice::createServer();

  BLEService *pService = pServer->createService(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_WRITE
                    );

  pCharacteristic->setCallbacks(new MyCallbacks());

  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.println("BLE Device is ready to pair");
}

void loop() {
  if (dataReceived) {
    Serial.println("Parsed BLE Info:");
    Serial.println("  Device ID: " + receivedDeviceId);
    Serial.println("  Custom Name: " + receivedCustomName);
    dataReceived = false;  // Prevent repeated prints
  }

  delay(100);
}

