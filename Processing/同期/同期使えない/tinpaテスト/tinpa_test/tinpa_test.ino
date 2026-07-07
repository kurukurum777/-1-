#include <Wire.h>

#define SLAVE_ADDRESS 0x09

const uint8_t CMD_START = 0x01;
const uint8_t CMD_PLAY  = 0x02;
const uint8_t CMD_STOP  = 0x03;
const uint8_t CMD_BPM   = 0x04;

volatile boolean playTriggered = false;
volatile boolean stopTriggered = false;
float tempoScale = 1.0;

// ★ループ管理用の変数
boolean isPlaying = false;          // 現在ループ演奏中かどうかのフラグ
unsigned long lastSendTime = 0;     // 最後に楽譜データを送った時刻
const float BASE_LOOP_DURATION = 29.0; // 1周の長さ（最後の音の開始27.0秒 + 音の長さ2.0秒 = 29.0秒）

// 【楽譜】C3(130.81Hz)とG2(98.00Hz)の繰り返し（計28音）
float baseFreqs[] = {
  130.81, 130.81, 98.00, 98.00,
  130.81, 130.81, 98.00, 98.00,
  130.81, 130.81, 98.00, 98.00,
  130.81, 130.81, 98.00, 98.00,
  130.81, 130.81, 98.00, 98.00,
  130.81, 130.81, 98.00, 98.00,
  130.81, 130.81, 98.00, 98.00
};

// 【タイミング】0.0 から 27.0 までのカウント（計28個）
float startTimes[] = {
  0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0,
  10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0,
  20.0, 21.0, 22.0, 23.0, 24.0, 25.0, 26.0, 27.0
};

// 【長さ】元のコードの 2.0 固定を適用（計28個）
float durations[] = {
  1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
  1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
  1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0
};

// 【強さ】フォーマット維持のため 0.8 で統一（計28個）
float amplitudes[] = {
  0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8,
  0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8,
  0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8
};

int numNotes = 28;

void setup() {
  Serial.begin(115200);
  Wire.begin(SLAVE_ADDRESS);
  Wire.onReceive(receiveEvent);
}

void loop() {
  // 親機から新しくPLAY指示（最初の1回目、または一時停止からの再開）が来たとき
  if (playTriggered) {
    playTriggered = false;
    isPlaying = true;
    sendSongData();
    lastSendTime = millis(); // 送信した時間を記録（ミリ秒タイマースタート）
  }

  // ★ループ再生処理：1周分の時間が経過したら、自動で次の周のデータを送る
  if (isPlaying) {
    // 現在のテンポスケールを計算に含めて、ミリ秒単位の1周の長さを出す
    unsigned long currentLoopDuration = BASE_LOOP_DURATION * tempoScale * 1000;
    
    if (millis() - lastSendTime >= currentLoopDuration) {
      sendSongData();          // 次の周のデータを一斉送信
      lastSendTime = millis(); // タイマーをリセットして次の周へ
    }
  }

  // 親機からSTOP指示が来たとき
  if (stopTriggered) {
    isPlaying = false;      // 自動ループを停止
    Serial.println("stop"); // Processing側にも演奏停止を命令
    stopTriggered = false;
  }
}

void sendSongData() {
  for (int i = 0; i < numNotes; i++) {
    float playTime = (startTimes[i] * tempoScale) + 0.5; // 通信安定のための猶予
    float duration = durations[i] * tempoScale;
    float freq = baseFreqs[i];
    int instType = 2; 

    Serial.print(instType);       Serial.print(",");
    Serial.print(playTime, 2);    Serial.print(",");
    Serial.print(freq, 2);        Serial.print(",");
    Serial.print(duration, 2);    Serial.print(",");
    Serial.println(amplitudes[i], 2);

    delay(2);
  }
}

void receiveEvent(int howMany) {
  if (Wire.available() > 0) {
    uint8_t cmd = Wire.read();

    if (cmd == CMD_PLAY) {
      playTriggered = true;
    }
    else if (cmd == CMD_STOP) {
      playTriggered = false;
      stopTriggered = true; 
    }
    else if (cmd == CMD_BPM) {
      if (Wire.available() > 0) {
        uint8_t bpm = Wire.read();
        tempoScale = 120.0 / bpm;
      }
    }
  }
}