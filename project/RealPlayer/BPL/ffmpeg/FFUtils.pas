(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * This file is a unit of some utils on ffmpeg.
 * Created by CodeCoolie@CNSW 2009/02/21 -> $Date:: 2013-11-18 #$
 *)

unit FFUtils;

interface

{$I CompilerDefines.inc}

{$DEFINE OPT_SCANLINE}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  {$IFDEF MSWINDOWS}
    Winapi.Windows,
  {$ENDIF}
  System.SysUtils,
  {$IFDEF VCL_XE4_OR_ABOVE}
    System.AnsiStrings, // StrLen
  {$ENDIF}
  {$IFDEF FFFMX}
    {$IFDEF VCL_XE5_OR_ABOVE}
      FMX.Graphics,
    {$ELSE}
      FMX.Types,
    {$ENDIF}
    {$IFDEF MSWINDOWS}
      FMX.Canvas.GDIP,
    {$ENDIF}
    {$IFDEF MACOS}
      FMX.Canvas.Mac,
    {$ENDIF}
  {$ELSE}
    Vcl.Graphics,
  {$ENDIF}
{$ELSE}
  Windows,
  SysUtils,
  Graphics,
{$ENDIF}

{$IFDEF FPC}
  IntfGraphics, // TLazIntfImage
{$ENDIF}

{$IFDEF BCB}
  BCBTypes,
{$ENDIF}
  libavcodec,
  AVCodecStubs,
  libavfilter,
  AVFilterStubs,
  libavformat,
  libavformat_avio,
  libavformat_url,
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
  AVUtilStubs,
  libswresample,
  SwResampleStubs,
  libswscale,
  SwScaleStubs,

  MyUtils,
  MyUtilStubs;

(****** TODO: check from cmdutils.h **************)
const
  HAS_ARG      = $0001;
  OPT_BOOL     = $0002;
  OPT_EXPERT   = $0004;
  OPT_STRING   = $0008;
  OPT_VIDEO    = $0010;
  OPT_AUDIO    = $0020;
  OPT_INT      = $0080;
  OPT_FLOAT    = $0100;
  OPT_SUBTITLE = $0200;
  OPT_INT64    = $0400;
  OPT_EXIT     = $0800;
  OPT_DATA     = $1000;
  OPT_PERFILE  = $2000;       (* the option is per-file (currently ffmpeg-only).
                                 implied by OPT_OFFSET or OPT_SPEC *)
  OPT_OFFSET   = $4000;       (* option is specified as an offset in a passed optctx *)
  OPT_SPEC     = $8000;       (* option is to be stored in an array of SpecifierOpt.
                                 Implies OPT_OFFSET. Next element after the offset is
                                 an int containing element count in the array. *)
  OPT_TIME     = $10000;
  OPT_DOUBLE   = $20000;
  OPT_INPUT    = $40000;
  OPT_OUTPUT   = $80000;
(****** end check from cmdutils.h **************)

type
(****** TODO: check from cmdutils.h **************)
  // option specifier
  TSpecifierOptUnion = record
    case Integer of
      0: (str: PAnsiChar);
      1: (i: Integer);
      2: (i64: Int64);
      3: (f: Single);
      4: (dbl: Double);
  end;
  PPSpecifierOpt = ^PSpecifierOpt;
  PSpecifierOpt = ^TSpecifierOpt;
  TSpecifierOpt = record
    specifier: PAnsiChar;     (**< stream/chapter/program/... specifier *)
    u: TSpecifierOptUnion;
  end;

  // default option
  Tfunc_arg = function(o: Pointer{POptionsContext}; opt, arg: PAnsiChar): Integer of object;
  TOptionDefUnion = record
    case Integer of
      0: (dst_ptr: Pointer);
      1: (func_arg: Tfunc_arg);
      2: (off: Integer{Cardinal});
  end;
  POptionDef = ^TOptionDef;
  TOptionDef = record
    name: PAnsiChar;
    flags: Integer;
    u: TOptionDefUnion;
    help: PAnsiChar;
    argname: PAnsiChar;
  end;
(****** end check from cmdutils.h **************)

{$IFNDEF FFFMX}
  TBMPPixelFormat = {$IFDEF FPC}pf24bit{$ELSE}pf8bit{$ENDIF}..pf32bit;
{$ENDIF}

  TFormatConverter = class
  private
    FAVPixFmt: TAVPixelFormat;
    FBitsPixel: Integer;
    FBitmap: TBitmap;
{$IFNDEF FFFMX}
    FBMPPixFmt: TBMPPixelFormat;
{$ENDIF}
{$IFDEF MSWINDOWS}
    FDIB: tagBITMAP;
{$IFDEF FPC}
    FIntfImg: TLazIntfImage;
{$ENDIF}
{$ENDIF}

    FRGBBuffer: PByte;
    FRGBBufSize: Integer;
    FRGBPicture: TAVPicture;
    FRGBPictureRef: PAVPicture;
    Fsws_flags: Integer;
    FtoRGB_convert_ctx: PSwsContext;
    FfromRGB_convert_ctx: PSwsContext;
    FLastErrMsg: string;

    procedure ResetFormat;
{$IFNDEF FFFMX}
    procedure SetBitsPixel(const Value: Integer);
    procedure SetBMPPixFmt(const Value: TBMPPixelFormat);
{$ENDIF}
{$IFDEF MSWINDOWS}
    function GetDIB: PBitmap;
{$ENDIF}
    function GetRGBPicture: PAVPicture;
  public
    constructor Create;
    destructor Destroy; override;

    function PictureToRGB(picture: PAVPicture; pix_fmt: TAVPixelFormat;
      width, height: Integer; ARGBToBitmap: Boolean = True): Boolean;
    procedure RGBToBitmap;
    procedure BitmapToRGB;
    function RGBToPicture(picture: PAVPicture; pix_fmt: TAVPixelFormat;
      width, height: Integer): Boolean;

    property Bitmap: TBitmap read FBitmap;
{$IFNDEF FFFMX}
    property BitsPixel: Integer read FBitsPixel write SetBitsPixel;
    property BMPPixFmt: TBMPPixelFormat read FBMPPixFmt write SetBMPPixFmt;
{$ENDIF}
{$IFDEF MSWINDOWS}
    property DIB: PBitmap read GetDIB;
{$ENDIF}
    property RGBPicture: PAVPicture read GetRGBPicture;
    property RGBPictureRef: PAVPicture read FRGBPictureRef;
    property LastErrMsg: string read FLastErrMsg;
    property sws_flags: Integer read Fsws_flags write Fsws_flags;
  end;

(****** TODO: check from cmdutils.h **************)

(**
 * Register a program-specific cleanup routine.
 *)
//void register_exit(void (*cb)(int ret));

(**
 * Wraps exit with a program-specific cleanup routine.
 *)
//void exit_program(int ret);

(**
 * Initialize the cmdutils option system, in particular
 * allocate the *_opts contexts.
 *)
//procedure init_opts();

(**
 * Uninitialize the cmdutils option system, in particular
 * free the *_opts contexts and their contents.
 *)
//procedure uninit_opts();

(**
 * Trivial log callback.
 * Only suitable for opt_help and similar since it lacks prefix handling.
 *)
//procedure log_callback_help(ptr: Pointer; level: Integer; const fmt: PAnsiChar; vl: PAnsiChar{va_list}); cdecl;

(**
 * Override the cpuflags.
 *)
//function opt_cpuflags(optctx: Pointer; const opt, arg: PAnsiChar): Integer;

(**
 * Fallback for options that are not explicitly handled, these will be
 * parsed through AVOptions.
 *)
//function opt_default(optctx: Pointer; const opt, arg: PAnsiChar): Integer;

(**
 * Set the libav* libraries log level.
 *)
function ff_opt_loglevel(optctx: Pointer; opt, arg: PAnsiChar): Integer;

//function opt_report(const opt: PAnsiChar): Integer;

//function opt_max_alloc(optctx: Pointer; const opt, arg: PAnsiChar): Integer;

//function opt_opencl(optctx: Pointer; const opt, arg: PAnsiChar): Integer;

(**
 * Limit the execution time.
 *)
//function opt_timelimit(optctx: Pointer; const opt, arg: PAnsiChar): Integer;

(**
 * Parse a string and return its corresponding value as a double.
 * Exit from the application if the string cannot be correctly
 * parsed or the corresponding value is invalid.
 *
 * @param context the context of the value to be set (e.g. the
 * corresponding command line option name)
 * @param numstr the string to be parsed
 * @param type the type (OPT_INT64 or OPT_FLOAT) as which the
 * string should be parsed
 * @param min the minimum valid accepted value
 * @param max the maximum valid accepted value
 *)
//function parse_number_or_die(const context, numstr: PAnsiChar; ttype: Integer; min, max: Double): Double;

(**
 * Parse a string specifying a time and return its corresponding
 * value as a number of microseconds. Exit from the application if
 * the string cannot be correctly parsed.
 *
 * @param context the context of the value to be set (e.g. the
 * corresponding command line option name)
 * @param timestr the string to be parsed
 * @param is_duration a flag which tells how to interpret timestr, if
 * not zero timestr is interpreted as a duration, otherwise as a
 * date
 *
 * @see av_parse_time()
 *)
function parse_time_or_die(const context, timestr: PAnsiChar; is_duration: Integer): Int64;

(**
 * Print help for all options matching specified flags.
 *
 * @param options a list of options
 * @param msg title of this group. Only printed if at least one option matches.
 * @param req_flags print only options which have all those flags set.
 * @param rej_flags don't print options which have any of those flags set.
 * @param alt_flags print only options that have at least one of those flags set
 *)
//procedure show_help_options(const options: POptionDef; const msg: PAnsiChar;
//  req_flags, rej_flags, alt_flags: Integer);

(**
 * Show help for all options with given flags in class and all its
 * children.
 *)
//procedure show_help_children(const cclass: PAVClass; flags: Integer);

(**
 * Per-avtool specific help handler. Implemented in each
 * avtool, called by show_help().
 *)
//procedure show_help_default(const opt, arg: PAnsiChar);

(**
 * Generic -h handler common to all avtools.
 *)
//function show_help(optctx: Pointer; const opt, arg: PAnsiChar): Integer;

(**
 * Parse the command line arguments.
 *
 * @param optctx an opaque options context
 * @param argc   number of command line arguments
 * @param argv   values of command line arguments
 * @param options Array with the definitions required to interpret every
 * option of the form: -option_name [argument]
 * @param parse_arg_function Name of the function called to process every
 * argument without a leading option name flag. NULL if such arguments do
 * not have to be processed.
 *)
function parse_options(optctx: Pointer; argc: Integer; argv: PPAnsiChar; const options: POptionDef;
  AReturnOnInvalidOption: Boolean): Integer;

(**
 * Parse one given option.
 *
 * @return on success 1 if arg was consumed, 0 otherwise; negative number on error
 *)
function parse_option(optctx: Pointer; const opt, _arg: PAnsiChar; const options: POptionDef): Integer;

(**
 * An option extracted from the commandline.
 * Cannot use AVDictionary because of options like -map which can be
 * used multiple times.
 *)
type
  POption = ^TOption;
  TOption = record
    opt: POptionDef;
    key: PAnsiChar;
    val: PAnsiChar;
  end;

  POptionGroup = ^TOptionGroup;
  TOptionGroup = record
    opts: POption;
    nb_opts: Integer;

    codec_opts: PAVDictionary;
    format_opts: PAVDictionary;
    resample_opts: PAVDictionary;
    sws_opts: PSwsContext;
    swr_opts: PAVDictionary;
  end;

  POptionParseContext = ^TOptionParseContext;
  TOptionParseContext = record
    global_opts: TOptionGroup;
    file_opts: TOptionGroup;
  end;

(****** TODO: check from cmdutils.c **************)
  TFFOptions = class
  private
    //avcodec_opts: array[TAVMediaType] of PAVCodecContext;
    //avformat_opts: PAVFormatContext;
    Fsws_flags: Cardinal; // SWS_BICUBIC
    Fsws_opts: PSwsContext;
    Fswr_opts: PAVDictionary;
    Fformat_opts, Fcodec_opts, Fresample_opts: PAVDictionary;

    Foctx: TOptionParseContext;

    procedure finish_group;
    function GetOptionParseContext: POptionParseContext;
  public
    constructor Create;
    destructor Destroy; override;

    function opt_default({optctx: Pointer; }const opt, arg: PAnsiChar): Integer; overload;
    function opt_default({optctx: Pointer; }const opt, arg: string): Integer; overload;

    procedure init_opts;
    procedure uninit_opts;
    procedure init_parse_context;
    procedure uninit_parse_context;

    function parse_options(optctx: Pointer; argc: Integer; argv: PPAnsiChar;
      const options: POptionDef; inout: string; AReturnOnInvalidOption: Boolean): Integer;

    property sws_flags: Cardinal read Fsws_flags write Fsws_flags;
    property sws_opts: PSwsContext read Fsws_opts write Fsws_opts;
    property swr_opts: PAVDictionary read Fswr_opts write Fswr_opts;
    property format_opts: PAVDictionary read Fformat_opts write Fformat_opts;
    property codec_opts: PAVDictionary read Fcodec_opts write Fcodec_opts;
    property resample_opts: PAVDictionary read Fresample_opts write Fresample_opts;

    property OptionParseContext: POptionParseContext read GetOptionParseContext;
  end;
(****** end check from cmdutils.c **************)

(**
 * Parse an options group and write results into optctx.
 *
 * @param optctx an app-specific options context. NULL for global options group
 *)
function parse_optgroup(optctx: Pointer; g: POptionGroup; inout: string; filename: PAnsiChar; group_flags: Integer; AReturnOnInvalidOption: Boolean): Integer;

(**
 * Split the commandline into an intermediate form convenient for further
 * processing.
 *
 * The commandline is assumed to be composed of options which either belong to a
 * group (those with OPT_SPEC, OPT_OFFSET or OPT_PERFILE) or are global
 * (everything else).
 *
 * A group (defined by an OptionGroupDef struct) is a sequence of options
 * terminated by either a group separator option (e.g. -i) or a parameter that
 * is not an option (doesn't start with -). A group without a separator option
 * must always be first in the supplied groups list.
 *
 * All options within the same group are stored in one OptionGroup struct in an
 * OptionGroupList, all groups with the same group definition are stored in one
 * OptionGroupList in OptionParseContext.groups. The order of group lists is the
 * same as the order of group definitions.
 *)
//int split_commandline(OptionParseContext *octx, int argc, char *argv[],
//                      const OptionDef *options,
//                      const OptionGroupDef *groups, int nb_groups);

(**
 * Free all allocated memory in an OptionParseContext.
 *)
//procedure uninit_parse_context(AOptions: TFFOptions; octx: POptionParseContext);

(**
 * Find the '-loglevel' option in the command line args.
 *)
procedure parse_loglevel(argc: Integer; argv: PPAnsiChar; const options: POptionDef);

(**
 * Return index of option opt in argv or 0 if not found.
 *)
function locate_option(argc: Integer; argv: PPAnsiChar; const options: POptionDef;
  const optname: PAnsiChar): Integer;

(**
 * Check if the given stream matches a stream specifier.
 *
 * @param s  Corresponding format context.
 * @param st Stream from s to be checked.
 * @param spec A stream specifier of the [v|a|s|d]:[\<stream index\>] form.
 *
 * @return 1 if the stream matches, 0 if it doesn't, <0 on error
 *)
function check_stream_specifier(s: PAVFormatContext; st: PAVStream; const spec: PAnsiChar): Integer;

(**
 * Filter out options for given codec.
 *
 * Create a new options dictionary containing only the options from
 * opts which apply to the codec with ID codec_id.
 *
 * @param opts     dictionary to place options in
 * @param codec_id ID of the codec that should be filtered for
 * @param s Corresponding format context.
 * @param st A stream from s for which the options should be filtered.
 * @param codec The particular codec for which the options should be filtered.
 *              If null, the default one is looked up according to the codec id.
 * @return a pointer to the created dictionary
 *)
function filter_codec_opts(opts: PAVDictionary; codec_id: TAVCodecID;
  s: PAVFormatContext; st: PAVStream; codec: PAVCodec): PAVDictionary;

(**
 * Setup AVCodecContext options for avformat_find_stream_info().
 *
 * Create an array of dictionaries, one dictionary for each stream
 * contained in s.
 * Each dictionary will contain the options from codec_opts which can
 * be applied to the corresponding stream codec context.
 *
 * @return pointer to the created array of dictionaries, NULL if it
 * cannot be created
 *)
function setup_find_stream_info_opts(s: PAVFormatContext; codec_opts: PAVDictionary): PPAVDictionary;

(**
 * Print an error message to stderr, indicating filename and a human
 * readable description of the error code err.
 *
 * If strerror_r() is not available the use of this function in a
 * multithreaded application may be unsafe.
 *
 * @see av_strerror()
 *)
function print_error(const filename: string; err: Integer): string;

(**
 * Print the program banner to stderr. The banner contents depend on the
 * current version of the repository and of the libav* libraries used by
 * the program.
 *)
//procedure show_banner(argc: Integer; argv: PPAnsiChar; const options: POptionDef);

(**
 * Print the version of the program to stdout. The version message
 * depends on the current versions of the repository and of the libav*
 * libraries.
 * This option processing function does not utilize the arguments.
 *)
//function show_version(optctx: Pointer; const opt, arg: PAnsiChar): Integer;

(**
 * Print the license of the program to stdout. The license depends on
 * the license of the libraries compiled into the program.
 * This option processing function does not utilize the arguments.
 *)
//function show_license(optctx: Pointer; const opt, arg: PAnsiChar): Integer;

(**
 * Print a listing containing all the formats supported by the
 * program.
 * This option processing function does not utilize the arguments.
 *)
//function show_formats(optctx: Pointer; const opt, arg: PAnsiChar): Integer;

(**
 * Print a listing containing all the codecs supported by the
 * program.
 * This option processing function does not utilize the arguments.
 *)
//function show_codecs(optctx: Pointer; const opt, arg: PAnsiChar): Integer;

(**
 * Print a listing containing all the decoders supported by the
 * program.
 *)
//function show_decoders(optctx: Pointer; const opt, arg: PAnsiChar): Integer;

(**
 * Print a listing containing all the encoders supported by the
 * program.
 *)
//function show_encoders(optctx: Pointer; const opt, arg: PAnsiChar): Integer;

(**
 * Print a listing containing all the filters supported by the
 * program.
 * This option processing function does not utilize the arguments.
 *)
//function show_filters(optctx: Pointer; const opt, arg: PAnsiChar): Integer;

(**
 * Print a listing containing all the bit stream filters supported by the
 * program.
 * This option processing function does not utilize the arguments.
 *)
//function show_bsfs(optctx: Pointer; const opt, arg: PAnsiChar): Integer;

(**
 * Print a listing containing all the protocols supported by the
 * program.
 * This option processing function does not utilize the arguments.
 *)
//function show_protocols(optctx: Pointer; const opt, arg: PAnsiChar): Integer;

(**
 * Print a listing containing all the pixel formats supported by the
 * program.
 * This option processing function does not utilize the arguments.
 *)
//function show_pix_fmts(optctx: Pointer; const opt, arg: PAnsiChar): Integer;

(**
 * Print a listing containing all the standard channel layouts supported by
 * the program.
 * This option processing function does not utilize the arguments.
 *)
//function show_layouts(optctx: Pointer; const opt, arg: PAnsiChar): Integer;

(**
 * Print a listing containing all the color names and values recognized
 * by the program.
 *)
//procedure show_colors(optctx: Pointer; const opt, arg: PAnsiChar);

(**
 * Print a listing containing all the sample formats supported by the
 * program.
 *)
//function show_sample_fmts(optctx: Pointer; const opt, arg: PAnsiChar): Integer;

(**
 * Return a positive value if a line read from standard input
 * starts with [yY], otherwise return 0.
 *)
//function read_yesno(): Integer;

(**
 * Read the file with name filename, and put its content in a newly
 * allocated 0-terminated buffer.
 *
 * @param filename file to read from
 * @param bufptr location where pointer to buffer is returned
 * @param size   location where size of buffer is returned
 * @return >= 0 in case of success, a negative value corresponding to an
 * AVERROR error code in case of failure.
 *)
function ffutils_read_file(const filename: PAnsiChar; bufptr: PPAnsiChar; size: PCardinal): Integer;

(**
 * Get a file corresponding to a preset file.
 *
 * If is_path is non-zero, look for the file in the path preset_name.
 * Otherwise search for a file named arg.ffpreset in the directories
 * $FFMPEG_DATADIR (if set), $HOME/.ffmpeg, and in the datadir defined
 * at configuration time or in a "ffpresets" folder along the executable
 * on win32, in that order. If no such file is found and
 * codec_name is defined, then search for a file named
 * codec_name-preset_name.avpreset in the above-mentioned directories.
 *
 * @param filename buffer where the name of the found filename is written
 * @param filename_size size in bytes of the filename buffer
 * @param preset_name name of the preset to search
 * @param is_path tell if preset_name is a filename path
 * @param codec_name name of the codec for which to look for the
 * preset, may be NULL
 *)
//function get_preset_file(filename: PAnsiChar; filename_size: Cardinal;
//  const preset_name: PAnsiChar; is_path: Integer; const codec_name: PAnsiChar): PHandle; // FILE *

(**
 * Realloc array to hold new_size elements of elem_size.
 * Calls exit() on failure.
 *
 * @param array array to reallocate
 * @param elem_size size in bytes of each element
 * @param size new element count will be written here
 * @param new_size number of elements to place in reallocated array
 * @return reallocated array
 *)
function grow_array(arr: Pointer; elem_size: Integer; size: PInteger; new_size: Integer): Pointer;

//#define media_type_string av_get_media_type_string

//#define GROW_ARRAY(array, nb_elems)\
//    array = grow_array(array, sizeof(*array), &nb_elems, nb_elems + 1)

(*
#define GET_PIX_FMT_NAME(pix_fmt)\
    const char *name = av_get_pix_fmt_name(pix_fmt);

#define GET_SAMPLE_FMT_NAME(sample_fmt)\
    const char *name = av_get_sample_fmt_name(sample_fmt)

#define GET_SAMPLE_RATE_NAME(rate)\
    char name[16];\
    snprintf(name, sizeof(name), "%d", rate);

#define GET_CH_LAYOUT_NAME(ch_layout)\
    char name[16];\
    snprintf(name, sizeof(name), "0x%"PRIx64, ch_layout);

#define GET_CH_LAYOUT_DESC(ch_layout)\
    char name[128];\
    av_get_channel_layout_string(name, sizeof(name), 0, ch_layout);
*)

(****** end check from cmdutils.h **************)

(****** from SDL **************)
(*
 * This takes two audio buffers of the signed 16 bits format (AV_SAMPLE_FMT_S16)
 * and mixes them, performing addition, volume adjustment, and overflow clipping.
 * The volume ranges from 0 - 128, and should be set to MIX_MAXVOLUME for full
 * audio volume.  Note this does not change hardware volume.
 *)
const
  MIX_MAXVOLUME = 128;
type
  TAudioVolume = 0..MIX_MAXVOLUME;
procedure MixAudioU8 (const Source; var Dest; Count: Integer; Volume: TAudioVolume = MIX_MAXVOLUME);
procedure MixAudioS16(const Source; var Dest; Count: Integer; Volume: TAudioVolume = MIX_MAXVOLUME);
procedure MixAudioS32(const Source; var Dest; Count: Integer; Volume: TAudioVolume = MIX_MAXVOLUME);
(****** end from SDL **************)

function MKTAG(a, b, c, d: AnsiChar): Integer;

function PPtrIdx(P: PPAnsiChar; I: Integer): PAnsiChar; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PPtrIdx(P: PPWideChar; I: Integer): PWideChar; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PPtrIdx(P: PPAVStream; I: Integer): PAVStream; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PPtrIdx(P: PPAVProgram; I: Integer): PAVProgram; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PPtrIdx(P: PPAVChapter; I: Integer): PAVChapter; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PPtrIdx(P: PPAVCodec; I: Integer): PAVCodec; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PPtrIdx(P: PCardinal; I: Integer): Cardinal; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PPtrIdx(P: PDouble; I: Integer): Double; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PPtrIdx(P: PInt64; I: Integer): Int64; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PPtrIdx(P: PInteger; I: Integer): Integer; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PPtrIdx(P: PPAVSubtitleRect; I: Integer): PAVSubtitleRect; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PPtrIdx(P: PPByte; I: Integer): PByte; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PtrIdx(P: PByte; I: Integer): PByte; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PtrIdx(P: PPAnsiChar; I: Integer): PPAnsiChar; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PtrIdx(P: PPAVStream; I: Integer): PPAVStream; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PtrIdx(P: PPAVChapter; I: Integer): PPAVChapter; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PtrIdx(P: PPAVCodec; I: Integer): PPAVCodec; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PtrIdx(P: PSpecifierOpt; I: Integer): PSpecifierOpt; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PtrIdx(P: PPAVDictionary; I: Integer): PPAVDictionary; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PtrIdx(P: PDouble; I: Integer): PDouble; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PtrIdx(P: PInteger; I: Integer): PInteger; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PtrIdx(P: PInt64; I: Integer): PInt64; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PtrIdx(P: PAVSubtitleRect; I: Integer): PAVSubtitleRect; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PtrIdx(P: PAVRational; I: Integer): PAVRational; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PtrIdx(P: PAnsiChar; I: Integer): PAnsiChar; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
function PtrIdx(P: PRcOverride; I: Integer): PRcOverride; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}

{$IFDEF MSWINDOWS}
function GetTimeZoneAbbreviation: string;
function DateTimeOffset: TDateTime;
function DateTimeToUnix(const AValue: TDateTime): Int64;
function DateTimeToUnixEx(const AValue: TDateTime): Int64;
function UnixToDateTime(const AValue: Int64): TDateTime;
function UnixToDateTimeEx(const AValue: Int64): TDateTime;
{$ENDIF}

function DurationToStr(ADuration: Int64): string; overload;
function DurationToStr(ADuration: Int64; time_base: TAVRational): string; overload;
function GetFrameInterval(AFrameRate: TAVRational): Int64;

{$IF Defined(FPC) Or Defined(FFFMX)}
function BytesPerScanline(PixelsPerScanline, BitsPerPixel, Alignment: Longint): Longint;
{$IFEND}
{$IFDEF ACTIVEX}
procedure DIBToBitmap(ABitmapPtr: PBitmap; ABitmap: TBitmap);
{$ENDIF}
function isprint(c: Byte): Boolean; {$IFDEF USE_INLINE}inline;{$ENDIF}
function GetMetaValue(const AMeta: PAVDictionary; const AName: AnsiString; const ADefault: string = ''): string;
function GetCodecName(codec: PAVCodecContext; const AEncode: Boolean = False): string;

function AVMediaTypeCaption(ctype: TAVMediaType): string;
function AVPictureTypeCaption(ctype: TAVPictureType): string;

function RegisterProtocol(AProtocol: PURLProtocol): Boolean;
procedure RegisterInputFormat(AInputFormat: PAVInputFormat);
procedure RegisterOutputFormat(AOutputFormat: PAVOutputFormat);

//procedure RegisterVideoFilter(AFilter: PAVFilter);

var
  GOptionError: string = '';

implementation

uses
  FFLog;

const
  ALLOC = 1;

function MKTAG(a, b, c, d: AnsiChar): Integer;
begin
  Result :=(Ord(a) or (Ord(b) shl 8) or (Ord(c) shl 16) or (Ord(d) shl 24));
end;

function PPtrIdx(P: PPAnsiChar; I: Integer): PAnsiChar;
begin
  Inc(P, I);
  Result := P^;
end;

function PPtrIdx(P: PPWideChar; I: Integer): PWideChar;
begin
  Inc(P, I);
  Result := P^;
end;

function PPtrIdx(P: PPAVStream; I: Integer): PAVStream;
begin
  Inc(P, I);
  Result := P^;
end;

function PPtrIdx(P: PPAVProgram; I: Integer): PAVProgram;
begin
  Inc(P, I);
  Result := P^;
end;

function PPtrIdx(P: PPAVChapter; I: Integer): PAVChapter;
begin
  Inc(P, I);
  Result := P^;
end;

function PPtrIdx(P: PPAVCodec; I: Integer): PAVCodec;
begin
  Inc(P, I);
  Result := P^;
end;

function PPtrIdx(P: PCardinal; I: Integer): Cardinal;
begin
  Inc(P, I);
  Result := P^;
end;

function PPtrIdx(P: PDouble; I: Integer): Double;
begin
  Inc(P, I);
  Result := P^;
end;

function PPtrIdx(P: PInt64; I: Integer): Int64;
begin
  Inc(P, I);
  Result := P^;
end;

function PPtrIdx(P: PInteger; I: Integer): Integer;
begin
  Inc(P, I);
  Result := P^;
end;

function PPtrIdx(P: PPAVSubtitleRect; I: Integer): PAVSubtitleRect;
begin
  Inc(P, I);
  Result := P^;
end;

function PPtrIdx(P: PPByte; I: Integer): PByte;
begin
  Inc(P, I);
  Result := P^;
end;

function PtrIdx(P: PByte; I: Integer): PByte;
begin
  Result := P;
  Inc(Result, I);
end;

function PtrIdx(P: PPAnsiChar; I: Integer): PPAnsiChar;
begin
  Result := P;
  Inc(Result, I);
end;
function PtrIdx(P: PPAVStream; I: Integer): PPAVStream;
begin
  Result := P;
  Inc(Result, I);
end;

function PtrIdx(P: PPAVChapter; I: Integer): PPAVChapter;
begin
  Result := P;
  Inc(Result, I);
end;

function PtrIdx(P: PPAVCodec; I: Integer): PPAVCodec;
begin
  Result := P;
  Inc(Result, I);
end;

function PtrIdx(P: PSpecifierOpt; I: Integer): PSpecifierOpt;
begin
  Inc(P, I);
  Result := P;
end;

function PtrIdx(P: PPAVDictionary; I: Integer): PPAVDictionary;
begin
  Result := P;
  Inc(Result, I);
end;

function PtrIdx(P: PDouble; I: Integer): PDouble;
begin
  Result := P;
  Inc(Result, I);
end;

function PtrIdx(P: PInteger; I: Integer): PInteger;
begin
  Result := P;
  Inc(Result, I);
end;

function PtrIdx(P: PInt64; I: Integer): PInt64;
begin
  Result := P;
  Inc(Result, I);
end;

function PtrIdx(P: PAVSubtitleRect; I: Integer): PAVSubtitleRect;
begin
  Result := P;
  Inc(Result, I);
end;

function PtrIdx(P: PAVRational; I: Integer): PAVRational;
begin
  Result := P;
  Inc(Result, I);
end;

function PtrIdx(P: PAnsiChar; I: Integer): PAnsiChar;
begin
  Result := P;
  Inc(Result, I);
end;

function PtrIdx(P: PRcOverride; I: Integer): PRcOverride;
begin
  Result := P;
  Inc(Result, I);
end;

function PtrIdx(P: POption; I: Integer): POption; overload;
begin
  Result := P;
  Inc(Result, I);
end;

{$IFDEF MSWINDOWS}
function GetTimeZoneAbbreviation: string;
const
  CGMT = 'UTC';//'GMT';
  CPlus = '+';
  CMinus = '-';
  CAbbreviationFormat_Minutes = '%s%s%.2d:%.2d';
{$IFNDEF VCL_7_OR_ABOVE}
  MinsPerHour = 60;
  SecsPerMin  = 60;
{$ENDIF}
{$IFNDEF VCL_2009_OR_ABOVE}
  SecsPerHour = SecsPerMin * MinsPerHour;
{$ENDIF}
var
  TimeZoneInformation: TTimeZoneInformation;
  LAbsOffset, LOffset: Int64;
  LSignChar: Char;
  LHours, LMinutes: Integer;
begin
  GetTimeZoneInformation(TimeZoneInformation);
  LOffset := Round(TimeZoneInformation.Bias / (24 * 60) * SecsPerDay);
  if LOffset = 0 then
    Result := CGMT
  else
  begin
    { Extract the number of distinct hours and minutes }
    LAbsOffset := Abs(LOffset);

    LHours := LAbsOffset div SecsPerHour;
    LMinutes := (LAbsOffset mod SecsPerHour) div SecsPerMin;

    { Select the proper character }
    if LOffset < 0 then
      LSignChar := CMinus
    else
      LSignChar := CPlus;
    Result := Format(CAbbreviationFormat_Minutes, [CGMT, LSignChar, LHours, LMinutes])
  end;
end;

function DateTimeOffset: TDateTime;
var
  TimeZoneInformation: TTimeZoneInformation;
begin
  GetTimeZoneInformation(TimeZoneInformation);
  Result := -TimeZoneInformation.Bias / (24 * 60);
end;

function DateTimeToUnix(const AValue: TDateTime): Int64;
begin
  Result := Round((AValue - UnixDateDelta) * SecsPerDay)
end;

function DateTimeToUnixEx(const AValue: TDateTime): Int64;
begin
  Result := Round((AValue - UnixDateDelta - DateTimeOffset) * SecsPerDay)
end;

function UnixToDateTime(const AValue: Int64): TDateTime;
begin
  Result := AValue / SecsPerDay + UnixDateDelta;
end;

function UnixToDateTimeEx(const AValue: Int64): TDateTime;
begin
  Result := AValue / SecsPerDay + UnixDateDelta + DateTimeOffset;
end;
{$ENDIF}

(****** TODO: check from libavformat/utils.c av_dump_format() **************)
function DurationToStr(ADuration: Int64): string;
var
  hours, mins, secs, us: Integer;
begin
  if ADuration <> AV_NOPTS_VALUE then
  begin
    secs := (ADuration + 5000) div AV_TIME_BASE;
    us := (ADuration + 5000) mod AV_TIME_BASE;
    mins := secs div 60;
    secs := secs mod 60;
    hours := mins div 60;
    mins := mins mod 60;
    Result := Format('%.2d:%.2d:%.2d.%.3d',
                    [hours, mins, secs, (1000 * us) div AV_TIME_BASE]);
  end
  else
    Result := 'N/A';
end;

function DurationToStr(ADuration: Int64; time_base: TAVRational): string;
begin
  if (ADuration <> AV_NOPTS_VALUE) and (av_cmp_q(time_base, AV_TIME_BASE_Q) <> 0) then
    ADuration := av_rescale_q(ADuration, time_base, AV_TIME_BASE_Q);
  Result := DurationToStr(ADuration);
end;

// return interval between two frames
function GetFrameInterval(AFrameRate: TAVRational): Int64;
begin
  with AFrameRate do
    if (num <> 0) and (den <> 0) then
      Result := Int64(AV_TIME_BASE) * den div num
    else
      Result := Int64(AV_TIME_BASE) div 25; // assume fps as 25
end;

(****** TODO: check from cmdutils.c **************)

{ TFFOptions }

constructor TFFOptions.Create;
begin
  Fsws_flags := SWS_BICUBIC;
  Fsws_opts := nil;
  Fswr_opts := nil;
  Fformat_opts := nil;
  Fcodec_opts := nil;
end;

destructor TFFOptions.Destroy;
begin
  uninit_opts;
  inherited Destroy;
end;

function TFFOptions.GetOptionParseContext: POptionParseContext;
begin
  Result := @Foctx;
end;

procedure TFFOptions.init_opts;
begin
  uninit_opts;
  Fsws_opts := sws_getContext(16, 16, TAVPixelFormat(0),
                              16, 16, TAVPixelFormat(0),
                              Fsws_flags, nil, nil, nil);
end;

procedure TFFOptions.uninit_opts;
begin
  if Assigned(sws_freeContext) then
    sws_freeContext(Fsws_opts);   // XXX memory leak if LibAV have been unloaded
  Fsws_opts := nil;
  if Assigned(av_dict_free) then  // XXX memory leak if LibAV have been unloaded
  begin
    av_dict_free(@Fswr_opts);
    av_dict_free(@Fformat_opts);
    av_dict_free(@Fcodec_opts);
    av_dict_free(@Fresample_opts);
  end;
end;

(*
procedure log_callback_help(ptr: Pointer; level: Integer; const fmt: PAnsiChar; vl: PAnsiChar{va_list});
begin
  // TODO: cmdutils.c
  // do nothing now
end;

procedure log_callback_report(ptr: Pointer; level: Integer; const fmt: PAnsiChar; vl: PAnsiChar{va_list}); cdecl;
begin
  // TODO: cmdutils.c
  // do nothing now
end;

function parse_number_or_die(const context, numstr: PAnsiChar; ttype: Integer; min, max: Double): Double;
begin
  // TODO: cmdutils.c
  // do nothing now
  Result := 0;
end;
*)

function parse_integer_or_die(const context, numstr: PAnsiChar): Integer;
begin
  try
    Result := StrToInt(string(numstr));
  except on E: Exception do
    raise Exception.CreateFmt('Expected integer for "%s" but found "%s"', [context, numstr]);
  end;
end;

function parse_int64_or_die(const context, numstr: PAnsiChar): Int64;
begin
  try
    Result := StrToInt64(string(numstr));
  except on E: Exception do
    raise Exception.CreateFmt('Expected int64 for "%s" but found "%s"', [context, numstr]);
  end;
end;

function parse_float_or_die(const context, numstr: PAnsiChar): Single;
begin
  try
    Result := StrToFloat(string(numstr));
  except on E: Exception do
    raise Exception.CreateFmt('Expected float for "%s" but found "%s"', [context, numstr]);
  end;
end;

function parse_double_or_die(const context, numstr: PAnsiChar): Double;
begin
  try
    Result := StrToFloat(string(numstr));
  except on E: Exception do
    raise Exception.CreateFmt('Expected double for "%s" but found "%s"', [context, numstr]);
  end;
end;

function parse_time_or_die(const context, timestr: PAnsiChar; is_duration: Integer): Int64;
var
  us: Int64;
  for_what: string;
begin
  if av_parse_time(@us, timestr, is_duration) < 0 then
  begin
    if is_duration <> 0 then
      for_what := 'duration'
    else
      for_what := 'date';
    raise Exception.CreateFmt('Invalid %s specification for "%s": "%s"',
                              [for_what, string(context), string(timestr)]);
    //exit_program(1);
  end;
  Result := us;
end;

{
procedure show_help_options(const options: POptionDef; const msg: PAnsiChar;
  req_flags, rej_flags, alt_flags: Integer);
begin
  // TODO: cmdutils.c
  // do nothing now
end;

procedure show_help_children(const cclass: PAVClass; flags: Integer);
begin
  // TODO: cmdutils.c
  // do nothing now
end;
}

function find_option(po: POptionDef; const name: PAnsiChar): POptionDef;
var
  p: PAnsiChar;
  len: Integer;
begin
  p := my_strchr(name, ':');
  if Assigned(p) then
    len := Integer(p) - Integer(name)
  else
    len := MyStrLen(name);

  while po.name <> nil do
  begin
    if ({AnsiStrLComp}my_strncmp(name, po.name, len) = 0) and (Integer(MyStrLen(po.name)) = len) then
      Break;
    Inc(po);
  end;
  Result := po;
end;

(**
 * Prepare command line arguments for executable.
 * For Windows - perform wide-char to UTF-8 conversion.
 * Input arguments should be main() function arguments.
 * @param argc_ptr Arguments number (including executable)
 * @param argv_ptr Arguments list.
 *)
//procedure prepare_app_arguments(argc_ptr: PInteger; argv_ptr: Pointer{PPPAnsiChar});
//begin
  // TODO: cmdutils.c
  (* nothing to do *)
//end;

function write_option(optctx: Pointer; const po: POptionDef; const opt, arg: PAnsiChar): Integer;
var
  dst: Pointer;
  dstcount: PInteger;
  so: PPSpecifierOpt;
  p: PAnsiChar;
  str: PAnsiChar;
  ret: Integer;
begin
  (* new-style options contain an offset into optctx, old-style address of
   * a global var*)
  if (po.flags and (OPT_OFFSET or OPT_SPEC)) <> 0 then
  begin
    Assert(Assigned(optctx));
    dst := Pointer(Integer(optctx) + po.u.off);
  end
  else
    dst := po.u.dst_ptr;

  if (po.flags and OPT_SPEC) <> 0 then
  begin
    so := dst;
    p := my_strchr(opt, ':');

    dstcount := PInteger(Integer(so) + SizeOf({PSpecifierOpt}so^));
    so^ := grow_array(so^, SizeOf({TSpecifierOpt}so^^), dstcount, dstcount^ + 1);
    if Assigned(p) then
      PtrIdx(so^, dstcount^ - 1).specifier := av_strdup(p + 1)
    else
      PtrIdx(so^, dstcount^ - 1).specifier := av_strdup('');
    dst := @PSpecifierOpt(PtrIdx(so^, dstcount^ - 1)).u;
  end;

  if (po.flags and OPT_STRING) <> 0 then
  begin
    str := av_strdup(arg);
    av_freep(dst);
    PPAnsiChar(dst)^ := str;
  end
  else if ((po.flags and OPT_BOOL) <> 0) or ((po.flags and OPT_INT) <> 0) then
    PInteger(dst)^ := parse_integer_or_die(opt, arg)
  else if (po.flags and OPT_INT64) <> 0 then
    PInt64(dst)^ := parse_int64_or_die(opt, arg)
  else if (po.flags and OPT_TIME) <> 0 then
    PInt64(dst)^ := parse_time_or_die(opt, arg, 1)
  else if (po.flags and OPT_FLOAT) <> 0 then
    PSingle(dst)^ := parse_float_or_die(opt, arg)
  else if (po.flags and OPT_DOUBLE) <> 0 then
    PDouble(dst)^ := parse_double_or_die(opt, arg)
  else if Assigned(po.u.func_arg) then
  begin
    GOptionError := '';
    ret := po.u.func_arg(optctx, opt, arg);
    if ret < 0 then
    begin
      if GOptionError <> '' then
        GOptionError := GOptionError + #13#10 + Format('Failed to set value "%s" for option "%s": %s', [string(arg), string(opt), print_error('', ret)])
      else
        GOptionError := Format('Failed to set value "%s" for option "%s": %s', [string(arg), string(opt), print_error('', ret)]);
      av_log(nil, AV_LOG_ERROR, 'Failed to set value "%s" for option "%s": %s'#10, arg, opt, PAnsiChar(AnsiString(print_error('', ret))));
      Result := ret;
      Exit;
    end;
  end;
  //if (po.flags and OPT_EXIT) <> 0 then
  //  exit_program(0);
  Result := 0;
end;

function parse_option(optctx: Pointer; const opt, _arg: PAnsiChar; const options: POptionDef): Integer;
var
  po: POptionDef;
  ret: Integer;
  arg: PAnsiChar;
begin
  arg := _arg;
  po := find_option(options, opt);
  if not Assigned(po.name) and (opt[0] = 'n') and (opt[1] = 'o') then
  begin
    (* handle 'no' bool option *)
    po := find_option(options, opt + 2);
    if (Assigned(po.name) and ((po.flags and OPT_BOOL) <> 0)) then
      arg := '0';
  end
  else if (po.flags and OPT_BOOL) <> 0 then
    arg := '1';

  if not Assigned(po.name) then
    po := find_option(options, 'default');
  if not Assigned(po.name) then
  begin
    GOptionError := Format('Unrecognized option "%s"', [string(opt)]);
    av_log(nil, AV_LOG_ERROR, 'Unrecognized option "%s"'#10, opt);
    Result := AVERROR_EINVAL;
    Exit;
  end;
  if ((po.flags and HAS_ARG) <> 0) and not Assigned(arg) then
  begin
    GOptionError := Format('Missing argument for option "%s"', [string(opt)]);
    av_log(nil, AV_LOG_ERROR, 'Missing argument for option "%s"'#10, opt);
    Result := AVERROR_EINVAL;
    Exit;
  end;

  ret := write_option(optctx, po, opt, arg);
  if ret < 0 then
  begin
    Result := ret;
    Exit;
  end;

  //return !!(po->flags & HAS_ARG);
  Result := Ord((po.flags and HAS_ARG) <> 0);
end;

function parse_options(optctx: Pointer; argc: Integer; argv: PPAnsiChar;
  const options: POptionDef; AReturnOnInvalidOption: Boolean): Integer;
var
  opt: PAnsiChar;
  optindex, {handleoptions,} ret: Integer;
begin
  (* perform system-dependent conversions for arguments list *)
  //prepare_app_arguments(&argc, &argv);

  (* parse options *)
  optindex := 0;
//  handleoptions := 1;
  while optindex < argc do
  begin
    opt := PPtrIdx(argv, optindex);
    Inc(optindex);
    if {(handleoptions <> 0) and} (opt^ = '-') and ((opt + 1)^ <> #0) then
    begin
{
      if (opt[1] = '-') and (opt[2] = #0) then
      begin
        handleoptions := 0;
        Continue;
      end;
}
      Inc(opt); // skip '-'
      GOptionError := '';
      ret := parse_option(optctx, opt, PPtrIdx(argv, optindex), options);
      if ret < 0 then
      begin
        if AReturnOnInvalidOption then
        begin
          Result := ret;
          Exit;
        end;
        ret := 0;
      end;
      Inc(optindex, ret);
    end
    else if AReturnOnInvalidOption then
    begin
      if opt^ <> #0 then
      begin
        GOptionError := 'Failed to parse options on ' + string(opt);
        av_log(nil, AV_LOG_ERROR, 'Failed to parse options on %s'#10, opt);
      end
      else
      begin
        GOptionError := 'Failed to parse options';
        av_log(nil, AV_LOG_ERROR, 'Failed to parse options'#10);
      end;
      Result := AVERROR_EINVAL;
      Exit;
    end
    else
    begin
      if opt^ <> #0 then
        av_log(nil, AV_LOG_ERROR, 'Invalid option %s found while parsing options, ignore'#10, opt)
      else
        av_log(nil, AV_LOG_ERROR, 'Invalid option found while parsing options, ignore'#10);
    end;
  end;
  Result := 0;
end;

function parse_optgroup(optctx: Pointer; g: POptionGroup; inout: string; filename: PAnsiChar; group_flags: Integer; AReturnOnInvalidOption: Boolean): Integer;
var
  i, ret: Integer;
  o: POption;
begin
  av_log(nil, AV_LOG_DEBUG, 'Parsing a group of options: %s.'#10, PAnsiChar(AnsiString(inout)));

  for i := 0 to g.nb_opts - 1 do
  begin
    o := PtrIdx(g.opts, i);

    if (group_flags <> 0) and
      ((group_flags and o.opt.flags) = 0) then
    begin
      av_log(nil, AV_LOG_ERROR, 'Option %s (%s) cannot be applied to ' +
             '%s %s -- you are trying to apply an input option to an ' +
             'output file or vice versa. Move this option before the ' +
             'file it belongs to.'#10, o.key, o.opt.help,
             PAnsiChar(AnsiString(inout)), filename);
      Result := AVERROR_EINVAL;
      Exit;
    end;

    av_log(nil, AV_LOG_DEBUG, 'Applying option %s (%s) with argument %s.'#10,
           o.key, o.opt.help, o.val);

    ret := write_option(optctx, o.opt, o.key, o.val);
    if ret < 0 then
    begin
      Result := ret;
      Exit;
    end;
  end;

  av_log(nil, AV_LOG_DEBUG, 'Successfully parsed a group of options.'#10);

  Result := 0;
end;

function locate_option(argc: Integer; argv: PPAnsiChar; const options: POptionDef;
  const optname: PAnsiChar): Integer;
var
  po: POptionDef;
  i: Integer;
  cur_opt: PAnsiChar;
begin
  i := 0;
  while i < argc do
  begin
    cur_opt := PPtrIdx(argv, i);
    if cur_opt^ <> '-' then
    begin
      Inc(i);
      Continue;
    end;
    Inc(cur_opt);

    po := find_option(options, cur_opt);
    if not Assigned(po.name) and (cur_opt^ = 'n') and ((cur_opt + 1)^ = 'o') then
      po := find_option(options, cur_opt + 2);

    if (not Assigned(po.name) and (my_strcmp(cur_opt, optname) = 0)) or
           (Assigned(po.name) and (my_strcmp(optname, po.name) = 0)) then
    begin
      Result := i;
      Exit;
    end;

    Inc(i);
    if (po.flags and HAS_ARG) <> 0 then
      Inc(i);
  end;
  Result := -1;
end;

{
procedure dump_argument(const a: PAnsiChar);
begin
  // TODO: cmdutils.c
  // do nothing now
end;
}

procedure parse_loglevel(argc: Integer; argv: PPAnsiChar; const options: POptionDef);
var
  idx: Integer;
begin
  idx := locate_option(argc, argv, options, 'loglevel');
  if idx < 0 then
    idx := locate_option(argc, argv, options, 'v');
  if (idx >= 0) and Assigned(PPtrIdx(argv, idx + 1)) then
    ff_opt_loglevel(nil, 'loglevel', PPtrIdx(argv, idx + 1));
(*
    idx = locate_option(argc, argv, options, "report");
    if ((env = getenv("FFREPORT")) || idx) {
        init_report(env);
        if (report_file) {
            int i;
            fprintf(report_file, "Command line:\n");
            for (i = 0; i < argc; i++) {
                dump_argument(argv[i]);
                fputc(i < argc - 1 ? ' ' : '\n', report_file);
            }
            fflush(report_file);
        }
    }
*)
end;

function opt_find(obj: Pointer; const name, unit_: PAnsiChar;
  opt_flags, search_flags: Integer): PAVOption;
var
  o: PAVOption;
begin
  o := av_opt_find(obj, name, unit_, opt_flags, search_flags);
  if Assigned(o) and (o.flags = 0) then
    Result := nil
  else
    Result := o;
end;

function FLAGS(o: PAVOption): Integer;
begin
  if o.ttype = AV_OPT_TYPE_FLAGS then
    Result := AV_DICT_APPEND
  else
    Result := 0;
end;

function TFFOptions.opt_default({optctx: Pointer; }const opt, arg: PAnsiChar): Integer;
var
  o: PAVOption;
  consumed: Integer;
  opt_stripped: array[0..128-1] of AnsiChar;
  p: PAnsiChar;
  cc, fc: PAVClass;
{$IFDEF CONFIG_AVRESAMPLE}
  rc: PAVClass;
{$ENDIF}
  sc, swr_class: PAVClass;
  swr: PSwrContext;
  ret: Integer;
begin
  consumed := 0;

  if (my_strcmp(opt, 'debug') = 0) or (my_strcmp(opt, 'fdebug') = 0) then
    FFLogger.LogLevel := IntToLogLevel(AV_LOG_DEBUG); //av_log_set_level(AV_LOG_DEBUG);

  p := my_strchr(opt, ':');
  if not Assigned(p) then
    p := opt + MyStrLen(opt);
  if SizeOf(opt_stripped) < p - opt + 1 then
    av_strlcpy(opt_stripped, opt, SizeOf(opt_stripped))
  else
    av_strlcpy(opt_stripped, opt, p - opt + 1);

  // codec options
  cc := avcodec_get_class;
  o := opt_find(@cc, opt_stripped, nil, 0,AV_OPT_SEARCH_CHILDREN or AV_OPT_SEARCH_FAKE_OBJ);
  if not Assigned(o) and ((opt^ = 'v') or (opt^ = 'a') or (opt^ = 's')) then
    o := opt_find(@cc, opt + 1, nil, 0, AV_OPT_SEARCH_FAKE_OBJ);
  if Assigned(o) then
  begin
    av_dict_set(@Fcodec_opts, opt, arg, FLAGS(o));
    consumed := 1;
  end;

  // format options
  fc := avformat_get_class;
  o := opt_find(@fc, opt, nil, 0, AV_OPT_SEARCH_CHILDREN or AV_OPT_SEARCH_FAKE_OBJ);
  if Assigned(o) then
  begin
    av_dict_set(@Fformat_opts, opt, arg, FLAGS(o));
    if consumed <> 0 then
      av_log(nil, AV_LOG_VERBOSE, 'Routing option %s to both codec and muxer layer'#10, opt);
    consumed := 1;
  end;

  // sws options
  if consumed = 0 then
  begin
    sc := sws_get_class();
    if Assigned(opt_find(@sc, opt, nil, 0, AV_OPT_SEARCH_CHILDREN or AV_OPT_SEARCH_FAKE_OBJ)) then
    begin
      // XXX we only support sws_flags, not arbitrary sws options
      ret := av_opt_set(Fsws_opts, opt, arg, 0);
      if ret < 0 then
      begin
        GOptionError := Format('Error setting option "%s"', [string(opt)]);
        av_log(nil, AV_LOG_ERROR, 'Error setting option "%s"'#10, opt);
        Result := ret;
        Exit;
      end;
      consumed := 1;
    end;
  end;

  // swr options
  if consumed = 0 then
  begin
    swr_class := swr_get_class();
    o := opt_find(@swr_class, opt, nil, 0, AV_OPT_SEARCH_CHILDREN or AV_OPT_SEARCH_FAKE_OBJ);
    if Assigned(o) then
    begin
      swr := swr_alloc();
      ret := av_opt_set(swr, opt, arg, 0);
      swr_free(@swr);
      if ret < 0 then
      begin
        GOptionError := Format('Error setting option "%s"', [string(opt)]);
        av_log(nil, AV_LOG_ERROR, 'Error setting option "%s"'#10, opt);
        Result := ret;
        Exit;
      end;
      av_dict_set(@Fswr_opts, opt, arg, FLAGS(o));
      consumed := 1;
    end;
  end;

{$IFDEF CONFIG_AVRESAMPLE}
  rc := avresample_get_class();
  o := opt_find(@rc, opt, nil, 0,
                   AV_OPT_SEARCH_CHILDREN or AV_OPT_SEARCH_FAKE_OBJ);
  if Assigned(o) then
  begin
    av_dict_set(@Fresample_opts, opt, arg, FLAGS(o));
    consumed := 1;
  end;
{$ENDIF}

  if consumed <> 0 then
    Result := 0
  else
    Result := AVERROR_OPTION_NOT_FOUND;
end;

function TFFOptions.opt_default({optctx: Pointer; }const opt, arg: string): Integer;
begin
  Result := opt_default({optctx, }PAnsiChar(AnsiString(opt)), PAnsiChar(AnsiString(arg)));
end;

(*
 * Finish parsing an option group.
 *)
procedure TFFOptions.finish_group;
begin
  Assert((Foctx.file_opts.sws_opts = nil) and
         (Foctx.file_opts.swr_opts = nil) and
         (Foctx.file_opts.codec_opts = nil) and
         (Foctx.file_opts.format_opts = nil) and
         (Foctx.file_opts.resample_opts = nil));
  Foctx.file_opts.sws_opts    := Fsws_opts;
  Foctx.file_opts.swr_opts    := Fswr_opts;
  Foctx.file_opts.codec_opts  := Fcodec_opts;
  Foctx.file_opts.format_opts := Fformat_opts;
  Foctx.file_opts.resample_opts := Fresample_opts;

  Fcodec_opts  := nil;
  Fformat_opts := nil;
  Fresample_opts := nil;
  Fsws_opts    := nil;
  Fswr_opts    := nil;

  init_opts;
end;

(*
 * Add an option instance to currently parsed group.
 *)
procedure add_opt(global_group, file_group: POptionGroup; const opt: POptionDef; const key, val: PAnsiChar);
var
  g: POptionGroup;
begin
  if (opt.flags and (OPT_PERFILE or OPT_SPEC or OPT_OFFSET)) = 0 then
    g := global_group
  else
    g := file_group;

  g.opts := grow_array(g.opts, SizeOf(g.opts^), @g.nb_opts, g.nb_opts + 1);
  PtrIdx(g.opts, g.nb_opts - 1).opt := opt;
  PtrIdx(g.opts, g.nb_opts - 1).key := key;
  PtrIdx(g.opts, g.nb_opts - 1).val := val;
end;

procedure TFFOptions.init_parse_context;
begin
  uninit_parse_context;
  FillChar(Foctx, SizeOf(Foctx), 0);

  init_opts();
end;

procedure TFFOptions.uninit_parse_context;
begin
  av_freep(@Foctx.file_opts.opts);
  av_dict_free(@Foctx.file_opts.codec_opts);
  av_dict_free(@Foctx.file_opts.format_opts);
  av_dict_free(@Foctx.file_opts.resample_opts);
  sws_freeContext(Foctx.file_opts.sws_opts);
  Foctx.file_opts.sws_opts := nil;
  av_dict_free(@Foctx.file_opts.swr_opts);

  av_freep(@Foctx.global_opts.opts);

  uninit_opts();
end;

function TFFOptions.parse_options(optctx: Pointer; argc: Integer; argv: PPAnsiChar;
  const options: POptionDef; inout: string; AReturnOnInvalidOption: Boolean): Integer;
type
  P_OptionsContext = ^T_OptionsContext;
  T_OptionsContext = record
    g: POptionGroup;
    dummy: Integer;
  end;
var
  optindex: Integer;
  opt, arg: PAnsiChar;
  po: POptionDef;
  ret: Integer;
begin
  optindex := 0;

  av_log(nil, AV_LOG_DEBUG, 'Parsing the options.'#10);

  while optindex < argc do
  begin
    opt := PPtrIdx(argv, optindex);
    Inc(optindex);

    av_log(nil, AV_LOG_DEBUG, 'Reading option "%s" ... ', opt);

    if (opt[0] <> '-') or (opt[1] = #0) then
    begin
      if AReturnOnInvalidOption then
      begin
        if opt^ <> #0 then
        begin
          GOptionError := 'Failed to parse options on ' + string(opt);
          av_log(nil, AV_LOG_ERROR, 'Failed to parse options on %s'#10, opt);
        end
        else
        begin
          GOptionError := 'Failed to parse options';
          av_log(nil, AV_LOG_ERROR, 'Failed to parse options'#10);
        end;
        Result := AVERROR_EINVAL;
        Exit;
      end
      else
      begin
        if opt^ <> #0 then
          av_log(nil, AV_LOG_ERROR, 'Invalid option %s found while parsing options, ignore'#10, opt)
        else
          av_log(nil, AV_LOG_ERROR, 'Invalid option found while parsing options, ignore'#10);
      end;
      Continue;
    end;

    Inc(opt); // skip '-'

    (* normal options *)
    po := find_option(options, opt);
    if Assigned(po.name) then
    begin
      {if (po.flags and OPT_EXIT) <> 0 then
      begin
        (* optional argument, e.g. -h *)
        arg := PPtrIdx(argv, optindex);
        Inc(optindex);
      end
      else} if (po.flags and HAS_ARG) <> 0 then
      begin
        arg := PPtrIdx(argv, optindex);
        Inc(optindex);
        if not Assigned(arg) then
        begin
          av_log(nil, AV_LOG_ERROR, 'Missing argument for option "%s".'#10, opt);
          Result := AVERROR_EINVAL;
          Exit;
        end;
      end
      else
        arg := '1';

      add_opt(@Foctx.global_opts, @Foctx.file_opts, po, opt, arg);
      av_log(nil, AV_LOG_DEBUG, 'matched as option "%s" (%s) with argument "%s".'#10,
             po.name, po.help, arg);
      Continue;
    end;

    (* AVOptions *)
    if Assigned(PPtrIdx(argv, optindex)) then
    begin
      ret := Self.opt_default(opt, PPtrIdx(argv, optindex));
      if ret >= 0 then
      begin
        av_log(nil, AV_LOG_DEBUG, 'matched as AVOption "%s" with argument "%s".'#10,
               opt, PPtrIdx(argv, optindex));
        Inc(optindex);
        Continue;
      end
      else if ret <> AVERROR_OPTION_NOT_FOUND then
      begin
        av_log(nil, AV_LOG_ERROR, 'Error parsing option "%s" with argument "%s".'#10,
               opt, PPtrIdx(argv, optindex));
        Result := ret;
        Exit;
      end;
    end;

    (* boolean -nofoo options *)
    if (opt[0] = 'n') and (opt[1] = 'o') then
    begin
      po := find_option(options, opt + 2);
      if Assigned(po) and Assigned(po.name) and ((po.flags and OPT_BOOL) <> 0) then
      begin
        add_opt(@Foctx.global_opts, @Foctx.file_opts, po, opt, '0');
        av_log(nil, AV_LOG_DEBUG, 'matched as option "%s" (%s) with argument 0.'#10,
               po.name, po.help);
        Continue;
      end;
    end;

    av_log(nil, AV_LOG_ERROR, 'Unrecognized option "%s".'#10, opt);
    if AReturnOnInvalidOption then
    begin
      Result := AVERROR_OPTION_NOT_FOUND;
      Exit;
    end;
  end;

  finish_group;

  av_log(nil, AV_LOG_DEBUG, 'Finished parsing the options.'#10);

  Result := 0;
end;

function ff_opt_loglevel(optctx: Pointer; opt, arg: PAnsiChar): Integer;
type
  Tlog_item = record
    name: PAnsiChar;
    level: Integer;
  end;
const
  log_levels: array[0..7] of Tlog_item = (
      ( name: 'quiet'  ; level: AV_LOG_QUIET   ),
      ( name: 'panic'  ; level: AV_LOG_PANIC   ),
      ( name: 'fatal'  ; level: AV_LOG_FATAL   ),
      ( name: 'error'  ; level: AV_LOG_ERROR   ),
      ( name: 'warning'; level: AV_LOG_WARNING ),
      ( name: 'info'   ; level: AV_LOG_INFO    ),
      ( name: 'verbose'; level: AV_LOG_VERBOSE ),
      ( name: 'debug'  ; level: AV_LOG_DEBUG   )
    );
var
  tail: PAnsiChar;
  level: Integer;
  i: Integer;
  s: string;
begin
  tail := my_strstr(arg, 'repeat');
  if Assigned(tail) then
    //av_log_set_flags(0)
    FFLogger.LogFlags := 0
  else
    //av_log_set_flags(AV_LOG_SKIP_REPEATED);
    FFLogger.LogFlags := AV_LOG_SKIP_REPEATED;
  if tail = arg then
  begin
    Inc(arg, 6);
    if arg[0] = '+' then
      Inc(arg);
  end;
  if Assigned(tail) and (arg^ = #0) then
  begin
    Result := 0;
    Exit;
  end;

  for i := 0 to High(log_levels) do
    if arg = log_levels[i].name then
    begin
      level := log_levels[i].level;
      FFLogger.LogLevel := IntToLogLevel(level); //av_log_set_level(level);
      Result := 0;
      Exit;
    end;
  level := my_strtol(arg, @tail, 10);
  if tail^ <> #0 then
  begin
    s := Format('Invalid loglevel "%s". Possible levels are numbers or:'#13#10, [string(arg)]);
    for i := 0 to High(log_levels) do
      s := s + Format('"%s"'#13#10, [string(log_levels[i].name)]);
    GOptionError := s;
    s := AdjustLineBreaks(s, tlbsLF);
    av_log(nil, AV_LOG_ERROR, PAnsiChar(AnsiString(s)));
    Result := AVERROR_EINVAL;
    Exit;
  end;
  FFLogger.LogLevel := IntToLogLevel(level); //av_log_set_level(level);
  Result := 0;
end;

{
function init_report(const env: PAnsiChar): Integer;
begin
  // TODO: cmdutils.c
  // do nothing now
  Result := 0;
end;

function opt_report(const opt: PAnsiChar): Integer;
begin
  Result := init_report(nil);
end;

function opt_max_alloc(optctx: Pointer; const opt, arg: PAnsiChar): Integer;
begin
  // move to FFmpegOpt.pas
  Result := 0;
end;

function opt_cpuflags(optctx: Pointer; const opt, arg: PAnsiChar): Integer;
begin
  // move to FFmpegOpt.pas
  Result := 0;
end;

function opt_timelimit(optctx: Pointer; const opt, arg: PAnsiChar): Integer;
begin
  Result := 0;
end;

#if CONFIG_OPENCL
function opt_opencl(optctx: Pointer; const opt, arg: PAnsiChar): Integer;
begin
  // TODO: cmdutils.c
  Result := 0;
end;
#endif
}

function print_error(const filename: string; err: Integer): string;
var
  I: Integer;
  S: string;
begin
  S := '';
  for I := 0 to High(CErrorList) do
    if CErrorList[I].err = err then
    begin
      S := CErrorList[I].msg;
      Break;
    end;
  if S = '' then
    S := Format('Error number %d occurred', [err]);
  if filename <> '' then
    Result := filename + ': ' + S
  else
    Result := S;
end;

{
procedure show_banner(argc: Integer; argv: PPAnsiChar; const options: POptionDef);
begin
  // TODO: cmdutils.c
  // do nothing now
end;

function show_version(optctx: Pointer; const opt, arg: PAnsiChar): Integer;
begin
  // TODO: cmdutils.c
  // do nothing now
  Result := 0;
end;

function show_license(optctx: Pointer; const opt, arg: PAnsiChar): Integer;
begin
  // TODO: cmdutils.c
  // do nothing now
  Result := 0;
end;

function show_formats(optctx: Pointer; const opt, arg: PAnsiChar): Integer;
begin
  // TODO: cmdutils.c
  // do nothing now
  Result := 0;
end;

function show_codecs(optctx: Pointer; const opt, arg: PAnsiChar): Integer;
begin
  // TODO: cmdutils.c
  // do nothing now
  Result := 0;
end;

function show_decoders(optctx: Pointer; const opt, arg: PAnsiChar): Integer;
begin
  // TODO: cmdutils.c
  // do nothing now
  Result := 0;
end;

function show_encoders(optctx: Pointer; const opt, arg: PAnsiChar): Integer;
begin
  // TODO: cmdutils.c
  // do nothing now
  Result := 0;
end;

function show_filters(optctx: Pointer; const opt, arg: PAnsiChar): Integer;
begin
  // TODO: cmdutils.c
  // do nothing now
  Result := 0;
end;

function show_bsfs(optctx: Pointer; const opt, arg: PAnsiChar): Integer;
begin
  // TODO: cmdutils.c
  // do nothing now
  Result := 0;
end;

function show_protocols(optctx: Pointer; const opt, arg: PAnsiChar): Integer;
begin
  // TODO: cmdutils.c
  // do nothing now
  Result := 0;
end;

function show_pix_fmts(optctx: Pointer; const opt, arg: PAnsiChar): Integer;
begin
  // TODO: cmdutils.c
  // do nothing now
  Result := 0;
end;

function show_layouts(optctx: Pointer; const opt, arg: PAnsiChar): Integer;
begin
  // TODO: cmdutils.c
  // do nothing now
  Result := 0;
end;

function show_sample_fmts(optctx: Pointer; const opt, arg: PAnsiChar): Integer;
begin
  // TODO: cmdutils.c
  // do nothing now
  Result := 0;
end;
}

function ffutils_read_file(const filename: PAnsiChar; bufptr: PPAnsiChar; size: PCardinal): Integer;
var
  ret: Integer;
  f: Pointer;
begin
  f := my_fopen(filename, 'rb');
  if not Assigned(f) then
  begin
    // Cannot read file
    av_log(nil, AV_LOG_ERROR, 'Cannot read file "%s"'#10, filename{, strerror(errno)});
    Result := -1;
    Exit;
  end;
  my_fseek(f, 0, SEEK_END);
  size^ := my_ftell(f);
  my_fseek(f, 0, SEEK_SET);
  if size^ = Cardinal(-1) then
  begin
    av_log(nil, AV_LOG_ERROR, 'IO error'#10{, strerror(errno)});
    my_fclose(f);
    Result := AVERROR_EIO; // AVERROR(errno);
    Exit;
  end;
  bufptr^ := av_malloc(size^ + 1);
  if not Assigned(bufptr^) then
  begin
    my_fclose(f);
    // Could not allocate file buffer
    av_log(nil, AV_LOG_ERROR, 'Could not allocate file buffer'#10);
    Result := AVERROR_ENOMEM;
    Exit;
  end;
  ret := my_fread(bufptr^, 1, size^, f);
  if ret < Integer(size^) then
  begin
    av_free(bufptr^);
    if my_ferror(f) <> 0 then
    begin
      av_log(nil, AV_LOG_ERROR, 'Error while reading file "%s"'#10, filename{, strerror(errno)});
      ret := AVERROR_EIO; // AVERROR(errno);
    end
    else
      ret := AVERROR_EOF;
  end
  else
  begin
    ret := 0;
    //(*bufptr)[(*size)++] = '\0';
    PtrIdx(bufptr^, size^)^ := #0;
    Inc(size^);
  end;

  my_fclose(f);
  Result := ret;
end;

{
function get_preset_file(filename: PAnsiChar; filename_size: Cardinal;
  const preset_name: PAnsiChar; is_path: Integer; const codec_name: PAnsiChar): PHandle; // FILE *
begin
  // TODO: cmdutils.c
  // do nothing now
  Result := nil;
end;
}

function check_stream_specifier(s: PAVFormatContext; st: PAVStream; const spec: PAnsiChar): Integer;
var
  ret: Integer;
begin
  ret := avformat_match_stream_specifier(s, st, spec);
  //if ret < 0 then
  //  av_log(s, AV_LOG_ERROR, 'Invalid stream specifier: "%s"'#10, spec);
  Result := ret;
end;

function filter_codec_opts(opts: PAVDictionary; codec_id: TAVCodecID;
  s: PAVFormatContext; st: PAVStream; codec: PAVCodec): PAVDictionary;
var
  ret: PAVDictionary;
  t: PAVDictionaryEntry;
  flags: Integer;
  prefix: AnsiChar;
  cc: PAVClass;
  p: PAnsiChar;
begin
  if Assigned(s.oformat) then
    flags := AV_OPT_FLAG_ENCODING_PARAM
  else
    flags := AV_OPT_FLAG_DECODING_PARAM;

  if not Assigned(codec) then
  begin
    if Assigned(s.oformat) then
      codec := avcodec_find_encoder(codec_id)
    else
      codec := avcodec_find_decoder(codec_id);
  end;

  ret := nil;
  prefix := #0;
  cc := avcodec_get_class();

  case st.codec.codec_type of
    AVMEDIA_TYPE_VIDEO:
      begin
        prefix := 'v';
        flags := flags or AV_OPT_FLAG_VIDEO_PARAM;
      end;
    AVMEDIA_TYPE_AUDIO:
      begin
        prefix := 'a';
        flags := flags or AV_OPT_FLAG_AUDIO_PARAM;
      end;
    AVMEDIA_TYPE_SUBTITLE:
      begin
        prefix := 's';
        flags := flags or AV_OPT_FLAG_SUBTITLE_PARAM;
      end;
  end;

  t := av_dict_get(opts, '', nil, AV_DICT_IGNORE_SUFFIX);
  while Assigned(t) do
  begin
    p := my_strchr(t.key, ':');

    (* check stream specification in opt name *)
    if Assigned(p) then
    begin
      case check_stream_specifier(s, st, p + 1) of
        1: p^ := #0;
        0:
          begin
            t := av_dict_get(opts, '', t, AV_DICT_IGNORE_SUFFIX);
            Continue;
          end
      else
        Result := nil;
        Exit;
      end;
    end;

    if Assigned(av_opt_find(@cc, t.key, nil, flags, AV_OPT_SEARCH_FAKE_OBJ)) or
      (Assigned(codec) and Assigned(codec.priv_class) and Assigned(av_opt_find(@codec.priv_class, t.key, nil, flags, AV_OPT_SEARCH_FAKE_OBJ))) then
      av_dict_set(@ret, t.key, t.value, 0)
    else if (t.key[0] = prefix) and Assigned(av_opt_find(@cc, t.key + 1, nil, flags, AV_OPT_SEARCH_FAKE_OBJ)) then
      av_dict_set(@ret, t.key + 1, t.value, 0);

    if Assigned(p) then
      p^ := ':';
    t := av_dict_get(opts, '', t, AV_DICT_IGNORE_SUFFIX);
  end;
  Result := ret;
end;

function setup_find_stream_info_opts(s: PAVFormatContext; codec_opts: PAVDictionary): PPAVDictionary;
var
  i: Integer;
  opts: PPAVDictionary;
begin
  if s.nb_streams = 0 then
  begin
    Result := nil;
    Exit;
  end;
  opts := av_mallocz(s.nb_streams * SizeOf(opts^));
  if not Assigned(opts) then
  begin
    av_log(nil, AV_LOG_ERROR, 'Could not alloc memory for stream options.'#10);
    Result := nil;
    Exit;
  end;
  for i := 0 to Integer(s.nb_streams) - 1 do
    PtrIdx(opts, i)^ := filter_codec_opts(codec_opts, PPtrIdx(s.streams, i)^.codec.codec_id,
                                          s, PPtrIdx(s.streams, i), nil);
  Result := opts;
end;

function grow_array(arr: Pointer; elem_size: Integer; size: PInteger; new_size: Integer): Pointer;
var
  tmp: PByte;
begin
  if new_size >= MaxInt div elem_size then
    raise Exception.Create('Array too big.');
  if size^ < new_size then
  begin
    tmp := av_realloc(arr, new_size * elem_size);
    if not Assigned(tmp) then
      raise Exception.Create('Could not alloc buffer.');
    FillChar(PByte(Integer(tmp) + size^ * elem_size)^, (new_size - size^) * elem_size, 0);
    size^ := new_size;
    Result := tmp;
  end
  else
    Result := arr;
end;

(****** end check from cmdutils.c **************)

{$IF Defined(FPC) Or Defined(FFFMX)}
function BytesPerScanline(PixelsPerScanline, BitsPerPixel, Alignment: Longint): Longint;
begin
  Dec(Alignment);
  Result := ((PixelsPerScanline * BitsPerPixel) + Alignment) and not Alignment;
  Result := Result div 8;
end;
{$IFEND}

{$IFDEF ACTIVEX}
procedure DIBToBitmap(ABitmapPtr: PBitmap; ABitmap: TBitmap);
var
  I: Integer;
  PData: PAnsiChar;
{$IFDEF OPT_SCANLINE}
  PBmp: PAnsiChar;
{$ENDIF}
begin
  case ABitmapPtr.bmBitsPixel of
    8: ABitmap.PixelFormat := pf8bit;
    15: ABitmap.PixelFormat := pf15bit;
    16: ABitmap.PixelFormat := pf16bit;
    24: ABitmap.PixelFormat := pf24bit;
    32: ABitmap.PixelFormat := pf32bit;
  else
    ABitmap.PixelFormat := pf32bit;
  end;
  ABitmap.Width := ABitmapPtr.bmWidth;
  ABitmap.Height := ABitmapPtr.bmHeight;
  PData := PAnsiChar(ABitmapPtr.bmBits);
{$IFDEF OPT_SCANLINE}
  PBmp := PAnsiChar(ABitmap.ScanLine[0]);
{$ENDIF}
  for I := 0 to ABitmapPtr.bmHeight - 1 do
  begin
{$IFDEF OPT_SCANLINE}
    Move(PData^, PBmp^, ABitmapPtr.bmWidthBytes);
    Dec(PBmp, ABitmapPtr.bmWidthBytes);
{$ELSE}
    Move(PData^, PAnsiChar(ABitmap.ScanLine[I])^, ABitmapPtr.bmWidthBytes);
{$ENDIF}
    Inc(PData, ABitmapPtr.bmWidthBytes);
  end;
end;
{$ENDIF}

function isprint(c: Byte): Boolean;
begin
  Result := (c >= $20) and (c <= $7e);
end;

function GetMetaValue(const AMeta: PAVDictionary; const AName: AnsiString; const ADefault: string): string;
var
  tag: PAVDictionaryEntry;
begin
  tag := av_dict_get(AMeta, PAnsiChar(AName), nil, 0);
  if Assigned(tag) then
    Result := string(tag.value)
  else
    Result := ADefault;
end;

function GetCodecName(codec: PAVCodecContext; const AEncode: Boolean): string;
var
  p: PAVCodec;
begin
  if AEncode then
    p := avcodec_find_encoder(codec.codec_id)
  else
    p := avcodec_find_decoder(codec.codec_id);
  if Assigned(p) then
  begin
    Result := string(p.name);
    if Assigned(p.long_name) and (Trim(string(p.long_name)) <> '') then
      Result := Format('%s(%s)', [Result, Trim(string(p.long_name))]);
  end
  else if codec.codec_id = AV_CODEC_ID_MPEG2TS then
    (* fake mpeg2 transport stream codec (currently not
       registered) *)
    Result := 'mpeg2ts'
  else if codec.codec_name[0] <> #0 then
    Result := Trim(string(codec.codec_name))
  else
  begin
    (* output avi tags *)
    if isprint(codec.codec_tag.fourbb[0]) and isprint(codec.codec_tag.fourbb[1]) and
      isprint(codec.codec_tag.fourbb[2]) and isprint(codec.codec_tag.fourbb[3]) then
      Result := Format('%s%s%s%s / 0x%04X',
                 [codec.codec_tag.fourcc[0],
                  codec.codec_tag.fourcc[1],
                  codec.codec_tag.fourcc[2],
                  codec.codec_tag.fourcc[3],
                  codec.codec_tag.tag])
    else
      Result := Format('0x%04x', [codec.codec_tag.tag]);
  end;
end;

function AVMediaTypeCaption(ctype: TAVMediaType): string;
begin
  case ctype of
    AVMEDIA_TYPE_VIDEO: Result := 'Video';
    AVMEDIA_TYPE_AUDIO: Result := 'Audio';
    AVMEDIA_TYPE_DATA: Result := 'Data';
    AVMEDIA_TYPE_SUBTITLE: Result := 'Subtitle';
    AVMEDIA_TYPE_ATTACHMENT: Result := 'Attachment';
  else
    Result := 'Unknown';
  end;
end;

function AVPictureTypeCaption(ctype: TAVPictureType): string;
begin
  case ctype of
    AV_PICTURE_TYPE_I: Result := 'Intra';
    AV_PICTURE_TYPE_P: Result := 'Predicted';
    AV_PICTURE_TYPE_B: Result := 'Bi-dir predicted';
    AV_PICTURE_TYPE_S: Result := 'S(GMC)-VOP MPEG4';
    AV_PICTURE_TYPE_SI: Result := 'Switching Intra';
    AV_PICTURE_TYPE_SP: Result := 'Switching Predicted';
    AV_PICTURE_TYPE_BI: Result := 'BI type';
  else
    Result := 'Unknown';
  end;
end;

function RegisterProtocol(AProtocol: PURLProtocol): Boolean;
var
  P: PURLProtocol;
begin
  Result := Assigned(ffurl_protocol_next) and Assigned(ffurl_register_protocol);
  if Result then
  begin
    P := ffurl_protocol_next(nil);
    while Assigned(P) do
    begin
      if AnsiString(P.name) = AnsiString(AProtocol.name) then
        Exit;
      P := ffurl_protocol_next(P);
    end;
    ffurl_register_protocol(AProtocol, SizeOf(TURLProtocol));
  end;
end;

procedure RegisterInputFormat(AInputFormat: PAVInputFormat);
var
  P: PAVInputFormat;
begin
  Assert(Assigned(av_iformat_next));
  Assert(Assigned(av_register_input_format));
  P := av_iformat_next(nil);
  while Assigned(P) do
  begin
    if AnsiString(P.name) = AnsiString(AInputFormat.name) then
      Exit;
    P := av_iformat_next(P);
  end;
  av_register_input_format(AInputFormat);
end;

procedure RegisterOutputFormat(AOutputFormat: PAVOutputFormat);
var
  P: PAVOutputFormat;
begin
  Assert(Assigned(av_oformat_next));
  Assert(Assigned(av_register_output_format));
  P := av_oformat_next(nil);
  while Assigned(P) do
  begin
    if AnsiString(P.name) = AnsiString(AOutputFormat.name) then
      Exit;
    P := av_oformat_next(P);
  end;
  av_register_output_format(AOutputFormat);
end;

{
procedure RegisterVideoFilter(AFilter: PAVFilter);
var
  P: PPAVFilter;
begin
  Assert(Assigned(av_filter_next));
  Assert(Assigned(avfilter_register));
  P := av_filter_next(nil);
  while Assigned(P^) do
  begin
    if AnsiString(P^.name) = AnsiString(AFilter.name) then
      Exit;
    P := av_filter_next(P);
  end;
  avfilter_register(AFilter);
end;
}

(* This table is used to add two sound values together and pin
 * the value to avoid overflow.  (used with permission from ARDI)
 * Changed to use 0xFE instead of 0xFF for better sound quality.
 *)
const
  mix8: array[0..511] of Byte = (
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $01, $02, $03,
    $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E,
    $0F, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19,
    $1A, $1B, $1C, $1D, $1E, $1F, $20, $21, $22, $23, $24,
    $25, $26, $27, $28, $29, $2A, $2B, $2C, $2D, $2E, $2F,
    $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3A,
    $3B, $3C, $3D, $3E, $3F, $40, $41, $42, $43, $44, $45,
    $46, $47, $48, $49, $4A, $4B, $4C, $4D, $4E, $4F, $50,
    $51, $52, $53, $54, $55, $56, $57, $58, $59, $5A, $5B,
    $5C, $5D, $5E, $5F, $60, $61, $62, $63, $64, $65, $66,
    $67, $68, $69, $6A, $6B, $6C, $6D, $6E, $6F, $70, $71,
    $72, $73, $74, $75, $76, $77, $78, $79, $7A, $7B, $7C,
    $7D, $7E, $7F, $80, $81, $82, $83, $84, $85, $86, $87,
    $88, $89, $8A, $8B, $8C, $8D, $8E, $8F, $90, $91, $92,
    $93, $94, $95, $96, $97, $98, $99, $9A, $9B, $9C, $9D,
    $9E, $9F, $A0, $A1, $A2, $A3, $A4, $A5, $A6, $A7, $A8,
    $A9, $AA, $AB, $AC, $AD, $AE, $AF, $B0, $B1, $B2, $B3,
    $B4, $B5, $B6, $B7, $B8, $B9, $BA, $BB, $BC, $BD, $BE,
    $BF, $C0, $C1, $C2, $C3, $C4, $C5, $C6, $C7, $C8, $C9,
    $CA, $CB, $CC, $CD, $CE, $CF, $D0, $D1, $D2, $D3, $D4,
    $D5, $D6, $D7, $D8, $D9, $DA, $DB, $DC, $DD, $DE, $DF,
    $E0, $E1, $E2, $E3, $E4, $E5, $E6, $E7, $E8, $E9, $EA,
    $EB, $EC, $ED, $EE, $EF, $F0, $F1, $F2, $F3, $F4, $F5,
    $F6, $F7, $F8, $F9, $FA, $FB, $FC, $FD, $FE, $FE, $FE,
    $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE,
    $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE,
    $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE,
    $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE,
    $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE,
    $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE,
    $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE,
    $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE,
    $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE,
    $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE,
    $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE,
    $FE, $FE, $FE, $FE, $FE, $FE
  );

procedure MixAudioU8(const Source; var Dest; Count: Integer; Volume: TAudioVolume);
var
  PSource: PByte;
  PDest: PByte;
  LCount: Integer;
begin
  if Volume = 0 then
    Exit;

  PSource := PByte(@Source);
  PDest := PByte(@Dest);
  LCount := Count;
  if Volume = MIX_MAXVOLUME then
  begin
    while LCount > 0 do
    begin
      PDest^ := mix8[PDest^ + PSource^];
      Inc(PSource);
      Inc(PDest);
      Dec(LCount);
    end;
  end
  else
  begin
    while LCount > 0 do
    begin
      PDest^ := mix8[PDest^ + (Word(PSource^) - 128) * Volume div MIX_MAXVOLUME + 128];
      Inc(PSource);
      Inc(PDest);
      Dec(LCount);
    end;
  end;
end;

procedure MixAudioS16(const Source; var Dest; Count: Integer; Volume: TAudioVolume);
const
  CMaxAudioValue =  (Integer(1) shl (16 - 1)) - 1;  //  32767 -> $00007FFF
  CMinAudioValue = -(Integer(1) shl (16 - 1));      // -32768 -> $8000FFFF
var
  PSource: PSmallInt;
  PDest: PSmallInt;
  LCount: Integer;
  LDestSample: Integer;
begin
  if Volume = 0 then
    Exit;

  PSource := PSmallInt(@Source);
  PDest := PSmallInt(@Dest);
  LCount := Count div 2;
  if Volume = MIX_MAXVOLUME then
  begin
    while LCount > 0 do
    begin
      // Source + Dest -> DestSample
      LDestSample := Integer(PSource^) + PDest^;
      // overflow clipping
      if LDestSample > CMaxAudioValue then
        LDestSample := CMaxAudioValue
      else if LDestSample < CMinAudioValue then
        LDestSample := CMinAudioValue;
      // DestSample to Dest
      PDest^ := LDestSample and $FFFF;

      Inc(PSource);
      Inc(PDest);
      Dec(LCount);
    end;
  end
  else
  begin
    while LCount > 0 do
    begin
      // Source (volume adjusted) + Dest -> DestSample
      LDestSample := Integer(PSource^) * Volume div MIX_MAXVOLUME + PDest^;
      // overflow clipping
      if LDestSample > CMaxAudioValue then
        LDestSample := CMaxAudioValue
      else if LDestSample < CMinAudioValue then
        LDestSample := CMinAudioValue;
      // DestSample to Dest
      PDest^ := LDestSample and $FFFF;

      Inc(PSource);
      Inc(PDest);
      Dec(LCount);
    end;
  end;
end;

procedure MixAudioS32(const Source; var Dest; Count: Integer; Volume: TAudioVolume);
const
  CMaxAudioValue =  (Int64(1) shl (32 - 1)) - 1;  //  2,147,483,647 -> $000000007FFFFFFF
  CMinAudioValue = -(Int64(1) shl (32 - 1));      // -2,147,483,648 -> $80000000FFFFFFFF
var
  PSource: PInteger;
  PDest: PInteger;
  LCount: Integer;
  LDestSample: Int64;
begin
  if Volume = 0 then
    Exit;

  PSource := PInteger(@Source);
  PDest := PInteger(@Dest);
  LCount := Count div 4;
  if Volume = MIX_MAXVOLUME then
  begin
    while LCount > 0 do
    begin
      // Source + Dest -> DestSample
      LDestSample := Int64(PSource^) + PDest^;
      // overflow clipping
      if LDestSample > CMaxAudioValue then
        LDestSample := CMaxAudioValue
      else if LDestSample < CMinAudioValue then
        LDestSample := CMinAudioValue;
      // DestSample to Dest
      PDest^ := LDestSample and $FFFFFFFF;

      Inc(PSource);
      Inc(PDest);
      Dec(LCount);
    end;
  end
  else
  begin
    while LCount > 0 do
    begin
      // Source (volume adjusted) + Dest -> DestSample
      LDestSample := Int64(PSource^) * Volume div MIX_MAXVOLUME + PDest^;
      // overflow clipping
      if LDestSample > CMaxAudioValue then
        LDestSample := CMaxAudioValue
      else if LDestSample < CMinAudioValue then
        LDestSample := CMinAudioValue;
      // DestSample to Dest
      PDest^ := LDestSample and $FFFFFFFF;

      Inc(PSource);
      Inc(PDest);
      Dec(LCount);
    end;
  end;
end;

{ TFormatConverter }

constructor TFormatConverter.Create;
begin
{$IFNDEF FFFMX}
  FBMPPixFmt := pf32bit;
  FBitmap := TBitmap.Create;
  FBitmap.Canvas.Brush.Style := bsClear;  // transparent background
{$ELSE}
  FBitmap := TBitmap.Create(0, 0);
{$ENDIF}
{$IFDEF FPC}
  FIntfImg := TLazIntfImage.Create(0, 0);
{$ENDIF}
  ResetFormat;
  Fsws_flags := SWS_BICUBIC;
end;

destructor TFormatConverter.Destroy;
begin
  if Assigned(FBitmap) then
    FreeAndNil(FBitmap);
{$IFDEF FPC}
  if Assigned(FIntfImg) then
    FreeAndNil(FIntfImg);
{$ENDIF}
  if Assigned(FRGBBuffer) then
  begin
    if Assigned(av_free) then
      av_free(FRGBBuffer);                    // XXX memory leak if LibAV have been unloaded
    FRGBBuffer := nil;
  end;
  if Assigned(FtoRGB_convert_ctx) then
  begin
    if Assigned(sws_freeContext) then
      sws_freeContext(FtoRGB_convert_ctx);    // XXX memory leak if LibAV have been unloaded
    FtoRGB_convert_ctx := nil;
  end;
  if Assigned(FfromRGB_convert_ctx) then
  begin
    if Assigned(sws_freeContext) then
      sws_freeContext(FfromRGB_convert_ctx);  // XXX memory leak if LibAV have been unloaded
    FfromRGB_convert_ctx := nil;
  end;
  inherited Destroy;
end;

procedure TFormatConverter.ResetFormat;
{$IFNDEF FFFMX}
const
  CBitsPixel: array[TBMPPixelFormat] of Integer = ({$IFNDEF FPC}8, 16{15???}, 16,{$ENDIF}24, 32);
  CAVPixFmt: array[TBMPPixelFormat] of TAVPixelFormat = (
                      {$IFNDEF FPC}AV_PIX_FMT_BGR8, AV_PIX_FMT_BGR555LE, AV_PIX_FMT_BGR565LE,{$ENDIF}
                      AV_PIX_FMT_BGR24, AV_PIX_FMT_BGRA);
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  FillChar(FDIB, SizeOf(tagBITMAP), 0);
{$ENDIF}
  FillChar(FRGBPicture, SizeOf(TAVPicture), 0);
  FRGBPictureRef := nil;

{$IFDEF FFFMX}
  FBitsPixel := 32;
  {$IFDEF MSWINDOWS}
    FAVPixFmt := AV_PIX_FMT_BGRA;
  {$ELSE}
    FAVPixFmt := AV_PIX_FMT_RGBA;
  {$ENDIF}
{$ELSE}
  FBitsPixel := CBitsPixel[FBMPPixFmt];
  FAVPixFmt := CAVPixFmt[FBMPPixFmt];

  FBitmap.PixelFormat := FBMPPixFmt;
{$IFDEF FPC}
  if FBitmap.PixelFormat = pf24bit then
    FIntfImg.DataDescription.Init_BPP24_B8G8R8_BIO_TTB(FBitmap.Width, FBitmap.Height)
  else
  begin
    Assert(FBitmap.PixelFormat = pf32bit);
    FIntfImg.DataDescription.Init_BPP32_B8G8R8A8_BIO_TTB(FBitmap.Width, FBitmap.Height);
  end;
{$ENDIF}
{$ENDIF}
end;

{$IFDEF MSWINDOWS}
function TFormatConverter.GetDIB: PBitmap;
begin
  Result := @FDIB;
end;
{$ENDIF}

function TFormatConverter.GetRGBPicture: PAVPicture;
begin
  Result := @FRGBPicture;
end;

{$IFNDEF FFFMX}
procedure TFormatConverter.SetBitsPixel(const Value: Integer);
begin
  if FBitsPixel <> Value then
  begin
    case Value of
{$IFNDEF FPC}
      8:  FBMPPixFmt := pf8bit;
      15: FBMPPixFmt := pf15bit;
      16: FBMPPixFmt := pf16bit;
{$ENDIF}
      24: FBMPPixFmt := pf24bit;
      32: FBMPPixFmt := pf32bit;
    else
      raise Exception.CreateFmt('Invalid BitsPixel %d', [Value]);
    end;
    ResetFormat;
  end;
end;

procedure TFormatConverter.SetBMPPixFmt(const Value: TBMPPixelFormat);
begin
  if FBMPPixFmt <> Value then
  begin
    case Value of
{$IFNDEF FPC}
      pf8bit, pf15bit, pf16bit,
{$ENDIF}
      pf24bit, pf32bit: FBMPPixFmt := Value;
    else
      raise Exception.CreateFmt('Invalid PixelFormat %d', [Ord(Value)]);
    end;
    ResetFormat;
  end;
end;
{$ENDIF}

function TFormatConverter.PictureToRGB(picture: PAVPicture;
  pix_fmt: TAVPixelFormat; width, height: Integer; ARGBToBitmap: Boolean): Boolean;
var
  LBufSize: Integer;
begin
{$IFDEF VCL_10_OR_ABOVE}
  FBitmap.SetSize(width, height);
{$ELSE}
  FBitmap.Width := width;
  FBitmap.Height := height;
{$ENDIF}

  // need to convert
  if (pix_fmt <> FAVPixFmt) or
    (width mod 2 <> 0) or (height mod 2 <> 0) or
    (picture.linesize[0] <> BytesPerScanline(width, FBitsPixel, 32)) then
  begin
    // malloc RGB buffer
    LBufSize := avpicture_get_size(FAVPixFmt, width, height);
    if not Assigned(FRGBBuffer) then
    begin
      FRGBBuffer := av_malloc(LBufSize);
      FRGBBufSize := LBufSize;
    end
    else if LBufSize > FRGBBufSize then
    begin
      av_free(FRGBBuffer);
      FRGBBuffer := av_malloc(LBufSize);
      FRGBBufSize := LBufSize;
    end;
    // assign buffer to picture
    avpicture_fill(@FRGBPicture, FRGBBuffer, FAVPixFmt, width, height);

    // transfer source picture to RGB format
    // if we already got a SWS context, let's realloc if is not re-useable
    FtoRGB_convert_ctx := sws_getCachedContext(
                    FtoRGB_convert_ctx,
                    width, height, Ord(pix_fmt),
                    width, height, Ord(FAVPixFmt),
                    Fsws_flags, nil, nil, nil);
    if not Assigned(FtoRGB_convert_ctx) then
    begin
      Result := False;
      FRGBPictureRef := nil;
      FLastErrMsg := 'Cannot initialize the toRGB conversion context';
      Exit;
    end
    else
    begin
      sws_scale(FtoRGB_convert_ctx,
          @(picture.data[0]), @(picture.linesize[0]), 0, height,
          @(FRGBPicture.data[0]), @(FRGBPicture.linesize[0]));
      FRGBPictureRef := @FRGBPicture;
    end;
  end
  else
    FRGBPictureRef := picture;

{$IFDEF MSWINDOWS}
  // generate tagBITMAP
  with FDIB do
  begin
    bmType := 0;
    bmWidth := width;
    bmHeight := height;
    bmWidthBytes := FRGBPictureRef.linesize[0]; // BytesPerScanline(width, FBitsPixel, 32);
    bmPlanes := 1;
    bmBitsPixel := FBitsPixel;
    bmBits := FRGBPictureRef.data[0];
  end;
{$ENDIF}

  if ARGBToBitmap then
    // copy RGB picture to bitmap
    RGBToBitmap;

  Result := True;
end;

{$IF Defined(FFFMX) And Defined(VCL_XE3_OR_ABOVE) And Not Defined(OPT_SCANLINE)}
  BOMB: new firemonkey requires OPT_SCANLINE
{$IFEND}

procedure TFormatConverter.RGBToBitmap;
var
  I: Integer;
  PData: PAnsiChar;
{$IF Defined(FFFMX) And Defined(VCL_XE3_OR_ABOVE)}
  D: TBitmapData;
{$IFEND}
{$IFDEF OPT_SCANLINE}
  PBmp: PAnsiChar;
{$ENDIF}
begin
  Assert(Assigned(FRGBPictureRef));
  PData := PAnsiChar(FRGBPictureRef.data[0]);
{$IFDEF FPC}
  if (FIntfImg.Width <> FBitmap.Width) or (FIntfImg.Height <> FBitmap.Height) then
    FIntfImg.SetSize(FBitmap.Width, FBitmap.Height);
{$ENDIF}
{$IFDEF OPT_SCANLINE}
  {$IFDEF FPC}
    PBmp := PAnsiChar(FIntfImg.PixelData);
  {$ELSE}
    {$IF Defined(FFFMX) And Defined(VCL_XE3_OR_ABOVE)}
      if FBitmap.Map(TMapAccess.maWrite, D) then
      begin
        try
          PBmp := PAnsiChar(D.Data);
    {$ELSE}
      PBmp := PAnsiChar(FBitmap.ScanLine[0]);
    {$IFEND}
  {$ENDIF}
{$ENDIF}
  for I := 0 to FBitmap.Height - 1 do
  begin
{$IFDEF OPT_SCANLINE}
    Move(PData^, PBmp^, FRGBPictureRef.linesize[0]);
  {$IF Defined(FPC) or Defined(FFFMX)}
    Inc(PBmp, FRGBPictureRef.linesize[0]);
  {$ELSE}
    Dec(PBmp, FRGBPictureRef.linesize[0]);
  {$IFEND}
{$ELSE}
  {$IFDEF FPC}
    Move(PData^, PAnsiChar(FIntfImg.GetDataLineStart(I))^, FRGBPictureRef.linesize[0]);
  {$ELSE}
    Move(PData^, PAnsiChar(FBitmap.ScanLine[I])^, FRGBPictureRef.linesize[0]);
  {$ENDIF}
{$ENDIF}
    Inc(PData, FRGBPictureRef.linesize[0]);
  end;
{$IFDEF FPC}
  FBitmap.LoadFromIntfImage(FIntfImg);
{$ENDIF}
{$IFDEF FFFMX}
  {$IFDEF VCL_XE3_OR_ABOVE}
      finally
        FBitmap.Unmap(D);
      end;
    end
    else
      FFLogger.Log(nil, llError, 'RGBToBitmap() failed. Could not Map Bitmap.');
  {$ELSE}
    FBitmap.UpdateHandles;
  {$ENDIF}
{$ENDIF}
end;

procedure TFormatConverter.BitmapToRGB;
var
  I: Integer;
  PData: PAnsiChar;
{$IF Defined(FFFMX) And Defined(VCL_XE3_OR_ABOVE)}
  S: TBitmapData;
{$IFEND}
{$IFDEF OPT_SCANLINE}
  PBmp: PAnsiChar;
{$ENDIF}
begin
  Assert(Assigned(FRGBPictureRef));
  PData := PAnsiChar(FRGBPictureRef.data[0]);
{$IFDEF FPC}
  FIntfImg.LoadFromBitmap(FBitmap.Handle, FBitmap.MaskHandle);
{$ENDIF}
{$IFDEF OPT_SCANLINE}
  {$IFDEF FPC}
  PBmp := PAnsiChar(FIntfImg.PixelData);
  {$ELSE}
    {$IF Defined(FFFMX) And Defined(VCL_XE3_OR_ABOVE)}
      if FBitmap.Map(TMapAccess.maRead, S) then
      begin
        try
          PBmp := PAnsiChar(S.Data);
    {$ELSE}
      PBmp := PAnsiChar(FBitmap.ScanLine[0]);
    {$IFEND}
  {$ENDIF}
{$ENDIF}
  for I := 0 to FBitmap.Height - 1 do
  begin
{$IFDEF OPT_SCANLINE}
    Move(PBmp^, PData^, FRGBPictureRef.linesize[0]);
  {$IF Defined(FPC) Or Defined(FFFMX)}
    Inc(PBmp, FRGBPictureRef.linesize[0]);
  {$ELSE}
    Dec(PBmp, FRGBPictureRef.linesize[0]);
  {$IFEND}
{$ELSE}
  {$IFDEF FPC}
    Move(PAnsiChar(FIntfImg.GetDataLineStart(I))^, PData^, FRGBPictureRef.linesize[0]);
  {$ELSE}
    Move(PAnsiChar(FBitmap.ScanLine[I])^, PData^, FRGBPictureRef.linesize[0]);
  {$ENDIF}
{$ENDIF}
    Inc(PData, FRGBPictureRef.linesize[0]);
  end;
{$IF Defined(FFFMX) And Defined(VCL_XE3_OR_ABOVE)}
    finally
      FBitmap.Unmap(S);
    end;
  end
  else
    FFLogger.Log(nil, llError, 'BitmapToRGB() failed. Could not Map Bitmap.');
{$IFEND}
end;

function TFormatConverter.RGBToPicture(picture: PAVPicture;
  pix_fmt: TAVPixelFormat; width, height: Integer): Boolean;
begin
  Assert(Assigned(FRGBPictureRef));
  FfromRGB_convert_ctx := sws_getCachedContext(
                FfromRGB_convert_ctx,
                width, height, Ord(FAVPixFmt),
                width, height, Ord(pix_fmt),
                Fsws_flags, nil, nil, nil);
  if not Assigned(FfromRGB_convert_ctx) then
  begin
    FLastErrMsg := 'Cannot initialize the fromRGB conversion context';
    Result := False;
  end
  else
  begin
    sws_scale(FfromRGB_convert_ctx,
        @(FRGBPictureRef.data[0]), @(FRGBPictureRef.linesize[0]), 0, height,
        @(picture.data[0]), @(picture.linesize[0]));
    Result := True;
  end;
end;

end.
