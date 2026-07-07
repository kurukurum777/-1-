#include <Wire.h>

#define SLAVE_ADDRESS 0x0A

volatile bool playRequested = false;
volatile bool stopRequested = false;
volatile uint8_t bpm = 80;

// --- コマンド定義 ---
const uint8_t CMD_START = 0x01;
const uint8_t CMD_PLAY  = 0x02;
const uint8_t CMD_STOP  = 0x03;
const uint8_t CMD_BPM   = 0x04;

const int numNotes = 42;

float baseFreqs[] = {
  523.25, 523.25, 783.99, 783.99, 880.00, 880.00, 783.99,
  698.46, 698.46, 659.25, 659.25, 587.33, 587.33, 523.25,
  783.99, 783.99, 698.46, 698.46, 659.25, 659.25, 587.33,
  783.99, 783.99, 698.46, 698.46, 659.25, 659.25, 587.33,
  523.25, 523.25, 783.99, 783.99, 880.00, 880.00, 783.99,
  698.46, 698.46, 659.25, 659.25, 587.33, 587.33, 523.25
};

float durations[] = {
  0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.8, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.8,
  0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.8, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.8,
  0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.8, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 1.6
};

float startTimes[] = {
  0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 4.5, 5.0, 5.5, 6.0, 6.5, 7.0,
  8.0, 8.5, 9.0, 9.5, 10.0, 10.5, 11.0, 12.0, 12.5, 13.0, 13.5, 14.0, 14.5, 15.0,
  16.0, 16.5, 17.0, 17.5, 18.0, 18.5, 19.0, 20.0, 20.5, 21.0, 21.5, 22.0, 22.5, 23.0
};

float amplitudes[] = {
  0.28, 0.18, 0.18, 0.18, 0.28, 0.18, 0.22, 0.18, 0.18, 0.18, 0.18, 0.18, 0.18, 0.22,
  0.28, 0.18, 0.28, 0.18, 0.28, 0.18, 0.22, 0.28, 0.18, 0.28, 0.18, 0.18, 0.18, 0.28,
  0.28, 0.18, 0.18, 0.18, 0.28, 0.18, 0.22, 0.18, 0.18, 0.18, 0.18, 0.18, 0.18, 0.22
};

// --- 演奏管理用 ---
bool playing = false;
int currentNote = 0;
unsigned long lastNoteMillis = 0;

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
  }

  if (playing) {
    updateSong();
  }
}

void updateSong() {
  if (currentNote >= numNotes - 1) {
    playing = false;
    return;
  }

  float beatsToNext = startTimes[currentNote + 1] - startTimes[currentNote];

  uint8_t currentBpm = bpm;
  float secPerBeat = 60.0 / currentBpm;

  unsigned long waitMs = (unsigned long)(beatsToNext * secPerBeat * 1000.0);

  if (millis() - lastNoteMillis >= waitMs) {
    currentNote++;
    lastNoteMillis = millis();
    sendNote(currentNote);
  }
}

void sendNote(int i) {
  uint8_t currentBpm = bpm;
  float secPerBeat = 60.0 / currentBpm;

  float playTime = 0.0;  // ★Processing側では受け取ったらすぐ鳴らす
  float duration = durations[i] * secPerBeat;
  float freq = baseFreqs[i];

  Serial.print(1);
  Serial.print(",");
  Serial.print(playTime, 2);
  Serial.print(",");
  Serial.print(freq, 2);
  Serial.print(",");
  Serial.print(duration, 2);
  Serial.print(",");
  Serial.println(amplitudes[i], 2);
}

void receiveEvent(int howMany) {
  while (Wire.available()) {
    uint8_t c = Wire.read();

    if (c == CMD_START) {
      // 何もしない
    }
    else if (c == CMD_PLAY) {
      playRequested = true;
    }
    else if (c == CMD_STOP) {
      stopRequested = true;
    }
    else if (c == CMD_BPM) {
      if (Wire.available()) {
        bpm = Wire.read();
      }
    }
  }
}
