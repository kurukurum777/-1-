import processing.serial.*;
import ddf.minim.*;
import ddf.minim.ugens.*;

Minim minim;
AudioOutput out;
Serial myPort;

// 楽曲データ
float[] baseFreqs = {
  587.33, 587.33, 523.25, 587.33, 587.33, 523.25, 587.33,
  587.33, 523.25, 587.33, 587.33, 523.25, 587.33, 587.33,
  523.25, 587.33, 587.33, 523.25, 587.33, 587.33, 523.25,
  587.33, 587.33, 523.25, 587.33, 587.33, 523.25, 587.33,
  587.33, 523.25, 587.33, 587.33, 523.25, 587.33, 587.33,
  523.25, 587.33, 587.33, 523.25, 587.33, 587.33, 523.25
};

float[] durations = {
  0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.8, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.8,
  0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.8, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.8,
  0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.8, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 1.6
};

float[] startTimes = {
  0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 4.5, 5.0, 5.5, 6.0, 6.5, 7.0,
  8.0, 8.5, 9.0, 9.5, 10.0, 10.5, 11.0, 12.0, 12.5, 13.0, 13.5, 14.0, 14.5, 15.0,
  16.0, 16.5, 17.0, 17.5, 18.0, 18.5, 19.0, 20.0, 20.5, 21.0, 21.5, 22.0, 22.5, 23.0
};

boolean isPlaying = false;

void setup() {
  size(400, 200);
  minim = new Minim(this);
  out = minim.getLineOut();
  
  // --- Arduino接続設定 ---
  printArray(Serial.list());
  try {
    // ※お使いの環境に合わせて [3] などの数値を変更してください
    String portName = Serial.list()[3]; 
    myPort = new Serial(this, portName, 115200);
    myPort.bufferUntil('\n');
    println("Arduino connected to: " + portName);
  } catch (Exception e) {
    println("Error: Arduino could not be connected. Check the Serial port index.");
  }
}

void draw() {
  background(0);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(16);
  
  if (isPlaying) {
    text("Playing Timpani...", width/2, height/2);
  } else {
    text("Press 'p' key to Play Timpani\nPress 's' key to Stop", width/2, height/2);
  }
}

// -------------------------
// キーボード入力時の処理
// -------------------------
void keyPressed() {
  // 'p' または 'P' キーが押されたら再生
  if (key == 'p' || key == 'P') {
    out.clearSignals(); // 既に鳴っている音があればリセット
    out.pauseNotes();   // スケジュールを一時停止
    
    for (int i = 0; i < 42; i++) {
      float playTime = startTimes[i] + 0.5; // 0.5秒の余裕を持たせてスケジュール
      out.playNote(playTime, durations[i], new Timpani(baseFreqs[i]));
    }
    
    out.resumeNotes();  // 一斉に再生開始
    isPlaying = true;
    println("Playback Started.");
  }
  
  // 's' または 'S' キーが押されたら停止
  if (key == 's' || key == 'S') {
    out.clearSignals();
    out.pauseNotes();
    isPlaying = false;
    println("Playback Stopped.");
  }
}

// -------------------------
// Arduinoからのデータ受信（必要に応じて動作）
// -------------------------
void serialEvent(Serial p) {
  String inString = p.readStringUntil('\n');
  if (inString == null) return;
  inString = trim(inString);

  if (inString.equals("stop")) {
    out.clearSignals(); 
    out.pauseNotes();   
    isPlaying = false;
    return;
  }

  String[] data = split(inString, ',');
  if (data.length == 5) {
    out.resumeNotes(); 
    float startTime = float(data[1]);
    float freq      = float(data[2]);
    float duration  = float(data[3]);
    out.playNote(startTime, duration, new Timpani(freq));
    isPlaying = true;
  }
}

// -------------------------
// ティンパニ音色クラス
// -------------------------
class Timpani implements Instrument {
  Summer sum;
  Line env;
  Multiplier amp;

  Timpani(float freq) {
    sum = new Summer();
    env = new Line(1.0, 0.0);
    amp = new Multiplier(0.8);

    Oscil wave  = new Oscil(freq,        0.7, Waves.TRIANGLE);
    Oscil sub   = new Oscil(freq * 0.99, 0.4, Waves.SINE);
    Oscil harm  = new Oscil(freq * 1.51, 0.2, Waves.SINE);
    Oscil click = new Oscil(freq * 4.2,  0.1, Waves.SINE);

    wave.patch(sum);
    sub.patch(sum);
    harm.patch(sum);
    click.patch(sum);

    sum.patch(amp);
    env.patch(amp.amplitude);
  }

  void noteOn(float dur) {
    env.activate(dur, 0.8, 0);
    amp.patch(out);
  }

  void noteOff() {
    amp.unpatch(out);
  }
}
