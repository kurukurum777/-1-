import processing.serial.*;
import ddf.minim.*;
import ddf.minim.ugens.*;

Minim minim;
AudioOutput out;
Serial myPort;

// =========================================================
// 鉄琴音源
// =========================================================
class GlockenspielInstrument implements Instrument {
Summer mix;
ADSR mainEnv;

GlockenspielInstrument(float frequency, float maxAmp) {
mix = new Summer();

Oscil osc1 = new Oscil(frequency, 0.6f, Waves.SINE);
Oscil osc2 = new Oscil(frequency * 2.756f, 0.25f, Waves.SINE);
Oscil osc3 = new Oscil(frequency * 5.404f, 0.1f, Waves.SINE);
Oscil osc4 = new Oscil(frequency + 2.5f, 0.05f, Waves.SINE);

osc1.patch(mix);
osc2.patch(mix);
osc3.patch(mix);
osc4.patch(mix);

mainEnv = new ADSR(maxAmp, 0.001f, 0.4f, 0.3f, 2.0f);
mix.patch(mainEnv);
}

void noteOn(float duration) {
mainEnv.noteOn();
mainEnv.patch(out);
}

void noteOff() {
mainEnv.noteOff();
mainEnv.unpatchAfterRelease(out);
}
}
// =========================================================

void setup() {
size(512, 200);
minim = new Minim(this);
out = minim.getLineOut();
out.setTempo(80);

printArray(Serial.list());
String portName = Serial.list()[2]; // ←ここは環境に合わせる
myPort = new Serial(this, portName, 115200);
myPort.bufferUntil('\n');
}

// Arduinoから受信して鳴らすだけ
void serialEvent(Serial p) {
String inString = p.readStringUntil('\n');
if (inString != null) {
inString = trim(inString);
String[] data = split(inString, ',');

if (data.length == 5) {
  float startTime = float(data[1]);
  float freq      = float(data[2]);
  float duration  = float(data[3]);
  float amp       = float(data[4]);

  float boostedAmp = min(amp * 3.0f, 1.0f);
  out.playNote(startTime, duration, new GlockenspielInstrument(freq, boostedAmp));
}
}
}

// 波形表示（デバッグ用）
void draw() {
  background(0);
  stroke(255);

  for (int i = 0; i < out.bufferSize() - 1; i++) {
    line(i, 50 - out.left.get(i) * 50,
         i + 1, 50 - out.left.get(i + 1) * 50);

    line(i, 150 - out.right.get(i) * 50,
         i + 1, 150 - out.right.get(i + 1) * 50);
  }
}
