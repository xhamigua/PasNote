(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * wave output interface
 * Created by CodeCoolie@CNSW 2010/07/16 -> $Date:: 2013-11-18 #$
 *)

unit WaveOutput;

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
  libavformat,
  libavutil_error,
  libavutil_log,
  libavutil_samplefmt,
  AVUtilStubs,

  FFBaseComponent,
  FFUtils,
  MyUtils;

type
  POutputWaveInfo = ^TOutputWaveInfo;
  TOutputWaveInfo = record
    FormatContext: PAVFormatContext;
    SampleRate: Integer;
    SampleFormat: TAVSampleFormat;
    Channels: Integer;
    CodecID: TAVCodecID;
    BitsPerSample: Integer;
    BlockAlign: Integer;
    BitRate: Integer;
    FrameNumber: Integer;
    Packet: PAVPacket;
  end;

  TWriteWaveEvent = procedure(Sender: TObject; AWaveInfo: POutputWaveInfo) of object;

  TWaveOutputAdapter = class(TFFBaseComponent)
  private
    FData: Pointer;
    FWaveInfo: POutputWaveInfo;
    FOnWriteHeader: TNotifyEvent;
    FOnWriteWave: TWriteWaveEvent;
    FOnWriteClose: TNotifyEvent;
  protected
    procedure WriteHeader;
    procedure WriteWave(AWaveInfo: POutputWaveInfo);
    procedure WriteClose;
  public
    destructor Destroy; override;
    property UserData: Pointer read FData write FData;
    property WaveInfo: POutputWaveInfo read FWaveInfo;
  published
    property OnWriteHeader: TNotifyEvent read FOnWriteHeader write FOnWriteHeader;
    property OnWriteWave: TWriteWaveEvent read FOnWriteWave write FOnWriteWave;
    property OnWriteClose: TNotifyEvent read FOnWriteClose write FOnWriteClose;
  end;

procedure register_waveoutput;

implementation

{ TWaveOutputAdapter }

destructor TWaveOutputAdapter.Destroy;
begin
  FOnWriteHeader := nil;
  FOnWriteWave := nil;
  FOnWriteClose := nil;
  inherited Destroy;
end;

procedure TWaveOutputAdapter.WriteHeader;
begin
  if Assigned(FOnWriteHeader) then
    FOnWriteHeader(Self);
end;

procedure TWaveOutputAdapter.WriteWave(AWaveInfo: POutputWaveInfo);
begin
  if Assigned(FOnWriteWave) then
    FOnWriteWave(Self, AWaveInfo);
end;

procedure TWaveOutputAdapter.WriteClose;
begin
  if Assigned(FOnWriteClose) then
    FOnWriteClose(Self);
end;

type
  Pwave_output = ^Twave_output;
  Twave_output = record
    s: PAVFormatContext;
    sample_rate: Integer;       // samples per second
    sample_fmt: TAVSampleFormat;  // audio sample format
    channels: Integer;
    codec_id: TAVCodecID;
    bits_per_coded_sample: Integer; // bits per sample from the demuxer
    block_align: Integer;       // number of bytes per packet if constant and known or 0
    bit_rate: Integer;

    frame_number: Integer;
    pkt: PAVPacket;

    adapter: TWaveOutputAdapter;  // wave output adapter
  end;

function raw_write_header(s: PAVFormatContext): Integer; cdecl;
var
  ctx: Pwave_output;
begin
  ctx := s.priv_data;

  // WaveOutputAdapter
  try
    ctx.adapter := TWaveOutputAdapter(StrToInt(string(s.filename)));
  except on E: Exception do
    begin
      av_log(s, AV_LOG_ERROR, 'Could not parse WaveOutputAdapter: "%s", ' +
        'it should be address of WaveOutputAdapter'#10, s.filename);
      Result := AVERROR_EINVAL;
      Exit;
    end;
  end;
  if not Assigned(ctx.adapter) then
  begin
    av_log(s, AV_LOG_ERROR, 'Invalid WaveOutputAdapter'#10);
    Result := AVERROR_EINVAL;
    Exit;
  end;

  ctx.s := s;
  with PPtrIdx(s.streams, 0)^.codec^ do
  begin
    ctx.sample_rate := sample_rate;
    ctx.sample_fmt := sample_fmt;
    ctx.channels := channels;
    ctx.codec_id := codec_id;
    ctx.bits_per_coded_sample := bits_per_coded_sample;
    ctx.block_align := block_align;
    ctx.bit_rate := bit_rate;
  end;

  // notify write header
  ctx.adapter.FWaveInfo := POutputWaveInfo(ctx);
  ctx.adapter.WriteHeader;

  Result := 0;
end;

function raw_write_packet(s: PAVFormatContext; pkt: PAVPacket): Integer; cdecl;
var
  ctx: Pwave_output;
begin
  ctx := s.priv_data;
  Inc(ctx.frame_number);
  ctx.pkt := pkt;
  ctx.adapter.WriteWave(POutputWaveInfo(ctx));
  Result := 0;
end;

function raw_write_trailer(s: PAVFormatContext): Integer; cdecl;
var
  ctx: Pwave_output;
begin
  ctx := s.priv_data;
  ctx.adapter.WriteClose;
  Result := 0;
end;

var
  waveoutput_muxer: TAVOutputFormat = (
    name: 'waveoutput';
    long_name: 'Wave output';
    mime_type: nil;
    extensions: 'wav';
    audio_codec: AV_CODEC_ID_PCM_S16LE;
    video_codec: AV_CODEC_ID_NONE;
    flags: AVFMT_NOFILE or AVFMT_NOTIMESTAMPS;
    priv_data_size: SizeOf(Twave_output);
    write_header: raw_write_header;
    write_packet: raw_write_packet;
    write_trailer: raw_write_trailer;
  );

procedure register_waveoutput;
begin
  RegisterOutputFormat(@waveoutput_muxer);
end;

end.
