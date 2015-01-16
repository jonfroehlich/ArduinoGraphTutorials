Code by Professor Jon Froehlich
jonfroehlich@gmail.com
Written for CMSC838f Tangible Interactive Computing
http://cmsc838f-s15.wikispaces.com/

This repo includes a series of Processing graph examples meant to help others
learn about graphing Arduino output and creating visualizations in Processing

To run this Processing sketch, your Arduino must be plugged in and communicating over the serial port
(you must configure the port in each .pde file). 

1. ArduinoGraph1.pde : The simplest--essentially Tom Igoe's original code
2. ArduinoGraph2SimpleScrolling.pde : changes visualization to scrolling rather than looping
3. ArduinoGraph3SimpleScrollingDoubleBuffered.pde : adds in double buffering
4. ArduinoGraph4SimpleScrollingDoubleBufferedResizable.pde : adds in responsive window resizing
5. ArduinoGraph5AnalogOnly.pde : adds in support for handling multiple channels of analog input (note: the data format changes)
6. ArduinoGraph6DigitalAndAnalog.pde : adds in support for digital input channels

The first four examples are simple, the fifth example is intermediate (ArduinoGraph5AnalogOnly.pde), and the last 
example (ArduinoGraph6DigitalAndAnalog.pde) is more advanced

== DATA FORMAT ON SERIAL PORT ==
For the first four examples, the serial port data must be formatted like:

value1\nvalue2\nvalue3\n ... valueN

That is:
22
34
45
124
...
N

You can use any Arduino sketch that prints values like this to the serial port but I suggest
you start with PrintSingleAnalogInputForProcessing.ino 

For examples #5 and #6, there is a more advanced comma-separated format:
label1=value1, label2=value2, label3=value3, ... labelN=valueN\n
label1=value1, label2=value2, label3=value3, ... labelN=valueN\n
label1=value1, label2=value2, label3=value3, ... labelN=valueN\n

That is:
A0=120, A2=240, A4=600\n
A0=562, A2=240, A4=300\n
A0=450, A2=240, A4=400\n
A0=321, A2=240, A4=500\n

== KNOWN PROBLEMS ==
There is a concurrent read/write problem on the primary data object (_mapLabelToGraphData) in the resizable examples. This is
because the UI thread reformats the data object to deal with window resizing while the serial port method
is adding new data. I couldn't figure out how to create proper thread synchronization (E.g., via a lock object)
in Processing. So, instead, I just put try/catches around access to this object.
