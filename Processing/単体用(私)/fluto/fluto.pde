import processing.serial.*;
import ddf.minim.*;
import ddf.minim.ugens.*;

Minim minim;
AudioOutput out;
Serial myPort;

// =====================================================
// フルート音色（音質は変更していません）
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
// Setup
// =====================================================
void setup() {
  size(512, 200);
  minim = new Minim(this);
  out = minim.getLineOut();
  out.setTempo(80);
  
  // ★Arduinoと通信する場合の設定（LEDなどを連動させる用として残しています）
  try {
    printArray(Serial.list()); 
    if (Serial.list().length > 3) {
      String portName = Serial.list()[3]; 
      myPort = new Serial(this, portName, 115200);
      myPort.bufferUntil('\n');
    }
  } catch (Exception e) {
    println("Arduinoが接続されていないか、ポート番号が違います。音の再生のみ行います。");
  }
}

// =====================================================
// 波形表示（大きく動くように調整）
// =====================================================
void draw() {
  background(0);
  stroke(255);
  
  float zoom = 150; // 波形を大きく見せる

  for (int i = 0; i < out.bufferSize() - 1; i++) {
    line(i, 50 - out.left.get(i)*zoom, i+1, 50 - out.left.get(i+1)*zoom);
    line(i, 150 - out.right.get(i)*zoom, i+1, 150 - out.right.get(i+1)*zoom);
  }
  
  fill(255);
  textSize(20);
  text("Flute (Perfect Tempo Sync)", 20, 30);
  text("Press P to Play", 20, 60);
}

// =====================================================
// 和音を鳴らす関数
// =====================================================
void playChord(float startTime, float duration, String[] notes, float amp) {
  for (String note : notes) {
    out.playNote(
      startTime,
      duration,
      new FluteInstrument(Frequency.ofPitch(note).asHz(), amp)
    );
  }
}

// =====================================================
// きらきら星（ヴァイオリンと同じテンポ・重音なし）
// =====================================================
void playSong() {
  out.pauseNotes();

  // 重音なしのシンプルなメロディ
  String[] melody = {
    "C5", "C5", "G5", "G5", "A5", "A5", "G5",
    "F5", "F5", "E5", "E5", "D5", "D5", "C5",
    "G5", "G5", "F5", "F5", "E5", "E5", "D5",
    "G5", "G5", "F5", "F5", "E5", "E5", "D5",
    "C5", "C5", "G5", "G5", "A5", "A5", "G5",
    "F5", "F5", "E5", "E5", "D5", "D5", "C5"
  };

  float[] duration = {
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.8f,
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.8f,
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.8f,
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.8f,
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.8f,
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.8f
  };

  // ヴァイオリン版と同じ完璧な0.5刻みのテンポ
  float[] startTime = {
     0.0f,  0.5f,  1.0f,  1.5f,  2.0f,  2.5f,  3.0f,
     4.0f,  4.5f,  5.0f,  5.5f,  6.0f,  6.5f,  7.0f,
     8.0f,  8.5f,  9.0f,  9.5f, 10.0f, 10.5f, 11.0f,
    12.0f, 12.5f, 13.0f, 13.5f, 14.0f, 14.5f, 15.0f,
    16.0f, 16.5f, 17.0f, 17.5f, 18.0f, 18.5f, 19.0f,
    20.0f, 20.5f, 21.0f, 21.5f, 22.0f, 22.5f, 23.0f
  };

  float[] amplitude = {
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.35f,
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.35f,
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.35f,
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.35f,
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.35f,
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.35f
  };

  // メロディのセット
  for (int i = 0; i < melody.length; i++) {
    out.playNote(startTime[i], duration[i],
      new FluteInstrument(Frequency.ofPitch(melody[i]).asHz(), amplitude[i])
    );
  }

  // 和音伴奏（通信待機ズレがなくなったので、offset無しでメロディとピッタリ合わせました）
  float d = 0.8f;
  float amp = 0.12f;

  playChord(0.0f, d, new String[]{"C4", "E4", "G4"}, amp);
  playChord(1.0f, d, new String[]{"E4", "G4", "B4"}, amp);
  playChord(2.0f, d, new String[]{"F4", "A4", "C5"}, amp);
  playChord(3.0f, d, new String[]{"C4", "E4", "G4"}, amp);
  
  playChord(4.0f, d, new String[]{"F4", "A4", "C5"}, amp);
  playChord(5.0f, d, new String[]{"C4", "E4", "G4"}, amp);
  playChord(6.0f, d, new String[]{"G3", "B3", "D4"}, amp);
  playChord(7.0f, 1.2f, new String[]{"C4", "E4", "G4"}, 0.15f);

  playChord(8.0f, d, new String[]{"C4", "E4", "G4"}, amp);
  playChord(9.0f, d, new String[]{"F4", "A4", "C5"}, amp);
  playChord(10.0f, d, new String[]{"C4", "E4", "G4"}, amp);
  playChord(11.0f, 1.2f, new String[]{"G3", "B3", "D4"}, 0.15f);

  playChord(12.0f, d, new String[]{"C4", "E4", "G4"}, amp);
  playChord(13.0f, d, new String[]{"F4", "A4", "C5"}, amp);
  playChord(14.0f, d, new String[]{"C4", "E4", "G4"}, amp);
  playChord(15.0f, 1.2f, new String[]{"G3", "B3", "D4"}, 0.15f);

  playChord(16.0f, d, new String[]{"C4", "E4", "G4"}, amp);
  playChord(17.0f, d, new String[]{"E4", "G4", "B4"}, amp);
  playChord(18.0f, d, new String[]{"F4", "A4", "C5"}, amp);
  playChord(19.0f, d, new String[]{"C4", "E4", "G4"}, amp);
  
  playChord(20.0f, d, new String[]{"F4", "A4", "C5"}, amp);
  playChord(21.0f, d, new String[]{"C4", "E4", "G4"}, amp);
  playChord(22.0f, d, new String[]{"G3", "B3", "D4"}, amp);
  playChord(23.0f, 1.2f, new String[]{"C4", "E4", "G4"}, 0.15f);

  out.resumeNotes();
}

// =====================================================
// キー操作
// =====================================================
void keyPressed() {
  if (key == 'p' || key == 'P') {
    // 音楽の再生
    playSong();
    
    // もしArduino側でLEDを光らせるなどの処理があれば合図を送る
    if (myPort != null) {
      myPort.write('p');
    }
  }
}

// ※今回はProcessing内で全て鳴らすため、serialEventでの受信発音は不要として削除しました。
