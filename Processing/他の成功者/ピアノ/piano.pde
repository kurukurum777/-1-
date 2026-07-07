import processing.serial.*;
import ddf.minim.*;
import ddf.minim.ugens.*;

Minim minim;
AudioOutput out;
Waveform currentWaveform; 
Serial myPort;

class PianoInstrument implements Instrument {
  Summer mix;         
  ADSR mainEnv;       
  MoogFilter filter;  
  
  PianoInstrument(float frequency, float maxAmp, Waveform wf) {
    mix = new Summer(); 
    
    // ① デチューン（波形の重ね合わせ）
    Oscil osc1 = new Oscil(frequency,        0.7f, wf);
    Oscil osc2 = new Oscil(frequency + 1.2f, 0.2f, wf);
    Oscil osc3 = new Oscil(frequency - 1.2f, 0.2f, wf);
    osc1.patch(mix);
    osc2.patch(mix);
    osc3.patch(mix);
    
    // ③ フィルター（打鍵の強さによる音色の変化）
    float cutoffFreq = frequency * (2.0f + maxAmp * 6.0f);
    filter = new MoogFilter(cutoffFreq, 0.15f); 
    
    // 【音量アップ】Sustainレベルを上げて音を太く設定
    mainEnv = new ADSR(maxAmp, 0.003f, 0.30f, 0.35f, 0.5f);
    
    mix.patch(filter).patch(mainEnv);
  }

  void noteOn(float duration) {
    mainEnv.noteOn();
    mainEnv.patch(out); 
  }

  void noteOff() {
    mainEnv.noteOff();
    mainEnv.unpatchAfterRelease(out); 
  }
}

void setup() {
  size(512, 200);
  minim = new Minim(this);
  out = minim.getLineOut();
  out.setTempo(80);
  
  // 初期音色の波形生成
  currentWaveform = WavetableGenerator.gen10(
    4096, new float[] { 1.0f, 0.12f, 0.05f, 0.02f, 0.01f }
  );

  printArray(Serial.list()); 
  // [3] 番のポートを指定（/dev/cu.usbmodem64E8335D2B842）
  String portName = Serial.list()[3];
  myPort = new Serial(this, portName, 115200);
  myPort.bufferUntil('\n');
}

// =========================================================
// ★同期部分の修正：Arduinoからリアルタイムに届いた音をその場で鳴らす
// =========================================================
void serialEvent(Serial p) {
  String inString = p.readStringUntil('\n');
  if (inString != null) {
    inString = trim(inString);
    println("受信データ: " + inString);
    String[] data = split(inString, ','); 
    
    if (data.length == 5) {
      // float startTime = float(data[1]); // 過去の時間になってしまうため使用しません
      float freq      = float(data[2]);
      float duration  = float(data[3]);
      float amp       = float(data[4]);
      
      // 【音量アップ】ブースト倍率
      float boostedAmp = min(amp * 5.0f, 1.0f);
      
      // ★第1引数（開始時間）を「0.0」にすることで、データが届いた瞬間に即座に発音します！
      out.playNote(0.0, duration, new PianoInstrument(freq, boostedAmp, currentWaveform));
    }
  }
}

void draw() {
  background(0);
  stroke(255);
  for (int i = 0; i < out.bufferSize() - 1; i++) {
    line(i, 50  - out.left.get(i)  * 50, i+1, 50  - out.left.get(i+1)  * 50);
    line(i, 150 - out.right.get(i) * 50, i+1, 150 - out.right.get(i+1) * 50);
  }
}

// 1〜5キーでの「音色の切り替え機能」
void keyPressed() {
  switch (key) {
    case '1': currentWaveform = Waves.SINE; break;
    case '2': currentWaveform = Waves.TRIANGLE; break;
    case '3': currentWaveform = Waves.SAW; break;
    case '4': currentWaveform = Waves.SQUARE; break;
    case '5':
      currentWaveform = WavetableGenerator.gen10(
        4096, new float[] { 1.0f, 0.18f, 0.05f, 0.02f, 0.01f }
      );
      break;
  }
}
