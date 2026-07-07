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
  String portName = Serial.list()[3]; // ←お使いの環境に合わせてください
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

  if (inString.equals("stop")) {
    out.clearSignals(); 
    out.pauseNotes();   
    return;
  }

  String[] data = split(inString, ',');

  // 成功したコードと同様に5つのデータを受信する
  if (data.length == 5) {
    out.resumeNotes(); 
    
    // data[0] は楽器識別用なので今回はスキップ
    float startTime = float(data[1]);
    float freq      = float(data[2]);
    float duration  = float(data[3]);
    float amp       = float(data[4]); // 今回のTimpaniクラスでは使用していませんが、フォーマットを揃えるため受信

    out.playNote(
      startTime,
      duration,
      new Timpani(freq)
    );
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
