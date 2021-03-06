(*
 * AVOptions
 * copyright (c) 2005 Michael Niedermayer <michaelni@gmx.at>
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
 * Original file: libavutil/opt.h
 * Ported by CodeCoolie@CNSW 2010/10/03 -> $Date:: 2013-11-18 #$
 *)

unit libavutil_opt;

interface

{$I CompilerDefines.inc}

uses
{$IFDEF BCB}
  BCBTypes,
{$ENDIF}
  libavutil,
  libavutil_dict,
  libavutil_pixfmt,
  libavutil_rational;

{$I libversion.inc}

(**
 * @file
 * AVOptions
 *)

(**
 * @defgroup avoptions AVOptions
 * @ingroup lavu_data
 * @{
 * AVOptions provide a generic system to declare options on arbitrary structs
 * ("objects"). An option can have a help text, a type and a range of possible
 * values. Options may then be enumerated, read and written to.
 *
 * @section avoptions_implement Implementing AVOptions
 * This section describes how to add AVOptions capabilities to a struct.
 *
 * All AVOptions-related information is stored in an AVClass. Therefore
 * the first member of the struct should be a pointer to an AVClass describing it.
 * The option field of the AVClass must be set to a NULL-terminated static array
 * of AVOptions. Each AVOption must have a non-empty name, a type, a default
 * value and for number-type AVOptions also a range of allowed values. It must
 * also declare an offset in bytes from the start of the struct, where the field
 * associated with this AVOption is located. Other fields in the AVOption struct
 * should also be set when applicable, but are not required.
 *
 * The following example illustrates an AVOptions-enabled struct:
 * @code
 * typedef struct test_struct {
 *     AVClass *class;
 *     int      int_opt;
 *     char    *str_opt;
 *     uint8_t *bin_opt;
 *     int      bin_len;
 * } test_struct;
 *
 * static const AVOption test_options[] = {
 *   { "test_int", "This is a test option of int type.", offsetof(test_struct, int_opt),
 *     AV_OPT_TYPE_INT, { .i64 = -1 }, INT_MIN, INT_MAX },
 *   { "test_str", "This is a test option of string type.", offsetof(test_struct, str_opt),
 *     AV_OPT_TYPE_STRING },
 *   { "test_bin", "This is a test option of binary type.", offsetof(test_struct, bin_opt),
 *     AV_OPT_TYPE_BINARY },
 *   { NULL },
 * };
 *
 * static const AVClass test_class = {
 *     .class_name = "test class",
 *     .item_name  = av_default_item_name,
 *     .option     = test_options,
 *     .version    = LIBAVUTIL_VERSION_INT,
 * };
 * @endcode
 *
 * Next, when allocating your struct, you must ensure that the AVClass pointer
 * is set to the correct value. Then, av_opt_set_defaults() can be called to
 * initialize defaults. After that the struct is ready to be used with the
 * AVOptions API.
 *
 * When cleaning up, you may use the av_opt_free() function to automatically
 * free all the allocated string and binary options.
 *
 * Continuing with the above example:
 *
 * @code
 * test_struct *alloc_test_struct(void)
 * {
 *     test_struct *ret = av_malloc(sizeof(*ret));
 *     ret->class = &test_class;
 *     av_opt_set_defaults(ret);
 *     return ret;
 * }
 * void free_test_struct(test_struct **foo)
 * {
 *     av_opt_free(*foo);
 *     av_freep(foo);
 * }
 * @endcode
 *
 * @subsection avoptions_implement_nesting Nesting
 *      It may happen that an AVOptions-enabled struct contains another
 *      AVOptions-enabled struct as a member (e.g. AVCodecContext in
 *      libavcodec exports generic options, while its priv_data field exports
 *      codec-specific options). In such a case, it is possible to set up the
 *      parent struct to export a child's options. To do that, simply
 *      implement AVClass.child_next() and AVClass.child_class_next() in the
 *      parent struct's AVClass.
 *      Assuming that the test_struct from above now also contains a
 *      child_struct field:
 *
 *      @code
 *      typedef struct child_struct {
 *          AVClass *class;
 *          int flags_opt;
 *      } child_struct;
 *      static const AVOption child_opts[] = {
 *          { "test_flags", "This is a test option of flags type.",
 *            offsetof(child_struct, flags_opt), AV_OPT_TYPE_FLAGS, { .i64 = 0 }, INT_MIN, INT_MAX },
 *          { NULL },
 *      };
 *      static const AVClass child_class = {
 *          .class_name = "child class",
 *          .item_name  = av_default_item_name,
 *          .option     = child_opts,
 *          .version    = LIBAVUTIL_VERSION_INT,
 *      };
 *
 *      void *child_next(void *obj, void *prev)
 *      {
 *          test_struct *t = obj;
 *          if (!prev && t->child_struct)
 *              return t->child_struct;
 *          return NULL
 *      }
 *      const AVClass child_class_next(const AVClass *prev)
 *      {
 *          return prev ? NULL : &child_class;
 *      }
 *      @endcode
 *      Putting child_next() and child_class_next() as defined above into
 *      test_class will now make child_struct's options accessible through
 *      test_struct (again, proper setup as described above needs to be done on
 *      child_struct right after it is created).
 *
 *      From the above example it might not be clear why both child_next()
 *      and child_class_next() are needed. The distinction is that child_next()
 *      iterates over actually existing objects, while child_class_next()
 *      iterates over all possible child classes. E.g. if an AVCodecContext
 *      was initialized to use a codec which has private options, then its
 *      child_next() will return AVCodecContext.priv_data and finish
 *      iterating. OTOH child_class_next() on AVCodecContext.av_class will
 *      iterate over all available codecs with private options.
 *
 * @subsection avoptions_implement_named_constants Named constants
 *      It is possible to create named constants for options. Simply set the unit
 *      field of the option the constants should apply to a string and
 *      create the constants themselves as options of type AV_OPT_TYPE_CONST
 *      with their unit field set to the same string.
 *      Their default_val field should contain the value of the named
 *      constant.
 *      For example, to add some named constants for the test_flags option
 *      above, put the following into the child_opts array:
 *      @code
 *      { "test_flags", "This is a test option of flags type.",
 *        offsetof(child_struct, flags_opt), AV_OPT_TYPE_FLAGS, { .i64 = 0 }, INT_MIN, INT_MAX, "test_unit" },
 *      { "flag1", "This is a flag with value 16", 0, AV_OPT_TYPE_CONST, { .i64 = 16 }, 0, 0, "test_unit" },
 *      @endcode
 *
 * @section avoptions_use Using AVOptions
 * This section deals with accessing options in an AVOptions-enabled struct.
 * Such structs in FFmpeg are e.g. AVCodecContext in libavcodec or
 * AVFormatContext in libavformat.
 *
 * @subsection avoptions_use_examine Examining AVOptions
 * The basic functions for examining options are av_opt_next(), which iterates
 * over all options defined for one object, and av_opt_find(), which searches
 * for an option with the given name.
 *
 * The situation is more complicated with nesting. An AVOptions-enabled struct
 * may have AVOptions-enabled children. Passing the AV_OPT_SEARCH_CHILDREN flag
 * to av_opt_find() will make the function search children recursively.
 *
 * For enumerating there are basically two cases. The first is when you want to
 * get all options that may potentially exist on the struct and its children
 * (e.g.  when constructing documentation). In that case you should call
 * av_opt_child_class_next() recursively on the parent struct's AVClass.  The
 * second case is when you have an already initialized struct with all its
 * children and you want to get all options that can be actually written or read
 * from it. In that case you should call av_opt_child_next() recursively (and
 * av_opt_next() on each result).
 *
 * @subsection avoptions_use_get_set Reading and writing AVOptions
 * When setting options, you often have a string read directly from the
 * user. In such a case, simply passing it to av_opt_set() is enough. For
 * non-string type options, av_opt_set() will parse the string according to the
 * option type.
 *
 * Similarly av_opt_get() will read any option type and convert it to a string
 * which will be returned. Do not forget that the string is allocated, so you
 * have to free it with av_free().
 *
 * In some cases it may be more convenient to put all options into an
 * AVDictionary and call av_opt_set_dict() on it. A specific case of this
 * are the format/codec open functions in lavf/lavc which take a dictionary
 * filled with option as a parameter. This allows to set some options
 * that cannot be set otherwise, since e.g. the input file format is not known
 * before the file is actually opened.
 *)

{$IF Defined(BCB) and Defined(VER140)} // C++Builder 6
const
  AV_OPT_TYPE_FLAGS=0;
  AV_OPT_TYPE_INT=1;
  AV_OPT_TYPE_INT64=2;
  AV_OPT_TYPE_DOUBLE=3;
  AV_OPT_TYPE_FLOAT=4;
  AV_OPT_TYPE_STRING=5;
  AV_OPT_TYPE_RATIONAL=6;
  AV_OPT_TYPE_BINARY=7;
  AV_OPT_TYPE_CONST=128;
  AV_OPT_TYPE_IMAGE_SIZE=(Ord('S') shl 24) or (Ord('I') shl 16) or (Ord('Z') shl 8) or Ord('E');
  AV_OPT_TYPE_PIXEL_FMT=(Ord('P') shl 24) or (Ord('F') shl 16) or (Ord('M') shl 8) or Ord('T');
  AV_OPT_TYPE_SAMPLE_FMT=(Ord('S') shl 24) or (Ord('F') shl 16) or (Ord('M') shl 8) or Ord('T');
  AV_OPT_TYPE_VIDEO_RATE=(Ord('V') shl 24) or (Ord('R') shl 16) or (Ord('A') shl 8) or Ord('T');
  AV_OPT_TYPE_DURATION=(Ord('D') shl 24) or (Ord('U') shl 16) or (Ord('R') shl 8) or Ord(' ');
  AV_OPT_TYPE_COLOR=(Ord('C') shl 24) or (Ord('O') shl 16) or (Ord('L') shl 8) or Ord('R');
  AV_OPT_TYPE_CHANNEL_LAYOUT=(Ord('C') shl 24) or (Ord('H') shl 16) or (Ord('L') shl 8) or Ord('A');
{$IFDEF FF_API_OLD_AVOPTIONS}
  FF_OPT_TYPE_FLAGS=0;
  FF_OPT_TYPE_INT=1;
  FF_OPT_TYPE_INT64=2;
  FF_OPT_TYPE_DOUBLE=3;
  FF_OPT_TYPE_FLOAT=4;
  FF_OPT_TYPE_STRING=5;
  FF_OPT_TYPE_RATIONAL=6;
  FF_OPT_TYPE_BINARY=7;
  FF_OPT_TYPE_CONST=128;
{$ENDIF}
type
  TAVOptionType = Integer;
{$ELSE}
type
  TAVOptionType = (
    AV_OPT_TYPE_FLAGS,
    AV_OPT_TYPE_INT,
    AV_OPT_TYPE_INT64,
    AV_OPT_TYPE_DOUBLE,
    AV_OPT_TYPE_FLOAT,
    AV_OPT_TYPE_STRING,
    AV_OPT_TYPE_RATIONAL,
    AV_OPT_TYPE_BINARY,  ///< offset must point to a pointer immediately followed by an int for the length
    AV_OPT_TYPE_CONST = 128,
    AV_OPT_TYPE_IMAGE_SIZE = (Ord('S') shl 24) or (Ord('I') shl 16) or (Ord('Z') shl 8) or Ord('E'), ///< offset must point to two consecutive integers
    AV_OPT_TYPE_PIXEL_FMT  = (Ord('P') shl 24) or (Ord('F') shl 16) or (Ord('M') shl 8) or Ord('T'),
    AV_OPT_TYPE_SAMPLE_FMT = (Ord('S') shl 24) or (Ord('F') shl 16) or (Ord('M') shl 8) or Ord('T'),
    AV_OPT_TYPE_VIDEO_RATE = (Ord('V') shl 24) or (Ord('R') shl 16) or (Ord('A') shl 8) or Ord('T'), ///< offset must point to AVRational
    AV_OPT_TYPE_DURATION   = (Ord('D') shl 24) or (Ord('U') shl 16) or (Ord('R') shl 8) or Ord(' '),
    AV_OPT_TYPE_COLOR      = (Ord('C') shl 24) or (Ord('O') shl 16) or (Ord('L') shl 8) or Ord('R'),
    AV_OPT_TYPE_CHANNEL_LAYOUT=(Ord('C') shl 24) or (Ord('H') shl 16) or (Ord('L') shl 8) or Ord('A')
{$IFDEF FF_API_OLD_AVOPTIONS}
    ,FF_OPT_TYPE_FLAGS = 0,
    FF_OPT_TYPE_INT,
    FF_OPT_TYPE_INT64,
    FF_OPT_TYPE_DOUBLE,
    FF_OPT_TYPE_FLOAT,
    FF_OPT_TYPE_STRING,
    FF_OPT_TYPE_RATIONAL,
    FF_OPT_TYPE_BINARY,    ///< offset must point to a pointer immediately followed by an int for the length
    FF_OPT_TYPE_CONST=128
{$ENDIF}
  );
{$IFEND}

const
  // const for TAVOption.flags
  AV_OPT_FLAG_ENCODING_PARAM  = 1;   ///< a generic parameter which can be set by the user for muxing or encoding
  AV_OPT_FLAG_DECODING_PARAM  = 2;   ///< a generic parameter which can be set by the user for demuxing or decoding
  AV_OPT_FLAG_METADATA        = 4;   ///< some data extracted or inserted into the file like title, comment, ...
  AV_OPT_FLAG_AUDIO_PARAM     = 8;
  AV_OPT_FLAG_VIDEO_PARAM     = 16;
  AV_OPT_FLAG_SUBTITLE_PARAM  = 32;
  AV_OPT_FLAG_FILTERING_PARAM = (1 shl 16); ///< a generic parameter which can be set by the user for filtering
//FIXME think about enc-audio, ... style flags

  AV_OPT_SEARCH_CHILDREN  = $0001; (**< Search in possible children of the
                                             given object first. *)
(**
 *  The obj passed to av_opt_find() is fake -- only a double pointer to AVClass
 *  instead of a required pointer to a struct containing AVClass. This is
 *  useful for searching for options without needing to allocate the corresponding
 *  object.
 *)
  AV_OPT_SEARCH_FAKE_OBJ  = $0002;

  AV_OPT_FLAG_IMPLICIT_KEY = 1;

(**
 * AVOption
 *)
type
  _T_default_val = record
    case Integer of
      0: (i64: Int64);
      1: (dbl: Double);
      2: (str: PAnsiChar);
      (* TODO those are unused now *)
      3: (q: TAVRational);
  end;

  PPAVOption = ^PAVOption;
  PAVOption = ^TAVOption;
  TAVOption = record
    name: PAnsiChar;

    (**
     * short English help text.
     * @todo What about other languages
     *)
    help: PAnsiChar;

    (**
     * The offset relative to the context structure where the option
     * value is stored. It should be 0 for named constants.
     *)
    offset: Integer;
    ttype: TAVOptionType;

    (**
     * the default value for scalar options
     *)
    default_val: _T_default_val;
    min: Double;                        ///< minimum valid value for the option
    max: Double;                        ///< maximum valid value for the option

    flags: Integer;
{
#define AV_OPT_FLAG_ENCODING_PARAM  1   ///< a generic parameter which can be set by the user for muxing or encoding
#define AV_OPT_FLAG_DECODING_PARAM  2   ///< a generic parameter which can be set by the user for demuxing or decoding
#define AV_OPT_FLAG_METADATA        4   ///< some data extracted or inserted into the file like title, comment, ...
#define AV_OPT_FLAG_AUDIO_PARAM     8
#define AV_OPT_FLAG_VIDEO_PARAM     16
#define AV_OPT_FLAG_SUBTITLE_PARAM  32
#define AV_OPT_FLAG_FILTERING_PARAM (1<<16) ///< a generic parameter which can be set by the user for filtering
//FIXME think about enc-audio, ... style flags
}

    (**
     * The logical unit to which the option belongs. Non-constant
     * options and corresponding named constants share the same
     * unit. May be NULL.
     *)
    uunit: PAnsiChar; //const char *unit;
  end;

(**
 * A single allowed range of values, or a single allowed value.
 *)
  PPAVOptionRange = ^PAVOptionRange;
  PAVOptionRange = ^TAVOptionRange;
  TAVOptionRange = record
    str: PAnsiChar;
    value_min, value_max: Double;             ///< For string ranges this represents the min/max length, for dimensions this represents the min/max pixel count
    component_min, component_max: Double;     ///< For string this represents the unicode range for chars, 0-127 limits to ASCII
    is_range: Integer;                        ///< if set to 1 the struct encodes a range, if set to 0 a single value
  end;

(**
 * List of AVOptionRange structs
 *)
  PPAVOptionRanges = ^PAVOptionRanges;
  PAVOptionRanges = ^TAVOptionRanges;
  TAVOptionRanges = record
    range: PPAVOptionRange;
    nb_ranges: Integer;
  end;


{$IFDEF FF_API_FIND_OPT}
(**
 * Look for an option in obj. Look only for the options which
 * have the flags set as specified in mask and flags (that is,
 * for which it is the case that (opt->flags & mask) == flags).
 *
 * @param[in] obj a pointer to a struct whose first element is a
 * pointer to an AVClass
 * @param[in] name the name of the option to look for
 * @param[in] unit the unit of the option to look for, or any if NULL
 * @return a pointer to the option found, or NULL if no option
 * has been found
 *
 * @deprecated use av_opt_find.
 *)
  Tav_find_optProc = function(obj: Pointer; const name, uunit: PAnsiChar; mask, flags: Integer): PAVOption; cdecl;
{$ENDIF}

{$IFDEF FF_API_OLD_AVOPTIONS}
(**
 * Set the field of obj with the given name to value.
 *
 * @param[in] obj A struct whose first element is a pointer to an
 * AVClass.
 * @param[in] name the name of the field to set
 * @param[in] val The value to set. If the field is not of a string
 * type, then the given string is parsed.
 * SI postfixes and some named scalars are supported.
 * If the field is of a numeric type, it has to be a numeric or named
 * scalar. Behavior with more than one scalar and +- infix operators
 * is undefined.
 * If the field is of a flags type, it has to be a sequence of numeric
 * scalars or named flags separated by '+' or '-'. Prefixing a flag
 * with '+' causes it to be set without affecting the other flags;
 * similarly, '-' unsets a flag.
 * @param[out] o_out if non-NULL put here a pointer to the AVOption
 * found
 * @param alloc this parameter is currently ignored
 * @return 0 if the value has been set, or an AVERROR code in case of
 * error:
 * AVERROR_OPTION_NOT_FOUND if no matching option exists
 * AVERROR(ERANGE) if the value is out of range
 * AVERROR(EINVAL) if the value is not valid
 * @deprecated use av_opt_set()
 *)
  Tav_set_string3Proc = function(obj: Pointer; const name, val: PAnsiChar; alloc: Integer; const o_out: PPAVOption): Integer; cdecl;

  Tav_set_doubleProc = function(obj: Pointer; const name: PAnsiChar; n: Double): PAVOption; cdecl;
  Tav_set_qProc = function(obj: Pointer; const name: PAnsiChar; n: TAVRational): PAVOption; cdecl;
  Tav_set_intProc = function(obj: Pointer; const name: PAnsiChar; n: Int64): PAVOption; cdecl;

  Tav_get_doubleProc = function(obj: Pointer; const name: PAnsiChar; const o_out: PPAVOption): Double; cdecl;
//TODO: API returen record  Tav_get_qProc = function(obj: Pointer; const name: PAnsiChar; const o_out: PPAVOption): TAVRational; cdecl;
  Tav_get_intProc = function(obj: Pointer; const name: PAnsiChar; const o_out: PPAVOption): Int64; cdecl;
  Tav_get_stringProc = function(obj: Pointer; const name: PAnsiChar; const o_out: PPAVOption; buf: PAnsiChar; buf_len: Integer): PAnsiChar; cdecl;
  Tav_next_optionProc = function(obj: Pointer; const last: PAVOption): PAVOption; cdecl;
{$ENDIF}

(**
 * Show the obj options.
 *
 * @param req_flags requested flags for the options to show. Show only the
 * options for which it is opt->flags & req_flags.
 * @param rej_flags rejected flags for the options to show. Show only the
 * options for which it is !(opt->flags & req_flags).
 * @param av_log_obj log context to use for showing the options
 *)
  Tav_opt_show2Proc = function(obj: Pointer; av_log_obj: Pointer; req_flags, rej_flags: Integer): Integer; cdecl;

(**
 * Set the values of all AVOption fields to their default values.
 *
 * @param s an AVOption-enabled struct (its first member must be a pointer to AVClass)
 *)
  Tav_opt_set_defaultsProc = procedure(s: Pointer); cdecl;

{$IFDEF FF_API_OLD_AVOPTIONS}
  Tav_opt_set_defaults2Proc = procedure(s: Pointer; mask, flags: Integer); cdecl;
{$ENDIF}

(**
 * Parse the key/value pairs list in opts. For each key/value pair
 * found, stores the value in the field in ctx that is named like the
 * key. ctx must be an AVClass context, storing is done using
 * AVOptions.
 *
 * @param opts options string to parse, may be NULL
 * @param key_val_sep a 0-terminated list of characters used to
 * separate key from value
 * @param pairs_sep a 0-terminated list of characters used to separate
 * two pairs from each other
 * @return the number of successfully set key/value pairs, or a negative
 * value corresponding to an AVERROR code in case of error:
 * AVERROR(EINVAL) if opts cannot be parsed,
 * the error code issued by av_set_string3() if a key/value pair
 * cannot be set
 *)
  Tav_set_options_stringProc = function(ctx: Pointer; const opts: PAnsiChar;
                          const key_val_sep: PAnsiChar; const pairs_sep: PAnsiChar): Integer; cdecl;

(**
 * Parse the key-value pairs list in opts. For each key=value pair found,
 * set the value of the corresponding option in ctx.
 *
 * @param ctx          the AVClass object to set options on
 * @param opts         the options string, key-value pairs separated by a
 *                     delimiter
 * @param shorthand    a NULL-terminated array of options names for shorthand
 *                     notation: if the first field in opts has no key part,
 *                     the key is taken from the first element of shorthand;
 *                     then again for the second, etc., until either opts is
 *                     finished, shorthand is finished or a named option is
 *                     found; after that, all options must be named
 * @param key_val_sep  a 0-terminated list of characters used to separate
 *                     key from value, for example '='
 * @param pairs_sep    a 0-terminated list of characters used to separate
 *                     two pairs from each other, for example ':' or ','
 * @return  the number of successfully set key=value pairs, or a negative
 *          value corresponding to an AVERROR code in case of error:
 *          AVERROR(EINVAL) if opts cannot be parsed,
 *          the error code issued by av_set_string3() if a key/value pair
 *          cannot be set
 *
 * Options names must use only the following characters: a-z A-Z 0-9 - . / _
 * Separators must use characters distinct from option names and from each
 * other.
 *)
  Tav_opt_set_from_stringProc = function(ctx: Pointer; const opts: PAnsiChar;
                           const shorthand: PPAnsiChar;//const char *const *shorthand,
                           const key_val_sep, pairs_sep: PAnsiChar): Integer; cdecl;
(**
 * Free all string and binary options in obj.
 *)
  Tav_opt_freeProc = procedure(obj: Pointer); cdecl;

(**
 * Check whether a particular flag is set in a flags field.
 *
 * @param field_name the name of the flag field option
 * @param flag_name the name of the flag to check
 * @return non-zero if the flag is set, zero if the flag isn't set,
 *         isn't of the right type, or the flags field doesn't exist.
 *)
  Tav_opt_flag_is_setProc = function(obj: Pointer; const field_name, flag_name: PAnsiChar): Integer; cdecl;

(**
 * Set all the options from a given dictionary on an object.
 *
 * @param obj a struct whose first element is a pointer to AVClass
 * @param options options to process. This dictionary will be freed and replaced
 *                by a new one containing all options not found in obj.
 *                Of course this new dictionary needs to be freed by caller
 *                with av_dict_free().
 *
 * @return 0 on success, a negative AVERROR if some option was found in obj,
 *         but could not be set.
 *
 * @see av_dict_copy()
 *)
  Tav_opt_set_dictProc = function(obj: Pointer; options: PPAVDictionary): Integer; cdecl;

(**
 * Extract a key-value pair from the beginning of a string.
 *
 * @param ropts        pointer to the options string, will be updated to
 *                     point to the rest of the string (one of the pairs_sep
 *                     or the final NUL)
 * @param key_val_sep  a 0-terminated list of characters used to separate
 *                     key from value, for example '='
 * @param pairs_sep    a 0-terminated list of characters used to separate
 *                     two pairs from each other, for example ':' or ','
 * @param flags        flags; see the AV_OPT_FLAG_* values below
 * @param rkey         parsed key; must be freed using av_free()
 * @param rval         parsed value; must be freed using av_free()
 *
 * @return  >=0 for success, or a negative value corresponding to an
 *          AVERROR code in case of error; in particular:
 *          AVERROR(EINVAL) if no key is present
 *
 *)
  Tav_opt_get_key_valueProc = function(const ropts: PPAnsiChar;
                         const key_val_sep, pairs_sep: PAnsiChar;
                         flags: Cardinal;
                         rkey, rval: PPAnsiChar): Integer; cdecl;

(*
enum {

    /**
     * Accept to parse a value without a key; the key will then be returned
     * as NULL.
     */
    AV_OPT_FLAG_IMPLICIT_KEY = 1,
};
*)

(**
 * @defgroup opt_eval_funcs Evaluating option strings
 * @{
 * This group of functions can be used to evaluate option strings
 * and get numbers out of them. They do the same thing as av_opt_set(),
 * except the result is written into the caller-supplied pointer.
 *
 * @param obj a struct whose first element is a pointer to AVClass.
 * @param o an option for which the string is to be evaluated.
 * @param val string to be evaluated.
 * @param *_out value of the string will be written here.
 *
 * @return 0 on success, a negative number on failure.
 *)
  Tav_opt_eval_flagsProc  = function(obj: Pointer; const o: PAVOption; const val: PAnsiChar; flags_out : PInteger)   : Integer; cdecl;
  Tav_opt_eval_intProc    = function(obj: Pointer; const o: PAVOption; const val: PAnsiChar; int_out   : PInteger)   : Integer; cdecl;
  Tav_opt_eval_int64Proc  = function(obj: Pointer; const o: PAVOption; const val: PAnsiChar; int64_out : PInt64)     : Integer; cdecl;
  Tav_opt_eval_floatProc  = function(obj: Pointer; const o: PAVOption; const val: PAnsiChar; float_out : PSingle)    : Integer; cdecl;
  Tav_opt_eval_doubleProc = function(obj: Pointer; const o: PAVOption; const val: PAnsiChar; double_out: PDouble)    : Integer; cdecl;
  Tav_opt_eval_qProc      = function(obj: Pointer; const o: PAVOption; const val: PAnsiChar; q_out     : PAVRational): Integer; cdecl;
(**
 * @}
 *)

(**
 * Look for an option in an object. Consider only options which
 * have all the specified flags set.
 *
 * @param[in] obj A pointer to a struct whose first element is a
 *                pointer to an AVClass.
 *                Alternatively a double pointer to an AVClass, if
 *                AV_OPT_SEARCH_FAKE_OBJ search flag is set.
 * @param[in] name The name of the option to look for.
 * @param[in] unit When searching for named constants, name of the unit
 *                 it belongs to.
 * @param opt_flags Find only options with all the specified flags set (AV_OPT_FLAG).
 * @param search_flags A combination of AV_OPT_SEARCH_*.
 *
 * @return A pointer to the option found, or NULL if no option
 *         was found.
 *
 * @note Options found with AV_OPT_SEARCH_CHILDREN flag may not be settable
 * directly with av_set_string3(). Use special calls which take an options
 * AVDictionary (e.g. avformat_open_input()) to set options found with this
 * flag.
 *)
  Tav_opt_findProc = function(obj: Pointer; const name, unit_: PAnsiChar;
                            opt_flags, search_flags: Integer): PAVOption; cdecl;

(**
 * Look for an option in an object. Consider only options which
 * have all the specified flags set.
 *
 * @param[in] obj A pointer to a struct whose first element is a
 *                pointer to an AVClass.
 *                Alternatively a double pointer to an AVClass, if
 *                AV_OPT_SEARCH_FAKE_OBJ search flag is set.
 * @param[in] name The name of the option to look for.
 * @param[in] unit When searching for named constants, name of the unit
 *                 it belongs to.
 * @param opt_flags Find only options with all the specified flags set (AV_OPT_FLAG).
 * @param search_flags A combination of AV_OPT_SEARCH_*.
 * @param[out] target_obj if non-NULL, an object to which the option belongs will be
 * written here. It may be different from obj if AV_OPT_SEARCH_CHILDREN is present
 * in search_flags. This parameter is ignored if search_flags contain
 * AV_OPT_SEARCH_FAKE_OBJ.
 *
 * @return A pointer to the option found, or NULL if no option
 *         was found.
 *)
  Tav_opt_find2Proc = function(obj: Pointer; const name, unit_: PAnsiChar;
                              opt_flags, search_flags: Integer; target_obj: PPointer): PAVOption; cdecl;

(**
 * Iterate over all AVOptions belonging to obj.
 *
 * @param obj an AVOptions-enabled struct or a double pointer to an
 *            AVClass describing it.
 * @param prev result of the previous call to av_opt_next() on this object
 *             or NULL
 * @return next AVOption or NULL
 *)
  Tav_opt_nextProc = function(obj: Pointer; const prev: PAVOption): PAVOption; cdecl;

(**
 * Iterate over AVOptions-enabled children of obj.
 *
 * @param prev result of a previous call to this function or NULL
 * @return next AVOptions-enabled child or NULL
 *)
  Tav_opt_child_nextProc = procedure(obj, prev: Pointer); cdecl;

(**
 * Iterate over potential AVOptions-enabled children of parent.
 *
 * @param prev result of a previous call to this function or NULL
 * @return AVClass corresponding to next potential child or NULL
 *)
  Tav_opt_child_class_nextProc = function(const parent, prev: Pointer{PAVClass}): Pointer{PAVClass}; cdecl;

(**
 * @defgroup opt_set_funcs Option setting functions
 * @{
 * Those functions set the field of obj with the given name to value.
 *
 * @param[in] obj A struct whose first element is a pointer to an AVClass.
 * @param[in] name the name of the field to set
 * @param[in] val The value to set. In case of av_opt_set() if the field is not
 * of a string type, then the given string is parsed.
 * SI postfixes and some named scalars are supported.
 * If the field is of a numeric type, it has to be a numeric or named
 * scalar. Behavior with more than one scalar and +- infix operators
 * is undefined.
 * If the field is of a flags type, it has to be a sequence of numeric
 * scalars or named flags separated by '+' or '-'. Prefixing a flag
 * with '+' causes it to be set without affecting the other flags;
 * similarly, '-' unsets a flag.
 * @param search_flags flags passed to av_opt_find2. I.e. if AV_OPT_SEARCH_CHILDREN
 * is passed here, then the option may be set on a child of obj.
 *
 * @return 0 if the value has been set, or an AVERROR code in case of
 * error:
 * AVERROR_OPTION_NOT_FOUND if no matching option exists
 * AVERROR(ERANGE) if the value is out of range
 * AVERROR(EINVAL) if the value is not valid
 *)
  Tav_opt_setProc        = function(obj: Pointer; const name: PAnsiChar; val: PAnsiChar;   search_flags: Integer): Integer; cdecl;
  Tav_opt_set_intProc    = function(obj: Pointer; const name: PAnsiChar; val: Int64;       search_flags: Integer): Integer; cdecl;
  Tav_opt_set_doubleProc = function(obj: Pointer; const name: PAnsiChar; val: Double;      search_flags: Integer): Integer; cdecl;
  Tav_opt_set_qProc      = function(obj: Pointer; const name: PAnsiChar; val: TAVRational; search_flags: Integer): Integer; cdecl;
  Tav_opt_set_binProc    = function(obj: Pointer; const name: PAnsiChar; val: PByte; size, search_flags: Integer): Integer; cdecl;
  Tav_opt_set_image_sizeProc = function(obj: Pointer; const name: PAnsiChar; w, h, search_flags: Integer): Integer; cdecl;
  Tav_opt_set_pixel_fmtProc  = function(obj: Pointer; const name: PAnsiChar; fmt: TAVPixelFormat; search_flags: Integer): Integer; cdecl;
  Tav_opt_set_sample_fmtProc = function(obj: Pointer; const name: PAnsiChar; fmt: TAVPixelFormat; search_flags: Integer): Integer; cdecl;
  Tav_opt_set_video_rateProc = function(obj: Pointer; const name: PAnsiChar; val: TAVRational; search_flags: Integer): Integer; cdecl;
  Tav_opt_set_channel_layoutProc = function(obj: Pointer; const name: PAnsiChar; ch_layout: Int64; search_flags: Integer): Integer; cdecl;

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
//#define av_opt_set_int_list(obj, name, val, term, flags) \
//    (av_int_list_length(val, term) > INT_MAX / sizeof(*(val)) ? \
//     AVERROR(EINVAL) : \
//     av_opt_set_bin(obj, name, (const uint8_t *)(val), \
//                    av_int_list_length(val, term) * sizeof(*(val)), flags))
(**
 * @}
 *)

(**
 * @defgroup opt_get_funcs Option getting functions
 * @{
 * Those functions get a value of the option with the given name from an object.
 *
 * @param[in] obj a struct whose first element is a pointer to an AVClass.
 * @param[in] name name of the option to get.
 * @param[in] search_flags flags passed to av_opt_find2. I.e. if AV_OPT_SEARCH_CHILDREN
 * is passed here, then the option may be found in a child of obj.
 * @param[out] out_val value of the option will be written here
 * @return >=0 on success, a negative error code otherwise
 *)
(**
 * @note the returned string will be av_malloc()ed and must be av_free()ed by the caller
 *)
  Tav_opt_getProc        = function(obj: Pointer; const name: PAnsiChar; search_flags: Integer; out_val: PPByte)     : Integer; cdecl;
  Tav_opt_get_intProc    = function(obj: Pointer; const name: PAnsiChar; search_flags: Integer; out_val: PInt64)     : Integer; cdecl;
  Tav_opt_get_doubleProc = function(obj: Pointer; const name: PAnsiChar; search_flags: Integer; out_val: PDouble)    : Integer; cdecl;
  Tav_opt_get_qProc      = function(obj: Pointer; const name: PAnsiChar; search_flags: Integer; out_val: PAVRational): Integer; cdecl;
  Tav_opt_get_image_sizeProc = function(obj: Pointer; const name: PAnsiChar; search_flags: Integer; w_out, h_out: PInteger): Integer; cdecl;
  Tav_opt_get_pixel_fmtProc  = function(obj: Pointer; const name: PAnsiChar; search_flags: Integer; out_fmt: PAVPixelFormat): Integer; cdecl;
  Tav_opt_get_sample_fmtProc = function(obj: Pointer; const name: PAnsiChar; search_flags: Integer; out_fmt: PAVPixelFormat): Integer; cdecl;
  Tav_opt_get_video_rateProc = function(obj: Pointer; const name: PAnsiChar; search_flags: Integer; out_val: PAVRational): Integer; cdecl;
  Tav_opt_get_channel_layoutProc = function(obj: Pointer; const name: PAnsiChar; search_flags: Integer; ch_layout: PInt64): Integer; cdecl;
(**
 * @}
 *)
(**
 * Gets a pointer to the requested field in a struct.
 * This function allows accessing a struct even when its fields are moved or
 * renamed since the application making the access has been compiled,
 *
 * @returns a pointer to the field, it can be cast to the correct type and read
 *          or written to.
 *)
  Tav_opt_ptrProc = function(const avclass: Pointer{PAVClass}; obj: Pointer; const name: PAnsiChar): Pointer; cdecl;

(**
 * Free an AVOptionRanges struct and set it to NULL.
 *)
  Tav_opt_freep_rangesProc = procedure(ranges: PPAVOptionRanges); cdecl;

(**
 * Get a list of allowed ranges for the given option.
 *
 * The returned list may depend on other fields in obj like for example profile.
 *
 * @param flags is a bitmask of flags, undefined flags should not be set and should be ignored
 *              AV_OPT_SEARCH_FAKE_OBJ indicates that the obj is a double pointer to a AVClass instead of a full instance
 *
 * The result must be freed with av_opt_freep_ranges.
 *
 * @return >= 0 on success, a negative errro code otherwise
 *)
  Tav_opt_query_rangesProc = function(ranges: PPAVOptionRanges; obj: Pointer; const key: PAnsiChar; flags: Integer): Integer; cdecl;

(**
 * Get a default list of allowed ranges for the given option.
 *
 * This list is constructed without using the AVClass.query_ranges() callback
 * and can be used as fallback from within the callback.
 *
 * @param flags is a bitmask of flags, undefined flags should not be set and should be ignored
 *              AV_OPT_SEARCH_FAKE_OBJ indicates that the obj is a double pointer to a AVClass instead of a full instance
 *
 * The result must be freed with av_opt_free_ranges.
 *
 * @return >= 0 on success, a negative errro code otherwise
 *)
  Tav_opt_query_ranges_defaultProc = function(ranges: PPAVOptionRanges; obj: Pointer; const key: PAnsiChar; flags: Integer): Integer; cdecl;

(**
 * @}
 *)

implementation

end.
