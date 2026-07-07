#include <Wire.h>
#include <avr/pgmspace.h>

#define SLAVE_ADDRESS 0x0D  // ヴァイオリンのアドレス

const uint8_t CMD_START = 0x01;
const uint8_t CMD_PLAY  = 0x02;
const uint8_t CMD_STOP  = 0x03;
const uint8_t CMD_BPM   = 0x04;

volatile boolean playRequested = false;
volatile boolean stopRequested = false;
volatile uint8_t bpm = 80; // 初期BPM

// 楽譜データ（★PROGMEMのまま維持）
const float startTimes[] PROGMEM = {
  0.00, 0.00, 0.00, 0.00, 0.50, 1.00, 1.00, 1.00, 1.00, 1.50,
  2.00, 2.00, 2.00, 2.00, 2.50, 3.00, 3.00, 3.00, 3.00, 4.00,
  4.00, 4.00, 4.00, 4.50, 5.00, 5.00, 5.00, 5.00, 5.50, 6.00,
  6.00, 6.00, 6.00, 6.50, 7.00, 7.00, 7.00, 7.00, 8.00, 8.00,
  8.00, 8.00, 8.50, 9.00, 9.00, 9.00, 9.00, 9.50, 10.00, 10.00,
  10.00, 10.00, 10.50, 10.50, 11.00, 11.00, 11.00, 11.00, 11.00, 12.00,
  12.00, 12.00, 12.00, 12.50, 13.00, 13.00, 13.00, 13.00, 13.50, 14.00,
  14.00, 14.00, 14.00, 14.00, 14.50, 14.50, 15.00, 15.00, 15.00, 15.00,
  15.00, 16.00, 16.00, 16.00, 16.00, 16.50, 17.00, 17.00, 17.00, 17.00,
  17.50, 18.00, 18.00, 18.00, 18.00, 18.50, 19.00, 19.00, 19.00, 19.00,
  20.00, 20.00, 20.00, 20.00, 20.50, 21.00, 21.00, 21.00, 21.00, 21.50,
  22.00, 22.00, 22.00, 22.00, 22.50, 23.00, 23.00, 23.00, 23.00
};
const float durations[] PROGMEM = {
  0.80, 0.80, 0.80, 0.30, 0.30, 0.80, 0.80, 0.80, 0.30, 0.30,
  0.80, 0.80, 0.80, 0.30, 0.30, 0.80, 0.80, 0.80, 0.80, 0.80,
  0.80, 0.80, 0.30, 0.30, 0.80, 0.80, 0.80, 0.30, 0.30, 0.80,
  0.80, 0.80, 0.30, 0.30, 1.20, 1.20, 1.20, 0.80, 0.80, 0.80,
  0.80, 0.30, 0.30, 0.80, 0.80, 0.80, 0.30, 0.30, 0.80, 0.80,
  0.80, 0.30, 0.30, 0.30, 1.20, 1.20, 1.20, 0.80, 0.80, 0.80,
  0.80, 0.80, 0.30, 0.30, 0.80, 0.80, 0.80, 0.30, 0.30, 0.80,
  0.80, 0.80, 0.30, 0.30, 0.30, 0.30, 1.20, 1.20, 1.20, 0.80,
  0.80, 0.80, 0.80, 0.80, 0.30, 0.30, 0.80, 0.80, 0.80, 0.30,
  0.30, 0.80, 0.80, 0.80, 0.30, 0.30, 0.80, 0.80, 0.80, 0.80,
  0.80, 0.80, 0.80, 0.30, 0.30, 0.80, 0.80, 0.80, 0.30, 0.30,
  0.80, 0.80, 0.80, 0.30, 0.30, 1.20, 1.20, 1.20, 0.80
};
const float baseFreqs[] PROGMEM = {
  261.63, 329.63, 392.00, 523.25, 523.25, 329.63, 392.00, 493.88, 783.99, 783.99,
  349.23, 440.00, 523.25, 880.00, 880.00, 261.63, 329.63, 392.00, 783.99, 349.23,
  440.00, 523.25, 698.46, 698.46, 261.63, 329.63, 392.00, 659.26, 659.26, 196.00,
  246.94, 293.66, 587.33, 587.33, 261.63, 329.63, 392.00, 523.25, 261.63, 329.63,
  392.00, 783.99, 783.99, 349.23, 440.00, 523.25, 698.46, 698.46, 261.63, 329.63,
  392.00, 659.26, 659.26, 783.99, 196.00, 246.94, 293.66, 587.33, 783.99, 261.63,
  329.63, 392.00, 783.99, 783.99, 349.23, 440.00, 523.25, 698.46, 698.46, 261.63,
  329.63, 392.00, 523.25, 659.26, 523.25, 659.26, 196.00, 246.94, 293.66, 523.25,
  587.33, 261.63, 329.63, 392.00, 523.25, 523.25, 329.63, 392.00, 493.88, 783.99,
  783.99, 349.23, 440.00, 523.25, 880.00, 880.00, 261.63, 329.63, 392.00, 783.99,
  349.23, 440.00, 523.25, 698.46, 698.46, 261.63, 329.63, 392.00, 659.26, 659.26,
  196.00, 246.94, 293.66, 587.33, 587.33, 261.63, 329.63, 392.00, 523.25
};
const float amplitudes[] PROGMEM = {
  0.12, 0.12, 0.12, 0.30, 0.30, 0.12, 0.12, 0.12, 0.30, 0.30,
  0.12, 0.12, 0.12, 0.30, 0.30, 0.12, 0.12, 0.12, 0.35, 0.12,
  0.12, 0.12, 0.30, 0.30, 0.12, 0.12, 0.12, 0.30, 0.30, 0.12,
  0.12, 0.12, 0.30, 0.30, 0.15, 0.15, 0.15, 0.35, 0.12, 0.12,
  0.12, 0.30, 0.30, 0.12, 0.12, 0.12, 0.30, 0.30, 0.12, 0.12,
  0.12, 0.30, 0.30, 0.30, 0.15, 0.15, 0.15, 0.35, 0.35, 0.12,
  0.12, 0.12, 0.30, 0.30, 0.12, 0.12, 0.12, 0.30, 0.30, 0.12,
  0.12, 0.12, 0.30, 0.30, 0.30, 0.30, 0.15, 0.15, 0.15, 0.35,
  0.35, 0.12, 0.12, 0.12, 0.30, 0.30, 0.12, 0.12, 0.12, 0.30,
  0.30, 0.12, 0.12, 0.12, 0.30, 0.30, 0.12, 0.12, 0.12, 0.35,
  0.12, 0.12, 0.12, 0.30, 0.30, 0.12, 0.12, 0.12, 0.30, 0.30,
  0.12, 0.12, 0.12, 0.30, 0.30, 0.15, 0.15, 0.15, 0.35
};

int numNotes = 119;

// --- 演奏管理用（他の方の構造をベースに適用） ---
bool playing = false;
int currentNote = 0;
unsigned long lastNoteMillis = 0;
float playDuration = 0.0;

void setup() {
  Serial.begin(115200);
  Wire.begin(SLAVE_ADDRESS);
  Wire.onReceive(receiveEvent);
}

void loop() {
  if (playRequested) {
    playRequested = false;
    playing = true;
    currentNote = 0;
    lastNoteMillis = millis();
    sendNote(currentNote);
  }

  if (stopRequested) {
    stopRequested = false;
    playing = false;
    currentNote = 0;
    Serial.println("stop"); // Processing側を待機状態に戻す
  }

  if (playing) {
    updateSong();
  }
}

void updateSong() {
  // ★ 追加：BPMの変更を検知して、経過時間を新BPMに合わせて補正する
  static uint8_t lastBpm = 80;
  if (bpm != lastBpm) {
    unsigned long elapsed = millis() - lastNoteMillis;
    // 経過時間を新旧BPMの比率で伸縮させる
    lastNoteMillis = millis() - (elapsed * lastBpm / bpm);
    lastBpm = bpm;
  }

  // 曲の最後の音符まで送り終えたときの処理（他の方のループなし終了構造に準拠）
  if (currentNote >= numNotes - 1) {
    float duration = pgm_read_float(&durations[currentNote]);
    uint8_t currentBpm = bpm;
    float secPerBeat = 120.0 / currentBpm; // ヴァイオリン元の基準速度に調整
    unsigned long waitMs = (unsigned long)(duration * secPerBeat * 1000.0);
    
    // 最後の音が鳴り終わったら演奏を完全に停止
    if (millis() - lastNoteMillis >= waitMs) {
      playing = false;
      currentNote = 0;
      Serial.println("stop"); // Processing側の画面をWaitingに戻す
    }
    return;
  }

  // 楽譜データから現在の音符と次の音符の時間を取得して差分(拍数)を計算
  float startTimeCurrent = pgm_read_float(&startTimes[currentNote]);
  float startTimeNext    = pgm_read_float(&startTimes[currentNote + 1]);
  float beatsToNext      = startTimeNext - startTimeCurrent;

  uint8_t currentBpm = bpm;
  float secPerBeat = 120.0 / currentBpm; // ヴァイオリン楽譜の基準に合わせるため120.0を使用

  unsigned long waitMs = (unsigned long)(beatsToNext * secPerBeat * 1000.0);

  // 指定時間が経過したら次の音を送信
  if (millis() - lastNoteMillis >= waitMs) {
    currentNote++;
    lastNoteMillis = millis();
    sendNote(currentNote);
  }
}

void sendNote(int i) {
  uint8_t currentBpm = bpm;
  float secPerBeat = 120.0 / currentBpm;

  float playTime = 0.0;  // ★リアルタイム方式のため、Processing側で受け取ったら即時再生
  float duration = pgm_read_float(&durations[i]) * secPerBeat;
  float freq     = pgm_read_float(&baseFreqs[i]);
  float amp      = pgm_read_float(&amplitudes[i]);

  int instType = 3; // 🎻 ヴァイオリンの楽器IDは「3」

  Serial.print(instType);       Serial.print(",");
  Serial.print(playTime, 2);    Serial.print(",");
  Serial.print(freq, 2);        Serial.print(",");
  Serial.print(duration, 2);Serial.print(",");
  Serial.println(amp, 2);
}

void receiveEvent(int howMany) {
  while (Wire.available() > 0) {
    uint8_t cmd = Wire.read();

    if (cmd == CMD_START) {
      // 何もしない
    }
    else if (cmd == CMD_PLAY) {
      playRequested = true;
    }
    else if (cmd == CMD_STOP) {
      playRequested = false;
      stopRequested = true; 
    }
    else if (cmd == CMD_BPM) {
      if (Wire.available() > 0) {
        bpm = Wire.read();
      }
    }
  }
}