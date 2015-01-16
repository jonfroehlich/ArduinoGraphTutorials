# Arduino Graph Tutorials

This repo includes a series of Processing graph examples meant to help others learn about graphing Arduino output and creating visualizations in Processing

To run this Processing sketch, your Arduino must be plugged in and communicating over the serial port (you must configure the port in each .pde file). 

1. ArduinoGraph1.pde : The simplest--essentially Tom Igoe's original code (http://arduino.cc/en/Tutorial/Graph)
2. ArduinoGraph2SimpleScrolling.pde : changes visualization to scrolling rather than looping
3. ArduinoGraph3SimpleScrollingDoubleBuffered.pde : adds in double buffering
4. ArduinoGraph4SimpleScrollingDoubleBufferedResizable.pde : adds in responsive window resizing
5. ArduinoGraph5AnalogOnly.pde : adds in support for handling multiple channels of analog input (note: the data format changes)
6. ArduinoGraph6DigitalAndAnalog.pde : adds in support for digital input channels

The first four examples are simple, the fifth example is intermediate (ArduinoGraph5AnalogOnly.pde), and the last 
example (ArduinoGraph6DigitalAndAnalog.pde) is more advanced

## Serial Port Data Format (Examples 1-4)
For the first four examples, the serial port data must be formatted like the following. 

```
value1\n
value2\n
value3\n 
... 
valueN
```

That is:
```
22\n
34\n
45\n
124\n
...
N
```

Note how you do not have to print the character '\n' as this is simply the newline character and automatically added by the println function. You can use any Arduino sketch that prints values like this to the serial port but I suggest you start with PrintSingleAnalogInputForProcessing.ino. This simply prints A0 to the serial port:

```
Serial.println(analogRead(A0));
```

The full program, in fact, is nearly that simple:

```
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
```

## Serial Port Data Format (Examples 5-6)
For examples #5 and #6, there is a more advanced comma-separated format:
```
label1=value1, label2=value2, label3=value3, ... labelN=valueN\n
label1=value1, label2=value2, label3=value3, ... labelN=valueN\n
label1=value1, label2=value2, label3=value3, ... labelN=valueN\n
```

That is:
```
A0=120, A2=240, A4=600\n
A0=562, A2=240, A4=300\n
A0=450, A2=240, A4=400\n
A0=321, A2=240, A4=500\n
```

Again, you can use any Arduino sketch that prints values like this to the serial port but I suggest you start with PrintInputsForProcessing.ino (which is in this repo).

## Known Problems
There is a concurrent read/write problem on the primary data object (_mapLabelToGraphData) in the more complex examples. This is because the UI thread can reformat the data object to deal with window resizing while the serial port method is simultaneously adding new data (this is bad!). I couldn't figure out how to create proper thread synchronization (e.g., via a lock object) in Processing. So, instead, I just put try/catches around access to this object.

## About
Code by Professor Jon Froehlich
jonfroehlich@gmail.com
Written for CMSC838f Tangible Interactive Computing
http://cmsc838f-s15.wikispaces.com/

