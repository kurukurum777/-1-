import processing.serial.*;
import ddf.minim.*;
import ddf.minim.ugens.*;

Minim minim;
Serial myPort;

String[] melody = {
"C5", "C5", "G5", "G5", "A5", "A5", "G5",
"F5", "F5", "E5", "E5", "D5", "D5", "C5"
};

float[] duration = {
0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.8f,
0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.8f
};

float[] startTime = {
0.0f, 0.5f, 1.0f, 1.5f, 2.0f, 2.5f, 3.0f,
4.0f, 4.5f, 5.0f, 5.5f, 6.0f, 6.5f, 7.0f
};

boolean isPlaying = false;
long playStartTime = 0;
int currentNoteIndex = 0;

void setup() {
size(300, 200);

minim = new Minim(this);

printArray(Serial.list());

String portName = Serial.list()[3];
myPort = new Serial(this, portName, 9600);

println("キーボードの 'p' を押すと再生します。");
}

void draw() {
background(0);

if (isPlaying) {

float elapsedTime = (millis() - playStartTime) / 1000.0f;


if (currentNoteIndex < melody.length && elapsedTime >= startTime[currentNoteIndex]) {


  float freq = Frequency.ofPitch(melody[currentNoteIndex]).asHz();

  int durMs = (int)(duration[currentNoteIndex] * 1000);


  String message = int(freq) + "," + durMs + "\n";

  myPort.write(message);
  println("送信: " + melody[currentNoteIndex] + " -> " + message.trim());

  currentNoteIndex++; // 次の音へ
}


if (currentNoteIndex >= melody.length) {
  isPlaying = false;
  println("再生終了");
}
}
}

void keyPressed() {
if (key == 'p') {
  isPlaying = true;
playStartTime = millis();
currentNoteIndex = 0;
println("再生開始...");
}
}
//pro
