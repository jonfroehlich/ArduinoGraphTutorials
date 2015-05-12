// Code by Professor Jon Froehlich
// jonfroehlich@gmail.com
// Written for CMSC838f Tangible Interactive Computing
// http://cmsc838f-s15.wikispaces.com/
// 
// This sketch is part of a series of Processing graph examples meant to help others
// learn about graphing Arduino output and creating visualizations in Processing
// Please feel free to remix and use this code in your own work but please attribute me
//
// This program visualizes the analog and digital input off the serial port
// The input must be formatted: "Label=Value, Label2=Value2, Label3=Value3..." etc.
// The program automatically infers whether the signal is digital or analog by looking
// at the value contents--if a value starts with 'L' for 'LOW' or 'H' 'HIGH', it infers digital. 
// Otherwise, the value content is set to analog
//
// The window is setup like the following: the top graph is for analog data. All analog data
// is drawn on the same graph with different colors assigned to each input channel. The
// digital data is split into N graphs below the analog area where N = number of digital inputs.
// In the example below, we have one analog input and two digital inputs.
//
// ------------------------------------------------------------------------------
// |                                                            Analog Legend   |
// |                                                                            |
// |    ANALOG VIS AREA                                                         |
// |                                                                            |
// |                                                          /----\            |
// |                                                         /      \  /--------|
// |        --------Scrolling Analog Data-----\             /        \/         |
// |       /                                   \-----------/                    |
// |      /                                                                     |
// |  ---/                                                                      |
// |                                                                            |
// |-----------------------------------------------------------------------------
// | D0 ______    DIGITAL VIS AREA             __________       ___   _____     |
// |____|    |_________________________________|         |______| |___|   |_____|
// |                                                                            |
// | D1          ___________      ___   _____     ___   _____         ___   ____|
// |_____________|         |______| |___|   |_____| |___|   |_________| |___|   |
// |____________________________________________________________________________|
//
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

final int MAX_DIGITAL_VALUE = 1;
final int MIN_DIGITAL_VALUE = 0;

final int MAX_ANALOG_INPUTS = 6;
final int DEFAULT_GRAPH_DATA_OPACITY = 100;
final int DEFAULT_GRAPH_ANALOG_DATA_STROKE_WEIGHT= 3;
final int DEFAULT_GRAPH_DIGITAL_DATA_STROKE_WEIGHT= 1;
final int MAX_SINGLE_DIGITAL_GRAPH_HEIGHT = 40; //pixels
final float MAX_DIGITAL_VIS_AREA_FRACTION = 0.4f;

//Stephen Few's color palette (medium range intensity)
//http://www.perceptualedge.com/articles/visual_business_intelligence/rules_for_using_color.pdf
final color STEPHEN_FEW_COLOR_PALETTE[] = new color[] {  
  color(241, 90, 96), 
  color(122, 195, 106), 
  color(90, 155, 212), 
  color(250, 167, 91), 
  color(158, 103, 171), 
  color(206, 112, 88), 
  color(215, 127, 180)
};

final color COLOR_BREWER14_COLOR_PALETTE[] = new color[] {  
  color(141, 211, 199), 
  color(255, 255, 179), 
  color(190, 186, 218), 
  color(251, 128, 114), 
  color(128, 177, 211), 
  color(253, 180, 98), 
  color(179, 222, 105), 
  color(252, 205, 229), 
  color(217, 217, 217), 
  color(188, 128, 189), 
  color(204, 235, 197), 
  color(255, 237, 111), 
  color(250, 250, 250), 
  color(120, 120, 120),
};

Serial _serialPort;

HashMap<String, GraphData> _mapLabelToGraphData = new HashMap<String, GraphData>();

int _numAnalogInputs = 0;
int _numDigitalInputs = 0;

int _analogVisAreaHeight = -1;
int _digitalVisAreaHeight = -1;

IntList _analogColorPalette = new IntList(STEPHEN_FEW_COLOR_PALETTE);
IntList _digitalColorPalette = new IntList(COLOR_BREWER14_COLOR_PALETTE);
color _backgroundColor = color(51);

PGraphics _pg;

// Although Processing allows you to hook into a window's resize event
// it causes a bit of chaos. As redraw() is automatically called by
// Processing when a frame/window is resized, I just use these bookkeeping
// variables to let me know when a window resize has occurred (and then
// configure the visualizations accordingly).
int _frameWidthOnLastDraw = -1;
int _frameHeightOnLastDraw = -1;
int _mapLabelToGraphDataSizeOnLastDraw = 0;

int _numYAxisTicksAnalogGraph = 10;

float _minYAnalogValue = MIN_ANALOG_VALUE;
float _maxYAnalogValue = MAX_ANALOG_VALUE;

// Obviously digital values can only be between 0 and 1. This is just
// a simple way of zooming out a bit on the graph
float _minYDigitalValue = -0.05f;
float _maxYDigitalValue = 1.2f;

// There is often garbage on the serial port. We wait 10 lines before
// actually parsing and using content
int _ignoreFirstNumLines = 10;
int _initializationLinesRead = 0;

PFont _axisFont = null;
StringList _labels = new StringList();
color _axesColor = color(128, 128, 128, 50);
int _axesStrokeWeight = 1;

// We can draw the digital data as outlines or filled. Filled is better
// so is on by default.
boolean _drawDigitalDataAsOutlineOnly = false;

// Each input channel has its own GraphData object.
class GraphData {
  int Values[];
  String Label;
  color Color;
  int StrokeWeight = 1;
  boolean IsAnalog = true;

  GraphData(String label, int[] values, color c, int strokeWeight) {
    Label = label;
    Values = values;
    Color = c;
    StrokeWeight = strokeWeight;
  }

  // Slides all values down one position to the left and adds the value to the end
  public void slideInsert(int value) {
    // Slide everything down in the array while also drawing to the screen
    for (int i = 0; i < Values.length - 1; i++) {
      Values[i] = Values[i + 1];
    }

    Values[Values.length - 1] = value;
  }

  // The number of values
  public int length() { 
    return Values.length;
  }
}

void setup () {
  // set the window size:
  size(400, 300);

  _frameWidthOnLastDraw = width;
  _frameHeightOnLastDraw = height;
  _analogVisAreaHeight = height;
  _digitalVisAreaHeight = 0;
  _pg = createGraphics(width, height);

  // set the window to be resizable
  if (frame != null) {
    frame.setResizable(true);
  }

  _axisFont = createFont("Arial", 16, true); // Arial, 16 point, anti-aliasing on

  // List all the available serial ports
  println(Serial.list());

  // Open whatever port is the one you're using.
  // On my PC at home, it's the second option in the list, index 1
  // On my Mac, it's the fifth option in the list, index 4
  _serialPort = new Serial(this, Serial.list()[1], 9600);

  // don't generate a serialEvent() unless you get a newline character:
  _serialPort.bufferUntil('\n');

  // set inital background:
  background(0);
}

void draw () {

  if (width != _frameWidthOnLastDraw || height != _frameHeightOnLastDraw || 
     _mapLabelToGraphData.size() != _mapLabelToGraphDataSizeOnLastDraw) {  
    // if we're here, then either the window has been resized or we've got a brand new GraphData
    // object. Either way, we need to reconfigure our visualizations to resize things!
    
    _pg.setSize(width, height);

    // setup analog and digital vis areas
    _digitalVisAreaHeight = _numDigitalInputs * MAX_SINGLE_DIGITAL_GRAPH_HEIGHT;
    if (_digitalVisAreaHeight / (float)height > MAX_DIGITAL_VIS_AREA_FRACTION) {
      _digitalVisAreaHeight = floor(MAX_DIGITAL_VIS_AREA_FRACTION * height);
    }
    _analogVisAreaHeight = height - _digitalVisAreaHeight;
    //println("AnalogVisAreaHeight=" + _analogVisAreaHeight + " _digitalVisAreaHeight=" + _digitalVisAreaHeight); 

    for (String label : _labels) {
      GraphData graphData = _mapLabelToGraphData.get(label);

      int temp[] = new int[width];
      if (_frameWidthOnLastDraw <= width) {
        int dstPosition = width - _frameWidthOnLastDraw;
        arrayCopy(graphData.Values, 0, temp, dstPosition, graphData.length());
      } else {
        int srcPosition = _frameWidthOnLastDraw - width;
        int numOfElementsToCopy = graphData.length() - srcPosition;

        //println("Copying " + numOfElementsToCopy + " elements from position " + srcPosition + " into the new array of size " + temp.length);
        arrayCopy(graphData.Values, srcPosition, temp, 0, numOfElementsToCopy);
      }
      graphData.Values = temp;
    }
  }

  // We draw to an offscreen buffer and then bitblt to the screen to reduce flickering
  _pg.beginDraw();
  _pg.background(_backgroundColor);
  drawAnalogGraph(_pg);
  drawDigitalGraphs(_pg);
  _pg.endDraw();
  image(_pg, 0, 0);

  _frameWidthOnLastDraw = width;
  _frameHeightOnLastDraw = height;
  _mapLabelToGraphDataSizeOnLastDraw = _mapLabelToGraphData.size();
}

void drawDigitalGraphs(PGraphics pg) {
  if (_numDigitalInputs > 0) {
    int yBufferBetweenAnalogAndDigital = 5;
    int singleGraphHeight = (_digitalVisAreaHeight - yBufferBetweenAnalogAndDigital) / _numDigitalInputs;
    
    // The first digital graph starts just after the analog visualization area
    int yLoc = _analogVisAreaHeight + yBufferBetweenAnalogAndDigital;
    //println("_digitalVisAreaHeight=" + _digitalVisAreaHeight + " _numDigitalInputs= " + _numDigitalInputs + " yLoc=" + yLoc + " graphHeight=" + singleGraphHeight);
    try {
      for (String label : _labels) {
        GraphData graphData = _mapLabelToGraphData.get(label);
        if (!graphData.IsAnalog) {
          drawDigitalGraphData(_pg, graphData, yLoc, singleGraphHeight);
          yLoc += singleGraphHeight;
        }
      }
    }
    catch(Exception e) {
      //as I couldn't find good object lock documentation for threadsafe operation
      //in Processing, occassionally the object _mapLabelToGraphData is currently read and written to simultaneously
      //which throws an exception.
      println(e);
    }
  }
}

void drawDigitalGraphData(PGraphics pg, GraphData graphData, int yLoc, int graphHeight) {  
  //set the color
  pg.stroke(graphData.Color); 
  pg.strokeWeight(graphData.StrokeWeight);

  if (_drawDigitalDataAsOutlineOnly) {
    for (int i = 0; i < graphData.length () - 1; i++) {
      float yCurPixelValue = map(graphData.Values[i], _minYDigitalValue, _maxYDigitalValue, 0, graphHeight); 
      float yNextPixelValue = map(graphData.Values[i + 1], _minYDigitalValue, _maxYDigitalValue, 0, graphHeight); 
      pg.line(i, yLoc + graphHeight - yCurPixelValue, i + 1, yLoc + graphHeight - yNextPixelValue);
      //println(String.format("(%d, %.1f) to (%d, %.1f)", i, yLoc + graphHeight - yCurPixelValue, i + 1, yLoc + graphHeight - yNextPixelValue));
    }
  }else{
    for (int i = 0; i < graphData.length (); i++) {
      float yCurPixelValue = map(graphData.Values[i], _minYDigitalValue, _maxYDigitalValue, 0, graphHeight);  
      pg.line(i, yLoc + graphHeight, i, yLoc + graphHeight - yCurPixelValue);
      //println(String.format("(%d, %.1f) to (%d, %.1f)", i, yLoc + graphHeight - yCurPixelValue, i + 1, yLoc + graphHeight - yNextPixelValue));
    }
  }

  //draw outline at top and bottom
  pg.strokeWeight(_axesStrokeWeight);
  pg.stroke(_axesColor);
  pg.line(0, yLoc, width, yLoc);
  pg.line(0, yLoc + graphHeight, width, yLoc + graphHeight);
  
  //draw label
  float fontSize = graphHeight * 0.5f;
  pg.textFont(_axisFont, fontSize);  // Specify font to be used
  pg.fill(245, 245, 245, 128); // Specify font color 
  pg.text(graphData.Label, 10, yLoc + graphHeight - fontSize / 2f);
}

void drawAnalogGraph(PGraphics pg) {
  try {
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

  //draw the axes
  drawAnalogAxes(_pg);

  //draw the legend
  drawAnalogLegend(_pg, _mapLabelToGraphData);
}


void drawAnalogGraphData(PGraphics pg, GraphData graphData) {
  //set the color
  pg.stroke(graphData.Color); 
  pg.strokeWeight(graphData.StrokeWeight);

  for (int i = 0; i < graphData.length () - 1; i++) {
    float yCurValue = map(graphData.Values[i], MIN_ANALOG_VALUE, MAX_ANALOG_VALUE, _minYAnalogValue, _maxYAnalogValue);
    
    //println(String.format("%s: value=%d y=%f", graphData.Label, graphData.Values[i], yCurValue));
    
    float yNextValue = map(graphData.Values[i + 1], MIN_ANALOG_VALUE, MAX_ANALOG_VALUE, _minYAnalogValue, _maxYAnalogValue);
    float yCurPixelValue = map(yCurValue, _minYAnalogValue, _maxYAnalogValue, 0, _analogVisAreaHeight); 
    float yNextPixelValue = map(yNextValue, _minYAnalogValue, _maxYAnalogValue, 0, _analogVisAreaHeight); 
    pg.line(i, _analogVisAreaHeight - yCurPixelValue, i + 1, _analogVisAreaHeight - yNextPixelValue);
  }
}

void drawAnalogLegend(PGraphics pg, HashMap<String, GraphData> mapLabelToGraphData) {
  int fontSize = 12;
  pg.textFont(_axisFont, fontSize);  // Specify font to be used
  color fontColor = color(225, 225, 225, 200);
  
  int longestLabelWidth = 0;
  for (String label : _labels) {
     int curLabelWidth = (int)pg.textWidth(label);
     if(curLabelWidth > longestLabelWidth){
       longestLabelWidth = curLabelWidth;
     }
  }

  int legendEntry = 0;
  int yStartLoc = 25;
  
  int rectWidth = 15;
  int rectHeight = 9;
  
  int xLoc = width - (longestLabelWidth + rectWidth + 10);
  
  for (String label : _labels) {
    GraphData graphData = mapLabelToGraphData.get(label);

    if (graphData.IsAnalog) {
      int yLoc = yStartLoc + legendEntry * (fontSize + 2);

      pg.fill(graphData.Color);
      pg.rect(xLoc, yLoc, rectWidth, rectHeight); 

      pg.fill(fontColor);
      pg.text(graphData.Label, xLoc + rectWidth + 5, yLoc + fontSize / 2f + 3);

      legendEntry++;
    }
  }
}

void drawAnalogAxes(PGraphics pg) {

  pg.textFont(_axisFont, 12);  // Specify font to be used
  pg.fill(200, 200, 200, 128); // Specify font color 

  float tickStepPixels = height / _numYAxisTicksAnalogGraph;
  pg.strokeWeight(_axesStrokeWeight);
  pg.stroke(_axesColor);
  for (int i = 0; i < _numYAxisTicksAnalogGraph; i++) {
    float yPixelValue = tickStepPixels * i;  
    pg.line(0, _analogVisAreaHeight - yPixelValue, width, _analogVisAreaHeight - yPixelValue);

    float yValue = map(yPixelValue, 0, _analogVisAreaHeight, _minYAnalogValue, _maxYAnalogValue);
    String yAxisLabel = String.format("%.1f", yValue);
    pg.text(yAxisLabel, 10, _analogVisAreaHeight - yPixelValue - 2);
  }
}

void serialEvent (Serial myPort) { 
  try {
    String inString = _serialPort.readStringUntil('\n');
    //println("Read in " + inString);

    if (_initializationLinesRead < _ignoreFirstNumLines) {
      _serialPort.clear();
      _initializationLinesRead++;
      println(String.format("Initializing serial port, %d lines read", _initializationLinesRead));
      return;
    }else if(_initializationLinesRead == _ignoreFirstNumLines){
      println(String.format("Initialized serial port after %d lines read", _initializationLinesRead));
      _initializationLinesRead++;
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

          String strValue = trim(labelValue[1].toLowerCase());
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

          //println(String.format("Read '%s' strValue=%s rawValue=%d", label, strValue, value)); 
        
          if (!_mapLabelToGraphData.containsKey(label)) {
            int[] values = new int[width];
            //int colorIndex = (int)random(_analogColorPalette.size()); 
            int colorIndex = 0;
            IntList colorPalette = isAnalog ? _analogColorPalette : _digitalColorPalette;
            int strokeWeight = isAnalog ? DEFAULT_GRAPH_ANALOG_DATA_STROKE_WEIGHT : DEFAULT_GRAPH_DIGITAL_DATA_STROKE_WEIGHT;
            color c = colorPalette.size() > 0 ? colorPalette.get(colorIndex) : color(255);
            c = color(red(c), green(c), blue(c), DEFAULT_GRAPH_DATA_OPACITY);
            colorPalette.remove(colorIndex);

            GraphData graphData = new GraphData(label, values, c, strokeWeight);
            graphData.IsAnalog = isAnalog;

            if (isAnalog) {
              _numAnalogInputs++;
            } else {
              _numDigitalInputs++;
            }        

            _mapLabelToGraphData.put(label, graphData);

            _labels.append(label);
          }

          GraphData graphData = _mapLabelToGraphData.get(label);
          graphData.slideInsert(value);
        }
      }

      redraw();
    }
  }
  catch(Exception e) {
    println(e);
  }
}
