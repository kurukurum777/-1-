import ddf.minim.*;
import ddf.minim.ugens.*;

Minim minim;
AudioOutput out;

// =====================================================
// フルート音色
// 基音メイン + 少しだけ3倍音
// =====================================================
class FluteInstrument implements Instrument {

  Oscil base;
  Oscil third;

  Summer sum;
  ADSR adsr;

  FluteInstrument(float frequency, float maxAmp) {

    // 基音
    base = new Oscil(frequency, maxAmp * 0.9f, Waves.SINE);

    // 少しだけ3倍音
    third = new Oscil(frequency * 3, maxAmp * 0.1f, Waves.SINE);

    sum = new Summer();

    base.patch(sum);
    third.patch(sum);

    // 柔らかい立ち上がり
    adsr = new ADSR(maxAmp, 0.1f, 0.8f, 0.7f, 0.3f);

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
// setup
// =====================================================
void setup() {

  size(512, 200);

  minim = new Minim(this);
  out = minim.getLineOut();

  out.setTempo(80);
}

// =====================================================
// 和音
// =====================================================
void playChord(float startTime, float duration, String[] notes, float amp) {

  for (String note : notes) {

    out.playNote(
      startTime,
      duration,
      new FluteInstrument(
        Frequency.ofPitch(note).asHz(),
        amp
      )
    );
  }
}

void playSong() {

  out.pauseNotes();

  // ★修正3: メロディを「6」から「4〜5」のオクターブに下げました
  String[] melody = {
    "C5", "C5", "G5", "G5", "A5", "A5", "G5",
    "F5", "F5", "E5", "E5", "D5", "D5", "C5",
    "G5", "G5", "F5", "F5", "E5", "E5", "D5",
    "G5", "G5",
    "G5", "G5", "F5", "F5", "E5", "E5", "D5",
    "C5", "C5", "C5",
    "C5", "C5", "G5", "G5", "A5", "A5", "G5",
    "F5", "F5", "E5", "E5", "D5", "D5", "C5"
  };

  float[] duration = {
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f,
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 1.0f,
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 1.0f,
    0.3f, 1.0f,
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 1.0f,
    0.3f, 0.3f, 1.0f,
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 1.0f,
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 1.0f
  };

  float[] startTime = {
    0.0f, 0.5f, 1.0f, 1.5f, 2.0f, 2.5f, 3.0f,
    5.0f, 5.5f, 6.0f, 6.5f, 7.0f, 7.5f, 8.0f,
    10.0f, 10.5f, 11.0f, 11.5f, 12.0f, 12.5f, 13.0f, 
    21.0f, 22.0f,
    15.0f, 15.5f, 20.0f, 20.5f, 21.0f, 21.5f, 22.0f,
    24.0f, 24.5f, 25.0f,
    27.0f, 27.5f, 28.0f, 29.5f, 30.0f, 30.5f, 31.0f,
    33.0f, 33.5f, 34.0f, 34.5f, 35.0f, 35.5f, 40.0f,
    42.0f, 42.5f, 43.0f, 43.5f, 44.0f, 44.5f, 45.0f,
  };

  float[] amplitude = {
    0.4f, 0.4f, 0.4f, 0.4f, 0.4f, 0.4f, 0.4f,
    0.4f, 0.4f, 0.4f, 0.4f, 0.4f, 0.4f, 0.4f,
    0.4f, 0.4f, 0.4f, 0.4f, 0.4f, 0.4f, 0.4f,
    0.4f, 0.4f,
    0.4f, 0.4f, 0.4f, 0.4f, 0.4f, 0.4f, 0.5f,
    0.4f, 0.4f, 0.4f,
    0.4f, 0.4f, 0.4f, 0.4f, 0.4f, 0.4f, 0.5f,
    0.4f, 0.4f, 0.4f, 0.4f, 0.4f, 0.4f, 0.5f,
  };
  // メロディ
  for (int i = 0; i < melody.length; i++) {

    out.playNote(
      startTime[i],
      duration[i],
      new FluteInstrument(
        Frequency.ofPitch(melody[i]).asHz(),
        amplitude[i]
      )
    );
  }

  // 和音
  playChord(0.0f, 0.8f, new String[]{"C5", "E5", "G5"}, 0.15f);
  playChord(1.0f, 0.8f, new String[]{"E5", "G5", "B5"}, 0.15f);
  playChord(2.0f, 0.8f, new String[]{"F5", "A5", "C6"}, 0.15f);
  playChord(3.0f, 0.8f, new String[]{"C5", "E5", "G5"}, 0.15f);

  playChord(4.0f, 0.8f, new String[]{"F5", "A5", "C6"}, 0.15f);
  playChord(5.0f, 0.8f, new String[]{"C5", "E5", "G5"}, 0.15f);
  playChord(6.0f, 0.8f, new String[]{"G4", "B4", "D5"}, 0.15f);
  playChord(7.0f, 1.2f, new String[]{"C5", "E5", "G5"}, 0.2f);

  out.resumeNotes();
}

// =====================================================
// 波形表示
// =====================================================
void draw() {

  background(0);

  stroke(255);

  for (int i = 0; i < out.bufferSize() - 1; i++) {

    line(i,
      50 - out.left.get(i) * 50,
      i + 1,
      50 - out.left.get(i + 1) * 50);

    line(i,
      150 - out.right.get(i) * 50,
      i + 1,
      150 - out.right.get(i + 1) * 50);
  }

  fill(255);
  textSize(20);
  text("Flute", 20, 30);
  text("Press P to Play", 20, 60);
}

// =====================================================
// キー操作
// =====================================================
void keyPressed() {

  if (key == 'p' || key == 'P') {
    playSong();
  }
}
