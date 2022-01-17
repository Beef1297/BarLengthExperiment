import processing.serial.*;

public enum Mode {
  EXPAND(0x0f),
    SHRINK(0x0e),
    TOGGLE(0x0d),
    NONE(0x0c),
    ;
  private int val;
  private Mode(int _val) {
    this.val = _val;
  }
  public int getInt() {
    return this.val;
  }
}
// experiment state enum
public enum State {
  VIBRATION,
    MEASURE_LENGTH,
    FINISH,
    NONE;
}

float pixelPitch = 0.311; // mm

// serial
Serial serial;
String portNum = "COM5";
int baudrate = 115200;

final float DEFAULT_LENGTH = 300; // mm

Mode mode = Mode.NONE;
State state = State.NONE;

//float velocity = 1.0; // mm/s

String subject = "test";
ExperimentManager em = new ExperimentManager(subject);


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

  // debug
  //state = State.MEASURE_LENGTH;
  //
  frameRate(50);

  // experiment manager
  em.loadConditionTable(); // this method must be called in setup();
  // set first condition
  em.setNextCondition();
}

int counter = 0;
int receivedByte = 0;
void serialEvent(Serial p) {
  if (p.available() > 1) {
    while (p.read() != 0xFF) p.read();

    receivedByte = p.read();
    if (state == State.VIBRATION) {
      // if button is pushed while presenting vibration,
      // that will mean illusion is induced.
      if (receivedByte != Mode.NONE.getInt()) {
        em.illusionInduced();
      }
    } else if (state == State.MEASURE_LENGTH) {
      //print(val, counter);
      if (receivedByte == Mode.EXPAND.getInt()) {
        mode = Mode.EXPAND;
        //velocity += 1.0;
      } else if (receivedByte == Mode.SHRINK.getInt()) {
        mode = Mode.SHRINK;
        //velocity -= 1.0;
      } else if (receivedByte == Mode.TOGGLE.getInt()) {
        mode = Mode.TOGGLE;
      } else {
        mode = Mode.NONE;
      }
    }
    //println(val, counter);
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
  //boolean changing = mode == Mode.EXPAND || mode == Mode.SHRINK;
  if (mode == Mode.EXPAND) {
    barLength += 0.1;
  } else if (mode == Mode.SHRINK) {
    barLength -= 0.1;
  } else if (mode == Mode.TOGGLE) {
    // FIXME: It's difficult to stop by just one time... because need to push at
    // the "very" same timing.
  } else if (mode == Mode.NONE) {
  }
}

float t;
float barLength = 300.0;
float widthAdjust = 0.95;
float heightAdjust = 1/20.0;
color backgroundColor = color(255, 255, 255);
//float vibrationTime = 10;
//int frameTimer = 0;
void draw() {
  if (state == State.VIBRATION) {
    background(255, 255, 255); // reset
  } else if (state == State.MEASURE_LENGTH) {
    background(255, 220, 220);
  } else if (state == State.FINISH) {
    background(220, 255, 220);
  } else {
    background(255);
  }
  // --- text --
  textSize(32);
  fill(0);
  text("Length: "+barLength+" mm", width/8, height/24, 0);
  //text("Velocity: "+velocity+" mm/s", width/8, 2*height/24, 0);
  text("Received Byte: "+receivedByte, width/8, 2*height/24, 0);
  text("Frame Rate: "+frameRate, width/8, 3*height/24, 0);
  // ------

  // rendering cylinder
  pushMatrix();
  lights();
  translate(width/2, height/2);
  strokeWeight(1);
  noStroke();
  fill(150, 150, 150);
  cylinder(24, mmToPix(300 * heightAdjust), mmToPix(barLength*widthAdjust));
  //height: 20 -> 400mm : set by 1/20
  //width: 100 -> 105 : set by 0.95
  // for check length
  //translate(0, -height/4);
  //cylinder(24, mmToPix(30 * heightAdjust), mmToPix(10*widthAdjust));
  popMatrix();
  // ----

  em.update(state);


  changeParameter();
}

void resetBarLength() {
  barLength = DEFAULT_LENGTH;
}

void keyPressed() {
  if (key == 'r') {
    //reset
    barLength = DEFAULT_LENGTH;
  }

  if (key == 's') {
    // start trial
    state = State.VIBRATION;
    em.startVibration();
  }

  if (key == 'm') {
    // measure length
    em.measureLength();
    em.waitForMillis(500);
    em.setNextCondition();
  }

  if (key == 'i') {
    // debug illusion induced
    em.illusionInduced();
  }
}

void exit() {
  em.onExit();
  super.exit();
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
