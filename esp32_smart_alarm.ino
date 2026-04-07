#define BLYNK_TEMPLATE_ID "TMPL6gdA18kml"
#define BLYNK_TEMPLATE_NAME "home alarm"
#define BLYNK_AUTH_TOKEN "2ffoYbFrhgy0tLaotK3rnJGgqIfvfhl5"

#define BLYNK_PRINT Serial

#include <WiFi.h>
#include <WiFiClient.h>
#include <BlynkSimpleEsp32.h>

char ssid[] = "alfaqueue";
char pass[] = "11223344";

// ================= HARWARE PINS =================
#define PIR_PIN 35         // ADC pin for PIR
#define FLAME_PIN 32       // Digital pin for flame sensor
#define DOOR_PIN 33        // Digital pin for door sensor (reed switch)
#define STATUS_LED 2       // Built-in LED

// ================= TUNE THESE (FOR PIR) =========
const float THRESH_HIGH = 2.5;     // voltage to trigger DETECTED
const float THRESH_LOW = 1.5;      // voltage to trigger CLEAR (hysteresis)
const uint32_t DEBOUNCE_MS = 300;  // spike must last longer than this to count
// ==============================================

const float ADC_REF = 3.3;
const int ADC_RES = 4095;

bool motionDetected = false;
bool pendingHigh = false;
uint32_t pendingStart = 0;
uint32_t lastSend = 0;
const uint32_t SEND_INTERVAL = 200;

// Variables to keep track of sensor states and reduce spam
int lastFlameState = -1;
int lastDoorState = -1;

void setup() {
  Serial.begin(115200);

  // Configure Pins
  pinMode(STATUS_LED, OUTPUT);
  digitalWrite(STATUS_LED, LOW);
  
  pinMode(FLAME_PIN, INPUT_PULLUP); // Assuming flame module provides digital output
  pinMode(DOOR_PIN, INPUT_PULLUP);  // Assuming magnetic reed switch to GND

  // Setup ADC for PIR
  analogReadResolution(12);
  analogSetAttenuation(ADC_11db);  // 0–3.3V range

  Serial.println("Connecting to Blynk...");
  Blynk.begin(BLYNK_AUTH_TOKEN, ssid, pass);
  Serial.println("Smart Alarm System Ready");
}

// BLYNK WRITE handler for V3 (Reset Button from App)
BLYNK_WRITE(V3) {
  int resetVal = param.asInt();
  if (resetVal == 1) {
    Serial.println("Reset command received from Dashboard! Rebooting...");
    digitalWrite(STATUS_LED, HIGH);
    delay(500); 
    
    // Clear the V3 pin back to 0 on the server before restarting
    Blynk.virtualWrite(V3, 0); 
    delay(100);
    
    ESP.restart(); // Hardware reset
  }
}

void loop() {
  Blynk.run();

  // 1. ============ PIR SENSOR LOGIC (V0) ============
  int adcSum = 0;
  for (int i = 0; i < 8; i++) {
    adcSum += analogRead(PIR_PIN);
    delayMicroseconds(100);
  }
  float voltage = ((adcSum / 8.0) * ADC_REF) / ADC_RES;

  if (!motionDetected) {
    if (voltage > THRESH_HIGH) {
      if (!pendingHigh) {
        pendingHigh = true;
        pendingStart = millis();
      } else if (millis() - pendingStart > DEBOUNCE_MS) {
        motionDetected = true;
        pendingHigh = false;
      }
    } else {
      pendingHigh = false;
    }
  } else {
    if (voltage < THRESH_LOW) {
      motionDetected = false;
    }
  }


  // 2. ============ FLAME SENSOR LOGIC (V1) ============
  // Most flame modules output LOW (0) when a flame is detected, and HIGH (1) when safe.
  // We'll read the pin and send 1 for DANGER and 0 for SAFE to Blynk.
  int currentFlameRead = digitalRead(FLAME_PIN);
  int isFire = (currentFlameRead == LOW) ? 1 : 0; 
  

  // 3. ============ DOOR SENSOR LOGIC (V2) ============
  // Reed switch typically connected between pin and GND.
  // Door closed -> magnet near -> switch closed -> reads LOW (0).
  // Door open -> magnet away -> switch open -> internal pullup makes it HIGH (1).
  // App logic: 0 = CLOSED, 1 = OPEN. So we report the pin value directly!
  int currentDoorRead = digitalRead(DOOR_PIN);


  // 4. ============ SEND TO BLYNK ============
  if (millis() - lastSend > SEND_INTERVAL) {
    
    // Always update PIR (V0)
    Blynk.virtualWrite(V0, motionDetected ? 1 : 0);
    
    // Only conditionally update digital sensors if they changed to save bandwidth,
    // or just send them periodically. Here we do it periodically for simplicity.
    if (isFire != lastFlameState) {
       Blynk.virtualWrite(V1, isFire);
       lastFlameState = isFire;
    }
    
    if (currentDoorRead != lastDoorState) {
       Blynk.virtualWrite(V2, currentDoorRead);
       lastDoorState = currentDoorRead;
    }

    // Status LED reflects motion or fire
    if(motionDetected || isFire == 1) {
      digitalWrite(STATUS_LED, HIGH);
    } else {
      digitalWrite(STATUS_LED, LOW);
    }

    lastSend = millis();
  }
}
