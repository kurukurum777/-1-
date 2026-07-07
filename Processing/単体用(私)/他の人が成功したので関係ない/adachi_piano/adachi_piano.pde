import processing.serial.*;
import ddf.minim.*;
import ddf.minim.ugens.*;

Minim minim;
AudioOutput out;
Serial myPort;

Waveform wfPiano;

// --- ピアノの音色定義 ---
class PianoInstrument implements Instrument {
  Oscil wave; 
  ADSR adsr; 
  
  PianoInstrument(float freq, float amp) {
    wave = new Oscil(freq, amp, wfPiano);
    adsr = new ADSR(amp, 0.01f, 0.2f, 0.3f, 0.4f);
    wave.patch(adsr);
  }
  
  void noteOn(float dur) { 
    adsr.noteOn(); 
    adsr.patch(out); 
  }
  
  void noteOff() { 
    adsr.noteOff(); 
    adsr.unpatchAfterRelease(out); 
  }
}

void setup() {
  size(512, 200);
  minim = new Minim(this);
  out = minim.getLineOut();
  out.setTempo(80);
  
  // ★ご自身のArduinoのポート番号に合わせて変更してください
  printArray(Serial.list()); 
  String portName = Serial.list()[3]; 
  myPort = new Serial(this, portName, 115200);
  myPort.bufferUntil('\n');
  
  // ピアノらしい倍音波形を作成
  wfPiano = WavetableGenerator.gen10(4096, new float[] { 1.0f, 0.4f, 0.1f, 0.05f });
}

void draw() {
  background(0);
  stroke(255);
  for (int i = 0; i < out.bufferSize() - 1; i++) {
    line(i, 50 - out.left.get(i)*50, i+1, 50 - out.left.get(i+1)*50);
    line(i, 150 - out.right.get(i)*50, i+1, 150 - out.right.get(i+1)*50);
  }
}

// Arduinoからデータが送られてきたら発動
void serialEvent(Serial p) {
  String inString = p.readStringUntil('\n');
  if (inString != null) {
    inString = trim(inString);
    String[] data = split(inString, ','); 
    
    // データが5つ揃っているか確認
    if (data.length == 5) {
      int instType = int(data[0]);
      float startTime = float(data[1]);
      float freq = float(data[2]);
      float duration = float(data[3]);
      float amp = float(data[4]);
      
      // 楽器IDが1（ピアノ）なら音を鳴らすスケジュールを登録
      if (instType == 1) {
        out.playNote(startTime, duration, new PianoInstrument(freq, amp));
      }
    }
  }
}
 
void keyPressed() {
  if (key == 'p') {
    // Arduinoに「楽譜データを送って！」と合図を出す
    if (myPort != null) {
      myPort.write('p');
    }
  }
}
