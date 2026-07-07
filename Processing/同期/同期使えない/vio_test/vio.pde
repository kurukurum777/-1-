import processing.serial.*;
import ddf.minim.*;
import ddf.minim.ugens.*;

Minim minim;
AudioOutput out;
Waveform currentWaveform;
Serial myPort;

// ============================
// 🎻 フーリエ合成Wavetable生成
// ============================
void createViolinWaveform() {

  Wavetable vlnTable = new Wavetable(1024);

  float[] harmonics = {
    1.0f, 0.4f, 0.2f, 0.1f, 
    0.05f, 0.02f
  };

  for (int i = 0; i < 1024; i++) {
    float phase = TWO_PI * i / 1024.0f;
    float value = 0;

    for (int h = 0; h < harmonics.length; h++) {
      int n = h + 1;
      value += harmonics[h] * sin(n * phase);
    }

    vlnTable.set(i, value);
  }

  float maxVal = 0;
  for (int i = 0; i < 1024; i++) {
    maxVal = max(maxVal, abs(vlnTable.get(i)));
  }

  for (int i = 0; i < 1024; i++) {
    vlnTable.set(i, vlnTable.get(i) / maxVal);
  }

  currentWaveform = vlnTable;
}

// ============================
// 🎻 ヴァイオリン用インストゥルメント
// ============================
class ViolinInstrument implements Instrument {
  Oscil wave;
  ADSR adsr;

  ViolinInstrument(float frequency, float maxAmp, Waveform wf) {
    wave = new Oscil(frequency, maxAmp, wf);

    adsr = new ADSR(maxAmp,
      0.15f,  // attack
      0.5f,   // decay
      0.7f,   // sustain
      0.4f    // release
    );

    wave.patch(adsr);
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

// ============================
// setup
// ============================
void setup() {
  size(512, 200);

  minim = new Minim(this);
  out = minim.getLineOut();
  out.setTempo(80);

  createViolinWaveform();
}

// ============================
// 和音
// ============================
void playChord(float startTime, float duration, String[] notes, float amp) {
  for (String note : notes) {
    out.playNote(startTime, duration,
      new ViolinInstrument(
        Frequency.ofPitch(note).asHz(),
        amp,
        currentWaveform
      )
    );
  }
}

// ============================
// きらきら星 (重なりアレンジ ＋ グロッケンテンポ)
// ============================
void playSong() {

  out.pauseNotes();

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
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.8f,
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.8f,
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.8f,
    0.3f, 0.8f, 
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.8f,
    0.3f, 0.3f, 0.8f, 
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.8f,
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.8f
  };

  float[] startTime = {
     0.0f,  0.5f,  1.0f,  1.5f,  2.0f,  2.5f,  3.0f,
     4.0f,  4.5f,  5.0f,  5.5f,  6.0f,  6.5f,  7.0f,
     8.0f,  8.5f,  9.0f,  9.5f, 10.0f, 10.5f, 11.0f,
    10.5f, 11.0f, 
    12.0f, 12.5f, 13.0f, 13.5f, 14.0f, 14.5f, 15.0f,
    14.0f, 14.5f, 15.0f, 
    16.0f, 16.5f, 17.0f, 17.5f, 18.0f, 18.5f, 19.0f,
    20.0f, 20.5f, 21.0f, 21.5f, 22.0f, 22.5f, 23.0f
  };

  // ★修正: 実際の音量を音割れしない安全圏ギリギリまで引き上げました
  float[] amplitude = {
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.35f,
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.35f,
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.35f,
    0.3f, 0.35f, 
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.35f,
    0.3f, 0.3f, 0.35f, 
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.35f,
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.35f
  };

  for (int i = 0; i < melody.length; i++) {
    out.playNote(startTime[i], duration[i],
      new ViolinInstrument(
        Frequency.ofPitch(melody[i]).asHz(),
        amplitude[i],
        currentWaveform
      )
    );
  }

  // ★修正: 伴奏の音量もバランスを取って引き上げました（0.08 → 0.12）
  playChord(0.0f, 0.8f, new String[]{"C4", "E4", "G4"}, 0.12f);
  playChord(1.0f, 0.8f, new String[]{"E4", "G4", "B4"}, 0.12f);
  playChord(2.0f, 0.8f, new String[]{"F4", "A4", "C5"}, 0.12f);
  playChord(3.0f, 0.8f, new String[]{"C4", "E4", "G4"}, 0.12f);
  playChord(4.0f, 0.8f, new String[]{"F4", "A4", "C5"}, 0.12f);
  playChord(5.0f, 0.8f, new String[]{"C4", "E4", "G4"}, 0.12f);
  playChord(6.0f, 0.8f, new String[]{"G3", "B3", "D4"}, 0.12f);
  playChord(7.0f, 1.2f, new String[]{"C4", "E4", "G4"}, 0.15f);

  playChord(8.0f, 0.8f, new String[]{"C4", "E4", "G4"}, 0.12f);
  playChord(9.0f, 0.8f, new String[]{"F4", "A4", "C5"}, 0.12f);
  playChord(10.0f, 0.8f, new String[]{"C4", "E4", "G4"}, 0.12f);
  playChord(11.0f, 1.2f, new String[]{"G3", "B3", "D4"}, 0.15f);

  playChord(12.0f, 0.8f, new String[]{"C4", "E4", "G4"}, 0.12f);
  playChord(13.0f, 0.8f, new String[]{"F4", "A4", "C5"}, 0.12f);
  playChord(14.0f, 0.8f, new String[]{"C4", "E4", "G4"}, 0.12f);
  playChord(15.0f, 1.2f, new String[]{"G3", "B3", "D4"}, 0.15f);

  playChord(16.0f, 0.8f, new String[]{"C4", "E4", "G4"}, 0.12f);
  playChord(17.0f, 0.8f, new String[]{"E4", "G4", "B4"}, 0.12f);
  playChord(18.0f, 0.8f, new String[]{"F4", "A4", "C5"}, 0.12f);
  playChord(19.0f, 0.8f, new String[]{"C4", "E4", "G4"}, 0.12f);
  playChord(20.0f, 0.8f, new String[]{"F4", "A4", "C5"}, 0.12f);
  playChord(21.0f, 0.8f, new String[]{"C4", "E4", "G4"}, 0.12f);
  playChord(22.0f, 0.8f, new String[]{"G3", "B3", "D4"}, 0.12f);
  playChord(23.0f, 1.2f, new String[]{"C4", "E4", "G4"}, 0.15f);

  out.resumeNotes();
}

// ============================
// 波形表示
// ============================
void draw() {
  background(0);
  stroke(255);

  // ★修正: 波形を描画する際の「倍率」を 50 → 150 にして見た目を拡大！
  float zoom = 150; 

  for (int i = 0; i < out.bufferSize() - 1; i++) {
    line(i, 50 - out.left.get(i)*zoom, i+1, 50 - out.left.get(i+1)*zoom);
    line(i, 150 - out.right.get(i)*zoom, i+1, 150 - out.right.get(i+1)*zoom);
  }
}

// ============================
// 操作
// ============================
void keyPressed() {
  if (key == 'p' || key == 'P') {
    playSong();
  }
}
