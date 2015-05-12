// Code by Professor Jon Froehlich
// jonfroehlich@gmail.com
// Written for CMSC838f Tangible Interactive Computing
// http://cmsc838f-s15.wikispaces.com/
// 
// This sketch is a remix of http://arduino.cc/en/Tutorial/Graph by Tom Igoe 
// and is part of a series of Processing graph examples meant to help others
// learn about graphing Arduino output and creating visualizations in Processing
//
// To run this Processing sketch, your Arduino must be plugged in and communicating over the serial port
// (you must configure the port below in setup()). You can use any Arduino sketch that prints
// values to the serial port but I suggest you start with this: PrintSingleAnalogInputForProcessing.ino 
// 
// 1. ArduinoGraph1.pde : The simplest--essentially Tom Igoe's original code
// 2. ArduinoGraph2SimpleScrolling.pde : changes visualization to scrolling rather than looping
// 3. ArduinoGraph3SimpleScrollingDoubleBuffered.pde : adds in double buffering
// 4. ArduinoGraph4SimpleScrollingDoubleBufferedResizable.pde : adds in responsive window resizing
// 5. ArduinoGraph5AnalogOnly.pde : adds in support for handling multiple channels of analog input (note: the data format changes)
// 6. ArduinoGraph6DigitalAndAnalog.pde : adds in support for digital input channels
//
// The first four examples are simple, the fifth example is intermediate (ArduinoGraph5AnalogOnly.pde), and the last 
// example (ArduinoGraph6DigitalAndAnalog.pde) is more advanced
//
// For the first four examples, the serial port data must be formatted like:
// 
// value1\nvalue2\nvalue3\n ... valuen
// 
// That is:
// 22
// 34
// 45
// 124
// ...
// N
//
// Read about the data formatting for #5 and #6 in those sketches.

import processing.serial.*;

Serial _serialPort;    // The serial port
int _xPos = 1;         // horizontal position of the graph

void setup () {
  // set the window size:
  size(400, 300);  

  // List all the available serial ports
  println(Serial.list());
  
  // TODO: change X in Serial.list()[X] to the index that is your Arduino
  // On my Windows machine, my Arduino Uno is index 1
  // On my Mac, it's index 4
  _serialPort = new Serial(this, Serial.list()[1], 9600);
  
  // don't generate a serialEvent() unless you get a newline character:
  _serialPort.bufferUntil('\n');
  
  // set inital background:
  background(0);
}
void draw () {
  // everything happens in the serialEvent()
}

void serialEvent (Serial myPort) {
  // get the ASCII string:
  String inString = _serialPort.readStringUntil('\n');

  if (inString != null) {
    // trim off any whitespace:
    inString = trim(inString);
    
    // convert to an int and map to the screen height:
    int analogVal = int(inString); 
    int yPixelValue = (int)map(analogVal, 0, 1023, 0, height);

    // draw the line:
    int redColor = (int)map(analogVal, 0, 1023, 0, 255);
    stroke(redColor, 34, 255); //set the color
    line(_xPos, height, _xPos, height - yPixelValue);

    // at the edge of the screen, go back to the beginning:
    if (_xPos >= width) {
      _xPos = 0;
      background(0); //clear the screen
    } else {
      // increment the horizontal position:
      _xPos++;
    }
  }
}
