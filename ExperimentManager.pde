enum VibrationMode {
  SHRINK,
    EXPAND
}

public class ExperimentManager {

  MyOSCClient oscClient = new MyOSCClient();
  // csv logging
  Table table;
  // for load conditions
  public Table conditionTable;

  int illusionPerceived = 0; // if illusion is induced, turn to 1;
  int conditionIndex = 0;
  int conditionNum = 0;

  int startTime = 0; // milliseconds
  public int vibrationTime = 2; // seconds
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
    this.table = new Table();
    this.table.addColumn("frame");
    this.table.addColumn("millis");
    this.table.addColumn("illusion");
  }

  public void resetLengthTable() {
    this.table = new Table();
    this.table.addColumn("length");
  }

  // on exit
  public void onExit() {
    this.oscClient.audioOFF();
  }

  public void update(State _state) {

    if (_state == State.VIBRATION) {
      TableRow _newRow = this.table.addRow();
      _newRow.setInt("frame", frameCount);
      _newRow.setInt("millis", millis());
      _newRow.setInt("illusion", illusionPerceived);

      //println(millis() - startTime);
      // it has been passed resetTime after vibration on
      if ((millis() - this.startTime)/1000.0 >= vibrationTime) {
        this.stopVibration();
        state = State.MEASURE_LENGTH;
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
    TableRow _newRow = this.table.addRow();
    _newRow.setFloat("length", barLength);

    String _file = "data/" + this.subject + "-" + this.conditionIndex + "-length.csv";
    saveTable(this.table, _file);
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
    this.oscClient.setAllAmp(0.0);

    // save table
    String _file = "data/" + this.subject + "-" + this.conditionIndex + "-illusion.csv";
    saveTable(this.table, _file);
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
    if (this.vibrationMode == VibrationMode.SHRINK) {
      // for shrinkg vib
      this.oscClient.setAmp(1, 0.5);
      this.oscClient.setAmp(2, 0.5);
      this.oscClient.setAmp(5, 0.5);
      this.oscClient.setAmp(6, 0.5);
    } else if (this.vibrationMode == VibrationMode.EXPAND) {
      // for expand vib
      this.oscClient.setAmp(3, 0.5);
      this.oscClient.setAmp(4, 0.5);
      this.oscClient.setAmp(7, 0.5);
      this.oscClient.setAmp(8, 0.5);
    }
  }

  // ---------------
  public void illusionInduced() {
    println("illusion induced !!");
    this.illusionPerceived = 1;
  }
}
