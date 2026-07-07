import ddf.minim.*;
import ddf.minim.ugens.*;

Minim minim;
AudioOutput out;
Waveform currentWaveform; 

// 鉄琴（グロッケン）風の音色
class GlockenspielInstrument implements Instrument {
  Oscil wave;
  ADSR  adsr; 
  
  GlockenspielInstrument(float frequency, float maxAmp, Waveform wf) {
    wave = new Oscil(frequency, maxAmp, wf);
    
    // ★修正2：Attackを 0.01 -> 0.02 にして、叩いた瞬間の「プツッ」というノイズを防止
    adsr = new ADSR(maxAmp, 0.02f, 1.5f, 0.0f, 1.5f);
    
    wave.patch(adsr);
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

void setup() {
  size(512, 200);
  minim = new Minim(this);
  out = minim.getLineOut();
  out.setTempo(80);
  
  currentWaveform = Waves.SINE; // 澄んだサイン波
}

void playChord(float startTime, float duration, String[] notes, float amp) {
  for (String note : notes) {
    out.playNote(startTime, duration, new GlockenspielInstrument(Frequency.ofPitch(note).asHz(), amp, currentWaveform));
  }
}

void playSong() {
  out.pauseNotes();

  String[] melody = {
    "C6", "C6", "G6", "G6", "A6", "A6", "G6", 
    "F6", "F6", "E6", "E6", "D6", "D6", "C6"
  };

  float[] duration = {
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.8f, 
    0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.3f, 0.8f
  };

  float[] startTime = {
    0.0f, 0.5f, 1.0f, 1.5f, 2.0f, 2.5f, 3.0f, 
    4.0f, 4.5f, 5.0f, 5.5f, 6.0f, 6.5f, 7.0f
  };

  // ★修正1：メロディの音量を 0.8 -> 0.4 に下げて音割れを防止
  float[] amplitude = {
    0.4f, 0.4f, 0.4f, 0.4f, 0.4f, 0.4f, 0.5f, 
    0.4f, 0.4f, 0.4f, 0.4f, 0.4f, 0.4f, 0.5f
  };

  for (int i = 0; i < melody.length; i++) {
    out.playNote(startTime[i], duration[i], 
      new GlockenspielInstrument(Frequency.ofPitch(melody[i]).asHz(), amplitude[i], currentWaveform)
    );
  }

  // ★修正1：和音（伴奏）の音量を 0.3 -> 0.15 に下げて音割れを防止
  playChord(0.0f, 0.8f, new String[]{"C5", "E5", "G5"}, 0.15f); 
  playChord(1.0f, 0.8f, new String[]{"E5", "G5", "B5"}, 0.15f); 
  playChord(2.0f, 0.8f, new String[]{"F5", "A5", "C6"}, 0.15f); 
  playChord(3.0f, 0.8f, new String[]{"C5", "E5", "G5"}, 0.15f); 
  
  playChord(4.0f, 0.8f, new String[]{"F5", "A5", "C6"}, 0.15f); 
  playChord(5.0f, 0.8f, new String[]{"C5", "E5", "G5"}, 0.15f); 
  playChord(6.0f, 0.8f, new String[]{"G4", "B4", "D5"}, 0.15f); 
  playChord(7.0f, 1.2f, new String[]{"C5", "E5", "G5"}, 0.2f); 

  out.resumeNotes();
}

void draw() {
  background(0);
  stroke(255);

  for (int i = 0; i < out.bufferSize() - 1; i++) {
    line(i, 50 - out.left.get(i)*50, i+1, 50 - out.left.get(i+1)*50);
    line(i, 150 - out.right.get(i)*50, i+1, 150 - out.right.get(i+1)*50);
  }
}
 
void keyPressed() {
  if (key == 'p') {
    playSong();
  }
}
