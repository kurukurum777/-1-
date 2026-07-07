import processing.serial.*;
import ddf.minim.*;
import ddf.minim.ugens.*;

Minim minim;
AudioOutput out;
Serial myPort;

Waveform currentWaveform;

// ==========================================
// 🎻 フーリエ合成Wavetable生成 (音色)
// ==========================================
void createViolinWaveform() {
  Wavetable vlnTable = new Wavetable(1024);
  float[] harmonics = {
    1.0f, 0.4f, 0.2f, 0.1f, 
    0.05f, 0.02f
  };

  for (int i = 0; i < 1024; i++) {
    float phase = TWO_PI * i / 1024.0f;
    float value = 0;
    for (int h = 0; h < harmonics.length; h++) {
      int n = h + 1;
      value += harmonics[h] * sin(n * phase);
    }
    vlnTable.set(i, value);
  }

  float maxVal = 0;
  for (int i = 0; i < 1024; i++) {
    maxVal = max(maxVal, abs(vlnTable.get(i)));
  }

  for (int i = 0; i < 1024; i++) {
    vlnTable.set(i, vlnTable.get(i) / maxVal);
  }
  currentWaveform = vlnTable;
}

// ==========================================
// 🎻 ヴァイオリン用インストゥルメント (ADSR制御)
// ==========================================
class ViolinInstrument implements Instrument {
  Oscil wave;
  ADSR adsr;

  ViolinInstrument(float frequency, float maxAmp, Waveform wf) {
    wave = new Oscil(frequency, maxAmp, wf);
    adsr = new ADSR(maxAmp, 0.15f, 0.5f, 0.7f, 0.4f);
    wave.patch(adsr);
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

// ==========================================
// Setup
// ==========================================
void setup() {
  size(512, 200);

  minim = new Minim(this);
  out = minim.getLineOut();
  out.setTempo(80);

  createViolinWaveform();
  
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

// ==========================================
// Arduinoからの指示を受信して鳴らす
// ==========================================
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
  
  // 5つのデータ(楽器ID, 開始時間, 周波数, 長さ, 音量)を受信したら発音
  if (data.length == 5) {
    out.resumeNotes();
    float startTime = float(data[1]);
    float freq      = float(data[2]);
    float duration  = float(data[3]);
    float amp       = float(data[4]);

    out.playNote(
      startTime, 
      duration, 
      new ViolinInstrument(freq, amp, currentWaveform)
    );
  }
}

// ==========================================
// 波形表示
// ==========================================
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
  text("Violin Synth Engine", 20, 30);
  text("Waiting for Arduino Score Data...", 20, 60);
}
