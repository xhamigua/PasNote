(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * This file is a unit of avutil library api stubs.
 * Created by CodeCoolie@CNSW 2008/03/20 -> $Date:: 2013-11-18 #$
 *)

unit AVUtilStubs;

interface

{$I CompilerDefines.inc}

{ $DEFINE DEBUG_MALLOC}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  System.SysUtils,
  System.Math,
{$ELSE}
  SysUtils,
  Math,
{$ENDIF}
  MyUtils,
  libavutil,
  libavutil_avstring,
  libavutil_buffer,
  libavutil_channel_layout,
  libavutil_common,
  libavutil_cpu,
  libavutil_dict,
  libavutil_error,
  libavutil_fifo,
  libavutil_frame,
  libavutil_imgutils,
  libavutil_log,
  libavutil_mathematics,
  libavutil_mem,
  libavutil_opt,
  libavutil_parseutils,
  libavutil_pixdesc,
  libavutil_pixfmt,
  libavutil_rational,
  libavutil_samplefmt;

{$I libversion.inc}

var
  av_asprintf             : Tav_asprintfProc              = nil;
  av_bprint_finalize      : Tav_bprint_finalizeProc       = nil;
  av_bprint_init          : Tav_bprint_initProc           = nil;
  av_bprintf              : Tav_bprintfProc               = nil;
  av_buffer_create        : Tav_buffer_createProc         = nil;
  av_buffer_default_free  : Tav_buffer_default_freeProc   = nil;
  av_compare_ts           : Tav_compare_tsProc            = nil;
  av_default_item_name    : Tav_default_item_nameProc     = nil;
  av_dict_copy            : Tav_dict_copyProc             = nil;
  av_dict_count           : Tav_dict_countProc            = nil;
  av_dict_free            : Tav_dict_freeProc             = nil;
  av_dict_get             : Tav_dict_getProc              = nil;
  av_dict_set             : Tav_dict_setProc              = nil;
  av_expr_eval            : Tav_expr_evalProc             = nil;
  av_expr_free            : Tav_expr_freeProc             = nil;
  av_expr_parse           : Tav_expr_parseProc            = nil;
  av_fifo_alloc           : Tav_fifo_allocProc            = nil;
  av_fifo_free            : Tav_fifo_freeProc             = nil;
  av_fifo_generic_read    : Tav_fifo_generic_readProc     = nil;
  av_fifo_generic_write   : Tav_fifo_generic_writeProc    = nil;
  av_fifo_size            : Tav_fifo_sizeProc             = nil;
  av_find_nearest_q_idx   : Tav_find_nearest_q_idxProc    = nil;
  av_force_cpu_flags      : Tav_force_cpu_flagsProc       = nil;
  av_frame_alloc          : Tav_frame_allocProc           = nil;
//vf_*  av_frame_copy_props     : Tav_frame_copy_propsProc      = nil;
  av_frame_free           : Tav_frame_freeProc            = nil;
  av_frame_get_best_effort_timestamp: Tav_frame_get_best_effort_timestampProc = nil;
  av_frame_get_buffer     : Tav_frame_get_bufferProc      = nil;
  av_frame_get_channels   : Tav_frame_get_channelsProc    = nil;
  av_frame_get_pkt_pos    : Tav_frame_get_pkt_posProc     = nil;
//vf_*  av_frame_is_writable    : Tav_frame_is_writableProc     = nil;
  av_frame_ref            : Tav_frame_refProc             = nil;
  av_frame_unref          : Tav_frame_unrefProc           = nil;
  av_free                 : Tav_freeProc                  = nil;
  av_freep                : Tav_freepProc                 = nil;
  av_gcd                  : Tav_gcdProc                   = nil;
  av_get_bytes_per_sample : Tav_get_bytes_per_sampleProc  = nil;
  av_get_channel_layout   : Tav_get_channel_layoutProc    = nil;
  av_get_channel_layout_nb_channels: Tav_get_channel_layout_nb_channelsProc = nil;
  av_get_channel_layout_string: Tav_get_channel_layout_stringProc = nil;
  av_get_cpu_flags        : Tav_get_cpu_flagsProc         = nil;
  av_get_default_channel_layout: Tav_get_default_channel_layoutProc = nil;
  av_get_int              : Tav_get_intProc               = nil;
  av_get_media_type_string: Tav_get_media_type_stringProc = nil;
  av_get_packed_sample_fmt: Tav_get_packed_sample_fmtProc = nil;
  av_get_picture_type_char: Tav_get_picture_type_charProc = nil;
  av_get_pix_fmt          : Tav_get_pix_fmtProc           = nil;
  av_get_pix_fmt_name     : Tav_get_pix_fmt_nameProc      = nil;
  av_get_sample_fmt       : Tav_get_sample_fmtProc        = nil;
  av_get_sample_fmt_name  : Tav_get_sample_fmt_nameProc   = nil;
  av_get_sample_fmt_string: Tav_get_sample_fmt_stringProc = nil;
  av_get_token            : Tav_get_tokenProc             = nil;
  av_gettime              : Tav_gettimeProc               = nil;
  av_image_check_size     : Tav_image_check_sizeProc      = nil;
  av_image_copy           : Tav_image_copyProc            = nil;
  av_image_copy_plane     : Tav_image_copy_planeProc      = nil;
  av_image_get_linesize   : Tav_image_get_linesizeProc    = nil;
  av_int_list_length_for_size: Tav_int_list_length_for_sizeProc = nil;
  av_log                  : Tav_logProc                   = nil;
  av_log_default_callback : Tav_log_default_callbackProc  = nil;
  av_log_get_level        : Tav_log_get_levelProc         = nil;
  av_log_set_callback     : Tav_log_set_callbackProc      = nil;
  av_log_set_flags        : Tav_log_set_flagsProc         = nil;
  av_log_set_level        : Tav_log_set_levelProc         = nil;
  av_malloc               : Tav_mallocProc                = nil;
  av_mallocz              : Tav_malloczProc               = nil;
  av_max_alloc            : Tav_max_allocProc             = nil;
  av_opt_find             : Tav_opt_findProc              = nil;
  av_opt_free             : Tav_opt_freeProc              = nil;
  av_opt_get_double       : Tav_opt_get_doubleProc        = nil;
  av_opt_get_int          : Tav_opt_get_intProc           = nil;
  av_opt_ptr              : Tav_opt_ptrProc               = nil;
  av_opt_set              : Tav_opt_setProc               = nil;
  av_opt_set_bin          : Tav_opt_set_binProc           = nil;
  av_opt_set_defaults     : Tav_opt_set_defaultsProc      = nil;
  av_opt_set_dict         : Tav_opt_set_dictProc          = nil;
  av_opt_set_double       : Tav_opt_set_doubleProc        = nil;
  av_opt_set_int          : Tav_opt_set_intProc           = nil;
  av_parse_cpu_caps       : Tav_parse_cpu_capsProc        = nil;
  av_parse_ratio          : Tav_parse_ratioProc           = nil;
  av_parse_time           : Tav_parse_timeProc            = nil;
  av_parse_video_rate     : Tav_parse_video_rateProc      = nil;
  av_parse_video_size     : Tav_parse_video_sizeProc      = nil;
  av_pix_fmt_desc_get     : Tav_pix_fmt_desc_getProc      = nil;
  av_pix_fmt_get_chroma_sub_sample: Tav_pix_fmt_get_chroma_sub_sampleProc = nil;
  av_realloc              : Tav_reallocProc               = nil;
  av_realloc_f            : Tav_realloc_fProc             = nil;
  av_reduce               : Tav_reduceProc                = nil;
  av_rescale              : Tav_rescaleProc               = nil;
  av_rescale_delta        : Tav_rescale_deltaProc         = nil;
  av_rescale_q            : Tav_rescale_qProc             = nil;
  av_samples_get_buffer_size: Tav_samples_get_buffer_sizeProc = nil;
  av_set_string3          : Tav_set_string3Proc           = nil;
  av_strcasecmp           : Tav_strcasecmpProc            = nil;
  av_strdup               : Tav_strdupProc                = nil;
  av_strlcat              : Tav_strlcatProc               = nil;
  av_strlcatf             : Tav_strlcatfProc              = nil;
  av_strlcpy              : Tav_strlcpyProc               = nil;
  av_strstart             : Tav_strstartProc              = nil;
  av_usleep               : Tav_usleepProc                = nil;

(****** TODO: check from libavutil/avutil.h **************)
(**
 * Return x default pointer in case p is NULL.
 *)
function av_x_if_null(const p, x: PAnsiChar): string; {$IFDEF USE_INLINE}inline;{$ENDIF}

(****** TODO: check from libavutil/bprint.h **************)
(**
 * Test if the print buffer is complete (not truncated).
 *
 * It may have been truncated due to a memory allocation failure
 * or the size_max limit (compare size and size_max if necessary).
 *)
function av_bprint_is_complete(buf: PAVBPrint): Integer; {$IFDEF USE_INLINE}inline;{$ENDIF}

(****** TODO: check from libavutil/rational.h **************)
(**
 * Multiply two rationals.
 * @param b first rational
 * @param c second rational
 * @return b*c
 *)
function av_mul_q(b, c: TAVRational): TAVRational; {$IFDEF USE_INLINE}inline;{$ENDIF}
(**
 * Divide one rational by another.
 * @param b first rational
 * @param c second rational
 * @return b/c
 *)
function av_div_q(b, c: TAVRational): TAVRational; {$IFDEF USE_INLINE}inline;{$ENDIF}
(**
 * Add two rationals.
 * @param b first rational
 * @param c second rational
 * @return b+c
 *)
function av_add_q(b, c: TAVRational): TAVRational; {$IFDEF USE_INLINE}inline;{$ENDIF}
(**
 * Subtract one rational from another.
 * @param b first rational
 * @param c second rational
 * @return b-c
 *)
function av_sub_q(b, c: TAVRational): TAVRational; {$IFDEF USE_INLINE}inline;{$ENDIF}
(**
 * Invert a rational.
 * @param q value
 * @return 1 / q
 *)
function av_inv_q(q: TAVRational): TAVRational; {$IFDEF USE_INLINE}inline;{$ENDIF}
(**
 * Convert a double precision floating point number to a rational.
 * inf is expressed as {1,0} or {-1,0} depending on the sign.
 *
 * @param d double to convert
 * @param max the maximum allowed numerator and denominator
 * @return (AVRational) d
 *)
function av_d2q(d: Double; max: Integer): TAVRational; {$IFDEF USE_INLINE}inline;{$ENDIF}


(****** TODO: check from libavutil/timestamp.h **************)
//const
//  AV_TS_MAX_STRING_SIZE = 32;

(**
 * Fill the provided buffer with a string containing a timestamp
 * representation.
 *
 * @param buf a buffer with size in bytes of at least AV_TS_MAX_STRING_SIZE
 * @param ts the timestamp to represent
 * @return the buffer in input
 *)
function av_ts_make_string(ts: Int64): string;

(**
 * Convenience macro, the return value should be used only directly in
 * function arguments but never stand-alone.
 *)
function av_ts2str(ts: Int64): string;

(**
 * Fill the provided buffer with a string containing a timestamp time
 * representation.
 *
 * @param buf a buffer with size in bytes of at least AV_TS_MAX_STRING_SIZE
 * @param ts the timestamp to represent
 * @param tb the timebase of the timestamp
 * @return the buffer in input
 *)
function av_ts_make_time_string(ts: Int64; tb: PAVRational): string;

(**
 * Convenience macro, the return value should be used only directly in
 * function arguments but never stand-alone.
 *)
function av_ts2timestr(ts: Int64; tb: PAVRational): string;

(****** TODO: check from libavutil/avutil.h **************)
(**
 * Compute the length of an integer list.
 *
 * @param term  list terminator (usually 0 or -1)
 * @param list  pointer to the list
 * @return  length of the list, in elements, not counting the terminator
 *)
function av_int_list_length(list: Pointer; item_size: Integer; term: Int64): Integer;

(****** TODO: check from libavutil/opt.h **************)
(**
 * Set a binary option to an integer list.
 *
 * @param obj    AVClass object to set options on
 * @param name   name of the binary option
 * @param val    pointer to an integer list (must have the correct type with
 *               regard to the contents of the list)
 * @param term   list terminator (usually 0 or -1)
 * @param flags  search flags
 *)
function av_opt_set_int_list(obj: Pointer; name: PAnsiChar; list: Pointer; item_size: Integer; term: Int64; flags: Integer): Integer;

(****** TODO: check from libavutil/common.h **************)
(* assume a>0 and b>0 *)
function FF_CEIL_RSHIFT(a, b: Integer): Integer;

procedure AVUtilFixupStubs(const ALibFile: TPathFileName; const AHandle: THandle);
procedure AVUtilUnfixStubs;

{$IFDEF DEBUG_MALLOC}
procedure init_mem_debuger;
procedure uninit_mem_debuger;
{$ENDIF}

implementation

{$IFDEF DEBUG_MALLOC}
uses
{$IFDEF VCL_XE2_OR_ABOVE}
  System.Classes,
{$ELSE}
  Classes,
{$ENDIF}
  NGSDebuger;
{$ENDIF}

(****** TODO: check from libavutil/avutil.h **************)
function av_x_if_null(const p, x: PAnsiChar): string;
begin
  if Assigned(p) then
    Result := string(p)
  else
    Result := string(x);
end;

(****** TODO: check from libavutil/bprint.h **************)
function av_bprint_is_complete(buf: PAVBPrint): Integer;
begin
  Result := Ord(buf.len < buf.size);
end;

(****** TODO: check from libavutil/rational.c **************)
function av_mul_q(b, c: TAVRational): TAVRational;
begin
  av_reduce(@Result.num, @Result.den,
            b.num * Int64(c.num),
            b.den * Int64(c.den), MaxInt);
end;

function av_div_q(b, c: TAVRational): TAVRational;
begin
  // return av_mul_q(b, (AVRational) { c.den, c.num });
  av_reduce(@Result.num, @Result.den,
            b.num * Int64(c.den),
            b.den * Int64(c.num), MaxInt);
end;

function av_add_q(b, c: TAVRational): TAVRational;
begin
  av_reduce(@Result.num, @Result.den,
            b.num * Int64(c.den) +
            c.num * Int64(b.den),
            b.den * Int64(c.den), MaxInt);
end;

function av_sub_q(b, c: TAVRational): TAVRational;
begin
  // return av_add_q(b, (AVRational) { -c.num, c.den });
  av_reduce(@Result.num, @Result.den,
            b.num * Int64(c.den) -
            c.num * Int64(b.den),
            b.den * Int64(c.den), MaxInt);
end;

function av_inv_q(q: TAVRational): TAVRational;
begin
  Result.num := q.den;
  Result.den := q.num;
end;

function av_d2q(d: Double; max: Integer): TAVRational;
var
  exponent: Integer;
  den: Int64;
begin
  if IsNaN(d) then
  begin
    Result.num := 0;
    Result.den := 0;
    Exit;
  end;
  //if IsInfinite(d) then
  if Abs(d) > Int64(MaxInt) + Int64(3) then
  begin
    if d < 0 then
      Result.num := -1
    else
      Result.num := 1;
    Result.den := 0;
    Exit;
  end;
  exponent := Round(Log10(Abs(d) + 1e-20) / 0.69314718055994530941723212145817656807550013436025);
  if exponent < 0 then
    exponent := 0;
  den := 1 shl (61 - exponent);
  // (int64_t)rint() and llrint() do not work with gcc on ia64 and sparc64
  av_reduce(@Result.num, @Result.den, Floor(d * den + 0.5), den, max);
  if ((Result.num = 0) or (Result.den = 0)) and (d <> 0) and (max > 0) and (max < MaxInt) then
    av_reduce(@Result.num, @Result.den, Floor(d * den + 0.5), den, MaxInt);
end;

function av_ts_make_string(ts: Int64): string;
begin
  if ts = AV_NOPTS_VALUE then
    Result := 'NOPTS'
  else
    Result := IntToStr(ts);
end;

function av_ts2str(ts: Int64): string;
begin
  if ts = AV_NOPTS_VALUE then
    Result := 'NOPTS'
  else
    Result := IntToStr(ts);
end;

function av_ts_make_time_string(ts: Int64; tb: PAVRational): string;
begin
  if ts = AV_NOPTS_VALUE then
    Result := 'NOPTS'
  else
    Result := Format('%.6g', [av_q2d(tb^) * ts]);
end;

function av_ts2timestr(ts: Int64; tb: PAVRational): string;
begin
  if ts = AV_NOPTS_VALUE then
    Result := 'NOPTS'
  else
    Result := Format('%.6g', [av_q2d(tb^) * ts]);
end;

//#define av_int_list_length(list, term) \
//    av_int_list_length_for_size(sizeof(*(list)), list, term)
function av_int_list_length(list: Pointer; item_size: Integer; term: Int64): Integer;
begin
  Result := av_int_list_length_for_size(item_size, list, term);
end;

//#define av_opt_set_int_list(obj, name, val, term, flags) \
//    (av_int_list_length(val, term) > INT_MAX / sizeof(*(val)) ? \
//     AVERROR(EINVAL) : \
//     av_opt_set_bin(obj, name, (const uint8_t *)(val), \
//                    av_int_list_length(val, term) * sizeof(*(val)), flags))
function av_opt_set_int_list(obj: Pointer; name: PAnsiChar; list: Pointer; item_size: Integer; term: Int64; flags: Integer): Integer;
begin
  if av_int_list_length(list, item_size, term) > MaxInt / item_size then
    Result := AVERROR_EINVAL
  else
    Result := av_opt_set_bin(obj, name, PByte(list),
                  av_int_list_length(list, item_size, term) * item_size, flags);
end;

//#define FF_CEIL_RSHIFT(a,b) (!av_builtin_constant_p(b) ? -((-(a)) >> (b)) \
//                                                       : ((a) + (1<<(b)) - 1) >> (b))
function FF_CEIL_RSHIFT(a, b: Integer): Integer;
begin
//  if av_builtin_constant_p(b) = 0 then
    Result := -MySAR(-a, b);
//  else
//    Result := MySAR(a + (1 shl b) - 1, b);
//Assert(-MySAR(-a, b) = MySAR(a + (1 shl b) - 1, b));
end;

{$IFDEF DEBUG_MALLOC}
var
  FMemList: TThreadList = nil;
type
  PMemItem = ^TMemItem;
  TMemItem = record
    P: Pointer;
    S: Cardinal;
  end;

procedure dump_mem_list;
var
  I: Integer;
  S: string;
  total: Cardinal;
begin
  with FMemList.LockList do
    try
      if Count > 0 then
      begin
        total := 0;
        S := 'memory leak found:';
        for I := 0 to Count - 1 do
        begin
          S := S + sLineBreak + Format('  %3d %x=%8d', [I + 1, Integer(PMemItem(Items[I]).P), PMemItem(Items[I]).S]);
          Inc(total, PMemItem(Items[I]).S);
          Dispose(PMemItem(Items[I]));
        end;
        S := S + sLineBreak + Format('total %d bytes / %d kb', [total, total div 1024]);
      end
      else
        S := 'no memory leak.';
      GDebuger.Debug(S);
    finally
      FMemList.UnlockList;
    end;
end;

const
  DebugLogSize = 39;

function my_malloc(size: Cardinal): Pointer; cdecl;
var
  P: PMemItem;
begin
  with FMemList.LockList do
    try
      GetMem(Result, size);
      //GDebuger.Debug('malloc: %x=%d', [Integer(Result), size]);
      if size = DebugLogSize then
        GDebuger.Debug('malloc: %x=%d', [Integer(Result), size]);
      New(P);
      P.P := Result;
      P.S := size;
      Add(P);
    finally
      FMemList.UnlockList;
    end;
end;

function my_realloc(ptr: Pointer; size: Cardinal): Pointer; cdecl;
var
  I: Integer;
begin
  with FMemList.LockList do
    try
      Result := ptr;
      ReallocMem(Result, size);
      //GDebuger.Debug('realloc: %x->%x=%d', [Integer(ptr), Integer(Result), size]);
      for I := 0 to Count - 1 do
        if PMemItem(Items[I]).P = ptr then
        begin
          if PMemItem(Items[I]).S = DebugLogSize then
            GDebuger.Debug('realloc: %x=%d->%x=%d', [Integer(ptr), PMemItem(Items[I]).S, Integer(Result), size]);
          PMemItem(Items[I]).P := Result;
          PMemItem(Items[I]).S := size;
          Break;
        end;
    finally
      FMemList.UnlockList;
    end;
end;

procedure my_free(ptr: Pointer); cdecl;
var
  I: Integer;
begin
  with FMemList.LockList do
    try
{
      asm
        emms;
      end;
}
      for I := 0 to Count - 1 do
        if PMemItem(Items[I]).P = ptr then
        begin
          if PMemItem(Items[I]).S = DebugLogSize then
            GDebuger.Debug('free: %x=%d', [Integer(ptr), PMemItem(Items[I]).S]);
          Dispose(PMemItem(Items[I]));
          Delete(I);
          Break;
        end;
      FreeMem(ptr);
      //GDebuger.Debug('free: %x', [Integer(ptr)]);
    finally
      FMemList.UnlockList;
    end;
end;

type
  Tff_init_mem_debugerProc = procedure(); cdecl;
  Tff_uninit_mem_debugerProc = procedure(); cdecl;
var
  ff_init_mem_debuger: Tff_init_mem_debugerProc = nil;
  ff_uninit_mem_debuger: Tff_uninit_mem_debugerProc = nil;
  mem_debuger_init: Boolean = False;

procedure init_mem_debuger;
begin
  if Assigned(ff_init_mem_debuger) and not mem_debuger_init then
  begin
    ff_init_mem_debuger;
    mem_debuger_init := True;
  end;
end;

procedure uninit_mem_debuger;
begin
  if Assigned(ff_uninit_mem_debuger) and mem_debuger_init then
  begin
    ff_uninit_mem_debuger;
    mem_debuger_init := False;
  end;
end;

procedure InstallMemoryManager(const ALibFile: TPathFileName; const AHandle: THandle);
type
  TmallocProc = function(size: Cardinal): Pointer; cdecl;
  TreallocProc = function(ptr: Pointer; size: Cardinal): Pointer; cdecl;
  TfreeProc = procedure(ptr: Pointer); cdecl;
var
  ff_set_malloc: procedure(p: TmallocProc); cdecl;
  ff_set_realloc: procedure(p: TreallocProc); cdecl;
  ff_set_free: procedure(p: TfreeProc); cdecl;
begin
  FixupStub(ALibFile, AHandle, 'ff_set_malloc',           @ff_set_malloc);
  FixupStub(ALibFile, AHandle, 'ff_set_realloc',          @ff_set_realloc);
  FixupStub(ALibFile, AHandle, 'ff_set_free',             @ff_set_free);
  ff_set_malloc(my_malloc);
  ff_set_realloc(my_realloc);
  ff_set_free(my_free);
  FixupStub(ALibFile, AHandle, 'ff_init_mem_debuger',     @ff_init_mem_debuger);
  FixupStub(ALibFile, AHandle, 'ff_uninit_mem_debuger',   @ff_uninit_mem_debuger);
  init_mem_debuger;
end;
{$ENDIF}

procedure AVUtilFixupStubs(const ALibFile: TPathFileName; const AHandle: THandle);
begin
{$IFDEF DEBUG_MALLOC}
  InstallMemoryManager(ALibFile, AHandle);
{$ENDIF}
  FixupStub(ALibFile, AHandle, 'av_asprintf',             @av_asprintf);
  FixupStub(ALibFile, AHandle, 'av_bprint_finalize',      @av_bprint_finalize);
  FixupStub(ALibFile, AHandle, 'av_bprint_init',          @av_bprint_init);
  FixupStub(ALibFile, AHandle, 'av_bprintf',              @av_bprintf);
  FixupStub(ALibFile, AHandle, 'av_buffer_create',        @av_buffer_create);
  FixupStub(ALibFile, AHandle, 'av_buffer_default_free',  @av_buffer_default_free);
  FixupStub(ALibFile, AHandle, 'av_compare_ts',           @av_compare_ts);
  FixupStub(ALibFile, AHandle, 'av_default_item_name',    @av_default_item_name);
  FixupStub(ALibFile, AHandle, 'av_dict_copy',            @av_dict_copy);
  FixupStub(ALibFile, AHandle, 'av_dict_count',           @av_dict_count);
  FixupStub(ALibFile, AHandle, 'av_dict_free',            @av_dict_free);
  FixupStub(ALibFile, AHandle, 'av_dict_get',             @av_dict_get);
  FixupStub(ALibFile, AHandle, 'av_dict_set',             @av_dict_set);
  FixupStub(ALibFile, AHandle, 'av_expr_eval',            @av_expr_eval);
  FixupStub(ALibFile, AHandle, 'av_expr_free',            @av_expr_free);
  FixupStub(ALibFile, AHandle, 'av_expr_parse',           @av_expr_parse);
  FixupStub(ALibFile, AHandle, 'av_fifo_alloc',           @av_fifo_alloc);
  FixupStub(ALibFile, AHandle, 'av_fifo_free',            @av_fifo_free);
  FixupStub(ALibFile, AHandle, 'av_fifo_generic_read',    @av_fifo_generic_read);
  FixupStub(ALibFile, AHandle, 'av_fifo_generic_write',   @av_fifo_generic_write);
  FixupStub(ALibFile, AHandle, 'av_fifo_size',            @av_fifo_size);
  FixupStub(ALibFile, AHandle, 'av_find_nearest_q_idx',   @av_find_nearest_q_idx);
  FixupStub(ALibFile, AHandle, 'av_force_cpu_flags',      @av_force_cpu_flags);
  FixupStub(ALibFile, AHandle, 'av_frame_alloc',          @av_frame_alloc);
//  FixupStub(ALibFile, AHandle, 'av_frame_copy_props',     @av_frame_copy_props);
  FixupStub(ALibFile, AHandle, 'av_frame_free',           @av_frame_free);
  FixupStub(ALibFile, AHandle, 'av_frame_get_best_effort_timestamp', @av_frame_get_best_effort_timestamp);
  FixupStub(ALibFile, AHandle, 'av_frame_get_buffer',     @av_frame_get_buffer);
  FixupStub(ALibFile, AHandle, 'av_frame_get_channels',   @av_frame_get_channels);
  FixupStub(ALibFile, AHandle, 'av_frame_get_pkt_pos',    @av_frame_get_pkt_pos);
//  FixupStub(ALibFile, AHandle, 'av_frame_is_writable',    @av_frame_is_writable);
  FixupStub(ALibFile, AHandle, 'av_frame_ref',            @av_frame_ref);
  FixupStub(ALibFile, AHandle, 'av_frame_unref',          @av_frame_unref);
  FixupStub(ALibFile, AHandle, 'av_free',                 @av_free);
  FixupStub(ALibFile, AHandle, 'av_freep',                @av_freep);
  FixupStub(ALibFile, AHandle, 'av_gcd',                  @av_gcd);
  FixupStub(ALibFile, AHandle, 'av_get_bytes_per_sample', @av_get_bytes_per_sample);
  FixupStub(ALibFile, AHandle, 'av_get_channel_layout',   @av_get_channel_layout);
  FixupStub(ALibFile, AHandle, 'av_get_channel_layout_nb_channels', @av_get_channel_layout_nb_channels);
  FixupStub(ALibFile, AHandle, 'av_get_channel_layout_string', @av_get_channel_layout_string);
  FixupStub(ALibFile, AHandle, 'av_get_cpu_flags',        @av_get_cpu_flags);
  FixupStub(ALibFile, AHandle, 'av_get_default_channel_layout', @av_get_default_channel_layout);
  FixupStub(ALibFile, AHandle, 'av_get_int',              @av_get_int);
  FixupStub(ALibFile, AHandle, 'av_get_media_type_string',@av_get_media_type_string);
  FixupStub(ALibFile, AHandle, 'av_get_packed_sample_fmt',@av_get_packed_sample_fmt);
  FixupStub(ALibFile, AHandle, 'av_get_picture_type_char',@av_get_picture_type_char);
  FixupStub(ALibFile, AHandle, 'av_get_pix_fmt',          @av_get_pix_fmt);
  FixupStub(ALibFile, AHandle, 'av_get_pix_fmt_name',     @av_get_pix_fmt_name);
  FixupStub(ALibFile, AHandle, 'av_get_sample_fmt',       @av_get_sample_fmt);
  FixupStub(ALibFile, AHandle, 'av_get_sample_fmt_name',  @av_get_sample_fmt_name);
  FixupStub(ALibFile, AHandle, 'av_get_sample_fmt_string',@av_get_sample_fmt_string);
  FixupStub(ALibFile, AHandle, 'av_get_token',            @av_get_token);
  FixupStub(ALibFile, AHandle, 'av_gettime',              @av_gettime);
  FixupStub(ALibFile, AHandle, 'av_image_check_size',     @av_image_check_size);
  FixupStub(ALibFile, AHandle, 'av_image_copy',           @av_image_copy);
  FixupStub(ALibFile, AHandle, 'av_image_copy_plane',     @av_image_copy_plane);
  FixupStub(ALibFile, AHandle, 'av_image_get_linesize',   @av_image_get_linesize);
  FixupStub(ALibFile, AHandle, 'av_int_list_length_for_size', @av_int_list_length_for_size);
  FixupStub(ALibFile, AHandle, 'av_log',                  @av_log);
  FixupStub(ALibFile, AHandle, 'av_log_default_callback', @av_log_default_callback);
  FixupStub(ALibFile, AHandle, 'av_log_get_level',        @av_log_get_level);
  FixupStub(ALibFile, AHandle, 'av_log_set_callback',     @av_log_set_callback);
  FixupStub(ALibFile, AHandle, 'av_log_set_flags',        @av_log_set_flags);
  FixupStub(ALibFile, AHandle, 'av_log_set_level',        @av_log_set_level);
  FixupStub(ALibFile, AHandle, 'av_malloc',               @av_malloc);
  FixupStub(ALibFile, AHandle, 'av_mallocz',              @av_mallocz);
  FixupStub(ALibFile, AHandle, 'av_max_alloc',            @av_max_alloc);
  FixupStub(ALibFile, AHandle, 'av_opt_find',             @av_opt_find);
  FixupStub(ALibFile, AHandle, 'av_opt_free',             @av_opt_free);
  FixupStub(ALibFile, AHandle, 'av_opt_get_double',       @av_opt_get_double);
  FixupStub(ALibFile, AHandle, 'av_opt_get_int',          @av_opt_get_int);
  FixupStub(ALibFile, AHandle, 'av_opt_ptr',              @av_opt_ptr);
  FixupStub(ALibFile, AHandle, 'av_opt_set',              @av_opt_set);
  FixupStub(ALibFile, AHandle, 'av_opt_set_bin',          @av_opt_set_bin);
  FixupStub(ALibFile, AHandle, 'av_opt_set_defaults',     @av_opt_set_defaults);
  FixupStub(ALibFile, AHandle, 'av_opt_set_dict',         @av_opt_set_dict);
  FixupStub(ALibFile, AHandle, 'av_opt_set_double',       @av_opt_set_double);
  FixupStub(ALibFile, AHandle, 'av_opt_set_int',          @av_opt_set_int);
  FixupStub(ALibFile, AHandle, 'av_parse_cpu_caps',       @av_parse_cpu_caps);
  FixupStub(ALibFile, AHandle, 'av_parse_ratio',          @av_parse_ratio);
  FixupStub(ALibFile, AHandle, 'av_parse_time',           @av_parse_time);
  FixupStub(ALibFile, AHandle, 'av_parse_video_rate',     @av_parse_video_rate);
  FixupStub(ALibFile, AHandle, 'av_parse_video_size',     @av_parse_video_size);
  FixupStub(ALibFile, AHandle, 'av_pix_fmt_desc_get',     @av_pix_fmt_desc_get);
  FixupStub(ALibFile, AHandle, 'av_pix_fmt_get_chroma_sub_sample', @av_pix_fmt_get_chroma_sub_sample);
  FixupStub(ALibFile, AHandle, 'av_realloc',              @av_realloc);
  FixupStub(ALibFile, AHandle, 'av_realloc_f',            @av_realloc_f);
  FixupStub(ALibFile, AHandle, 'av_reduce',               @av_reduce);
  FixupStub(ALibFile, AHandle, 'av_rescale',              @av_rescale);
  FixupStub(ALibFile, AHandle, 'av_rescale_delta',        @av_rescale_delta);
  FixupStub(ALibFile, AHandle, 'av_rescale_q',            @av_rescale_q);
  FixupStub(ALibFile, AHandle, 'av_samples_get_buffer_size', @av_samples_get_buffer_size);
  FixupStub(ALibFile, AHandle, 'av_set_string3',          @av_set_string3);
  FixupStub(ALibFile, AHandle, 'av_strcasecmp',           @av_strcasecmp);
  FixupStub(ALibFile, AHandle, 'av_strdup',               @av_strdup);
  FixupStub(ALibFile, AHandle, 'av_strlcat',              @av_strlcat);
  FixupStub(ALibFile, AHandle, 'av_strlcatf',             @av_strlcatf);
  FixupStub(ALibFile, AHandle, 'av_strlcpy',              @av_strlcpy);
  FixupStub(ALibFile, AHandle, 'av_strstart',             @av_strstart);
  FixupStub(ALibFile, AHandle, 'av_usleep',               @av_usleep);
end;

procedure AVUtilUnfixStubs;
begin
{$IFDEF DEBUG_MALLOC}
  uninit_mem_debuger;
{$ENDIF}
  @av_asprintf                := nil;
  @av_bprint_finalize         := nil;
  @av_bprint_init             := nil;
  @av_bprintf                 := nil;
  @av_buffer_create           := nil;
  @av_buffer_default_free     := nil;
  @av_compare_ts              := nil;
  @av_default_item_name       := nil;
  @av_dict_copy               := nil;
  @av_dict_count              := nil;
  @av_dict_free               := nil;
  @av_dict_get                := nil;
  @av_dict_set                := nil;
  @av_expr_eval               := nil;
  @av_expr_free               := nil;
  @av_expr_parse              := nil;
  @av_fifo_alloc              := nil;
  @av_fifo_free               := nil;
  @av_fifo_generic_read       := nil;
  @av_fifo_generic_write      := nil;
  @av_fifo_size               := nil;
  @av_find_nearest_q_idx      := nil;
  @av_force_cpu_flags         := nil;
  @av_frame_alloc             := nil;
//  @av_frame_copy_props        := nil;
  @av_frame_free              := nil;
  @av_frame_get_best_effort_timestamp := nil;
  @av_frame_get_buffer        := nil;
  @av_frame_get_channels      := nil;
  @av_frame_get_pkt_pos       := nil;
//  @av_frame_is_writable       := nil;
  @av_frame_ref               := nil;
  @av_frame_unref             := nil;
  @av_free                    := nil;
  @av_freep                   := nil;
  @av_gcd                     := nil;
  @av_get_bytes_per_sample    := nil;
  @av_get_channel_layout      := nil;
  @av_get_channel_layout_nb_channels := nil;
  @av_get_channel_layout_string := nil;
  @av_get_cpu_flags           := nil;
  @av_get_default_channel_layout := nil;
  @av_get_int                 := nil;
  @av_get_media_type_string   := nil;
  @av_get_packed_sample_fmt   := nil;
  @av_get_picture_type_char   := nil;
  @av_get_pix_fmt             := nil;
  @av_get_pix_fmt_name        := nil;
  @av_get_sample_fmt          := nil;
  @av_get_sample_fmt_name     := nil;
  @av_get_sample_fmt_string   := nil;
  @av_get_token               := nil;
  @av_gettime                 := nil;
  @av_image_check_size        := nil;
  @av_image_copy              := nil;
  @av_image_copy_plane        := nil;
  @av_image_get_linesize      := nil;
  @av_int_list_length_for_size:= nil;
  @av_log                     := nil;
  @av_log_default_callback    := nil;
  @av_log_get_level           := nil;
  @av_log_set_callback        := nil;
  @av_log_set_flags           := nil;
  @av_log_set_level           := nil;
  @av_malloc                  := nil;
  @av_mallocz                 := nil;
  @av_max_alloc               := nil;
  @av_opt_find                := nil;
  @av_opt_free                := nil;
  @av_opt_get_double          := nil;
  @av_opt_get_int             := nil;
  @av_opt_ptr                 := nil;
  @av_opt_set                 := nil;
  @av_opt_set_bin             := nil;
  @av_opt_set_defaults        := nil;
  @av_opt_set_dict            := nil;
  @av_opt_set_double          := nil;
  @av_opt_set_int             := nil;
  @av_parse_cpu_caps          := nil;
  @av_parse_ratio             := nil;
  @av_parse_time              := nil;
  @av_parse_video_rate        := nil;
  @av_parse_video_size        := nil;
  @av_pix_fmt_desc_get        := nil;
  @av_pix_fmt_get_chroma_sub_sample := nil;
  @av_realloc                 := nil;
  @av_realloc_f               := nil;
  @av_reduce                  := nil;
  @av_rescale                 := nil;
  @av_rescale_delta           := nil;
  @av_rescale_q               := nil;
  @av_samples_get_buffer_size := nil;
  @av_set_string3             := nil;
  @av_strcasecmp              := nil;
  @av_strdup                  := nil;
  @av_strlcat                 := nil;
  @av_strlcatf                := nil;
  @av_strlcpy                 := nil;
  @av_strstart                := nil;
  @av_usleep                  := nil;
end;

{$IFDEF DEBUG_MALLOC}
initialization
  GDebuger.Open;
  FMemList := TThreadList.Create;
finalization
  dump_mem_list;
  FreeAndNil(FMemList);
{$ENDIF}

end.
