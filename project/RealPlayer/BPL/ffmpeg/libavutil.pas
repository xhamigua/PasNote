(*
 * copyright (c) 2006 Michael Niedermayer <michaelni@gmx.at>
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
 * Original file: libavutil/avutil.h
 * Ported by CodeCoolie@CNSW 2008/03/18 -> $Date:: 2013-11-18 #$
 *)

unit libavutil;

interface

{$I CompilerDefines.inc}

uses
  libavutil_avstring,
  libavutil_rational;

{$I libversion.inc}

(**
 * @file
 * external API header
 *)

(**
 * @mainpage
 *
 * @section ffmpeg_intro Introduction
 *
 * This document describes the usage of the different libraries
 * provided by FFmpeg.
 *
 * @li @ref libavc "libavcodec" encoding/decoding library
 * @li @ref lavfi "libavfilter" graph-based frame editing library
 * @li @ref libavf "libavformat" I/O and muxing/demuxing library
 * @li @ref lavd "libavdevice" special devices muxing/demuxing library
 * @li @ref lavu "libavutil" common utility library
 * @li @ref lswr "libswresample" audio resampling, format conversion and mixing
 * @li @ref lpp  "libpostproc" post processing library
 * @li @ref lsws "libswscale" color conversion and scaling library
 *
 * @section ffmpeg_versioning Versioning and compatibility
 *
 * Each of the FFmpeg libraries contains a version.h header, which defines a
 * major, minor and micro version number with the
 * <em>LIBRARYNAME_VERSION_{MAJOR,MINOR,MICRO}</em> macros. The major version
 * number is incremented with backward incompatible changes - e.g. removing
 * parts of the public API, reordering public struct members, etc. The minor
 * version number is incremented for backward compatible API changes or major
 * new features - e.g. adding a new public function or a new decoder. The micro
 * version number is incremented for smaller changes that a calling program
 * might still want to check for - e.g. changing behavior in a previously
 * unspecified situation.
 *
 * FFmpeg guarantees backward API and ABI compatibility for each library as long
 * as its major version number is unchanged. This means that no public symbols
 * will be removed or renamed. Types and names of the public struct members and
 * values of public macros and enums will remain the same (unless they were
 * explicitly declared as not part of the public API). Documented behavior will
 * not change.
 *
 * In other words, any correct program that works with a given FFmpeg snapshot
 * should work just as well without any changes with any later snapshot with the
 * same major versions. This applies to both rebuilding the program against new
 * FFmpeg versions or to replacing the dynamic FFmpeg libraries that a program
 * links against.
 *
 * However, new public symbols may be added and new members may be appended to
 * public structs whose size is not part of public ABI (most public structs in
 * FFmpeg). New macros and enum values may be added. Behavior in undocumented
 * situations may change slightly (and be documented). All those are accompanied
 * by an entry in doc/APIchanges and incrementing either the minor or micro
 * version number.
 *)

(**
 * @defgroup lavu Common utility functions
 *
 * @brief
 * libavutil contains the code shared across all the other FFmpeg
 * libraries
 *
 * @note In order to use the functions provided by avutil you must include
 * the specific header.
 *
 * @{
 *
 * @defgroup lavu_crypto Crypto and Hashing
 *
 * @{
 * @}
 *
 * @defgroup lavu_math Maths
 * @{
 *
 * @}
 *
 * @defgroup lavu_string String Manipulation
 *
 * @{
 *
 * @}
 *
 * @defgroup lavu_mem Memory Management
 *
 * @{
 *
 * @}
 *
 * @defgroup lavu_data Data Structures
 * @{
 *
 * @}
 *
 * @defgroup lavu_audio Audio related
 *
 * @{
 *
 * @}
 *
 * @defgroup lavu_error Error Codes
 *
 * @{
 *
 * @}
 *
 * @defgroup lavu_log Logging Facility
 *
 * @{
 *
 * @}
 *
 * @defgroup lavu_misc Other
 *
 * @{
 *
 * @defgroup lavu_internal Internal
 *
 * Not exported functions, for internal usage only
 *
 * @{
 *
 * @}
 *)


type
  PPPByte = ^PPByte;
  PPByte = ^PByte;

(**
 * @addtogroup lavu_ver
 * @{
 *)

(**
 * Return the LIBAVUTIL_VERSION_INT constant.
 *)
  Tavutil_versionProc = function: Cardinal; cdecl;

(**
 * Return the libavutil build-time configuration.
 *)
  Tavutil_configurationProc = function: PAnsiChar; cdecl;

(**
 * Return the libavutil license.
 *)
  Tavutil_licenseProc = function: PAnsiChar; cdecl;

(**
 * @}
 *)

(**
 * @addtogroup lavu_media Media Type
 * @brief Media Type
 *)

{$IF Defined(BCB) and Defined(VER140)} // C++Builder 6
  TAVMediaType = Integer;
{$ELSE}
  TAVMediaType = (
    AVMEDIA_TYPE_UNKNOWN = -1,  ///< Usually treated as AVMEDIA_TYPE_DATA
    AVMEDIA_TYPE_VIDEO,
    AVMEDIA_TYPE_AUDIO,
    AVMEDIA_TYPE_DATA,          ///< Opaque data information usually continuous
    AVMEDIA_TYPE_SUBTITLE,
    AVMEDIA_TYPE_ATTACHMENT,    ///< Opaque data information usually sparse
    AVMEDIA_TYPE_NB
  );
{$IFEND}

{$IF Defined(BCB) and Defined(VER140)} // C++Builder 6
const
  AVMEDIA_TYPE_UNKNOWN=-1;
  AVMEDIA_TYPE_VIDEO=0;
  AVMEDIA_TYPE_AUDIO=1;
  AVMEDIA_TYPE_DATA=2;
  AVMEDIA_TYPE_SUBTITLE=3;
  AVMEDIA_TYPE_ATTACHMENT=4;
  AVMEDIA_TYPE_NB=5;

  AV_PICTURE_TYPE_NONE=0;
  AV_PICTURE_TYPE_I=1;
  AV_PICTURE_TYPE_P=2;
  AV_PICTURE_TYPE_B=3;
  AV_PICTURE_TYPE_S=4;
  AV_PICTURE_TYPE_SI=5;
  AV_PICTURE_TYPE_SP=6;
  AV_PICTURE_TYPE_BI=7;
{$IFEND}

(**
 * Return a string describing the media_type enum, NULL if media_type
 * is unknown.
 *)
  Tav_get_media_type_stringProc = function(media_type: TAVMediaType): PAnsiChar; cdecl;

(**
 * @defgroup lavu_const Constants
 * @{
 *
 * @defgroup lavu_enc Encoding specific
 *
 * @note those definition should move to avcodec
 * @{
 *)

const
  // AVCodecContext.global_quality;
  FF_LAMBDA_SHIFT = 7;
  FF_LAMBDA_SCALE = (1 shl FF_LAMBDA_SHIFT);
  FF_QP2LAMBDA = 118; ///< factor to convert from H.263 QP to lambda
  FF_LAMBDA_MAX = (256*128-1);
  FF_QUALITY_SCALE = FF_LAMBDA_SCALE; //FIXME maybe remove

(**
 * @}
 * @defgroup lavu_time Timestamp specific
 *
 * FFmpeg internal timebase and timestamp definitions
 *
 * @{
 *)

(**
 * @brief Undefined timestamp value
 *
 * Usually reported by demuxer that work on containers that do not provide
 * either pts or dts.
 *)

  AV_NOPTS_VALUE: Int64    = Int64($8000000000000000);

(**
 * Internal time base represented as integer
 *)

  AV_TIME_BASE_I           = 1000000;
  AV_TIME_BASE: Int64      = AV_TIME_BASE_I;

(**
 * Internal time base represented as fractional value
 *)

  AV_TIME_BASE_Q: TAVRational = (num: 1; den: AV_TIME_BASE_I);
  AV_TIME_BASE_SUB: TAVRational = (num: 1; den: 1000);

(**
 * @}
 * @}
 * @defgroup lavu_picture Image related
 *
 * AVPicture types, pixel formats and basic image planes manipulation.
 *
 * @{
 *)

type
{$IF Defined(BCB) and Defined(VER140)} // C++Builder 6
  TAVPictureType = Integer;
{$ELSE}
  TAVPictureType = (
    AV_PICTURE_TYPE_NONE = 0, ///< Undefined
    AV_PICTURE_TYPE_I,     ///< Intra
    AV_PICTURE_TYPE_P,     ///< Predicted
    AV_PICTURE_TYPE_B,     ///< Bi-dir predicted
    AV_PICTURE_TYPE_S,     ///< S(GMC)-VOP MPEG4
    AV_PICTURE_TYPE_SI,    ///< Switching Intra
    AV_PICTURE_TYPE_SP,    ///< Switching Predicted
    AV_PICTURE_TYPE_BI     ///< BI type
  );
{$IFEND}

(**
 * Return a single letter to describe the given picture type
 * pict_type.
 *
 * @param[in] pict_type the picture type @return a single character
 * representing the picture type, '?' if pict_type is unknown
 *)
  Tav_get_picture_type_charProc = function(pict_type: TAVPictureType): AnsiChar; cdecl;

(**
 * @}
 *)

(**
 * Return x default pointer in case p is NULL.
 *)
//static inline void *av_x_if_null(const void *p, const void *x)
//{
//    return (void *)(intptr_t)(p ? p : x);
//}

(**
 * Compute the length of an integer list.
 *
 * @param elsize  size in bytes of each list element (only 1, 2, 4 or 8)
 * @param term    list terminator (usually 0 or -1)
 * @param list    pointer to the list
 * @return  length of the list, in elements, not counting the terminator
 *)
  Tav_int_list_length_for_sizeProc = function(elsize: Cardinal;
                                     const list: Pointer; term: Int64): Cardinal; cdecl;

(**
 * Compute the length of an integer list.
 *
 * @param term  list terminator (usually 0 or -1)
 * @param list  pointer to the list
 * @return  length of the list, in elements, not counting the terminator
 *)
//#define av_int_list_length(list, term) \
//    av_int_list_length_for_size(sizeof(*(list)), list, term)

(****** TODO: check from libavutil/time.h **************)

(**
 * Get the current time in microseconds.
 *)
  Tav_gettimeProc = function: Int64; cdecl;

(**
 * Sleep for a period of time.  Although the duration is expressed in
 * microseconds, the actual delay may be rounded to the precision of the
 * system timer.
 *
 * @param  usec Number of microseconds to sleep.
 * @return zero on success or (negative) error code.
 *)
  Tav_usleepProc = function(usec: Cardinal): Integer; cdecl;


(****** TODO: check from libavutil/eval.h **************)

  PPAVExpr = ^PAVExpr;
  PAVExpr = ^TAVExpr;
  TAVExpr = record
    // need {$ALIGN 8}
  end;

(**
 * Parse and evaluate an expression.
 * Note, this is significantly slower than av_expr_eval().
 *
 * @param res a pointer to a double where is put the result value of
 * the expression, or NAN in case of error
 * @param s expression as a zero terminated string, for example "1+2^3+5*5+sin(2/3)"
 * @param const_names NULL terminated array of zero terminated strings of constant identifiers, for example {"PI", "E", 0}
 * @param const_values a zero terminated array of values for the identifiers from const_names
 * @param func1_names NULL terminated array of zero terminated strings of funcs1 identifiers
 * @param funcs1 NULL terminated array of function pointers for functions which take 1 argument
 * @param func2_names NULL terminated array of zero terminated strings of funcs2 identifiers
 * @param funcs2 NULL terminated array of function pointers for functions which take 2 arguments
 * @param opaque a pointer which will be passed to all functions from funcs1 and funcs2
 * @param log_ctx parent logging context
 * @return >= 0 in case of success, a negative value corresponding to an
 * AVERROR code otherwise
 *)
  // double (* const *funcs1)(void *, double)
  Tfuncs1 = function(p: Pointer; v: double): PDouble; cdecl;
  // double (* const *funcs2)(void *, double, double)
  Tfuncs2 = function(p: Pointer; v1, v2: Double): PDouble; cdecl;
  Tav_expr_parse_and_evalProc = function(res: Double; const s: PAnsiChar;
                           const const_names: PPAnsiChar; const const_values: PDouble;
                           const func1_names: PPAnsiChar; funcs1: Tfuncs1;
                           const func2_names: PPAnsiChar; funcs2: Tfuncs2;
                           opaque: Pointer; log_offset: Integer; log_ctx: Pointer): Integer; cdecl;

(**
 * Parse an expression.
 *
 * @param expr a pointer where is put an AVExpr containing the parsed
 * value in case of successful parsing, or NULL otherwise.
 * The pointed to AVExpr must be freed with av_expr_free() by the user
 * when it is not needed anymore.
 * @param s expression as a zero terminated string, for example "1+2^3+5*5+sin(2/3)"
 * @param const_names NULL terminated array of zero terminated strings of constant identifiers, for example {"PI", "E", 0}
 * @param func1_names NULL terminated array of zero terminated strings of funcs1 identifiers
 * @param funcs1 NULL terminated array of function pointers for functions which take 1 argument
 * @param func2_names NULL terminated array of zero terminated strings of funcs2 identifiers
 * @param funcs2 NULL terminated array of function pointers for functions which take 2 arguments
 * @param log_ctx parent logging context
 * @return >= 0 in case of success, a negative value corresponding to an
 * AVERROR code otherwise
 *)
  Tav_expr_parseProc = function(expr: PPAVExpr; const s: PAnsiChar;
                  const const_names: PPAnsiChar;
                  const func1_names: PPAnsiChar; funcs1: Tfuncs1;
                  const func2_names: PPAnsiChar; funcs2: Tfuncs2;
                  log_offset: Integer; log_ctx: Pointer): Integer; cdecl;

(**
 * Evaluate a previously parsed expression.
 *
 * @param const_values a zero terminated array of values for the identifiers from av_expr_parse() const_names
 * @param opaque a pointer which will be passed to all functions from funcs1 and funcs2
 * @return the value of the expression
 *)
  Tav_expr_evalProc = function(e: PAVExpr; const const_values: PDouble; opaque: Pointer): Double; cdecl;

(**
 * Free a parsed expression previously created with av_expr_parse().
 *)
  Tav_expr_freeProc = procedure(e: PAVExpr); cdecl;

(**
 * Parse the string in numstr and return its value as a double. If
 * the string is empty, contains only whitespaces, or does not contain
 * an initial substring that has the expected syntax for a
 * floating-point number, no conversion is performed. In this case,
 * returns a value of zero and the value returned in tail is the value
 * of numstr.
 *
 * @param numstr a string representing a number, may contain one of
 * the International System number postfixes, for example 'K', 'M',
 * 'G'. If 'i' is appended after the postfix, powers of 2 are used
 * instead of powers of 10. The 'B' postfix multiplies the value for
 * 8, and can be appended after another postfix or used alone. This
 * allows using for example 'KB', 'MiB', 'G' and 'B' as postfix.
 * @param tail if non-NULL puts here the pointer to the char next
 * after the last parsed character
 *)
  Tav_strtodProc = function(const numstr: PAnsiChar; tail: PPAnsiChar): Double; cdecl;

(****** TODO: check from libavutil/bprint.h **************)

(**
 * Define a structure with extra padding to a fixed size
 * This helps ensuring binary compatibility with future versions.
 *)
//#define FF_PAD_STRUCTURE(size, ...) \
//    __VA_ARGS__ \
//    char reserved_padding[size - sizeof(struct { __VA_ARGS__ })];

(**
 * Buffer to print data progressively
 *
 * The string buffer grows as necessary and is always 0-terminated.
 * The content of the string is never accessed, and thus is
 * encoding-agnostic and can even hold binary data.
 *
 * Small buffers are kept in the structure itself, and thus require no
 * memory allocation at all (unless the contents of the buffer is needed
 * after the structure goes out of scope). This is almost as lightweight as
 * declaring a local "char buf[512]".
 *
 * The length of the string can go beyond the allocated size: the buffer is
 * then truncated, but the functions still keep account of the actual total
 * length.
 *
 * In other words, buf->len can be greater than buf->size and records the
 * total length of what would have been to the buffer if there had been
 * enough memory.
 *
 * Append operations do not need to be tested for failure: if a memory
 * allocation fails, data stop being appended to the buffer, but the length
 * is still updated. This situation can be tested with
 * av_bprint_is_complete().
 *
 * The size_max field determines several possible behaviours:
 *
 * size_max = -1 (= UINT_MAX) or any large value will let the buffer be
 * reallocated as necessary, with an amortized linear cost.
 *
 * size_max = 0 prevents writing anything to the buffer: only the total
 * length is computed. The write operations can then possibly be repeated in
 * a buffer with exactly the necessary size
 * (using size_init = size_max = len + 1).
 *
 * size_max = 1 is automatically replaced by the exact size available in the
 * structure itself, thus ensuring no dynamic memory allocation. The
 * internal buffer is large enough to hold a reasonable paragraph of text,
 * such as the current paragraph.
 *)
  PAVBPrint = ^TAVBPrint;
  TAVBPrint = record
    str: PAnsiChar;     (**< string so far *)
    len: Cardinal;      (**< length so far *)
    size: Cardinal;     (**< allocated memory *)
    size_max: Cardinal; (**< maximum allocated memory *)
    reserved_internal_buffer: array[0..0] of AnsiChar;
    reserved_padding: array[0..1006] of AnsiChar;
  end;

(**
 * Convenience macros for special values for av_bprint_init() size_max
 * parameter.
 *)
const
  AV_BPRINT_SIZE_UNLIMITED  = Cardinal(-1);
  AV_BPRINT_SIZE_AUTOMATIC  = 1;
  AV_BPRINT_SIZE_COUNT_ONLY = 0;

(**
 * Init a print buffer.
 *
 * @param buf        buffer to init
 * @param size_init  initial size (including the final 0)
 * @param size_max   maximum size;
 *                   0 means do not write anything, just count the length;
 *                   1 is replaced by the maximum value for automatic storage;
 *                   any large value means that the internal buffer will be
 *                   reallocated as needed up to that limit; -1 is converted to
 *                   UINT_MAX, the largest limit possible.
 *                   Check also AV_BPRINT_SIZE_* macros.
 *)
type
  Tav_bprint_initProc = procedure(buf: PAVBPrint; size_init, size_max: Cardinal); cdecl;

(**
 * Init a print buffer using a pre-existing buffer.
 *
 * The buffer will not be reallocated.
 *
 * @param buf     buffer structure to init
 * @param buffer  byte buffer to use for the string data
 * @param size    size of buffer
 *)
  Tav_bprint_init_for_bufferProc = procedure(buf: PAVBPrint; buffer: PAnsiChar; size: Cardinal); cdecl;

(**
 * Append a formatted string to a print buffer.
 *)
  Tav_bprintfProc = procedure(buf: PAVBPrint; const fmt: PAnsiChar); cdecl varargs;

(**
 * Append a formatted string to a print buffer.
 *)
  Tav_vbprintfProc = procedure(buf: PAVBPrint; const fmt: PAnsiChar; vl_arg: Pointer{va_list}); cdecl;

(**
 * Append char c n times to a print buffer.
 *)
  Tav_bprint_charsProc = procedure(buf: PAVBPrint; c: AnsiChar; n: Cardinal); cdecl;

(**
 * Append data to a print buffer.
 *
 * param buf  bprint buffer to use
 * param data pointer to data
 * param size size of data
 *)
  Tav_bprint_append_dataProc = procedure(buf: PAVBPrint; const data: PAnsiChar; size: Cardinal); cdecl;

//struct tm;
(**
 * Append a formatted date and time to a print buffer.
 *
 * param buf  bprint buffer to use
 * param fmt  date and time format string, see strftime()
 * param tm   broken-down time structure to translate
 *
 * @note due to poor design of the standard strftime function, it may
 * produce poor results if the format string expands to a very long text and
 * the bprint buffer is near the limit stated by the size_max option.
 *)
  Tav_bprint_strftimeProc = procedure(buf: PAVBPrint; const fmt: PAnsiChar; const tm: Pointer{struct tm *tm}); cdecl;

(**
 * Allocate bytes in the buffer for external use.
 *
 * @param[in]  buf          buffer structure
 * @param[in]  size         required size
 * @param[out] mem          pointer to the memory area
 * @param[out] actual_size  size of the memory area after allocation;
 *                          can be larger or smaller than size
 *)
  Tav_bprint_get_bufferProc = procedure(buf: PAVBPrint; size: Cardinal;
                          mem: PPByte{unsigned char **mem}; actual_size: PCardinal); cdecl;

(**
 * Reset the string to "" but keep internal allocated data.
 *)
  Tav_bprint_clearProc = procedure(buf: PAVBPrint); cdecl;

(**
 * Test if the print buffer is complete (not truncated).
 *
 * It may have been truncated due to a memory allocation failure
 * or the size_max limit (compare size and size_max if necessary).
 *)
//static inline int av_bprint_is_complete(AVBPrint *buf)
//{
//    return buf->len < buf->size;
//}

(**
 * Finalize a print buffer.
 *
 * The print buffer can no longer be used afterwards,
 * but the len and size fields are still valid.
 *
 * @arg[out] ret_str  if not NULL, used to return a permanent copy of the
 *                    buffer contents, or NULL if memory allocation fails;
 *                    if NULL, the buffer is discarded and freed
 * @return  0 for success or error code (probably AVERROR(ENOMEM))
 *)
  Tav_bprint_finalizeProc = function(buf: PAVBPrint; ret_str: PPAnsiChar): Integer; cdecl;

(**
 * Escape the content in src and append it to dstbuf.
 *
 * @param dstbuf        already inited destination bprint buffer
 * @param src           string containing the text to escape
 * @param special_chars string containing the special characters which
 *                      need to be escaped, can be NULL
 * @param mode          escape mode to employ, see AV_ESCAPE_MODE_* macros.
 *                      Any unknown value for mode will be considered equivalent to
 *                      AV_ESCAPE_MODE_BACKSLASH, but this behaviour can change without
 *                      notice.
 * @param flags         flags which control how to escape, see AV_ESCAPE_FLAG_* macros
 *)
  Tav_bprint_escapeProc = procedure(dstbuf: PAVBPrint; const src, special_chars: PAnsiChar;
                            mode: TAVEscapeMode; flags: Integer); cdecl;

implementation

end.
