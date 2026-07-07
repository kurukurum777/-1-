import processing.serial.*;
import ddf.minim.*;
import ddf.minim.ugens.*;

Minim minim;
AudioOutput out;
Serial myPort;

void setup() {
  size(300, 200);
  minim = new Minim(this);
  out = minim.getLineOut();
  
  printArray(Serial.list());
  String portName = Serial.list()[3]; // ←お使いの環境に合わせて番号を変更してください
  myPort = new Serial(this, portName, 115200);
  myPort.bufferUntil('\n');
}

void draw() {
  background(0);
  fill(255);
  text("Waiting for Arduino...", 80, 100);
}

void serialEvent(Serial p) {
  String inString = p.readStringUntil('\n');
  if (inString == null) return;

  inString = trim(inString);

  // 親機からの一斉停止指示を受け取った場合の処理
  if (inString.equals("stop")) {
    out.clearSignals(); // 現在鳴っている音の消音
    out.pauseNotes();   // 予約されている音のスケジュールをクリア
    return;
  }

  String[] data = split(inString, ',');

  // 5つのデータが正しく受信できたか確認
  if (data.length == 5) {
    try {
      out.resumeNotes(); 
      
      float startTime = float(data[1]);
      float freq      = float(data[2]);
      float duration  = float(data[3]);

      // ★ティンパニからスネアドラム（Snare）に変更して音をスケジュール再生
      out.playNote(
        startTime,
        duration,
        new Snare(freq)
      );
    } catch (Exception e) {
      println("パースエラー（スキップしました）: " + inString);
    }
  }
}

// -------------------------
// スネアドラム音色クラス（新規作成）
// -------------------------
class Snare implements Instrument {
  Summer sum;
  Noise noise;
  Oscil osc;
  Line noiseEnv;
  Line oscEnv;
  Multiplier noiseAmp;
  Multiplier oscAmp;

  Snare(float freq) {
    sum = new Summer();

    // 1. スナッピー（響き線）の音：ホワイトノイズで「シャッ！」という空気感を作る
    noise = new Noise(0.8, Noise.Tint.WHITE);
    noiseEnv = new Line(1.0, 0.0);
    noiseAmp = new Multiplier(0.6); // ノイズの音量
    noise.patch(noiseAmp);
    noiseEnv.patch(noiseAmp.amplitude);
    noiseAmp.patch(sum);

    // 2. ドラム胴の音：サイン波で「トッ！」という芯のある音を作る
    // Arduinoから送られてくる音階(freq)を少し高めにしてスネアの張りを表現
    osc = new Oscil(freq * 1.5, 0.8, Waves.SINE);
    oscEnv = new Line(1.0, 0.0);
    oscAmp = new Multiplier(0.8); // 胴の音量
    osc.patch(oscAmp);
    oscEnv.patch(oscAmp.amplitude);
    oscAmp.patch(sum);
  }

  void noteOn(float dur) {
    // スネアドラムは「歯切れの良さ」が命なので、
    // Arduinoから送られてくる音の長さ(dur)を無視して、0.15秒で強制的に音をスパッと切断します
    noiseEnv.activate(0.15, 0.6, 0.0); 
    oscEnv.activate(0.1, 0.8, 0.0);    
    sum.patch(out);
  }

  void noteOff() {
    sum.unpatch(out);
  }
}
