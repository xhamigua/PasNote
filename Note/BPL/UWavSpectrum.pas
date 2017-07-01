//------------------------------------------------------------------------------
//
//WAV声波频谱分析显示控件
//
//
//------------------------------------------------------------------------------

{$INCLUDE '..\TypeDef.inc'}
unit UWavSpectrum;
interface
uses
  Windows, Messages, SysUtils, Classes, Controls, MMSystem, Graphics, Math;
type
  TComplex = record
    Real: Double;
    Imag: Double;
  end;
  PComplexArray = ^TComplexArray;
  TComplexArray = array of TComplex;

const
  DEF_BUFFER_SIZE = 1024;
  DEF_DATA_SCALE  = 16384;
  SIZE_RATIO      = 4;

type
  TWaveMode = (svmLine, svmDot, svmNubby);    //线、点、块状
  TAMStyle  = (smsSpectrum, smsOscillograph); //频谱、示波器

  TAudioSpectrum = class(TCustomControl)
  private
    FActive:      Boolean;
    FRealTime:    Boolean;
    FRedial:      Boolean;
    FAutoFit:     Boolean;         //自适应幅度
    FWaveIn:      HWAVEIN;
    FWaveHeaders: array of WaveHdr;
    FWaveFormat:  TWaveFormatEx;
    FBuffers:     Integer;
    FBufferSize:  Integer;
    FBufferIndex: Integer;
    FWaveBufSize: Integer;
    FErrorMsg:    string;
    FTick:        DWord;
    FBorderColor,
    FForeColor:   TColor;
    FWaitTick:    DWord;
    FDataStep:    Integer;
    FDataScale:   Integer;
    FFillSkip:    Integer;
    FMixTime:     Integer;
    FWaveMode:    TWaveMode;
    FAMStyle:     TAMStyle;
    FFreqWidth:   Integer;         //频带宽度
    FFreqSpace:   Integer;         //频带间隔
    FWaveSource:  TComplexArray;
    FFreqTarget:  TComplexArray;
    function InitWaveIn: MMRESULT;
    function CloseWaveIn: MMRESULT;
    procedure SetActive(Value: Boolean);
    procedure SetBuffers(Value: Integer);
    procedure SetBorderColor(Value: TColor);
    procedure SetForeColor(Value: TColor);
    procedure SetErrorMsg(const Value: string);
    procedure SetDataStep(Value: Integer);
    procedure SetDataScale(Value: Integer);
    procedure SetMixTime(Value: Integer);
    procedure SetAMStyle(Value: TAMStyle);
    procedure SetFreqWidth(Value: Integer);
    procedure SetFreqSpace(Value: Integer);
    procedure WMEraseBkgnd(var Message: TMessage); message WM_ERASEBKGND;
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Paint; override;
    procedure ProcessInput;
    procedure PaintWave(Data: PSmallInt); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Open;
    procedure Close;
  published
    property Active: Boolean read FActive write SetActive default False;
    property RealTime: Boolean read FRealTime write FRealTime default False;
    property Buffers: Integer read FBuffers write SetBuffers default 2;
    property ErrorMsg: string read FErrorMsg write SetErrorMsg;
    property BorderColor: TColor read FBorderColor write SetBorderColor default clGreen;
    property ForeColor: TColor read FForeColor write SetForeColor default clAqua;
    property WaitTick: DWord read FWaitTick write FWaitTick default 40;
    property DataStep: Integer read FDataStep write SetDataStep default 2;       //波形步数
    property DataScale: Integer read FDataScale write SetDataScale default DEF_DATA_SCALE;   //调整幅度
    property MixTime: Integer read FMixTime write SetMixTime default 0;
    property WaveMode: TWaveMode read FWaveMode write FWaveMode default svmLine;         //绘制模式
    property Redial: Boolean read FRedial write FRedial default False;                   //放射效果
    property AutoFit: Boolean read FAutoFit write FAutoFit default False;                //自适应幅度
    property AMStyle: TAMStyle read FAMStyle write SetAMStyle default smsOscillograph;   //频谱、示波器
    property FreqWidth: Integer read FFreqWidth write SetFreqWidth default 1;
    property FreqSpace: Integer read FFreqSpace write SetFreqSpace default 1;

    property Action;
    property Align;
    property Color default clBlack;
    property Constraints;
    //property Ctl3D;
    property PopupMenu;
    property ShowHint;
    property Visible;

    property OnCanResize;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDockDrop;
    property OnDockOver;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetSiteInfo;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
    property OnUnDock;
  end;

  //傅立叶变换
  procedure FFT(Source, Target: TComplexArray; iCount: Integer);
  procedure iFFT(Source, Target: TComplexArray; iCount: Integer);
  procedure Register;
implementation

procedure Register;
begin
  RegisterComponents('AHMGbpl', [TAudioSpectrum]);
end;

function NumberOfBitsNeeded(PowerOfTwo: word):word;
var
  i: word;
begin
  for i := 0 to 16 do begin
    if (PowerOfTwo AND (1 SHL i)) <> 0 then begin
      Result := i;
      Exit;
    end;
  end;
  Result := 0;
end;

function ReverseBits(index, NumBits: word):word;
var
  i: word;
begin
  Result := 0;
  for i := 0 to NumBits-1 do begin
    Result := (Result SHL 1) OR (index AND 1);
    index := index SHR 1;
  end;
end;

procedure DoFFT(Source, Target: TComplexArray; iCount: Integer; AngleNumerator: Double);
var
  NumBits, i, j, k, n, BlockSize, BlockEnd: word;
  delta_angle, delta_ar: double;
  alpha, beta: double;
  tr, ti, ar, ai: double;
begin
  //if not IsPowerOfTwo(iCount) or (iCount<2) then
  //  raise Exception.Create('Count is not a positive integer power of 2');

  NumBits := NumberOfBitsNeeded (iCount);
  for i := 0 to iCount-1 do begin
    j := ReverseBits ( i, NumBits );
    Target[j] := Source[i];
  end;
  BlockEnd := 1;
  BlockSize := 2;
  while BlockSize <= iCount do begin
    delta_angle := AngleNumerator / BlockSize;
    alpha       := sin ( 0.5 * delta_angle );
    alpha       := 2.0 * alpha * alpha;
    beta        := sin ( delta_angle );

    i := 0;
    while i < iCount do begin
      ar := 1.0;    (* cos(0) *)
      ai := 0.0;    (* sin(0) *)

      j := i;
      for n := 0 to BlockEnd-1 do begin
        k := j + BlockEnd;
        tr := ar*Target[k].Real - ai*Target[k].Imag;
        ti := ar*Target[k].Imag + ai*Target[k].Real;
        Target[k].Real := Target[j].Real - tr;
        Target[k].Imag := Target[j].Imag - ti;
        Target[j].Real := Target[j].Real + tr;
        Target[j].Imag := Target[j].Imag + ti;
        delta_ar := alpha*ar + beta*ai;
        ai := ai - (alpha*ai - beta*ar);
        ar := ar - delta_ar;
        INC(j);
      end;
      i := i + BlockSize;
    end;
    BlockEnd := BlockSize;
    BlockSize := BlockSize SHL 1;
  end;
end;

procedure FFT(Source, Target: TComplexArray; iCount: Integer);
begin
  DoFFT(Source, Target, iCount, 2 * PI);
end;

procedure iFFT(Source, Target: TComplexArray; iCount: Integer);
var
  i: Integer;
begin
  DoFFT(Source, Target, iCount, -2 * PI);
  (* Normalize the resulting time samples... *)
  for i := 0 to iCount -1 do begin
    Target[i].Real := Target[i].Real / iCount;
    Target[i].Imag := Target[i].Imag / iCount;
  end;
end;

//---------------------------------------------------------------------------
procedure WaveInProc(waveIn: HWAVEIN; uMsg: UINT; dwInstance, dwParam1, dwParam2: DWORD); stdcall;
begin
  if (uMsg = MM_WIM_DATA) and (dwInstance <> 0)
      and (TObject(dwInstance) is TAudioSpectrum) then
  begin
    with TAudioSpectrum(TObject(dwInstance)) do
    begin
      ProcessInput;
    end;
  end;
end;
//---------------------------------------------------------------------------



{ TAudioSpectrum }

procedure TAudioSpectrum.Close;
begin
  SetActive(False);
end;

function TAudioSpectrum.CloseWaveIn: MMRESULT;
var
  i: Integer;
begin
  for i := Low(FWaveHeaders) to High(FWaveHeaders) do begin
    while waveInUnprepareHeader(FWaveIn, @FWaveHeaders[i], SizeOf(WAVEHDR)) = WAVERR_STILLPLAYING do
    begin
      Sleep(200);      //这样才有保证释放彻底！  2006.3.27
    end;
  end;
  Result := waveInClose(FWaveIn);
  for i := Low(FWaveHeaders) to High(FWaveHeaders) do begin
    VirtualFree(FWaveHeaders[i].lpData, 0, MEM_RELEASE );
    FWaveHeaders[i].lpData := nil;
  end;
end;

constructor TAudioSpectrum.Create(AOwner: TComponent);
begin
  inherited;
  Width   := 200;
  Height  := 100;
  Color   := clBlack;
  TabStop := True;   //设为True，才能接受键盘消息（含弹出右键菜单）

  FBorderColor := clGreen;
  FForeColor   := clAqua;
  SetBuffers(2);
  FBufferSize  := DEF_BUFFER_SIZE;
  FBufferIndex := Low(FWaveHeaders);
  with FWaveFormat do begin
    wFormatTag      := WAVE_FORMAT_PCM;
    nChannels       := 2;
    nSamplesPerSec  := 44100;
    wBitsPerSample  := 16;
    nBlockAlign     := wBitsPerSample div 8 * nChannels;
    nAvgBytesPerSec := nBlockAlign * nSamplesPerSec;
    cbSize          := 0;
    FWaveBufSize    := FBufferSize * nBlockAlign;
  end;
  FWaitTick   := 40;
  FDataStep   := 2;
  FDataScale  := DEF_DATA_SCALE;
  FWaveMode   := svmLine;
  FAMStyle    := smsOscillograph;
  FFreqWidth  := 1;
  FFreqSpace  := 1;
  SetLength(FWaveSource, DEF_BUFFER_SIZE);
  SetLength(FFreqTarget, DEF_BUFFER_SIZE);
end;

destructor TAudioSpectrum.Destroy;
begin
  SetActive(False);
  inherited;
end;

function TAudioSpectrum.InitWaveIn: MMRESULT;
var
  i: Integer;
  sErr: string[255];
begin
  for i := Low(FWaveHeaders) to High(FWaveHeaders) do begin
    with FWaveHeaders[i] do
    begin
      dwBufferLength := FWaveBufSize;
      dwFlags        := 0;
      dwLoops        := 0;
      if lpData = nil then
        lpData := PAnsiChar(VirtualAlloc(nil, FWaveBufSize, MEM_COMMIT, PAGE_READWRITE));
    end;
  end;
  Result := waveInOpen(@FWaveIn, WAVE_MAPPER, @FWaveFormat, DWORD(@WaveInProc),
                       DWord(Self), CALLBACK_FUNCTION);
  if Result = MMSYSERR_NOERROR then begin
    FBufferIndex := Low(FWaveHeaders);
    for i := Low(FWaveHeaders) to High(FWaveHeaders) do begin
      Result := waveInPrepareHeader(FWaveIn, @FWaveHeaders[i], SizeOf(WAVEHDR));
      if Result = MMSYSERR_NOERROR then begin
        Result := waveInAddBuffer(FWaveIn, @FWaveHeaders[i], SizeOf(WAVEHDR));
      end;
      if Result <> MMSYSERR_NOERROR then Break;
    end;
    if Result = MMSYSERR_NOERROR then begin
      Result := waveInStart(FWaveIn);
      FTick  := GetTickCount();
    end;
  end;
  if Result <> MMSYSERR_NOERROR then begin
    if waveInGetErrorText(Result, PChar(@sErr[1]), Length(sErr)) = MMSYSERR_NOERROR then
      FErrorMsg := sErr;
  end;
end;

procedure TAudioSpectrum.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;
  if not Focused then begin
    Windows.SetFocus(Handle);
  end;
end;

procedure TAudioSpectrum.Open;
begin
  SetActive(True);
end;

procedure TAudioSpectrum.Paint;
begin
//  inherited;
  with Canvas do
  begin
    Lock;
    try
      Brush.Color := Color;
      Pen.Color   := BorderColor;
      Rectangle( 0, 0, Width, Height );
    finally
      UnLock;
    end;
  end;
end;

procedure TAudioSpectrum.PaintWave(Data: PSmallInt);
var
  pData: PSmallInt;

  procedure CalcRedialXY(var x, y: Integer);
  var
    iOriginX, iOriginY, iRadii: Integer;
    dStereoScale: Double;
  begin
    iOriginX := Width shr 1;
    iOriginY := Height shr 1;
    iRadii   := Min(Width, Height) shr 1;
    dStereoScale := 0.707 * iRadii / DataScale;

    x := iOriginX + Trunc(Tan(y) * x * dStereoScale);
    y := iOriginY + Trunc(CoTan(x) * y * dStereoScale);

    if WaveMode = svmLine then
      Canvas.MoveTo(iOriginX, iOriginY);
  end;

  function GetScale: Integer;
  var
    dwVolume: DWord;
  begin
    if AutoFit and (waveOutGetVolume(0, @dwVolume)= MMSYSERR_NOERROR) then begin
      Result := Max(Integer((dwVolume shr 16)and $0FFFF),
                    Integer(dwVolume and $0FFFF)) shr 1;
    end else begin
      Result := DataScale;          //标准: 32768, 只是可能幅度太小
    end;
  end;

  procedure DoPaintWaveGraph;
  var
    x, y, i, k, iOldX, iZeroLevel: Integer;
    dTimeScale, ts:  Double;
  begin
    iZeroLevel  := Height shr 1;
    dTimeScale := iZeroLevel / GetScale();
    with Canvas do begin
      ts := Width / FBufferSize;
      for k := 0 to (DataStep + 1) mod 2 do begin
        MoveTo(0, iZeroLevel);
        iOldX := -1;
        pData := Data;
        Inc(pData, k);
        i     := k;
        while i < FBufferSize do begin
          if Redial then  x := i  else  x := Trunc(i * ts);
          if x <> iOldX then begin
            if Redial then begin
              y := pData^;
              CalcRedialXY(x, y);
            end else
              y := iZeroLevel - Trunc(pData^ * dTimeScale);
            case WaveMode of
              svmLine:    LineTo( x, y );
              svmDot:     Pixels[x, y] := ForeColor;
              svmNubby:   FillRect(Rect(x-1, y-1, x+1, y+1));
            end;
            iOldX := x;
          end;
          Inc(pData, DataStep);
          Inc(i, DataStep);
        end;
      end;
    end;
  end;

  procedure DoPaintSpectrum;
  var
    i, x, y: Integer;
  begin
    pData := Data;
    for i := 0 to DEF_BUFFER_SIZE -1 do begin
      FWaveSource[i].Real := DWord(pData^ - 32768);
      FWaveSource[i].Imag := 0;
      Inc(pData);
    end;
    FFT(FWaveSource, FFreqTarget, DEF_BUFFER_SIZE);
    with Canvas do begin
      x := 0;
      for i := 0 to DEF_BUFFER_SIZE div SIZE_RATIO -1 do begin
        if x < Width then begin
          y := Trunc(sqrt((FFreqTarget[i].Real * FFreqTarget[i].Real
                           + FFreqTarget[i].Imag * FFreqTarget[i].Imag)
                          / DEF_BUFFER_SIZE));
          y := Min(y, 8192);
          y := Height - y * Height div 8192;
          Rectangle(x, y, x + FreqWidth, Height -1);
          Inc(x, FreqSpace + FreqWidth);
        end else begin
          Break;
        end;
      end;
    end;
  end;

begin
  if not Active or not Visible then Exit;

  if not RealTime then begin
    if GetTickCount() - FTick < WaitTick then Exit;
    FTick := GetTickCount();
  end;

  with Canvas do begin
    Lock();
    try
      Brush.Color := Color;
      Pen.Color   := BorderColor;
      if FFillSkip = 0 then begin
        Rectangle( 0, 0, Width, Height );
      end;
      if MixTime = 0 then begin
        FFillSkip := 0;
      end else begin
        Inc(FFillSkip);
        FFillSkip := FFillSkip mod MixTime;
      end;

      Pen.Color   := ForeColor;
      Brush.Color := ForeColor;
      case AMStyle of
        smsSpectrum:     DoPaintSpectrum();
        smsOscillograph: DoPaintWaveGraph();
      end;
    finally
      Unlock();
    end;
  end;
end;

procedure TAudioSpectrum.ProcessInput;
var
  pBuff: PWAVEHDR;
begin
  if FActive then begin
    pBuff := @FWaveHeaders[FBufferIndex];
    waveInUnprepareHeader(FWaveIn, pBuff, SizeOf(WAVEHDR));
    if not RealTime then
      PaintWave(PSmallInt(pBuff.lpData)); //其实可用线程，只不过一般情况不需要
    Inc(FBufferIndex);
    if FBufferIndex > High(FWaveHeaders) then
      FBufferIndex := Low(FWaveHeaders);
    waveInPrepareHeader(FWaveIn, @FWaveHeaders[FBufferIndex], SizeOf(WAVEHDR));
    waveInAddBuffer(FWaveIn, @FWaveHeaders[FBufferIndex], SizeOf(WAVEHDR));
    if RealTime then
      PaintWave(PSmallInt(pBuff.lpData)); //其实可用线程，只不过一般情况不需要
  end;
end;

procedure TAudioSpectrum.SetActive(Value: Boolean);
begin                            //由于采用回调函数方法似乎在系统中只能独占使用
  if FActive <> Value then begin //所以设计期不可将Active设为True！
    FActive := Value;            //当然，设计期还是可以预览一下的，XP则可以?!
    if Value then begin
      FActive := InitWaveIn = MMSYSERR_NOERROR;
      if not FActive then
        CloseWaveIn;
    end else begin
      CloseWaveIn;
    end;
  end;
end;

procedure TAudioSpectrum.SetAMStyle(Value: TAMStyle);
begin
  if Value <> FAMStyle then begin
    FAMStyle := Value;
    Paint;
  end;
end;

procedure TAudioSpectrum.SetBorderColor(Value: TColor);
begin
  if FBorderColor <> Value then begin
    FBorderColor := Value;
    Paint;
  end;
end;

procedure TAudioSpectrum.SetBuffers(Value: Integer);
var
  bActive: Boolean;
begin
  if (FBuffers <> Value) and (Value >= 1) and (Value <= 64) then begin
    FBuffers := Value;
    bActive  := FActive;
    if FActive then SetActive(False);
    SetLength(FWaveHeaders, Value);
    if bActive then SetActive(True);
  end;
end;

procedure TAudioSpectrum.SetDataScale(Value: Integer);
begin
  if (Value > 0) and (Value <= 65536) then
    FDataScale := Value;
end;

procedure TAudioSpectrum.SetDataStep(Value: Integer);
begin                    //标准: DATA STEP = 2 , 改为奇数，
                         //则可简单合成两个声道波形为一个波形！
  if (FDataStep <> Value) and (Value >= 1) and (Value <= 64) then
    FDataStep := Value;
end;

procedure TAudioSpectrum.SetErrorMsg(const Value: string);
begin
  //写个空函数,否则设计期ErrorMsg属性不出现
end;

procedure TAudioSpectrum.SetForeColor(Value: TColor);
begin
  if FForeColor <> Value then begin
    FForeColor := Value;
    Paint;
  end;
end;

procedure TAudioSpectrum.SetFreqSpace(Value: Integer);
begin
  if (Value >= 0) and (Value <= 64) then
    FFreqSpace := Value;
end;

procedure TAudioSpectrum.SetFreqWidth(Value: Integer);
begin
  if (Value > 0) and (Value <= 64) then
    FFreqWidth := Value;
end;

procedure TAudioSpectrum.SetMixTime(Value: Integer);
begin
  if (Value >= 0) and (Value <= 64) then
    FMixTime := Value;
end;

procedure TAudioSpectrum.WMEraseBkgnd(var Message: TMessage);
begin
  Message.Result := 1;
end;

end.
