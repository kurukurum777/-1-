#include <Wire.h>

// フルートのI2Cアドレス
#define SLAVE_ADDRESS 0x0B

const uint8_t CMD_START = 0x01;
const uint8_t CMD_PLAY  = 0x02;
const uint8_t CMD_STOP  = 0x03;
const uint8_t CMD_BPM   = 0x04;

volatile boolean playTriggered = false;
float tempoScale = 1.0;

// 基準となる「きらきら星」の周波数
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
  0.0,  0.5,  1.0,  1.5,  2.0,  2.5,  3.0,  4.0,  4.5,  5.0,  5.5,  6.0,  6.5,  7.0,
  8.0,  8.5,  9.0,  9.5, 10.0, 10.5, 11.0, 12.0, 12.5, 13.0, 13.5, 14.0, 14.5, 15.0,
  16.0, 16.5, 17.0, 17.5, 18.0, 18.5, 19.0, 20.0, 20.5, 21.0, 21.5, 22.0, 22.5, 23.0
};

float amplitudes[] = {
  0.28, 0.18, 0.18, 0.18, 0.28, 0.18, 0.22, 0.18, 0.18, 0.18, 0.18, 0.18, 0.18, 0.22,
  0.28, 0.18, 0.28, 0.18, 0.28, 0.18, 0.22, 0.28, 0.18, 0.28, 0.18, 0.18, 0.18, 0.28,
  0.28, 0.18, 0.18, 0.18, 0.28, 0.18, 0.22, 0.18, 0.18, 0.18, 0.18, 0.18, 0.18, 0.22
};

int numNotes = 42; 

void setup() {
  Serial.begin(115200); 

  // I2Cスレーブとして初期化
  Wire.begin(SLAVE_ADDRESS);
  Wire.onReceive(receiveEvent);
}

void loop() {
  if (playTriggered) {
    sendSongData();
    playTriggered = false;
  }
}

void sendSongData() {
  // 楽器ID 3（フルートとして区別）
  sendMelodyPart(3, 0.0, 1.0); 
}

void sendMelodyPart(int instType, float timeOffset, float freqMultiplier) {
  for (int i = 0; i < numNotes; i++) {
    // 成功コードと計算式を統一
    float playTime = (startTimes[i] * tempoScale) + timeOffset + 0.5; 
    float duration = durations[i] * tempoScale;
    float freq = baseFreqs[i] * freqMultiplier;
    
    Serial.print(instType);        Serial.print(",");
    Serial.print(playTime, 2);     Serial.print(",");
    Serial.print(freq, 2);         Serial.print(",");
    Serial.print(duration, 2);     Serial.print(",");
    Serial.println(amplitudes[i], 2);
    
    delay(2); 
  }
}

// I2C受信イベント（親機からの指示）
void receiveEvent(int howMany) {
  if (Wire.available() > 0) {
    uint8_t cmd = Wire.read();

    if (cmd == CMD_PLAY) {
      playTriggered = true;
    }
    else if (cmd == CMD_STOP) {
      playTriggered = false;
    }
    else if (cmd == CMD_BPM) {
      if (Wire.available() > 0) {
        uint8_t bpm = Wire.read();
        tempoScale = 120.0 / bpm;
      }
    }
  }
}