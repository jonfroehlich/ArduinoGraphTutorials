// Jon Froehlich
// jonfroehlich@gmail.com
// Written for CMSC838f Tangible Interactive Computing
// http://cmsc838f-s15.wikispaces.com/
//
// This sketch is part of a series meant to help others learn about graphing Arduino output and
// creating visualizations in Processing. Note: this sketch is for #1 - #4 below. For #5 and #6,
// use the sketch: PrintInputsForProcessing
//
// 1. ArduinoGraph : The simplest and essentially Tom Igoe's original ArduinoGraph code (http://arduino.cc/en/Tutorial/Graph)
// 2. ArduinoGraphSimpleScrolling : changes visualization to scrolling rather than looping
// 3. ArduinoGraphSimpleScrollingDoubleBuffered : adds in double buffering
// 4. ArduinoGraphSimpleScrollingDoubleBufferedResizable : adds in responsive window resizing
// 5. JonArduinoGraphAnalogOnly : adds in support for handling multiple channels of analog input 
// 6. JonArduinoGraph : the full visualizer that supports multiple analog and digital input channels
//
// This code was originally developed by the Arduino team: http://www.arduino.cc/en/Tutorial/Graph
//
// The original documentation is below:
//
// A simple example of communication from the Arduino board to the computer:
// the value of analog input 0 is sent out the serial port.  We call this "serial"
// communication because the connection appears to both the Arduino and the
// computer as a serial port, even though it may actually use
// a USB cable. Bytes are sent one after another (serially) from the Arduino
// to the computer.
//
// You can use the Arduino serial monitor to view the sent data, or it can
// be read by Processing, PD, Max/MSP, or any other program capable of reading 
// data from a serial port.  The Processing code below graphs the data received 
// so you can see the value of the analog input changing over time.
//
// The circuit:
// Any analog input sensor is attached to analog in pin 0.
//
// created 2006
// by David A. Mellis
// modified 9 Apr 2012
// by Tom Igoe and Scott Fitzgerald
//
// This example code is in the public domain.
void setup() {
  // initialize the serial communication:
  Serial.begin(9600);
}

void loop() {
  // send the value of analog input 0:
  Serial.println(analogRead(A0));
  // wait a bit for the analog-to-digital converter 
  // to stabilize after the last reading:
  delay(2);
}
