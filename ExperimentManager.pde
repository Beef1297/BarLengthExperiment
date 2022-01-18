enum VibrationMode {
  SHRINK,
    EXPAND
}

public class ExperimentManager {

  MyOSCClient oscClient = new MyOSCClient();
  // csv logging
  Table illusionTable;
  // for load conditions
  public Table conditionTable;
  public Table practiceConditionTable;

  int illusionPerceived = 0; // if illusion is induced, turn to 1;
  int conditionIndex = 0;
  int conditionNum = 0;

  int startTime = 0; // milliseconds
  public int vibrationTime = 10; // seconds
  public float vibrationFreq = 70;
  public int resetLength = 300;
  VibrationMode vibrationMode;

  String subject;

  String conditionHeader = "condition";
  String lengthHeader = "initLength";
  String freqHeader = "freq";
  String modeHeader = "mode";

  // constructor
  ExperimentManager(String _subject) {
    vibrationInit();
    //resetTable();
    this.subject = _subject;
  }

  int popupStartTime = -1;
  String popupText;
  public void setPopup(String _text) {
    this.popupStartTime = millis();
    this.popupText = _text;
  }

  public void displayTempPopup() {
    if (this.popupStartTime < 0) return;
    int t = millis() - this.popupStartTime;
    float val = t/2000.0;
    if (val > 1.0) {
      this.popupStartTime = -1;
      return;
    }
    textSize(16);
    fill(255*val);
    text(this.popupText, 100, height - 100);
  }

  // load next condition
  public void setNextCondition() {

    if (conditionIndex >= conditionTable.getRowCount()) {
      println("all conditions have conducted!!");
      state = State.FINISH;
    } else {
      TableRow _row = conditionTable.getRow(conditionIndex);
      this.vibrationFreq = _row.getInt(freqHeader);
      this.resetLength = _row.getInt(lengthHeader);
      String _m = _row.getString(modeHeader);
      barLength = this.resetLength;
      // set freq
      this.oscClient.setAllFreq(this.vibrationFreq);
      // set vibration mode
      if (_m.equals("s")) {
        println("shrink");
        this.vibrationMode = VibrationMode.SHRINK;
      } else if (_m.equals("e")) {
        println("expand");
        this.vibrationMode = VibrationMode.EXPAND;
      }
      state = State.NONE;

      println("loaded next condition!");
      this.conditionIndex += 1;
    }
  }


  public void loadConditionTable() {
    String _file = "conditions/" + this.subject + ".csv";
    println(_file);
    this.conditionTable = loadTable(_file, "header");
    println("condition num: " + this.conditionTable.getRowCount());
  }

  public void resetIllusionTable() {
    this.illusionTable = new Table();
    this.illusionTable.addColumn("frame");
    this.illusionTable.addColumn("millis");
    this.illusionTable.addColumn("illusion");
  }

  public void resetLengthTable() {
    this.illusionTable = new Table();
    this.illusionTable.addColumn("length");
  }

  // on exit
  public void onExit() {
    this.oscClient.audioOFF();
  }

  public void update(State _state) {

    if (_state == State.VIBRATION) {
      TableRow _newRow = this.illusionTable.addRow();
      _newRow.setInt("frame", frameCount);
      _newRow.setInt("millis", millis());
      _newRow.setInt("illusion", illusionPerceived);

      //println(millis() - startTime);
      // it has been passed resetTime after vibration on
      if ((millis() - this.startTime)/1000.0 >= vibrationTime) {
        this.stopVibration();
        state = State.MEASURE_LENGTH;
      }
    } else if (_state == State.DEBUG_VIBRATION) {
      if ((millis() - this.startTime)/1000.0 >= vibrationTime) {
        state = State.NONE;
        this.oscClient.setAllGate(0);
      }
    }
  }


  // wait application for millis by inserting loop in main thread
  // FIXME: bad method
  public void waitForMillis(int _ms) {
    int _currentMillis = millis();
    int _localTimer = 0;
    while (_localTimer <= _ms) {
      _localTimer = millis() - _currentMillis;
    }
  }

  public void measureLength() {
    if (state == State.FINISH) return;
    resetLengthTable();
    TableRow _newRow = this.illusionTable.addRow();
    _newRow.setFloat("length", barLength);

    String _file = "data/" + this.subject + "/" + this.conditionIndex + "-length.csv";
    saveTable(this.illusionTable, _file);
    this.setPopup("saved length");
  }

  // -----------------
  public void vibrationInit() {
    // settings of OSC
    this.oscClient.init();
    this.oscClient.audioON();
  }

  public void stopVibration() {
    if (state == State.FINISH) return;
    // vibration off
    this.oscClient.setAllGate(0);

    // save table
    String _file = "data/" + this.subject + "/" + this.conditionIndex + "-illusion.csv";
    saveTable(this.illusionTable, _file);
    this.setPopup("saved illusion table");
  }

  public void startVibration() {
    if (state == State.FINISH) return;
    // initialize variables for starting trial
    resetIllusionTable();
    this.startTime = millis();
    this.illusionPerceived = 0;

    if (this.vibrationMode == null) {
      println("vibration mode is null! something is wrong.");
    }

    //oscClient.setAmp(1, 0.5); // temp
    if (this.vibrationMode == VibrationMode.EXPAND) {
      // for shrinkg vib
      this.oscClient.setGate(1, 1);
      this.oscClient.setGate(2, 1);
      this.oscClient.setGate(5, 1);
      this.oscClient.setGate(6, 1);
    } else if (this.vibrationMode == VibrationMode.SHRINK) {
      // for expand vib
      this.oscClient.setGate(3, 1);
      this.oscClient.setGate(4, 1);
      this.oscClient.setGate(7, 1);
      this.oscClient.setGate(8, 1);
    }
  }

  public void expandVibration() {
    this.oscClient.setGate(1, 1);
    this.oscClient.setGate(2, 1);
    this.oscClient.setGate(5, 1);
    this.oscClient.setGate(6, 1);
    state = State.DEBUG_VIBRATION;
    this.startTime = millis();
  }

  public void shrinkVibration() {
    this.oscClient.setGate(3, 1);
    this.oscClient.setGate(4, 1);
    this.oscClient.setGate(7, 1);
    this.oscClient.setGate(8, 1);
    state = State.DEBUG_VIBRATION;
    this.startTime = millis();
  }


  // ---------------
  public void illusionInduced() {
    println("illusion induced !!");
    this.illusionPerceived = 1;
  }
}
