#include <Wire.h>

#define SLAVE_ADDRESS 0x08

// すべて「C5（523.25Hz）」の音程に固定
float baseFreqs[] = {
  523.25, 523.25, 523.25, 523.25, 523.25, 523.25, 523.25,
  523.25, 523.25, 523.25, 523.25, 523.25, 523.25, 523.25,
  523.25, 523.25, 523.25, 523.25, 523.25, 523.25, 523.25,
  523.25, 523.25, 523.25, 523.25, 523.25, 523.25, 523.25,
  523.25, 523.25, 523.25, 523.25, 523.25, 523.25, 523.25,
  523.25, 523.25, 523.25, 523.25, 523.25, 523.25, 523.25
};

// 音符の長さ
float durations[] = {
  0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.8, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.8,
  0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.8, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.8,
  0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.8, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 1.6
};

// 鳴らし始めるタイミング
float startTimes[] = {
  0.0,  0.5,  1.0,  1.5,  2.0,  2.5,  3.0,  4.0,  4.5,  5.0,  5.5,  6.0,  6.5,  7.0,
  8.0,  8.5,  9.0,  9.5,  10.0, 10.5, 11.0, 12.0, 12.5, 13.0, 13.5, 14.0, 14.5, 15.0,
  16.0, 16.5, 17.0, 17.5, 18.0, 18.5, 19.0, 20.0, 20.5, 21.0, 21.5, 22.0, 22.5, 23.0
};

// 音の強弱（アクセント）
float amplitudes[] = {
  0.28, 0.18, 0.18, 0.18, 0.28, 0.18, 0.22, 0.18, 0.18, 0.18, 0.18, 0.18, 0.18, 0.22,
  0.28, 0.18, 0.28, 0.18, 0.28, 0.18, 0.22, 0.28, 0.18, 0.28, 0.18, 0.18, 0.18, 0.28,
  0.28, 0.18, 0.18, 0.18, 0.28, 0.18, 0.22, 0.18, 0.18, 0.18, 0.18, 0.18, 0.18, 0.22
};

int numNotes = 42; 

void setup() {
  Serial.begin(115200); 
  Wire.begin(SLAVE_ADDRESS); // 子機として参加
}

void loop() {
  if (Serial.available() > 0) {
    char c = Serial.read();
    if (c == 'p') {
      sendSongData();
    }
  }
}

void sendSongData() {
  sendMelodyPart(1, 0.0, 1.0); 
}

void sendMelodyPart(int instType, float timeOffset, float freqMultiplier) {
  for (int i = 0; i < numNotes; i++) {
    float playTime = startTimes[i] + timeOffset + 0.5; // 通信安定のための猶予
    float freq = baseFreqs[i] * freqMultiplier;
    
    Serial.print(instType);        Serial.print(",");
    Serial.print(playTime, 2);     Serial.print(",");
    Serial.print(freq, 2);         Serial.print(",");
    Serial.print(durations[i], 2); Serial.print(",");
    Serial.println(amplitudes[i], 2);
    
    delay(2); 
  }
}