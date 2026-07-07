#include <Wire.h>

#define SLAVE_ADDRESS 0x09

const uint8_t CMD_START = 0x01;
const uint8_t CMD_PLAY  = 0x02;
const uint8_t CMD_STOP  = 0x03;
const uint8_t CMD_BPM   = 0x04;

volatile boolean playRequested = false;
volatile boolean stopRequested = false;
volatile uint8_t bpm = 80;

// --- きらきら星 ティンパニ伴奏用楽譜（4部輪唱対応：全25音） ---
const int numNotes = 25;

float baseFreqs[] = {
  130.81, 130.81, 130.81, 98.00,  // 0~6拍目 (1番目スタート)
  98.00,  130.81, 98.00,  130.81, // 8~14拍目 (2番目スタート)
  130.81, 130.81, 130.81, 98.00,  // 16~22拍目 (3番目スタート)
  130.81, 130.81, 130.81, 98.00,  // 24~30拍目 (4番目スタート)
  98.00,  130.81, 98.00,  130.81, // 32~38拍目 (1,2番目が演奏終了していく)
  130.81, 130.81, 130.81, 98.00,  // 40~46拍目 (4番目だけが残る)
  130.81                          // 47拍目 (★本当の最後の締め！)
};

float startTimes[] = {
  0.0, 2.0, 4.0, 6.0, 
  8.0, 10.0, 12.0, 14.0, 
  16.0, 18.0, 20.0, 22.0, 
  24.0, 26.0, 28.0, 30.0,
  32.0, 34.0, 36.0, 38.0,
  40.0, 42.0, 44.0, 46.0,
  47.0 
};

float durations[] = {
  1.0, 1.0, 1.0, 1.0, 
  1.0, 1.0, 1.0, 1.0, 
  1.0, 1.0, 1.0, 1.0, 
  1.0, 1.0, 1.0, 1.0, 
  1.0, 1.0, 1.0, 1.0, 
  1.0, 1.0, 1.0, 1.0, 
  2.0 // 最後だけ長く響かせる
};

float amplitudes[] = {
  0.8, 0.8, 0.8, 0.8, 
  0.8, 0.8, 0.8, 0.8, 
  0.8, 0.8, 0.8, 0.8, 
  0.8, 0.8, 0.8, 0.8, 
  0.8, 0.8, 0.8, 0.8, 
  0.8, 0.8, 0.8, 0.8, 
  0.8
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
    Serial.println("stop"); 
  }

  if (playing) {
    updateSong();
  }
}

void updateSong() {
  static uint8_t lastBpm = 80;
  if (bpm != lastBpm) {
    unsigned long elapsed = millis() - lastNoteMillis;
    lastNoteMillis = millis() - (elapsed * lastBpm / bpm);
    lastBpm = bpm;
  }

  if (currentNote >= numNotes - 1) {
    float duration = durations[currentNote];
    uint8_t currentBpm = bpm;
    float secPerBeat = 60.0 / currentBpm; 
    unsigned long waitMs = (unsigned long)(duration * secPerBeat * 1000.0);
    
    if (millis() - lastNoteMillis >= waitMs) {
      playing = false;
      currentNote = 0;
      Serial.println("stop");
    }
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

  float playTime = 0.0; 
  float duration = durations[i] * secPerBeat;
  float freq = baseFreqs[i];
  float amp = amplitudes[i];

  int instType = 2; // ティンパニ

  Serial.print(instType);       Serial.print(",");
  Serial.print(playTime, 2);    Serial.print(",");
  Serial.print(freq, 2);        Serial.print(",");
  Serial.print(duration, 2);    Serial.print(",");
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