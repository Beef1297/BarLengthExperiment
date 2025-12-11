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
  public Table vibrationAmpTable;

  int illusionPerceived = 0; // if illusion is induced, turn to 1;
  int conditionIndex = 0;
  int practiceIndex = 0;
  int conditionNum = 0;

  int startTime = 0; // milliseconds
  public int vibrationTime = 10; // seconds
  public float vibrationFreq = 70;
  VibrationMode vibrationMode;

  public int resetLength = 300;
  float initBarLength = 0.0;

  String subject;

  String conditionHeader = "condition";
  String lengthHeader = "initLength";
  String freqHeader = "freq";
  String modeHeader = "mode";

  Boolean isPractice = false;

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
    this.popupText = this.popupText + " " + _text;
  }

  public void displayTempPopup() {
    if (this.popupStartTime < 0) return;
    int t = millis() - this.popupStartTime;
    float val = t/2000.0;
    if (val > 0.8) {
      this.popupStartTime = -1;
      this.popupText = "";
      return;
    }
    textSize(16);
    fill(255 * val);
    text(this.popupText, 100, height - 100);
  }

  public void setFrequency(int id) {
    if (id == 0) {
      this.vibrationFreq = 70;
    } else {
      this.vibrationFreq = 220;
    }
    this.oscClient.setAllFreq(this.vibrationFreq);
    this.setAmplitudeByFrequency();
  }

  public void resetExperimentConditions() {
    this.conditionIndex = 0;
    this.setNextCondition();
  }

  // load next condition
  public void setNextCondition() {
    if (isPractice) {
      barLength = this.resetLength;
      state = State.ADJUST_INIT_LENGTH;
      return;
    }

    if (conditionIndex >= conditionTable.getRowCount()) {
      println("all conditions have conducted!!");
      state = State.FINISH;
    } else {
      TableRow _row = conditionTable.getRow(conditionIndex);
      this.conditionNum = _row.getInt(conditionHeader);
      this.vibrationFreq = _row.getInt(freqHeader);
      this.resetLength = _row.getInt(lengthHeader);
      String _m = _row.getString(modeHeader);
      barLength = this.resetLength;
      // set freq
      this.oscClient.setAllFreq(this.vibrationFreq);
      this.setAmplitudeByFrequency();
      // set vibration mode
      if (_m.equals("s")) {
        println("shrink");
        this.vibrationMode = VibrationMode.SHRINK;
      } else if (_m.equals("e")) {
        println("expand");
        this.vibrationMode = VibrationMode.EXPAND;
      }
      state = State.ADJUST_INIT_LENGTH;

      this.setPopup("loaded next condition. index: " + this.conditionIndex + "num: " + this.conditionNum);
      this.conditionIndex += 1;
    }
  }

  public void setAmplitudeByFrequency() {
    if (this.vibrationFreq == 70) {
      TableRow _row = vibrationAmpTable.getRow(0);
      for (int i = 1; i <= 8; i++) {
        this.oscClient.setAmp(i, _row.getFloat(str(i)));
      }
    } else if (this.vibrationFreq >= 200) {
      TableRow _row = vibrationAmpTable.getRow(1);
      for (int i = 1; i <= 8; i++) {
        this.oscClient.setAmp(i, _row.getFloat(str(i)));
      }
    }
  }


  public void loadConditionTable() {
    // vibration amp
    String _ampFile = this.subject + "/vibration-volume.csv";
    this.vibrationAmpTable = loadTable(_ampFile, "header");
    // practice conditions
    String _practiceFile = "conditions/practice.csv";
    this.practiceConditionTable = loadTable(_practiceFile, "header");
    // experiment conditions
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
      }
    } else if (_state == State.DEBUG_VIBRATION || _state == State.PRACTICE) {
      if ((millis() - this.startTime)/1000.0 >= vibrationTime) {
        this.stopVibration();
      }
    }
  }

  String timestamp() {
    return year() + "-" + month() + "-" + day() + "-" + hour() + "-" + minute() + "-" + second();
  }

  // wait application for millis by inserting loop in main thread
  // FIXME: bad method
  public void waitForMillis(int _ms) {
    int _currentMillis = millis();
    int _localTimer = 0;
    while (_localTimer <= _ms) {
      //this.displayTempPopup();
      _localTimer = millis() - _currentMillis;
    }
  }
  // ----------------------
  public void practice() {
    state = State.PRACTICE;
    this.isPractice = true;

    if (this.practiceIndex >= practiceConditionTable.getRowCount()) {
      this.setPopup("all practice conditions have conducted!!");
      state = State.ADJUST_INIT_LENGTH;
      this.isPractice = false;
    } else {
      TableRow _row = practiceConditionTable.getRow(this.practiceIndex);
      this.vibrationFreq = _row.getInt(this.freqHeader);
      this.resetLength = _row.getInt(this.lengthHeader);
      String _m = _row.getString(this.modeHeader);

      // set freq
      this.oscClient.setAllFreq(this.vibrationFreq);
      this.setAmplitudeByFrequency();
      // set vibration mode
      if (_m.equals("s")) {
        println("[practice] shrink");
        this.vibrationMode = VibrationMode.SHRINK;
      } else if (_m.equals("e")) {
        println("[practice] expand");
        this.vibrationMode = VibrationMode.EXPAND;
      }
      this.setPopup("practice condition index: " + str(this.practiceIndex));
      println("[practice] loaded next condition!");
      this.practiceIndex += 1;

      this.waitForMillis(250);
      this.startVibration();
    }
  }

  // -----------------------

  public void measureLength() {
    if (state == State.FINISH || isPractice) return;

    resetLengthTable();
    TableRow _newRow = this.illusionTable.addRow();
    _newRow.setFloat("length", this.initBarLength);
    _newRow = this.illusionTable.addRow();
    _newRow.setFloat("length", barLength);

    String _file = "data/" + this.subject + "/" + this.conditionNum + "-length-"
      + timestamp() + ".csv";
    saveTable(this.illusionTable, _file);
    this.setPopup("saved length");
  }

  // -----------------
  public void vibrationInit() {
    // settings of OSC
    this.oscClient.init();
    this.oscClient.audioON();
  }
  
  public void audioStop() {
    this.oscClient.audioOFF();
    this.oscClient.setAllGate(0);
  }

  public void stopVibration() {
    if (state == State.FINISH) return;
    // vibration off
    this.oscClient.setAllGate(0);

    // save table
    if (state == State.VIBRATION) {

      String _file = "data/" + this.subject + "/" + this.conditionNum + "-illusion-" +
        timestamp() + ".csv";
      saveTable(this.illusionTable, _file);
      this.setPopup("saved illusion table");
    }
    // after vibration, set MEASURE_LENGTH state
    if (state != State.DEBUG_VIBRATION) state = State.MEASURE_LENGTH;
  }

  public void againTrial() {
    this.conditionIndex -= 2;
    this.setNextCondition();
  }

  public void startVibration() {
    if (state == State.FINISH) return;
    // initialize variables for starting trial
    this.oscClient.audioON();
    resetIllusionTable();
    //this.isPractice = false;
    this.startTime = millis();
    this.illusionPerceived = 0;
    this.initBarLength = barLength;

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
