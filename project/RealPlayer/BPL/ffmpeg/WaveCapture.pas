(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * Wave capture interface
 * Created by CodeCoolie@CNSW 2009/11/28 -> $Date:: 2013-11-18 #$
 *)

unit WaveCapture;

interface

{$I CompilerDefines.inc}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  Winapi.Windows,
  System.SysUtils,

  Winapi.MMSystem;
{$ELSE}
  Windows,
  SysUtils,

  MMSystem;
{$ENDIF}

procedure register_wavecapture;

implementation

uses
  libavcodec,
  AVCodecStubs,
  libavformat,
  AVFormatStubs,
  libavutil,
  libavutil_error,
  libavutil_log,
  libavutil_opt,
  libavutil_samplefmt,
  AVUtilStubs,

  FFUtils,
  MyUtils;

const
  WAVE_BUFFER_SIZE = 4096; // $10000; // 64 KB
  AUDIO_BLOCK_SIZE = 4096;

type
  Pwave_grab = ^Twave_grab;
  Twave_grab = record
    class_: PAVClass;
    device: LongWord;                   // index of sound card
    sample_rate: Integer;               // sample rate, set by a private option
    channels: Integer;                  // channels, set by a private option
    sample_format: Integer;             // sample format
    sample_fmt: TAVSampleFormat;
    codec_id: TAVCodecID;
    BufSize: Integer;                   // waveIn buffer size
    frame_size: Integer;

    // for waveIn functions
    WaveFormat: TWaveFormatEx;          // wave format
    WaveHandle: HWAVEIN;                // wave input handle
    _WaveHdr: array[0..1] of TWaveHdr;  // wave Header buffer
    WaveHdr: array[0..1] of PWaveHdr;   // wave Header pointer
    WaveBuf: array[0..1] of PAnsiChar;  // wave buffer
    WaveBufIdx: Integer;                // wave buffer index

    // status
    Started: Integer;
    Stoped: Integer;
    Paused: PInteger;
    mutex: THANDLE;
    event: THANDLE;
    time_start: Int64;

    // statistics
//    DataCount: Integer;

    sample_fmt_str: PAnsiChar;    // set by a private option

    pktl: PAVPacketList;
    s: PAVFormatContext;
  end;

// get waveIn function error message
function waveInGetError(mmrError: MMRESULT): string;
var
  LBuf: array[0..255] of Char;
begin
  FillChar(LBuf[0], SizeOf(LBuf), 0);
  waveInGetErrorText(mmrError, LBuf, SizeOf(LBuf));
  Result := LBuf;
end;

// release resource
procedure ReleaseResource(ctx: Pwave_grab);
var
  I: Integer;
  pktl: PAVPacketList;
begin
  ctx.s := nil;
  ctx.Stoped := 1;

  // close wave device
  if ctx.WaveHandle <> 0 then
  begin
    waveInReset(ctx.WaveHandle);
    waveInClose(ctx.WaveHandle);
    ctx.WaveHandle := 0;
  end;

  // close mutex and event
  if ctx.mutex <> 0 then
  begin
    CloseHandle(ctx.mutex);
    ctx.mutex := 0;
  end;
  if ctx.event <> 0 then
  begin
    CloseHandle(ctx.event);
    ctx.event := 0;
  end;

  // free wave buffer
  for I := Low(ctx.WaveBuf) to High(ctx.WaveBuf) do
  begin
    if Assigned(ctx.WaveBuf[I]) then
    begin
      FreeMem(ctx.WaveBuf[I]);
      ctx.WaveBuf[I] := nil;
    end;
  end;

  // free pktl
  while Assigned(ctx.pktl) do
  begin
    pktl := ctx.pktl;
    ctx.pktl := pktl.next;
    av_free(pktl);
  end;
end;

// queue next wave buffer
function PushNextBuffer(ctx: Pwave_grab): Boolean;
var
  LRet: MMRESULT;
begin
  if ctx.WaveHandle = 0 then
  begin
    av_log(ctx.s, AV_LOG_DEBUG, 'WaveHandle is invalid.'#10);
    Result := False;
    Exit;
  end;

  // add wave buffer
  LRet := waveInAddBuffer(ctx.WaveHandle, ctx.WaveHdr[ctx.WaveBufIdx], SizeOf(TWaveHdr));
  if LRet <> MMSYSERR_NOERROR then
  begin
    av_log(ctx.s, AV_LOG_ERROR, PAnsiChar(AnsiString(waveInGetError(LRet)) + #10));
    ctx.Stoped := 1;
    Result := False;
    Exit;
  end;

  // toggle for next buffer index
  // TODO: support MAX_BUFFER_COUNT
  ctx.WaveBufIdx := 1 - ctx.WaveBufIdx;
  Result := True;
end;

// waveIn callback
procedure waveInCallback(hwi: HWAVEIN; uMsg: UINT;
  dwInstance, dwParam1, dwParam2: DWORD{_PTR}); stdcall;
type
  PPAVPacketList = ^PAVPacketList;
var
  ctx: Pwave_grab;
  LBytes: DWORD;
  ppktl: PPAVPacketList;
  pktl_next: PAVPacketList;
  pts: Int64;
begin
  ctx := Pwave_grab(dwInstance);

  if ctx.Stoped = 1 then
    Exit;

  case uMsg of
    WIM_DATA: // wave data recorded
      begin
        pts := av_gettime - ctx.time_start;
        // bytes recorded
        LBytes := PWaveHdr(dwParam1).dwBytesRecorded;
        if LBytes = 0 then
        begin
          PushNextBuffer(ctx);
          Exit;
        end;

        // skip when not started
        if ctx.Started = 0 then
        begin
          av_log(ctx.s, AV_LOG_DEBUG, 'not started, skip wave data %d bytes'#10, LBytes);
          PushNextBuffer(ctx);
          Exit;
        end;

        // skip when paused
        if Assigned(ctx.Paused) and (ctx.Paused^ <> 0) then
        begin
//          av_log(ctx.s, AV_LOG_DEBUG, 'paused, skip wave data %d bytes'#10, LBytes);
          PushNextBuffer(ctx);
          Exit;
        end;

        // obtain mutex for writing
        WaitForSingleObject(ctx.mutex, INFINITE);
        try
          // create packet list
          pktl_next := av_mallocz(SizeOf(TAVPacketList));
          if not Assigned(pktl_next) then
          begin
            av_log(ctx.s, AV_LOG_ERROR, 'av_mallocz() error'#10);
            ctx.Stoped := 1;
            Exit;
          end;

          // create packet
          if av_new_packet(@pktl_next.pkt, LBytes) < 0 then
          begin
            av_log(ctx.s, AV_LOG_ERROR, 'av_new_packet() error'#10);
            av_free(pktl_next);
            ctx.Stoped := 1;
            Exit;
          end;

          // write wave data
          Move(ctx.WaveBuf[ctx.WaveBufIdx]^, pktl_next.pkt.data^, LBytes);
          pktl_next.pkt.pts := pts;
//          Inc(ctx.DataCount, LBytes);
          //av_log(ctx.s, AV_LOG_DEBUG, 'Wave data %d bytes'#10, LBytes);

          // add packet to list
          ppktl := @ctx.pktl;
          while Assigned(ppktl^) do
            ppktl := @ppktl^.next;
          ppktl^ := pktl_next;
        finally
          SetEvent(ctx.event);
          ReleaseMutex(ctx.mutex);
        end;

        PushNextBuffer(ctx);
      end;
    WIM_OPEN: // <- waveInOpen()
      begin
        av_log(ctx.s, AV_LOG_INFO, 'waveIn device opened.'#10);
      end;
    WIM_CLOSE: // <- waveInClose()
      begin
        av_log(ctx.s, AV_LOG_INFO, 'waveIn device closed.'#10);
        ctx.WaveHandle := 0;
        ctx.Stoped := 1;
      end;
  end;
end;

// init wave device
function InitWaveDevice(ctx: Pwave_grab): Boolean;
var
  I: Integer;
  LBufSize: DWORD;
  LRet: MMRESULT;
begin
  Result := False;

  // find a device compatible with the available wave characteristics
  // TODO: check device index
  if waveInGetNumDevs < 1 then
  begin
    av_log(ctx.s, AV_LOG_ERROR, 'No wave audio recording devices found.'#10);
    Exit;
  end;

// TODO: if waveInGetDevCaps(0, @m_WaveInDevCaps,sizeof(WAVEINCAPS));

  // init wave format structure
  FillChar(ctx.WaveFormat, SizeOf(TWaveFormatEx), 0);
  with ctx.WaveFormat do
  begin
    wFormatTag := WAVE_FORMAT_PCM;
    cbSize := 0;

    nSamplesPerSec := ctx.sample_rate;
    wBitsPerSample := ctx.sample_format;
    nChannels := ctx.channels;

    nBlockAlign := wBitsPerSample * nChannels div 8;
    if nBlockAlign = 0 then
      nBlockAlign := 1;
    nAvgBytesPerSec := nSamplesPerSec * nBlockAlign;
  end;

  // init wave header
  for I := Low(ctx.WaveHdr) to High(ctx.WaveHdr) do
  begin
    ctx.WaveHdr[I] := @ctx._WaveHdr[I];
    FillChar(ctx.WaveHdr[I]^, SizeOf(TWaveHdr), 0);
  end;

  // make the wave buffer size a multiple of the block align
  LBufSize := ctx.BufSize - (ctx.BufSize mod ctx.WaveFormat.nBlockAlign);
  // allocate the wave data buffer memory
  for I := Low(ctx.WaveBuf) to High(ctx.WaveBuf) do
  begin
    GetMem(ctx.WaveBuf[I], LBufSize);
    if ctx.WaveBuf[I] = nil then
    begin
      av_log(ctx.s, AV_LOG_ERROR, 'Error allocating wave buffer memory.'#10);
      Exit;
    end;
    FillChar(ctx.WaveBuf[I]^, LBufSize, 0);
    // assign wave buffer with wave header
    ctx.WaveHdr[I].dwBufferLength := LBufSize;
    ctx.WaveHdr[I].lpData := ctx.WaveBuf[I];
  end;

  // query the device for recording format
  LRet := waveInOpen(nil, ctx.device, @ctx.WaveFormat, 0, 0, WAVE_FORMAT_QUERY);
  if LRet <> MMSYSERR_NOERROR then
  begin
    av_log(ctx.s, AV_LOG_ERROR, PAnsiChar(AnsiString(waveInGetError(LRet)) + #10));
    Exit;
  end;

  // open the device
  LRet := waveInOpen(@ctx.WaveHandle, ctx.device, @ctx.WaveFormat,
                     DWORD(@waveInCallback), DWORD(ctx), CALLBACK_FUNCTION or {WAVE_FORMAT_DIRECT}8);
  if LRet <> MMSYSERR_NOERROR then
  begin
    av_log(ctx.s, AV_LOG_ERROR, PAnsiChar(AnsiString(waveInGetError(LRet)) + #10));
    Exit;
  end;

  // prepare wave header
  if (waveInPrepareHeader(ctx.WaveHandle, ctx.WaveHdr[0], SizeOf(TWaveHdr)) <> MMSYSERR_NOERROR) or
    (waveInPrepareHeader(ctx.WaveHandle, ctx.WaveHdr[1], SizeOf(TWaveHdr)) <> MMSYSERR_NOERROR) then
  begin
    av_log(ctx.s, AV_LOG_ERROR, PAnsiChar(AnsiString(waveInGetError(LRet)) + #10));
    Exit;
  end;

  // first wave buffer index
  ctx.WaveBufIdx := 0;

  // add the first buffer
  if not PushNextBuffer(ctx) then
    Exit;

  // start recording to first buffer
  LRet := waveInStart(ctx.WaveHandle);
  if LRet <> MMSYSERR_NOERROR then
  begin
    av_log(ctx.s, AV_LOG_ERROR, PAnsiChar(AnsiString(waveInGetError(LRet)) + #10));
    Exit;
  end;

  // queue the next buffer
  if not PushNextBuffer(ctx)  then
    Exit;

  Result := True;
end;

// wave grab demuxer read_header API
function wave_grab_read_header(s: PAVFormatContext): Integer; cdecl;
var
  ctx: Pwave_grab;
  st: PAVStream;
begin
  ctx := s.priv_data;
  ctx.s := s;
  ctx.frame_size := AUDIO_BLOCK_SIZE;

  try
    // filename is the device identifier, default WAVE_MAPPER(-1)
    ctx.device := StrToInt(string(s.filename));
  except
    av_log(s, AV_LOG_ERROR, 'Invalid device identifier: "%s"'#10, s.filename);
    Result := AVERROR_EINVAL;
    Exit;
  end;

  // sample format, u8 or s16
  if Assigned(ctx.sample_fmt_str) and (ctx.sample_fmt_str <> '') then
  begin
    ctx.sample_fmt := av_get_sample_fmt(ctx.sample_fmt_str);
    if ctx.sample_fmt = AV_SAMPLE_FMT_U8 then
    begin
      ctx.sample_format := 8;
      ctx.codec_id := AV_CODEC_ID_PCM_U8;
    end
    else if ctx.sample_fmt = AV_SAMPLE_FMT_S16 then
    begin
      ctx.sample_format := 16;
      ctx.codec_id := AV_CODEC_ID_PCM_S16LE;
    end
    else
    begin
      av_log(s, AV_LOG_ERROR, 'Invalid sample format: "%s", it should be u8 or s16'#10, ctx.sample_fmt_str);
      Result := AVERROR_EINVAL;
      Exit;
    end;
  end
  else
  begin
    ctx.sample_fmt := AV_SAMPLE_FMT_S16;
    ctx.sample_format := 16;
    ctx.codec_id := AV_CODEC_ID_PCM_S16LE;
  end;

  // chck buffer size
  if ctx.BufSize <= 0 then
    ctx.BufSize := WAVE_BUFFER_SIZE;

  // check sample rate
  if ctx.sample_rate <= 0 then
  begin
    av_log(s, AV_LOG_ERROR, 'Invalid sample rate %d'#10, ctx.sample_rate);
    Result := AVERROR_EINVAL;
    Exit;
  end;

  // check channels
  if ctx.channels <= 0 then
  begin
    av_log(s, AV_LOG_ERROR, 'Invalid channels %d'#10, ctx.channels);
    Result := AVERROR_EINVAL;
    Exit;
  end;

  // create mutex
  ctx.mutex := CreateMutex(nil, False, nil);
  if ctx.mutex = 0 then
  begin
    av_log(s, AV_LOG_ERROR, 'Could not create Mutex.'#10);
    ReleaseResource(ctx);
    Result := AVERROR_EIO;
    Exit;
  end;

  // create event
  ctx.event := CreateEvent(nil, True, False, nil);
  if ctx.event = 0 then
  begin
    av_log(s, AV_LOG_ERROR, 'Could not create Event.'#10);
    ReleaseResource(ctx);
    Result := AVERROR_EIO;
    Exit;
  end;

  // init wave device
  if not InitWaveDevice(ctx) then
  begin
    ReleaseResource(ctx);
    Result := AVERROR_EIO;
    Exit;
  end;

  // new stream
  st := avformat_new_stream(s, nil);
  if st = nil then
  begin
    av_log(s, AV_LOG_ERROR, 'Cannot add stream.'#10);
    ReleaseResource(ctx);
    Result := AVERROR_ENOMEM;
    Exit;
  end;

  (* take real parameters *)
  st.codec.codec_type   := AVMEDIA_TYPE_AUDIO;
  st.codec.codec_id     := ctx.codec_id;
  st.codec.channels     := ctx.channels;
  st.codec.sample_rate  := ctx.sample_rate;
  st.codec.block_align  := ctx.WaveFormat.nBlockAlign;
  st.codec.sample_fmt   := ctx.sample_fmt;
  st.codec.bit_rate     := ctx.sample_rate * ctx.channels * ctx.sample_format;
  st.codec.frame_size   := ctx.frame_size;
  st.codec.bits_per_coded_sample := ctx.sample_format;
  st.codec.thread_count := 1; // avoid multithreading issue of log callback

  // !!! to avoid av_find_stream_info() to read packets
  // condition 1
//  st.r_frame_rate.num := ctx.time_base.den;
//  st.r_frame_rate.den := ctx.time_base.num;
//  st.avg_frame_rate.num := ctx.time_base.den;
//  st.avg_frame_rate.den := ctx.time_base.num;
  // condition 2
  s.flags := s.flags or AVFMT_FLAG_NOPARSE;
  // condition 3
  st.first_dts := 0;
  // condition ALL
  s.probesize := 0;

//  av_set_pts_info(st, 64, 1, ctx.sample_rate);
  av_set_pts_info(st, 64, 1, 1000000); (* 64 bits pts in us *)

  av_log(s, AV_LOG_INFO, 'ready for recording...'#10);

  Result := 0;
end;

// wave grab demuxer read_packet API
function wave_grab_read_packet(s: PAVFormatContext; pkt: PAVPacket): Integer; cdecl;
var
  ctx: Pwave_grab;
  pktl: PAVPacketList;
begin
  ctx := s.priv_data;

  // TODO: could we miss one wave buffer?
  if ctx.Started = 0 then
  begin
    ctx.Started := 1;
    ctx.time_start := av_gettime;
  end;

  if ctx.Stoped = 1 then
  begin
    Result := AVERROR_EOF;
    Exit;
  end;

  pktl := nil;
  while not Assigned(pktl) do
  begin
    // obtain mutex for reading
    WaitForSingleObject(ctx.mutex, INFINITE);
    pktl := ctx.pktl;
    if Assigned(pktl) then
    begin
      pkt^ := pktl.pkt;
      ctx.pktl := pktl.next;
      av_free(pktl);
    end;
    ResetEvent(ctx.event);
    ReleaseMutex(ctx.mutex);

    // wait for packet incoming
    if not Assigned(pktl) then
    begin
      if (s.flags and AVFMT_FLAG_NONBLOCK) <> 0 then
      begin
        av_log(ctx.s, AV_LOG_DEBUG, 'non-block, need read again'#10);
        Result := AVERROR_EAGAIN;
        Exit;
      end
      else
      begin
        //WaitForSingleObject(ctx.event, INFINITE);
        if WaitForSingleObject(ctx.event, 1000) <> WAIT_OBJECT_0 then
        begin
          av_log(ctx.s, AV_LOG_DEBUG, 'wait timeout, need read again'#10);
          Result := AVERROR_EAGAIN;
          Exit;
        end;

        if ctx.Stoped = 1 then
        begin
          Result := AVERROR_EOF;
          Exit;
        end;
      end;
    end;
  end;

  Result := pkt.size;
end;

// wave grab demuxer read_close API
function wave_grab_read_close(s: PAVFormatContext): Integer; cdecl;
var
  ctx: Pwave_grab;
begin
  ctx := s.priv_data;
  ReleaseResource(ctx);
  Result := 0;
end;

var
  options: array[0..5] of TAVOption = (
    (name       : 'sample_rate';
     help       : 'set audio sampling rate (in Hz)';
     offset     : -1;
     ttype      : AV_OPT_TYPE_INT;
     default_val: (i64: 44100);
     min        : 0;
     max        : MaxInt;
     flags      : AV_OPT_FLAG_DECODING_PARAM),
    (name       : 'channels';
     help       : 'set number of audio channels';
     offset     : -1;
     ttype      : AV_OPT_TYPE_INT;
     default_val: (i64: 2);
     min        : 0;
     max        : MaxInt;
     flags      : AV_OPT_FLAG_DECODING_PARAM),
    (name       : 'sample_fmt';
     help       : 'set sample format';
     offset     : -1;
     ttype      : AV_OPT_TYPE_STRING;
     default_val: (str: 's16');
     min        : 0;
     max        : 0;
     flags      : AV_OPT_FLAG_DECODING_PARAM),
    (name       : 'bufsize';
     help       : 'waveIn buffer size';
     offset     : -1;
     ttype      : AV_OPT_TYPE_INT;
     default_val: (i64: WAVE_BUFFER_SIZE);
     min        : 0;
     max        : MaxInt;
     flags      : AV_OPT_FLAG_DECODING_PARAM),
    (name       : 'pause_pointer';
     help       : 'integer value of pause flag pointer';
     offset     : -1;
     ttype      : AV_OPT_TYPE_INT;
     default_val: (i64: 0);
     min        : Low(Integer);
     max        : MaxInt;
     flags      : AV_OPT_FLAG_DECODING_PARAM),
    (name       : nil;)
  );

  wave_capture_class: TAVClass = (
    class_name: 'WaveCaptureFormat';
    //item_name : av_default_item_name;
    option    : @options[0];
    version   : LIBAVUTIL_VERSION_INT;
  );

  wave_capture_demuxer: TAVInputFormat = (
    name: 'wavecapture';
    long_name: 'Wave capture using waveIn functions';
    flags: AVFMT_NOFILE;
    priv_class: @wave_capture_class;
    priv_data_size: SizeOf(Twave_grab);
    read_header: wave_grab_read_header;
    read_packet: wave_grab_read_packet;
    read_close: wave_grab_read_close;
  );

procedure register_wavecapture;
var
  ctx: Twave_grab;
begin
  Assert(Assigned(av_default_item_name));
  wave_capture_class.item_name := av_default_item_name;
  options[0].offset := Integer(@ctx.sample_rate) - Integer(@ctx);
  options[1].offset := Integer(@ctx.channels) - Integer(@ctx);
  options[2].offset := Integer(@ctx.sample_fmt_str) - Integer(@ctx);
  options[3].offset := Integer(@ctx.bufsize) - Integer(@ctx);
  options[4].offset := Integer(@ctx.Paused) - Integer(@ctx);
  RegisterInputFormat(@wave_capture_demuxer);
end;

end.
