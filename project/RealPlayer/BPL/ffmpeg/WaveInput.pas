(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * wave input interface
 * Created by CodeCoolie@CNSW 2010/07/15 -> $Date:: 2013-11-18 #$
 *)

unit WaveInput;

interface

{$I CompilerDefines.inc}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  System.SysUtils,
  System.Classes,
{$ELSE}
  SysUtils,
  Classes,
{$ENDIF}

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

  FFBaseComponent,
  FFUtils,
  MyUtils;

type
  PInputWaveInfo = ^TInputWaveInfo;
  TInputWaveInfo = record
    TimeStamp: Int64;
    FrameNumber: Integer;
    FrameSize: Integer;
    TotalSize: Int64;
    SampleRate: Integer;
    SampleFormat: Integer;
    Channels: Integer;
  end;

  TReadWaveDataEvent = function(Sender: TObject; AData: Pointer;
    AWaveInfo: PInputWaveInfo): Integer of object;

  TWaveInputAdapter = class(TFFBaseComponent)
  private
    FData: Pointer;
    FWaveInfo: PInputWaveInfo;
    FOnReadHeader: TNotifyEvent;
    FOnReadClose: TNotifyEvent;
    FOnReadWaveData: TReadWaveDataEvent;
  protected
    procedure ReadHeader;
    procedure ReadClose;
    function ReadWaveData(AData: Pointer; AWaveInfo: PInputWaveInfo): Integer;
  public
    destructor Destroy; override;
    property UserData: Pointer read FData write FData;
    property WaveInfo: PInputWaveInfo read FWaveInfo;
  published
    property OnReadHeader: TNotifyEvent read FOnReadHeader write FOnReadHeader;
    property OnReadClose: TNotifyEvent read FOnReadClose write FOnReadClose;
    property OnReadWaveData: TReadWaveDataEvent read FOnReadWaveData write FOnReadWaveData;
  end;

procedure register_waveinput;

implementation

const
  RAW_SAMPLES = 1024;

type
  Pwave_input = ^Twave_input;
  Twave_input = record
    class_: PAVClass;
    pts: Int64;             // timestamp
    frame_number: Integer;  // current frame number
    frame_size: Integer;    // size in bytes of the frame
    total_size: Int64;      // current total size in bytes

    sample_rate: Integer;   // samples per second
    sample_format: Integer; // sample format
    channels: Integer;      // number of audio channels

    codec_id: TAVCodecID;     // codec id
    sample_fmt: TAVSampleFormat; // internal sample format

    sample_fmt_str: PAnsiChar;    // set by a private option

    adapter: TWaveInputAdapter;   // wave input adapter
  end;

{ TWaveInputAdapter }

destructor TWaveInputAdapter.Destroy;
begin
  FOnReadHeader := nil;
  FOnReadClose := nil;
  FOnReadWaveData := nil;
  inherited Destroy;
end;

procedure TWaveInputAdapter.ReadHeader;
begin
  if Assigned(FOnReadHeader) then
    FOnReadHeader(Self);
end;

procedure TWaveInputAdapter.ReadClose;
begin
  if Assigned(FOnReadClose) then
    FOnReadClose(Self);
end;

function TWaveInputAdapter.ReadWaveData(AData: Pointer;
  AWaveInfo: PInputWaveInfo): Integer;
begin
  if Assigned(FOnReadWaveData) then
    Result := FOnReadWaveData(Self, AData, AWaveInfo)
  else
    Result := -1;
end;

function waveinput_read_header(s: PAVFormatContext): Integer; cdecl;
var
  ctx: Pwave_input;
  st: PAVStream;
begin
  ctx := s.priv_data;

  // WaveInputAdapter
  try
    ctx.adapter := TWaveInputAdapter(StrToInt(string(s.filename)));
  except on E: Exception do
    begin
      av_log(s, AV_LOG_ERROR, 'Could not parse WaveInputAdapter: "%s", ' +
        'it should be address of WaveInputAdapter'#10, s.filename);
      Result := AVERROR_EINVAL;
      Exit;
    end;
  end;
  if not Assigned(ctx.adapter) then
  begin
    av_log(s, AV_LOG_ERROR, 'Invalid WaveInputAdapter'#10);
    Result := AVERROR_EINVAL;
    Exit;
  end;

  // sample format, u8, s16 or s32
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
    else if ctx.sample_fmt = AV_SAMPLE_FMT_S32 then
    begin
      ctx.sample_format := 32;
      ctx.codec_id := AV_CODEC_ID_PCM_S32LE;
    end
    else
    begin
      av_log(s, AV_LOG_ERROR, 'Invalid sample format: "%s", it should be u8, s16 or s32'#10, ctx.sample_fmt_str);
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

  // create stream
  st := avformat_new_stream(s, nil);
  if st = nil then
  begin
    Result := AVERROR_ENOMEM;
    Exit;
  end;

  with st.codec^ do
  begin
    codec_type  := AVMEDIA_TYPE_AUDIO;
    codec_id    := ctx.codec_id;
    sample_fmt  := ctx.sample_fmt;
    sample_rate := ctx.sample_rate;
    channels    := ctx.channels;
    bits_per_coded_sample := av_get_bits_per_sample(codec_id);
    Assert(bits_per_coded_sample > 0);
    Assert(bits_per_coded_sample = ctx.sample_format);
    block_align := bits_per_coded_sample * channels div 8;
    if block_align = 0 then
      block_align := 1;
    bit_rate     := ctx.sample_rate * ctx.channels * ctx.sample_format;
    ctx.frame_size := RAW_SAMPLES * block_align;
    frame_size   := ctx.frame_size;
    thread_count := 1; // avoid multithreading issue of log callback
    //av_set_pts_info(st, 64, 1, sample_rate);
    av_set_pts_info(st, 64, 1, 1000000);
  end;

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

  // notify read header
  ctx.adapter.FWaveInfo := PInputWaveInfo(@ctx.pts);
  ctx.adapter.ReadHeader;

  Result := 0;
end;

(* Read one packet and put it in 'pkt'. pts and flags are also
   set. 'av_new_stream' can be called only if the flag
   AVFMTCTX_NOHEADER is used. *)
function waveinput_read_packet(s: PAVFormatContext; pkt: PAVPacket): Integer; cdecl;
var
  ctx: Pwave_input;
begin
  ctx := s.priv_data;

  // malloc packet
  if av_new_packet(pkt, ctx.frame_size) < 0 then
  begin
    Result := AVERROR_ENOMEM;
    Exit;
  end;

  // increase frame number
  Inc(ctx.frame_number);

  // calculate pts
  //ctx.pts := ctx.total_size * 8 div (ctx.sample_format * ctx.channels);
  ctx.pts := (AV_TIME_BASE div (ctx.sample_format div 8) * ctx.total_size) div (ctx.sample_rate * ctx.channels);
  pkt.pts := ctx.pts;
  pkt.dts := ctx.pts;
  pkt.stream_index := 0;

  // read frame
  Result := ctx.adapter.ReadWaveData(pkt.data, PInputWaveInfo(@ctx.pts));

  if Result < 0 then
  begin
    av_log(s, AV_LOG_INFO, 'reading wave data return %d'#10, Result);
    av_free_packet(pkt);
    Exit;
  end;

  Assert(Result <= ctx.frame_size);

  Inc(ctx.total_size, Result);
  pkt.size := Result;
end;

(* Close the stream. The AVFormatContext and AVStreams are not
   freed by this function *)
function waveinput_read_close(s: PAVFormatContext): Integer; cdecl;
var
  ctx: Pwave_input;
begin
  ctx := s.priv_data;

  // notify read close
  ctx.adapter.ReadClose;

  Result := 0;
end;

var
  options: array[0..3] of TAVOption = (
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
    (name       : nil;)
  );

  wave_input_class: TAVClass = (
    class_name: 'WaveInputFormat';
    //item_name : av_default_item_name;
    option    : @options[0];
    version   : LIBAVUTIL_VERSION_INT;
  );

  waveinput_demuxer: TAVInputFormat = (
    name: 'waveinput';
    long_name: 'Wave input';
    flags: AVFMT_NOFILE;
    priv_class: @wave_input_class;
    priv_data_size: SizeOf(Twave_input);
    read_header: waveinput_read_header;
    read_packet: waveinput_read_packet;
    read_close: waveinput_read_close;
  );

procedure register_waveinput;
var
  ctx: Twave_input;
begin
  Assert(Assigned(av_default_item_name));
  wave_input_class.item_name := av_default_item_name;
  options[0].offset := Integer(@ctx.sample_rate) - Integer(@ctx);
  options[1].offset := Integer(@ctx.channels) - Integer(@ctx);
  options[2].offset := Integer(@ctx.sample_fmt_str) - Integer(@ctx);
  RegisterInputFormat(@waveinput_demuxer);
end;

end.
