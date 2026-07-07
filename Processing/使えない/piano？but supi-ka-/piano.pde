import ddf.minim.*;
import ddf.minim.ugens.*;

Minim minim;
AudioOutput out;

// きらきら星
String[] melody = {
  "C5","C5","G5","G5","A5","A5","G5",
  "F5","F5","E5","E5","D5","D5","C5"
};

float[] duration = {
  0.4f,0.4f,0.4f,0.4f,0.4f,0.4f,0.8f,
  0.4f,0.4f,0.4f,0.4f,0.4f,0.4f,0.8f
};

float[] startTime = {
  0.0f,0.5f,1.0f,1.5f,2.0f,2.5f,3.0f,
  4.0f,4.5f,5.0f,5.5f,6.0f,6.5f,7.0f
};

boolean isPlaying = false;
long playStart;

// 🎹 ピアノ風Instrument
class PianoInstrument implements Instrument {
  Oscil osc1, osc2, osc3;
  Line ampEnv;

  PianoInstrument(float freq) {
    // 基本波 + 倍音（ピアノっぽさ）
    osc1 = new Oscil(freq, 0, Waves.SINE);
    osc2 = new Oscil(freq * 2, 0, Waves.SINE);
    osc3 = new Oscil(freq * 3, 0, Waves.SINE);

    ampEnv = new Line();

    ampEnv.patch(osc1.amplitude);
    ampEnv.patch(osc2.amplitude);
    ampEnv.patch(osc3.amplitude);
  }

  void noteOn(float dur) {
    // アタック速く → 徐々に減衰（ピアノっぽい）
    ampEnv.activate(dur, 0.6f, 0.0f);

    osc1.patch(out);
    osc2.patch(out);
    osc3.patch(out);
  }

  void noteOff() {
    osc1.unpatch(out);
    osc2.unpatch(out);
    osc3.unpatch(out);
  }
}

void setup() {
  size(400, 200);
  minim = new Minim(this);
  out = minim.getLineOut();
}

void draw() {
  background(0);

  if (isPlaying) {
    float t = (millis() - playStart) / 1000.0f;

    for (int i = 0; i < melody.length; i++) {
      if (abs(t - startTime[i]) < 0.02) {
        float freq = Frequency.ofPitch(melody[i]).asHz();
        out.playNote(0, duration[i], new PianoInstrument(freq));
      }
    }

    if (t > startTime[startTime.length - 1] + 1.0f) {
      isPlaying = false;
      println("再生終了");
    }
  }

  fill(255);
  text("pキーで再生", 150, 100);
}

void keyPressed() {
  if (key == 'p') {
    isPlaying = true;
    playStart = millis();
    println("再生開始");
  }
}
