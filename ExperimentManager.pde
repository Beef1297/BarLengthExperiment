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
    subject = _subject;
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
      oscClient.setAllFreq(this.vibrationFreq);
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
      conditionIndex += 1;
    }
  }


  public void loadConditionTable() {
    String file = "conditions/" + this.subject + ".csv";
    println(file);
    conditionTable = loadTable(file, "header");
    println("condition num: " + conditionTable.getRowCount());
  }

  public void resetIllusionTable() {
    table = new Table();
    table.addColumn("frame");
    table.addColumn("millis");
    table.addColumn("illusion");
  }

  public void resetLengthTable() {
    table = new Table();
    table.addColumn("length");
  }

  // on exit
  public void onExit() {
    oscClient.audioOFF();
  }

  void update(State _state) {

    if (_state == State.VIBRATION) {
      TableRow newRow = this.table.addRow();
      newRow.setInt("frame", frameCount);
      newRow.setInt("millis", millis());
      newRow.setInt("illusion", illusionPerceived);

      //println(millis() - startTime);
      // it has been passed resetTime after vibration on
      if ((millis() - startTime)/1000.0 >= vibrationTime) {
        this.stopVibration();
        state = State.MEASURE_LENGTH;
      }
    }
  }


  // wait application for millis by inserting loop in main thread
  // FIXME: bad method
  public void waitForMillis(int _ms) {
    int ms = millis();
    int localTimer = 0;
    while (localTimer <= _ms) {
      localTimer = millis() - ms;
    }
  }

  public void measureLength() {
    if (state == State.FINISH) return;
    resetLengthTable();
    TableRow newRow = this.table.addRow();
    newRow.setFloat("length", barLength);

    String file = "data/" + subject + "-" + conditionIndex + "-length.csv";
    saveTable(table, file);
  }

  // -----------------
  public void vibrationInit() {
    // settings of OSC
    oscClient.init();
    oscClient.audioON();
  }

  public void stopVibration() {
    if (state == State.FINISH) return;
    // vibration off
    oscClient.setAllAmp(0.0);

    // save table
    String file = "data/" + subject + "-" + conditionIndex + "-illusion.csv";
    saveTable(table, file);
  }

  public void startVibration() {
    if (state == State.FINISH) return;
    // initialize variables for starting trial
    resetIllusionTable();
    startTime = millis();
    illusionPerceived = 0;

    if (vibrationMode == null) {
      println("vibration mode is null! something is wrong.");
    }

    //oscClient.setAmp(1, 0.5); // temp
    if (this.vibrationMode == VibrationMode.SHRINK) {
      // for shrinkg vib
      oscClient.setAmp(1, 0.5);
      oscClient.setAmp(2, 0.5);
      oscClient.setAmp(5, 0.5);
      oscClient.setAmp(6, 0.5);
    } else if (this.vibrationMode == VibrationMode.EXPAND) {
      // for expand vib
      oscClient.setAmp(3, 0.5);
      oscClient.setAmp(4, 0.5);
      oscClient.setAmp(7, 0.5);
      oscClient.setAmp(8, 0.5);
    }
  }

  // ---------------
  public void illusionInduced() {
    println("illusion induced !!");
    illusionPerceived = 1;
  }
}
