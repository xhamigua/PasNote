(*
 * ffmpeg option parsing
 *
 * This file is part of FFmpeg.
 *
 * FFmpeg is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * FFmpeg is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with FFmpeg; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 *)

(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * Original file: ffmpeg_opt.c
 * Ported by CodeCoolie@CNSW 2012/11/06 -> $Date:: 2013-12-24 #$
 *)

unit FFmpegOpt;

interface

{$I CompilerDefines.inc}

{$I _LicenseDefines.inc}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  {$IFDEF MSWINDOWS}
    Winapi.Windows,
  {$ENDIF}
  {$IFDEF POSIX}
    Posix.Unistd, // DeleteFile -> unlink
    Posix.Time,
    Posix.SysTypes,
  {$ENDIF}
  System.SysUtils,
  {$IFDEF VCL_XE4_OR_ABOVE}
    System.AnsiStrings, // StrLen
  {$ENDIF}
  System.Classes,
{$ELSE}
  Windows,
  SysUtils,
  Classes,
{$ENDIF}

{$IFDEF BCB}
  BCBTypes,
{$ENDIF}

{$IFDEF USES_LICKEY}
  LicenseKey,
{$ENDIF}

  libavcodec,
  AVCodecStubs,
  libavfilter,
  AVFilterStubs,
  libavformat,
  libavformat_avio,
  AVFormatStubs,
  libavutil,
  libavutil_dict,
  libavutil_error,
  libavutil_frame,
  libavutil_log,
  libavutil_opt,
  libavutil_pixdesc,
  libavutil_pixfmt,
  libavutil_rational,
  libavutil_samplefmt,
  AVUtilStubs,
  libswresample,
  libswscale,

  MyUtils,
  MyUtilStubs,

  UnicodeProtocol,
  FFBaseComponent,
  FFUtils;

{$I libversion.inc}

const
(****** from ffmpeg.h **************)
  VSYNC_AUTO        = -1;
  VSYNC_PASSTHROUGH = 0;
  VSYNC_CFR         = 1;
  VSYNC_VFR         = 2;
  VSYNC_VSCFR       = $FE;
  VSYNC_DROP        = $FF;

  MAX_STREAMS       = 1024; (* arbitrary sanity check value *)

type
  (* select an input stream for an output stream *)
  PStreamMap = ^TStreamMap;
  TStreamMap = record
    disabled: Integer;            (* 1 is this mapping is disabled by a negative map *)
    file_index: Integer;
    stream_index: Integer;
    sync_file_index: Integer;
    sync_stream_index: Integer;
    linklabel: PAnsiChar;         (* name of an output link, for mapping lavfi outputs *)
  end;

  PAudioChannelMap = ^TAudioChannelMap;
  TAudioChannelMap = record
    file_idx, stream_idx, channel_idx: Integer; // input
    ofile_idx, ostream_idx: Integer;            // output
  end;

  POptionsContext = ^TOptionsContext;
  TOptionsContext = record
    g: POptionGroup;

    (* input/output options *)
    start_time: Int64;
    format: PAnsiChar;

    codec_names: PSpecifierOpt;
    nb_codec_names: Integer;
    audio_channels: PSpecifierOpt;
    nb_audio_channels: Integer;
    audio_sample_rate: PSpecifierOpt;
    nb_audio_sample_rate: Integer;
    frame_rates: PSpecifierOpt;
    nb_frame_rates: Integer;
    frame_sizes: PSpecifierOpt;
    nb_frame_sizes: Integer;
    frame_pix_fmts: PSpecifierOpt;
    nb_frame_pix_fmts: Integer;

    (* input options *)
    input_ts_offset: Int64;
    rate_emu: Integer;
    accurate_seek: Integer;

    ts_scale: PSpecifierOpt;
    nb_ts_scale: Integer;
    dump_attachment: PSpecifierOpt;
    nb_dump_attachment: Integer;

    (* output options *)
    stream_maps: PStreamMap;
    nb_stream_maps: Integer;
    audio_channel_maps: PAudioChannelMap; (* one info entry per -map_channel *)
    nb_audio_channel_maps: Integer;       (* number of (valid) -map_channel settings *)
    metadata_global_manual: Integer;
    metadata_streams_manual: Integer;
    metadata_chapters_manual: Integer;
    attachments: PPAnsiChar;
    nb_attachments: Integer;

    chapters_input_file: Integer;

    recording_time: Int64;
    stop_time: Int64;
    limit_filesize: Int64;
    mux_preload: Single;
    mux_max_delay: Single;
    shortest: Integer;

    video_disable: Integer;
    audio_disable: Integer;
    subtitle_disable: Integer;
    data_disable: Integer;

    (* indexed by output file stream index *)
    streamid_map: PInteger;
    nb_streamid_map: Integer;

    metadata: PSpecifierOpt;
    nb_metadata: Integer;
    max_frames: PSpecifierOpt;
    nb_max_frames: Integer;
    bitstream_filters: PSpecifierOpt;
    nb_bitstream_filters: Integer;
    codec_tags: PSpecifierOpt;
    nb_codec_tags: Integer;
    sample_fmts: PSpecifierOpt;
    nb_sample_fmts: Integer;
    qscale: PSpecifierOpt;
    nb_qscale: Integer;
    forced_key_frames: PSpecifierOpt;
    nb_forced_key_frames: Integer;
    force_fps: PSpecifierOpt;
    nb_force_fps: Integer;
    frame_aspect_ratios: PSpecifierOpt;
    nb_frame_aspect_ratios: Integer;
    rc_overrides: PSpecifierOpt;
    nb_rc_overrides: Integer;
    intra_matrices: PSpecifierOpt;
    nb_intra_matrices: Integer;
    inter_matrices: PSpecifierOpt;
    nb_inter_matrices: Integer;
    top_field_first: PSpecifierOpt;
    nb_top_field_first: Integer;
    metadata_map: PSpecifierOpt;
    nb_metadata_map: Integer;
    // TODO: presets support
//    presets: PSpecifierOpt;
//    nb_presets: Integer;
    copy_initial_nonkeyframes: PSpecifierOpt;
    nb_copy_initial_nonkeyframes: Integer;
    copy_prior_start: PSpecifierOpt;
    nb_copy_prior_start: Integer;
    filters: PSpecifierOpt;
    nb_filters: Integer;
    filter_scripts: PSpecifierOpt;
    nb_filter_scripts: Integer;
    reinit_filters: PSpecifierOpt;
    nb_reinit_filters: Integer;
    fix_sub_duration: PSpecifierOpt;
    nb_fix_sub_duration: Integer;
    canvas_sizes: PSpecifierOpt;
    nb_canvas_sizes: Integer;
    pass: PSpecifierOpt;
    nb_pass: Integer;
    passlogfiles: PSpecifierOpt;
    nb_passlogfiles: Integer;
    guess_layout_max: PSpecifierOpt;
    nb_guess_layout_max: Integer;
    apad: PSpecifierOpt;
    nb_apad: Integer;
  end;

  PPFilterGraph = ^PFilterGraph;
  PFilterGraph = ^TFilterGraph;
  PPInputStream = ^PInputStream;
  PInputStream = ^TInputStream;
  PPInputFilter = ^PInputFilter;
  PInputFilter = ^TInputFilter;
  TInputFilter = record
    filter: PAVFilterContext;
    ist: PInputStream;
    graph: PFilterGraph;
    name: PByte;
  end;

  PPOutputStream = ^POutputStream;
  POutputStream = ^TOutputStream;
  PPOutputFilter = ^POutputFilter;
  POutputFilter = ^TOutputFilter;
  TOutputFilter = record
    filter: PAVFilterContext;
    ost: POutputStream;
    graph: PFilterGraph;
    name: PByte;

    (* temporary storage until stream maps are processed *)
    out_tmp: PAVFilterInOut;
  end;

  TFilterGraph = record
    index: Integer;
    graph_desc: PAnsiChar;

    graph: PAVFilterGraph;
    reconfiguration: Integer;

    inputs: PPInputFilter;
    nb_inputs: Integer;
    outputs: PPOutputFilter;
    nb_outputs: Integer;
  end;

  TISprev_sub = record (* previous decoded subtitle and related variables *)
    got_output: Integer;
    ret: Integer;
    subtitle: TAVSubtitle;
  end;

  TISsub2video = record
    last_pts: Int64;
    end_pts: Int64;
    frame: PAVFrame;
    w, h: Integer;
  end;

  TInputStream = record
    file_index: Integer;
    st: PAVStream;
    discard: Integer;               (* true if stream data should be discarded *)
    decoding_needed: Integer;       (* true if the packets must be decoded in 'raw_fifo' *)
    avdec: PAVCodec;
    decoded_frame: PAVFrame;
    filter_frame: PAVFrame;         (* a ref of decoded_frame, to be sent to filters *)

    start: Int64;                   (* time when read started *)
    (* predicted dts of the next packet read for this stream or (when there are
     * several frames in a packet) of the next frame in current packet (in AV_TIME_BASE units) *)
    next_dts: Int64;
    dts: Int64;                     ///< dts of the last packet read for this stream (in AV_TIME_BASE units)

    next_pts: Int64;                ///< synthetic pts for the next decode frame (in AV_TIME_BASE units)
    pts: Int64;                     ///< current pts of the decoded frame  (in AV_TIME_BASE units)
    wrap_correction_done: Integer;

    filter_in_rescale_delta_last: Int64;

    ts_scale: Double;
    is_start: Integer;              (* is 1 at the start and after a discontinuity *)
    saw_first_ts: Integer;
    showed_multi_packet_warning: Integer;
    opts: PAVDictionary;
    framerate: TAVRational;         (* framerate forced with -r *)
    top_field_first: Integer;
    guess_layout_max: Integer;

    resample_height: Integer;
    resample_width: Integer;
    resample_pix_fmt: Integer;

    resample_sample_fmt: Integer;
    resample_sample_rate: Integer;
    resample_channels: Integer;
    resample_channel_layout: Int64;

    fix_sub_duration: Integer;
    prev_sub: TISprev_sub;

    sub2video: TISsub2video;

    dr1: Integer;

    (* decoded data from this stream goes into all those filters
     * currently video and audio only *)
    filters: PPInputFilter;
    nb_filters: Integer;

    reinit_filters: Integer;

    // hack
    frame_number: Integer;          // input frame number
    decoder_flushed: Integer;       // used for join mode
    decoder_closed: Integer;        // used for join mode
    stream_freed: Integer;          // used for join mode
    join_used: Integer;             // used for join mode
  end;

  PPInputFile = ^PInputFile;
  PInputFile = ^TInputFile;
  TInputFile = record
    ctx: PAVFormatContext;
    eof_reached: Integer;           (* true if eof reached *)
    eagain: Integer;                (* true if last read attempt returned EAGAIN *)
    ist_index: Integer;             (* index of first stream in input_streams *)
    input_ts_offset: Int64;
    ts_offset: Int64;
    last_ts: Int64;
    start_time: Int64;              (* user-specified start time in AV_TIME_BASE or AV_NOPTS_VALUE *)
    recording_time: Int64;
    nb_streams: Integer;            (* number of stream that ffmpeg is aware of; may be different
                                       from ctx.nb_streams if new streams appear during av_read_frame() *)
    nb_streams_warn: Integer;       (* number of streams that the user was warned of *)
    rate_emu: Integer;
    accurate_seek: Integer;
  end;

  Tforced_keyframes_const = (
    FKF_N,
    FKF_N_FORCED,
    FKF_PREV_FORCED_N,
    FKF_PREV_FORCED_T,
    FKF_T,
    FKF_NB
  );

  TOutputStream = record
    // TODO: check the reused fields in join mode
    file_index: Integer;            (* output file index *)
    index: Integer;                 (* stream index in the output file *)
    source_index: Integer;          (* InputStream index *)
    st: PAVStream;                  (* stream in the output file *)
    encoding_needed: Integer;       (* true if encoding needed for this stream *)
    frame_number: Integer;
    (* input pts and corresponding output pts for A/V sync *)
    sync_ist: PInputStream;         (* input stream to sync against *)
    sync_opts: Int64;               (* output frame counter, could be changed to some true timestamp *) // FIXME look at frame_number
    (* pts of the first frame encoded for this stream, used for limiting
     * recording time *)
    first_pts: Int64;
    (* dts of the last packet sent to the muxer *)
    last_mux_dts: Int64;
    bitstream_filters: PAVBitStreamFilterContext;
    enc: PAVCodec;
    max_frames: Int64;
    filtered_frame: PAVFrame;

    (* video only *)
    frame_rate: TAVRational;
    force_fps: Integer;
    top_field_first: Integer;

    frame_aspect_ratio: TAVRational;

    (* forced key frames *)
    forced_kf_pts: PInt64;
    forced_kf_count: Integer;
    forced_kf_index: Integer;
    forced_keyframes: PAnsiChar;
    forced_keyframes_pexpr: PAVExpr;
    forced_keyframes_expr_const_values: array[Tforced_keyframes_const] of Double;

    (* audio only *)
    audio_channels_map: array[0..SWR_CH_MAX-1] of Integer;  (* list of the channels id to pick from the source stream *)
    audio_channels_mapped: Integer;                         (* number of channels in audio_channels_map *)

    logfile_prefix: PAnsiChar;
    logfile: Pointer; { FILE * }

    filter: POutputFilter;
    avfilter: PAnsiChar;

    sws_flags: Int64;
    opts: PAVDictionary;
    swr_opts: PAVDictionary;
    resample_opts: PAVDictionary;
    apad: PAnsiChar;
    finished: Integer;          (* no more packets should be written for this stream *)
    unavailable: Integer;       (* true if the steram is unavailable (possibly temporarily) *)
    stream_copy: Integer;
    attachment_filename: PAnsiChar;
    copy_initial_nonkeyframes: Integer;
    copy_prior_start: Integer;

    keep_pix_fmt: Integer;

    // hack: for join mode
    codec_id_bak: TAVCodecID;
    opts_bak: PAVDictionary;
    max_b_frames: Integer; // fix joining libx264
    not_show_fps: Integer;
    encoder_flushed: Integer;
    last_pts: Int64;
    last_dts: Int64;

    // hack: for fix memory leak
    is_filter_codec_opts: Integer;
    is_avcodec_get_context_defaults: Integer;
    is_avcodec_opened: Integer;
    is_avcodec_closed: Integer;
  end;

  PPOutputFile = ^POutputFile;
  POutputFile = ^TOutputFile;
  TOutputFile = record
    // TODO: check the reused fields in join mode
    ctx: PAVFormatContext;
    opts: PAVDictionary;
    ost_index: Integer;             (* index of the first stream in output_streams *)
    recording_time: Int64;          ///< desired length of the resulting file in microseconds == AV_TIME_BASE units
    start_time: Int64;              ///< start time in microseconds == AV_TIME_BASE units
    limit_filesize: Int64;          (* filesize limit expressed in bytes *)

    shortest: Integer;
  end;

(****** end from ffmpeg.h **************)

type
  FFmpegException = class(Exception);

  TCustomFFmpegOpt = class
  protected
    Fvstats_filename: PAnsiChar;

    Faudio_drift_threshold: Single;
    Fdts_delta_threshold: Single;
    Fdts_error_threshold: Single;

    Faudio_volume: Integer;
    Faudio_sync_method: Integer;
    Fvideo_sync_method: Integer; // should be -1, 0, 1, 2
    Fdo_deinterlace: Integer;
    //Fdo_benchmark: Integer;
    //Fdo_benchmark_all: Integer;
    Fdo_hex_dump: Integer;
    Fdo_pkt_dump: Integer;
    Fcopy_ts: Integer;
    Fcopy_tb: Integer;
    Fdebug_ts: Integer;
    Fexit_on_error: Integer;
    Fprint_stats: Integer;
    Fqp_hist: Integer;
    //Fstdin_interaction: Integer;
    Fframe_bits_per_raw_sample: Integer;
    Fmax_error_rate: Single;


    Fintra_only: Integer;
    Ffile_overwrite: Integer;
    Fno_file_overwrite: Integer;
    Fvideo_discard: Integer;
    Fintra_dc_precision: Integer;
    Fdo_psnr: Integer;
    Finput_sync: Integer;
    Foverride_ffserver: Integer;

(****** from ffmpeg.c **************)
    Fprogress_avio: PAVIOContext;

    Finput_streams: PPInputStream;
    Fnb_input_streams: Integer;
    Finput_files: PPInputFile;
    Fnb_input_files: Integer;

    Foutput_streams: PPOutputStream;
    Fnb_output_streams: Integer;
    Foutput_files: PPOutputFile;
    Fnb_output_files: Integer;

    Ffiltergraphs: PPFilterGraph;
    Fnb_filtergraphs: Integer;
(****** end from ffmpeg.c **************)

    procedure MATCH_PER_STREAM_OPT_copy_initial_nonkeyframes_i(o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PInteger);
    procedure MATCH_PER_STREAM_OPT_audio_sample_rate_i        (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PInteger);
    procedure MATCH_PER_STREAM_OPT_copy_prior_start_i         (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PInteger);
    procedure MATCH_PER_STREAM_OPT_fix_sub_duration_i         (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PInteger);
    procedure MATCH_PER_STREAM_OPT_guess_layout_max_i         (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PInteger);
    procedure MATCH_PER_STREAM_OPT_top_field_first_i          (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PInteger);
    procedure MATCH_PER_STREAM_OPT_audio_channels_i           (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PInteger);
    procedure MATCH_PER_STREAM_OPT_reinit_filters_i           (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PInteger);
    procedure MATCH_PER_STREAM_OPT_force_fps_i                (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PInteger);
    procedure MATCH_PER_STREAM_OPT_pass_i                     (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PInteger);
    procedure MATCH_PER_STREAM_OPT_frame_aspect_ratios_str    (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
    procedure MATCH_PER_STREAM_OPT_forced_key_frames_str      (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
    procedure MATCH_PER_STREAM_OPT_bitstream_filters_str      (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
    procedure MATCH_PER_STREAM_OPT_filter_scripts_str         (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
    procedure MATCH_PER_STREAM_OPT_frame_pix_fmts_str         (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
    procedure MATCH_PER_STREAM_OPT_intra_matrices_str         (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
    procedure MATCH_PER_STREAM_OPT_inter_matrices_str         (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
    procedure MATCH_PER_STREAM_OPT_canvas_sizes_str           (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
    procedure MATCH_PER_STREAM_OPT_passlogfiles_str           (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
    procedure MATCH_PER_STREAM_OPT_rc_overrides_str           (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
    procedure MATCH_PER_STREAM_OPT_codec_names_str            (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
    procedure MATCH_PER_STREAM_OPT_frame_rates_str            (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
    procedure MATCH_PER_STREAM_OPT_frame_sizes_str            (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
    procedure MATCH_PER_STREAM_OPT_sample_fmts_str            (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
    procedure MATCH_PER_STREAM_OPT_codec_tags_str             (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
    procedure MATCH_PER_STREAM_OPT_filters_str                (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
    procedure MATCH_PER_STREAM_OPT_apad_str                   (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
    procedure MATCH_PER_STREAM_OPT_max_frames_i64             (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PInt64);
    procedure MATCH_PER_STREAM_OPT_ts_scale_dbl               (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PDouble);
    procedure MATCH_PER_STREAM_OPT_qscale_dbl                 (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PDouble);

    procedure init_options(o: POptionsContext);
    procedure uninit_options(o: POptionsContext);

    function opt_ignore(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_skip(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_not_support(optctx: Pointer; opt, arg: PAnsiChar): Integer;

    function opt_sameq(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_video_channel(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_video_standard(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_audio_codec(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_video_codec(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_subtitle_codec(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_data_codec(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_map(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_attach(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_map_channel(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function parse_meta_type(arg: PAnsiChar; type_: PAnsiChar; index: PInteger;
      const stream_spec: PPAnsiChar): Integer;
    function copy_metadata(outspec, inspec: PAnsiChar; oc, ic: PAVFormatContext; o: POptionsContext): Integer;
    function opt_recording_timestamp(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function find_codec_or_die(const name: PAnsiChar; ttype: TAVMediaType; encoder: Integer): PAVCodec;
    function choose_decoder(o: POptionsContext; s: PAVFormatContext; st: PAVStream): PAVCodec;
    procedure add_input_streams(o: POptionsContext; ic: PAVFormatContext);
    function assert_file_overwrite(filename: PAnsiChar): Boolean;
    procedure dump_attachment(st: PAVStream; filename: PAnsiChar);
    function open_input_file(o: POptionsContext; AOptions, APresets: AnsiString;
      const filename: TPathFileName): Integer;
    procedure choose_encoder(o: POptionsContext; s: PAVFormatContext; ost: POutputStream);
    function new_output_stream(o: POptionsContext; oc: PAVFormatContext; ttype: TAVMediaType; source_index: Integer): POutputStream;
{$IFDEF BCB}
    procedure parse_matrix_coeffs(dest: PWord; str: PAnsiChar);
{$ELSE}
    procedure parse_matrix_coeffs(dest: System.PWord; str: PAnsiChar);
{$ENDIF}
    function get_ost_filters(o: POptionsContext; oc: PAVFormatContext; ost: POutputStream): PAnsiChar;
    function new_video_stream(o: POptionsContext; oc: PAVFormatContext; source_index: Integer): POutputStream;
    function new_audio_stream(o: POptionsContext; oc: PAVFormatContext; source_index: Integer): POutputStream;
    function new_data_stream(o: POptionsContext; oc: PAVFormatContext; source_index: Integer): POutputStream;
    function new_attachment_stream(o: POptionsContext; oc: PAVFormatContext; source_index: Integer): POutputStream;
    function new_subtitle_stream(o: POptionsContext; oc: PAVFormatContext; source_index: Integer): POutputStream;
    function opt_streamid(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function read_ffserver_streams(o: POptionsContext; s: PAVFormatContext; const filename: PAnsiChar): Integer;
(****** from ffmpeg_filter.c **************)
    function init_simple_filtergraph(ist: PInputStream; ost: POutputStream): PFilterGraph;
    procedure init_input_filter(fg: PFilterGraph; fin: PAVFilterInOut);
    function configure_output_video_filter(fg: PFilterGraph; ofilter: POutputFilter;
      fout: PAVFilterInOut): Integer;
    function configure_output_audio_filter(fg: PFilterGraph; ofilter: POutputFilter;
      fout: PAVFilterInOut): Integer;
    function configure_output_filter(fg: PFilterGraph; ofilter: POutputFilter;
      fout: PAVFilterInOut): Integer;
    function sub2video_prepare(ist: PInputStream): Integer;
    function configure_input_video_filter(fg: PFilterGraph; ifilter: PInputFilter;
      fin: PAVFilterInOut): Integer;
    function configure_input_audio_filter(fg: PFilterGraph; ifilter: PInputFilter;
      fin: PAVFilterInOut): Integer;
    function configure_input_filter(fg: PFilterGraph; ifilter: PInputFilter;
      fin: PAVFilterInOut): Integer;
    function configure_filtergraph(fg: PFilterGraph): Integer;
(****** end from ffmpeg_filter.c **************)
    procedure init_output_filter(ofilter: POutputFilter; o: POptionsContext; oc: PAVFormatContext);
    function configure_complex_filters(): Integer;
    function open_output_file(o: POptionsContext; AOptions, APresets: AnsiString;
      const filename: TPathFileName; AJoinMode: Boolean = False): Integer;
    function join_output_file(o: POptionsContext; file_index: Integer): Integer; // hack: for join mode
    function UpdateJoinMode(o: POptionsContext): Integer; // hack: for join mode
    procedure FreeOutputStreams; // hack: for convenience
    function opt_target(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_vstats_file(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_vstats(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_video_frames(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_audio_frames(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_data_frames(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_default_new(o: POptionsContext; opt, arg: PAnsiChar): Integer;
    function opt_preset(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_old2new(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_bitrate(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_qscale(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_profile(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_video_filters(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_audio_filters(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_vsync(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_timecode(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_channel_layout(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_audio_qscale(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_filter_complex(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_filter_complex_script(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_progress(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_TimeStart(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_TimeLength(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_loglevel(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_max_alloc(optctx: Pointer; opt, arg: PAnsiChar): Integer;
    function opt_cpuflags(optctx: Pointer; opt, arg: PAnsiChar): Integer;
{$IFDEF MSWINDOWS}
    function add_frame_hooker(optctx: Pointer; opt, arg: PAnsiChar): Integer; virtual; abstract;
{$ENDIF}
{$IFNDEF FFFMX}
    function opt_VideoHookBitsPixel(optctx: Pointer; opt, arg: PAnsiChar): Integer; virtual; abstract;
{$ENDIF}
  protected
{$IFDEF NEED_KEY}
    FLic: Pointer;
{$ENDIF}
    FOptions: TFFOptions;
    _OptionDef: array[0..192] of TOptionDef; // TODO: check size when append options
    FOptionDef: POptionDef;

    HaltOnInvalidOption: Boolean;

    FJoinMode: Boolean;
    Fnb_output_streams_join: Integer;

    FBroken: Boolean;
    FReadTimeout: Integer;
    FWriteTimeout: Integer;

    FReadCallback: TAVIOInterruptCB;
    FLastRead: Int64;
    FWriteCallback: TAVIOInterruptCB;
    FLastWrite: Int64;

    FInputDuration: Int64;
    FOutputDuration: Int64;

    FLastErrMsg: string;

    FOnBeforeFindStreamInfo: TBeforeFindStreamInfoEvent;

(****** from ffmpeg.c **************)
    procedure assert_avoptions(m: PAVDictionary);
    procedure abort_codec_experimental(c: PAVCodec; encoder: Integer);
(****** end from ffmpeg.c **************)

    procedure InitOptionDef;
    function ParseOptions(o: POptionsContext; AOptions, APresets: AnsiString; inout: string; filename: PAnsiChar; group_flags: Integer): Integer;
    function ParsePresets(o: POptionsContext; APresets: AnsiString; inout: string): Integer;

    procedure RaiseException(const Msg: string); overload;
    procedure RaiseException(const Msg: string; const Args: array of const); overload;

    property OnBeforeFindStreamInfo: TBeforeFindStreamInfoEvent read FOnBeforeFindStreamInfo write FOnBeforeFindStreamInfo;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    property LastErrMsg: string read FLastErrMsg;
    property OutputDuration: Int64 read FOutputDuration;
  end;

function PtrIdx(P: PPInputFile; I: Integer): PPInputFile; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PtrIdx(P: PPInputFilter; I: Integer): PPInputFilter; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PtrIdx(P: PPFilterGraph; I: Integer): PPFilterGraph; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}

function PtrIdx(P: PPInputStream; I: Integer): PPInputStream; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PtrIdx(P: PPOutputFile; I: Integer): PPOutputFile; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PtrIdx(P: PPOutputStream; I: Integer): PPOutputStream; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PtrIdx(P: PPOutputFilter; I: Integer): PPOutputFilter; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PPtrIdx(P: PPInputFile; I: Integer): PInputFile; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PPtrIdx(P: PPInputFilter; I: Integer): PInputFilter; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PPtrIdx(P: PPFilterGraph; I: Integer): PFilterGraph; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PPtrIdx(P: PPInputStream; I: Integer): PInputStream; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PPtrIdx(P: PPOutputFile; I: Integer): POutputFile; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PPtrIdx(P: PPOutputFilter; I: Integer): POutputFilter; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PPtrIdx(P: PPOutputStream; I: Integer): POutputStream; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function guess_input_channel_layout(ist: PInputStream): Integer;
function write_interrupt_callback(opaque: Pointer): Integer; cdecl;
function ist_in_filtergraph(fg: PFilterGraph; ist: PInputStream): Integer;

implementation

uses
  FFLog;

{$IFDEF BCB}
function PtrIdx(P: PWord; I: Integer): PWord; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
{$ELSE}
function PtrIdx(P: System.PWord; I: Integer): System.PWord; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
{$ENDIF}
begin
  Result := P;
  Inc(Result, I);
end;

function PtrIdx(P: PStreamMap; I: Integer): PStreamMap; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  Result := P;
  Inc(Result, I);
end;

function PtrIdx(P: PAudioChannelMap; I: Integer): PAudioChannelMap; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  Result := P;
  Inc(Result, I);
end;

function PtrIdx(P: PPInputFile; I: Integer): PPInputFile; //overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  Result := P;
  Inc(Result, I);
end;

function PtrIdx(P: PPInputFilter; I: Integer): PPInputFilter; //overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  Result := P;
  Inc(Result, I);
end;

function PtrIdx(P: PPFilterGraph; I: Integer): PPFilterGraph; //overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  Result := P;
  Inc(Result, I);
end;

function PtrIdx(P: PPInputStream; I: Integer): PPInputStream; //overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  Result := P;
  Inc(Result, I);
end;

function PtrIdx(P: PPOutputFile; I: Integer): PPOutputFile; //overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  Result := P;
  Inc(Result, I);
end;

function PtrIdx(P: PPOutputStream; I: Integer): PPOutputStream; //overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  Result := P;
  Inc(Result, I);
end;

function PtrIdx(P: PPOutputFilter; I: Integer): PPOutputFilter; //overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  Result := P;
  Inc(Result, I);
end;

function PPtrIdx(P: PPInputFile; I: Integer): PInputFile; //overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  Inc(P, I);
  Result := P^;
end;

function PPtrIdx(P: PPInputFilter; I: Integer): PInputFilter; //overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  Inc(P, I);
  Result := P^;
end;

function PPtrIdx(P: PPFilterGraph; I: Integer): PFilterGraph; //overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  Inc(P, I);
  Result := P^;
end;

function PPtrIdx(P: PPInputStream; I: Integer): PInputStream; //overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  Inc(P, I);
  Result := P^;
end;

function PPtrIdx(P: PPOutputFile; I: Integer): POutputFile; //overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  Inc(P, I);
  Result := P^;
end;

function PPtrIdx(P: PPOutputFilter; I: Integer): POutputFilter; //overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  Inc(P, I);
  Result := P^;
end;

function PPtrIdx(P: PPOutputStream; I: Integer): POutputStream; //overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  Inc(P, I);
  Result := P^;
end;

function guess_input_channel_layout(ist: PInputStream): Integer;
var
  avdec: PAVCodecContext;
  layout_name: array[0..255] of AnsiChar;
begin
  avdec := ist.st.codec;

  if avdec.channel_layout = 0 then
  begin
    if avdec.channels > ist.guess_layout_max then
    begin
      Result := 0;
      Exit;
    end;
    avdec.channel_layout := av_get_default_channel_layout(avdec.channels);
    if avdec.channel_layout = 0 then
    begin
      Result := 0;
      Exit;
    end;
    av_get_channel_layout_string(layout_name, SizeOf(layout_name),
                                 avdec.channels, avdec.channel_layout);
    FFLogger.Log(nil, llWarning, 'Guessed Channel Layout for  Input Stream ' +
           '#%d.%d : %s', [ist.file_index, ist.st.index, string(layout_name)]);
  end;
  Result := 1;
end;

{ TCustomFFmpegOpt }

function read_interrupt_callback(opaque: Pointer): Integer; cdecl;
begin
  //if TObject(opaque) is TCustomFFmpegOpt then
    with TObject(opaque) as TCustomFFmpegOpt do
    begin
      if FBroken then
      begin
        FFLogger.Log(TObject(opaque), llInfo, 'reading/writing broken');
        Result := 1;
        Exit;
      end;
      if (FLastRead < High(Int64)) and (FReadTimeout > 0) and (av_gettime() - FLastRead > FReadTimeout * 1000) then
      begin
        if FLastRead <> 0 then
          FFLogger.Log(TObject(opaque), llInfo, 'connecting/reading timeout')
        else
          FFLogger.Log(TObject(opaque), llInfo, 'connecting/reading canceled');
        Result := 1;
        Exit;
      end;
    end;
  Result := 0;
end;

function write_interrupt_callback(opaque: Pointer): Integer; cdecl;
begin
  //if TObject(opaque) is TCustomFFmpegOpt then
    with TObject(opaque) as TCustomFFmpegOpt do
    begin
{
      if FBroken then
      begin
        FFLogger.Log(TObject(opaque), llInfo, 'reading/writing broken');
        Result := 1;
        Exit;
      end;
}
      if (FLastWrite < High(Int64)) and (FWriteTimeout > 0) and (av_gettime() - FLastWrite > FWriteTimeout * 1000) then
      begin
        if FLastWrite <> 0 then
          FFLogger.Log(TObject(opaque), llInfo, 'connecting/writing timeout')
        else
          FFLogger.Log(TObject(opaque), llInfo, 'connecting/writing canceled');
        Result := 1;
        Exit;
      end;
    end;
  Result := 0;
end;

constructor TCustomFFmpegOpt.Create;
begin
  Fvstats_filename := nil;

  Faudio_drift_threshold := 0.1;
  Fdts_delta_threshold := 10;
  Fdts_error_threshold := 3600*30;

  Faudio_volume := 256;
  Faudio_sync_method := 0;
  Fvideo_sync_method := VSYNC_AUTO;
  Fdo_deinterlace := 0;
  //Fdo_benchmark := 0;
  //Fdo_benchmark_all := 0;
  Fdo_hex_dump := 0;
  Fdo_pkt_dump := 0;
  Fcopy_ts := 0;
  Fcopy_tb := -1;
  Fdebug_ts := 0;
  Fexit_on_error := 0;
  Fprint_stats := -1;
  Fqp_hist := 0;
  //Fstdin_interaction := 1;
  Fframe_bits_per_raw_sample := 0;
  Fmax_error_rate := 2.0/3;


  Fintra_only := 0;
  Ffile_overwrite := 0;
  Fno_file_overwrite := 0;
  Fvideo_discard := 0;
  Fintra_dc_precision := 8;
  Fdo_psnr := 0;
  Finput_sync := 0;
  Foverride_ffserver := 0;

  HaltOnInvalidOption := True;
  FJoinMode := False;
  Fnb_output_streams_join := 0;

  FOptions := TFFOptions.Create;

  with FReadCallback do
  begin
    callback := read_interrupt_callback;
    opaque := Self;
  end;
  FReadTimeout := 30 * 1000;
  with FWriteCallback do
  begin
    callback := write_interrupt_callback;
    opaque := Self;
  end;
  FWriteTimeout := 30 * 1000;
end;

destructor TCustomFFmpegOpt.Destroy;
begin
  FOptions.Free;
  inherited;
end;

procedure TCustomFFmpegOpt.RaiseException(const Msg: string);
begin
  FLastErrMsg := Msg;
  FFLogger.Log(Self, llFatal, FLastErrMsg);
  raise FFmpegException.Create(FLastErrMsg);
end;

procedure TCustomFFmpegOpt.RaiseException(const Msg: string; const Args: array of const);
begin
  FLastErrMsg := Format(Msg, Args);
  FFLogger.Log(Self, llFatal, FLastErrMsg);
  raise FFmpegException.Create(FLastErrMsg);
end;

procedure TCustomFFmpegOpt.assert_avoptions(m: PAVDictionary);
var
  t: PAVDictionaryEntry;
begin
  t := av_dict_get(m, '', nil, AV_DICT_IGNORE_SUFFIX);
  if Assigned(t) then
    if HaltOnInvalidOption then
      RaiseException('Option %s not found.', [string(t.key)]) // exit_program(1);
    else
      FLastErrMsg := Format('Option %s not found.', [string(t.key)]);
end;

procedure TCustomFFmpegOpt.abort_codec_experimental(c: PAVCodec; encoder: Integer);
begin
  RaiseException('abort codec experimental'); // exit_program(1);
end;

(*
#define MATCH_PER_STREAM_OPT(name, type, outvar, fmtctx, st)\
{\
    int i, ret;\
    for (i = 0; i < o->nb_ ## name; i++) {\
        char *spec = o->name[i].specifier;\
        if ((ret = check_stream_specifier(fmtctx, st, spec)) > 0)\
            outvar = o->name[i].u.type;\
        else if (ret < 0)\
            exit_program(1);\
    }\
}
*)

procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_copy_initial_nonkeyframes_i
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PInteger);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_copy_initial_nonkeyframes{name} - 1 do
  begin
    spec := PtrIdx(o.copy_initial_nonkeyframes{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.copy_initial_nonkeyframes{name}, i).u.i{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;
procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_audio_sample_rate_i
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PInteger);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_audio_sample_rate{name} - 1 do
  begin
    spec := PtrIdx(o.audio_sample_rate{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.audio_sample_rate{name}, i).u.i{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;
procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_copy_prior_start_i
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PInteger);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_copy_prior_start{name} - 1 do
  begin
    spec := PtrIdx(o.copy_prior_start{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.copy_prior_start{name}, i).u.i{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;
procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_fix_sub_duration_i
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PInteger);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_fix_sub_duration{name} - 1 do
  begin
    spec := PtrIdx(o.fix_sub_duration{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.fix_sub_duration{name}, i).u.i{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;
procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_guess_layout_max_i
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PInteger);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_guess_layout_max{name} - 1 do
  begin
    spec := PtrIdx(o.guess_layout_max{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.guess_layout_max{name}, i).u.i{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;
procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_top_field_first_i
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PInteger);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_top_field_first{name} - 1 do
  begin
    spec := PtrIdx(o.top_field_first{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.top_field_first{name}, i).u.i{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;
procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_audio_channels_i
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PInteger);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_audio_channels{name} - 1 do
  begin
    spec := PtrIdx(o.audio_channels{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.audio_channels{name}, i).u.i{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;
procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_reinit_filters_i
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PInteger);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_reinit_filters{name} - 1 do
  begin
    spec := PtrIdx(o.reinit_filters{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.reinit_filters{name}, i).u.i{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;
procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_force_fps_i
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PInteger);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_force_fps{name} - 1 do
  begin
    spec := PtrIdx(o.force_fps{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.force_fps{name}, i).u.i{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;
procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_pass_i
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PInteger);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_pass{name} - 1 do
  begin
    spec := PtrIdx(o.pass{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.pass{name}, i).u.i{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;
procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_frame_aspect_ratios_str
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_frame_aspect_ratios{name} - 1 do
  begin
    spec := PtrIdx(o.frame_aspect_ratios{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.frame_aspect_ratios{name}, i).u.str{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;
procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_forced_key_frames_str
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_forced_key_frames{name} - 1 do
  begin
    spec := PtrIdx(o.forced_key_frames{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.forced_key_frames{name}, i).u.str{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;
procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_bitstream_filters_str
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_bitstream_filters{name} - 1 do
  begin
    spec := PtrIdx(o.bitstream_filters{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.bitstream_filters{name}, i).u.str{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;
procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_filter_scripts_str
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_filter_scripts{name} - 1 do
  begin
    spec := PtrIdx(o.filter_scripts{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.filter_scripts{name}, i).u.str{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;
procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_frame_pix_fmts_str
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_frame_pix_fmts{name} - 1 do
  begin
    spec := PtrIdx(o.frame_pix_fmts{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.frame_pix_fmts{name}, i).u.str{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;
procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_intra_matrices_str
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_intra_matrices{name} - 1 do
  begin
    spec := PtrIdx(o.intra_matrices{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.intra_matrices{name}, i).u.str{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;
procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_inter_matrices_str
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_inter_matrices{name} - 1 do
  begin
    spec := PtrIdx(o.inter_matrices{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.inter_matrices{name}, i).u.str{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;
procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_canvas_sizes_str
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_canvas_sizes{name} - 1 do
  begin
    spec := PtrIdx(o.canvas_sizes{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.canvas_sizes{name}, i).u.str{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;
procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_passlogfiles_str
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_passlogfiles{name} - 1 do
  begin
    spec := PtrIdx(o.passlogfiles{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.passlogfiles{name}, i).u.str{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;
procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_rc_overrides_str
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_rc_overrides{name} - 1 do
  begin
    spec := PtrIdx(o.rc_overrides{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.rc_overrides{name}, i).u.str{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;
procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_codec_names_str
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_codec_names{name} - 1 do
  begin
    spec := PtrIdx(o.codec_names{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.codec_names{name}, i).u.str{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;
procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_frame_rates_str
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_frame_rates{name} - 1 do
  begin
    spec := PtrIdx(o.frame_rates{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.frame_rates{name}, i).u.str{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;
procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_frame_sizes_str
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_frame_sizes{name} - 1 do
  begin
    spec := PtrIdx(o.frame_sizes{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.frame_sizes{name}, i).u.str{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;
procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_sample_fmts_str
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_sample_fmts{name} - 1 do
  begin
    spec := PtrIdx(o.sample_fmts{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.sample_fmts{name}, i).u.str{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;
procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_codec_tags_str
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_codec_tags{name} - 1 do
  begin
    spec := PtrIdx(o.codec_tags{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.codec_tags{name}, i).u.str{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;
procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_filters_str
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_filters{name} - 1 do
  begin
    spec := PtrIdx(o.filters{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.filters{name}, i).u.str{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;
procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_apad_str
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PPAnsiChar);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_apad{name} - 1 do
  begin
    spec := PtrIdx(o.apad{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.apad{name}, i).u.str{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;
procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_max_frames_i64
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PInt64);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_max_frames{name} - 1 do
  begin
    spec := PtrIdx(o.max_frames{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.max_frames{name}, i).u.i64{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;
procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_ts_scale_dbl
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PDouble);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_ts_scale{name} - 1 do
  begin
    spec := PtrIdx(o.ts_scale{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.ts_scale{name}, i).u.dbl{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;
procedure TCustomFFmpegOpt.MATCH_PER_STREAM_OPT_qscale_dbl
  (o: POptionsContext; s: PAVFormatContext; st: PAVStream; outvar: PDouble);
var
  i, ret: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_qscale{name} - 1 do
  begin
    spec := PtrIdx(o.qscale{name}, i).specifier;
    ret := check_stream_specifier(s, st, spec);
    if ret > 0 then
      outvar^ := PtrIdx(o.qscale{name}, i).u.dbl{type}
    else if ret < 0 then
      RaiseException(print_error('check_stream_specifier', ret));
  end;
end;

(*
#define MATCH_PER_TYPE_OPT(name, type, outvar, fmtctx, mediatype)\
{\
    int i;\
    for (i = 0; i < o->nb_ ## name; i++) {\
        char *spec = o->name[i].specifier;\
        if (!strcmp(spec, mediatype))\
            outvar = o->name[i].u.type;\
    }\
}
*)

procedure MATCH_PER_TYPE_OPT_codec_names_str
  (o: POptionsContext; s: PAVFormatContext; mediatype: PAnsiChar; outvar: PPAnsiChar);
var
  i: Integer;
  spec: PAnsiChar;
begin
  for i := 0 to o.nb_codec_names{name} - 1 do
  begin
    spec := PtrIdx(o.codec_names{name}, i).specifier;
    if my_strcmp(spec, mediatype) = 0 then
      outvar^ := PtrIdx(o.codec_names{name}, i).u.str;{type}
  end;
end;

procedure TCustomFFmpegOpt.init_options(o: POptionsContext);
begin
  FillChar(o^, SizeOf(o^), 0);

  o.stop_time := High(Int64);
  o.mux_max_delay := 0.7;
  o.start_time := AV_NOPTS_VALUE;
  o.recording_time := High(Int64);
  o.limit_filesize := High(Int64);
  o.chapters_input_file := MaxInt;
  o.accurate_seek := 1;

  FOptions.init_parse_context;
  o.g := @FOptions.OptionParseContext.file_opts;
end;

procedure TCustomFFmpegOpt.uninit_options(o: POptionsContext);
var
  po: POptionDef;
  i: Integer;
  dst: Pointer;
  so: PPSpecifierOpt;
  count: PInteger;
begin
  po := FOptionDef;

  (* all OPT_SPEC and OPT_STRING can be freed in generic way *)
  while Assigned(po.name) do
  begin
    dst := Pointer(Integer(o) + po.u.off);

    if (po.flags and OPT_SPEC) <> 0 then
    begin
      so := dst;
      count := PInteger(Integer(so) + SizeOf(so^));
      for i := 0 to count^ - 1 do
      begin
        av_freep(@PSpecifierOpt(PtrIdx(so^, i)).specifier);
        if (po.flags and OPT_STRING) <> 0 then
          av_freep(@PSpecifierOpt(PtrIdx(so^, i)).u.str);
      end;
      av_freep(so);
      count^ := 0;
    end
    else if ((po.flags and OPT_OFFSET) <> 0) and ((po.flags and OPT_STRING) <> 0) then
      av_freep(dst);
    Inc(po);
  end;

  for i := 0 to o.nb_stream_maps - 1 do
    av_freep(@PAnsiChar(PtrIdx(o.stream_maps, i)^.linklabel));
  av_freep(@o.stream_maps);
  av_freep(@o.audio_channel_maps);
  av_freep(@o.streamid_map);
  av_freep(@o.attachments);
  FOptions.uninit_parse_context;
end;

function TCustomFFmpegOpt.opt_ignore(optctx: Pointer; opt, arg: PAnsiChar): Integer;
begin
  GOptionError := Format('options "%s" not supported, ignore', [string(opt)]);
  FFLogger.Log(Self, llWarning, GOptionError);
  Result := 0;
end;

function TCustomFFmpegOpt.opt_skip(optctx: Pointer; opt, arg: PAnsiChar): Integer;
begin
  Result := 0;
end;

function TCustomFFmpegOpt.opt_not_support(optctx: Pointer; opt, arg: PAnsiChar): Integer;
begin
  GOptionError := Format('options "%s" not supported', [string(opt)]);
  FFLogger.Log(Self, llError, GOptionError);
  Result := AVERROR_EINVAL;
end;

(* return a copy of the input with the stream specifiers removed from the keys *)
function strip_specifiers(dict: PAVDictionary): PAVDictionary;
var
  e: PAVDictionaryEntry;
  ret: PAVDictionary;
  p: PAnsiChar;
begin
  e := nil;
  ret := nil;

  e := av_dict_get(dict, '', e, AV_DICT_IGNORE_SUFFIX);
  while Assigned(e) do
  begin
    p := my_strchr(e.key, ':');

    if Assigned(p) then
      p^ := #0;
    av_dict_set(@ret, e.key, e.value, 0);
    if Assigned(p) then
      p^ := ':';
    e := av_dict_get(dict, '', e, AV_DICT_IGNORE_SUFFIX);
  end;
  Result := ret;
end;

function TCustomFFmpegOpt.opt_sameq(optctx: Pointer; opt, arg: PAnsiChar): Integer;
begin
  GOptionError := Format('Option "%s" was removed. ' +
         'If you are looking for an option to preserve the quality (which is not ' +
         'what -%s was for), use -qscale 0 or an equivalent quality factor option.',
         [string(opt), string(opt)]);
  FFLogger.Log(Self, llWarning, GOptionError);
  Result := AVERROR_EINVAL;
end;

function TCustomFFmpegOpt.opt_video_channel(optctx: Pointer; opt, arg: PAnsiChar): Integer;
begin
  FFLogger.Log(Self, llWarning, 'This option is deprecated, use -channel.');
  Result := FOptions.opt_default(PAnsiChar('channel'), arg);
end;

function TCustomFFmpegOpt.opt_video_standard(optctx: Pointer; opt, arg: PAnsiChar): Integer;
begin
  FFLogger.Log(Self, llWarning, 'This option is deprecated, use -standard.');
  Result := FOptions.opt_default(PAnsiChar('standard'), arg);
end;

function TCustomFFmpegOpt.opt_audio_codec(optctx: Pointer; opt, arg: PAnsiChar): Integer;
begin
  Result := parse_option(optctx, 'codec:a', arg, FOptionDef);
end;

function TCustomFFmpegOpt.opt_video_codec(optctx: Pointer; opt, arg: PAnsiChar): Integer;
begin
  Result := parse_option(optctx, 'codec:v', arg, FOptionDef);
end;

function TCustomFFmpegOpt.opt_subtitle_codec(optctx: Pointer; opt, arg: PAnsiChar): Integer;
begin
  Result := parse_option(optctx, 'codec:s', arg, FOptionDef);
end;

function TCustomFFmpegOpt.opt_data_codec(optctx: Pointer; opt, arg: PAnsiChar): Integer;
begin
  Result := parse_option(optctx, 'codec:d', arg, FOptionDef);
end;

function TCustomFFmpegOpt.opt_map(optctx: Pointer; opt, arg: PAnsiChar): Integer;
var
  o: POptionsContext;
  m: PStreamMap;
  i, negative, file_idx: Integer;
  sync_file_idx, sync_stream_idx: Integer;
  p, pp, sync: PAnsiChar;
  map: PAnsiChar;
  c: PAnsiChar;
begin
  o := optctx;

  m := nil;
  negative := 0;
  sync_file_idx := -1;
  sync_stream_idx := 0;

  // [-]input_file_id[:stream_specifier][,sync_file_id[:stream_specifier]]
  if arg^ = '-' then
  begin
    negative := 1;
    Inc(arg);
  end;
  map := av_strdup(arg);

  (* parse sync stream first, just pick first matching stream *)
  sync := my_strchr(map, ',');
  if Assigned(sync) then
  begin
    sync^ := #0;
    sync_file_idx := my_strtol(sync + 1, @sync, 0);
    if (sync_file_idx >= Fnb_input_files) or (sync_file_idx < 0) then
    begin
      RaiseException('Invalid sync file index: %d.', [sync_file_idx]);
      //exit_program(1);
    end;
    if sync^ <> #0 then
      Inc(sync);
    for i := 0 to PPtrIdx(Finput_files, sync_file_idx).nb_streams - 1 do
      if check_stream_specifier(PPtrIdx(Finput_files, sync_file_idx).ctx,
                                PPtrIdx(PPtrIdx(Finput_files, sync_file_idx).ctx.streams, i), sync) = 1 then
      begin
        sync_stream_idx := i;
        Break;
      end;
    if i = PPtrIdx(Finput_files, sync_file_idx).nb_streams then
    begin
      RaiseException('Sync stream specification in map %s does not match any streams.', [string(arg)]);
      //exit_program(1);
    end;
  end;

  if map^ = '[' then
  begin
    (* this mapping refers to lavfi output *)
    c := map + 1;
    o.stream_maps := grow_array(o.stream_maps, SizeOf(o.stream_maps^),
                                @o.nb_stream_maps, o.nb_stream_maps + 1);
    m := PtrIdx(o.stream_maps, o.nb_stream_maps - 1);
    m.linklabel := av_get_token(@c, ']');
    if not Assigned(m.linklabel) then
    begin
      RaiseException('Invalid output link label: %s.', [string(map)]);
      //exit_program(1);
    end;
  end
  else
  begin
    file_idx := my_strtol(map, @p, 0);
    if (file_idx >= Fnb_input_files) or (file_idx < 0) then
    begin
      RaiseException('Invalid input file index: %d.', [file_idx]);
      //exit_program(1);
    end;
    if p^ = ':' then
      pp := p + 1
    else
      pp := p;
    if negative <> 0 then
    begin
      (* disable some already defined maps *)
      for i := 0 to o.nb_stream_maps - 1 do
      begin
        m := PtrIdx(o.stream_maps, i);
        if (file_idx = m.file_index) and
          (check_stream_specifier(PPtrIdx(Finput_files, m.file_index).ctx,
                                  PPtrIdx(PPtrIdx(Finput_files, m.file_index).ctx.streams, m.stream_index),
                                  pp) > 0) then
          m.disabled := 1;
      end;
    end
    else
    begin
      for i := 0 to PPtrIdx(Finput_files, file_idx).nb_streams - 1 do
      begin
        if check_stream_specifier(PPtrIdx(Finput_files, file_idx).ctx,
                                  PPtrIdx(PPtrIdx(Finput_files, file_idx).ctx.streams, i),
                                  pp) <= 0 then
          Continue;
        o.stream_maps := grow_array(o.stream_maps, SizeOf(o.stream_maps^),
                                    @o.nb_stream_maps, o.nb_stream_maps + 1);
        m := PtrIdx(o.stream_maps, o.nb_stream_maps - 1);

        m.file_index   := file_idx;
        m.stream_index := i;

        if sync_file_idx >= 0 then
        begin
          m.sync_file_index   := sync_file_idx;
          m.sync_stream_index := sync_stream_idx;
        end
        else
        begin
          m.sync_file_index   := file_idx;
          m.sync_stream_index := i;
        end;
      end;
    end;
  end;

  if not Assigned(m) then
  begin
    RaiseException('Stream map "%s" matches no streams.', [string(arg)]);
    //exit_program(1);
  end;

  av_freep(@map);
  Result := 0;
end;

function TCustomFFmpegOpt.opt_attach(optctx: Pointer; opt, arg: PAnsiChar): Integer;
var
  o: POptionsContext;
begin
  o := optctx;
  o.attachments := grow_array(o.attachments, SizeOf(o.attachments^),
                              @o.nb_attachments, o.nb_attachments + 1);
  PtrIdx(o.attachments, o.nb_attachments - 1)^ := arg;
  Result := 0;
end;

function TCustomFFmpegOpt.opt_map_channel(optctx: Pointer; opt, arg: PAnsiChar): Integer;
var
  o: POptionsContext;
  n: Integer;
  st: PAVStream;
  m: PAudioChannelMap;
begin
  o := optctx;

  o.audio_channel_maps :=
      grow_array(o.audio_channel_maps, SizeOf(o.audio_channel_maps^),
                 @o.nb_audio_channel_maps, o.nb_audio_channel_maps + 1);
  m := PtrIdx(o.audio_channel_maps, o.nb_audio_channel_maps - 1);

  (* muted channel syntax *)
  n := my_sscanf(arg, '%d:%d.%d', @m.channel_idx, @m.ofile_idx, @m.ostream_idx);
  if ((n = 1) or (n = 3)) and (m.channel_idx = -1) then
  begin
    m.file_idx := -1;
    m.stream_idx := -1;
    if n = 1 then
    begin
      m.ofile_idx := -1;
      m.ostream_idx := -1;
    end;
    Result := 0;
    Exit;
  end;

  (* normal syntax *)
  n := my_sscanf(arg, '%d.%d.%d:%d.%d',
                 @m.file_idx,  @m.stream_idx, @m.channel_idx,
                 @m.ofile_idx, @m.ostream_idx);

  if (n <> 3) and (n <> 5) then
  begin
    RaiseException('Syntax error, mapchan usage: [file.stream.channel|-1][:syncfile:syncstream]');
    //exit_program(1);
  end;

  if n <> 5 then // only file.stream.channel specified
  begin
    m.ofile_idx := -1;
    m.ostream_idx := -1;
  end;

  (* check input *)
  if (m.file_idx < 0) or (m.file_idx >= Fnb_input_files) then
  begin
    RaiseException('mapchan: invalid input file index: %d', [m.file_idx]);
    //exit_program(1);
  end;
  if (m.stream_idx < 0) or
    (m.stream_idx >= PPtrIdx(Finput_files, m.file_idx).nb_streams) then
  begin
    RaiseException('mapchan: invalid input file stream index #%d.%d', [m.file_idx, m.stream_idx]);
    //exit_program(1);
  end;
  st := PPtrIdx(PPtrIdx(Finput_files, m.file_idx).ctx.streams, m.stream_idx);
  if st.codec.codec_type <> AVMEDIA_TYPE_AUDIO then
  begin
    RaiseException('mapchan: stream #%d.%d is not an audio stream.', [m.file_idx, m.stream_idx]);
    //exit_program(1);
  end;
  if (m.channel_idx < 0) or (m.channel_idx >= st.codec.channels) then
  begin
    RaiseException('mapchan: invalid audio channel #%d.%d.%d', [m.file_idx, m.stream_idx, m.channel_idx]);
    //exit_program(1);
  end;

  Result := 0;
end;

(**
 * Parse a metadata specifier passed as 'arg' parameter.
 * @param arg  metadata string to parse
 * @param type metadata type is written here -- g(lobal)/s(tream)/c(hapter)/p(rogram)
 * @param index for type c/p, chapter/program index is written here
 * @param stream_spec for type s, the stream specifier is written here
 *)
function TCustomFFmpegOpt.parse_meta_type(arg: PAnsiChar; type_: PAnsiChar;
  index: PInteger; const stream_spec: PPAnsiChar): Integer;
begin
  if arg^ <> #0 then
  begin
    type_^ := arg^;
    case arg^ of
      'g': ;
      's':
        begin
          Inc(arg);
          if (arg^ <> #0) and (arg^ <> ':') then
          begin
            //RaiseException('Invalid metadata specifier %s.', [string(arg)]);
            //exit_program(1);
            FLastErrMsg := Format('Invalid metadata specifier %s.', [string(arg)]);
            FFLogger.Log(Self, llFatal, FLastErrMsg);
            Result := -1;
            Exit;
          end;
          if arg^ = ':' then
            stream_spec^ := arg + 1
          else
            stream_spec^ := '';
        end;
      'c',
      'p':
      begin
        Inc(arg);
        if arg^ = ':' then
        begin
          Inc(arg);
          index^ := my_strtol(arg, nil, 0);
        end;
      end
    else
      //RaiseException('Invalid metadata type %s.', [arg^]);
      //exit_program(1);
      FLastErrMsg := Format('Invalid metadata type %s.', [arg^]);
      FFLogger.Log(Self, llFatal, FLastErrMsg);
      Result := -1;
      Exit;
    end;
  end
  else
    type_^ := 'g';
  Result := 0;
end;

function TCustomFFmpegOpt.copy_metadata(outspec, inspec: PAnsiChar; oc, ic: PAVFormatContext; o: POptionsContext): Integer;
var
  meta_in: PPAVDictionary;
  meta_out: PPAVDictionary;
  i, ret: Integer;
  type_in, type_out: AnsiChar;
  istream_spec, ostream_spec: PAnsiChar;
  idx_in, idx_out: Integer;
begin
  meta_in := nil;
  meta_out := nil;
  istream_spec := nil;
  ostream_spec := nil;
  idx_in := 0;
  idx_out := 0;

  if (parse_meta_type(inspec,  @type_in,  @idx_in,  @istream_spec) < 0) or
     (parse_meta_type(outspec, @type_out, @idx_out, @ostream_spec) < 0) then
  begin
    Result := -1;
    Exit;
  end;

  if not Assigned(ic) then
  begin
    if (type_out = 'g') or (outspec^ = #0) then
      o.metadata_global_manual := 1;
    if (type_out = 's') or (outspec^ = #0) then
      o.metadata_streams_manual := 1;
    if (type_out = 'c') or (outspec^ = #0) then
      o.metadata_chapters_manual := 1;
    Result := 0;
    Exit;
  end;

  if (type_in = 'g') or (type_out = 'g') then
    o.metadata_global_manual := 1;
  if (type_in = 's') or (type_out = 's') then
    o.metadata_streams_manual := 1;
  if (type_in = 'c') or (type_out = 'c') then
    o.metadata_chapters_manual := 1;

  (* ic is NULL when just disabling automatic mappings *)
  if not Assigned(ic) then
  begin
    Result := 0;
    Exit;
  end;

(*
#define METADATA_CHECK_INDEX(index, nb_elems, desc)\
    if ((index) < 0 || (index) >= (nb_elems)) {\
        av_log(NULL, AV_LOG_FATAL, "Invalid %s index %d while processing metadata maps.\n",\
                (desc), (index));\
        exit_program(1);\
    }

#define SET_DICT(type, meta, context, index)\
        switch (type) {\
        case 'g':\
            meta = &context->metadata;\
            break;\
        case 'c':\
            METADATA_CHECK_INDEX(index, context->nb_chapters, "chapter")\
            meta = &context->chapters[index]->metadata;\
            break;\
        case 'p':\
            METADATA_CHECK_INDEX(index, context->nb_programs, "program")\
            meta = &context->programs[index]->metadata;\
            break;\
        case 's':\
            break; /* handled separately below */ \
        default: av_assert0(0);\
        }\

  SET_DICT(type_in, meta_in, ic, idx_in);
  SET_DICT(type_out, meta_out, oc, idx_out);
*)
  case type_in of
    'g': meta_in := @ic.metadata;
    'c':
      begin
        if (idx_in < 0) or (idx_in >= Integer(ic.nb_chapters)) then
        begin
          //RaiseException('Invalid %s index %d while processing metadata maps.', ['chapter', idx_in]);
          //exit_program(1);
          FLastErrMsg := Format('Invalid %s index %d while processing metadata maps.', ['chapter', idx_in]);
          Result := -1;
          Exit;
        end;
        meta_in := @PAVDictionary(PPtrIdx(ic.chapters, idx_in).metadata);
      end;
    'p':
      begin
        if (idx_in < 0) or (idx_in >= Integer(ic.nb_programs)) then
        begin
          //RaiseException('Invalid %s index %d while processing metadata maps.',['program', idx_in]);
          //exit_program(1);
          FLastErrMsg := Format('Invalid %s index %d while processing metadata maps.',['program', idx_in]);
          Result := -1;
          Exit;
        end;
        meta_in := @PAVDictionary(PPtrIdx(ic.programs, idx_in).metadata);
      end;
    's': ;  (* handled separately below *)
  else
    raise FFmpegException.Create('never occur');
  end;

  case type_out of
    'g': meta_out := @oc.metadata;
    'c':
      begin
        if (idx_out < 0) or (idx_out >= Integer(oc.nb_chapters)) then
        begin
          //RaiseException('Invalid %s index %d while processing metadata maps.', ['chapter', idx_out]);
          //exit_program(1);
          FLastErrMsg := Format('Invalid %s index %d while processing metadata maps.', ['chapter', idx_out]);
          Result := -1;
          Exit;
        end;
        meta_out := @PAVDictionary(PPtrIdx(oc.chapters, idx_out).metadata);
      end;
    'p':
      begin
        if (idx_out < 0) or (idx_out >= Integer(oc.nb_programs)) then
        begin
          //RaiseException('Invalid %s index %d while processing metadata maps.', ['program', idx_in]);
          //exit_program(1);
          FLastErrMsg := Format('Invalid %s index %d while processing metadata maps.', ['program', idx_in]);
          Result := -1;
          Exit;
        end;
        meta_out := @PAVDictionary(PPtrIdx(oc.programs, idx_out).metadata);
      end;
    's': ;  (* handled separately below *)
  else
    raise FFmpegException.Create('never occur');
  end;

  (* for input streams choose first matching stream *)
  if type_in = 's' then
  begin
    for i := 0 to Integer(ic.nb_streams) - 1 do
    begin
      ret := check_stream_specifier(ic, PPtrIdx(ic.streams, i), istream_spec);
      if ret > 0 then
      begin
        meta_in := @PAVDictionary(PPtrIdx(ic.streams, i).metadata);
        Break;
      end
      else if ret < 0 then
      begin
        //RaiseException(print_error('check_stream_specifier', ret));
        //exit_program(1);
        FLastErrMsg := print_error('check_stream_specifier', ret);
        Result := ret;
        Exit;
      end;
    end;
    if not Assigned(meta_in) then
    begin
      //RaiseException('Stream specifier %s does not match  any streams.', [string(istream_spec)]);
      //exit_program(1);
      FLastErrMsg := Format('Stream specifier %s does not match  any streams.', [string(istream_spec)]);
      Result := -1;
      Exit;
    end;
  end;

  if type_out = 's' then
  begin
    for i := 0 to Integer(oc.nb_streams) - 1 do
    begin
      ret := check_stream_specifier(oc, PPtrIdx(oc.streams, i), ostream_spec);
      if ret > 0 then
      begin
        meta_out := @PAVDictionary(PPtrIdx(oc.streams, i).metadata);
        av_dict_copy(meta_out, meta_in^, AV_DICT_DONT_OVERWRITE);
      end
      else if ret < 0 then
      begin
        //RaiseException(print_error('check_stream_specifier', ret));
        //exit_program(1);
        FLastErrMsg := print_error('check_stream_specifier', ret);
        Result := ret;
        Exit;
      end;
    end;
  end
  else
    av_dict_copy(meta_out, meta_in^, AV_DICT_DONT_OVERWRITE);

  Result := 0;
end;

function TCustomFFmpegOpt.opt_recording_timestamp(optctx: Pointer; opt, arg: PAnsiChar): Integer;
var
  o: POptionsContext;
  recording_timestamp: Int64;
{$IFDEF MSWINDOWS}
  buf: string;
{$ENDIF}
{$IFDEF POSIX}
  buf: array[0..128] of AnsiChar;
  time: tm;
  tt: time_t;
{$ENDIF}
begin
  o := optctx;
  recording_timestamp := Round(parse_time_or_die(opt, arg, 0) / 1000000);
{$IFDEF MSWINDOWS}
  buf := 'creation_time=' +
          FormatDateTime('yyyy-mm-dd hh:nn:ss', UnixToDateTimeEx(recording_timestamp)) +
          ' ' + GetTimeZoneAbbreviation;
  Result := parse_option(o, 'metadata', PAnsiChar(AnsiString(buf)), FOptionDef);
{$ENDIF}
{$IFDEF POSIX}
  tt := recording_timestamp;
  time := gmtime(tt)^;
  strftime(buf, SizeOf(buf), 'creation_time=%FT%T%z', time);
  Result := parse_option(o, 'metadata', buf, FOptionDef);
{$ENDIF}
  FFLogger.Log(Self, llWarning, '%s is deprecated, set the "creation_time" metadata tag instead.', [string(opt)]);
end;

function TCustomFFmpegOpt.find_codec_or_die(const name: PAnsiChar;
  ttype: TAVMediaType; encoder: Integer): PAVCodec;
var
  desc: PAVCodecDescriptor;
  codec_string: string;
  codec: PAVCodec;
begin
  if encoder <> 0 then
  begin
    codec_string := 'encoder';
    codec := avcodec_find_encoder_by_name(name);
  end
  else
  begin
    codec_string := 'decoder';
    codec := avcodec_find_decoder_by_name(name);
  end;

  if not Assigned(codec) then
  begin
    desc := avcodec_descriptor_get_by_name(name);
    if Assigned(desc) then
    begin
      if encoder <> 0 then
        codec := avcodec_find_encoder(desc.id)
      else
        codec := avcodec_find_decoder(desc.id);
      if Assigned(codec) then
        FFLogger.Log(Self, llVerbose, 'Matched %s "%s" for codec "%s".',
                     [codec_string, string(codec.name), string(desc.name)]);
    end;
  end;

  if not Assigned(codec) then
  begin
    RaiseException('Unknown %s "%s"', [codec_string, string(name)]);
    //exit_program(1);
  end;

  if codec.ttype <> ttype then
  begin
    RaiseException('Invalid %s type "%s"', [codec_string, string(name)]);
    //exit_program(1);
  end;

  Result := codec;
end;

function TCustomFFmpegOpt.choose_decoder(o: POptionsContext; s: PAVFormatContext; st: PAVStream): PAVCodec;
var
  codec_name: PAnsiChar;
  codec: PAVCodec;
begin
  codec_name := nil;
//  MATCH_PER_STREAM_OPT(codec_names, str, codec_name, s, st);
  MATCH_PER_STREAM_OPT_codec_names_str(o, s, st, @codec_name);
  if Assigned(codec_name) then
  begin
    codec := find_codec_or_die(codec_name, st.codec.codec_type, 0);
    st.codec.codec_id := codec.id;
    Result := codec;
  end
  else
    Result := avcodec_find_decoder(st.codec.codec_id);
end;

(* Add all the streams from the given input file to the global
 * list of input streams. *)
procedure TCustomFFmpegOpt.add_input_streams(o: POptionsContext; ic: PAVFormatContext);
var
  i: Integer;
  next, codec_tag: PAnsiChar;
  st: PAVStream;
  avdec: PAVCodecContext;
  ist: PInputStream;
  framerate: PAnsiChar;
  tag: Cardinal;
  canvas_size: PAnsiChar;
begin
  codec_tag := nil;
  for i := 0 to Integer(ic.nb_streams) - 1 do
  begin
    st := PPtrIdx(ic.streams, i);
    avdec := st.codec;
    ist := av_mallocz(SizeOf(ist^));
    framerate := nil;

    if not Assigned(ist) then
    begin
      RaiseException('av_mallocz() failed');
      //exit_program(1);
    end;

    Finput_streams := grow_array(Finput_streams, SizeOf(Finput_streams^), @Fnb_input_streams, Fnb_input_streams + 1);
    PtrIdx(Finput_streams, Fnb_input_streams - 1)^ := ist;

    ist.st := st;
    ist.file_index := Fnb_input_files;
    ist.discard := 1;
    st.discard := AVDISCARD_ALL;

    ist.ts_scale := 1.0;
    //MATCH_PER_STREAM_OPT(ts_scale, dbl, ist.ts_scale, ic, st);
    MATCH_PER_STREAM_OPT_ts_scale_dbl(o, ic, st, @ist.ts_scale);

    //MATCH_PER_STREAM_OPT(codec_tags, str, codec_tag, ic, st);
    MATCH_PER_STREAM_OPT_codec_tags_str(o, ic, st, @codec_tag);
    if Assigned(codec_tag) then
    begin
      tag := my_strtol(codec_tag, @next, 0);
      if next^ <> #0 then
        //tag := AV_RL32(codec_tag);
        tag := Ord((codec_tag + 3)^) shl 24 or
               Ord((codec_tag + 2)^) shl 16 or
               Ord((codec_tag + 1)^) shl 8 or
               Ord(codec_tag^);

      st.codec.codec_tag.tag := tag;
    end;

    ist.avdec := choose_decoder(o, ic, st);
    ist.opts := filter_codec_opts(o.g.codec_opts, ist.st.codec.codec_id, ic, st, ist.avdec);

    ist.reinit_filters := -1;
    //MATCH_PER_STREAM_OPT(reinit_filters, i, ist.reinit_filters, ic, st);
    MATCH_PER_STREAM_OPT_reinit_filters_i(o, ic, st, @ist.reinit_filters);

    ist.filter_in_rescale_delta_last := AV_NOPTS_VALUE;

    case avdec.codec_type of
      AVMEDIA_TYPE_VIDEO:
        begin
          if not Assigned(ist.avdec) then
            ist.avdec := avcodec_find_decoder(avdec.codec_id);
          if av_codec_get_lowres(avdec) <> 0 then
            avdec.flags := avdec.flags or CODEC_FLAG_EMU_EDGE;

          ist.resample_height  := avdec.height;
          ist.resample_width   := avdec.width;
          ist.resample_pix_fmt := Ord(avdec.pix_fmt);

          MATCH_PER_STREAM_OPT_frame_rates_str(o, ic, st, @framerate);
          if Assigned(framerate) and (av_parse_video_rate(@ist.framerate, framerate) < 0) then
          begin
            RaiseException('Error parsing framerate %s.', [string(framerate)]);
            //exit_program(1);
          end;

          ist.top_field_first := -1;
          MATCH_PER_STREAM_OPT_top_field_first_i(o, ic, st, @ist.top_field_first);
        end;
      AVMEDIA_TYPE_AUDIO:
        begin
          ist.guess_layout_max := MaxInt;
          //MATCH_PER_STREAM_OPT(guess_layout_max, i, ist->guess_layout_max, ic, st);
          MATCH_PER_STREAM_OPT_guess_layout_max_i(o, ic, st, @ist.guess_layout_max);
          guess_input_channel_layout(ist);

          ist.resample_sample_fmt     := Ord(avdec.sample_fmt);
          ist.resample_sample_rate    := avdec.sample_rate;
          ist.resample_channels       := avdec.channels;
          ist.resample_channel_layout := avdec.channel_layout;
        end;
      AVMEDIA_TYPE_DATA,
      AVMEDIA_TYPE_SUBTITLE:
        begin
          canvas_size := nil;
          if not Assigned(ist.avdec) then
            ist.avdec := avcodec_find_decoder(avdec.codec_id);
          MATCH_PER_STREAM_OPT_fix_sub_duration_i(o, ic, st, @ist.fix_sub_duration);
          MATCH_PER_STREAM_OPT_canvas_sizes_str(o, ic, st, @canvas_size);
          if Assigned(canvas_size) and
            (av_parse_video_size(@avdec.width, @avdec.height, canvas_size) < 0) then
          begin
            RaiseException('Invalid canvas size: %s.', [string(canvas_size)]);
            //exit_program(1);
          end;
        end;
      AVMEDIA_TYPE_ATTACHMENT: ;
      AVMEDIA_TYPE_UNKNOWN: ;
    else
      raise FFmpegException.Create('Never occur');
    end;
  end;
end;

function TCustomFFmpegOpt.assert_file_overwrite(filename: PAnsiChar): Boolean;
begin
  if (Ffile_overwrite <> 0) and (Fno_file_overwrite <> 0) then
  begin
    RaiseException('Error, both -y and -n supplied.');
    //exit_program(1);
  end;

  if (Ffile_overwrite = 0) and
    ((my_strchr(filename, ':') = nil) or ((filename + 1)^ = ':') or
     (av_strstart(filename, 'file:', nil) <> 0)) then
  begin
    if avio_check(filename, 0) = 0 then
    begin
      FLastErrMsg := Format('File "%s" already exists. Ignore.', [string(filename)]);
      FFLogger.Log(Self, llWarning, FLastErrMsg);
      Result := False;
      Exit;
    end;
  end;
  Result := True;
end;

procedure TCustomFFmpegOpt.dump_attachment(st: PAVStream; filename: PAnsiChar);
var
  ret: Integer;
  avout: PAVIOContext;
  e: PAVDictionaryEntry;
begin
  avout := nil;

  if st.codec.extradata_size = 0 then
  begin
    FFLogger.Log(Self, llWarning, 'No extradata to dump in stream #%d:%d.',
                 [Fnb_input_files - 1, st.index]);
    Exit;
  end;
  if filename^ = #0 then
  begin
    e := av_dict_get(st.metadata, 'filename', nil, 0);
    if Assigned(e) then
      filename := e.value;
  end;
  if filename^ = #0 then
  begin
    //RaiseException('No filename specified and no "filename" tag in stream #%d:%d.',
    //                [Fnb_input_files - 1, st.index]);
    //exit_program(1);
    FFLogger.Log(Self, llError, 'No filename specified and no "filename" tag in stream #%d:%d.',
                    [Fnb_input_files - 1, st.index]);
    Exit;
  end;

  if not assert_file_overwrite(filename) then
    Exit;

  FLastWrite := av_gettime(); // hack: for write timeout
  ret := avio_open2(@avout, filename, AVIO_FLAG_WRITE, @FWriteCallback, nil);
  if ret < 0 then
  begin
    //RaiseException('Could not open file %s for writing.', [string(filename)]);
    //exit_program(1);
    FFLogger.Log(Self, llError, 'Could not open file %s for writing.', [string(filename)]);
    Exit;
  end;

  FLastWrite := av_gettime(); // hack: for write timeout
  avio_write(avout, st.codec.extradata, st.codec.extradata_size);
  avio_flush(avout);
  avio_close(avout);
end;

function TCustomFFmpegOpt.open_input_file(o: POptionsContext;
  AOptions, APresets: AnsiString; const filename: TPathFileName): Integer;
var
  f: PInputFile;
  ic: PAVFormatContext;
  file_iformat: PAVInputFormat;
  err, i, ret: Integer;
  timestamp: Int64;
  buf: array[0..127] of Byte;
  opts: PPAVDictionary;
  unused_opts: PAVDictionary;
  e: PAVDictionaryEntry;
  class_: PAVClass;
  option: PAVOption;
  opt_help: PAnsiChar;
  orig_nb_streams: Integer; // number of streams before avformat_find_stream_info
  st: PAVStream;
  j: Integer;
  video_codec_name: PAnsiChar;
  audio_codec_name: PAnsiChar;
  subtitle_codec_name: PAnsiChar;
begin
  ret := ParseOptions(o, AOptions, APresets, 'input file', ffmpeg_filename(filename), OPT_INPUT);
  if ret < 0 then
  begin
    Result := ret;
    Exit;
  end;

  video_codec_name := nil;
  audio_codec_name := nil;
  subtitle_codec_name := nil;

  if Assigned(o.format) then
  begin
    file_iformat := av_find_input_format(o.format);
    if not Assigned(file_iformat) then
    begin
      //RaiseException('Unknown input format: "%s"', [string(o.format)]);
      //exit_program(1);
      Result := AVERROR_EINVAL;
      FLastErrMsg := Format('Unknown input format: "%s"', [string(o.format)]);
      FFLogger.Log(Self, llFatal, FLastErrMsg);
      Exit;
    end;
  end
  else
    file_iformat := nil;
{
    if (!strcmp(filename, "-"))
        filename = "pipe:";
    stdin_interaction &= strncmp(filename, "pipe:", 5) &&
                         strcmp(filename, "/dev/stdin");
}
  (* get default parameters from command line *)
  ic := avformat_alloc_context();
  if not Assigned(ic) then
  begin
    //RaiseException(print_error(filename, AVERROR_ENOMEM));
    //exit_program(1);
    Result := AVERROR_ENOMEM;
    FLastErrMsg := 'avformat_alloc_context() failed';
    FFLogger.Log(Self, llFatal, FLastErrMsg);
    Exit;
  end;

  if o.nb_audio_sample_rate <> 0 then
  begin
    my_snprintf(@buf[0], SizeOf(buf), '%d', PtrIdx(o.audio_sample_rate, o.nb_audio_sample_rate - 1).u.i);
    av_dict_set(@o.g.format_opts, 'sample_rate', @buf[0], 0);
  end;
  if o.nb_audio_channels <> 0 then
  begin
    (* because we set audio_channels based on both the "ac" and
     * "channel_layout" options, we need to check that the specified
     * demuxer actually has the "channels" option before setting it *)
    if Assigned(file_iformat) and Assigned(file_iformat.priv_class) and
       Assigned(av_opt_find(@file_iformat.priv_class, 'channels', nil, 0, AV_OPT_SEARCH_FAKE_OBJ)) then
    begin
      my_snprintf(@buf[0], SizeOf(buf), '%d', PtrIdx(o.audio_channels, o.nb_audio_channels - 1).u.i);
      av_dict_set(@o.g.format_opts, 'channels', @buf[0], 0);
    end;
  end;
  if o.nb_frame_rates <> 0 then
  begin
    (* set the format-level framerate option;
     * this is important for video grabbers, e.g. x11 *)
    if Assigned(file_iformat) and Assigned(file_iformat.priv_class) and
       Assigned(av_opt_find(@file_iformat.priv_class, 'framerate', nil, 0, AV_OPT_SEARCH_FAKE_OBJ)) then
      av_dict_set(@o.g.format_opts, 'framerate', PtrIdx(o.frame_rates, o.nb_frame_rates - 1).u.str, 0);
  end;
  if o.nb_frame_sizes <> 0 then
    av_dict_set(@o.g.format_opts, 'video_size', PtrIdx(o.frame_sizes, o.nb_frame_sizes - 1).u.str, 0);
  if o.nb_frame_pix_fmts <> 0 then
    av_dict_set(@o.g.format_opts, 'pixel_format', PtrIdx(o.frame_pix_fmts, o.nb_frame_pix_fmts - 1).u.str, 0);

  MATCH_PER_TYPE_OPT_codec_names_str(o, ic, 'v', @video_codec_name);
  MATCH_PER_TYPE_OPT_codec_names_str(o, ic, 'a', @audio_codec_name);
  MATCH_PER_TYPE_OPT_codec_names_str(o, ic, 's', @subtitle_codec_name);

  if Assigned(video_codec_name) then
    ic.video_codec_id := find_codec_or_die(video_codec_name, AVMEDIA_TYPE_VIDEO, 0).id
  else
    ic.video_codec_id := AV_CODEC_ID_NONE;
  if Assigned(audio_codec_name) then
    ic.audio_codec_id := find_codec_or_die(audio_codec_name, AVMEDIA_TYPE_AUDIO, 0).id
  else
    ic.audio_codec_id := AV_CODEC_ID_NONE;
  if Assigned(subtitle_codec_name) then
    ic.subtitle_codec_id := find_codec_or_die(subtitle_codec_name, AVMEDIA_TYPE_SUBTITLE, 0).id
  else
    ic.subtitle_codec_id := AV_CODEC_ID_NONE;

  if Assigned(video_codec_name) then
    av_format_set_video_codec   (ic, find_codec_or_die(video_codec_name   , AVMEDIA_TYPE_VIDEO   , 0));
  if Assigned(audio_codec_name) then
    av_format_set_audio_codec   (ic, find_codec_or_die(audio_codec_name   , AVMEDIA_TYPE_AUDIO   , 0));
  if Assigned(subtitle_codec_name) then
    av_format_set_subtitle_codec(ic, find_codec_or_die(subtitle_codec_name, AVMEDIA_TYPE_SUBTITLE, 0));

  ic.flags := ic.flags or AVFMT_FLAG_NONBLOCK;

  // hack: read callback
  with ic.interrupt_callback do
  begin
    callback := read_interrupt_callback;
    opaque := Self;
  end;
  // hack end

  (* open the input file with generic avformat function *)
  FLastRead := av_gettime(); // hack: for read timeout
  err := avformat_open_input(@ic, ffmpeg_filename(filename), file_iformat, @o.g.format_opts);
  if err < 0 then
  begin
    //RaiseException(print_error(filename, err));
    //exit_program(1);
    Result := err;
    FLastErrMsg := print_error(filename, err);
    FFLogger.Log(Self, llFatal, FLastErrMsg);
    Exit;
  end;
  assert_avoptions(o.g.format_opts);

  (* apply forced codec ids *)
  for i := 0 to Integer(ic.nb_streams) - 1 do
    choose_decoder(o, ic, PPtrIdx(ic.streams, i));

  (* Set AVCodecContext options for avformat_find_stream_info *)
  opts := setup_find_stream_info_opts(ic, o.g.codec_opts);
  orig_nb_streams := ic.nb_streams;

  // hack: OnBeforeFindStreamInfo event
  if Assigned(FOnBeforeFindStreamInfo) then
    FOnBeforeFindStreamInfo(Self, ic);
  // hack end

  (* If not enough info to get the stream parameters, we decode the
     first frames to get it. (used in mpeg case for example) *)
  FLastRead := av_gettime(); // hack: for read timeout
  ret := avformat_find_stream_info(ic, opts);
  if ret < 0 then
  begin
    avformat_close_input(@ic);
    //RaiseException('%s: could not find codec parameters', [filename]);
    //exit_program(1);
    FLastErrMsg := Format('%s: could not find codec parameters', [filename]);
    FFLogger.Log(Self, llFatal, FLastErrMsg);
    Result := ret;
    Exit;
  end;

  if o.start_time = AV_NOPTS_VALUE then
    timestamp := 0
  else
    timestamp := o.start_time;

  // hack: input duration
  if (ic.duration <> AV_NOPTS_VALUE) and (ic.duration - timestamp > FInputDuration) then
    FInputDuration := ic.duration - timestamp;
  // hack end

  (* add the stream start time *)
  if ic.start_time <> AV_NOPTS_VALUE then
    Inc(timestamp, ic.start_time);

  (* if seeking requested, we execute it *)
  if o.start_time <> AV_NOPTS_VALUE then
  begin
    FLastRead := av_gettime();
    ret := avformat_seek_file(ic, -1, Low(Int64), timestamp, timestamp, 0);
    if ret < 0 then
      FFLogger.Log(Self, llWarning, '%s: could not seek to position %0.3f',
                   [filename, timestamp / AV_TIME_BASE]);
  end;

  (* update the current parameters so that they match the one of the input stream *)
  add_input_streams(o, ic);

  (* dump the file content *)
  av_dump_format(ic, Fnb_input_files, PAnsiChar({$IFDEF FPC}filename{$ELSE}{$IFDEF UNICODE}Utf8Encode{$ELSE}AnsiString{$ENDIF}(filename){$ENDIF}), 0);

  Finput_files := grow_array(Finput_files, SizeOf(Finput_files^), @Fnb_input_files, Fnb_input_files + 1);
  f := av_mallocz(SizeOf(f^));
  if not Assigned(f) then
//  PtrIdx(Finput_files, Fnb_input_files - 1)^ := av_mallocz(SizeOf(Finput_files^^));
//  if not Assigned(PtrIdx(Finput_files, Fnb_input_files - 1)^) then
  begin
    RaiseException('av_mallocz() failed');
    //exit_program(1);
  end;
  PtrIdx(Finput_files, Fnb_input_files - 1)^ := f;

  f.ctx        := ic;
  f.ist_index  := Fnb_input_streams - Integer(ic.nb_streams);
  f.start_time := o.start_time;
  f.recording_time := o.recording_time;
  f.input_ts_offset := o.input_ts_offset;
  if Fcopy_ts <> 0 then
    f.ts_offset  := o.input_ts_offset - 0
  else
    f.ts_offset  := o.input_ts_offset - timestamp;
  f.nb_streams := ic.nb_streams;
  f.rate_emu   := o.rate_emu;
  f.accurate_seek := o.accurate_seek;

  (* check if all codec options have been used *)
  unused_opts := strip_specifiers(o.g.codec_opts);
  for i := f.ist_index to Fnb_input_streams - 1 do
  begin
    e := av_dict_get(PPtrIdx(Finput_streams, i).opts, '', nil, AV_DICT_IGNORE_SUFFIX);
    while Assigned(e) do
    begin
      av_dict_set(@unused_opts, e.key, nil, 0);
      e := av_dict_get(PPtrIdx(Finput_streams, i).opts, '', e, AV_DICT_IGNORE_SUFFIX);
    end;
  end;

  e := av_dict_get(unused_opts, '', nil, AV_DICT_IGNORE_SUFFIX);
  while Assigned(e) do
  begin
    class_ := avcodec_get_class();
    option := av_opt_find(@class_, e.key, nil, 0, AV_OPT_SEARCH_CHILDREN or AV_OPT_SEARCH_FAKE_OBJ);
    if Assigned(option) then
    begin
      if Assigned(option.help) then
        opt_help := option.help
      else
        opt_help := '';
      if (option.flags and AV_OPT_FLAG_DECODING_PARAM) = 0 then
      begin
        //RaiseException('Codec AVOption %s (%s) specified for ' +
        //               'input file #%d (%s) is not a decoding option.',
        //               [string(e.key), string(opt_help), Fnb_input_files - 1, filename]);
        //exit_program(1);
        Result := AVERROR_EINVAL;
        FLastErrMsg := Format('Codec AVOption %s (%s) specified for ' +
                         'input file #%d (%s) is not a decoding option.',
                         [string(e.key), string(opt_help), Fnb_input_files - 1, filename]);
        FFLogger.Log(Self, llError, FLastErrMsg);
        Exit;
      end;

      FFLogger.Log(Self, llWarning,
                  'Codec AVOption %s (%s) specified for ' +
                  'input file #%d (%s) has not been used for any stream. The most ' +
                  'likely reason is either wrong type (e.g. a video option with ' +
                  'no video streams) or that it is a private option of some decoder ' +
                  'which was not actually used for any stream.',
                  [string(e.key), string(opt_help), Fnb_input_files - 1, filename]);
    end;
    e := av_dict_get(unused_opts, '', e, AV_DICT_IGNORE_SUFFIX);
  end;
  av_dict_free(@unused_opts);

  for i := 0 to o.nb_dump_attachment - 1 do
  begin
    for j := 0 to Integer(ic.nb_streams) - 1 do
    begin
      st := PPtrIdx(ic.streams, j);
      if check_stream_specifier(ic, st, PtrIdx(o.dump_attachment, i).specifier) = 1 then
        dump_attachment(st, PtrIdx(o.dump_attachment, i).u.str);
    end;
  end;

  for i := 0 to orig_nb_streams - 1 do
    av_dict_free(PtrIdx(opts, i));
  av_freep(@opts);

  Result := Fnb_input_files - 1;
end;

(*
static uint8_t *get_line(AVIOContext *s)
{
    AVIOContext *line;
    uint8_t *buf;
    char c;

    if (avio_open_dyn_buf(&line) < 0) {
        av_log(NULL, AV_LOG_FATAL, "Could not alloc buffer for reading preset.\n");
        exit_program(1);
    }

    while ((c = avio_r8(s)) && c != '\n')
        avio_w8(line, c);
    avio_w8(line, 0);
    avio_close_dyn_buf(line, &buf);

    return buf;
}

static int get_preset_file_2(const char *preset_name, const char *codec_name, AVIOContext **s)
{
    int i, ret = 1;
    char filename[1000];
    const char *base[3] = { getenv("AVCONV_DATADIR"),
                            getenv("HOME"),
                            AVCONV_DATADIR,
                            };

    for (i = 0; i < FF_ARRAY_ELEMS(base) && ret; i++) {
        if (!base[i])
            continue;
        if (codec_name) {
            snprintf(filename, sizeof(filename), "%s%s/%s-%s.avpreset", base[i],
                     i != 1 ? "" : "/.avconv", codec_name, preset_name);
            ret = avio_open2(s, filename, AVIO_FLAG_READ, &int_cb, NULL);
        }
        if (ret) {
            snprintf(filename, sizeof(filename), "%s%s/%s.avpreset", base[i],
                     i != 1 ? "" : "/.avconv", preset_name);
            ret = avio_open2(s, filename, AVIO_FLAG_READ, &int_cb, NULL);
        }
    }
    return ret;
}
*)

procedure TCustomFFmpegOpt.choose_encoder(o: POptionsContext; s: PAVFormatContext; ost: POutputStream);
var
  codec_name: PAnsiChar;
begin
  codec_name := nil;

  MATCH_PER_STREAM_OPT_codec_names_str(o, s, ost.st, @codec_name);
  if not Assigned(codec_name) then
  begin
    ost.st.codec.codec_id := av_guess_codec(s.oformat, nil, s.filename,
                                            nil, ost.st.codec.codec_type);
    ost.enc := avcodec_find_encoder(ost.st.codec.codec_id);
  end
  else if codec_name = 'copy' {my_strcmp(codec_name, 'copy') = 0} then
    ost.stream_copy := 1
  else
  begin
    ost.enc := find_codec_or_die(codec_name, ost.st.codec.codec_type, 1);
    ost.st.codec.codec_id := ost.enc.id;
  end;
end;

function TCustomFFmpegOpt.new_output_stream(o: POptionsContext; oc: PAVFormatContext; ttype: TAVMediaType; source_index: Integer): POutputStream;
var
  ost: POutputStream;
  st: PAVStream;
  idx: Integer;
  bsf, next, codec_tag: PAnsiChar;
  bsfc, bsfc_prev: PAVBitStreamFilterContext;
  qscale: Double;
  i: Integer;
  p: PAnsiChar;
  tag: Cardinal;
begin
  st := avformat_new_stream(oc, nil);
  if not Assigned(st) then
  begin
    RaiseException('Could not alloc stream.');
    //exit_program(1);
  end;

  idx := oc.nb_streams - 1;
  bsf := nil;
  codec_tag := nil;
  bsfc_prev := nil;
  qscale := -1;

  if Integer(oc.nb_streams) - 1 < o.nb_streamid_map then
    st.id := PtrIdx(o.streamid_map, oc.nb_streams - 1)^;

  Foutput_streams := grow_array(Foutput_streams, SizeOf(Foutput_streams^), @Fnb_output_streams,
                                Fnb_output_streams + 1);
  ost := av_mallocz(SizeOf(ost^));
  if not Assigned(ost) then
  begin
    RaiseException('av_mallocz() failed');
    //exit_program(1);
  end;
  PtrIdx(Foutput_streams, Fnb_output_streams - 1)^ := ost;

  ost.file_index := Fnb_output_files - 1;
  ost.index      := idx;
  ost.st         := st;
  ost.last_pts   := AV_NOPTS_VALUE; // hack: for join mode
  ost.last_dts   := AV_NOPTS_VALUE; // hack: for join mode
  st.codec.codec_type := ttype;
  choose_encoder(o, oc, ost);
  if Assigned(ost.enc) then
  begin
    ost.opts := filter_codec_opts(o.g.codec_opts, ost.enc.id, oc, st, ost.enc);
    ost.is_filter_codec_opts := 1;  // hack: for fix memory leak
  // TODO: presets support
(*
        AVIOContext *s = NULL;
        char *buf = NULL, *arg = NULL, *preset = NULL;
        MATCH_PER_STREAM_OPT(presets, str, preset, oc, st);
        if (preset && (!(ret = get_preset_file_2(preset, ost->enc->name, &s)))) {
            do  {
                buf = get_line(s);
                if (!buf[0] || buf[0] == '#') {
                    av_free(buf);
                    continue;
                }
                if (!(arg = strchr(buf, '='))) {
                    av_log(NULL, AV_LOG_FATAL, "Invalid line found in the preset file.\n");
                    exit_program(1);
                }
                *arg++ = 0;
                av_dict_set(&ost->opts, buf, arg, AV_DICT_DONT_OVERWRITE);
                av_free(buf);
            } while (!s->eof_reached);
            avio_close(s);
        }
        if (ret) {
            av_log(NULL, AV_LOG_FATAL,
                   "Preset %s specified for stream %d:%d, but could not be opened.\n",
                   preset, ost->file_index, ost->index);
            exit_program(1);
        }
*)
  end
  else
  begin
    ost.opts := filter_codec_opts(o.g.codec_opts, AV_CODEC_ID_NONE, oc, st, nil);
    ost.is_filter_codec_opts := 1;  // hack: for fix memory leak
  end;

  avcodec_get_context_defaults3(st.codec, ost.enc);
  st.codec.codec_type := ttype; // XXX hack, avcodec_get_context_defaults2() sets type to unknown for stream copy
  ost.is_avcodec_get_context_defaults := 1; // hack: for fix memory leak

  ost.max_frames := High(Int64);
  MATCH_PER_STREAM_OPT_max_frames_i64(o, oc, st, @ost.max_frames);
  for i := 0 to o.nb_max_frames - 1 do
  begin
    p := PtrIdx(o.max_frames, i).specifier;
    if (p^ = #0) and (ttype <> AVMEDIA_TYPE_VIDEO) then
    begin
      FFLogger.Log(Self, llWarning, 'Applying unspecific -frames to non video streams, maybe you meant -vframes ?');
      Break;
    end;
  end;

  ost.copy_prior_start := -1;
  MATCH_PER_STREAM_OPT_copy_prior_start_i(o, oc, st, @ost.copy_prior_start);

  MATCH_PER_STREAM_OPT_bitstream_filters_str(o, oc, st, @bsf);
  while Assigned(bsf) do
  begin
    next := my_strchr(bsf, ',');
    if Assigned(next) then
    begin
      next^ := #0;
      Inc(next);
    end;
    bsfc := av_bitstream_filter_init(bsf);
    if not Assigned(bsfc) then
    begin
      RaiseException('Unknown bitstream filter "%s"', [string(bsf)]);
      //exit_program(1);
    end;
    if Assigned(bsfc_prev) then
      bsfc_prev.next := bsfc
    else
      ost.bitstream_filters := bsfc;

    bsfc_prev := bsfc;
    bsf       := next;
  end;

  MATCH_PER_STREAM_OPT_codec_tags_str(o, oc, st, @codec_tag);
  if Assigned(codec_tag) then
  begin
    tag := my_strtol(codec_tag, @next, 0);
    if next^ <> #0 then
      //tag := AV_RL32(codec_tag);
      tag := Ord((codec_tag + 3)^) shl 24 or
             Ord((codec_tag + 2)^) shl 16 or
             Ord((codec_tag + 1)^) shl 8 or
             Ord(codec_tag^);
    st.codec.codec_tag.tag := tag;
  end;

  MATCH_PER_STREAM_OPT_qscale_dbl(o, oc, st, @qscale);
  if qscale >= 0 then
  begin
    st.codec.flags := st.codec.flags or CODEC_FLAG_QSCALE;
    st.codec.global_quality := Trunc(FF_QP2LAMBDA * qscale);
  end;

  if (oc.oformat.flags and AVFMT_GLOBALHEADER) <> 0 then
    st.codec.flags := st.codec.flags or CODEC_FLAG_GLOBAL_HEADER;

  av_opt_get_int   (o.g.sws_opts, 'sws_flags',     0, @ost.sws_flags);

  av_dict_copy(@ost.swr_opts, o.g.swr_opts, 0);
  if Assigned(ost.enc) and (av_get_exact_bits_per_sample(ost.enc.id) = 24) then
    av_dict_set(@ost.swr_opts, 'output_sample_bits', '24', 0);

  av_dict_copy(@ost.resample_opts, o.g.resample_opts, 0);

  ost.source_index := source_index;
  if source_index >= 0 then
  begin
    ost.sync_ist := PPtrIdx(Finput_streams, source_index);
    PPtrIdx(Finput_streams, source_index).discard := 0;
    PPtrIdx(Finput_streams, source_index).st.discard := AVDISCARD_NONE;
  end;
  ost.last_mux_dts := AV_NOPTS_VALUE;

  Result := ost;
end;

{$IFDEF BCB}
procedure TCustomFFmpegOpt.parse_matrix_coeffs(dest: PWord; str: PAnsiChar);
{$ELSE}
procedure TCustomFFmpegOpt.parse_matrix_coeffs(dest: System.PWord; str: PAnsiChar);
{$ENDIF}
var
  i: Integer;
  p: PAnsiChar;
begin
  p := str;
  i := 0;
  while True do
  begin
    PtrIdx(dest, i)^ := my_atoi(p);
    if i = 63 then
      Break;
    p := my_strchr(p, ',');
    if not Assigned(p) then
    begin
      RaiseException('Syntax error in matrix "%s" at coeff %d', [string(str), i]);
      //exit_program(1);
    end;
    Inc(p);
    Inc(i);
  end;
end;

(* read file contents into a string *)
function read_file(const filename: PAnsiChar): PAnsiChar;
var
  pb: PAVIOContext;
  dyn_buf: PAVIOContext;
  ret: Integer;
  buf: array[0..1023] of AnsiChar;
  str: PAnsiChar;
begin
  pb := nil;
  dyn_buf := nil;
  ret := avio_open(@pb, filename, AVIO_FLAG_READ);

  if ret < 0 then
  begin
    FFLogger.Log(nil, llError, 'Error opening file %s.', [string(filename)]);
    Result := nil;
    Exit;
  end;

  ret := avio_open_dyn_buf(@dyn_buf);
  if ret < 0 then
  begin
    avio_closep(@pb);
    Result := nil;
    Exit;
  end;
  ret := avio_read(pb, @buf[0], SizeOf(buf));
  while ret > 0 do
    avio_write(dyn_buf, @buf[0], ret);
  avio_w8(dyn_buf, 0);
  avio_closep(@pb);

  ret := avio_close_dyn_buf(dyn_buf, @str);
  if ret < 0 then
    Result := nil
  else
    Result := str;
end;

function TCustomFFmpegOpt.get_ost_filters(o: POptionsContext; oc: PAVFormatContext; ost: POutputStream): PAnsiChar;
var
  st: PAVStream;
  filter, filter_script: PAnsiChar;
begin
  st := ost.st;
  filter := nil;
  filter_script := nil;

  MATCH_PER_STREAM_OPT_filter_scripts_str(o, oc, st, @filter_script);
  MATCH_PER_STREAM_OPT_filters_str(o, oc, st, @filter);

  if Assigned(filter_script) and Assigned(filter) then
  begin
    RaiseException('Both -filter and -filter_script set for output stream #%d:%d.',
                  [Fnb_output_files, st.index]);
    //exit_program(1);
  end;

  if Assigned(filter_script) then
    Result := read_file(filter_script)
  else if Assigned(filter) then
    Result := av_strdup(filter)
  else if st.codec.codec_type = AVMEDIA_TYPE_VIDEO then
    Result := av_strdup('null')
  else
    Result := av_strdup('anull');
end;

function TCustomFFmpegOpt.new_video_stream(o: POptionsContext; oc: PAVFormatContext; source_index: Integer): POutputStream;
var
  st: PAVStream;
  ost: POutputStream;
  video_enc: PAVCodecContext;
  frame_rate, frame_aspect_ratio: PAnsiChar;

  p: PAnsiChar;
  frame_size: PAnsiChar;
  frame_pix_fmt: PAnsiChar;
  intra_matrix, inter_matrix: PAnsiChar;
  do_pass: Integer;
  i: Integer;
  ratio{q}: TAVRational;
  start, end_, q: Integer;
  e: Integer;
begin
  frame_rate := nil;
  frame_aspect_ratio := nil;
  ost := new_output_stream(o, oc, AVMEDIA_TYPE_VIDEO, source_index);
  st  := ost.st;
  video_enc := st.codec;

  Result := ost;

  MATCH_PER_STREAM_OPT_frame_rates_str(o, oc, st, @frame_rate);
  if Assigned(frame_rate) and (av_parse_video_rate(@ost.frame_rate, frame_rate) < 0) then
  begin
    RaiseException('Invalid framerate value: %s', [string(frame_rate)]);
    //exit_program(1);
  end;

  MATCH_PER_STREAM_OPT_frame_aspect_ratios_str(o, oc, st, @frame_aspect_ratio);
  if Assigned(frame_aspect_ratio) then
  begin
    if (av_parse_ratio(@ratio, frame_aspect_ratio, 255, 0, nil) < 0) or
       (ratio.num <= 0) or (ratio.den <= 0) then
    begin
      RaiseException('Invalid aspect ratio: %s', [string(frame_aspect_ratio)]);
      //exit_program(1);
    end;
    ost.frame_aspect_ratio := ratio;
  end;

  if ost.stream_copy <> 0 then
  begin
    MATCH_PER_STREAM_OPT_copy_initial_nonkeyframes_i(o, oc ,st, @ost.copy_initial_nonkeyframes);
    Exit;
  end;

  p := nil;
  frame_size := nil;
  frame_pix_fmt := nil;
  intra_matrix := nil;
  inter_matrix := nil;
  do_pass := 0;

  MATCH_PER_STREAM_OPT_frame_sizes_str(o, oc, st, @frame_size);
  if Assigned(frame_size) and (av_parse_video_size(@video_enc.width, @video_enc.height, frame_size) < 0) then
  begin
    RaiseException('Invalid frame size: %s.', [string(frame_size)]);
    //exit_program(1);
  end;

  video_enc.bits_per_raw_sample := Fframe_bits_per_raw_sample;
  MATCH_PER_STREAM_OPT_frame_pix_fmts_str(o, oc, st, @frame_pix_fmt);
  if Assigned(frame_pix_fmt) and (frame_pix_fmt^ = '+') then
  begin
    ost.keep_pix_fmt := 1;
    Inc(frame_pix_fmt);
    if frame_pix_fmt^ = #0 then
      frame_pix_fmt := nil;
  end;
  if Assigned(frame_pix_fmt) then
  begin
    video_enc.pix_fmt := av_get_pix_fmt(frame_pix_fmt);
    if video_enc.pix_fmt = AV_PIX_FMT_NONE then
    begin
      RaiseException('Unknown pixel format requested: %s.', [string(frame_pix_fmt)]);
      //exit_program(1);
    end;
  end;
  st.sample_aspect_ratio := video_enc.sample_aspect_ratio;

  if Fintra_only <> 0 then
    video_enc.gop_size := 0;
  MATCH_PER_STREAM_OPT_intra_matrices_str(o, oc, st, @intra_matrix);
  if Assigned(intra_matrix) then
  begin
    video_enc.intra_matrix := av_mallocz(SizeOf(video_enc.intra_matrix^) * 64);
    if not Assigned(video_enc.intra_matrix) then
    begin
      RaiseException('Could not allocate memory for intra matrix.');
      //exit_program(1);
    end;
    parse_matrix_coeffs(video_enc.intra_matrix, intra_matrix);
  end;
  MATCH_PER_STREAM_OPT_inter_matrices_str(o, oc, st, @inter_matrix);
  if Assigned(inter_matrix) then
  begin
    video_enc.inter_matrix := av_mallocz(SizeOf(video_enc.inter_matrix^) * 64);
    if not Assigned(video_enc.inter_matrix) then
    begin
      RaiseException('Could not allocate memory for inter matrix.');
      //exit_program(1);
    end;
    parse_matrix_coeffs(video_enc.inter_matrix, inter_matrix);
  end;

  MATCH_PER_STREAM_OPT_rc_overrides_str(o, oc, st, @p);
  i := 0;
  while Assigned(p) do
  begin
    e := my_sscanf(p, '%d,%d,%d', @start, @end_, @q);
    if e <> 3 then
    begin
      RaiseException('error parsing rc_override');
      //exit_program(1);
    end;
    (* FIXME realloc failure *)
    video_enc.rc_override := av_realloc(video_enc.rc_override, SizeOf(TRcOverride) * (i + 1));
    PtrIdx(video_enc.rc_override, i).start_frame := start;
    PtrIdx(video_enc.rc_override, i).end_frame   := end_;
    if q > 0 then
    begin
      PtrIdx(video_enc.rc_override, i).qscale         := q;
      PtrIdx(video_enc.rc_override, i).quality_factor := 1.0;
    end
    else
    begin
      PtrIdx(video_enc.rc_override, i).qscale         := 0;
      PtrIdx(video_enc.rc_override, i).quality_factor := -q / 100.0;
    end;
    Inc(i);
    p := my_strchr(p, '/');
    if Assigned(p) then
      Inc(p);
  end;
  video_enc.rc_override_count := i;
  video_enc.intra_dc_precision := Fintra_dc_precision - 8;

  if Fdo_psnr <> 0 then
    video_enc.flags := video_enc.flags or CODEC_FLAG_PSNR;

  (* two pass mode *)
  MATCH_PER_STREAM_OPT_pass_i(o, oc, st, @do_pass);
  if do_pass <> 0 then
  begin
    if (do_pass and 1) <> 0 then
    begin
      video_enc.flags := video_enc.flags or CODEC_FLAG_PASS1;
      av_dict_set(@ost.opts, 'flags', '+pass1', AV_DICT_APPEND);
    end;
    if (do_pass and 2) <> 0 then
    begin
      video_enc.flags := video_enc.flags or CODEC_FLAG_PASS2;
      av_dict_set(@ost.opts, 'flags', '+pass2', AV_DICT_APPEND);
    end;
  end;

  MATCH_PER_STREAM_OPT_passlogfiles_str(o, oc, st, @ost.logfile_prefix);
  if Assigned(ost.logfile_prefix) then
  begin
    ost.logfile_prefix := av_strdup(ost.logfile_prefix);
    if not Assigned(ost.logfile_prefix) then
    begin
      RaiseException('av_strdup() failed');
      //exit_program(1);
    end;
  end;

  MATCH_PER_STREAM_OPT_forced_key_frames_str(o, oc, st, @ost.forced_keyframes);
  if Assigned(ost.forced_keyframes) then
    ost.forced_keyframes := av_strdup(ost.forced_keyframes);

  MATCH_PER_STREAM_OPT_force_fps_i(o, oc, st, @ost.force_fps);

  ost.top_field_first := -1;
  MATCH_PER_STREAM_OPT_top_field_first_i(o, oc, st, @ost.top_field_first);


  ost.avfilter := get_ost_filters(o, oc, ost);
  if not Assigned(ost.avfilter) then
  begin
    RaiseException('get_ost_filters() failed');
    //exit_program(1);
  end;
end;

function TCustomFFmpegOpt.new_audio_stream(o: POptionsContext; oc: PAVFormatContext; source_index: Integer): POutputStream;
var
  n: Integer;
  st: PAVStream;
  ost: POutputStream;
  audio_enc: PAVCodecContext;
  sample_fmt: PAnsiChar;
  map: PAudioChannelMap;
  ist: PInputStream;
begin
  ost := new_output_stream(o, oc, AVMEDIA_TYPE_AUDIO, source_index);
  st  := ost.st;

  audio_enc := st.codec;
  audio_enc.codec_type := AVMEDIA_TYPE_AUDIO;

  Result := ost;

  if ost.stream_copy <> 0 then
    Exit;

  sample_fmt := nil;

  MATCH_PER_STREAM_OPT_audio_channels_i(o, oc, st, @audio_enc.channels);

  MATCH_PER_STREAM_OPT_sample_fmts_str(o, oc, st, @sample_fmt);
  if Assigned(sample_fmt) then
  begin
    audio_enc.sample_fmt := av_get_sample_fmt(sample_fmt);
    if audio_enc.sample_fmt = AV_SAMPLE_FMT_NONE then
    begin
      RaiseException('Invalid sample format "%s"', [string(sample_fmt)]);
      //exit_program(1);
    end;
  end;

  MATCH_PER_STREAM_OPT_audio_sample_rate_i(o, oc, st, @audio_enc.sample_rate);

  MATCH_PER_STREAM_OPT_apad_str(o, oc, st, @ost.apad);
  ost.apad := av_strdup(ost.apad);

  ost.avfilter := get_ost_filters(o, oc, ost);
  if not Assigned(ost.avfilter) then
  begin
    RaiseException('get_ost_filters() failed');
    //exit_program(1);
  end;

  (* check for channel mapping for this audio stream *)
  for n := 0 to o.nb_audio_channel_maps - 1 do
  begin
    map := PtrIdx(o.audio_channel_maps, n);
    ist := PPtrIdx(Finput_streams, ost.source_index);
    if ((map.channel_idx = -1) or ((ist.file_index = map.file_idx) and (ist.st.index = map.stream_idx))) and
       ((map.ofile_idx   = -1) or (ost.file_index  = map.ofile_idx)) and
       ((map.ostream_idx = -1) or (ost.st.index    = map.ostream_idx)) then
    begin
      if ost.audio_channels_mapped < Length(ost.audio_channels_map) then
      begin
        ost.audio_channels_map[ost.audio_channels_mapped] := map.channel_idx;
        Inc(ost.audio_channels_mapped);
      end
      else
        FFLogger.Log(Self, llFatal, 'Max channel mapping for output %d.%d reached',
                        [ost.file_index, ost.st.index]);
    end;
  end;
end;

function TCustomFFmpegOpt.new_data_stream(o: POptionsContext; oc: PAVFormatContext; source_index: Integer): POutputStream;
var
  ost: POutputStream;
begin
  ost := new_output_stream(o, oc, AVMEDIA_TYPE_DATA, source_index);
  if ost.stream_copy = 0 then
  begin
    RaiseException('Data stream encoding not supported yet (only streamcopy)');
    //exit_program(1);
  end;
  Result := ost;
end;

function TCustomFFmpegOpt.new_attachment_stream(o: POptionsContext; oc: PAVFormatContext; source_index: Integer): POutputStream;
var
  ost: POutputStream;
begin
  ost := new_output_stream(o, oc, AVMEDIA_TYPE_ATTACHMENT, source_index);
  ost.stream_copy := 1;
  ost.finished := 1;
  Result := ost;
end;

function TCustomFFmpegOpt.new_subtitle_stream(o: POptionsContext; oc: PAVFormatContext; source_index: Integer): POutputStream;
var
  st: PAVStream;
  ost: POutputStream;
  subtitle_enc: PAVCodecContext;
  frame_size: PAnsiChar;
begin
  ost := new_output_stream(o, oc, AVMEDIA_TYPE_SUBTITLE, source_index);
  st  := ost.st;
  subtitle_enc := st.codec;

  subtitle_enc.codec_type := AVMEDIA_TYPE_SUBTITLE;

  Result := ost;

  MATCH_PER_STREAM_OPT_copy_initial_nonkeyframes_i(o, oc, st, @ost.copy_initial_nonkeyframes);

  if ost.stream_copy <> 0 then
    Exit;

  frame_size := nil;

  MATCH_PER_STREAM_OPT_frame_sizes_str(o, oc, st, @frame_size);
  if Assigned(frame_size) and (av_parse_video_size(@subtitle_enc.width, @subtitle_enc.height, frame_size) < 0) then
  begin
    RaiseException('Invalid frame size: %s.', [frame_size]);
    //exit_program(1);
  end;
end;

(* arg format is 'output-stream-index:streamid-value'. *)
function TCustomFFmpegOpt.opt_streamid(optctx: Pointer; opt, arg: PAnsiChar): Integer;
var
  o: POptionsContext;
  idx: string;
  val: string;
  idx_i: Integer;
  val_i: Integer;
begin
  val := string(arg);
  idx := Fetch(val, ':');
  idx_i := StrToIntDef(idx, Low(Integer));
  val_i := StrToIntDef(val, Low(Integer));
  if (idx_i = Low(Integer)) or (val_i = Low(Integer)) then
  begin
    GOptionError := Format('Invalid value "%s" for option "%s", required syntax is "index:value"', [string(arg), string(opt)]);
    FFLogger.Log(Self, llError, GOptionError);
    Result := AVERROR_EINVAL
    //exit_program(1);
  end
  else if (idx_i < 0) or (idx_i > MAX_STREAMS - 1) then
  begin
    GOptionError := Format('The value for "%s" was "%s" which is not within %d - %d',
                          ['streamid', idx, 0, MAX_STREAMS - 1]);
    FFLogger.Log(Self, llError, GOptionError);
    Result := AVERROR_EINVAL;
  end
  else if val_i < 0 then
  begin
    GOptionError := Format('The value for "%s" was "%s" which is not within %d - %d',
                          ['streamid', idx, 0, MaxInt]);
    FFLogger.Log(Self, llError, GOptionError);
    Result := AVERROR_EINVAL;
  end
  else
  begin
    o := optctx;
    o.streamid_map := grow_array(o.streamid_map, SizeOf(o.streamid_map^), @o.nb_streamid_map, idx_i + 1);
    PtrIdx(o.streamid_map, idx_i)^ := val_i;
    Result := 0;
  end;
end;

function copy_chapters(ifile: PInputFile; ofile: POutputFile; copy_metadata: Integer): Integer;
var
  ic: PAVFormatContext;
  oc: PAVFormatContext;
  tmp: PPAVChapter;
  i: Integer;
  in_ch, out_ch: PAVChapter;
  start_time, ts_off, rt: Int64;
begin
  ic := ifile.ctx;
  oc := ofile.ctx;

  tmp := av_realloc_f(oc.chapters, ic.nb_chapters + oc.nb_chapters, SizeOf(oc.chapters^));
  if not Assigned(tmp) then
  begin
    Result := AVERROR_ENOMEM;
    Exit;
  end;
  oc.chapters := tmp;

  for i := 0 to Integer(ic.nb_chapters) - 1 do
  begin
    in_ch := PPtrIdx(ic.chapters, i);
    if ofile.start_time = AV_NOPTS_VALUE then
      start_time := 0
    else
      start_time := ofile.start_time;
    ts_off := av_rescale_q(start_time - ifile.ts_offset, AV_TIME_BASE_Q, in_ch.time_base);
    if ofile.recording_time = High(Int64) then
      rt := High(Int64)
    else
      rt := av_rescale_q(ofile.recording_time, AV_TIME_BASE_Q, in_ch.time_base);

    if in_ch.eend < ts_off then
      Continue;
    if (rt <> High(Int64)) and (in_ch.start > rt + ts_off) then
      Break;

    out_ch := av_mallocz(SizeOf(TAVChapter));
    if not Assigned(out_ch) then
    begin
      Result := AVERROR_ENOMEM;
      Exit;
    end;

    out_ch.id        := in_ch.id;
    out_ch.time_base := in_ch.time_base;
    if in_ch.start - ts_off > 0 then
      out_ch.start   := in_ch.start - ts_off
    else
      out_ch.start   := 0;
    if rt < in_ch.eend - ts_off then
      out_ch.eend    := rt
    else
      out_ch.eend    := in_ch.eend - ts_off;

    if copy_metadata <> 0 then
      av_dict_copy(@out_ch.metadata, in_ch.metadata, 0);

    PtrIdx(oc.chapters, oc.nb_chapters)^ := out_ch;
    Inc(oc.nb_chapters);
  end;
  Result := 0;
end;

const
  PIX_FMTS_MJPEG: array[0..4] of TAVPixelFormat = (
    AV_PIX_FMT_YUVJ420P, AV_PIX_FMT_YUVJ422P, AV_PIX_FMT_YUV420P, AV_PIX_FMT_YUV422P, AV_PIX_FMT_NONE);
  PIX_FMTS_LJPEG: array[0..7] of TAVPixelFormat = (
    AV_PIX_FMT_YUVJ420P, AV_PIX_FMT_YUVJ422P, AV_PIX_FMT_YUVJ444P, AV_PIX_FMT_YUV420P,
    AV_PIX_FMT_YUV422P, AV_PIX_FMT_YUV444P, AV_PIX_FMT_BGRA, AV_PIX_FMT_NONE);

(****** from ffmpeg_filter.c **************)
function choose_pixel_fmt(st: PAVStream; codec: PAVCodec; target: TAVPixelFormat): TAVPixelFormat;
var
  p: PAVPixelFormat;
  desc: PAVPixFmtDescriptor;
  has_alpha: Integer;
  best: TAVPixelFormat;
begin
  if Assigned(codec) and Assigned(codec.pix_fmts) then
  begin
    p := codec.pix_fmts;
    desc := av_pix_fmt_desc_get(target);
    if Assigned(desc) then
      has_alpha := Ord((desc.nb_components mod 2) = 0)
    else
      has_alpha := 0;
    best := AV_PIX_FMT_NONE;
    if st.codec.strict_std_compliance <= FF_COMPLIANCE_UNOFFICIAL then
    begin
      if st.codec.codec_id = AV_CODEC_ID_MJPEG then
        p := @PIX_FMTS_MJPEG[0]
      else if st.codec.codec_id = AV_CODEC_ID_LJPEG then
        p := @PIX_FMTS_LJPEG[0];
    end;
    while p^ <> AV_PIX_FMT_NONE do
    begin
      best := avcodec_find_best_pix_fmt_of_2(best, p^, target, has_alpha, nil);
      if p^ = target then
        Break;
      Inc(p);
    end;
    if p^ = AV_PIX_FMT_NONE then
    begin
      if target <> AV_PIX_FMT_NONE then
        av_log(nil, AV_LOG_WARNING,
               'Incompatible pixel format "%s" for codec "%s", auto-selecting format "%s"'#10,
               av_get_pix_fmt_name(target),
               codec.name,
               av_get_pix_fmt_name(best));
      Result := best;
      Exit;
    end;
  end;
  Result := target;
end;

(****** from ffmpeg_filter.c **************)
procedure choose_sample_fmt(st: PAVStream; codec: PAVCodec);
var
  p: PAVSampleFormat;
begin
  if Assigned(codec) and Assigned(codec.sample_fmts) then
  begin
    p := codec.sample_fmts;
    while p^ <> AV_SAMPLE_FMT_NONE do
    begin
      if p^ = st.codec.sample_fmt then
        Break;
      Inc(p);
    end;
    if p^ = AV_SAMPLE_FMT_NONE then
    begin
      if ((codec.capabilities and CODEC_CAP_LOSSLESS) <> 0) and
        (Integer(av_get_sample_fmt_name(st.codec.sample_fmt)) > Integer(av_get_sample_fmt_name(codec.sample_fmts^))) then
        av_log(nil, AV_LOG_ERROR, 'Conversion will not be lossless.'#10);
      if Assigned(av_get_sample_fmt_name(st.codec.sample_fmt)) then
        av_log(nil, AV_LOG_WARNING,
               'Incompatible sample format "%s" for codec "%s", auto-selecting format "%s"'#10,
               av_get_sample_fmt_name(st.codec.sample_fmt),
               codec.name,
               av_get_sample_fmt_name(codec.sample_fmts^));
      st.codec.sample_fmt := codec.sample_fmts^;
    end;
  end;
end;

(****** from ffmpeg_filter.c **************)
function choose_pix_fmts(ost: POutputStream): PAnsiChar;
var
  strict_dict: PAVDictionaryEntry;
  p: PAVPixelFormat;
  s: PAVIOContext;
  ret: PAnsiChar;
  len: Integer;
  name: PAnsiChar;
begin
  strict_dict := av_dict_get(ost.opts, 'strict', nil, 0);
  if Assigned(strict_dict) then
    // used by choose_pixel_fmt() and below
    av_opt_set(ost.st.codec, 'strict', strict_dict.value, 0);

  if ost.keep_pix_fmt <> 0 then
  begin
    if Assigned(ost.filter) then
      avfilter_graph_set_auto_convert(ost.filter.graph.graph,
                                      Ord(AVFILTER_AUTO_CONVERT_NONE));
    if ost.st.codec.pix_fmt = AV_PIX_FMT_NONE then
    begin
      Result := nil;
      Exit;
    end;
    Result := av_strdup(av_get_pix_fmt_name(ost.st.codec.pix_fmt));
    Exit;
  end;
  if ost.st.codec.pix_fmt <> AV_PIX_FMT_NONE then
    Result := av_strdup(av_get_pix_fmt_name(choose_pixel_fmt(ost.st, ost.enc, ost.st.codec.pix_fmt)))
  else if Assigned(ost.enc) and Assigned(ost.enc.pix_fmts) then
  begin
    s := nil;

    if avio_open_dyn_buf(@s) < 0 then
    begin
      raise FFmpegException.Create('avio_open_dyn_buf() failed');
      //exit_program(1);
    end;

    p := ost.enc.pix_fmts;
    if ost.st.codec.strict_std_compliance <= FF_COMPLIANCE_UNOFFICIAL then
    begin
      if ost.st.codec.codec_id = AV_CODEC_ID_MJPEG then
        p := @PIX_FMTS_MJPEG[0]
      else if ost.st.codec.codec_id = AV_CODEC_ID_LJPEG then
        p := @PIX_FMTS_LJPEG[0];
    end;

    while p^ <> AV_PIX_FMT_NONE do
    begin
      name := av_get_pix_fmt_name(p^);
      avio_printf(s, '%s|', name);
      Inc(p);
    end;
    len := avio_close_dyn_buf(s, @ret);
    ret[len - 1] := #0;
    Result := ret;
  end
  else
    Result := nil;
end;

(* Define a function for building a string containing a list of
 * allowed formats. *)
(*
#define DEF_CHOOSE_FORMAT(type, var, supported_list, none, get_name)           \
static char *choose_ ## var ## s(OutputStream *ost)                            \
{                                                                              \
    if (ost->st->codec->var != none) {                                         \
        get_name(ost->st->codec->var);                                         \
        return av_strdup(name);                                                \
    } else if (ost->enc && ost->enc->supported_list) {                         \
        const type *p;                                                         \
        AVIOContext *s = NULL;                                                 \
        uint8_t *ret;                                                          \
        int len;                                                               \
                                                                               \
        if (avio_open_dyn_buf(&s) < 0)                                         \
            exit_program(1);                                                   \
                                                                               \
        for (p = ost->enc->supported_list; *p != none; p++) {                  \
            get_name(*p);                                                      \
            avio_printf(s, "%s|", name);                                       \
        }                                                                      \
        len = avio_close_dyn_buf(s, &ret);                                     \
        ret[len - 1] = 0;                                                      \
        return ret;                                                            \
    } else                                                                     \
        return NULL;                                                           \
}
*)

// DEF_CHOOSE_FORMAT(enum AVPixelFormat, pix_fmt, pix_fmts, AV_PIX_FMT_NONE,
//                   GET_PIX_FMT_NAME)
//#define GET_PIX_FMT_NAME(pix_fmt)\
//    const char *name = av_get_pix_fmt_name(pix_fmt);
//#define DEF_CHOOSE_FORMAT(type, var, supported_list, none, get_name)
{
  choose_pix_fmts()
}

//DEF_CHOOSE_FORMAT(enum AVSampleFormat, sample_fmt, sample_fmts,
//                  AV_SAMPLE_FMT_NONE, GET_SAMPLE_FMT_NAME)
//#define GET_SAMPLE_FMT_NAME(sample_fmt)\
//    const char *name = av_get_sample_fmt_name(sample_fmt)
//#define DEF_CHOOSE_FORMAT(type, var, supported_list, none, get_name)
function choose_sample_fmts{choose_##var##s}(ost: POutputStream): PAnsiChar;
var
  name: PAnsiChar;
  p: PAVSampleFormat;{P##type##}
  s: PAVIOContext;
  ret: PAnsiChar;
  len: Integer;
begin
  if ost.st.codec.sample_fmt{.##var##} <> AV_SAMPLE_FMT_NONE{##none##} then
  begin
    {!!get_name!!}
    name := av_get_sample_fmt_name(ost.st.codec.sample_fmt{.##var##});
    Result := av_strdup(name);
  end
  else if Assigned(ost.enc) and Assigned(ost.enc.sample_fmts{.##supported_list##}) then
  begin
    s := nil;

    if avio_open_dyn_buf(@s) < 0 then
    begin
      raise FFmpegException.Create('avio_open_dyn_buf() failed');
      //exit_program(1);
    end;

    p := ost.enc.sample_fmts{.##supported_list##};
    while p^ <> AV_SAMPLE_FMT_NONE{##none##} do
    begin
      {!!get_name!!}
      name := av_get_sample_fmt_name(p^);
      avio_printf(s, '%s|', name);
      Inc(p);
    end;
    len := avio_close_dyn_buf(s, @ret);
    ret[len - 1] := #0;
    Result := ret;
  end
  else
    Result := nil;
end;

//DEF_CHOOSE_FORMAT(int, sample_rate, supported_samplerates, 0,
//                  GET_SAMPLE_RATE_NAME)
//#define GET_SAMPLE_RATE_NAME(rate)\
//    char name[16];\
//    snprintf(name, sizeof(name), "%d", rate);
//#define DEF_CHOOSE_FORMAT(type, var, supported_list, none, get_name)
function choose_sample_rates{choose_##var##s}(ost: POutputStream): PAnsiChar;
var
  name: array[0..15] of AnsiChar;
  p: PInteger;{P##type##}
  s: PAVIOContext;
  ret: PAnsiChar;
  len: Integer;
begin
  if ost.st.codec.sample_rate{.##var##} <> 0{##none##} then
  begin
    {!!get_name!!}
    my_snprintf(name, SizeOf(name), '%d', ost.st.codec.sample_rate{.##var##});
    Result := av_strdup(name);
  end
  else if Assigned(ost.enc) and Assigned(ost.enc.supported_samplerates{.##supported_list##}) then
  begin
    s := nil;

    if avio_open_dyn_buf(@s) < 0 then
    begin
      raise FFmpegException.Create('avio_open_dyn_buf() failed');
      //exit_program(1);
    end;

    p := ost.enc.supported_samplerates{.##supported_list##};
    while p^ <> 0{##none##} do
    begin
      {!!get_name!!}
      my_snprintf(name, SizeOf(name), '%d', p^);
      avio_printf(s, '%s|', name);
      Inc(p);
    end;
    len := avio_close_dyn_buf(s, @ret);
    ret[len - 1] := #0;
    Result := ret;
  end
  else
    Result := nil;
end;

//DEF_CHOOSE_FORMAT(uint64_t, channel_layout, channel_layouts, 0,
//                  GET_CH_LAYOUT_NAME)
//#define GET_CH_LAYOUT_NAME(ch_layout)\
//    char name[16];\
//    snprintf(name, sizeof(name), "0x%"PRIx64, ch_layout);
//#define DEF_CHOOSE_FORMAT(type, var, supported_list, none, get_name)
function choose_channel_layouts{choose_##var##s}(ost: POutputStream): PAnsiChar;
var
  name: array[0..31] of AnsiChar;
  p: PInt64;{P##type##}
  s: PAVIOContext;
  ret: PAnsiChar;
  len: Integer;
{$IF Defined(VCL_60) Or Defined(VCL_70)}
  I64: Int64;
  Lo, Hi: Integer;
{$IFEND}
begin
  if ost.st.codec.channel_layout{.##var##} <> 0{##none##} then
  begin
    {!!get_name!!}
{$IF Defined(VCL_60) Or Defined(VCL_70)}
    // Int64Rec on non-local variables will cause Internal error(URW699) in Delphi 6
    I64 := ost.st.codec.channel_layout;
    Lo := Int64Rec(I64).Lo;
    Hi := Int64Rec(I64).Hi;
{$IFEND}
    // #define PRIx64 "llx"
    my_snprintf(name, SizeOf(name),
{$IFDEF MSWINDOWS}
                // '%lld/%llx' works on Vista or above, '%I64d/%I64x' works always
                '0x%I64x',
{$ELSE}
                '0x%llx',
{$ENDIF}
{$IF Defined(VCL_60) Or Defined(VCL_70)}
                // http://qc.embarcadero.com/wc/qcmain.aspx?d=6338
                // Int64 and Single are incorrectly passed to cdecl/varargs functions
                Lo, Hi);
{$ELSE}
                ost.st.codec.channel_layout{.##var##});
{$IFEND}
    Result := av_strdup(name);
  end
  else if Assigned(ost.enc) and Assigned(ost.enc.channel_layouts{.##supported_list##}) then
  begin
    s := nil;

    if avio_open_dyn_buf(@s) < 0 then
    begin
      raise FFmpegException.Create('avio_open_dyn_buf() failed');
      //exit_program(1);
    end;

    p := ost.enc.channel_layouts{.##supported_list##};
    while p^ <> 0{##none##} do
    begin
      {!!get_name!!}
{$IF Defined(VCL_60) Or Defined(VCL_70)}
      // Int64Rec on non-local variables will cause Internal error(URW699) in Delphi 6
      I64 := p^;
      Lo := Int64Rec(I64).Lo;
      Hi := Int64Rec(I64).Hi;
{$IFEND}
      // #define PRIx64 "llx"
      my_snprintf(name, SizeOf(name),
{$IFDEF MSWINDOWS}
                  // '%lld/%llx' works on Vista or above, '%I64d/%I64x' works always
                  '0x%I64x',
{$ELSE}
                  '0x%llx',
{$ENDIF}
{$IF Defined(VCL_60) Or Defined(VCL_70)}
                  // http://qc.embarcadero.com/wc/qcmain.aspx?d=6338
                  // Int64 and Single are incorrectly passed to cdecl/varargs functions
                  Lo, Hi);
{$ELSE}
                  p^);
{$IFEND}
      avio_printf(s, '%s|', name);
      Inc(p);
    end;
    len := avio_close_dyn_buf(s, @ret);
    ret[len - 1] := #0;
    Result := ret;
  end
  else
    Result := nil;
end;

(****** from ffmpeg_filter.c **************)
function TCustomFFmpegOpt.init_simple_filtergraph(ist: PInputStream; ost: POutputStream): PFilterGraph;
var
  fg: PFilterGraph;
begin
  fg := av_mallocz(SizeOf(fg^));

  if not Assigned(fg) then
  begin
    RaiseException('av_mallocz() failed');
    //exit_program(1);
  end;
  fg.index := Fnb_filtergraphs;

  fg.outputs := grow_array(fg.outputs, SizeOf(fg.outputs^), @fg.nb_outputs,
                           fg.nb_outputs + 1);
  fg.outputs^ := av_mallocz(SizeOf(fg.outputs^^));
  if not Assigned(fg.outputs^) then
  begin
    RaiseException('av_mallocz() failed');
    //exit_program(1);
  end;

  fg.outputs^^.ost   := ost;
  fg.outputs^^.graph := fg;

  ost.filter := fg.outputs^;

  fg.inputs := grow_array(fg.inputs, SizeOf(fg.inputs^), @fg.nb_inputs,
                          fg.nb_inputs + 1);
  fg.inputs^ := av_mallocz(SizeOf(fg.inputs^^));
  if not Assigned(fg.inputs^) then
  begin
    RaiseException('av_mallocz() failed');
    //exit_program(1);
  end;
  fg.inputs^^.ist   := ist;
  fg.inputs^^.graph := fg;

  ist.filters := grow_array(ist.filters, SizeOf(ist.filters^),
                            @ist.nb_filters, ist.nb_filters + 1);
  PtrIdx(ist.filters, ist.nb_filters - 1)^ := fg.inputs^;

  Ffiltergraphs := grow_array(Ffiltergraphs, SizeOf(Ffiltergraphs^),
                              @Fnb_filtergraphs, Fnb_filtergraphs + 1);
  PtrIdx(Ffiltergraphs, Fnb_filtergraphs - 1)^ := fg;

  result := fg;
end;

(****** from ffmpeg_filter.c **************)
procedure TCustomFFmpegOpt.init_input_filter(fg: PFilterGraph; fin: PAVFilterInOut);
var
  ist: PInputStream;
  ttype: TAVMediaType;
  i: Integer;
  s: PAVFormatContext;
  st: PAVStream;
  p, p1: PAnsiChar;
  file_idx: Integer;
  stream_type: TAVMediaType;
begin
  ist := nil;
  ttype := avfilter_pad_get_type(fin.filter_ctx.input_pads, fin.pad_idx);

  // TODO: support other filter types
  if (ttype <> AVMEDIA_TYPE_VIDEO) and (ttype <> AVMEDIA_TYPE_AUDIO) then
  begin
    RaiseException('Only video and audio filters supported currently.');
    //exit_program(1);
  end;

  if Assigned(fin.name) then
  begin
    st := nil;
    file_idx := my_strtol(fin.name, @p, 0);

    if (file_idx < 0) or (file_idx >= Fnb_input_files) then
    begin
      RaiseException('Invalid file index %d in filtergraph description %s.',
             [file_idx, string(fg.graph_desc)]);
      //exit_program(1);
    end;
    s := PPtrIdx(Finput_files, file_idx).ctx;

    for i := 0 to s.nb_streams - 1 do
    begin
      stream_type := PPtrIdx(s.streams, i).codec.codec_type;
      if (stream_type <> ttype) and
         not ((stream_type = AVMEDIA_TYPE_SUBTITLE) and
              (ttype = AVMEDIA_TYPE_VIDEO)) then (* sub2video hack *)
        Continue;
      if p^ = ':' then
        p1 := p + 1
      else
        p1 := p;
      if check_stream_specifier(s, PPtrIdx(s.streams, i), p1) = 1 then
      begin
        st := PPtrIdx(s.streams, i);
        Break;
      end;
    end;
    if not Assigned(st) then
    begin
      RaiseException('Stream specifier "%s" in filtergraph description %s ' +
             'matches no streams.', [string(p), string(fg.graph_desc)]);
      //exit_program(1);
    end;
    ist := PPtrIdx(Finput_streams, PPtrIdx(Finput_files, file_idx).ist_index + st.index);
  end
  else
  begin
    (* find the first unused stream of corresponding type *)
    for i := 0 to Fnb_input_streams - 1 do
    begin
      ist := PPtrIdx(Finput_streams, i);
      if (ist.st.codec.codec_type = ttype) and (ist.discard <> 0) then
        Break;
    end;
    if i = Fnb_input_streams then
    begin
      RaiseException('Cannot find a matching stream for ' +
             'unlabeled input pad %d on filter %s', [fin.pad_idx, string(fin.filter_ctx.name)]);
      //exit_program(1);
    end;
  end;
  Assert(Assigned(ist));

  ist.discard := 0;
  Inc(ist.decoding_needed);
  ist.st.discard := AVDISCARD_NONE;

  fg.inputs := grow_array(fg.inputs, SizeOf(fg.inputs^),
                         @fg.nb_inputs, fg.nb_inputs + 1);
  PtrIdx(fg.inputs, fg.nb_inputs - 1)^ := av_mallocz(SizeOf(fg.inputs^^));
  if not Assigned(PPtrIdx(fg.inputs, fg.nb_inputs - 1)) then
  begin
    RaiseException('av_mallocz() failed');
    //exit_program(1);
  end;
  PPtrIdx(fg.inputs, fg.nb_inputs - 1).ist   := ist;
  PPtrIdx(fg.inputs, fg.nb_inputs - 1).graph := fg;

  ist.filters := grow_array(ist.filters, SizeOf(ist.filters^),
                           @ist.nb_filters, ist.nb_filters + 1);
  PtrIdx(ist.filters, ist.nb_filters - 1)^ := PPtrIdx(fg.inputs, fg.nb_inputs - 1);
end;

(****** from ffmpeg_filter.c **************)
function insert_trim(start_time, duration: Int64;
                     last_filter: PPAVFilterContext; pad_idx: PInteger;
                     const filter_name: PAnsiChar): Integer;
var
  graph: PAVFilterGraph;
  ctx: PAVFilterContext;
  trim_filter: PAVFilter;
  type_: TAVMediaType;
  name: PAnsiChar;
  ret: Integer;
begin
  graph := last_filter^.graph;
  type_ := avfilter_pad_get_type(last_filter^.output_pads, pad_idx^);
  if type_ = AVMEDIA_TYPE_VIDEO then
    name := 'trim'
  else
    name := 'atrim';
  ret := 0;

  if (duration = High(Int64)) and (start_time = AV_NOPTS_VALUE) then
  begin
    Result := 0;
    Exit;
  end;

  trim_filter := avfilter_get_by_name(name);
  if not Assigned(trim_filter) then
  begin
    av_log(nil, AV_LOG_ERROR, '%s filter not present, cannot limit ' +
           'recording time.'#10, name);
    Result := AVERROR_FILTER_NOT_FOUND;
    Exit;
  end;

  ctx := avfilter_graph_alloc_filter(graph, trim_filter, filter_name);
  if not Assigned(ctx) then
  begin
    Result := AVERROR_ENOMEM;
    Exit;
  end;

  if duration <> High(Int64) then
    ret := av_opt_set_int(ctx, 'durationi', duration,
                              AV_OPT_SEARCH_CHILDREN);
  if (ret >= 0) and (start_time <> AV_NOPTS_VALUE) then
    ret := av_opt_set_int(ctx, 'starti', start_time,
                              AV_OPT_SEARCH_CHILDREN);
  if ret < 0 then
  begin
    av_log(ctx, AV_LOG_ERROR, 'Error configuring the %s filter'#10, name);
    Result := ret;
    Exit;
  end;

  ret := avfilter_init_str(ctx, nil);
  if ret < 0 then
  begin
    Result := ret;
    Exit;
  end;

  ret := avfilter_link(last_filter^, pad_idx^, ctx, 0);
  if ret < 0 then
  begin
    Result := ret;
    Exit;
  end;

  last_filter^ := ctx;
  pad_idx^     := 0;
  Result := 0;
end;

function TCustomFFmpegOpt.configure_output_video_filter(fg: PFilterGraph; ofilter: POutputFilter;
  fout: PAVFilterInOut): Integer;
var
  pix_fmts: PAnsiChar;
  ost: POutputStream;
  ofile: POutputFile;
  codec: PAVCodecContext;
  last_filter: PAVFilterContext;
  pad_idx: Integer;
  ret: Integer;
  name: array[0..255] of AnsiChar;
  args: array[0..255] of AnsiChar;
  filter: PAVFilterContext;
  sws_flags: Cardinal;
begin
  ost := ofilter.ost;
  ofile := PPtrIdx(Foutput_files, ost.file_index);
  codec := ost.st.codec;
  last_filter := fout.filter_ctx;
  pad_idx := fout.pad_idx;

  my_snprintf(name, SizeOf(name), 'output stream %d:%d', ost.file_index, ost.index);
  ret := avfilter_graph_create_filter(@ofilter.filter,
                                      avfilter_get_by_name('buffersink'),
                                      name, nil, nil, fg.graph);

  if ret < 0 then
  begin
    Result := ret;
    Exit;
  end;

  if (codec.width <> 0) or (codec.height <> 0) then
  begin
    sws_flags := ost.sws_flags;
    my_snprintf(args, SizeOf(args), '%d:%d:0x%X',
                codec.width,
                codec.height,
                sws_flags);
    my_snprintf(name, SizeOf(name), 'scaler for output stream %d:%d',
                ost.file_index, ost.index);
    ret := avfilter_graph_create_filter(@filter, avfilter_get_by_name('scale'),
                                        name, args, nil, fg.graph);
    if ret < 0 then
    begin
      Result := ret;
      Exit;
    end;
    ret := avfilter_link(last_filter, pad_idx, filter, 0);
    if ret < 0 then
    begin
      Result := ret;
      Exit;
    end;

    last_filter := filter;
    pad_idx := 0;
  end;

  pix_fmts := choose_pix_fmts(ost);
  if Assigned(pix_fmts) then
  begin
    my_snprintf(name, SizeOf(name), 'pixel format for output stream %d:%d',
                ost.file_index, ost.index);
    ret := avfilter_graph_create_filter(@filter,
                                        avfilter_get_by_name('format'),
                                        name{'format'}, pix_fmts, nil,
                                        fg.graph);
    av_freep(@pix_fmts);
    if ret < 0 then
    begin
      Result := ret;
      Exit;
    end;
    ret := avfilter_link(last_filter, pad_idx, filter, 0);
    if ret < 0 then
    begin
      Result := ret;
      Exit;
    end;

    last_filter := filter;
    pad_idx     := 0;
  end;

(*
  if (ost->frame_rate.num && 0) {
      AVFilterContext *fps;
      char args[255];

      snprintf(args, sizeof(args), "fps=%d/%d", ost->frame_rate.num,
               ost->frame_rate.den);
      snprintf(name, sizeof(name), "fps for output stream %d:%d",
               ost->file_index, ost->index);
      ret = avfilter_graph_create_filter(&fps, avfilter_get_by_name("fps"),
                                         name, args, NULL, fg->graph);
      if (ret < 0)
          return ret;

      ret = avfilter_link(last_filter, pad_idx, fps, 0);
      if (ret < 0)
          return ret;
      last_filter = fps;
      pad_idx = 0;
  }
*)

  my_snprintf(name, SizeOf(name), 'trim for output stream %d:%d',
           ost.file_index, ost.index);
  ret := insert_trim(ofile.start_time, ofile.recording_time,
                    @last_filter, @pad_idx, name);
  if ret < 0 then
  begin
    Result := ret;
    Exit;
  end;


  ret := avfilter_link(last_filter, pad_idx, ofilter.filter, 0);
  if ret < 0 then
  begin
    Result := ret;
    Exit;
  end;

  Result := 0;
end;

(****** from ffmpeg_filter.c **************)
(*
#define AUTO_INSERT_FILTER(opt_name, filter_name, arg) do {                 \
    AVFilterContext *filt_ctx;                                              \
                                                                            \
    av_log(NULL, AV_LOG_INFO, opt_name " is forwarded to lavfi "            \
           "similarly to -af " filter_name "=%s.\n", arg);                  \
                                                                            \
    ret = avfilter_graph_create_filter(&filt_ctx,                           \
                                       avfilter_get_by_name(filter_name),   \
                                       filter_name, arg, NULL, fg->graph);  \
    if (ret < 0)                                                            \
        return ret;                                                         \
                                                                            \
    ret = avfilter_link(last_filter, pad_idx, filt_ctx, 0);                 \
    if (ret < 0)                                                            \
        return ret;                                                         \
                                                                            \
    last_filter = filt_ctx;                                                 \
    pad_idx = 0;                                                            \
} while (0)
*)

(****** from ffmpeg_filter.c **************)
function TCustomFFmpegOpt.configure_output_audio_filter(fg: PFilterGraph; ofilter: POutputFilter;
  fout: PAVFilterInOut): Integer;
var
  ost: POutputStream;
  ofile: POutputFile;
  codec: PAVCodecContext;
  last_filter: PAVFilterContext;
  pad_idx: Integer;
  sample_fmts, sample_rates, channel_layouts: PAnsiChar;
  name: array[0..255] of AnsiChar;
  ret: Integer;
  i: Integer;
  pan_buf: TAVBPrint;
  filt_ctx: PAVFilterContext;
  ftformat: PAVFilterContext;
  args: array[0..255] of AnsiChar;
{$IF Defined(VCL_60) Or Defined(VCL_70)}
  I64: Int64;
  Lo, Hi: Integer;
{$IFEND}
begin
  ost := ofilter.ost;
  ofile := PPtrIdx(Foutput_files, ost.file_index);
  codec := ost.st.codec;
  last_filter := fout.filter_ctx;
  pad_idx := fout.pad_idx;
  my_snprintf(name, SizeOf(name), 'output stream %d:%d', ost.file_index, ost.index);
  ret := avfilter_graph_create_filter(@ofilter.filter,
                                      avfilter_get_by_name('abuffersink'),
                                      name, nil, nil, fg.graph);
  if ret < 0 then
  begin
    Result := ret;
    Exit;
  end;
  ret := av_opt_set_int(ofilter.filter, 'all_channel_counts', 1, AV_OPT_SEARCH_CHILDREN);
  if ret < 0 then
  begin
    Result := ret;
    Exit;
  end;

  if ost.audio_channels_mapped <> 0 then
  begin
    av_bprint_init(@pan_buf, 256, 8192);
{$IF Defined(VCL_60) Or Defined(VCL_70)}
    // Int64Rec on non-local variables will cause Internal error(URW699) in Delphi 6
    I64 := av_get_default_channel_layout(ost.audio_channels_mapped);
    Lo := Int64Rec(I64).Lo;
    Hi := Int64Rec(I64).Hi;
{$IFEND}
    // #define PRIx64 "llx"
    av_bprintf(@pan_buf,
{$IFDEF MSWINDOWS}
                // '%lld/%llx' works on Vista or above, '%I64d/%I64x' works always
                '0x%I64x',
{$ELSE}
                '0x%llx',
{$ENDIF}
{$IF Defined(VCL_60) Or Defined(VCL_70)}
                // http://qc.embarcadero.com/wc/qcmain.aspx?d=6338
                // Int64 and Single are incorrectly passed to cdecl/varargs functions
                Lo, Hi);
{$ELSE}
                av_get_default_channel_layout(ost.audio_channels_mapped));
{$IFEND}
    for i := 0 to ost.audio_channels_mapped - 1 do
      if ost.audio_channels_map[i] <> -1 then
        av_bprintf(@pan_buf, ':c%d=c%d', i, ost.audio_channels_map[i]);

    //AUTO_INSERT_FILTER("-map_channel", "pan", pan_buf.str);
//#define AUTO_INSERT_FILTER(opt_name, filter_name, arg) do {
    FFLogger.Log(Self, llInfo, '%s is forwarded to lavfi ' +
                 'similarly to -af %s=%s.', ['-map_channel', 'pan', string(pan_buf.str)]);

    ret := avfilter_graph_create_filter(@filt_ctx,
                                        avfilter_get_by_name('pan'),
                                        'pan', pan_buf.str, nil, fg.graph);
    if ret < 0 then
    begin
      Result := ret;
      Exit;
    end;

    ret := avfilter_link(last_filter, pad_idx, filt_ctx, 0);
    if ret < 0 then
    begin
      Result := ret;
      Exit;
    end;

    last_filter := filt_ctx;
    pad_idx := 0;

    av_bprint_finalize(@pan_buf, nil);
  end;

  if (codec.channels <> 0) and (codec.channel_layout = 0) then
    codec.channel_layout := av_get_default_channel_layout(codec.channels);

  sample_fmts     := choose_sample_fmts(ost);
  sample_rates    := choose_sample_rates(ost);
  channel_layouts := choose_channel_layouts(ost);
  if Assigned(sample_fmts) or Assigned(sample_rates) or Assigned(channel_layouts) then
  begin
    args[0] := #0;

    if Assigned(sample_fmts) then
      av_strlcatf(args, SizeOf(args), 'sample_fmts=%s:',
                  sample_fmts);
    if Assigned(sample_rates) then
      av_strlcatf(args, SizeOf(args), 'sample_rates=%s:',
                  sample_rates);
    if Assigned(channel_layouts) then
      av_strlcatf(args, SizeOf(args), 'channel_layouts=%s:',
                  channel_layouts);

    av_freep(@sample_fmts);
    av_freep(@sample_rates);
    av_freep(@channel_layouts);

    my_snprintf(name, SizeOf(name), 'audio format for output stream %d:%d',
                ost.file_index, ost.index);
    ret := avfilter_graph_create_filter(@ftformat,
                                        avfilter_get_by_name('aformat'),
                                        name, args, nil, fg.graph);
    if ret < 0 then
    begin
      Result := ret;
      Exit;
    end;

    ret := avfilter_link(last_filter, pad_idx, ftformat, 0);
    if ret < 0 then
    begin
      Result := ret;
      Exit;
    end;

    last_filter := ftformat;
    pad_idx := 0;
  end;

(*
  if (audio_volume != 256 && 0) {
      char args[256];

      snprintf(args, sizeof(args), "%f", audio_volume / 256.);
      AUTO_INSERT_FILTER("-vol", "volume", args);
  }
*)

  if Assigned(ost.apad) and (ofile.shortest <> 0) then
  begin
    for i := 0 to ofile.ctx.nb_streams - 1 do
      if PPtrIdx(ofile.ctx.streams, i).codec.codec_type = AVMEDIA_TYPE_VIDEO then
      begin
        my_snprintf(args, SizeOf(args), '%s', ost.apad);
        //AUTO_INSERT_FILTER('-apad', 'apad', args);
//#define AUTO_INSERT_FILTER(opt_name, filter_name, arg) do {                 \
        FFLogger.Log(Self, llInfo, '%s is forwarded to lavfi ' +
                     'similarly to -af %s=%s.', ['-apad', 'apad', string(ost.apad)]);

        ret := avfilter_graph_create_filter(@filt_ctx,
                                            avfilter_get_by_name('apad'),
                                            'apad', ost.apad, nil, fg.graph);
        if ret < 0 then
        begin
          Result := ret;
          Exit;
        end;

        ret := avfilter_link(last_filter, pad_idx, filt_ctx, 0);
        if ret < 0 then
        begin
          Result := ret;
          Exit;
        end;

        last_filter := filt_ctx;
        pad_idx := 0;

        Break;
      end;
  end;

  my_snprintf(name, SizeOf(name), 'trim for output stream %d:%d',
           ost.file_index, ost.index);
  ret := insert_trim(ofile.start_time, ofile.recording_time,
                    @last_filter, @pad_idx, name);
  if ret < 0 then
  begin
    Result := ret;
    Exit;
  end;

  ret := avfilter_link(last_filter, pad_idx, ofilter.filter, 0);
  if ret < 0 then
  begin
    Result := ret;
    Exit;
  end;

  Result := 0;
end;

(****** from ffmpeg_filter.c **************)
procedure DESCRIBE_FILTER_LINK(name: PPByte; inout: PAVFilterInOut; is_in: Integer);
var
  ctx: PAVFilterContext;
  pads: PAVFilterPad;
  nb_pads: Integer;
  pb: PAVIOContext;
begin
  ctx := inout.filter_ctx;
  if is_in <> 0 then
  begin
    pads := ctx.input_pads;
    nb_pads := ctx.nb_inputs;
  end
  else
  begin
    pads := ctx.output_pads;
    nb_pads := ctx.nb_outputs;
  end;

  if avio_open_dyn_buf(@pb) < 0 then
  begin
    raise FFmpegException.Create('avio_open_dyn_buf() failed');
    //exit_program(1);
  end;
  avio_printf(pb, '%s', ctx.filter.name);
  if nb_pads > 1 then
    avio_printf(pb, ':%s', avfilter_pad_get_name(pads, inout.pad_idx));
  avio_w8(pb, 0);
  avio_close_dyn_buf(pb, name);
end;

(****** from ffmpeg_filter.c **************)
function TCustomFFmpegOpt.configure_output_filter(fg: PFilterGraph; ofilter: POutputFilter; fout: PAVFilterInOut): Integer;
begin
  av_freep(@ofilter.name);
  DESCRIBE_FILTER_LINK(@ofilter.name, fout, 0);

  case avfilter_pad_get_type(fout.filter_ctx.output_pads, fout.pad_idx) of
    AVMEDIA_TYPE_VIDEO: Result := configure_output_video_filter(fg, ofilter, fout);
    AVMEDIA_TYPE_AUDIO: Result := configure_output_audio_filter(fg, ofilter, fout);
  else
    raise FFmpegException.Create('Never occur');
  end;
end;

(****** from ffmpeg_filter.c **************)
function TCustomFFmpegOpt.sub2video_prepare(ist: PInputStream): Integer;
var
  avf: PAVFormatContext;
  i, w, h: Integer;
begin
  avf := PPtrIdx(Finput_files, ist.file_index).ctx;

  (* Compute the size of the canvas for the subtitles stream.
     If the subtitles codec has set a size, use it. Otherwise use the
     maximum dimensions of the video streams in the same file. *)
  w := ist.st.codec.width;
  h := ist.st.codec.height;
  if (w = 0) or (h = 0) then
  begin
    for i := 0 to avf.nb_streams - 1 do
    begin
      if PPtrIdx(avf.streams, i).codec.codec_type = AVMEDIA_TYPE_VIDEO then
      begin
        if w < PPtrIdx(avf.streams, i).codec.width then
          w := PPtrIdx(avf.streams, i).codec.width;
        if h < PPtrIdx(avf.streams, i).codec.height then
          h := PPtrIdx(avf.streams, i).codec.height;
      end;
    end;
    if (w = 0) or (h = 0) then
    begin
      if w < 720 then
        w := 720;
      if h < 576 then
        h := 576;
    end;
    av_log(avf, AV_LOG_INFO, 'sub2video: using %dx%d canvas'#10, w, h);
  end;
  ist.sub2video.w := w;
  ist.st.codec.width := w;
  ist.resample_width := w;
  ist.sub2video.h := h;
  ist.st.codec.height := h;
  ist.resample_height := h;

  (* rectangles are AV_PIX_FMT_PAL8, but we have no guarantee that the
     palettes for all rectangles are identical or compatible *)
  ist.st.codec.pix_fmt := AV_PIX_FMT_RGB32;
  ist.resample_pix_fmt := Ord(AV_PIX_FMT_RGB32);

  ist.sub2video.frame := av_frame_alloc();
  if not Assigned(ist.sub2video.frame) then
  begin
    Result := AVERROR_ENOMEM;
    Exit;
  end;
  Result := 0;
end;

(****** from ffmpeg_filter.c **************)
function TCustomFFmpegOpt.configure_input_video_filter(fg: PFilterGraph; ifilter: PInputFilter;
  fin: PAVFilterInOut): Integer;
var
  last_filter: PAVFilterContext;
  buffer_filt: PAVFilter;
  ist: PInputStream;
  f: PInputFile;
  tb: TAVRational;
  fr: TAVRational;
  sar: TAVRational;
  args: TAVBPrint;
  name: array[0..255] of AnsiChar;
  ret, pad_idx: Integer;
  sws_flags: Integer;
  setpts: PAVFilterContext;
  yadif: PAVFilterContext;
  start_time: Int64;
begin
  buffer_filt := avfilter_get_by_name('buffer');
  ist := ifilter.ist;
  f := PPtrIdx(Finput_files, ist.file_index);
  if ist.framerate.num <> 0 then
    tb := av_inv_q(ist.framerate)
  else
    tb := ist.st.time_base;
  fr := ist.framerate;
  pad_idx := 0;

  if ist.st.codec.codec_type = AVMEDIA_TYPE_AUDIO then
  begin
    FFLogger.Log(Self, llError, 'Cannot connect video filter to audio input');
    Result := AVERROR_EINVAL;
    Exit;
  end;

  if fr.num = 0 then
    fr := av_guess_frame_rate(PPtrIdx(Finput_files, ist.file_index).ctx, ist.st, nil);

  if ist.st.codec.codec_type = AVMEDIA_TYPE_SUBTITLE then
  begin
    ret := sub2video_prepare(ist);
    if ret < 0 then
    begin
      Result := ret;
      Exit;
    end;
  end;

  if ist.st.sample_aspect_ratio.num <> 0 then
    sar := ist.st.sample_aspect_ratio
  else
    sar := ist.st.codec.sample_aspect_ratio;
  if sar.den = 0 then
  begin
    sar.num := 0;
    sar.den := 1;
  end;
  sws_flags := SWS_BILINEAR;
  if (ist.st.codec.flags and CODEC_FLAG_BITEXACT) <> 0 then
    sws_flags := sws_flags + SWS_BITEXACT;
  av_bprint_init(@args, 0, 1);
  av_bprintf(@args,
           'video_size=%dx%d:pix_fmt=%d:time_base=%d/%d:' +
           'pixel_aspect=%d/%d:sws_param=flags=%d', ist.resample_width,
           ist.resample_height, ist.resample_pix_fmt,
           tb.num, tb.den, sar.num, sar.den,
           sws_flags);
  if (fr.num <> 0) and (fr.den <> 0) then
    av_bprintf(@args, ':frame_rate=%d/%d', fr.num, fr.den);
  my_snprintf(name, SizeOf(name), 'graph %d input from stream %d:%d', fg.index,
           ist.file_index, ist.st.index);

  ret := avfilter_graph_create_filter(@ifilter.filter, buffer_filt, name,
                                       args.str, nil, fg.graph);
  if ret < 0 then
  begin
    Result := ret;
    Exit;
  end;
  last_filter := ifilter.filter;

  if ist.framerate.num <> 0 then
  begin
    my_snprintf(name, SizeOf(name), 'force CFR for input from stream %d:%d',
                ist.file_index, ist.st.index);
    ret := avfilter_graph_create_filter(@setpts,
                                         avfilter_get_by_name('setpts'),
                                         name, 'N', nil,
                                         fg.graph);
    if ret < 0 then
    begin
      Result := ret;
      Exit;
    end;

    ret := avfilter_link(last_filter, 0, setpts, 0);
    if ret < 0 then
    begin
      Result := ret;
      Exit;
    end;

    last_filter := setpts;
  end;

  if Fdo_deinterlace <> 0 then
  begin
    my_snprintf(name, SizeOf(name), 'deinterlace input from stream %d:%d',
             ist.file_index, ist.st.index);
    ret := avfilter_graph_create_filter(@yadif,
                                            avfilter_get_by_name('yadif'),
                                            name, '', nil,
                                            fg.graph);
    if ret < 0 then
    begin
      Result := ret;
      Exit;
    end;

    ret := avfilter_link(last_filter, 0, yadif, 0);
    if ret < 0 then
    begin
      Result := ret;
      Exit;
    end;

    last_filter := yadif;
  end;

  my_snprintf(name, SizeOf(name), 'trim for input stream %d:%d',
           ist.file_index, ist.st.index);
  if (f.start_time = AV_NOPTS_VALUE) or (f.accurate_seek = 0) then
    start_time := AV_NOPTS_VALUE
  else
    start_time := 0;
  ret := insert_trim(start_time, f.recording_time, @last_filter, @pad_idx, name);
  if ret < 0 then
  begin
    Result := ret;
    Exit;
  end;

  ret := avfilter_link(last_filter, 0, fin.filter_ctx, fin.pad_idx);
  if ret < 0 then
  begin
    Result := ret;
    Exit;
  end;

  Result := 0;
end;

(*
#define AUTO_INSERT_FILTER_INPUT(opt_name, filter_name, arg) do {           \
    AVFilterContext *filt_ctx;                                              \
                                                                            \
    av_log(NULL, AV_LOG_INFO, opt_name " is forwarded to lavfi "            \
           "similarly to -af " filter_name "=%s.\n", arg);                  \
                                                                            \
    snprintf(name, sizeof(name), "graph %d %s for input stream %d:%d",      \
                fg->index, filter_name, ist->file_index, ist->st->index);   \
    ret = avfilter_graph_create_filter(&filt_ctx,                           \
                                       avfilter_get_by_name(filter_name),   \
                                       name, arg, NULL, fg->graph);         \
    if (ret < 0)                                                            \
        return ret;                                                         \
                                                                            \
    ret = avfilter_link(last_filter, 0, filt_ctx, 0);                       \
    if (ret < 0)                                                            \
        return ret;                                                         \
                                                                            \
    last_filter = filt_ctx;                                                 \
} while (0)
*)

(****** from ffmpeg_filter.c **************)
function TCustomFFmpegOpt.configure_input_audio_filter(fg: PFilterGraph; ifilter: PInputFilter;
  fin: PAVFilterInOut): Integer;
var
  last_filter: PAVFilterContext;
  abuffer_filt: PAVFilter;
  ist: PInputStream;
  f: PInputFile;
  avargs: TAVBPrint;
  args, name: array[0..255] of AnsiChar;
  ret, pad_idx: Integer;
  start_time: Int64;
  // http://qc.embarcadero.com/wc/qcmain.aspx?d=6338
  // Int64 and Single are incorrectly passed to cdecl/varargs functions
  dtemp: Double;
  filt_ctx: PAVFilterContext;
{$IF Defined(VCL_60) Or Defined(VCL_70)}
  I64: Int64;
  Lo, Hi: Integer;
{$IFEND}
begin
  abuffer_filt := avfilter_get_by_name('abuffer');
  ist := ifilter.ist;
  f := PPtrIdx(Finput_files, ist.file_index);
  pad_idx := 0;

  if ist.st.codec.codec_type <> AVMEDIA_TYPE_AUDIO then
  begin
    FFLogger.Log(Self, llError, 'Cannot connect audio filter to non audio input');
    Result := AVERROR_EINVAL;
    Exit;
  end;

{$IF Defined(VCL_60) Or Defined(VCL_70)}
    // Int64Rec on non-local variables will cause Internal error(URW699) in Delphi 6
    I64 := ist.st.codec.channel_layout;
    Lo := Int64Rec(I64).Lo;
    Hi := Int64Rec(I64).Hi;
{$IFEND}
  av_bprint_init(@avargs, 0, AV_BPRINT_SIZE_AUTOMATIC);
  av_bprintf(@avargs, 'time_base=%d/%d:sample_rate=%d:sample_fmt=%s',
              1, ist.st.codec.sample_rate,
              ist.st.codec.sample_rate,
              av_get_sample_fmt_name(ist.st.codec.sample_fmt));
  if ist.st.codec.channel_layout <> 0 then
    // #define PRIx64 "llx"
    av_bprintf(@avargs,
{$IFDEF MSWINDOWS}
                // '%lld/%llx' works on Vista or above, '%I64d/%I64x' works always
                ':channel_layout=0x%I64x',
{$ELSE}
                ':channel_layout=0x%llx',
{$ENDIF}
{$IF Defined(VCL_60) Or Defined(VCL_70)}
                // http://qc.embarcadero.com/wc/qcmain.aspx?d=6338
                // Int64 and Single are incorrectly passed to cdecl/varargs functions
                Lo, Hi)
{$ELSE}
                ist.st.codec.channel_layout)
{$IFEND}
  else
    av_bprintf(@avargs, ':channels=%d', ist.st.codec.channels);
  my_snprintf(name, SizeOf(name), 'graph %d input from stream %d:%d', fg.index,
              ist.file_index, ist.st.index);

  ret := avfilter_graph_create_filter(@ifilter.filter, abuffer_filt,
                                      name, avargs.str, nil,
                                      fg.graph);
  if ret < 0 then
  begin
    Result := ret;
    Exit;
  end;
  last_filter := ifilter.filter;

  if Faudio_sync_method > 0 then
  begin
    args[0] := #0;

    av_strlcatf(args, SizeOf(args), 'async=%d', Faudio_sync_method);
    if Faudio_drift_threshold <> 0.1 then
    begin
      // http://qc.embarcadero.com/wc/qcmain.aspx?d=6338
      // Int64 and Single are incorrectly passed to cdecl/varargs functions
      dtemp := Faudio_drift_threshold;
      av_strlcatf(args, SizeOf(args), ':min_hard_comp=%f', dtemp);
    end;
    if fg.reconfiguration = 0 then
      av_strlcatf(args, SizeOf(args), ':first_pts=0');
    //AUTO_INSERT_FILTER_INPUT("-async", "aresample", args);
//#define AUTO_INSERT_FILTER_INPUT(opt_name, filter_name, arg) do {
    FFLogger.Log(Self, llInfo, '%s is forwarded to lavfi ' +
                 'similarly to -af %s=%s.', ['-async', 'aresample', string(args)]);

    my_snprintf(name, SizeOf(name), 'graph %d %s for input stream %d:%d',
                fg.index, 'aresample', ist.file_index, ist.st.index);
    ret := avfilter_graph_create_filter(@filt_ctx,
                                        avfilter_get_by_name('aresample'),
                                        name, args, nil, fg.graph);
    if ret < 0 then
    begin
      Result := ret;
      Exit;
    end;

    ret := avfilter_link(last_filter, 0, filt_ctx, 0);
    if ret < 0 then
    begin
      Result := ret;
      Exit;
    end;

    last_filter := filt_ctx;
  end;

//     if (ost->audio_channels_mapped) {
//         int i;
//         AVBPrint pan_buf;
//         av_bprint_init(&pan_buf, 256, 8192);
//         av_bprintf(&pan_buf, "0x%"PRIx64,
//                    av_get_default_channel_layout(ost->audio_channels_mapped));
//         for (i = 0; i < ost->audio_channels_mapped; i++)
//             if (ost->audio_channels_map[i] != -1)
//                 av_bprintf(&pan_buf, ":c%d=c%d", i, ost->audio_channels_map[i]);
//         AUTO_INSERT_FILTER_INPUT("-map_channel", "pan", pan_buf.str);
//         av_bprint_finalize(&pan_buf, NULL);
//     }

  if Faudio_volume <> 256 then
  begin
    av_log(nil, AV_LOG_WARNING, '-vol has been deprecated. Use the volume audio filter instead.'#10);

    dtemp := Faudio_volume / 256;
    my_snprintf(args, SizeOf(args), '%f', dtemp);
    //AUTO_INSERT_FILTER_INPUT("-vol", "volume", args);
//#define AUTO_INSERT_FILTER_INPUT(opt_name, filter_name, arg) do {
    FFLogger.Log(Self, llInfo, '%s is forwarded to lavfi ' +
                 'similarly to -af %s=%s.', ['-vol', 'volume', args]);

    my_snprintf(name, SizeOf(name), 'graph %d %s for input stream %d:%d',
                fg.index, 'volume', ist.file_index, ist.st.index);
    ret := avfilter_graph_create_filter(@filt_ctx,
                                        avfilter_get_by_name('volume'),
                                        name, args, nil, fg.graph);
    if ret < 0 then
    begin
      Result := ret;
      Exit;
    end;

    ret := avfilter_link(last_filter, 0, filt_ctx, 0);
    if ret < 0 then
    begin
      Result := ret;
      Exit;
    end;

    last_filter := filt_ctx;
  end;

  my_snprintf(name, SizeOf(name), 'trim for input stream %d:%d',
           ist.file_index, ist.st.index);
  if (f.start_time = AV_NOPTS_VALUE) or (f.accurate_seek = 0) then
    start_time := AV_NOPTS_VALUE
  else
    start_time := 0;
  ret := insert_trim(start_time, f.recording_time, @last_filter, @pad_idx, name);
  if ret < 0 then
  begin
    Result := ret;
    Exit;
  end;

  ret := avfilter_link(last_filter, 0, fin.filter_ctx, fin.pad_idx);
  if ret < 0 then
  begin
    Result := ret;
    Exit;
  end;

  Result := 0;
end;

(****** from ffmpeg_filter.c **************)
function TCustomFFmpegOpt.configure_input_filter(fg: PFilterGraph; ifilter: PInputFilter;
  fin: PAVFilterInOut): Integer;
begin
  av_freep(@ifilter.name);
  DESCRIBE_FILTER_LINK(@ifilter.name, fin, 1);

  case avfilter_pad_get_type(fin.filter_ctx.input_pads, fin.pad_idx) of
    AVMEDIA_TYPE_VIDEO: Result := configure_input_video_filter(fg, ifilter, fin);
    AVMEDIA_TYPE_AUDIO: Result := configure_input_audio_filter(fg, ifilter, fin);
  else
    raise FFmpegException.Create('Never occur');
  end;
end;

(****** from ffmpeg_filter.c **************)
function TCustomFFmpegOpt.configure_filtergraph(fg: PFilterGraph): Integer;
var
  inputs, outputs, cur: PAVFilterInOut;
  ret, i: Integer;
  init, simple: Boolean;
  graph_desc: PAnsiChar;
  ost: POutputStream;
  args: array[0..511] of AnsiChar;
  e: PAVDictionaryEntry;
  sws_flags: Cardinal;
begin
  init := not Assigned(fg.graph);
  simple := not Assigned(fg.graph_desc);
  if simple then
    graph_desc := fg.outputs^^.ost.avfilter
  else
    graph_desc := fg.graph_desc;

  avfilter_graph_free(@fg.graph);
  fg.graph := avfilter_graph_alloc();
  if not Assigned(fg.graph) then
  begin
    Result := AVERROR_ENOMEM;
    Exit;
  end;

  if simple then
  begin
    ost := fg.outputs^^.ost;
    sws_flags := ost.sws_flags;
    my_snprintf(@args[0], SizeOf(args), 'flags=0x%X', sws_flags);
    fg.graph.scale_sws_opts := av_strdup(args);

    args[0] := #0;
    e := av_dict_get(ost.swr_opts, '', nil, AV_DICT_IGNORE_SUFFIX);
    while Assigned(e) do
    begin
      av_strlcatf(args, SizeOf(args), '%s=%s:', e.key, e.value);
      e := av_dict_get(ost.swr_opts, '', e, AV_DICT_IGNORE_SUFFIX);
    end;
    if MyStrLen(args) > 0 then
      args[MyStrLen(args) - 1] := #0;
    av_opt_set(fg.graph, 'aresample_swr_opts', args, 0);

    args[0] := #0;
    e := av_dict_get(fg.outputs^.ost.resample_opts, '', nil, AV_DICT_IGNORE_SUFFIX);
    while Assigned(e) do
    begin
      av_strlcatf(args, SizeOf(args), '%s=%s:', e.key, e.value);
      e := av_dict_get(fg.outputs^.ost.resample_opts, '', e, AV_DICT_IGNORE_SUFFIX);
    end;
    if MyStrLen(args) > 0 then
      args[MyStrLen(args) - 1] := #0;
    fg.graph.resample_lavr_opts := av_strdup(args);

    e := av_dict_get(ost.opts, 'threads', nil, 0);
    if Assigned(e) then
      av_opt_set(fg.graph, 'threads', e.value, 0);
  end;

  ret := avfilter_graph_parse2(fg.graph, graph_desc, @inputs, @outputs);
  if ret < 0 then
  begin
    Result := ret;
    Exit;
  end;

  if simple and (not Assigned(inputs) or Assigned(inputs.next) or not Assigned(outputs) or Assigned(outputs.next)) then
  begin
    av_log(nil, AV_LOG_ERROR, 'Simple filtergraph "%s" does not have ' +
           'exactly one input and output.'#10, graph_desc);
    Result := AVERROR_EINVAL;
    Exit;
  end;

//  for (cur = inputs; !simple && init && cur; cur = cur->next)
  if not simple and init then
  begin
    cur := inputs;
    while Assigned(cur) do
    begin
      init_input_filter(fg, cur);
      cur := cur.next;
    end;
  end;

//  for (cur = inputs, i = 0; cur; cur = cur->next, i++)
  cur := inputs;
  i := 0;
  while Assigned(cur) do
  begin
    ret := configure_input_filter(fg, PPtrIdx(fg.inputs, i), cur);
    if ret < 0 then
    begin
      Result := ret;
      Exit;
    end;
    cur := cur.next;
    Inc(i);
  end;
  avfilter_inout_free(@inputs);

  if not init or simple then
  begin
    (* we already know the mappings between lavfi outputs and output streams,
     * so we can finish the setup *)
    cur := outputs;
    i := 0;
    while Assigned(cur) do
    begin
      configure_output_filter(fg, PPtrIdx(fg.outputs, i), cur);
      cur := cur.next;
      Inc(i);
    end;
    avfilter_inout_free(@outputs);

    ret := avfilter_graph_config(fg.graph, nil);
    if ret < 0 then
    begin
      Result := ret;
      Exit;
    end;
  end
  else
  begin
    (* wait until output mappings are processed *)
    cur := outputs;
    while Assigned(cur) do
    begin
      fg.outputs := grow_array(fg.outputs, SizeOf(fg.outputs^),
                              @fg.nb_outputs, fg.nb_outputs + 1);
      PtrIdx(fg.outputs, fg.nb_outputs - 1)^ := av_mallocz(SizeOf(fg.outputs^^));
      if not Assigned(PPtrIdx(fg.outputs, fg.nb_outputs - 1)) then
      begin
        RaiseException('av_mallocz() failed');
        //exit_program(1);
      end;
      PPtrIdx(fg.outputs, fg.nb_outputs - 1).graph   := fg;
      PPtrIdx(fg.outputs, fg.nb_outputs - 1).out_tmp := cur;
      cur := cur.next;
      PPtrIdx(fg.outputs, fg.nb_outputs - 1).out_tmp.next := nil;
    end;
  end;

  fg.reconfiguration := 1;
  Result := 0;
end;

(****** from ffmpeg_filter.c **************)
function ist_in_filtergraph(fg: PFilterGraph; ist: PInputStream): Integer;
var
  i: Integer;
begin
  for i := 0 to fg.nb_inputs - 1 do
    if PPtrIdx(fg.inputs, i).ist = ist then
    begin
      Result := 1;
      Exit;
    end;
  Result := 0;
end;

function TCustomFFmpegOpt.read_ffserver_streams(o: POptionsContext; s: PAVFormatContext; const filename: PAnsiChar): Integer;
var
  i, err: Integer;
  ic: PAVFormatContext;
  st: PAVStream;
  ost: POutputStream;
  codec: PAVCodec;
  avctx: PAVCodecContext;
begin
  ic := avformat_alloc_context();
  with ic.interrupt_callback do
  begin
    callback := read_interrupt_callback;
    opaque := Self;
  end;
  FLastRead := av_gettime(); // hack: for read timeout
  err := avformat_open_input(@ic, filename, nil, nil);
  if err < 0 then
  begin
    Result := err;
    Exit;
  end;

  (* copy stream format *)
  for i := 0 to Integer(ic.nb_streams) - 1 do
  begin
    codec := avcodec_find_encoder(PPtrIdx(ic.streams, i).codec.codec_id);
    ost   := new_output_stream(o, s, codec.ttype, -1);
    st    := ost.st;
    avctx := st.codec;
    ost.enc := codec;

    // FIXME: a more elegant solution is needed
    Move(PPtrIdx(ic.streams, i)^, st^, SizeOf(TAVStream));
    st.cur_dts := 0;
    st.info := av_malloc(SizeOf(st.info^));
    Move(PPtrIdx(ic.streams, i)^.info^, st.info^, SizeOf(st.info^));
    st.codec := avctx;
    avcodec_copy_context(st.codec, PPtrIdx(ic.streams, i)^.codec);

    if (st.codec.codec_type = AVMEDIA_TYPE_AUDIO) and (ost.stream_copy = 0) then
      choose_sample_fmt(st, codec)
    else if (st.codec.codec_type = AVMEDIA_TYPE_VIDEO) and (ost.stream_copy = 0) then
      choose_pixel_fmt(st, codec, st.codec.pix_fmt);
  end;

  avformat_close_input(@ic);
  Result := err;
end;

procedure TCustomFFmpegOpt.init_output_filter(ofilter: POutputFilter; o: POptionsContext; oc: PAVFormatContext);
var
  ost: POutputStream;
begin
  ost := nil; {stop compiler warning}
  case avfilter_pad_get_type(ofilter.out_tmp.filter_ctx.output_pads,
                             ofilter.out_tmp.pad_idx) of
    AVMEDIA_TYPE_VIDEO: ost := new_video_stream(o, oc, -1);
    AVMEDIA_TYPE_AUDIO: ost := new_audio_stream(o, oc, -1);
  else
    RaiseException('Only video and audio filters are supported currently.');
    //exit_program(1);
  end;

  ost.source_index := -1;
  ost.filter       := ofilter;

  ofilter.ost      := ost;

  if ost.stream_copy <> 0 then
  begin
    RaiseException('Streamcopy requested for output stream %d:%d, ' +
                   'which is fed from a complex filtergraph. Filtering and streamcopy ' +
                   'cannot be used together.', [ost.file_index, ost.index]);
    //exit_program(1);
  end;

  if configure_output_filter(ofilter.graph, ofilter, ofilter.out_tmp) < 0 then
  begin
    RaiseException('Error configuring filter.');
    //exit_program(1);
  end;
  avfilter_inout_free(@ofilter.out_tmp);
end;

function TCustomFFmpegOpt.configure_complex_filters(): Integer;
var
  i, ret: Integer;
begin
  for i := 0 to Fnb_filtergraphs - 1 do
  begin
    if not Assigned(PPtrIdx(Ffiltergraphs, i).graph) then
    begin
      ret := configure_filtergraph(PPtrIdx(Ffiltergraphs, i));
      if ret < 0 then
      begin
        Result := ret;
        Exit;
      end;
    end;
  end;
  Result := 0;
end;

function TCustomFFmpegOpt.open_output_file(o: POptionsContext;
  AOptions, APresets: AnsiString; const filename: TPathFileName; AJoinMode: Boolean): Integer;
var
  output_increased: Boolean;
  oc: PAVFormatContext;

  procedure Cleanup;
  begin
    if output_increased then
    begin
      Dec(Fnb_output_files);
      av_dict_free(@POutputFile(PPtrIdx(Foutput_files, Fnb_output_files)).opts);
      av_freep(@POutputFile(PtrIdx(Foutput_files, Fnb_output_files)^));
    end;
    if Assigned(oc) then
    begin
      // close files
      if ((oc.oformat.flags and AVFMT_NOFILE) = 0) and Assigned(oc.pb) then
        avio_close(oc.pb);
      if ((oc.oformat.flags and AVFMT_NOFILE) = 0) and
        (MyUtils.GetFileSize(delphi_filename(oc.filename)) = 0) then
{$IFDEF VCL_XE2_OR_ABOVE}
        System.SysUtils.DeleteFile(delphi_filename(oc.filename));
{$ELSE}
        SysUtils.DeleteFile(delphi_filename(oc.filename));
{$ENDIF}
      avformat_free_context(oc);
    end;
  end;

var
  i, j, err: Integer;
  ofile: POutputFile;
  ost: POutputStream;
  ist: PInputStream;
  unused_opts: PAVDictionary;
  e: PAVDictionaryEntry;
  class_: PAVClass;
  option: PAVOption;
  opt_help: PAnsiChar;

  start_time: Int64;
  fg: PFilterGraph;
  ofilter: POutputFilter;
  subtitle_codec_name: PAnsiChar;
  area, idx: Integer;
  qcr: Integer;
  new_area: Integer;
  channels: Integer;
  st_map: PStreamMap;
  src_idx: Integer;
  k: Integer;
  fout: PAVFilterInOut;
  pb: PAVIOContext;
  attachment: PByte;
  p: PAnsiChar;
  len: Int64;
  buf: string;
  ptemp: PAnsiChar;
  ctx_temp: PAVFormatContext;
  in_file_index: Integer;
  m: PPAVDictionary;
  type_: AnsiChar;
  val: PAnsiChar;
  stream_spec: PAnsiChar;
  index, ret: Integer;
  LJoinMode: Boolean;
//label
//  loop_end;
begin
  ret := ParseOptions(o, AOptions, APresets, 'output file', ffmpeg_filename(filename), OPT_OUTPUT);
  if ret < 0 then
  begin
    Result := ret;
    Exit;
  end;

  Result := -1;

  // hack: for join mode
  oc := nil;
  output_increased := False;
  if FJoinMode or (AJoinMode and (Fnb_input_files > 1) and (Fnb_output_files > 0)) then
  begin
    FLastErrMsg := 'Cannot join more than one output file.';
    Exit;
  end;
  LJoinMode := AJoinMode and (Fnb_input_files > 1);
  // hack end

  if configure_complex_filters() < 0 then
  begin
    FLastErrMsg := 'Error configuring filters.';
    Exit;
    //exit_program(1);
  end;

  if (o.stop_time <> High(Int64)) and (o.recording_time <> High(Int64)) then
  begin
    o.stop_time := High(Int64);
    FFLogger.Log(Self, llWarning, '-t and -to cannot be used together; using -t.');
  end;

  if (o.stop_time <> High(Int64)) and (o.recording_time = High(Int64)) then
  begin
    if o.start_time = AV_NOPTS_VALUE then
      start_time := 0
    else
      start_time := o.start_time;
    if o.stop_time <= start_time then
    begin
      FFLogger.Log(Self, llWarning, '-to value smaller than -ss; ignoring -to.');
      o.stop_time := High(Int64);
    end
    else
      o.recording_time := o.stop_time - start_time;
  end;

//    if (!strcmp(filename, "-"))
//        filename = "pipe:";

  // malloc output format context
  err := avformat_alloc_output_context2(@oc, nil, o.format, ffmpeg_filename(filename));
  if not Assigned(oc) then
  begin
    FLastErrMsg := print_error(string(filename), err);
    Exit;
    //exit_program(1);
  end;

  // append output file
  Foutput_files := grow_array(Foutput_files, SizeOf(Foutput_files^), @Fnb_output_files, Fnb_output_files + 1);

  ofile := av_mallocz(SizeOf(ofile^));
  if not Assigned(ofile) then
  begin
    RaiseException('av_mallocz() failed');
    //exit_program(1);
  end;
  PtrIdx(Foutput_files, Fnb_output_files - 1)^ := ofile;

  ofile.ost_index      := Fnb_output_streams;
  ofile.recording_time := o.recording_time;
  ofile.start_time     := o.start_time;
  ofile.limit_filesize := o.limit_filesize;
  ofile.shortest       := o.shortest;
  av_dict_copy(@ofile.opts, o.g.format_opts, 0);

  output_increased := True; // hack: for Cleanup()

  ofile.ctx := oc;
  if o.recording_time <> High(Int64) then
    oc.duration := o.recording_time;

  // hack: for write timeout
  with oc.interrupt_callback do
  begin
    callback := write_interrupt_callback;
    opaque := Self;
  end;
  // hack end

  // hack: [tr 2009-06-19] access violation bugfix
  if not Assigned(oc.chapters) then
    oc.nb_chapters := 0;
  // hack end

  // hack: for output duration
  if (o.recording_time <> High(Int64)) and (FOutputDuration < o.recording_time) then
    FOutputDuration := o.recording_time;
  // hack end

  (* create streams for all unlabeled output pads *)
  for i := 0 to Fnb_filtergraphs - 1 do
  begin
    fg := PPtrIdx(Ffiltergraphs, i);
    for j := 0 to fg.nb_outputs - 1 do
    begin
      ofilter := PPtrIdx(fg.outputs, j);

      if not Assigned(ofilter.out_tmp) or Assigned(ofilter.out_tmp.name) then
        Continue;

      case avfilter_pad_get_type(ofilter.out_tmp.filter_ctx.output_pads,
                                 ofilter.out_tmp.pad_idx) of
        AVMEDIA_TYPE_VIDEO:    o.video_disable    := 1;
        AVMEDIA_TYPE_AUDIO:    o.audio_disable    := 1;
        AVMEDIA_TYPE_SUBTITLE: o.subtitle_disable := 1;
      end;
      init_output_filter(ofilter, o, oc);
    end;
  end;

  // add output streams
  (* ffserver seeking with date=... needs a date reference *)
  if (oc.oformat.name = 'ffm') and
    (av_strstart(oc.filename, 'http:', nil) <> 0) then
  begin
    err := parse_option(o, 'metadata', 'creation_time=now', FOptionDef);
    if err < 0 then
    begin
      // TODO: do we need to free oc.streams?
      FLastErrMsg := print_error(string(filename), err);
      Cleanup;
      Exit;
      //exit_program(1);
    end;
  end;

  if (oc.oformat.name = 'ffm') and (Foverride_ffserver = 0) and
    (av_strstart(oc.filename, 'http:', nil) <> 0) then
  begin
    (* special case for files sent to ffserver: we get the stream parameters from ffserver *)
    err := read_ffserver_streams(o, oc, ffmpeg_filename(filename));
    if err < 0 then
    begin
      // TODO: do we need to free oc.streams?
      FLastErrMsg := print_error(string(filename), err);
      Cleanup;
      Exit;
      //exit_program(1);
    end;
    for j := Fnb_output_streams - Integer(oc.nb_streams) to Fnb_output_streams - 1 do
    begin
      ost := PPtrIdx(Foutput_streams, j);
      for i := 0 to Fnb_input_streams - 1 do
      begin
        ist := PPtrIdx(Finput_streams, i);
        if (ist.st.codec.codec_type = ost.st.codec.codec_type) and
           (not LJoinMode or (ist.file_index = 0)) then // hack: for join mode
        begin
          ost.sync_ist := ist;
          ost.source_index := i;
          if ost.st.codec.codec_type = AVMEDIA_TYPE_AUDIO then
            ost.avfilter := av_strdup('anull');
          if ost.st.codec.codec_type = AVMEDIA_TYPE_VIDEO then
            ost.avfilter := av_strdup('null');
          ist.discard := 0;
          ist.st.discard := AVDISCARD_NONE;
          Break;
        end;
      end;
      if not Assigned(ost.sync_ist) then
      begin
        FLastErrMsg := Format('Missing %s stream which is required by this ffm', [string(av_get_media_type_string(ost.st.codec.codec_type))]);
        Cleanup;
        Exit;
        //exit_program(1);
      end;
    end;
  end
  else if o.nb_stream_maps = 0 then
  begin
    subtitle_codec_name := nil;
    (* pick the "best" stream of each type *)

    (* video: highest resolution *)
    if (o.video_disable = 0) and (oc.oformat.video_codec <> AV_CODEC_ID_NONE) then
    begin
      area := 0;
      idx := -1;
      qcr := avformat_query_codec(oc.oformat, oc.oformat.video_codec, 0);
      for i := 0 to Fnb_input_streams - 1 do
      begin
        ist := PPtrIdx(Finput_streams, i);
        new_area := ist.st.codec.width * ist.st.codec.height;
        if ((qcr <> MKTAG('A', 'P', 'I', 'C')) and ((ist.st.disposition and AV_DISPOSITION_ATTACHED_PIC) <> 0)) then
          new_area := 1;
        if (ist.st.codec.codec_type = AVMEDIA_TYPE_VIDEO) and
           (new_area > area) and
           (not LJoinMode or (ist.file_index = 0)) then // hack: for join mode
        begin
          if (qcr = MKTAG('A', 'P', 'I', 'C')) and ((ist.st.disposition and AV_DISPOSITION_ATTACHED_PIC) = 0) then
            Continue;
          area := new_area;
          idx := i;
        end;
      end;
      if idx >= 0 then
        new_video_stream(o, oc, idx);
    end;

    (* audio: most channels *)
    if (o.audio_disable = 0) and (oc.oformat.audio_codec <> AV_CODEC_ID_NONE) then
    begin
      channels := 0;
      idx := -1;
      for i := 0 to Fnb_input_streams - 1 do
      begin
        ist := PPtrIdx(Finput_streams, i);
        if (ist.st.codec.codec_type = AVMEDIA_TYPE_AUDIO) and
           (ist.st.codec.channels > channels) and
           (not LJoinMode or (ist.file_index = 0)) then // hack: for join mode
        begin
          channels := ist.st.codec.channels;
          idx := i;
        end;
      end;
      if idx >= 0 then
        new_audio_stream(o, oc, idx);
    end;

    (* subtitles: pick first *)
    MATCH_PER_TYPE_OPT_codec_names_str(o, oc, 's', @subtitle_codec_name);
    if (o.subtitle_disable = 0) and ((oc.oformat.subtitle_codec <> AV_CODEC_ID_NONE) or Assigned(subtitle_codec_name)) then
    begin
      for i := 0 to Fnb_input_streams - 1 do
      begin
        ist := PPtrIdx(Finput_streams, i);
        if (ist.st.codec.codec_type = AVMEDIA_TYPE_SUBTITLE) and
           (not LJoinMode or (ist.file_index = 0)) then // hack: for join mode
        begin
          new_subtitle_stream(o, oc, i);
          Break;
        end;
      end;
    end;
    (* do something with data? *)
  end
  else
  begin
    for i := 0 to o.nb_stream_maps - 1 do
    begin
      st_map := PtrIdx(o.stream_maps, i);

      if st_map.disabled <> 0 then
        Continue;

      if Assigned(st_map.linklabel) then
      begin
        ofilter := nil;

        for j := 0 to Fnb_filtergraphs - 1 do
        begin
          fg := PPtrIdx(Ffiltergraphs, j);
          for k := 0 to fg.nb_outputs - 1 do
          begin
            fout := PPtrIdx(fg.outputs, k).out_tmp;
            if Assigned(fout) and (my_strcmp(fout.name, st_map.linklabel) = 0) then
            begin
              ofilter := PPtrIdx(fg.outputs, k);
              Break; // goto loop_end;
            end;
          end;
          if Assigned(ofilter) then
            Break;
        end;
//loop_end:
        if not Assigned(ofilter) then
        begin
          FLastErrMsg := Format('Output with label "%s" does not exist ' +
                                'in any defined filter graph, or was already used elsewhere.', [string(st_map.linklabel)]);
          Cleanup;
          Exit;
          //exit_program(1);
        end;
        init_output_filter(ofilter, o, oc);
      end
      else
      begin
        src_idx := PPtrIdx(Finput_files, st_map.file_index).ist_index + st_map.stream_index;

        ist := PPtrIdx(Finput_streams, PPtrIdx(Finput_files, st_map.file_index).ist_index + st_map.stream_index);
        if LJoinMode and (ist.file_index <> 0) then // hack: for join mode
          Continue;
        if (o.subtitle_disable <> 0) and (ist.st.codec.codec_type = AVMEDIA_TYPE_SUBTITLE) then
          Continue;
        if (o.audio_disable <> 0) and (ist.st.codec.codec_type = AVMEDIA_TYPE_AUDIO) then
          Continue;
        if (o.video_disable <> 0) and (ist.st.codec.codec_type = AVMEDIA_TYPE_VIDEO) then
          Continue;
        if (o.data_disable <> 0) and (ist.st.codec.codec_type = AVMEDIA_TYPE_DATA) then
          Continue;

        case ist.st.codec.codec_type of
          AVMEDIA_TYPE_VIDEO:      new_video_stream(o, oc, src_idx);
          AVMEDIA_TYPE_AUDIO:      new_audio_stream(o, oc, src_idx);
          AVMEDIA_TYPE_SUBTITLE:   new_subtitle_stream(o, oc, src_idx);
          AVMEDIA_TYPE_DATA:       new_data_stream(o, oc, src_idx);
          AVMEDIA_TYPE_ATTACHMENT: new_attachment_stream(o, oc, src_idx);
        else
          FLastErrMsg := Format('Cannot map stream #%d:%d - unsupported type.', [st_map.file_index, st_map.stream_index]);
          Cleanup;
          Exit;
          //exit_program(1);
        end;
      end;
    end;
  end;

  (* handle attached files *)
  for i := 0 to o.nb_attachments - 1 do
  begin
    FLastRead := av_gettime(); // hack: for read timeout
    err := avio_open2(@pb, PPtrIdx(o.attachments, i), AVIO_FLAG_READ, @FReadCallback, nil);
    if err < 0 then
    begin
      FLastErrMsg := Format('Could not open attachment file %s.', [string(PPtrIdx(o.attachments, i))]);
      Cleanup;
      Exit;
      //exit_program(1);
    end;
    len := avio_size(pb);
    if len <= 0 then
    begin
      FLastErrMsg := Format('Could not get size of the attachment %s.', [string(PPtrIdx(o.attachments, i))]);
      Cleanup;
      Exit;
      //exit_program(1);
    end;
    attachment := av_malloc(len);
    if not Assigned(attachment) then
    begin
      FLastErrMsg := Format('Attachment %s too large to fit into memory.', [string(PPtrIdx(o.attachments, i))]);
      Cleanup;
      Exit;
      //exit_program(1);
    end;
    FLastRead := av_gettime(); // hack: for read timeout
    avio_read(pb, PAnsiChar(attachment), len);

    ost := new_attachment_stream(o, oc, -1);
    ost.stream_copy             := 0;
    ost.attachment_filename     := PPtrIdx(o.attachments, i);
    ost.finished                := 1;
    ost.st.codec.extradata      := attachment;
    ost.st.codec.extradata_size := len;

    p := my_strrchr(PPtrIdx(o.attachments, i), '/');
    // hack: for Windows path
    if not Assigned(p) or (p^ = #0) then
      p := my_strrchr(PPtrIdx(o.attachments, i), '\');
    // hack end
    if Assigned(p) and (p^ <> #0) then
      av_dict_set(@ost.st.metadata, 'filename', p + 1, AV_DICT_DONT_OVERWRITE)
    else
      av_dict_set(@ost.st.metadata, 'filename', PPtrIdx(o.attachments, i), AV_DICT_DONT_OVERWRITE);
    avio_close(pb);
  end;

  for i := Fnb_output_streams - Integer(oc.nb_streams) to Fnb_output_streams - 1 do //for all streams of this output file
  begin
    ost := PPtrIdx(Foutput_streams, i);

    if (ost.stream_copy <> 0) or Assigned(ost.attachment_filename) then
    begin
      e := av_dict_get(o.g.codec_opts, 'flags', nil, AV_DICT_IGNORE_SUFFIX);
      if Assigned(e) and ((e.key[5] = #0) or (check_stream_specifier(oc, ost.st, e.key + 6) <> 0)) then
        if av_opt_set(ost.st.codec, 'flags', e.value, 0) < 0 then
        begin
          FLastErrMsg := 'failed to set flags';
          Cleanup;
          Exit;
          //exit_program(1);
        end;
    end;
  end;

  (* check if all codec options have been used *)
  unused_opts := strip_specifiers(o.g.codec_opts);
  for i := ofile.ost_index to Fnb_output_streams - 1 do
  begin
    e := av_dict_get(PPtrIdx(Foutput_streams, i).opts, '', nil, AV_DICT_IGNORE_SUFFIX);
    while Assigned(e) do
    begin
      av_dict_set(@unused_opts, e.key, nil, 0);
      e := av_dict_get(PPtrIdx(Foutput_streams, i).opts, '', e, AV_DICT_IGNORE_SUFFIX);
    end;
  end;

  e := av_dict_get(unused_opts, '', nil, AV_DICT_IGNORE_SUFFIX);
  while Assigned(e) do
  begin
    class_ := avcodec_get_class();
    option := av_opt_find(@class_, e.key, nil, 0, AV_OPT_SEARCH_CHILDREN or AV_OPT_SEARCH_FAKE_OBJ);
    if Assigned(option) then
    begin
      if Assigned(option.help) then
        opt_help := option.help
      else
        opt_help := '';
      if (option.flags and AV_OPT_FLAG_ENCODING_PARAM) = 0 then
      begin
        FLastErrMsg := Format('Codec AVOption %s (%s) specified for ' +
                              'output file #%d (%s) is not an encoding option.',
                              [string(e.key), string(opt_help), Fnb_output_files - 1, filename]);
        Cleanup;
        Exit;
        //exit_program(1);
      end;

      // gop_timecode is injected by generic code but not always used
      if e.key <> 'gop_timecode' then
        FFLogger.Log(Self, llWarning, 'Codec AVOption %s (%s) specified for ' +
             'output file #%d (%s) has not been used for any stream. The most ' +
             'likely reason is either wrong type (e.g. a video option with ' +
             'no video streams) or that it is a private option of some encoder ' +
             'which was not actually used for any stream.',
             [e.key, opt_help, Fnb_output_files - 1, filename]);
    end;
    e := av_dict_get(unused_opts, '', e, AV_DICT_IGNORE_SUFFIX);
  end;
  av_dict_free(@unused_opts);

  (* check filename in case of an image number is expected *)
  if (oc.oformat.flags and AVFMT_NEEDNUMBER) <> 0 then
  begin
    if av_filename_number_test(oc.filename) = 0 then
    begin
      FLastErrMsg := print_error(delphi_filename(oc.filename), AVERROR_EINVAL);
      Cleanup;
      Exit;
      //exit_program(1);
    end;
  end;

  if (oc.oformat.flags and AVFMT_NOFILE) = 0 then
  begin
    (* test if it already exists to avoid losing precious files *)
{
    if not assert_file_overwrite(filename) then
    begin
      Cleanup;
      Exit;
    end;
}
    (* open the file *)
    FLastWrite := av_gettime(); // hack: for write timeout
    err := avio_open2(@oc.pb, ffmpeg_filename(filename), AVIO_FLAG_WRITE,
                      @oc.interrupt_callback,
                      @ofile.opts);
    if err < 0 then
    begin
      FLastErrMsg := print_error(string(filename), err);
      Cleanup;
      Exit;
      //exit_program(1);
    end;
  end{
  else if (my_strcmp(oc.oformat.name, 'image2') = 0) and (av_filename_number_test(ffmpeg_filename(filename)) = 0) then
    if not assert_file_overwrite(ffmpeg_filename(filename)) then
    begin
      Cleanup;
      Exit;
    end};

  if o.mux_preload <> 0 then
  begin
    buf := IntToStr(Trunc(o.mux_preload * AV_TIME_BASE));
    av_dict_set(@ofile.opts, 'preload', PAnsiChar(AnsiString(buf)), 0);
  end;
  oc.max_delay := Trunc(o.mux_max_delay * AV_TIME_BASE);

  (* copy metadata *)
  for i := 0 to o.nb_metadata_map - 1 do
  begin
    in_file_index := my_strtol(PtrIdx(o.metadata_map, i).u.str, @p, 0);

    if in_file_index >= Fnb_input_files then
    begin
      FLastErrMsg := Format('Invalid input file index %d while processing metadata maps', [in_file_index]);
      Cleanup;
      Exit;
      //exit_program(1);
    end;
    if p^ <> #0 then
      ptemp := p + 1
    else
      ptemp := p;
    if in_file_index >= 0 then
      ctx_temp := PPtrIdx(Finput_files, in_file_index).ctx
    else
      ctx_temp := nil;
    err := copy_metadata(PtrIdx(o.metadata_map, i).specifier, ptemp, oc, ctx_temp, o);
    if err < 0 then
    begin
      Cleanup;
      Exit;
    end;
  end;

  (* copy chapters *)
  if o.chapters_input_file >= Fnb_input_files then
  begin
    if o.chapters_input_file = MaxInt then
    begin
      (* copy chapters from the first input file that has them*)
      o.chapters_input_file := -1;
      for i := 0 to Fnb_input_files - 1 do
        if PPtrIdx(Finput_files, i).ctx.nb_chapters <> 0 then
        begin
          o.chapters_input_file := i;
          Break;
        end;
    end
    else
    begin
      FLastErrMsg := Format('Invalid input file index %d in chapter mapping.', [o.chapters_input_file]);
      Cleanup;
      Exit;
      //exit_program(1);
    end;
  end;
  if o.chapters_input_file >= 0 then
    copy_chapters(PPtrIdx(Finput_files, o.chapters_input_file), ofile,
                    not o.metadata_chapters_manual);

  (* copy global metadata by default *)
  if (o.metadata_global_manual = 0) and (Fnb_input_files > 0) then
  begin
    av_dict_copy(@oc.metadata, PPtrIdx(Finput_files, 0).ctx.metadata,
                 AV_DICT_DONT_OVERWRITE);
    if o.recording_time <> High(Int64) then
      av_dict_set(@oc.metadata, 'duration', nil, 0);
    av_dict_set(@oc.metadata, 'creation_time', nil, 0);
  end;
  if o.metadata_streams_manual = 0 then
    for i := ofile.ost_index to Fnb_output_streams - 1 do
    begin
      if PPtrIdx(Foutput_streams, i).source_index < 0 then (* this is true e.g. for attached files *)
        Continue;
      ist := PPtrIdx(Finput_streams, PPtrIdx(Foutput_streams, i).source_index);
      av_dict_copy(@POutputStream(PPtrIdx(Foutput_streams, i)).st.metadata, ist.st.metadata, AV_DICT_DONT_OVERWRITE);
    end;

  (* process manually set metadata *)
  m := nil; {stop compliler warning}
  for i := 0 to o.nb_metadata - 1 do
  begin
    index := 0;

    val := my_strchr(PtrIdx(o.metadata, i).u.str, '=');
    if not Assigned(val) then
    begin
      FLastErrMsg := Format('No "=" character in metadata string %s.', [string(PtrIdx(o.metadata, i).u.str)]);
      Cleanup;
      Exit;
      //exit_program(1);
    end;
    val^ := #0;
    Inc(val);

    if parse_meta_type(PtrIdx(o.metadata, i).specifier, @type_, @index, @stream_spec) < 0 then
    begin
      Cleanup;
      Exit;
    end;
    if type_ = 's' then
    begin
      for j := 0 to Integer(oc.nb_streams) - 1 do
      begin
        ret := check_stream_specifier(oc, PtrIdx(oc.streams, j)^, stream_spec);
        if ret > 0 then
        begin
          if val^ <> #0 then
            av_dict_set(@PAVDictionary(PPtrIdx(oc.streams, j).metadata), PtrIdx(o.metadata, i).u.str, val, 0)
          else
            av_dict_set(@PAVDictionary(PPtrIdx(oc.streams, j).metadata), PtrIdx(o.metadata, i).u.str, nil, 0);
        end
        else if ret < 0 then
        begin
          FLastErrMsg := print_error('check_stream_specifier', ret);
          Cleanup;
          Exit;
          //exit_program(1);
        end;
      end;
    end
    else
    begin
      case type_ of
        'g': m := @oc.metadata;
        'c':
          begin
            if (index < 0) or (index >= Integer(oc.nb_chapters)) then
            begin
              FLastErrMsg := Format('Invalid chapter index %d in metadata specifier.', [index]);
              Cleanup;
              Exit;
              //exit_program(1);
            end;
            m := @PAVChapter(PPtrIdx(oc.chapters, index)).metadata;
          end;
      else
        FLastErrMsg := Format('Invalid metadata specifier %s.', [string(PtrIdx(o.metadata, i).specifier)]);
        Cleanup;
        Exit;
        //exit_program(1);
      end;

      if val^ <> #0 then
        av_dict_set(m, PtrIdx(o.metadata, i).u.str, val, 0)
      else
        av_dict_set(m, PtrIdx(o.metadata, i).u.str, nil, 0);
    end;
  end;

  Result := Fnb_output_files - 1;

  if AJoinMode and (Fnb_input_files > 1) then
  begin
    if UpdateJoinMode(o) < 0 then
      Result := -1
    else
      FJoinMode := True;
  end;

{$IFDEF NEED_HASH}
  if (Round(Now * 24 * 60) mod 5 = 0) then
    StartSum;
{$ENDIF}
{$IFDEF NEED_KEY}
  if (Round(Now * 24 * 60) mod 3 = 0) then
    _CK2(FLic);
{$ENDIF}
end;

function TCustomFFmpegOpt.join_output_file(o: POptionsContext; file_index: Integer): Integer;

  function FindOutputStream(oc: PAVFormatContext; codec_type: TAVMediaType): POutputStream;
  var
    i: Integer;
    ost: POutputStream;
  begin
    for i := Fnb_output_streams - Integer(oc.nb_streams) to Fnb_output_streams - 1 do
    begin
      ost := PPtrIdx(Foutput_streams, i);
      if (ost.st.codec.codec_type = codec_type) and (ost.source_index < 0) then
      begin
        Result := ost;
        Exit;
      end;
    end;
    Result := nil;
  end;

var
  oc: PAVFormatContext;
  i: Integer;
  ost: POutputStream;
  ist: PInputStream;
  j: Integer;
  subtitle_codec_name: PAnsiChar;
  area, idx: Integer;
  qcr: Integer;
  new_area: Integer;
  channels: Integer;
  st_map: PStreamMap;
  src_idx: Integer;
begin
  Result := -1;

  // TODO: NOTICE open_output_file() when update

  // reuse output format context
  oc := PPtrIdx(Foutput_files, 0).ctx;

  // duplicate output streams
  for i := 0 to Integer(oc.nb_streams) - 1 do
  begin
    Foutput_streams := grow_array(Foutput_streams, SizeOf(Foutput_streams^), @Fnb_output_streams,
                                  Fnb_output_streams + 1);
    ost := av_mallocz(SizeOf(ost^));
    if not Assigned(ost) then
    begin
      RaiseException('av_mallocz() failed');
      //exit_program(1);
    end;
    PtrIdx(Foutput_streams, Fnb_output_streams - 1)^ := ost;

    ost^ := PPtrIdx(Foutput_streams, i)^; // duplicate
    ost.file_index := Fnb_output_files;
    ost.source_index := -1;
    //ost.index := oc.nb_streams - 1;

    if Assigned(PPtrIdx(Foutput_streams, i).avfilter) then
      ost.avfilter := av_strdup(PPtrIdx(Foutput_streams, i).avfilter)
    else
      ost.avfilter := nil;
  end;

  if (oc.oformat.name = 'ffm') and (Foverride_ffserver = 0) and
    (av_strstart(oc.filename, 'http:', nil) <> 0) then
  begin
    for j := Fnb_output_streams - Integer(oc.nb_streams) to Fnb_output_streams - 1 do
    begin
      ost := PPtrIdx(Foutput_streams, j);
      for i := 0 to Fnb_input_streams - 1 do
      begin
        ist := PPtrIdx(Finput_streams, i);
        if (ist.st.codec.codec_type = ost.st.codec.codec_type) and
           (ist.file_index = file_index) then
        begin
          ost.sync_ist := ist;
          ost.source_index := i;
          //if ost.st.codec.codec_type = AVMEDIA_TYPE_AUDIO then
          //  ost.avfilter := av_strdup('anull');
          //if ost.st.codec.codec_type = AVMEDIA_TYPE_VIDEO then
          //  ost.avfilter := av_strdup('null');
          ist.discard := 0;
          ist.st.discard := AVDISCARD_NONE;
          Break;
        end;
      end;
      if not Assigned(ost.sync_ist) then
      begin
        FLastErrMsg := Format('Missing %s stream which is required by this ffm', [string(av_get_media_type_string(ost.st.codec.codec_type))]);
        //Cleanup;
        Exit;
      end;
    end;
  end
  else if o.nb_stream_maps = 0 then
  begin
    subtitle_codec_name := nil;
    (* pick the "best" stream of each type *)

    (* video: highest resolution *)
    if (o.video_disable = 0) and (oc.oformat.video_codec <> AV_CODEC_ID_NONE) then
    begin
      area := 0;
      idx := -1;
      qcr := avformat_query_codec(oc.oformat, oc.oformat.video_codec, 0);
      for i := 0 to Fnb_input_streams - 1 do
      begin
        ist := PPtrIdx(Finput_streams, i);
        new_area := ist.st.codec.width * ist.st.codec.height;
        if ((qcr <> MKTAG('A', 'P', 'I', 'C')) and ((ist.st.disposition and AV_DISPOSITION_ATTACHED_PIC) <> 0)) then
          new_area := 1;
        if (ist.st.codec.codec_type = AVMEDIA_TYPE_VIDEO) and
           (new_area > area) and
           (ist.file_index = file_index) then
        begin
          if (qcr = MKTAG('A', 'P', 'I', 'C')) and ((ist.st.disposition and AV_DISPOSITION_ATTACHED_PIC) = 0) then
            Continue;
          area := new_area;
          idx := i;
        end;
      end;
      if idx >= 0 then
      begin
        ost := FindOutputStream(oc, AVMEDIA_TYPE_VIDEO);
        if Assigned(ost) then
        begin
          ost.source_index := idx;
          ost.sync_ist     := PPtrIdx(Finput_streams, idx);
          PPtrIdx(Finput_streams, idx).discard := 0;
          PPtrIdx(Finput_streams, idx).st.discard := AVDISCARD_NONE;
        end;
      end;
    end;

    (* audio: most channels *)
    if (o.audio_disable = 0) and (oc.oformat.audio_codec <> AV_CODEC_ID_NONE) then
    begin
      channels := 0;
      idx := -1;
      for i := 0 to Fnb_input_streams - 1 do
      begin
        ist := PPtrIdx(Finput_streams, i);
        if (ist.st.codec.codec_type = AVMEDIA_TYPE_AUDIO) and
           (ist.st.codec.channels > channels) and
           (ist.file_index = file_index) then
        begin
          channels := ist.st.codec.channels;
          idx := i;
        end;
      end;
      if idx >= 0 then
      begin
        ost := FindOutputStream(oc, AVMEDIA_TYPE_AUDIO);
        if Assigned(ost) then
        begin
          ost.source_index := idx;
          ost.sync_ist     := PPtrIdx(Finput_streams, idx);
          PPtrIdx(Finput_streams, idx).discard := 0;
          PPtrIdx(Finput_streams, idx).st.discard := AVDISCARD_NONE;
        end;
      end;
    end;

    (* subtitles: pick first *)
    //MATCH_PER_TYPE_OPT_codec_names_str(o, oc, 's', @subtitle_codec_name);
    if (o.subtitle_disable = 0) and ((oc.oformat.subtitle_codec <> AV_CODEC_ID_NONE) or Assigned(subtitle_codec_name)) then
    begin
      for i := 0 to Fnb_input_streams - 1 do
      begin
        ist := PPtrIdx(Finput_streams, i);
        if (ist.st.codec.codec_type = AVMEDIA_TYPE_SUBTITLE) and
           (ist.file_index = file_index) then
        begin
          ost := FindOutputStream(oc, AVMEDIA_TYPE_SUBTITLE);
          if Assigned(ost) then
          begin
            ost.source_index := i;
            ost.sync_ist     := ist;
            ist.discard      := 0;
            ist.st.discard   := AVDISCARD_NONE;
          end;
          Break;
        end;
      end;
    end;
    (* do something with data? *)
  end
  else
  begin
    ost := nil; {stop compiler warning}
    for i := 0 to o.nb_stream_maps - 1 do
    begin
      st_map := PtrIdx(o.stream_maps, i);
      src_idx := PPtrIdx(Finput_files, st_map.file_index).ist_index + st_map.stream_index;

      if st_map.disabled <> 0 then
        Continue;

      ist := PPtrIdx(Finput_streams, src_idx);
      if ist.file_index <> file_index then
        Continue;
      if (o.subtitle_disable <> 0) and (ist.st.codec.codec_type = AVMEDIA_TYPE_SUBTITLE) then
        Continue;
      if (o.audio_disable <> 0) and (ist.st.codec.codec_type = AVMEDIA_TYPE_AUDIO) then
        Continue;
      if (o.video_disable <> 0) and (ist.st.codec.codec_type = AVMEDIA_TYPE_VIDEO) then
        Continue;
      if (o.data_disable <> 0) and (ist.st.codec.codec_type = AVMEDIA_TYPE_DATA) then
        Continue;

      case ist.st.codec.codec_type of
        AVMEDIA_TYPE_VIDEO:      ost := FindOutputStream(oc, AVMEDIA_TYPE_VIDEO);
        AVMEDIA_TYPE_AUDIO:      ost := FindOutputStream(oc, AVMEDIA_TYPE_AUDIO);
        AVMEDIA_TYPE_SUBTITLE:   ost := FindOutputStream(oc, AVMEDIA_TYPE_SUBTITLE);
        AVMEDIA_TYPE_DATA:       ost := FindOutputStream(oc, AVMEDIA_TYPE_DATA);
        AVMEDIA_TYPE_ATTACHMENT: ost := FindOutputStream(oc, AVMEDIA_TYPE_ATTACHMENT);
      else
        FLastErrMsg := Format('Cannot map stream #%d:%d - unsupported type.', [st_map.file_index, st_map.stream_index]);
        //Cleanup;
        Exit;
      end;

      if Assigned(ost) then
      begin
        ost.source_index := src_idx;
        ost.sync_ist := PPtrIdx(Finput_streams, PPtrIdx(Finput_files, st_map.sync_file_index).ist_index +
                                       st_map.sync_stream_index);
        ist.discard := 0;
        ist.st.discard := AVDISCARD_NONE;
      end;
    end;
  end;

  // sanity check streams state
  for i := 0 to Integer(oc.nb_streams) - 1 do
  begin
    ost := PPtrIdx(Foutput_streams, Fnb_output_streams - 1 - i);
    if ost.source_index < 0 then
    begin
      FLastErrMsg := 'Cannot join files with diffrent steams state';
      Exit;
    end;
  end;

  // duplicate output file
  Foutput_files := grow_array(Foutput_files, SizeOf(Foutput_files^), @Fnb_output_files, Fnb_output_files + 1);
  PtrIdx(Foutput_files, Fnb_output_files - 1)^ := av_mallocz(SizeOf(Foutput_files^^));
  if not Assigned((PtrIdx(Foutput_files, Fnb_output_files - 1)^)) then
  begin
    RaiseException('av_mallocz() failed');
    //exit_program(1);
  end;
  PPtrIdx(Foutput_files, Fnb_output_files - 1)^ := PPtrIdx(Foutput_files, 0)^;
  with PPtrIdx(Foutput_files, Fnb_output_files - 1)^ do
    ost_index := Fnb_output_streams - Integer(oc.nb_streams);
  Result := Fnb_output_files - 1;
end;

function TCustomFFmpegOpt.UpdateJoinMode(o: POptionsContext): Integer;
var
  i, j: Integer;
  ic: PAVFormatContext;
  s: PAVFormatContext;
  ost: POutputStream;
begin
  Fnb_output_streams_join := PPtrIdx(Foutput_files, 0).ctx.nb_streams;

  // duplicate output files and streams
  for i := 1 to Fnb_input_files - 1 do
    if join_output_file(o, i) < 0 then
    begin
      // free output_streams
      for j := 0 to Fnb_output_streams_join - 1 do
      begin
        ost := PPtrIdx(Foutput_streams, j);
        if Assigned(ost) then
        begin
          if ost.stream_copy <> 0 then
            av_freep(@ost.st.codec.extradata);
          // close two pass logfile
          if Assigned(ost.logfile) then
          begin
            my_fclose(ost.logfile);
            ost.logfile := nil;
          end;
          av_freep(@ost.st.codec.subtitle_header);
          av_freep(@ost.forced_kf_pts);
          av_freep(@ost.apad);
          av_dict_free(@ost.opts);
          av_dict_free(@ost.swr_opts);
          av_dict_free(@ost.resample_opts);
        end;
      end;
      // close output file
      s := PPtrIdx(Foutput_files, 0).ctx;
      if ((s.oformat.flags and AVFMT_NOFILE) = 0) and Assigned(s.pb) then
        avio_close(s.pb);
      // hack: remove zero file
      if ((s.oformat.flags and AVFMT_NOFILE) = 0) and
        (MyUtils.GetFileSize(delphi_filename(s.filename)) = 0) then
{$IFDEF VCL_XE2_OR_ABOVE}
        System.SysUtils.DeleteFile(delphi_filename(s.filename));
{$ELSE}
        SysUtils.DeleteFile(delphi_filename(s.filename));
{$ENDIF}
      // hack end
      avformat_free_context(s);
      av_dict_free(@POutputFile(PPtrIdx(Foutput_files, 0)).opts); // TODO: only 0 or all outputs?
      for j := 0 to Fnb_output_files - 1 do
        av_freep(@POutputFile(PtrIdx(Foutput_files, j)^));
      Fnb_output_files := 0;
      av_freep(@Foutput_files);
      // free output_streams
      FreeOutputStreams;
      av_freep(@Foutput_streams);
      // reset join mode
      Result := -1;
      FJoinMode := False;
      Fnb_output_streams_join := 0;
      Exit;
    end;

  // update output duration
  FOutputDuration := 0;
  for I := 0 to Fnb_input_files - 1 do
  begin
    ic := PPtrIdx(Finput_files, I).ctx;
    if ic.duration <> AV_NOPTS_VALUE then
      Inc(FOutputDuration, ic.duration);
  end;
  if FOutputDuration = 0 then
    FOutputDuration := -1;

  Result := 0;
end;

procedure TCustomFFmpegOpt.FreeOutputStreams;
var
  i: Integer;
  bsfc: PAVBitStreamFilterContext;
  bsfc_next: PAVBitStreamFilterContext;
begin
  for i := 0 to Fnb_output_streams - 1 do
  begin
    bsfc := PPtrIdx(Foutput_streams, i).bitstream_filters;
    while Assigned(bsfc) do
    begin
      bsfc_next := bsfc.next;
      av_bitstream_filter_close(bsfc);
      bsfc := bsfc_next;
    end;
    PPtrIdx(Foutput_streams, i).bitstream_filters := nil;
    avcodec_free_frame(@PAVFrame(PPtrIdx(Foutput_streams, i).filtered_frame));

    av_freep(@PAnsiChar(PPtrIdx(Foutput_streams, i).forced_keyframes));
    av_expr_free(PPtrIdx(Foutput_streams, i).forced_keyframes_pexpr);
    av_freep(@PAnsiChar(PPtrIdx(Foutput_streams, i).avfilter));
    av_freep(@PAnsiChar(PPtrIdx(Foutput_streams, i).logfile_prefix));
    av_freep(@POutputStream(PtrIdx(Foutput_streams, i)^));
  end;
  Fnb_output_streams := 0; // hack: reset
end;

function TCustomFFmpegOpt.opt_target(optctx: Pointer; opt, arg: PAnsiChar): Integer;
type
  TNorm = (PAL, NTSC, FILM, UNKNOWN);
const
  frame_rates: array[TNorm] of PAnsiChar = ('25', '30000/1001', '24000/1001', '');
var
  o: POptionsContext;
  S: string;
  norm: TNorm;
  i, j, fr: Integer;
  c: PAVCodecContext;
begin
  o := optctx;
  S := string(arg);
  if Pos('pal-', S) = 1 then
  begin
    norm := PAL;
    Inc(arg, 4);
  end
  else if Pos('ntsc-', S) = 1 then
  begin
    norm := NTSC;
    Inc(arg, 5);
  end
  else if Pos('film-', S) = 1 then
  begin
    norm := FILM;
    Inc(arg, 5);
  end
  else
  begin
    norm := UNKNOWN;
    (* Try to determine PAL/NTSC by peeking in the input files *)
    for j := 0 to Fnb_input_files - 1 do
    begin
      for i := 0 to PPtrIdx(Finput_files, j).nb_streams - 1 do
      begin
        c := PPtrIdx(PPtrIdx(Finput_files, j).ctx.streams, i).codec;
        if c.codec_type <> AVMEDIA_TYPE_VIDEO then
          Continue;
        fr := Round(c.time_base.den * 1000 / c.time_base.num);
        if fr = 25000 then
        begin
          norm := PAL;
          Break;
        end
        else if (fr = 29970) or (fr = 23976) then
        begin
          norm := NTSC;
          Break;
        end;
      end;
      if norm <> UNKNOWN then
        Break;
    end;
    if norm <> UNKNOWN then
    begin
      if norm <> PAL then
        FFLogger.Log(Self, llInfo, Format('Assuming %s for target.', ['NTSC']))
      else
        FFLogger.Log(Self, llInfo, Format('Assuming %s for target.', ['PAL']));
    end
    else
    begin
      RaiseException('Could not determine norm (PAL/NTSC/NTSC-Film) for target.' + #13#10 +
              'Please prefix target with "pal-", "ntsc-" or "film-",' + #13#10 +
              'or set a framerate with "-r xxx".');
      //exit_program(1);
    end;
  end;

  if arg = 'vcd' then
  begin
    opt_video_codec(o, 'c:v', 'mpeg1video');
    opt_audio_codec(o, 'c:a', 'mp2');
    parse_option(o, 'f', 'vcd', FOptionDef);
//??    av_dict_set(@o.g.codec_opts, 'b:v', arg, 0);

    if norm = PAL then
      parse_option(o, 's', '352x288', FOptionDef)
    else
      parse_option(o, 's', '352x240', FOptionDef);
    parse_option(o, 'r', frame_rates[norm], FOptionDef);
    if norm = PAL then
      av_dict_set(@o.g.codec_opts, 'g', '15', 0)
    else
      av_dict_set(@o.g.codec_opts, 'g', '18', 0);

    av_dict_set(@o.g.codec_opts, 'b:v', '1150000', 0);
    av_dict_set(@o.g.codec_opts, 'maxrate', '1150000', 0);
    av_dict_set(@o.g.codec_opts, 'minrate', '1150000', 0);
    av_dict_set(@o.g.codec_opts, 'bufsize', '327680', 0); // 40*1024*8;

    av_dict_set(@o.g.codec_opts, 'b:a', '224000', 0);
    parse_option(o, 'ar', '44100', FOptionDef);
    parse_option(o, 'ac', '2', FOptionDef);

    av_dict_set(@o.g.format_opts, 'packetsize', '2324', 0);
    av_dict_set(@o.g.format_opts, 'muxrate', '1411200', 0); // 2352 * 75 * 8;

    (* We have to offset the PTS, so that it is consistent with the SCR.
       SCR starts at 36000, but the first two packs contain only padding
       and the first pack from the other stream, respectively, may also have
       been written before.
       So the real data starts at SCR 36000+3*1200. *)
    o.mux_preload := (36000+3*1200) / 90000.0; // 0.44
  end
  else if arg = 'svcd' then
  begin
    opt_video_codec(o, 'c:v', 'mpeg2video');
    opt_audio_codec(o, 'c:a', 'mp2');
    parse_option(o, 'f', 'svcd', FOptionDef);

    if norm = PAL then
      parse_option(o, 's', '480x576', FOptionDef)
    else
      parse_option(o, 's', '480x480', FOptionDef);
    parse_option(o, 'r', frame_rates[norm], FOptionDef);
    parse_option(o, 'pix_fmt', 'yuv420p', FOptionDef);
    if norm = PAL then
      av_dict_set(@o.g.codec_opts, 'g', '15', 0)
    else
      av_dict_set(@o.g.codec_opts, 'g', '18', 0);

    av_dict_set(@o.g.codec_opts, 'b:v', '2040000', 0);
    av_dict_set(@o.g.codec_opts, 'maxrate', '2516000', 0);
    av_dict_set(@o.g.codec_opts, 'minrate', '0', 0); // 1145000;
    av_dict_set(@o.g.codec_opts, 'bufsize', '1835008', 0); // 224*1024*8;
    av_dict_set(@o.g.codec_opts, 'scan_offset', '1', 0);

    av_dict_set(@o.g.codec_opts, 'b:a', '224000', 0);
    parse_option(o, 'ar', '44100', FOptionDef);

    av_dict_set(@o.g.format_opts, 'packetsize', '2324', 0);
  end
  else if arg = 'dvd' then
  begin
    opt_video_codec(o, 'c:v', 'mpeg2video');
    opt_audio_codec(o, 'c:a', 'ac3');
    parse_option(o, 'f', 'dvd', FOptionDef);

    if norm = PAL then
      parse_option(o, 's', '720x576', FOptionDef)
    else
      parse_option(o, 's', '720x480', FOptionDef);
    parse_option(o, 'r', frame_rates[norm], FOptionDef);
    parse_option(o, 'pix_fmt', 'yuv420p', FOptionDef);
    if norm = PAL then
      av_dict_set(@o.g.codec_opts, 'g', '15', 0)
    else
      av_dict_set(@o.g.codec_opts, 'g', '18', 0);

    av_dict_set(@o.g.codec_opts, 'b:v', '6000000', 0);
    av_dict_set(@o.g.codec_opts, 'maxrate', '9000000', 0);
    av_dict_set(@o.g.codec_opts, 'minrate', '0', 0); // 1500000;
    av_dict_set(@o.g.codec_opts, 'bufsize', '1835008', 0); // 224*1024*8;

    av_dict_set(@o.g.format_opts, 'packetsize', '2048', 0);  // from www.mpucoder.com: DVD sectors contain 2048 bytes of data, this is also the size of one pack.
    av_dict_set(@o.g.format_opts, 'muxrate', '10080000', 0); // from mplex project: data_rate = 1260000. mux_rate = data_rate * 8

    av_dict_set(@o.g.codec_opts, 'b:a', '448000', 0);
    parse_option(o, 'ar', '48000', FOptionDef);
  end
  else if (arg^ = 'd') and (PAnsiChar(arg + 1) = 'v') then
  begin
    parse_option(o, 'f', 'dv', FOptionDef);

    if norm = PAL then
      parse_option(o, 's', '720x576', FOptionDef)
    else
      parse_option(o, 's', '720x480', FOptionDef);

    if arg = 'dv50' then
      parse_option(o, 'pix_fmt', 'yuv422p', FOptionDef)
    else if norm = PAL then
      parse_option(o, 'pix_fmt', 'yuv420p', FOptionDef) // dv25
    else
      parse_option(o, 'pix_fmt', 'yuv411p', FOptionDef);
    parse_option(o, 'r', frame_rates[norm], FOptionDef);

    parse_option(o, 'ar', '48000', FOptionDef);
    parse_option(o, 'ac', '2', FOptionDef);
  end
  else
  begin
    GOptionError := Format('Unknown target: %s', [string(arg)]);
    FFLogger.Log(Self, llError, GOptionError);
    Result := AVERROR_EINVAL;
    Exit;
  end;
  Result := 0;
end;

function TCustomFFmpegOpt.opt_vstats_file(optctx: Pointer; opt, arg: PAnsiChar): Integer;
begin
  av_freep(@Fvstats_filename);
  Fvstats_filename := av_strdup(arg);
  Result := 0;
end;

function TCustomFFmpegOpt.opt_vstats(optctx: Pointer; opt, arg: PAnsiChar): Integer;
var
  S: string;
begin
  DateTimeToString(S, 'hhnnss', Now);
  S := Format('vstats_%s.log', [S]);
  Result := opt_vstats_file(nil, opt, PAnsiChar(AnsiString(S)));
end;

function TCustomFFmpegOpt.opt_video_frames(optctx: Pointer; opt, arg: PAnsiChar): Integer;
begin
  Result := parse_option(optctx, 'frames:v', arg, FOptionDef);
end;

function TCustomFFmpegOpt.opt_audio_frames(optctx: Pointer; opt, arg: PAnsiChar): Integer;
begin
  Result := parse_option(optctx, 'frames:a', arg, FOptionDef);
end;

function TCustomFFmpegOpt.opt_data_frames(optctx: Pointer; opt, arg: PAnsiChar): Integer;
begin
  Result := parse_option(optctx, 'frames:d', arg, FOptionDef);
end;

function TCustomFFmpegOpt.opt_default_new(o: POptionsContext; opt, arg: PAnsiChar): Integer;
var
  ret: Integer;
  cbak: PAVDictionary;
  fbak: PAVDictionary;
begin
  cbak := FOptions.codec_opts;
  fbak := FOptions.format_opts;
  FOptions.codec_opts := nil;
  FOptions.format_opts := nil;

  ret := FOptions.opt_default(opt, arg);

  av_dict_copy(@o.g.codec_opts, FOptions.codec_opts, 0);
  av_dict_copy(@o.g.format_opts, FOptions.format_opts, 0);
  av_dict_free(@FOptions.codec_opts);
  av_dict_free(@FOptions.format_opts);
  FOptions.codec_opts := cbak;
  FOptions.format_opts := fbak;

  Result := ret;
end;

function TCustomFFmpegOpt.opt_preset(optctx: Pointer; opt, arg: PAnsiChar): Integer;
var
  o: POptionsContext;
  preset: string;
  SL: TStringList;
  I: Integer;
  line: string;
  key, value: string;
  error: string;
  ret: Integer;
begin
  Assert(opt^ in ['v', 'a', 's', 'f']);
  o := optctx;

  preset := string(arg);
  if not FileExists(preset) then
  begin
    GOptionError := Format('Preset file "%s" not found', [preset]);
    FFLogger.Log(Self, llError, GOptionError);
    Result := AVERROR_EINVAL;
    Exit;
    //exit_program(1);
  end;

  SL := TStringList.Create;
  try
    SL.LoadFromFile(preset);
    FFLogger.Log(Self, llInfo, 'Parse preset file: %s', [preset]);
    for I := 0 to SL.Count - 1 do
    begin
      line := Trim(SL.Strings[I]);
      if (line = '') or (line[1] = '#') then
        Continue;
      value := line;
      key := Fetch(value, '=');
      if (key = '') or (value = '') then
      begin
        error := Format('%s: Invalid syntax: "%s"', [preset, line]);
        FFLogger.Log(Self, llError, error);
        if HaltOnInvalidOption then
        begin
          GOptionError := error;
          Result := AVERROR_EINVAL;
          Exit;
          //exit_program(1);
        end;
      end;
      FFLogger.Log(Self, llDebug, 'Applying preset %s with argument %s.'#10,
                  [key, value]);
      GOptionError := '';
      if SameText(key, 'acodec') then
        ret := opt_audio_codec(o, PAnsiChar(AnsiString(key)), PAnsiChar(AnsiString(value)))
      else if SameText(key, 'vcodec') then
        ret := opt_video_codec(o, PAnsiChar(AnsiString(key)), PAnsiChar(AnsiString(value)))
      else if SameText(key, 'scodec') then
        ret := opt_subtitle_codec(o, PAnsiChar(AnsiString(key)), PAnsiChar(AnsiString(value)))
      else if SameText(key, 'dcodec') then
        ret := opt_data_codec(o, PAnsiChar(AnsiString(key)), PAnsiChar(AnsiString(value)))
      else
        ret := opt_default_new(o, PAnsiChar(AnsiString(key)), PAnsiChar(AnsiString(value)));
      if ret < 0 then
      begin
        error := Format('%s: Invalid option or argument: "%s", parsed as "%s" = "%s"',
                        [ExtractFileName(preset), line, key, value]);
        FFLogger.Log(Self, llError, error);
        if HaltOnInvalidOption then
        begin
          if GOptionError <> '' then
            GOptionError := GOptionError + #13#10 + error
          else
            GOptionError := error;
          Result := ret;
          Exit;
        end;
        //exit_program(1);
      end;
    end;
    Result := 0;
  finally
    SL.Free;
  end;
end;

function TCustomFFmpegOpt.ParsePresets(o: POptionsContext; APresets: AnsiString; inout: string): Integer;
var
  S, line, key, value: string;
  ret: Integer;
  error: string;
begin
  if APresets = '' then
  begin
    Result := 0;
    Exit;
  end;
  FFLogger.Log(Self, llInfo, 'ParsePresets for %s:%s%s', [inout, sLineBreak, AdjustLineBreaks(string(APresets), tlbsCRLF)]);
  S := AdjustLineBreaks(Trim(string(APresets)), tlbsLF);
  S := StringReplace(S, '<CRLF>', #10, [rfReplaceAll]);
  while S <> '' do
  begin
    line := Trim(Fetch(S, #10));
    if (line = '') or (line[1] = '#') then
      Continue;
    value := line;
    key := Fetch(value, '=');
    if (key = '') or (value = '') then
    begin
      error := Format('Invalid syntax: "%s"', [line]);
      FFLogger.Log(Self, llError, error);
      if HaltOnInvalidOption then
      begin
        GOptionError := error;
        Result := AVERROR_EINVAL;
        Exit;
      end;
    end;
    FFLogger.Log(Self, llDebug, 'Applying preset %s with argument %s.'#10,
                [key, value]);
    GOptionError := '';
    if SameText(key, 'acodec') then
      ret := opt_audio_codec(o, PAnsiChar(AnsiString(key)), PAnsiChar(AnsiString(value)))
    else if SameText(key, 'vcodec') then
      ret := opt_video_codec(o, PAnsiChar(AnsiString(key)), PAnsiChar(AnsiString(value)))
    else if SameText(key, 'scodec') then
      ret := opt_subtitle_codec(o, PAnsiChar(AnsiString(key)), PAnsiChar(AnsiString(value)))
    else if SameText(key, 'dcodec') then
      ret := opt_data_codec(o, PAnsiChar(AnsiString(key)), PAnsiChar(AnsiString(value)))
    else
      ret := opt_default_new(o, PAnsiChar(AnsiString(key)), PAnsiChar(AnsiString(value)));
    if ret < 0 then
    begin
      error := Format('Invalid option or argument: "%s", parsed as "%s" = "%s"',
                      [line, key, value]);
      FFLogger.Log(Self, llError, error);
      if HaltOnInvalidOption then
      begin
        if GOptionError <> '' then
          GOptionError := GOptionError + #13#10 + error
        else
          GOptionError := error;
        Result := ret;
        Exit;
      end;
    end;
  end;
  Result := 0;
end;

function TCustomFFmpegOpt.opt_old2new(optctx: Pointer; opt, arg: PAnsiChar): Integer;
var
  s: PAnsiChar;
begin
  s := av_asprintf('%s:%c', opt + 1, opt^);
  Result := parse_option(optctx, s, arg, FOptionDef);
  av_free(s);
end;

function TCustomFFmpegOpt.opt_bitrate(optctx: Pointer; opt, arg: PAnsiChar): Integer;
var
  o: POptionsContext;
begin
  o := optctx;
  if opt = 'b' then
  begin
    FFLogger.Log(Self, llWarning, 'Please use -b:a or -b:v, -b is ambiguous');
    av_dict_set(@o.g.codec_opts, 'b:v', arg, 0);
  end
  else
    av_dict_set(@o.g.codec_opts, opt, arg, 0);
  Result := 0;
end;

function TCustomFFmpegOpt.opt_qscale(optctx: Pointer; opt, arg: PAnsiChar): Integer;
var
  s: PAnsiChar;
begin
  if my_strcmp(opt, 'qscale') = 0 then
  begin
    FFLogger.Log(Self, llWarning, 'Please use -q:a or -q:v, -qscale is ambiguous');
    Result := parse_option(optctx, 'q:v', arg, FOptionDef);
    Exit;
  end;
  s := av_asprintf('q%s', opt + 6);
  Result := parse_option(optctx, s, arg, FOptionDef);
  av_free(s);
end;

function TCustomFFmpegOpt.opt_profile(optctx: Pointer; opt, arg: PAnsiChar): Integer;
var
  o: POptionsContext;
begin
  o := optctx;
  if my_strcmp(opt, 'profile') = 0 then
  begin
    FFLogger.Log(Self, llWarning, 'Please use -profile:a or -profile:v, -profile is ambiguous');
    av_dict_set(@o.g.codec_opts, 'profile:v', arg, 0);
  end
  else
    av_dict_set(@o.g.codec_opts, opt, arg, 0);
  Result := 0;
end;

function TCustomFFmpegOpt.opt_video_filters(optctx: Pointer; opt, arg: PAnsiChar): Integer;
begin
  Result := parse_option(optctx, 'filter:v', arg, FOptionDef);
end;

function TCustomFFmpegOpt.opt_audio_filters(optctx: Pointer; opt, arg: PAnsiChar): Integer;
begin
  Result := parse_option(optctx, 'filter:a', arg, FOptionDef);
end;

function TCustomFFmpegOpt.opt_vsync(optctx: Pointer; opt, arg: PAnsiChar): Integer;
var
  i: Integer;
begin
  if      av_strcasecmp(arg, 'cfr') = 0 then         Fvideo_sync_method := VSYNC_CFR
  else if av_strcasecmp(arg, 'vfr') = 0 then         Fvideo_sync_method := VSYNC_VFR
  else if av_strcasecmp(arg, 'passthrough') = 0 then Fvideo_sync_method := VSYNC_PASSTHROUGH
  else if av_strcasecmp(arg, 'drop') = 0 then        Fvideo_sync_method := VSYNC_DROP;

  if Fvideo_sync_method = VSYNC_AUTO then
  begin
    i := StrToIntDef(string(arg), Low(Integer));
    case i of
      VSYNC_AUTO, VSYNC_PASSTHROUGH, VSYNC_CFR, VSYNC_VFR, VSYNC_DROP:
        Fvideo_sync_method := i;
    else
      begin
        GOptionError := Format('The value for "%s" was "%s" which is invalid',
                              ['vsync', string(arg)]);
        FFLogger.Log(Self, llError, GOptionError);
        Result := AVERROR_EINVAL;
        Exit;
      end;
    end;
  end;
  Result := 0;
end;

function TCustomFFmpegOpt.opt_timecode(optctx: Pointer; opt, arg: PAnsiChar): Integer;
var
  o: POptionsContext;
  tcr: PAnsiChar;
  ret: Integer;
begin
  o := optctx;
  tcr := av_asprintf('timecode=%s', arg);
  ret := parse_option(optctx, 'metadata:g', tcr, FOptionDef);
  if ret >= 0 then
    {ret := }av_dict_set(@o.g.codec_opts, 'gop_timecode', arg, 0);
  av_free(tcr);
  Result := 0;
end;

function TCustomFFmpegOpt.opt_channel_layout(optctx: Pointer; opt, arg: PAnsiChar): Integer;
var
  str: string;
  //char layout_str[32];
  stream_str: PAnsiChar;
  ac_str: PAnsiChar;
  ret, channels, ac_str_size: Integer;
  layout: Int64;
begin
  layout := av_get_channel_layout(arg);
  if layout = 0 then
  begin
    GOptionError := Format('Unknown channel layout: %s', [string(arg)]);
    FFLogger.Log(Self, llError, GOptionError);
    Result := AVERROR_EINVAL;
    Exit;
  end;
  str := IntToStr(layout);
  //snprintf(layout_str, sizeof(layout_str), "%"PRIu64, layout);
  //ret = opt_default_new(o, opt, layout_str);
  ret := opt_default_new(optctx, opt, PAnsiChar(AnsiString(str)));
  if ret < 0 then
  begin
    Result := ret;
    Exit;
  end;

  (* set 'ac' option based on channel layout *)
  channels := av_get_channel_layout_nb_channels(layout);
  str := IntToStr(channels);
  stream_str := my_strchr(opt, ':');
  if Assigned(stream_str) then
    ac_str_size := 3 + MyStrLen(stream_str)
  else
    ac_str_size := 3;
  ac_str := av_mallocz(ac_str_size);
  if not Assigned(ac_str) then
  begin
    Result := AVERROR_ENOMEM;
    Exit;
  end;
  av_strlcpy(ac_str, 'ac', 3);
  if Assigned(stream_str) then
    av_strlcat(ac_str, stream_str, ac_str_size);
  ret := parse_option(optctx, ac_str, PAnsiChar(AnsiString(str)), FOptionDef);
  av_free(ac_str);

  Result := ret;
end;

function TCustomFFmpegOpt.opt_audio_qscale(optctx: Pointer; opt, arg: PAnsiChar): Integer;
begin
  Result := parse_option(optctx, 'q:a', arg, FOptionDef);
end;

function TCustomFFmpegOpt.opt_filter_complex(optctx: Pointer; opt, arg: PAnsiChar): Integer;
begin
  Ffiltergraphs := grow_array(Ffiltergraphs, SizeOf(Ffiltergraphs^),
                              @Fnb_filtergraphs, Fnb_filtergraphs + 1);
  PtrIdx(Ffiltergraphs, Fnb_filtergraphs - 1)^ := av_mallocz(SizeOf(Ffiltergraphs^^));
  if not Assigned(PtrIdx(Ffiltergraphs, Fnb_filtergraphs - 1)^) then
  begin
    Result := AVERROR_ENOMEM;
    Exit;
  end;
  PPtrIdx(Ffiltergraphs, Fnb_filtergraphs - 1).index      := Fnb_filtergraphs - 1;
  PPtrIdx(Ffiltergraphs, Fnb_filtergraphs - 1).graph_desc := av_strdup(arg);
  if not Assigned(PPtrIdx(Ffiltergraphs, Fnb_filtergraphs - 1).graph_desc) then
    Result := AVERROR_ENOMEM
  else
    Result := 0;
end;

function TCustomFFmpegOpt.opt_filter_complex_script(optctx: Pointer; opt, arg: PAnsiChar): Integer;
var
  graph_desc: PAnsiChar;
begin
  graph_desc := read_file(arg);
  if not Assigned(graph_desc) then
  begin
    Result := AVERROR_EINVAL;
    Exit;
  end;

  Ffiltergraphs := grow_array(Ffiltergraphs, SizeOf(Ffiltergraphs^),
                              @Fnb_filtergraphs, Fnb_filtergraphs + 1);
  PtrIdx(Ffiltergraphs, Fnb_filtergraphs - 1)^ := av_mallocz(SizeOf(Ffiltergraphs^^));
  if not Assigned(PtrIdx(Ffiltergraphs, Fnb_filtergraphs - 1)^) then
  begin
    Result := AVERROR_ENOMEM;
    Exit;
  end;
  PPtrIdx(Ffiltergraphs, Fnb_filtergraphs - 1).index      := Fnb_filtergraphs - 1;
  PPtrIdx(Ffiltergraphs, Fnb_filtergraphs - 1).graph_desc := graph_desc;
  Result := 0;
end;

function TCustomFFmpegOpt.opt_progress(optctx: Pointer; opt, arg: PAnsiChar): Integer;
var
  avio: PAVIOContext;
  ret: Integer;
begin
  avio := nil;

  if my_strcmp(arg, '-') = 0 then
    arg := 'pipe:';
  FLastWrite := av_gettime(); // hack: for write timeout
  ret := avio_open2(@avio, arg, AVIO_FLAG_WRITE, @FWriteCallback, nil);
  if ret < 0 then
  begin
    GOptionError := Format('Failed to open progress URL "%s": %s', [string(arg), print_error('', ret)]);
    FFLogger.Log(Self, llError, GOptionError);
    Result := ret;
    Exit;
  end;
  Fprogress_avio := avio;
  Result := 0;
end;

// hack: -ss in microseconds unit
function TCustomFFmpegOpt.opt_TimeStart(optctx: Pointer; opt, arg: PAnsiChar): Integer;
var
  I: Int64;
begin
  try
    I := Round(StrToFloat(string(arg)) * 1000000);
    Result := parse_option(optctx, 'ss_microsecond', PAnsiChar(AnsiString(IntToStr(I))), FOptionDef);
  except on E: Exception do
    begin
      GOptionError := E.Message;
      FFLogger.Log(Self, llError, GOptionError);
      Result := AVERROR_EINVAL;
    end;
  end;
end;

// hack: -t in microseconds unit
function TCustomFFmpegOpt.opt_TimeLength(optctx: Pointer; opt, arg: PAnsiChar): Integer;
var
  I: Int64;
begin
  try
    I := Round(StrToFloat(string(arg)) * 1000000);
    Result := parse_option(optctx, 't_microsecond', PAnsiChar(AnsiString(IntToStr(I))), FOptionDef);
  except on E: Exception do
    begin
      GOptionError := E.Message;
      FFLogger.Log(Self, llError, GOptionError);
      Result := AVERROR_EINVAL;
    end;
  end;
end;

function TCustomFFmpegOpt.opt_loglevel(optctx: Pointer; opt, arg: PAnsiChar): Integer;
begin
  Result := ff_opt_loglevel(optctx, opt, arg);
end;

// cmdutils
function TCustomFFmpegOpt.opt_max_alloc(optctx: Pointer; opt, arg: PAnsiChar): Integer;
var
  tail: PAnsiChar;
  max: Cardinal;
begin
  max := my_strtol(arg, @tail, 10);
  if tail^ <> #0 then
  begin
    GOptionError := Format('Invalid max_alloc "%s".', [arg]);
    FFLogger.Log(Self, llFatal, GOptionError);
    Result := AVERROR_EINVAL;
  end
  else
  begin
    av_max_alloc(max);
    Result := 0;
  end;
end;

// cmdutils
function TCustomFFmpegOpt.opt_cpuflags(optctx: Pointer; opt, arg: PAnsiChar): Integer;
var
  ret: Integer;
  flags: Cardinal;
begin
  flags := av_get_cpu_flags();

  ret := av_parse_cpu_caps(@flags, arg);
  if ret < 0 then
  begin
    GOptionError := print_error(Format('Failed to parse cpu flags "%s"', [arg]), ret);
    FFLogger.Log(Self, llFatal, GOptionError);
    Result := ret;
    Exit;
  end;

  av_force_cpu_flags(flags);
  Result := 0;
end;

function TCustomFFmpegOpt.ParseOptions(o: POptionsContext; AOptions, APresets: AnsiString; inout: string; filename: PAnsiChar; group_flags: Integer): Integer;
var
  p: PAnsiChar;
  cmdstart: PAnsiChar;
  numargs, numchars: Integer;
  argc: Integer;
  argv: PPAnsiChar;
  error: string;
  ret: Integer;
begin
  if AOptions = '' then
    ret := ParsePresets(o, APresets, inout)
  else
  begin
    FFLogger.Log(Self, llInfo, 'ParseOptions for %s: %s', [inout, string(AOptions)]);
    cmdstart := PAnsiChar(AOptions);
    (* first find out how much space is needed to store args *)
    parse_cmdline(cmdstart, nil, nil, @numargs, @numchars);
    (* allocate space for argv[] vector and strings *)
    GetMem(p, numargs * SizeOf(PAnsiChar) + numchars * SizeOf(AnsiChar));
    try
      (* store args and argv ptrs in just allocated block *)
      parse_cmdline(cmdstart, PPAnsiChar(p), p + numargs * SizeOf(PAnsiChar), @numargs, @numchars);
      (* set argv and argc *)
      argc := numargs - 1;
      argv := PPAnsiChar(p);
      parse_loglevel(argc, argv, FOptionDef);
      GOptionError := '';
      ret := FOptions.parse_options(o, argc, argv, FOptionDef, inout, HaltOnInvalidOption);

      if (ret >= 0) and (FOptions.OptionParseContext.global_opts.nb_opts > 0) then
        (* apply global options *)
        ret := parse_optgroup(nil, @FOptions.OptionParseContext.global_opts, 'global', '', 0, HaltOnInvalidOption);

      if ret >= 0 then
        ret := ParsePresets(o, APresets, inout);

      if (ret >= 0) and (FOptions.OptionParseContext.file_opts.nb_opts > 0) then
        ret := parse_optgroup(o, @FOptions.OptionParseContext.file_opts, inout, filename, group_flags, HaltOnInvalidOption);
    finally
      FreeMem(p);
    end;
  end;

  if HaltOnInvalidOption then
    Result := ret
  else
    Result := 0;

  if ret < 0 then
  begin
    error := print_error(error, ret);
    FFLogger.Log(Self, llFatal, error);
    if HaltOnInvalidOption then
    begin
      if GOptionError <> '' then
        FLastErrMsg := GOptionError + #13#10 + error
      else
        FLastErrMsg := error;
    end;
  end;
end;

procedure TCustomFFmpegOpt.InitOptionDef;
var
  oc_tmp: TOptionsContext;
  head_address: Integer;
  p: POptionDef;
begin
  if Assigned(FOptionDef) then Exit;
  FOptionDef := @_OptionDef[0];
  //#define OFFSET(x) offsetof(OptionsContext, x)
  head_address := Integer(@oc_tmp);
  p := FOptionDef;

  (* main options *)
//  { "L"          , OPT_EXIT, {.func_arg = show_license},      "show license" },
  p.name := 'L';
  p.flags := OPT_EXIT;
  p.u.func_arg := opt_ignore;
  p.help := 'show license';
  Inc(p);
//  { "h"          , OPT_EXIT, {.func_arg = show_help},         "show help", "topic" },
  p.name := 'h';
  p.flags := OPT_EXIT;
  p.u.func_arg := opt_ignore;
  p.help := 'show help';
  p.argname := 'topic';
  Inc(p);
//  { "?"          , OPT_EXIT, {.func_arg = show_help},         "show help", "topic" },
  p.name := '?';
  p.flags := OPT_EXIT;
  p.u.func_arg := opt_ignore;
  p.help := 'show help';
  p.argname := 'topic';
  Inc(p);
//  { "help"       , OPT_EXIT, {.func_arg = show_help},         "show help", "topic" },
  p.name := 'help';
  p.flags := OPT_EXIT;
  p.u.func_arg := opt_ignore;
  p.help := 'show help';
  p.argname := 'topic';
  Inc(p);
//  { "-help"      , OPT_EXIT, {.func_arg = show_help},         "show help", "topic" },
  p.name := '-help';
  p.flags := OPT_EXIT;
  p.u.func_arg := opt_ignore;
  p.help := 'show help';
  p.argname := 'topic';
  Inc(p);
//  { "version"    , OPT_EXIT, {.func_arg = show_version},      "show version" },
  p.name := 'version';
  p.flags := OPT_EXIT;
  p.u.func_arg := opt_ignore;
  p.help := 'show version';
  Inc(p);
//  { "formats"    , OPT_EXIT, {.func_arg = show_formats  },    "show available formats" },
  p.name := 'formats';
  p.flags := OPT_EXIT;
  p.u.func_arg := opt_ignore;
  p.help := 'show available formats';
  Inc(p);
//  { "codecs"     , OPT_EXIT, {.func_arg = show_codecs   },    "show available codecs" },
  p.name := 'codecs';
  p.flags := OPT_EXIT;
  p.u.func_arg := opt_ignore;
  p.help := 'show available codecs';
  Inc(p);
//  { "decoders"   , OPT_EXIT, {.func_arg = show_decoders },    "show available decoders" },
  p.name := 'decoders';
  p.flags := OPT_EXIT;
  p.u.func_arg := opt_ignore;
  p.help := 'show available decoders';
  Inc(p);
//  { "encoders"   , OPT_EXIT, {.func_arg = show_encoders },    "show available encoders" },
  p.name := 'encoders';
  p.flags := OPT_EXIT;
  p.u.func_arg := opt_ignore;
  p.help := 'show available encoders';
  Inc(p);
//  { "bsfs"       , OPT_EXIT, {.func_arg = show_bsfs     },    "show available bit stream filters" },
  p.name := 'bsfs';
  p.flags := OPT_EXIT;
  p.u.func_arg := opt_ignore;
  p.help := 'show available bit stream filters';
  Inc(p);
//  { "protocols"  , OPT_EXIT, {.func_arg = show_protocols},    "show available protocols" },
  p.name := 'protocols';
  p.flags := OPT_EXIT;
  p.u.func_arg := opt_ignore;
  p.help := 'show available protocols';
  Inc(p);
//  { "filters"    , OPT_EXIT, {.func_arg = show_filters  },    "show available filters" },
  p.name := 'filters';
  p.flags := OPT_EXIT;
  p.u.func_arg := opt_ignore;
  p.help := 'show available filters';
  Inc(p);
//  { "pix_fmts"   , OPT_EXIT, {.func_arg = show_pix_fmts },    "show available pixel formats" },
  p.name := 'pix_fmts';
  p.flags := OPT_EXIT;
  p.u.func_arg := opt_ignore;
  p.help := 'show available pixel formats';
  Inc(p);
//  { "layouts"    , OPT_EXIT, {.func_arg = show_layouts  },    "show standard channel layouts" },
  p.name := 'layouts';
  p.flags := OPT_EXIT;
  p.u.func_arg := opt_ignore;
  p.help := 'show standard channel layouts';
  Inc(p);
//  { "sample_fmts", OPT_EXIT, {.func_arg = show_sample_fmts }, "show available audio sample formats" },
  p.name := 'sample_fmts';
  p.flags := OPT_EXIT;
  p.u.func_arg := opt_ignore;
  p.help := 'show available audio sample formats';
  Inc(p);
//  { "colors"     , OPT_EXIT, {.func_arg = show_colors },      "show available color names" },
  p.name := 'colors';
  p.flags := OPT_EXIT;
  p.u.func_arg := opt_ignore;
  p.help := 'show available color names';
  Inc(p);
//  { "loglevel"   , HAS_ARG,  {.func_arg = opt_loglevel},      "set logging level", "loglevel" },
  p.name := 'loglevel';
  p.flags := HAS_ARG;
  p.u.func_arg := opt_loglevel;
  p.help := 'set logging level';
  p.argname := 'loglevel';
  Inc(p);
//  { "v",           HAS_ARG,  {.func_arg = opt_loglevel},      "set logging level", "loglevel" },
  p.name := 'v';
  p.flags := HAS_ARG;
  p.u.func_arg := opt_loglevel;
  p.help := 'set logging level';
  p.argname := 'loglevel';
  Inc(p);
//  { "report"     , 0,        {(void*)opt_report}, "generate a report" },
  p.name := 'report';
  p.flags := 0;
  p.u.func_arg := opt_not_support; // TODO: opt_report
  p.help := 'generate a report';
  Inc(p);
//  { "max_alloc"  , HAS_ARG,  {.func_arg = opt_max_alloc},     "set maximum size of a single allocated block", "bytes" },
  p.name := 'max_alloc';
  p.flags := HAS_ARG;
  p.u.func_arg := opt_max_alloc;
  p.help := 'set maximum size of a single allocated block';
  p.argname := 'bytes';
  Inc(p);
//  { "cpuflags"   , HAS_ARG | OPT_EXPERT, { .func_arg = opt_cpuflags }, "force specific cpu flags", "flags" },
  p.name := 'cpuflags';
  p.flags := HAS_ARG;
  p.u.func_arg := opt_cpuflags;
  p.help := 'force specific cpu flags';
  p.argname := 'flags';
  Inc(p);
{$IFDEF CONFIG_OPENCL}
//  { "opencl_options", HAS_ARG, {.func_arg = opt_opencl},      "set OpenCL environment options" },
  p.name := 'opencl_options';
  p.flags := HAS_ARG;
  p.u.func_arg := opt_opencl;
  p.help := 'set OpenCL environment options';
  Inc(p);
{$ENDIF}

//  { "f",              HAS_ARG | OPT_STRING | OPT_OFFSET |
//                      OPT_INPUT | OPT_OUTPUT,                      { .off       = OFFSET(format) },
//      "force format", "fmt" },
  p.name := 'f';
  p.flags := HAS_ARG or OPT_STRING or OPT_OFFSET or OPT_INPUT or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.format) - head_address;
  p.help := 'force format';
  p.argname := 'fmt';
  Inc(p);
//  { "y",              OPT_BOOL,                                    {              &file_overwrite },
//      "overwrite output files" },
  p.name := 'y';
  p.flags := OPT_BOOL;
  p.u.dst_ptr := @Ffile_overwrite;
  p.help := 'overwrite output files';
  Inc(p);
//  { "n",              OPT_BOOL,                                    {              &no_file_overwrite },
//      "never overwrite output files" },
  p.name := 'n';
  p.flags := OPT_BOOL;
  p.u.dst_ptr := @Fno_file_overwrite;
  p.help := 'never overwrite output files';
  Inc(p);
//  { "c",              HAS_ARG | OPT_STRING | OPT_SPEC |
//                      OPT_INPUT | OPT_OUTPUT,                      { .off       = OFFSET(codec_names) },
//      "codec name", "codec" },
  p.name := 'c';
  p.flags := HAS_ARG or OPT_STRING or OPT_SPEC or OPT_INPUT or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.codec_names) - head_address;
  p.help := 'codec name';
  p.argname := 'codec';
  Inc(p);
//  { "codec",          HAS_ARG | OPT_STRING | OPT_SPEC |
//                      OPT_INPUT | OPT_OUTPUT,                      { .off       = OFFSET(codec_names) },
//      "codec name", "codec" },
  p.name := 'codec';
  p.flags := HAS_ARG or OPT_STRING or OPT_SPEC or OPT_INPUT or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.codec_names) - head_address;
  p.help := 'codec name';
  p.argname := 'codec';
  Inc(p);
//  { "pre",            HAS_ARG | OPT_STRING | OPT_SPEC |
//                      OPT_OUTPUT,                                  { .off       = OFFSET(presets) },
//      "preset name", "preset" },
  p.name := 'pre';
  p.flags := OPT_EXIT;
  //p.u.off := Integer(@oc_tmp.presets) - head_address;
  p.u.func_arg := opt_not_support;
  p.help := 'preset name';
  p.argname := 'preset';
  Inc(p);
//  { "map",            HAS_ARG | OPT_EXPERT | OPT_PERFILE |
//                      OPT_OUTPUT,                                  { .func_arg = opt_map },
//      "set input stream mapping",
//      "[-]input_file_id[:stream_specifier][,sync_file_id[:stream_specifier]]" },
  p.name := 'map';
  p.flags := HAS_ARG or OPT_EXPERT or OPT_PERFILE or OPT_OUTPUT;
  p.u.func_arg := opt_map;
  p.help := 'set input stream mapping';
  p.argname := '[-]input_file_id[:stream_specifier][,sync_file_id[:stream_specifier]]';
  Inc(p);
//  { "map_channel",    HAS_ARG | OPT_EXPERT | OPT_PERFILE | OPT_OUTPUT, { .func_arg = opt_map_channel },
//      "map an audio channel from one stream to another", "file.stream.channel[:syncfile.syncstream]" },
  p.name := 'map_channel';
  p.flags := HAS_ARG or OPT_EXPERT or OPT_PERFILE or OPT_OUTPUT;
  p.u.func_arg := opt_map_channel;
  p.help := 'map an audio channel from one stream to another';
  p.argname := 'file.stream.channel[:syncfile.syncstream]';
  Inc(p);
//  { "map_metadata",   HAS_ARG | OPT_STRING | OPT_SPEC |
//                      OPT_OUTPUT,                                  { .off       = OFFSET(metadata_map) },
//      "set metadata information of outfile from infile",
//      "outfile[,metadata]:infile[,metadata]" },
  p.name := 'map_metadata';
  p.flags := HAS_ARG or OPT_STRING or OPT_SPEC or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.metadata_map) - head_address;
  p.help := 'set metadata information of outfile from infile';
  p.argname := 'outfile[,metadata]:infile[,metadata]';
  Inc(p);
//  { "map_chapters",   HAS_ARG | OPT_INT | OPT_EXPERT | OPT_OFFSET |
//                      OPT_OUTPUT,                                  { .off = OFFSET(chapters_input_file) },
//      "set chapters mapping", "input_file_index" },
  p.name := 'map_chapters';
  p.flags := HAS_ARG or OPT_INT or OPT_EXPERT or OPT_OFFSET or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.chapters_input_file) - head_address;
  p.help := 'set chapters mapping';
  p.argname := 'input_file_index';
  Inc(p);
//  { "t",              HAS_ARG | OPT_TIME | OPT_OFFSET |
//                      OPT_INPUT | OPT_OUTPUT,                      { .off = OFFSET(recording_time) },
//      "record or transcode \"duration\" seconds of audio/video",
//      "duration" },
  p.name := 't';
  p.flags := HAS_ARG or OPT_TIME or OPT_OFFSET or OPT_INPUT or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.recording_time) - head_address;
  p.help := 'record or transcode "duration" seconds of audio/video';
  p.argname := 'duration';
  Inc(p);
  p.name := 't_microsecond';
  p.flags := HAS_ARG or OPT_INT64 or OPT_OFFSET or OPT_INPUT or OPT_OUTPUT; // hack: -t in microseconds unit
  p.u.off := Integer(@oc_tmp.recording_time) - head_address;
  p.help := 'record or transcode "duration" seconds of audio/video';
  p.argname := 'duration';
  Inc(p);
//  { "to",             HAS_ARG | OPT_TIME | OPT_OFFSET | OPT_OUTPUT,  { .off = OFFSET(stop_time) },
//      "record or transcode stop time", "time_stop" },
  p.name := 'to';
  p.flags := HAS_ARG or OPT_TIME or OPT_OFFSET or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.stop_time) - head_address;
  p.help := 'record or transcode stop time';
  p.argname := 'time_stop';
  Inc(p);
  p.name := 'to_microsecond';
  p.flags := HAS_ARG or OPT_INT64 or OPT_OFFSET or OPT_OUTPUT; // hack: -to in microseconds unit
  p.u.off := Integer(@oc_tmp.stop_time) - head_address;
  p.help := 'record or transcode stop time';
  p.argname := 'time_stop';
  Inc(p);
//  { "fs",             HAS_ARG | OPT_INT64 | OPT_OFFSET | OPT_OUTPUT, { .off = OFFSET(limit_filesize) },
//      "set the limit file size in bytes", "limit_size" },
  p.name := 'fs';
  p.flags := HAS_ARG or OPT_INT64 or OPT_OFFSET or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.limit_filesize) - head_address;
  p.help := 'set the limit file size in bytes';
  p.argname := 'limit_size';
  Inc(p);
//  { "ss",             HAS_ARG | OPT_TIME | OPT_OFFSET |
//                      OPT_INPUT | OPT_OUTPUT,                      { .off = OFFSET(start_time) },
//      "set the start time offset", "time_off" },
  p.name := 'ss';
  p.flags := HAS_ARG or OPT_TIME or OPT_OFFSET or OPT_INPUT or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.start_time) - head_address;
  p.help := 'set the start time offset';
  p.argname := 'time_off';
  Inc(p);
  p.name := 'ss_microsecond';
  p.flags := HAS_ARG or OPT_INT64 or OPT_OFFSET or OPT_INPUT or OPT_OUTPUT; // hack: -ss in microseconds unit
  p.u.off := Integer(@oc_tmp.start_time) - head_address;
  p.help := 'set the start time offset';
  p.argname := 'time_off';
  Inc(p);
//  { "accurate_seek",  OPT_BOOL | OPT_OFFSET | OPT_EXPERT |
//                      OPT_INPUT,                                   { .off = OFFSET(accurate_seek) },
//      "enable/disable accurate seeking with -ss" },
  p.name := 'accurate_seek';
  p.flags := OPT_BOOL or OPT_OFFSET or OPT_EXPERT or OPT_INPUT;
  p.u.off := Integer(@oc_tmp.accurate_seek) - head_address;
  p.help := 'enable/disable accurate seeking with -ss';
  Inc(p);
//  { "itsoffset",      HAS_ARG | OPT_TIME | OPT_OFFSET |
//                      OPT_EXPERT | OPT_INPUT,                      { .off = OFFSET(input_ts_offset) },
//      "set the input ts offset", "time_off" },
  p.name := 'itsoffset';
  p.flags := HAS_ARG or OPT_TIME or OPT_OFFSET or OPT_EXPERT or OPT_INPUT;
  p.u.off := Integer(@oc_tmp.input_ts_offset) - head_address;
  p.help := 'set the input ts offset';
  p.argname := 'time_off';
  Inc(p);
  p.name := 'itsoffset_microsecond';
  p.flags := HAS_ARG or OPT_INT64 or OPT_OFFSET or OPT_EXPERT or OPT_INPUT; // hack: -itsoffset microseconds unit
  p.u.off := Integer(@oc_tmp.input_ts_offset) - head_address;
  p.help := 'set the input ts offset';
  p.argname := 'time_off';
  Inc(p);
//  { "itsscale",       HAS_ARG | OPT_DOUBLE | OPT_SPEC |
//                      OPT_EXPERT | OPT_INPUT,                      { .off = OFFSET(ts_scale) },
//      "set the input ts scale", "scale" },
  p.name := 'itsscale';
  p.flags := HAS_ARG or OPT_DOUBLE or OPT_SPEC or OPT_EXPERT or OPT_INPUT;
  p.u.off := Integer(@oc_tmp.ts_scale) - head_address;
  p.help := 'set the input ts scale';
  p.argname := 'scale';
  Inc(p);
//  { "timestamp",      HAS_ARG | OPT_PERFILE,                       { .func_arg = opt_recording_timestamp },
//      "set the recording timestamp ('now' to set the current time)", "time" },
  p.name := 'timestamp';
  p.flags := HAS_ARG or OPT_PERFILE;
  p.u.func_arg := opt_recording_timestamp;
  p.help := 'set the recording timestamp ("now" to set the current time)';
  p.argname := 'time';
  Inc(p);
//  { "metadata",       HAS_ARG | OPT_STRING | OPT_SPEC | OPT_OUTPUT, { .off = OFFSET(metadata) },
//      "add metadata", "string=string" },
  p.name := 'metadata';
  p.flags := HAS_ARG or OPT_STRING or OPT_SPEC or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.metadata) - head_address;
  p.help := 'add metadata';
  p.argname := 'string=string';
  Inc(p);
//  { "dframes",        HAS_ARG | OPT_PERFILE | OPT_EXPERT |
//                      OPT_OUTPUT,                                  { .func_arg = opt_data_frames },
//      "set the number of data frames to record", "number" },
  p.name := 'dframes';
  p.flags := HAS_ARG or OPT_PERFILE or OPT_EXPERT or OPT_OUTPUT;
  p.u.func_arg := opt_data_frames;
  p.help := 'set the number of data frames to record';
  p.argname := 'number';
  Inc(p);
//  { "benchmark",      OPT_BOOL | OPT_EXPERT,                       { &do_benchmark },
//      "add timings for benchmarking" },
  p.name := 'benchmark';
  p.flags := OPT_EXIT;
  p.u.func_arg := opt_not_support;
  p.help := 'add timings for benchmarking';
  Inc(p);
//  { "benchmark_all",  OPT_BOOL | OPT_EXPERT,                       { &do_benchmark_all },
//      "add timings for each task" },
  p.name := 'benchmark_all';
  p.flags := OPT_EXIT;
  p.u.func_arg := opt_not_support;
  p.help := 'add timings for each task';
  Inc(p);
//  { "progress",       HAS_ARG | OPT_EXPERT,                        { .func_arg = opt_progress },
//      "write program-readable progress information", "url" },
  p.name := 'progress';
  p.flags := HAS_ARG or OPT_EXPERT;
  p.u.func_arg := opt_progress;
  p.help := 'write program-readable progress information';
  p.argname := 'url';
  Inc(p);
//  { "stdin",          OPT_BOOL | OPT_EXPERT,                       { &stdin_interaction },
//      "enable or disable interaction on standard input" },
  p.name := 'stdin';
  p.flags := OPT_EXIT;
  p.u.func_arg := opt_not_support;
  p.help := 'enable or disable interaction on standard input';
  Inc(p);
//  { "timelimit",      HAS_ARG | OPT_EXPERT,                        { .func_arg = opt_timelimit },
//      "set max runtime in seconds", "limit" },
  p.name := 'timelimit';
  p.flags := OPT_EXIT;
  p.u.func_arg := opt_not_support;
  p.help := 'set max runtime in seconds';
  p.argname := 'limit';
  Inc(p);
//  { "dump",           OPT_BOOL | OPT_EXPERT,                       { &do_pkt_dump },
//      "dump each input packet" },
  p.name := 'dump';
  p.flags := OPT_BOOL or OPT_EXPERT;
  p.u.dst_ptr := @Fdo_pkt_dump;
  p.help := 'dump each input packet';
  Inc(p);
//  { "hex",            OPT_BOOL | OPT_EXPERT,                       { &do_hex_dump },
//      "when dumping packets, also dump the payload" },
  p.name := 'hex';
  p.flags := OPT_BOOL or OPT_EXPERT;
  p.u.dst_ptr := @Fdo_hex_dump;
  p.help := 'when dumping packets, also dump the payload';
  Inc(p);
//  { "re",             OPT_BOOL | OPT_EXPERT | OPT_OFFSET |
//                      OPT_INPUT,                                   { .off = OFFSET(rate_emu) },
//      "read input at native frame rate", "" },
  p.name := 're';
  p.flags := OPT_BOOL or OPT_EXPERT or OPT_OFFSET or OPT_INPUT;
  p.u.off := Integer(@oc_tmp.rate_emu) - head_address;
  p.help := 'read input at native frame rate';
  p.argname := '';
  Inc(p);
//  { "target",         HAS_ARG | OPT_PERFILE | OPT_OUTPUT,          { .func_arg = opt_target },
//      "specify target file type (\"vcd\", \"svcd\", \"dvd\","
//      " \"dv\", \"dv50\", \"pal-vcd\", \"ntsc-svcd\", ...)", "type" },
  p.name := 'target';
  p.flags := HAS_ARG or OPT_PERFILE or OPT_OUTPUT;
  p.u.func_arg := opt_target;
  p.help := 'specify target file type ("vcd", "svcd", "dvd", "dv", "dv50", "pal-vcd", "ntsc-svcd", ...)';
  p.argname := 'type';
  Inc(p);
//  { "vsync",          HAS_ARG | OPT_EXPERT,                        { opt_vsync },
//      "video sync method", "" },
  p.name := 'vsync';
  p.flags := HAS_ARG or OPT_EXPERT;
  p.u.func_arg := opt_vsync;
  p.help := 'video sync method';
  p.argname := '';
  Inc(p);
//  { "async",          HAS_ARG | OPT_INT | OPT_EXPERT,              { &audio_sync_method },
//      "audio sync method", "" },
  p.name := 'async';
  p.flags := HAS_ARG or OPT_INT or OPT_EXPERT;
  p.u.dst_ptr := @Faudio_sync_method;
  p.help := 'audio sync method';
  p.argname := '';
  Inc(p);
//  { "adrift_threshold", HAS_ARG | OPT_FLOAT | OPT_EXPERT,          { &audio_drift_threshold },
//      "audio drift threshold", "threshold" },
  p.name := 'adrift_threshold';
  p.flags := HAS_ARG or OPT_FLOAT or OPT_EXPERT;
  p.u.dst_ptr := @Faudio_drift_threshold;
  p.help := 'audio drift threshold';
  p.argname := 'threshold';
  Inc(p);
//  { "copyts",         OPT_BOOL | OPT_EXPERT,                       { &copy_ts },
//      "copy timestamps" },
  p.name := 'copyts';
  p.flags := OPT_BOOL or OPT_EXPERT;
  p.u.dst_ptr := @Fcopy_ts;
  p.help := 'copy timestamps';
  Inc(p);
//  { "copytb", HAS_ARG | OPT_INT | OPT_EXPERT, {(void*)&copy_tb}, "copy input stream time base when stream copying", "source" },
//  { "copytb",         HAS_ARG | OPT_INT | OPT_EXPERT,              { &copy_tb },
//      "copy input stream time base when stream copying", "mode" },
  p.name := 'copytb';
  p.flags := HAS_ARG or OPT_INT or OPT_EXPERT;
  p.u.dst_ptr := @Fcopy_tb;
  p.help := 'copy input stream time base when stream copying';
  p.argname := 'mode';
  Inc(p);
//  { "shortest",       OPT_BOOL | OPT_EXPERT | OPT_OFFSET |
//                      OPT_OUTPUT,                                  { .off = OFFSET(shortest) },
//      "finish encoding within shortest input" },
  p.name := 'shortest';
  p.flags := OPT_BOOL or OPT_EXPERT or OPT_OFFSET or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.shortest) - head_address;
  p.help := 'finish encoding within shortest input';
  Inc(p);
//  { "apad",           OPT_STRING | HAS_ARG | OPT_SPEC |
//                      OPT_OUTPUT,                                  { .off = OFFSET(apad) },
//      "audio pad", "" },
  p.name := 'apad';
  p.flags := OPT_STRING or HAS_ARG or OPT_SPEC or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.apad) - head_address;
  p.help := 'audio pad';
  p.argname := '';
  Inc(p);
//  { "dts_delta_threshold", HAS_ARG | OPT_FLOAT | OPT_EXPERT,       { &dts_delta_threshold },
//      "timestamp discontinuity delta threshold", "threshold" },
  p.name := 'dts_delta_threshold';
  p.flags := HAS_ARG or OPT_FLOAT or OPT_EXPERT;
  p.u.dst_ptr := @Fdts_delta_threshold;
  p.help := 'timestamp discontinuity delta threshold';
  p.argname := 'threshold';
  Inc(p);
//  { "dts_error_threshold", HAS_ARG | OPT_FLOAT | OPT_EXPERT,       { &dts_error_threshold },
//      "timestamp error delta threshold", "threshold" },
  p.name := 'dts_error_threshold';
  p.flags := HAS_ARG or OPT_FLOAT or OPT_EXPERT;
  p.u.dst_ptr := @Fdts_error_threshold;
  p.help := 'timestamp error delta threshold';
  p.argname := 'threshold';
  Inc(p);
//  { "xerror",         OPT_BOOL | OPT_EXPERT,                       { &exit_on_error },
//      "exit on error", "error" },
  p.name := 'xerror';
  p.flags := OPT_BOOL or OPT_EXPERT;
  p.u.dst_ptr := @Fexit_on_error;
  p.help := 'exit on error';
  p.argname := 'error';
  Inc(p);
//  { "copyinkf",       OPT_BOOL | OPT_EXPERT | OPT_SPEC |
//                      OPT_OUTPUT,                                  { .off = OFFSET(copy_initial_nonkeyframes) },
//      "copy initial non-keyframes" },
  p.name := 'copyinkf';
  p.flags := OPT_BOOL or OPT_EXPERT or OPT_SPEC or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.copy_initial_nonkeyframes) - head_address;
  p.help := 'copy initial non-keyframes';
  Inc(p);
//  { "copypriorss",    OPT_INT | HAS_ARG | OPT_EXPERT | OPT_SPEC | OPT_OUTPUT,   { .off = OFFSET(copy_prior_start) },
//      "copy or discard frames before start time" },
  p.name := 'copypriorss';
  p.flags := OPT_INT or HAS_ARG or OPT_EXPERT or OPT_SPEC or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.copy_prior_start) - head_address;
  p.help := 'copy or discard frames before start time';
  Inc(p);
//  { "frames",         OPT_INT64 | HAS_ARG | OPT_SPEC | OPT_OUTPUT, { .off = OFFSET(max_frames) },
//      "set the number of frames to record", "number" },
  p.name := 'frames';
  p.flags := OPT_INT64 or HAS_ARG or OPT_SPEC or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.max_frames) - head_address;
  p.help := 'set the number of frames to record';
  p.argname := 'number';
  Inc(p);
//  { "tag",            OPT_STRING | HAS_ARG | OPT_SPEC |
//                      OPT_EXPERT | OPT_OUTPUT,                     { .off = OFFSET(codec_tags) },
//      "force codec tag/fourcc", "fourcc/tag" },
  p.name := 'tag';
  p.flags := OPT_STRING or HAS_ARG or OPT_SPEC or OPT_EXPERT or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.codec_tags) - head_address;
  p.help := 'force codec tag/fourcc';
  p.argname := 'fourcc/tag';
  Inc(p);
//  { "q",              HAS_ARG | OPT_EXPERT | OPT_DOUBLE |
//                      OPT_SPEC | OPT_OUTPUT,                       { .off = OFFSET(qscale) },
//      "use fixed quality scale (VBR)", "q" },
  p.name := 'q';
  p.flags := HAS_ARG or OPT_EXPERT or OPT_DOUBLE or OPT_SPEC or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.qscale) - head_address;
  p.help := 'use fixed quality scale (VBR)';
  p.argname := 'q';
  Inc(p);
//  { "qscale",         HAS_ARG | OPT_EXPERT | OPT_PERFILE |
//                      OPT_OUTPUT,                                  { .func_arg = opt_qscale },
//      "use fixed quality scale (VBR)", "q" },
  p.name := 'qscale';
  p.flags := HAS_ARG or OPT_EXPERT or OPT_PERFILE or OPT_OUTPUT;
  p.u.func_arg := opt_qscale;
  p.help := 'use fixed quality scale (VBR)';
  p.argname := 'q';
  Inc(p);
//  { "profile",        HAS_ARG | OPT_EXPERT | OPT_PERFILE | OPT_OUTPUT, { .func_arg = opt_profile },
//      "set profile", "profile" },
  p.name := 'profile';
  p.flags := HAS_ARG or OPT_EXPERT or OPT_PERFILE or OPT_OUTPUT;
  p.u.func_arg := opt_profile;
  p.help := 'set profile';
  p.argname := 'profile';
  Inc(p);
//  { "filter",         HAS_ARG | OPT_STRING | OPT_SPEC | OPT_OUTPUT, { .off = OFFSET(filters) },
//      "set stream filtergraph", "filter_graph" },
  p.name := 'filter';
  p.flags := HAS_ARG or OPT_STRING or OPT_SPEC or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.filters) - head_address;
  p.help := 'set stream filtergraph';
  p.argname := 'filter_graph';
  Inc(p);
//  { "filter_script",  HAS_ARG | OPT_STRING | OPT_SPEC | OPT_OUTPUT, { .off = OFFSET(filter_scripts) },
//      "read stream filtergraph description from a file", "filename" },
  p.name := 'filter_script';
  p.flags := HAS_ARG or OPT_STRING or OPT_SPEC or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.filter_scripts) - head_address;
  p.help := 'read stream filtergraph description from a file';
  p.argname := 'filename';
  Inc(p);
//  { "reinit_filter",  HAS_ARG | OPT_INT | OPT_SPEC | OPT_INPUT,    { .off = OFFSET(reinit_filters) },
//      "reinit filtergraph on input parameter changes", "" },
  p.name := 'reinit_filter';
  p.flags := HAS_ARG or OPT_INT or OPT_SPEC or OPT_INPUT;
  p.u.off := Integer(@oc_tmp.reinit_filters) - head_address;
  p.help := 'reinit filtergraph on input parameter changes';
  Inc(p);
//  { "filter_complex", HAS_ARG | OPT_EXPERT,                        { .func_arg = opt_filter_complex },
//      "create a complex filtergraph", "graph_description" },
  p.name := 'filter_complex';
  p.flags := HAS_ARG or OPT_EXPERT;
  p.u.func_arg := opt_filter_complex;
  p.help := 'create a complex filtergraph';
  p.argname := 'graph_description';
  Inc(p);
//  { "lavfi",          HAS_ARG | OPT_EXPERT,                        { .func_arg = opt_filter_complex },
//      "create a complex filtergraph", "graph_description" },
  p.name := 'lavfi';
  p.flags := HAS_ARG or OPT_EXPERT;
  p.u.func_arg := opt_filter_complex;
  p.help := 'create a complex filtergraph';
  p.argname := 'graph_description';
  Inc(p);
//  { "filter_complex_script", HAS_ARG | OPT_EXPERT,                 { .func_arg = opt_filter_complex_script },
//      "read complex filtergraph description from a file", "filename" },
  p.name := 'filter_complex_script';
  p.flags := HAS_ARG or OPT_EXPERT;
  p.u.func_arg := opt_filter_complex_script;
  p.help := 'read complex filtergraph description from a file';
  p.argname := 'filename';
  Inc(p);
//  { "stats",          OPT_BOOL,                                    { &print_stats },
//      "print progress report during encoding", },
  p.name := 'stats';
  p.flags := OPT_BOOL;
  p.u.dst_ptr := @Fprint_stats;
  p.help := 'print progress report during encoding';
  Inc(p);
//  { "attach",         HAS_ARG | OPT_PERFILE | OPT_EXPERT |
//                      OPT_OUTPUT,                                  { .func_arg = opt_attach },
//      "add an attachment to the output file", "filename" },
  p.name := 'attach';
  p.flags := HAS_ARG or OPT_PERFILE or OPT_EXPERT or OPT_OUTPUT;
  p.u.func_arg := opt_attach;
  p.help := 'add an attachment to the output file';
  p.argname := 'filename';
  Inc(p);
//  { "dump_attachment", HAS_ARG | OPT_STRING | OPT_SPEC |
//                       OPT_EXPERT | OPT_INPUT,                     { .off = OFFSET(dump_attachment) },
//      "extract an attachment into a file", "filename" },
  p.name := 'dump_attachment';
  p.flags := HAS_ARG or OPT_STRING or OPT_SPEC or OPT_EXPERT or OPT_INPUT;
  p.u.off := Integer(@oc_tmp.dump_attachment) - head_address;
  p.help := 'extract an attachment into a file';
  p.argname := 'filename';
  Inc(p);
//  { "debug_ts",       OPT_BOOL | OPT_EXPERT,                       { &debug_ts },
//      "print timestamp debugging info" },
  p.name := 'stats';
  p.flags := OPT_BOOL or OPT_EXPERT;
  p.u.dst_ptr := @Fdebug_ts;
  p.help := 'print timestamp debugging info';
  Inc(p);
//  { "max_error_rate",  HAS_ARG | OPT_FLOAT,                        { &max_error_rate },
//      "maximum error rate", "ratio of errors (0.0: no errors, 1.0: 100% errors) above which ffmpeg returns an error instead of success." },
  p.name := 'max_error_rate';
  p.flags := HAS_ARG or OPT_FLOAT;
  p.u.dst_ptr := @Fmax_error_rate;
  p.help := 'maximum error rate';
  p.argname := 'ratio of errors (0.0: no errors, 1.0: 100% errors) above which ffmpeg returns an error instead of success.';
  Inc(p);

  (* video options *)
//  { "vframes",      OPT_VIDEO | HAS_ARG  | OPT_PERFILE | OPT_OUTPUT,           { .func_arg = opt_video_frames },
//      "set the number of video frames to record", "number" },
  p.name := 'vframes';
  p.flags := OPT_VIDEO or HAS_ARG or OPT_PERFILE or OPT_OUTPUT;
  p.u.func_arg := opt_video_frames;
  p.help := 'set the number of video frames to record';
  p.argname := 'number';
  Inc(p);
//  { "r",            OPT_VIDEO | HAS_ARG  | OPT_STRING | OPT_SPEC |
//                    OPT_INPUT | OPT_OUTPUT,                                    { .off = OFFSET(frame_rates) },
//      "set frame rate (Hz value, fraction or abbreviation)", "rate" },
  p.name := 'r';
  p.flags := OPT_VIDEO or HAS_ARG or OPT_STRING or OPT_SPEC or OPT_INPUT or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.frame_rates) - head_address;
  p.help := 'set frame rate (Hz value, fraction or abbreviation)';
  p.argname := 'rate';
  Inc(p);
//  { "s",            OPT_VIDEO | HAS_ARG | OPT_SUBTITLE | OPT_STRING | OPT_SPEC |
//                    OPT_INPUT | OPT_OUTPUT,                                    { .off = OFFSET(frame_sizes) },
//      "set frame size (WxH or abbreviation)", "size" },
  p.name := 's';
  p.flags := OPT_VIDEO or HAS_ARG or OPT_SUBTITLE or OPT_STRING or OPT_SPEC or OPT_INPUT or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.frame_sizes) - head_address;
  p.help := 'set frame size (WxH or abbreviation)';
  p.argname := 'size';
  Inc(p);
//  { "aspect",       OPT_VIDEO | HAS_ARG  | OPT_STRING | OPT_SPEC |
//                    OPT_OUTPUT,                                                { .off = OFFSET(frame_aspect_ratios) },
//      "set aspect ratio (4:3, 16:9 or 1.3333, 1.7777)", "aspect" },
  p.name := 'aspect';
  p.flags := OPT_VIDEO or HAS_ARG or OPT_STRING or OPT_SPEC or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.frame_aspect_ratios) - head_address;
  p.help := 'set aspect ratio (4:3, 16:9 or 1.3333, 1.7777)';
  p.argname := 'aspect';
  Inc(p);
//  { "pix_fmt",      OPT_VIDEO | HAS_ARG | OPT_EXPERT  | OPT_STRING | OPT_SPEC |
//                    OPT_INPUT | OPT_OUTPUT,                                    { .off = OFFSET(frame_pix_fmts) },
//      "set pixel format", "format" },
  p.name := 'pix_fmt';
  p.flags := OPT_VIDEO or HAS_ARG or OPT_EXPERT or OPT_STRING or OPT_SPEC or OPT_INPUT or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.frame_pix_fmts) - head_address;
  p.help := 'set pixel format';
  p.argname := 'format';
  Inc(p);
//  { "bits_per_raw_sample", OPT_VIDEO | OPT_INT | HAS_ARG,                      { &frame_bits_per_raw_sample },
//      "set the number of bits per raw sample", "number" },
  p.name := 'bits_per_raw_sample';
  p.flags := OPT_VIDEO or OPT_INT or HAS_ARG;
  p.u.dst_ptr := @Fframe_bits_per_raw_sample;
  p.help := 'set the number of bits per raw sample';
  p.argname := 'number';
  Inc(p);
//  { "intra",        OPT_VIDEO | OPT_BOOL | OPT_EXPERT,                         { &intra_only },
//      "deprecated use -g 1" },
  p.name := 'intra';
  p.flags := OPT_VIDEO or OPT_BOOL or OPT_EXPERT;
  p.u.dst_ptr := @Fintra_only;
  p.help := 'deprecated use -g 1';
  Inc(p);
//  { "vn",           OPT_VIDEO | OPT_BOOL  | OPT_OFFSET | OPT_INPUT | OPT_OUTPUT,{ .off = OFFSET(video_disable) },
//      "disable video" },
  p.name := 'vn';
  p.flags := OPT_VIDEO or OPT_BOOL or OPT_OFFSET or OPT_INPUT or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.video_disable) - head_address;
  p.help := 'disable video';
  Inc(p);
//  { "vdt",          OPT_VIDEO | OPT_INT | HAS_ARG | OPT_EXPERT ,               { &video_discard },
//      "discard threshold", "n" },
  p.name := 'vdt';
  p.flags := OPT_VIDEO or OPT_INT or HAS_ARG or OPT_EXPERT;
  p.u.dst_ptr := @Fvideo_discard;
  p.help := 'discard threshold';
  p.argname := 'n';
  Inc(p);
//  { "rc_override",  OPT_VIDEO | HAS_ARG | OPT_EXPERT  | OPT_STRING | OPT_SPEC |
//                    OPT_OUTPUT,                                                { .off = OFFSET(rc_overrides) },
//      "rate control override for specific intervals", "override" },
  p.name := 'rc_override';
  p.flags := OPT_VIDEO or HAS_ARG or OPT_EXPERT or OPT_STRING or OPT_SPEC or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.rc_overrides) - head_address;
  p.help := 'rate control override for specific intervals';
  p.argname := 'override';
  Inc(p);
//  { "vcodec",       OPT_VIDEO | HAS_ARG  | OPT_PERFILE | OPT_INPUT |
//                    OPT_OUTPUT,                                                { .func_arg = opt_video_codec },
//      "force video codec ('copy' to copy stream)", "codec" },
  p.name := 'vcodec';
  p.flags := OPT_VIDEO or HAS_ARG or OPT_PERFILE or OPT_INPUT or OPT_OUTPUT;
  p.u.func_arg := opt_video_codec;
  p.help := 'force video codec ("copy" to copy stream)';
  p.argname := 'codec';
  Inc(p);
//  { "sameq",        OPT_VIDEO | OPT_EXPERT ,                                   { .func_arg = opt_sameq },
//      "Removed" },
  p.name := 'sameq';
  p.flags := OPT_VIDEO or OPT_EXPERT;
  p.u.func_arg := opt_sameq;
  p.help := 'Removed';
  Inc(p);
//  { "same_quant",   OPT_VIDEO | OPT_EXPERT ,                                   { .func_arg = opt_sameq },
//      "Removed" },
  p.name := 'same_quant';
  p.flags := OPT_VIDEO or OPT_EXPERT;
  p.u.func_arg := opt_sameq;
  p.help := 'Removed';
  Inc(p);
//  { "timecode",     OPT_VIDEO | HAS_ARG | OPT_PERFILE | OPT_OUTPUT,            { .func_arg = opt_timecode },
//      "set initial TimeCode value.", "hh:mm:ss[:;.]ff" },
  p.name := 'timecode';
  p.flags := OPT_VIDEO or HAS_ARG or OPT_PERFILE or OPT_OUTPUT;
  p.u.func_arg := opt_timecode;
  p.help := 'set initial TimeCode value.';
  p.argname := 'hh:mm:ss[:;.]ff';
  Inc(p);
//  { "pass",         OPT_VIDEO | HAS_ARG | OPT_SPEC | OPT_INT | OPT_OUTPUT,     { .off = OFFSET(pass) },
//      "select the pass number (1 to 3)", "n" },
  p.name := 'pass';
  p.flags := OPT_VIDEO or HAS_ARG or OPT_SPEC or OPT_INT or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.pass) - head_address;
  p.help := 'select the pass number (1 to 3)';
  p.argname := 'n';
  Inc(p);
//  { "passlogfile",  OPT_VIDEO | HAS_ARG | OPT_STRING | OPT_EXPERT | OPT_SPEC |
//                    OPT_OUTPUT,                                                { .off = OFFSET(passlogfiles) },
//      "select two pass log file name prefix", "prefix" },
  p.name := 'passlogfile';
  p.flags := OPT_VIDEO or HAS_ARG or OPT_STRING or OPT_EXPERT or OPT_SPEC or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.passlogfiles) - head_address;
  p.help := 'select two pass log file name prefix';
  p.argname := 'prefix';
  Inc(p);
//  { "deinterlace",  OPT_VIDEO | OPT_BOOL | OPT_EXPERT,                         { &do_deinterlace },
//      "this option is deprecated, use the yadif filter instead" },
  p.name := 'deinterlace';
  p.flags := OPT_VIDEO or OPT_BOOL or OPT_EXPERT;
  p.u.dst_ptr := @Fdo_deinterlace;
  p.help := 'this option is deprecated, use the yadif filter instead';
  Inc(p);
//  { "psnr",         OPT_VIDEO | OPT_BOOL | OPT_EXPERT,                         { &do_psnr },
//      "calculate PSNR of compressed frames" },
  p.name := 'psnr';
  p.flags := OPT_VIDEO or OPT_BOOL or OPT_EXPERT;
  p.u.dst_ptr := @Fdo_psnr;
  p.help := 'calculate PSNR of compressed frames';
  Inc(p);
//  { "vstats",       OPT_VIDEO | OPT_EXPERT ,                                   { &opt_vstats },
//      "dump video coding statistics to file" },
  p.name := 'vstats';
  p.flags := OPT_VIDEO or OPT_EXPERT;
  p.u.func_arg := opt_vstats;
  p.help := 'dump video coding statistics to file';
  Inc(p);
//  { "vstats_file",  OPT_VIDEO | HAS_ARG | OPT_EXPERT ,                         { opt_vstats_file },
//      "dump video coding statistics to file", "file" },
  p.name := 'vstats_file';
  p.flags := OPT_VIDEO or HAS_ARG or OPT_EXPERT;
  p.u.func_arg := opt_vstats_file;
  p.help := 'dump video coding statistics to file';
  p.argname := 'file';
  Inc(p);
//  { "vf",           OPT_VIDEO | HAS_ARG  | OPT_PERFILE | OPT_OUTPUT,           { .func_arg = opt_video_filters },
//      "set video filters", "filter_graph" },
  p.name := 'vf';
  p.flags := OPT_VIDEO or HAS_ARG or OPT_PERFILE or OPT_OUTPUT;
  p.u.func_arg := opt_video_filters;
  p.help := 'set video filters';
  p.argname := 'filter_graph';
  Inc(p);
//  { "intra_matrix", OPT_VIDEO | HAS_ARG | OPT_EXPERT  | OPT_STRING | OPT_SPEC |
//                    OPT_OUTPUT,                                                { .off = OFFSET(intra_matrices) },
//      "specify intra matrix coeffs", "matrix" },
  p.name := 'intra_matrix';
  p.flags := OPT_VIDEO or HAS_ARG or OPT_EXPERT or OPT_STRING or OPT_SPEC or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.intra_matrices) - head_address;
  p.help := 'specify intra matrix coeffs';
  p.argname := 'matrix';
  Inc(p);
//  { "inter_matrix", OPT_VIDEO | HAS_ARG | OPT_EXPERT  | OPT_STRING | OPT_SPEC |
//                    OPT_OUTPUT,                                                { .off = OFFSET(inter_matrices) },
//      "specify inter matrix coeffs", "matrix" },
  p.name := 'inter_matrix';
  p.flags := OPT_VIDEO or HAS_ARG or OPT_EXPERT or OPT_STRING or OPT_SPEC or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.inter_matrices) - head_address;
  p.help := 'specify inter matrix coeffs';
  p.argname := 'matrix';
  Inc(p);
//  { "top",          OPT_VIDEO | HAS_ARG | OPT_EXPERT  | OPT_INT| OPT_SPEC |
//                    OPT_INPUT | OPT_OUTPUT,                                    { .off = OFFSET(top_field_first) },
//      "top=1/bottom=0/auto=-1 field first", "" },
  p.name := 'top';
  p.flags := OPT_VIDEO or HAS_ARG or OPT_EXPERT or OPT_INT or OPT_SPEC or OPT_INPUT or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.top_field_first) - head_address;
  p.help := 'top=1/bottom=0/auto=-1 field first';
  p.argname := '';
  Inc(p);
//  { "dc",           OPT_VIDEO | OPT_INT | HAS_ARG | OPT_EXPERT ,               { &intra_dc_precision },
//      "intra_dc_precision", "precision" },
  p.name := 'dc';
  p.flags := OPT_VIDEO or OPT_INT or HAS_ARG or OPT_EXPERT;
  p.u.dst_ptr := @Fintra_dc_precision;
  p.help := 'intra_dc_precision';
  p.argname := 'precision';
  Inc(p);
//  { "vtag",         OPT_VIDEO | HAS_ARG | OPT_EXPERT  | OPT_PERFILE |
//                    OPT_OUTPUT,                                                { .func_arg = opt_old2new },
//      "force video tag/fourcc", "fourcc/tag" },
  p.name := 'vtag';
  p.flags := OPT_VIDEO or HAS_ARG or OPT_EXPERT or OPT_PERFILE or OPT_OUTPUT;
  p.u.func_arg := opt_old2new;
  p.help := 'force video tag/fourcc';
  p.argname := 'fourcc/tag';
  Inc(p);
//  { "qphist",       OPT_VIDEO | OPT_BOOL | OPT_EXPERT ,                        { &qp_hist },
//      "show QP histogram" },
  p.name := 'qphist';
  p.flags := OPT_VIDEO or OPT_BOOL or OPT_EXPERT;
  p.u.dst_ptr := @Fqp_hist;
  p.help := 'show QP histogram';
  Inc(p);
//  { "force_fps",    OPT_VIDEO | OPT_BOOL | OPT_EXPERT  | OPT_SPEC |
//                    OPT_OUTPUT,                                                { .off = OFFSET(force_fps) },
//      "force the selected framerate, disable the best supported framerate selection" },
  p.name := 'force_fps';
  p.flags := OPT_VIDEO or OPT_BOOL or OPT_EXPERT or OPT_SPEC or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.force_fps) - head_address;
  p.help := 'force the selected framerate, disable the best supported framerate selection';
  Inc(p);
//  { "streamid",     OPT_VIDEO | HAS_ARG | OPT_EXPERT | OPT_PERFILE |
//                    OPT_OUTPUT,                                                { .func_arg = opt_streamid },
//      "set the value of an outfile streamid", "streamIndex:value" },
  p.name := 'streamid';
  p.flags := OPT_VIDEO or HAS_ARG or OPT_EXPERT or OPT_PERFILE or OPT_OUTPUT;
  p.u.func_arg := opt_streamid;
  p.help := 'set the value of an outfile streamid';
  p.argname := 'streamIndex:value';
  Inc(p);
//  { "force_key_frames", OPT_VIDEO | OPT_STRING | HAS_ARG | OPT_EXPERT |
//                        OPT_SPEC | OPT_OUTPUT,                                 { .off = OFFSET(forced_key_frames) },
//      "force key frames at specified timestamps", "timestamps" },
  p.name := 'force_key_frames';
  p.flags := OPT_VIDEO or OPT_STRING or HAS_ARG or OPT_EXPERT or OPT_SPEC or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.forced_key_frames) - head_address;
  p.help := 'force key frames at specified timestamps';
  p.argname := 'timestamps';
  Inc(p);
//  { "b",            OPT_VIDEO | HAS_ARG | OPT_PERFILE | OPT_OUTPUT,            { .func_arg = opt_bitrate },
//      "video bitrate (please use -b:v)", "bitrate" },
  p.name := 'b';
  p.flags := OPT_VIDEO or HAS_ARG or OPT_PERFILE or OPT_OUTPUT;
  p.u.func_arg := opt_bitrate;
  p.help := 'video bitrate (please use -b:v)';
  p.argname := 'bitrate';
  Inc(p);

  (* audio options *)
//  { "aframes",        OPT_AUDIO | HAS_ARG  | OPT_PERFILE | OPT_OUTPUT,           { .func_arg = opt_audio_frames },
//      "set the number of audio frames to record", "number" },
  p.name := 'aframes';
  p.flags := OPT_AUDIO or HAS_ARG or OPT_PERFILE or OPT_OUTPUT;
  p.u.func_arg := opt_audio_frames;
  p.help := 'set the number of audio frames to record';
  p.argname := 'number';
  Inc(p);
//  { "aq",             OPT_AUDIO | HAS_ARG  | OPT_PERFILE | OPT_OUTPUT,           { .func_arg = opt_audio_qscale },
//      "set audio quality (codec-specific)", "quality", },
  p.name := 'aq';
  p.flags := OPT_AUDIO or HAS_ARG or OPT_PERFILE or OPT_OUTPUT;
  p.u.func_arg := opt_audio_qscale;
  p.help := 'set audio quality (codec-specific)';
  p.argname := 'quality';
  Inc(p);
//  { "ar",             OPT_AUDIO | HAS_ARG  | OPT_INT | OPT_SPEC |
//                      OPT_INPUT | OPT_OUTPUT,                                    { .off = OFFSET(audio_sample_rate) },
//      "set audio sampling rate (in Hz)", "rate" },
  p.name := 'ar';
  p.flags := OPT_AUDIO or HAS_ARG or OPT_INT or OPT_SPEC or OPT_INPUT or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.audio_sample_rate) - head_address;
  p.help := 'set audio sampling rate (in Hz)';
  p.argname := 'rate';
  Inc(p);
//  { "ac",             OPT_AUDIO | HAS_ARG  | OPT_INT | OPT_SPEC |
//                      OPT_INPUT | OPT_OUTPUT,                                    { .off = OFFSET(audio_channels) },
//      "set number of audio channels", "channels" },
  p.name := 'ac';
  p.flags := OPT_AUDIO or HAS_ARG or OPT_INT or OPT_SPEC or OPT_INPUT or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.audio_channels) - head_address;
  p.help := 'set number of audio channels';
  p.argname := 'channels';
  Inc(p);
//  { "an",             OPT_AUDIO | OPT_BOOL | OPT_OFFSET | OPT_INPUT | OPT_OUTPUT,{ .off = OFFSET(audio_disable) },
//      "disable audio" },
  p.name := 'an';
  p.flags := OPT_AUDIO or OPT_BOOL or OPT_OFFSET or OPT_INPUT or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.audio_disable) - head_address;
  p.help := 'disable audio';
  Inc(p);
//  { "acodec",         OPT_AUDIO | HAS_ARG  | OPT_PERFILE |
//                      OPT_INPUT | OPT_OUTPUT,                                    { .func_arg = opt_audio_codec },
//      "force audio codec ('copy' to copy stream)", "codec" },
  p.name := 'acodec';
  p.flags := OPT_AUDIO or HAS_ARG or OPT_PERFILE or OPT_INPUT or OPT_OUTPUT;
  p.u.func_arg := opt_audio_codec;
  p.help := 'force audio codec ("copy" to copy stream)';
  p.argname := 'codec';
  Inc(p);
//  { "atag",           OPT_AUDIO | HAS_ARG  | OPT_EXPERT | OPT_PERFILE |
//                      OPT_OUTPUT,                                                { .func_arg = opt_old2new },
//      "force audio tag/fourcc", "fourcc/tag" },
  p.name := 'atag';
  p.flags := OPT_AUDIO or HAS_ARG or OPT_EXPERT or OPT_PERFILE or OPT_OUTPUT;
  p.u.func_arg := opt_old2new;
  p.help := 'force audio tag/fourcc';
  p.argname := 'fourcc/tag';
  Inc(p);
//  { "vol",            OPT_AUDIO | HAS_ARG  | OPT_INT,                            { &audio_volume },
//      "change audio volume (256=normal)" , "volume" },
  p.name := 'vol';
  p.flags := OPT_AUDIO or HAS_ARG or OPT_INT;
  p.u.dst_ptr := @Faudio_volume;
  p.help := 'change audio volume (256=normal)';
  p.argname := 'volume';
  Inc(p);
//  { "sample_fmt",     OPT_AUDIO | HAS_ARG  | OPT_EXPERT | OPT_SPEC |
//                      OPT_STRING | OPT_INPUT | OPT_OUTPUT,                       { .off = OFFSET(sample_fmts) },
//      "set sample format", "format" },
  p.name := 'sample_fmt';
  p.flags := OPT_AUDIO or HAS_ARG or OPT_EXPERT or OPT_SPEC or OPT_STRING or OPT_INPUT or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.sample_fmts) - head_address;
  p.help := 'set sample format';
  p.argname := 'format';
  Inc(p);
//  { "channel_layout", OPT_AUDIO | HAS_ARG  | OPT_EXPERT | OPT_PERFILE |
//                      OPT_INPUT | OPT_OUTPUT,                                    { .func_arg = opt_channel_layout },
//      "set channel layout", "layout" },
  p.name := 'channel_layout';
  p.flags := OPT_AUDIO or HAS_ARG or OPT_EXPERT or OPT_PERFILE or OPT_INPUT or OPT_OUTPUT;
  p.u.func_arg := opt_channel_layout;
  p.help := 'set channel layout';
  p.argname := 'layout';
  Inc(p);
//  { "af",             OPT_AUDIO | HAS_ARG  | OPT_PERFILE | OPT_OUTPUT,           { .func_arg = opt_audio_filters },
//      "set audio filters", "filter_graph" },
  p.name := 'af';
  p.flags := OPT_AUDIO or HAS_ARG or OPT_PERFILE or OPT_OUTPUT;
  p.u.func_arg := opt_audio_filters;
  p.help := 'set audio filters';
  p.argname := 'filter_graph';
  Inc(p);
//  { "guess_layout_max", OPT_AUDIO | HAS_ARG | OPT_INT | OPT_SPEC | OPT_EXPERT | OPT_INPUT, { .off = OFFSET(guess_layout_max) },
//    "set the maximum number of channels to try to guess the channel layout" },
  p.name := 'guess_layout_max';
  p.flags := OPT_AUDIO or HAS_ARG or OPT_INT or OPT_SPEC or OPT_EXPERT or OPT_INPUT;
  p.u.off := Integer(@oc_tmp.guess_layout_max) - head_address;
  p.help := 'set the maximum number of channels to try to guess the channel layout';
  Inc(p);

  (* subtitle options *)
//  { "sn",     OPT_SUBTITLE | OPT_BOOL | OPT_OFFSET | OPT_INPUT | OPT_OUTPUT, { .off = OFFSET(subtitle_disable) },
//      "disable subtitle" },
  p.name := 'sn';
  p.flags := OPT_SUBTITLE or OPT_BOOL or OPT_OFFSET or OPT_INPUT or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.subtitle_disable) - head_address;
  p.help := 'disable subtitle';
  Inc(p);
//  { "scodec", OPT_SUBTITLE | HAS_ARG  | OPT_PERFILE | OPT_INPUT | OPT_OUTPUT, { .func_arg = opt_subtitle_codec },
//      "force subtitle codec ('copy' to copy stream)", "codec" },
  p.name := 'scodec';
  p.flags := OPT_SUBTITLE or HAS_ARG or OPT_PERFILE or OPT_INPUT or OPT_OUTPUT;
  p.u.func_arg := opt_subtitle_codec;
  p.help := 'force subtitle codec ("copy" to copy stream)';
  p.argname := 'codec';
  Inc(p);
//  { "stag",   OPT_SUBTITLE | HAS_ARG  | OPT_EXPERT  | OPT_PERFILE | OPT_OUTPUT, { .func_arg = opt_old2new }
//        , "force subtitle tag/fourcc", "fourcc/tag" },
  p.name := 'stag';
  p.flags := OPT_SUBTITLE or HAS_ARG or OPT_EXPERT or OPT_PERFILE or OPT_OUTPUT;
  p.u.func_arg := opt_old2new;
  p.help := 'force subtitle tag/fourcc';
  p.argname := 'fourcc/tag';
  Inc(p);
//  { "fix_sub_duration", OPT_BOOL | OPT_EXPERT | OPT_SUBTITLE | OPT_SPEC | OPT_INPUT, { .off = OFFSET(fix_sub_duration) },
//      "fix subtitles duration" },
  p.name := 'fix_sub_duration';
  p.flags := OPT_BOOL or OPT_EXPERT or OPT_SUBTITLE or OPT_SPEC or OPT_INPUT;
  p.u.off := Integer(@oc_tmp.fix_sub_duration) - head_address;
  p.help := 'fix subtitles duration';
  Inc(p);
//  { "canvas_size", OPT_SUBTITLE | HAS_ARG | OPT_STRING | OPT_SPEC | OPT_INPUT, { .off = OFFSET(canvas_sizes) },
//      "set canvas size (WxH or abbreviation)", "size" },
  p.name := 'canvas_size';
  p.flags := OPT_SUBTITLE or HAS_ARG or OPT_STRING or OPT_SPEC or OPT_INPUT;
  p.u.off := Integer(@oc_tmp.canvas_sizes) - head_address;
  p.help := 'set canvas size (WxH or abbreviation)';
  p.argname := 'size';
  Inc(p);

  (* grab options *)
//  { "vc", HAS_ARG | OPT_EXPERT | OPT_VIDEO, { .func_arg = opt_video_channel },
//      "deprecated, use -channel", "channel" },
  p.name := 'vc';
  p.flags := HAS_ARG or OPT_EXPERT or OPT_VIDEO;
  p.u.func_arg := opt_video_channel;
  p.help := 'deprecated, use -channel';
  p.argname := 'channel';
  Inc(p);
//  { "tvstd", HAS_ARG | OPT_EXPERT | OPT_VIDEO, { .func_arg = opt_video_standard },
//      "deprecated, use -standard", "standard" },
  p.name := 'tvstd';
  p.flags := HAS_ARG or OPT_EXPERT or OPT_VIDEO;
  p.u.func_arg := opt_video_standard;
  p.help := 'deprecated, use -standard';
  p.argname := 'standard';
  Inc(p);
//  { "isync", OPT_BOOL | OPT_EXPERT, { &input_sync }, "this option is deprecated and does nothing", "" },
  p.name := 'isync';
  p.flags := OPT_BOOL or OPT_EXPERT;
  p.u.dst_ptr := @Finput_sync;
  p.help := 'this option is deprecated and does nothing';
  p.argname := '';
  Inc(p);

  (* muxer options *)
//  { "muxdelay",   OPT_FLOAT | HAS_ARG | OPT_EXPERT | OPT_OFFSET | OPT_OUTPUT, { .off = OFFSET(mux_max_delay) },
//      "set the maximum demux-decode delay", "seconds" },
  p.name := 'muxdelay';
  p.flags := OPT_FLOAT or HAS_ARG or OPT_EXPERT or OPT_OFFSET or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.mux_max_delay) - head_address;
  p.help := 'set the maximum demux-decode delay';
  p.argname := 'seconds';
  Inc(p);
//  { "muxpreload", OPT_FLOAT | HAS_ARG | OPT_EXPERT | OPT_OFFSET | OPT_OUTPUT, { .off = OFFSET(mux_preload) },
//      "set the initial demux-decode delay", "seconds" },
  p.name := 'muxpreload';
  p.flags := OPT_FLOAT or HAS_ARG or OPT_EXPERT or OPT_OFFSET or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.mux_preload) - head_address;
  p.help := 'set the initial demux-decode delay';
  p.argname := 'seconds';
  Inc(p);
//  { "override_ffserver", OPT_BOOL | OPT_EXPERT | OPT_OUTPUT, { &override_ffserver },
//      "override the options from ffserver", "" },
  p.name := 'override_ffserver';
  p.flags := OPT_BOOL or OPT_EXPERT or OPT_OUTPUT;
  p.u.dst_ptr := @Foverride_ffserver;
  p.help := 'override the options from ffserver';
  p.argname := '';
  Inc(p);

//  { "bsf", HAS_ARG | OPT_STRING | OPT_SPEC | OPT_EXPERT | OPT_OUTPUT, { .off = OFFSET(bitstream_filters) },
//      "A comma-separated list of bitstream filters", "bitstream_filters" },
  p.name := 'bsf';
  p.flags := HAS_ARG or OPT_STRING or OPT_SPEC or OPT_EXPERT or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.bitstream_filters) - head_address;
  p.help := 'A comma-separated list of bitstream filters';
  p.argname := 'bitstream_filters';
  Inc(p);
//  { "absf", HAS_ARG | OPT_AUDIO | OPT_EXPERT| OPT_PERFILE | OPT_OUTPUT, { .func_arg = opt_old2new },
//      "deprecated", "audio bitstream_filters" },
  p.name := 'absf';
  p.flags := HAS_ARG or OPT_AUDIO or OPT_EXPERT or OPT_PERFILE or OPT_OUTPUT;
  p.u.func_arg := opt_old2new;
  p.help := 'deprecated';
  p.argname := 'audio bitstream_filters';
  Inc(p);
//  { "vbsf", OPT_VIDEO | HAS_ARG | OPT_EXPERT| OPT_PERFILE | OPT_OUTPUT, { .func_arg = opt_old2new },
//      "deprecated", "video bitstream_filters" },
  p.name := 'vbsf';
  p.flags := HAS_ARG or OPT_VIDEO or OPT_EXPERT or OPT_PERFILE or OPT_OUTPUT;
  p.u.func_arg := opt_old2new;
  p.help := 'deprecated';
  p.argname := 'video bitstream_filters';
  Inc(p);

//  { "apre", HAS_ARG | OPT_AUDIO | OPT_EXPERT| OPT_PERFILE | OPT_OUTPUT,    { .func_arg = opt_preset },
//      "set the audio options to the indicated preset", "preset" },
  p.name := 'apre';
  p.flags := HAS_ARG or OPT_AUDIO or OPT_EXPERT or OPT_PERFILE or OPT_OUTPUT;
  p.u.func_arg := opt_preset;
  p.help := 'set the audio options to the indicated preset';
  p.argname := 'preset';
  Inc(p);
//  { "vpre", OPT_VIDEO | HAS_ARG | OPT_EXPERT| OPT_PERFILE | OPT_OUTPUT,    { .func_arg = opt_preset },
//      "set the video options to the indicated preset", "preset" },
  p.name := 'vpre';
  p.flags := OPT_VIDEO or HAS_ARG or OPT_EXPERT or OPT_PERFILE or OPT_OUTPUT;
  p.u.func_arg := opt_preset;
  p.help := 'set the video options to the indicated preset';
  p.argname := 'preset';
  Inc(p);
//  { "spre", HAS_ARG | OPT_SUBTITLE | OPT_EXPERT| OPT_PERFILE | OPT_OUTPUT, { .func_arg = opt_preset },
//      "set the subtitle options to the indicated preset", "preset" },
  p.name := 'spre';
  p.flags := HAS_ARG or OPT_SUBTITLE or OPT_EXPERT or OPT_PERFILE or OPT_OUTPUT;
  p.u.func_arg := opt_preset;
  p.help := 'set the subtitle options to the indicated preset';
  p.argname := 'preset';
  Inc(p);
//  { "fpre", HAS_ARG | OPT_EXPERT| OPT_PERFILE | OPT_OUTPUT,                { .func_arg = opt_preset },
//      "set options from indicated preset file", "filename" },
  p.name := 'fpre';
  p.flags := HAS_ARG or OPT_EXPERT or OPT_PERFILE or OPT_OUTPUT;
  p.u.func_arg := opt_preset;
  p.help := 'set options from indicated preset file';
  p.argname := 'filename';
  Inc(p);

  (* data codec support *)
//  { "dcodec", HAS_ARG | OPT_DATA | OPT_PERFILE | OPT_EXPERT | OPT_INPUT | OPT_OUTPUT, { .func_arg = opt_data_codec },
//      "force data codec ('copy' to copy stream)", "codec" },
  p.name := 'dcodec';
  p.flags := HAS_ARG or OPT_DATA or OPT_PERFILE or OPT_EXPERT or OPT_INPUT or OPT_OUTPUT;
  p.u.func_arg := opt_data_codec;
  p.help := 'force data codec ("copy" to copy stream)';
  p.argname := 'codec';
  Inc(p);
//  { "dn", OPT_BOOL | OPT_VIDEO | OPT_OFFSET | OPT_INPUT | OPT_OUTPUT, { .off = OFFSET(data_disable) },
//      "disable data" },
  p.name := 'dn';
  p.flags := OPT_BOOL or OPT_VIDEO or OPT_OFFSET or OPT_INPUT or OPT_OUTPUT;
  p.u.off := Integer(@oc_tmp.data_disable) - head_address;
  p.help := 'disable data';
  Inc(p);

  // hack
{$IFDEF MSWINDOWS}
//  { "vhook", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)add_frame_hooker}, "insert video processing module", "module" },
  p.name := 'vhook';
  p.flags := HAS_ARG or OPT_EXPERT or OPT_VIDEO;
  p.u.func_arg := add_frame_hooker;
  p.help := 'insert video processing module';
  p.argname := 'module';
  Inc(p);
{$ENDIF}

{$IFNDEF FFFMX}
  // -VideoHookBitsPixel
  p.name := 'VideoHookBitsPixel';
  p.flags := HAS_ARG or OPT_EXPERT or OPT_VIDEO;
  p.u.func_arg := opt_VideoHookBitsPixel;
  p.help := 'VideoHookBitsPixel';
  p.argname := 'bpp';
  Inc(p);
{$ENDIF}

  // -TimeStart
  p.name := 'TimeStart';
  p.flags := HAS_ARG or OPT_EXPERT;
  p.u.func_arg := opt_TimeStart;
  p.help := 'TimeStart';
  Inc(p);
  p.name := 'timestart';
  p.flags := HAS_ARG or OPT_EXPERT;
  p.u.func_arg := opt_TimeStart;
  p.help := 'timestart';
  Inc(p);

  // -TimeLength
  p.name := 'TimeLength';
  p.flags := HAS_ARG or OPT_EXPERT;
  p.u.func_arg := opt_TimeLength;
  p.help := 'TimeLength';
  Inc(p);
  p.name := 'timelength';
  p.flags := HAS_ARG or OPT_EXPERT;
  p.u.func_arg := opt_TimeLength;
  p.help := 'timelength';
  Inc(p);

  // -AudioInputHook
  p.name := 'AudioInputHook';
  p.flags := OPT_EXIT;
  p.u.func_arg := opt_skip;
  p.help := 'AudioInputHook';
  Inc(p);

  // -AudioOutputHook
  p.name := 'AudioOutputHook';
  p.flags := OPT_EXIT;
  p.u.func_arg := opt_skip;
  p.help := 'AudioOutputHook';
  Inc(p);

  // -VideoInputHook
  p.name := 'VideoInputHook';
  p.flags := OPT_EXIT;
  p.u.func_arg := opt_skip;
  p.help := 'VideoInputHook';
  Inc(p);

  // -VideoOutputHook
  p.name := 'VideoOutputHook';
  p.flags := OPT_EXIT;
  p.u.func_arg := opt_skip;
  p.help := 'VideoOutputHook';
  Inc(p);

  // -FrameInputHook
  p.name := 'FrameInputHook';
  p.flags := OPT_EXIT;
  p.u.func_arg := opt_skip;
  p.help := 'FrameInputHook';
  Inc(p);

  // -FrameOutputHook
  p.name := 'FrameOutputHook';
  p.flags := OPT_EXIT;
  p.u.func_arg := opt_skip;
  p.help := 'FrameOutputHook';
  Inc(p);

  // -Join
  p.name := 'Join';
  p.flags := OPT_EXIT;
  p.u.func_arg := opt_skip;
  p.help := 'Join';
  Inc(p);

//  { NULL, },
  p.name := nil;
end;

end.
