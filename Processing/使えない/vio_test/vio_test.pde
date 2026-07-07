import processing.serial.*;
import ddf.minim.*;
import ddf.minim.ugens.*;

Minim minim;
AudioOutput out;
Serial myPort;

Waveform currentWaveform;

void setup() {
  size(512, 200); // 元のヴァイオリンコードのキャンバスサイズ

  minim = new Minim(this);
  out = minim.getLineOut();
  
  // 🎻 フーリエ合成によるヴァイオリンの波形生成
  createViolinWaveform();

  printArray(Serial.list());
  String portName = Serial.list()[3]; // お使いの環境のCOMポート番号に合わせて変更してください
  myPort = new Serial(this, portName, 115200);
  myPort.bufferUntil('\n');
}

void draw() {
  background(0);
  stroke(255);

  // 🎻 元のコードと同じ150倍ズームの波形描画処理
  float zoom = 150; 

  for (int i = 0; i < out.bufferSize() - 1; i++) {
    line(i, 50 - out.left.get(i)*zoom, i+1, 50 - out.left.get(i+1)*zoom);
    line(i, 150 - out.right.get(i)*zoom, i+1, 150 - out.right.get(i+1)*zoom);
  }
}

void serialEvent(Serial p) {
  String inString = p.readStringUntil('\n');
  if (inString == null) return;

  inString = trim(inString);

  // 親機からの停止命令処理
  if (inString.equals("stop")) {
    out.clearSignals(); 
    out.pauseNotes();   
    return;
  }

  String[] data = split(inString, ',');

  if (data.length == 5) {
    try {
      out.resumeNotes(); 
      
      int instType    = int(data[0]);
      float startTime = float(data[1]);
      float freq      = float(data[2]);
      float duration  = float(data[3]);
      float amp       = float(data[4]);

      // 楽器IDが 3 (ヴァイオリン) だった場合のみ再生
      if (instType == 3) {
        out.playNote(
          startTime,
          duration,
          new ViolinInstrument(freq, amp, currentWaveform)
        );
      }
    } catch (Exception e) {
      println("パースエラー（スキップしました）: " + inString);
    }
  }
}

// ============================
// 🎻 フーリエ合成Wavetable生成 (変更なし)
// ============================
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

// ============================
// 🎻 ヴァイオリン用インストゥルメント (変更なし)
// ============================
class ViolinInstrument implements Instrument {
  Oscil wave;
  ADSR adsr;

  ViolinInstrument(float frequency, float maxAmp, Waveform wf) {
    wave = new Oscil(frequency, maxAmp, wf);

    adsr = new ADSR(maxAmp,
      0.15f,  // attack
      0.5f,   // decay
      0.7f,   // sustain
      0.4f    // release
    );

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
