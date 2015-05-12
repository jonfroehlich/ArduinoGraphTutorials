// Code by Professor Jon Froehlich
// jonfroehlich@gmail.com
// Written for CMSC838f Tangible Interactive Computing
// http://cmsc838f-s15.wikispaces.com/
// 
// This sketch is part of a series of Processing graph examples meant to help others
// learn about graphing Arduino output and creating visualizations in Processing
// Please feel free to remix and use this code in your own work but please attribute me
//
// This program visualizes the analog and digital input off the serial port using
// an abstract representation: a simple particle system based on Daniel Shiffman's
// particle system tutorial: https://processing.org/examples/simpleparticlesystem.html.
// Each input channel auto-generates its own particle emitter. The values off the analog
// channels (which range from 0 - 1023) set the size of the particle. The values off
// the digital channels simply turn their respective emitters on or off.
//
// The input must be formatted: "Label=Value, Label2=Value2, Label3=Value3..." etc.
// The program automatically infers whether the signal is digital or analog by looking
// at the value contents--if a value starts with 'L' for 'LOW' or 'H' 'HIGH', it infers digital. 
// Otherwise, the value content is set to analog
//
// To run this Processing sketch, your Arduino must be plugged in and communicating over the serial port
// (you must configure the port below in setup()). You can use any Arduino sketch that prints
// values to the serial port using the above data format but I suggest you start with this: PrintInputsForProcessing.ino
// 

import processing.serial.*;
import java.awt.event.*;
import java.util.Map;

final int MAX_ANALOG_VALUE = 1023;
final int MIN_ANALOG_VALUE = 0;

final int MAX_DIGITAL_VALUE = 1;
final int MIN_DIGITAL_VALUE = 0;

final int MAX_ANALOG_INPUTS = 6;
final int DEFAULT_GRAPH_DATA_OPACITY = 175;
final int DEFAULT_GRAPH_ANALOG_DATA_STROKE_WEIGHT= 4;
final int DEFAULT_GRAPH_DIGITAL_DATA_STROKE_WEIGHT= 1;
final int DEFAULT_DIGITAL_PARTICLE_SIZE = 3;
final boolean DEFAULT_PARTICLE_EMITTER_MOTION_ENABLED = true;


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

int _numAnalogInputs = 0;
int _numDigitalInputs = 0;

int _analogVisAreaHeight = -1;
int _digitalVisAreaHeight = -1;

IntList _analogColorPalette = new IntList(STEPHEN_FEW_COLOR_PALETTE);
IntList _digitalColorPalette = new IntList(COLOR_BREWER14_COLOR_PALETTE);
color _backgroundColor = color(51);

PGraphics _pg;

// Although Processing allows you to hook into a window's resize event
// it causes a bit of chaos so I'm not using it. Instead, because redraw() is 
// automatically called by Processing when a frame/window is resized, I just 
// use these bookkeeping variables to let me know when a window resize has occurred
// (and then configure the visualizations accordingly).
int _frameWidthOnLastDraw = -1;
int _frameHeightOnLastDraw = -1;
int _mapLabelToParticleSystemSizeOnLastDraw = 0;

// There is often garbage on the serial port. We wait 10 lines before
// actually parsing and using content
int _ignoreFirstNumLines = 10;
int _initializationLinesRead = 0;

PFont _axisFont = null;
StringList _labels = new StringList();

HashMap<String, ParticleSystem> _mapLabelToParticleSystem = new HashMap<String, ParticleSystem>();

void setup () {
  // set the window size:
  size(1100, 550);

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
  _serialPort = new Serial(this, Serial.list()[4], 9600);

  // don't generate a serialEvent() unless you get a newline character:
  _serialPort.bufferUntil('\n');

  // set inital background:
  background(0);
  
}

void draw () {

  if (width != _frameWidthOnLastDraw || height != _frameHeightOnLastDraw || 
     _mapLabelToParticleSystem.size() != _mapLabelToParticleSystemSizeOnLastDraw) {  
    // if we're here, then either the window has been resized or we've got a brand new GraphData
    // object. Either way, we need to reconfigure our visualizations to resize things!
    
    _pg.setSize(width, height);
  }

  // We draw to an offscreen buffer and then bitblt to the screen to reduce flickering
  _pg.beginDraw();
  //_pg.blendMode(ADD);
  _pg.background(_backgroundColor);

   for (String label : _labels) {
      ParticleSystem particleSystem = _mapLabelToParticleSystem.get(label);
      particleSystem.run();
   }

  _pg.endDraw();
  image(_pg, 0, 0);

  _frameWidthOnLastDraw = width;
  _frameHeightOnLastDraw = height;
  _mapLabelToParticleSystemSizeOnLastDraw = _mapLabelToParticleSystem.size();
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

          if (!_mapLabelToParticleSystem.containsKey(label)) {
            
            //int colorIndex = (int)random(_analogColorPalette.size()); 
            int colorIndex = 0;
            IntList colorPalette = isAnalog ? _analogColorPalette : _digitalColorPalette;
            int strokeWeight = isAnalog ? DEFAULT_GRAPH_ANALOG_DATA_STROKE_WEIGHT : DEFAULT_GRAPH_DIGITAL_DATA_STROKE_WEIGHT;
            color c = colorPalette.size() > 0 ? colorPalette.get(colorIndex) : color(255);
            c = color(red(c), green(c), blue(c), DEFAULT_GRAPH_DATA_OPACITY);
            colorPalette.remove(colorIndex);
            
            PVector emitterLocation = new PVector(50 + random(width-100), 50 + random(height * 0.2f));
            ParticleSystem particleSystem = new ParticleSystem(_pg, emitterLocation, label, c, c, strokeWeight, isAnalog);

            if (isAnalog) {
              _numAnalogInputs++;
            } else {
              _numDigitalInputs++;
            }        

            _mapLabelToParticleSystem.put(label, particleSystem);
            _labels.append(label);
          }

          ParticleSystem particleSystem = _mapLabelToParticleSystem.get(label);
          
          if(value >= 1){
            if(isAnalog){
              particleSystem.addParticle(value/20f);
            }else{
              particleSystem.addParticle(DEFAULT_DIGITAL_PARTICLE_SIZE);
            }
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


// A class to describe a group of Particles
// An ArrayList is used to manage the list of Particles 
// Based on https://processing.org/examples/simpleparticlesystem.html
class ParticleSystem {
  ArrayList<Particle> particles;
  PVector origin;
  String label;
  color fillColor;
  color strokeColor;
  int strokeWeight = 1;
  boolean isAnalog = true;
  boolean isMotionEnabled = DEFAULT_PARTICLE_EMITTER_MOTION_ENABLED;
  
  private PGraphics _pg;
  private float _xMovementTime = random(200);  
  private float _yMovementTime = random(200);
  private float _movementIncrement = 0.0008;  

  ParticleSystem(PGraphics pg, PVector location, String label, color fillColor, color strokeColor, int strokeWeight, boolean isAnalog) {
    origin = location.get();
    
    particles = new ArrayList<Particle>();
    _pg = pg;
    this.label = label;
    this.fillColor = fillColor;
    this.strokeColor = strokeColor;
    this.strokeWeight = strokeWeight;
    this.isAnalog = isAnalog;
  }

  void addParticle(float size) {
    if(isAnalog){
      particles.add(new Particle(origin, size, fillColor, strokeColor, strokeWeight));
    }else{
      particles.add(new CrazyParticle(origin, size, fillColor, strokeColor, strokeWeight));
    }
  }

  void run() {
    
    if(isMotionEnabled){
      origin.x = noise(_xMovementTime)*width;  
      origin.y = noise(_yMovementTime)*height;  
      _xMovementTime += _movementIncrement;  
      _yMovementTime += _movementIncrement;
    }
    
    for (int i = particles.size()-1; i >= 0; i--) {
      Particle p = particles.get(i);
      p.run(_pg);
      if (p.isDead()) {
        particles.remove(i);
      }
    }
    
    //draw label
    float fontSize = 24;
    _pg.textFont(_axisFont, fontSize);  // Specify font to be used
    float textWidth = _pg.textWidth(label);
    _pg.fill(245, 245, 245, 128); // Specify font color 
    _pg.text(this.label, origin.x - textWidth/2.0, origin.y - fontSize / 2f);
  }
}


// A simple Particle class based on https://processing.org/examples/simpleparticlesystem.html
class Particle {
  PVector location;
  PVector velocity;
  PVector acceleration;
  float lifespan;
  float size;
  color strokeColor;
  color fillColor;
  int strokeWeight;

  Particle(PVector l, float size, color fillColor, color strokeColor, int strokeWeight) {
    acceleration = new PVector(0,0.05);
    velocity = new PVector(random(-1,1),random(-2,0));
    location = l.get();
    lifespan = 125;
    this.size = size;
    this.fillColor = fillColor;
    this.strokeColor = strokeColor;
    this.strokeWeight = strokeWeight;
  }

  void run(PGraphics pg) {
    update();
    display(pg);
  }

  // Method to update location
  void update() {
    velocity.add(acceleration);
    location.add(velocity);
    lifespan -= 1.0;
  }

  // Method to display
  void display(PGraphics pg) {
    color newStrokeColor = color(red(this.strokeColor), green(this.strokeColor), blue(this.strokeColor), lifespan);
    pg.stroke(newStrokeColor);
    color newFillColor = color(red(this.fillColor), green(this.fillColor), blue(this.fillColor), lifespan);
    pg.fill(newFillColor);
    pg.ellipse(location.x,location.y,size,size);
  }
  
  // Is the particle still useful?
  boolean isDead() {
    if (lifespan < 0.0) {
      return true;
    } else {
      return false;
    }
  }
}

// A subclass of Particle
// Based on https://processing.org/examples/multipleparticlesystems.html
class CrazyParticle extends Particle {

  // Just adding one new variable to a CrazyParticle
  // It inherits all other fields from "Particle", and we don't have to retype them!
  float theta;

  // The CrazyParticle constructor can call the parent class (super class) constructor
  CrazyParticle(PVector l, float size, color fillColor, color strokeColor, int strokeWeight) {
    // "super" means do everything from the constructor in Particle
    super(l, size, fillColor, strokeColor, strokeWeight);
    // One more line of code to deal with the new variable, theta
    theta = 0.0;
  }

  // Notice we don't have the method run() here; it is inherited from Particle

  // This update() method overrides the parent class update() method
  void update() {
    super.update();
    // Increment rotation based on horizontal velocity
    float theta_vel = (velocity.x * velocity.mag()) / 10.0f;
    theta += theta_vel;
  }

  // This display() method overrides the parent class display() method
  void display(PGraphics pg) {
    // Render the ellipse just like in a regular particle
    super.display(pg);
    // Then add a rotating line
    pg.pushMatrix();
    pg.translate(location.x,location.y);
    pg.rotate(theta);
    color newStrokeColor = color(red(this.strokeColor), green(this.strokeColor), blue(this.strokeColor), lifespan);
    pg.stroke(newStrokeColor);
    //stroke(255,lifespan);
    pg.line(0,0,25,0);
    pg.popMatrix();
  }

}
