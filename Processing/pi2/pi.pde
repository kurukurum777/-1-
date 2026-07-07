import ddf.minim.*;//実行したやつは、数字を押しながらpのボタンを押す
import ddf.minim.ugens.*;

Minim minim;
AudioOutput out;

void setup()
{
    size(512,200);
    minim=new Minim(this);
    out=minim.getLineOut();
    out.setTempo(120);
}
void playSong(){
  out.pauseNotes();
    out.playNote(0.0f, 5.0f,
    new HackInstrument ( Frequency . ofPitch ( "A4" ). asHz (),
      0.5f, currentWaveform ));
//  out.playNote(0.0f,5.0,"A4");
  out.resumeNotes();
}

void draw()
{
  background(0);
  stroke(255);
  
  for(int i=0;i<out.bufferSize()-1;i++)
  {
    line(i, 50 - out.left.get(i)*50,i+1,50-out.left.get(i+1)*50);
    line(i,150 - out.right.get(i)*150,i+1,50-out.right.get(i+1)*50);
  }
}

void keyPressed () {
  switch (key)
  {
  case '1':
    currentWaveform = Waves . SINE ;
    break ;
  case '2':
    currentWaveform = Waves . TRIANGLE ;
    break ;
  case '3':
    currentWaveform = Waves .SAW;
    break ;
  case '4':
    currentWaveform = Waves . SQUARE ;
    break ;
  case '5':
     currentWaveform = WavetableGenerator . gen10 (
       4096 , // サンプルサイズ（2 の倍数で）
       new float [] { 1.0f, 0.45f, 0.20f, 0.10f, 0.05f } // 各倍音の振幅値
        );
      break ;
  case 'p':
// 作成した信号を出力
  playSong ();
    break ;
  default :
    break ;
   }
}
//void keyPressed(){
//  switch (key)
//  {
//    case 'p':
//      playSong();
//      break;
//  }
//}

Waveform currentWaveform;
class HackInstrument implements Instrument
{
  Oscil wave;
  Line ampEnv;
  float maxAmp;
  
  HackInstrument(float frequency,float maxAmp,Waveform wf)
  {
    wave = new Oscil(frequency, 0, wf);
    // 引数で渡された最大振幅をクラスの変数に代入
    this . maxAmp = maxAmp ;
// 振幅変調を与える（初期値は1 から0 への減衰）
     ampEnv = new Line ( );
// 作成した音信号を振幅変調の出力に送る
    ampEnv.patch(wave.amplitude);
  }
  
  void noteOn(float duration)
  {

    ampEnv . activate ( duration , this .maxAmp , 0);
// 音の再生
    wave . patch ( out );
// コールバック関数：再生停止
  }
  
  void noteOff ()
  { // 再生の停止
    wave . unpatch ( out );
  }
}

  
  
