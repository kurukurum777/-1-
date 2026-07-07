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
      // float amp     = float(data[4]); // 今回はTimpani内部で音量を固定しているため受信のみ

      // ティンパニ音色で音をスケジュール再生
      out.playNote(
        startTime,
        duration,
        new Timpani(freq)
      );
    } catch (Exception e) {
      println("パースエラー（スキップしました）: " + inString);
    }
  }
}

// -------------------------
// ティンパニ音色クラス（変更なし）
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
