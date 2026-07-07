import ddf.minim.*;
import ddf.minim.ugens.*;

Minim minim;
AudioOutput out;

// =====================================================
// ティンパニ音色
// =====================================================
class TimpaniInstrument implements Instrument {

  Summer sum;
  ADSR adsr;

  TimpaniInstrument(float freq, float amp) {

    Oscil wave  = new Oscil(freq,         amp * 0.7f, Waves.TRIANGLE);
    Oscil sub   = new Oscil(freq * 0.99f, amp * 0.4f, Waves.SINE);
    Oscil harm  = new Oscil(freq * 1.51f, amp * 0.2f, Waves.SINE);
    Oscil click = new Oscil(freq * 4.2f,  amp * 0.1f, Waves.SINE);

    sum = new Summer();

    wave.patch(sum);
    sub.patch(sum);
    harm.patch(sum);
    click.patch(sum);

    // ティンパニらしい短いアタック
    adsr = new ADSR(amp, 0.01f, 0.2f, 0.4f, 0.3f);

    sum.patch(adsr);
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

// =====================================================
// Setup
// =====================================================
void setup() {
  size(512, 220);

  minim = new Minim(this);
  out = minim.getLineOut();

  out.setTempo(80);
}

// =====================================================
// 波形表示
// =====================================================
void draw() {

  background(0);

  stroke(255);

  float zoom = 150;

  for (int i = 0; i < out.bufferSize()-1; i++) {

    line(
      i,
      80 - out.left.get(i) * zoom,
      i+1,
      80 - out.left.get(i+1) * zoom
    );

    line(
      i,
      180 - out.right.get(i) * zoom,
      i+1,
      180 - out.right.get(i+1) * zoom
    );
  }

  fill(255);

  textSize(20);
  text("Timpani", 20, 30);
  text("Press P to Play", 20, 60);
}

// =====================================================
// ティンパニ伴奏
// =====================================================
void playSong() {

  out.pauseNotes();

  // 「ドン・ドン」を繰り返す
  String notes[] = {

    "C2","G1",
    "C2","G1",
    "F1","C2",
    "G1","C2",

    "F1","C2",
    "C2","G1",
    "G1","D2",
    "C2","G1",

    "C2","G1",
    "F1","C2",
    "C2","G1",
    "G1","D2",

    "C2","G1",
    "F1","C2",
    "C2","G1",
    "G1","C2",

    "C2","G1",
    "C2","G1",
    "F1","C2",
    "G1","C2"
  };

  float start[] = {

     0.0,  0.5,
     1.0,  1.5,
     2.0,  2.5,
     3.0,  3.5,

     4.0,  4.5,
     5.0,  5.5,
     6.0,  6.5,
     7.0,  7.5,

     8.0,  8.5,
     9.0,  9.5,
    10.0, 10.5,
    11.0, 11.5,

    12.0, 12.5,
    13.0, 13.5,
    14.0, 14.5,
    15.0, 15.5,

    16.0, 16.5,
    17.0, 17.5,
    18.0, 18.5,
    19.0, 19.5
  };

  for (int i = 0; i < notes.length; i++) {

    out.playNote(
      start[i],
      0.25f,
      new TimpaniInstrument(
        Frequency.ofPitch(notes[i]).asHz(),
        0.5f
      )
    );
  }

  out.resumeNotes();
}

// =====================================================
// キー操作
// =====================================================
void keyPressed() {

  if (key == 'p' || key == 'P') {
    playSong();
  }
}
