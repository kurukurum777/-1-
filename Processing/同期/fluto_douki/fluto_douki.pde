import processing.serial.*;
import ddf.minim.*;
import ddf.minim.ugens.*;

Minim minim;
AudioOutput out;
Serial myPort;

// =====================================================
// フルート音色
// =====================================================
class FluteInstrument implements Instrument {
  Oscil base;
  Oscil third;
  Summer sum;
  ADSR adsr;

  FluteInstrument(float frequency, float maxAmp) {
    base = new Oscil(frequency, maxAmp * 0.9f, Waves.SINE);
    third = new Oscil(frequency * 3, maxAmp * 0.1f, Waves.SINE);

    sum = new Summer();
    base.patch(sum);
    third.patch(sum);

    adsr = new ADSR(maxAmp, 0.1f, 0.8f, 0.7f, 0.3f);
    sum.patch(adsr);
  }

  void noteOn(float duration) {
    adsr.noteOn();
    adsr.patch(out);
  }

  void noteOff() {
    adsr.noteOff();
    adsr.unpatchAfterRelease(out);
  }
}

// =====================================================
// Setup
// =====================================================
void setup() {
  size(512, 200);
  minim = new Minim(this);
  out = minim.getLineOut();
  out.setTempo(80);
  
  printArray(Serial.list()); 
  try {
    String portName = Serial.list()[3]; // ←お使いの環境に合わせて変更してください
    myPort = new Serial(this, portName, 115200);
    myPort.bufferUntil('\n');
    println("Connected to: " + portName);
  } catch (Exception e) {
    println("エラー：Arduinoのポート番号を確認してください。");
  }
}

// =====================================================
// Arduinoから受信して鳴らす（同期の要）
// =====================================================
void serialEvent(Serial p) {
  String inString = p.readStringUntil('\n');
  if (inString == null) return;
  
  inString = trim(inString);

  if (inString.equals("stop")) {
    out.clearSignals();
    out.pauseNotes();
    return;
  }

  String[] data = split(inString, ',');
  
  // 成功例と同じ5つのデータを受信
  if (data.length == 5) {
    out.resumeNotes();
    float startTime = float(data[1]);
    float freq      = float(data[2]);
    float duration  = float(data[3]);
    float amp       = float(data[4]);

    // フルート用の音量調整（小さすぎないように少しブースト）
    float boostedAmp = min(amp * 2.0f, 1.0f);
    
    out.playNote(
      startTime, 
      duration, 
      new FluteInstrument(freq, boostedAmp)
    );
  }
}

// =====================================================
// 波形表示
// =====================================================
void draw() {
  background(0);
  stroke(255);
  
  float zoom = 150; 

  for (int i = 0; i < out.bufferSize() - 1; i++) {
    line(i, 50 - out.left.get(i)*zoom, i+1, 50 - out.left.get(i+1)*zoom);
    line(i, 150 - out.right.get(i)*zoom, i+1, 150 - out.right.get(i+1)*zoom);
  }
  
  fill(255);
  textSize(20);
  text("Flute (I2C Sync Mode)", 20, 30);
  text("Waiting for Arduino Sync...", 20, 60);
}
