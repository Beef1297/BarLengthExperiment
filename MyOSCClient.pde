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

  void sendOSC(String address, float val) {
    /* create a new OscMessage with an address pattern, in this case /test. */
    OscMessage myOscMessage = new OscMessage(address);
    /* add a value (an integer) to the OscMessage */
    myOscMessage.add(val);
    /* send the OscMessage to a remote location specified in myNetAddress */
    oscP5.send(myOscMessage, broadcast);
  }

  void audioON() {
    audioState = 1;
    sendOSC("/on", audioState);
  }

  void audioOFF() {
    audioState = 0;
    sendOSC("/on", audioState);
  }

  void toggleAudioOutput() {
    audioState = (audioState + 1) % 2;
    sendOSC("/on", audioState);
  }
  
  void setFreq(int ch, float freq) {
    String address = "/" + ch + "/freq";
    sendOSC(address, freq);
  }
  
  void setAmp(int ch, float amp) {
    String address = "/" + ch + "/amp";
    sendOSC(address, amp);
  }

  void init() {
    audioOFF();
    for (int i = 1; i <= 4; i++) {
      setFreq(i, 70.0);
      setAmp(i, 0.0);
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
