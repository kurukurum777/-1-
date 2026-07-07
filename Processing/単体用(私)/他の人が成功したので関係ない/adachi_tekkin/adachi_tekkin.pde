import processing.serial.*;
import ddf.minim.*;
import ddf.minim.ugens.*;

Minim minim;
AudioOutput out;
Serial myPort;

// --- 究極のリアル鉄琴（ノイズ完全除去版） ---
class GlockenspielInstrument implements Instrument {
  Oscil toneMain, toneStrike1, toneStrike2;
  ADSR adsrMain, adsrStrike1, adsrStrike2; 
  
  GlockenspielInstrument(float freq, float amp) {
    // ① メインの音（長く澄んで響く鉄琴の「ポーン」という音）
    toneMain = new Oscil(freq, amp * 0.7f, Waves.SINE);
    adsrMain = new ADSR(amp * 0.7f, 0.005f, 0.1f, 0.8f, 1.5f);
    toneMain.patch(adsrMain);
    
    // ② 打撃音その1（金属特有の「2.76倍」の非整数倍音）
    toneStrike1 = new Oscil(freq * 2.76f, amp * 0.2f, Waves.SINE);
    // ★ノイズ対策：リリースタイムを 0.0f から 0.05f にしてブチ切りを防止
    adsrStrike1 = new ADSR(amp * 0.2f, 0.004f, 0.05f, 0.0f, 0.05f); 
    toneStrike1.patch(adsrStrike1);

    // ③ 打撃音その2（さらに高い「5.4倍」の非整数倍音）
    toneStrike2 = new Oscil(freq * 5.4f, amp * 0.1f, Waves.SINE);
    // ★ノイズ対策：リリースタイムを 0.0f から 0.02f にしてブチ切りを防止
    adsrStrike2 = new ADSR(amp * 0.1f, 0.003f, 0.02f, 0.0f, 0.02f); 
    toneStrike2.patch(adsrStrike2);
  }
  
  void noteOn(float dur) { 
    adsrMain.noteOn(); adsrMain.patch(out); 
    adsrStrike1.noteOn(); adsrStrike1.patch(out);
    adsrStrike2.noteOn(); adsrStrike2.patch(out);
  }
  
  void noteOff() { 
    adsrMain.noteOff(); adsrMain.unpatchAfterRelease(out); 
    adsrStrike1.noteOff(); adsrStrike1.unpatchAfterRelease(out);
    adsrStrike2.noteOff(); adsrStrike2.unpatchAfterRelease(out);
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
}

void draw() {
  background(0);
  stroke(255);
  for (int i = 0; i < out.bufferSize() - 1; i++) {
    line(i, 50 - out.left.get(i)*50, i+1, 50 - out.left.get(i+1)*50);
    line(i, 150 - out.right.get(i)*50, i+1, 150 - out.right.get(i+1)*50);
  }
}

void serialEvent(Serial p) {
  String inString = p.readStringUntil('\n');
  if (inString != null) {
    inString = trim(inString);
    String[] data = split(inString, ','); 
    
    if (data.length == 5) {
      float startTime = float(data[1]);
      float freq = float(data[2]);
      float duration = float(data[3]);
      float amp = float(data[4]);
      
      out.playNote(startTime, duration, new GlockenspielInstrument(freq, amp));
    }
  }
}
 
void keyPressed() {
  if (key == 'p') {
    if (myPort != null) {
      myPort.write('p');
    }
  }
}
