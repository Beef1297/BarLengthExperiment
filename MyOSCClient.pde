import oscP5.*;
import netP5.*;

class MyOSCClient {
  public OscP5 oscP5;
  public NetAddress broadcast;
  String localAddress = "127.0.0.1";
  int oscPort = 3333;
  int audioState = 0;

  MyOSCClient() {
    oscP5 = new OscP5(this, 12000);
    broadcast = new NetAddress(localAddress, oscPort);
  }

  public void sendOSC(String address, float val) {
    /* create a new OscMessage with an address pattern, in this case /test. */
    OscMessage myOscMessage = new OscMessage(address);
    /* add a value (an integer) to the OscMessage */
    myOscMessage.add(val);
    /* send the OscMessage to a remote location specified in myNetAddress */
    oscP5.send(myOscMessage, broadcast);
  }

  public void audioON() {
    audioState = 1;
    sendOSC("/on", audioState);
  }

  public void audioOFF() {
    audioState = 0;
    sendOSC("/on", audioState);
  }

  public void toggleAudioOutput() {
    audioState = (audioState + 1) % 2;
    sendOSC("/on", audioState);
  }

  public void setGate(int ch, int val) {
    String address = "/" + ch + "/gate";
    sendOSC(address, val);
  }

  public void setAllGate(int val) {
    for (int i = 1; i <= 8; i++) {
      String address = "/" + i + "/gate";
      sendOSC(address, val);
    }
  }

  public void setFreq(int ch, float freq) {
    String address = "/" + ch + "/freq";
    sendOSC(address, freq);
  }

  //public void setAllAmp(float amp) {
  //  for (int ch = 1; ch <= 8; ch++) {
  //    String address = "/" + ch + "/amp";
  //    sendOSC(address, amp);
  //  }
  //}

  public void setAllFreq(float freq) {
    for (int ch = 1; ch <= 8; ch++) {
      String address = "/" + ch + "/freq";
      sendOSC(address, freq);
    }
  }

  //public void setAmp(int ch, float amp) {
  //  String address = "/" + ch + "/amp";
  //  sendOSC(address, amp);
  //}

  public void init() {
    audioOFF();
    for (int i = 1; i <= 4; i++) {
      setFreq(i, 70.0);
      //setAmp(i, 0.0); // do not change preset amplitude
      setGate(i, 0);
    }
  }

  //void setup() {
  //  size(600, 400);
  //  frameRate(150);
  //  oscP5 = new OscP5(this, 12000);
  //  broadcast = new NetAddress(localAddress, oscPort);

  //  audioON();
  //}

  float v = 0;
  void send_test() {
    v = (v+0.01) % 0.5;
    sendOSC("/1/amp", v);
  }

  //void mousePressed() {
  //  audioOFF();
  //  exit();
  //}
}
