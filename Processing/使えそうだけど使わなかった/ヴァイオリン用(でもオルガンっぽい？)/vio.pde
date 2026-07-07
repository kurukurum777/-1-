import ddf.minim.*;
import ddf.minim.ugens.*;

Minim minim;
AudioOutput out;

Waveform currentWaveform;

// ============================
// 🎻 フーリエ合成Wavetable生成
// ============================
void createViolinWaveform() {

  Wavetable vlnTable = new Wavetable(1024);

  // ★修正1: 高次倍音を削り、丸みのある落ち着いた音色に変更
  float[] harmonics = {
    1.0f, 0.4f, 0.2f, 0.1f, 
    0.05f, 0.02f,
  };

  // フーリエ合成
  for (int i = 0; i < 1024; i++) {
    float phase = TWO_PI * i / 1024.0f;
    float value = 0;

    for (int h = 0; h < harmonics.length; h++) {
      int n = h + 1;
      value += harmonics[h] * sin(n * phase);
    }

    vlnTable.set(i, value);
  }

  // 正規化
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

    // ★修正2: 擦弦楽器（ヴァイオリン）用のADSRに変更
    adsr = new ADSR(maxAmp,
      0.2f,   // attack: ゆっくり立ち上がる
      1.5f,   // decay: 少しだけ落ち着く
      1.0f,   // sustain: 弾いている間は音量をキープ
      0.8f    // release: 弓を離した後の自然な余韻
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
// きらきら星
// ============================
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
    0.0f, 1.0f, 2.0f, 3.0f, 4.0f, 5.0f, 6.0f,
    8.0f, 9.0f, 10.0f, 11.0f, 12.0f, 13.0f, 14.0f,
    16.0f, 17.0f, 18.0f, 19.0f, 20.0f, 21.0f, 22.0f, 
    21.0f, 22.0f,
    24.0f, 25.0f, 26.0f, 27.0f, 28.0f, 29.0f, 30.0f,
    28.0f, 29.0f, 30.0f,
    32.0f, 33.0f, 34.0f, 35.0f, 36.0f, 37.0f, 38.0f,
    40.0f, 41.0f, 42.0f, 43.0f, 44.0f, 45.0f, 46.0f,
    48.0f, 49.0f, 50.0f, 51.0f, 52.0f, 53.0f, 54.0f,
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

  for (int i = 0; i < melody.length; i++) {
    out.playNote(startTime[i], duration[i],
      new ViolinInstrument(
        Frequency.ofPitch(melody[i]).asHz(),
        amplitude[i],
        currentWaveform
      )
    );
  }

  // ★修正4: 伴奏も「5」から「4」中心のオクターブに下げました
  playChord(0.0f, 0.8f, new String[]{"C4", "E4", "G4"}, 0.15f);
  playChord(1.0f, 0.8f, new String[]{"E4", "G4", "B4"}, 0.15f);
  playChord(2.0f, 0.8f, new String[]{"F4", "A4", "C5"}, 0.15f);
  playChord(3.0f, 0.8f, new String[]{"C4", "E4", "G4"}, 0.15f);
  playChord(4.0f, 0.8f, new String[]{"F4", "A4", "C5"}, 0.15f);
  playChord(5.0f, 0.8f, new String[]{"C4", "E4", "G4"}, 0.15f);
  playChord(6.0f, 0.8f, new String[]{"G3", "B3", "D4"}, 0.15f);
  playChord(7.0f, 1.2f, new String[]{"C4", "E4", "G4"}, 0.2f);

  out.resumeNotes();
}

// ============================
// 波形表示
// ============================
void draw() {
  background(0);
  stroke(255);

  for (int i = 0; i < out.bufferSize() - 1; i++) {
    line(i, 50 - out.left.get(i)*50, i+1, 50 - out.left.get(i+1)*50);
    line(i, 150 - out.right.get(i)*50, i+1, 150 - out.right.get(i+1)*50);
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
