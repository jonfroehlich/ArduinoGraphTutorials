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
// 1. ArduinoGraph1.pde : The simplest and essentially Tom Igoe's original code (with some variable renaming)
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
import java.awt.event.*;

Serial _serialPort;       // The serial port
int _analogValues[];
PGraphics _pg;
int _frameWidthOnLastDraw = -1;
int _frameHeightOnLastDraw = -1;

void setup () {
  // set the window size:
  size(400, 300);
  _frameWidthOnLastDraw = width;
  _frameHeightOnLastDraw = height;
  _pg = createGraphics(width, height);
  _analogValues = new int [width];

  // set the window to be resizable
  if (frame != null) {
    frame.setResizable(true);
  }
  
  // List all the available serial ports
  println(Serial.list());

  // Open whatever port is the one you're using.
  _serialPort = new Serial(this, Serial.list()[1], 9600);

  // don't generate a serialEvent() unless you get a newline character:
  _serialPort.bufferUntil('\n');

  // set inital background:
  background(0);
}

void draw () {
  
  if(width != _frameWidthOnLastDraw || height != _frameHeightOnLastDraw){    
    // If we're here, the window was resized -- note redraw() is called automatically when a window is resized
    // I'm doing this rather than hooking up to the componentResized AWT call because, though I tried this,
    // I ran into all sorts of problems. See an example discussion here: 
    // http://forum.processing.org/two/discussion/327/trying-to-capture-window-resize-event-to-redraw-background-to-new-size-not-working/p1
    _pg.setSize(width, height);
          
    int temp[] = new int[width];
    
    if(_frameWidthOnLastDraw <= width){
      int dstPosition = width - _frameWidthOnLastDraw;
      arrayCopy(_analogValues, 0, temp, dstPosition, _analogValues.length);
    }else{
      int srcPosition = _frameWidthOnLastDraw - width;
      int numOfElementsToCopy = _analogValues.length - srcPosition;
      
      //println("Copying " + numOfElementsToCopy + " elements from position " + srcPosition + " into the new array of size " + temp.length);
      arrayCopy(_analogValues, srcPosition, temp, 0, numOfElementsToCopy);
    }
    
    _analogValues = temp;  
  }
  
  
  _pg.beginDraw();
  _pg.background(25);

  //set the color
  _pg.stroke(127, 34, 255, 127); 

  // draw to the buffer
  for (int i = 0; i < _analogValues.length; i++) {
    int yPixelValue = (int)map(_analogValues[i], 0, 1023, 0, height);
    _pg.line(i, height, i, height - yPixelValue);
  }
  _pg.endDraw();

  image(_pg, 0, 0);
  
  _frameWidthOnLastDraw = width;
  _frameHeightOnLastDraw = height;
}

void serialEvent (Serial myPort) { 
  // get the ASCII string:
  String inString = _serialPort.readStringUntil('\n');

  if (inString != null) {
    // trim off any whitespace:
    inString = trim(inString);

    // convert to an int and map to the screen height:
    int analogVal = int(inString); 
    
    // Slide everything down in the array while also drawing to the screen
    for (int i = 0; i < _analogValues.length - 1; i++) {
      _analogValues[i] = _analogValues[i + 1];
    }

    _analogValues[_analogValues.length - 1] = analogVal;
    redraw();
  }
}
