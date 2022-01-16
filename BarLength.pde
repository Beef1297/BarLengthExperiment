import processing.serial.*;

float pixelPitch = 0.311; // mm

// serial
Serial serial;
String portNum = "COM5";
int baudrate = 115200;

final float DEFAULT_LENGTH = 300; // mm
// const val for serial
final int EXPAND = 0x0f;
final int SHRINK = 0x0e;
final int TOGGLE = 0x0d;
final int NONE = 0x0c;
int mode = NONE;

float velocity = 1.0; // mm/s

// csv logging
Table table;
ArrayList<Integer> illusionCheck = new ArrayList<Integer>();

// experiment state enum
enum State {
  VIBRATION,
  MEASURE,
  NONE;
}
State state = State.NONE;

// -- for velocity-based control --
boolean canChange = false;
boolean isMoving = false;

// OSC Client for vibration
MyOSCClient oscClinet = new MyOSCClient();

void setup() {
  fullScreen(P3D, 1);
  //String[] list = Serial.list();
  //println(list.length);
  try {
    serial = new Serial(this, Serial.list()[0], baudrate);
  }
  catch (ArrayIndexOutOfBoundsException e) {
    e.printStackTrace();
    exit();
  }
  
  // settings of OSC
  oscClinet.init();
  oscClinet.audioON();
  
  frameRate(50);
}

int counter = 0;
void serialEvent(Serial p) {
  if (p.available() > 1) {
    while (p.read() != 0xFF) p.read();

    int val = p.read();
    if (val == EXPAND) {
      mode = EXPAND;
      //velocity += 1.0;
    } else if (val == SHRINK) {
      mode = SHRINK;
      //velocity -= 1.0;
    } else if (val == TOGGLE) {
      mode = TOGGLE;
    } else {
      mode = NONE;
    }
    println(val, counter);
    counter++;
  }
}


// I want to use Camera Matrix for conversion
float pixToMM(float pix) {
  return pix * pixelPitch;
}

float mmToPix(float mm) {
  return mm / pixelPitch;
}

void changeParameter() {
  boolean changing = mode == EXPAND || mode == SHRINK;
  if (mode == EXPAND) {
    barLength += 0.1;
    //velocity += 1.0;
    canChange = false;
  } else if (mode == SHRINK) {
    barLength -= 0.1;
    //velocity -= 1.0;
    canChange = false;
  } else if (mode == TOGGLE && (canChange || changing)) {
    // FIXME: It's difficult to stop by just one time... because need to push at
    // the "very" same timing.
    //velocity = 0;
    isMoving = !isMoving;
    canChange = false;
  } else if (mode == NONE) {
    canChange = true;
  }
}

float t;
float barLength = 300.0;
float widthAdjust = 0.95;
float heightAdjust = 1/20.0;
float resetTime = 10;
int frameTimer = 0;
void draw() {
  background(255);
  textSize(32);
  fill(0);
  text("Length: "+barLength+" mm", width/8, height/24, 0);
  text("Velocity: "+velocity+" mm/s", width/8, 2*height/24, 0);
  text("Frame Rate: "+frameRate, width/8, 3*height/24, 0);

  pushMatrix();
  lights();
  translate(width/2, height/2);
  strokeWeight(1);
  noStroke();
  fill(150, 150, 150);
  cylinder(24, mmToPix(300 * heightAdjust), mmToPix(barLength*widthAdjust));
  //height: 20 -> 400mm : set by 1/20
  //width: 100 -> 105 : set by 0.95
  
  translate(0, -height/4);
  cylinder(24, mmToPix(30 * heightAdjust), mmToPix(10*widthAdjust));
  popMatrix();

  // for velocity-based change
  if (isMoving) {
    barLength += velocity / frameRate;
    frameTimer += 1;

    if (frameTimer >= resetTime * frameRate || barLength >= 590) {
      frameTimer = 0;
      barLength = DEFAULT_LENGTH;
    }
  }
  changeParameter();
}

void expandVibration() {
  
}

void shrinkVibration() {
  
}

void keyPressed() {
  if (key == 'r') {
    //reset
    barLength = DEFAULT_LENGTH;
  }

  if (key == 's') {
    // start trial
    state = State.VIBRATION;
    
  }
}

void cylinder(int sides, float r, float h) {
  float angle = 360.0 / sides;
  float halfHeight = h / 2.0;
  beginShape();
  for (int i = 0; i < sides; i++) {
    float x = cos(radians(i * angle)) * r;
    float y = sin(radians(i * angle)) * r;
    vertex(-halfHeight, y, x);
  }
  endShape(CLOSE);
  beginShape();
  for (int i = 0; i < sides; i++) {
    float x = cos(radians(i * angle)) * r;
    float y = sin(radians(i * angle)) * r;
    vertex(halfHeight, y, x);
  }
  endShape(CLOSE);
  // draw body
  beginShape(TRIANGLE_STRIP);
  for (int i = 0; i < sides + 1; i++) {
    float x = cos( radians( i * angle ) ) * r;
    float y = sin( radians( i * angle ) ) * r;
    vertex(halfHeight, y, x);
    vertex(-halfHeight, y, x);
  }
  endShape(CLOSE);
}
