import ddf.minim.*;        // ★これが必要でした！
import ddf.minim.ugens.*;

Minim minim;
AudioOutput out;

String[] notes = {"C3", "C3", "G2", "G2", "C3", "C3", "G2", "G2", "C3", "C3", "G2", "G2", "C3", "C3", "G2", "G2","C3", "C3", "G2", "G2","C3", "C3", "G2", "G2","C3", "C3", "G2", "G2",};
float[] beats = {0, 1, 2, 3, 4, 5, 6, 7, 8 ,9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28};

void setup() {
  size(300, 200);
  minim = new Minim(this);
  out = minim.getLineOut();
}

void draw() {
  background(0);
  fill(255);
  text("Press P", 100, 100);
}

void keyPressed() {
  if (key == 'p' || key == 'P') {
    out.pauseNotes();
    for (int i = 0; i < notes.length; i++) {
      out.playNote(beats[i], 2.0, new Timpani(Frequency.ofPitch(notes[i]).asHz()));
    }
    out.resumeNotes();
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

    Oscil wave = new Oscil(freq, 0.7, Waves.TRIANGLE);
    Oscil sub  = new Oscil(freq * 0.99, 0.4, Waves.SINE);
    Oscil harm = new Oscil(freq * 1.51, 0.2, Waves.SINE);
    Oscil click = new Oscil(freq * 4.2, 0.1, Waves.SINE);

    wave.patch(sum); sub.patch(sum); harm.patch(sum); click.patch(sum);

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
