#include <Wire.h>

// ヴァイオリンのI2Cアドレス
#define SLAVE_ADDRESS 0x0C

const uint8_t CMD_PLAY  = 0x02;
const uint8_t CMD_STOP  = 0x03;
const uint8_t CMD_BPM   = 0x04;

volatile boolean playTriggered = false;
float tempoScale = 1.0;

// ==========================================
// ヴァイオリン メロディの楽譜データ（47音）
// ==========================================
float mFreqs[] = {
  523.25, 523.25, 783.99, 783.99, 880.00, 880.00, 783.99, // C C G G A A G
  698.46, 698.46, 659.25, 659.25, 587.33, 587.33, 523.25, // F F E E D D C
  783.99, 783.99, 698.46, 698.46, 659.25, 659.25, 587.33, // G G F F E E D
  783.99, 783.99,                                         // G G (重なり)
  783.99, 783.99, 698.46, 698.46, 659.25, 659.25, 587.33, // G G F F E E D
  523.25, 523.25, 523.25,                                 // C C C (重なり)
  523.25, 523.25, 783.99, 783.99, 880.00, 880.00, 783.99, // C C G G A A G
  698.46, 698.46, 659.25, 659.25, 587.33, 587.33, 523.25  // F F E E D D C
};

float mDur[] = {
  0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.8,
  0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.8,
  0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.8,
  0.3, 0.8,
  0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.8,
  0.3, 0.3, 0.8,
  0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.8,
  0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.8
};

float mStart[] = {
   0.0,  0.5,  1.0,  1.5,  2.0,  2.5,  3.0,
   4.0,  4.5,  5.0,  5.5,  6.0,  6.5,  7.0,
   8.0,  8.5,  9.0,  9.5, 10.0, 10.5, 11.0,
  10.5, 11.0,
  12.0, 12.5, 13.0, 13.5, 14.0, 14.5, 15.0,
  14.0, 14.5, 15.0,
  16.0, 16.5, 17.0, 17.5, 18.0, 18.5, 19.0,
  20.0, 20.5, 21.0, 21.5, 22.0, 22.5, 23.0
};

float mAmp[] = {
  0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.35,
  0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.35,
  0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.35,
  0.3, 0.35,
  0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.35,
  0.3, 0.3, 0.35,
  0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.35,
  0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.35
};

int numMelodyNotes = 47;

// ==========================================
// Setup & Loop
// ==========================================
void setup() {
  Serial.begin(115200); 
  Wire.begin(SLAVE_ADDRESS);
  Wire.onReceive(receiveEvent);
}

void loop() {
  if (playTriggered) {
    playTriggered = false;
    sendSongData();
  }
}

// ==========================================
// 音符データ送信処理
// ==========================================
void sendSongData() {
  // 1. メロディの送信
  for (int i = 0; i < numMelodyNotes; i++) {
    sendData(mStart[i], mFreqs[i], mDur[i], mAmp[i]);
  }

  // 2. 和音（伴奏）の送信
  // C4=261.63, E4=329.63, G4=392.00, B4=493.88, C5=523.25
  // F4=349.23, A4=440.00, G3=196.00, B3=246.94, D4=293.66
  
  /*
  sendChord( 0.0, 0.8, 261.63, 329.63, 392.00, 0.12); // C
  sendChord( 1.0, 0.8, 329.63, 392.00, 493.88, 0.12); // Em
  sendChord( 2.0, 0.8, 349.23, 440.00, 523.25, 0.12); // F
  sendChord( 3.0, 0.8, 261.63, 329.63, 392.00, 0.12); // C
  sendChord( 4.0, 0.8, 349.23, 440.00, 523.25, 0.12); // F
  sendChord( 5.0, 0.8, 261.63, 329.63, 392.00, 0.12); // C
  sendChord( 6.0, 0.8, 196.00, 246.94, 293.66, 0.12); // G
  sendChord( 7.0, 1.2, 261.63, 329.63, 392.00, 0.15); // C

  sendChord( 8.0, 0.8, 261.63, 329.63, 392.00, 0.12); // C
  sendChord( 9.0, 0.8, 349.23, 440.00, 523.25, 0.12); // F
  sendChord(10.0, 0.8, 261.63, 329.63, 392.00, 0.12); // C
  sendChord(11.0, 1.2, 196.00, 246.94, 293.66, 0.15); // G

  sendChord(12.0, 0.8, 261.63, 329.63, 392.00, 0.12); // C
  sendChord(13.0, 0.8, 349.23, 440.00, 523.25, 0.12); // F
  sendChord(14.0, 0.8, 261.63, 329.63, 392.00, 0.12); // C
  sendChord(15.0, 1.2, 196.00, 246.94, 293.66, 0.15); // G

  sendChord(16.0, 0.8, 261.63, 329.63, 392.00, 0.12); // C
  sendChord(17.0, 0.8, 329.63, 392.00, 493.88, 0.12); // Em
  sendChord(18.0, 0.8, 349.23, 440.00, 523.25, 0.12); // F
  sendChord(19.0, 0.8, 261.63, 329.63, 392.00, 0.12); // C
  sendChord(20.0, 0.8, 349.23, 440.00, 523.25, 0.12); // F
  sendChord(21.0, 0.8, 261.63, 329.63, 392.00, 0.12); // C
  sendChord(22.0, 0.8, 196.00, 246.94, 293.66, 0.12); // G
  sendChord(23.0, 1.2, 261.63, 329.63, 392.00, 0.15); // C
*/
}


// 3和音を分解して送信するヘルパー
void sendChord(float start, float dur, float f1, float f2, float f3, float amp) {
  sendData(start, f1, dur, amp);
  sendData(start, f2, dur, amp);
  sendData(start, f3, dur, amp);
}

// シリアル送信の根幹
void sendData(float start, float freq, float dur, float amp) {
  float playTime = (start * tempoScale) + 0.5; // 通信安定の0.5秒オフセット
  float d = dur * tempoScale;
  
  Serial.print("1,"); // ヴァイオリンの楽器IDは「1」
  Serial.print(playTime, 2); Serial.print(",");
  Serial.print(freq, 2);     Serial.print(",");
  Serial.print(d, 2);        Serial.print(",");
  Serial.println(amp, 2);
  
  delay(2); // シリアルバッファあふれ防止
}

// I2C受信イベント（親機からの指示）
void receiveEvent(int howMany) {
  if (Wire.available() > 0) {
    uint8_t cmd = Wire.read();
    if (cmd == CMD_PLAY) {
      playTriggered = true;
    }
    else if (cmd == CMD_BPM) {
      if (Wire.available() > 0) {
        uint8_t bpm = Wire.read();
        tempoScale = 120.0 / bpm;
      }
    }
  }
}