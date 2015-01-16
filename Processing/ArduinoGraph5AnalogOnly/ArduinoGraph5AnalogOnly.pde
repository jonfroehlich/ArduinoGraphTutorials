// Code by Professor Jon Froehlich
// jonfroehlich@gmail.com
// Written for CMSC838f Tangible Interactive Computing
// http://cmsc838f-s15.wikispaces.com/
// 
// This sketch is part of a series of Processing graph examples meant to help others
// learn about graphing Arduino output and creating visualizations in Processing
// Please feel free to remix and use this code in your own work but please attribute me
//
// This program visualizes the analog input off the serial port
// The input must be formatted: "Label=Value, Label2=Value2, Label3=Value3..." etc.
// 
// To run this Processing sketch, your Arduino must be plugged in and communicating over the serial port
// (you must configure the port below in setup()). You can use any Arduino sketch that prints
// values to the serial port using the above data format but I suggest you start with this: PrintInputsForProcessing.ino
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

import processing.serial.*;
import java.awt.event.*;
import java.util.Map;

final int MAX_ANALOG_VALUE = 1023;
final int MIN_ANALOG_VALUE = 0;
final int MAX_ANALOG_INPUTS = 6;
final int DEFAULT_GRAPH_DATA_OPACITY = 175;
final int DEFAULT_GRAPH_DATA_STROKE_WEIGHT= 4;

final color COLOR_PALETTE[] = new color[] {  
  color(241, 90, 96), 
  color(122, 195, 106), 
  color(90, 155, 212), 
  color(250, 167, 91), 
  color(158, 103, 171), 
  color(206, 112, 88), 
  color(215, 127, 180)
};

Serial _serialPort;       // The serial port

HashMap<String, GraphData> _mapLabelToGraphData = new HashMap<String, GraphData>();
IntList _listOfColors = new IntList(COLOR_PALETTE);
color _backgroundColor = color(51);

PGraphics _pg;
int _frameWidthOnLastDraw = -1;
int _frameHeightOnLastDraw = -1;
int _numYAxisTicks = 10;

float _minYValue = MIN_ANALOG_VALUE;
float _maxYValue = 715;

int _ignoreFirstNumLines = 10;
int _linesRead = 0;

PFont _axisFont = null;
StringList _labels = new StringList();


class GraphData {
  int Values[];
  String Label;
  color Color;
  int StrokeWeight = DEFAULT_GRAPH_DATA_STROKE_WEIGHT;
  boolean IsAnalog = true;

  GraphData(String label, int[] values, color c) {
    Label = label;
    Values = values;
    Color = c;
  }

  public void slideInsert(int value) {
    // Slide everything down in the array while also drawing to the screen
    for (int i = 0; i < Values.length - 1; i++) {
      Values[i] = Values[i + 1];
    }

    Values[Values.length - 1] = value;
  }

  public int length() { 
    return Values.length;
  }
}

void setup () {
  // set the window size:
  size(400, 300);

  _frameWidthOnLastDraw = width;
  _frameHeightOnLastDraw = height;
  _pg = createGraphics(width, height);

  // set the window to be resizable
  if (frame != null) {
    frame.setResizable(true);
  }

  _axisFont = createFont("Arial", 16, true); // Arial, 16 point, anti-aliasing on

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

  if (width != _frameWidthOnLastDraw || height != _frameHeightOnLastDraw) {    
    // The window was resized -- note redraw() is called automatically when a window is resized
    //println("Frame resized from (" + _frameWidthOnLastDraw + ", " + _frameHeightOnLastDraw + ") to (" + width + ", " + height + ")");
    _pg.setSize(width, height);

    for (String label : _labels) {
      GraphData graphData = _mapLabelToGraphData.get(label);

      int temp[] = new int[width];
      if (_frameWidthOnLastDraw <= width) {
        int dstPosition = width - _frameWidthOnLastDraw;
        arrayCopy(graphData.Values, 0, temp, dstPosition, graphData.length());
      } else {
        int srcPosition = _frameWidthOnLastDraw - width;
        int numOfElementsToCopy = graphData.length() - srcPosition;

        println("Copying " + numOfElementsToCopy + " elements from position " + srcPosition + " into the new array of size " + temp.length);
        arrayCopy(graphData.Values, srcPosition, temp, 0, numOfElementsToCopy);
      }
      graphData.Values = temp;
    }
  }

  _pg.beginDraw();
  _pg.background(_backgroundColor);

  try {
    //for (Map.Entry mapEntry : _mapLabelToGraphData.entrySet ()) {
    //  GraphData graphData = (GraphData)mapEntry.getValue();
    for (String label : _labels) {
      GraphData graphData = _mapLabelToGraphData.get(label);

      if (graphData.IsAnalog) {
        drawAnalogGraphData(_pg, graphData);
      }
    }
  }
  catch(Exception e) {
    //as I couldn't find good object lock documentation for threadsafe operation
    //in processing, occassionally the object _mapLabelToGraphData is currently read and written to
    //which throws an exception.
    println(e);
  }

  //draw the axes overlaid
  drawAxes(_pg);

  drawLegend(_pg, _mapLabelToGraphData);

  _pg.endDraw();

  image(_pg, 0, 0);

  _frameWidthOnLastDraw = width;
  _frameHeightOnLastDraw = height;
}

void drawAnalogGraphData(PGraphics pg, GraphData graphData) {
  //set the color
  pg.stroke(graphData.Color); 
  pg.strokeWeight(graphData.StrokeWeight);

  for (int i = 0; i < graphData.length () - 1; i++) {
    float yCurValue = map(graphData.Values[i], MIN_ANALOG_VALUE, MAX_ANALOG_VALUE, _minYValue, _maxYValue);
    float yNextValue = map(graphData.Values[i + 1], MIN_ANALOG_VALUE, MAX_ANALOG_VALUE, _minYValue, _maxYValue);
    float yCurPixelValue = map(yCurValue, _minYValue, _maxYValue, 0, height); 
    float yNextPixelValue = map(yNextValue, _minYValue, _maxYValue, 0, height); 
    pg.line(i, height - yCurPixelValue, i + 1, height - yNextPixelValue);
  }
}

void drawLegend(PGraphics pg, HashMap<String, GraphData> mapLabelToGraphData) {
  int fontSize = 12;
  pg.textFont(_axisFont, fontSize);  // Specify font to be used
  color fontColor = color(225, 225, 225, 200);

  int legendEntry = 0;
  int yStartLoc = 25;
  int xLoc = width - 70;
  int rectWidth = 15;
  int rectHeight = 9;
  for (String label : _labels) {
    GraphData graphData = mapLabelToGraphData.get(label);
    int yLoc = yStartLoc + legendEntry * (fontSize + 2);

    pg.fill(graphData.Color);
    pg.rect(xLoc, yLoc, rectWidth, rectHeight); 

    pg.fill(fontColor);
    pg.text(graphData.Label, xLoc + rectWidth + 5, yLoc + fontSize / 2f + 3);

    legendEntry++;
  }
}

void drawAxes(PGraphics pg) {

  pg.textFont(_axisFont, 12);  // Specify font to be used
  pg.fill(200, 200, 200, 128); // Specify font color 

  float tickStepPixels = height / _numYAxisTicks;
  pg.strokeWeight(1);
  pg.stroke(128, 128, 128, 50);
  for (int i = 0; i < _numYAxisTicks; i++) {
    float yPixelValue = tickStepPixels * i;  
    pg.line(0, height - yPixelValue, width, height - yPixelValue);

    float yValue = map(yPixelValue, 0, height, _minYValue, _maxYValue);
    String yAxisLabel = String.format("%.1f", yValue);
    pg.text(yAxisLabel, 10, height - yPixelValue - 2);
  }
}

void serialEvent (Serial myPort) { 
  // get the ASCII string:

  try {
    String inString = _serialPort.readStringUntil('\n');
    //println("Read in " + inString);

    if (_linesRead < _ignoreFirstNumLines) {
      _serialPort.clear();
      _linesRead++;
      return;
    }

    if (inString != null) {

      // trim off any whitespace:
      inString = trim(inString);

      // parse the data
      String[] chunks = split(inString, ',');
      for (int i = 0; i < chunks.length; i++) {
        String[] labelValue = split(chunks[i], '=');

        if (labelValue.length == 2) {
          String label = labelValue[0];

          String strValue = labelValue[1].toLowerCase();
          boolean isAnalog = true;
          int value = -1;
          if (strValue.startsWith("l") || strValue.startsWith("h")) {
            if (strValue.startsWith("l")) {
              value = 0;
              isAnalog = false;
            } else if (strValue.startsWith("h")) {
              value = 1; 
              isAnalog = false;
            }
          } else {
            value = int(strValue);
          }

          if (isAnalog) {
            if (!_mapLabelToGraphData.containsKey(label)) {
              int[] values = new int[width];
              //int colorIndex = (int)random(_listOfColors.size());
              int colorIndex = 0;
              color c = _listOfColors.get(colorIndex);
              c = color(red(c), green(c), blue(c), DEFAULT_GRAPH_DATA_OPACITY);
              _listOfColors.remove(colorIndex);

              GraphData graphData = new GraphData(label, values, c);
              graphData.IsAnalog = isAnalog;

              _mapLabelToGraphData.put(label, graphData);

              _labels.append(label);
            }

            GraphData graphData = _mapLabelToGraphData.get(label);
            graphData.slideInsert(value);
          }
        }
      }

      redraw();
    }
  }
  catch(Exception e) {
    println(e);
  }
}
