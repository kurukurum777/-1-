import ddf.minim.*;//付録Bを参考にした
import ddf.minim.ugens.*;

Minim minim;
AudioOutput out;
Waveform currentWaveform;


// 各音の高さ
String [] melody = {
  "A4","A#4","B4","C5","C#5","D5","D#5","E5","F5","F#5","G5","G#5","A5"
};

//各音の長さ
float[] duration = {
  0.9f,0.9f,0.9f,0.9f,0.9f,0.9f,0.9f,
  0.9f,0.9f,0.9f,0.9f,0.9f,0.9f
};

//各音の開始位置
float[] startTime = {
  0.0f, 0.9f, 1.8f, 2.7f, 3.6f, 4.5f, 5.4f,
  6.3f, 7.2f, 8.1f, 9.0f, 9.9f, 10.8f
};
// 音色を変更するためにInstrument インタフェースを実装する
class HackInstrument implements Instrument
{
  Oscil wave;
  Line ampEnv;
  float maxAmp;
  
  HackInstrument ( float frequency , float maxAmp , Waveform wf )
  { // Oscilを使って音信号を作成（周波数, 振幅, 音色）
  wave = new Oscil(frequency,0,wf);
  // 引数で渡された最大振幅をクラスの変数に代入
  this.maxAmp=maxAmp;
  // 振幅変調を与える（初期値は1 から0 への減衰）
  ampEnv = new Line ( );
  // 作成した音信号を振幅変調の出力に送る
  ampEnv . patch ( wave . amplitude );
  }
  
  // コールバック関数：再生開始
  void noteOn ( float duration )
  { // 振幅変調の開始（長さ，開始時の振幅，終了時の振幅）
    ampEnv . activate ( duration , this .maxAmp , 0);
    // 音の再生
    wave . patch ( out );
  }
  
  // コールバック関数：再生停止
  void noteOff ()
  { // 再生の停止
  wave . unpatch ( out );
  }
}

void setup ()
{
  size (512 , 200);
  minim = new Minim ( this );
  //minimのインスタンスを用意
  minim = new Minim ( this );
  // minimのgetLineOutメソッドを呼び出し，AudioOutputオブジェクトを受け取る
  out = minim . getLineOut ();
  // テンポの設定，BPM=120
  out. setTempo ( 120 );
  // 音色の初期値（正弦波）
  currentWaveform = Waves.SINE ;
}

void playSong () {
  // 再生を停止
  out. pauseNotes ();
  // 繰り返し処理を使って異なる音を追加
  for (int i = 0; i < melody . length ; i++) {
    out.playNote (startTime [i], duration [i],
      new HackInstrument ( Frequency . ofPitch ( melody [i] ). asHz (),
        0.5f, currentWaveform ));
  }
  // 再生
  out. resumeNotes ();
}

void draw ()
{
  background (0);
  stroke (255);
  // 左チャンネルと右チャンネルに入っている波形を描画
  for(int i = 0; i < out. bufferSize () - 1; i++)
  {
    line ( i, 50 + out. left .get(i)*50 , i+1, 50 + out. left .get(i +1)*50 );
    line ( i, 150 + out. right .get(i)*50 , i+1, 150 + out. right .get(i +1)*50 );
  }
}

void keyPressed () {
  switch (key)
  {
    case '1':
    // 正弦波
    currentWaveform = Waves . SINE ;
    break;
   case '2':
     // 三角波
     currentWaveform = Waves . TRIANGLE ;
    break;
   case '3':
   // のこぎり波
     currentWaveform = Waves .SAW;
    break;
   case '4':
   // 矩形波
     currentWaveform = Waves . SQUARE ;
    break;
   case '5':
   // 16個の奇数倍音からなる音。振幅値はランダム。
   currentWaveform = Waves . randomNOddHarms (16);
   break;
  case '6':
  // 倍音の振幅値を指定した自作の音色
    currentWaveform = WavetableGenerator . gen10 (
      4096 , // サンプルサイズ（2 の倍数で）
      new float[] { 1.0f, 0.45f, 0.20f, 0.10f, 0.05f } // 各倍音の振幅値(0.0˜1.0）
      );
      break;
 case 'p':
     // 作成した信号を出力
     playSong ();
     break;
     default:
     break;
  }
}
