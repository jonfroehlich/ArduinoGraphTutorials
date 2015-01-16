// Code by Jon Froehlich
// jonfroehlich@gmail.com
// Written for CMSC838f Tangible Interactive Computing
// http://cmsc838f-s15.wikispaces.com/
//
// Please feel free to remix and use this code in your own work but please attribute me
//
// Use the pinstatus arrays (_analogInPinStatuses or _digitalInPinStatuses) to turn on/off
// printing of those input pins.
// 
// The digital pin values can either be 'LOW' or 'L' or 'HIGH' or 'H'
//
// This sketch is part of a series meant to help others learn about graphing Arduino output and
// creating visualizations in Processing. Note: this sketch does NOT work for #1-4 below. Instead,
// use the sketch: PrintSingleAnalogInputForProcessing
//
// 1. ArduinoGraph : The simplest and essentially Tom Igoe's original ArduinoGraph code (http://arduino.cc/en/Tutorial/Graph)
// 2. ArduinoGraphSimpleScrolling : changes visualization to scrolling rather than looping
// 3. ArduinoGraphSimpleScrollingDoubleBuffered : adds in double buffering
// 4. ArduinoGraphSimpleScrollingDoubleBufferedResizable : adds in responsive window resizing
// 5. JonArduinoGraphAnalogOnly : adds in support for handling multiple channels of analog input 
// 6. JonArduinoGraph : the full visualizer that supports multiple analog and digital input channels
//
// This particular Arduino sketch goes with JonArduinoGraphAnalogOnly and JonArduinoGraph and 
// was originally developed for the Arduino Uno

bool _analogInPinStatuses[6] = {true, false, false, false, false, false};
String _analogInPinLabels[6] = {"A0", "A1", "A2", "A3", "A4", "A5"};
int _analogInPinValues[6] = { -1, -1, -1, -1, -1, -1};

bool _digitalInPinStatuses[14] = { false, false, true, true, true, true, true, true, true, true, true, true, true, true };
String _digitalInPinLabels[14] = {"D0", "D1", "D2", "D3", "D4", "D5", "D6", "D7", "D8", "D9", "D10", "D11", "D12", "D13"};
String _digitalInPinValues[14] = {"LOW", "LOW", "LOW", "LOW", "LOW", "LOW", "LOW", "LOW", "LOW", "LOW", "LOW", "LOW", "LOW", "LOW"};

int _delayMilliSecs = 10;

void setup() {
  Serial.begin(9600);
  
  for (int digitalPin = 0; digitalPin < 14; digitalPin++) {
    if (_digitalInPinStatuses[digitalPin]) {
      pinMode(digitalPin, INPUT);
    }
  }
}

void loop() {
  for (int analogPinIn = 0; analogPinIn < 6; analogPinIn++) {
    int analogVal = analogRead(analogPinIn);
    _analogInPinValues[analogPinIn] = analogVal;
  }

  for (int digitalPin = 0; digitalPin < 14; digitalPin++) {
    if (_digitalInPinStatuses[digitalPin]) {
      int digitalVal = digitalRead(digitalPin);
      _digitalInPinValues[digitalPin] = (digitalVal == 0) ? "L" : "H";
    }
  }

  graphPrint();
  delay(_delayMilliSecs);
}

void graphPrint() {
  String str = "";
  for (int i = 0; i < 6; i++) {
    if (_analogInPinStatuses[i]) {
      if (str.length() > 0) {
        str += ",";
      }
      str += _analogInPinLabels[i] + "=" + _analogInPinValues[i];
    }
  }

  for (int i = 0; i < 14; i++) {
    if (_digitalInPinStatuses[i]) {
      if (str.length() > 0) {
        str += ",";
      }
      str += _digitalInPinLabels[i] + "=" + _digitalInPinValues[i];
    }
  }

  Serial.println(str);
}
