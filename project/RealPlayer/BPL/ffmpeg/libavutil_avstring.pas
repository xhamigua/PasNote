(*
 * Copyright (c) 2007 Mans Rullgard
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
 * Original file: libavutil/avstring.h
 * Ported by CodeCoolie@CNSW 2008/03/26 -> $Date:: 2013-11-18 #$
 *)

unit libavutil_avstring;

interface

{$I CompilerDefines.inc}

{$I libversion.inc}

(**
 * @addtogroup lavu_string
 * @{
 *)

(**
 * Return non-zero if pfx is a prefix of str. If it is, *ptr is set to
 * the address of the first character in str after the prefix.
 *
 * @param str input string
 * @param pfx prefix to test
 * @param ptr updated if the prefix is matched inside str
 * @return non-zero if the prefix matches, zero otherwise
 *)
type
  Tav_strstartProc = function(const str, pfx: PAnsiChar; const ptr: PPAnsiChar): Integer; cdecl;

(**
 * Return non-zero if pfx is a prefix of str independent of case. If
 * it is, *ptr is set to the address of the first character in str
 * after the prefix.
 *
 * @param str input string
 * @param pfx prefix to test
 * @param ptr updated if the prefix is matched inside str
 * @return non-zero if the prefix matches, zero otherwise
 *)
  Tav_stristartProc = function(const str, pfx: PAnsiChar; const ptr: PPAnsiChar): Integer; cdecl;

(**
 * Locate the first case-independent occurrence in the string haystack
 * of the string needle.  A zero-length string needle is considered to
 * match at the start of haystack.
 *
 * This function is a case-insensitive version of the standard strstr().
 *
 * @param haystack string to search in
 * @param needle   string to search for
 * @return         pointer to the located match within haystack
 *                 or a null pointer if no match
 *)
  Tav_stristrProc = function(const haystack, needle: PAnsiChar): PAnsiChar; cdecl;

(**
 * Locate the first occurrence of the string needle in the string haystack
 * where not more than hay_length characters are searched. A zero-length
 * string needle is considered to match at the start of haystack.
 *
 * This function is a length-limited version of the standard strstr().
 *
 * @param haystack   string to search in
 * @param needle     string to search for
 * @param hay_length length of string to search in
 * @return           pointer to the located match within haystack
 *                   or a null pointer if no match
 *)
  Tav_strnstrProc = function(const haystack, needle: PAnsiChar; hay_length: Cardinal): PAnsiChar; cdecl;

(**
 * Copy the string src to dst, but no more than size - 1 bytes, and
 * null-terminate dst.
 *
 * This function is the same as BSD strlcpy().
 *
 * @param dst destination buffer
 * @param src source string
 * @param size size of destination buffer
 * @return the length of src
 *
 * @warning since the return value is the length of src, src absolutely
 * _must_ be a properly 0-terminated string, otherwise this will read beyond
 * the end of the buffer and possibly crash.
 *)
  Tav_strlcpyProc = function(dst: PAnsiChar; const src: PAnsiChar; size: Cardinal{size_t}): Cardinal{size_t}; cdecl;

(**
 * Append the string src to the string dst, but to a total length of
 * no more than size - 1 bytes, and null-terminate dst.
 *
 * This function is similar to BSD strlcat(), but differs when
 * size <= strlen(dst).
 *
 * @param dst destination buffer
 * @param src source string
 * @param size size of destination buffer
 * @return the total length of src and dst
 *
 * @warning since the return value use the length of src and dst, these
 * absolutely _must_ be a properly 0-terminated strings, otherwise this
 * will read beyond the end of the buffer and possibly crash.
 *)
  Tav_strlcatProc = function(dst: PAnsiChar; const src: PAnsiChar; size: Cardinal{size_t}): Cardinal{size_t}; cdecl;

(**
 * Append output to a string, according to a format. Never write out of
 * the destination buffer, and and always put a terminating 0 within
 * the buffer.
 * @param dst destination buffer (string to which the output is
 *  appended)
 * @param size total size of the destination buffer
 * @param fmt printf-compatible format string, specifying how the
 *  following parameters are used
 * @return the length of the string that would have been generated
 *  if enough space had been available
 *)
  //size_t av_strlcatf(char *dst, size_t size, const char *fmt, ...) av_printf_format(3, 4);
  Tav_strlcatfProc = function(dst: PAnsiChar; size: Cardinal{size_t}; const fmt: PAnsiChar): Cardinal{size_t}; cdecl varargs;

(**
 * Print arguments following specified format into a large enough auto
 * allocated buffer. It is similar to GNU asprintf().
 * @param fmt printf-compatible format string, specifying how the
 *            following parameters are used.
 * @return the allocated string
 * @note You have to free the string yourself with av_free().
 *)
  //char *av_asprintf(const char *fmt, ...) av_printf_format(1, 2);
  Tav_asprintfProc = function(const fmt: PAnsiChar): PAnsiChar; cdecl varargs;

(**
 * Convert a number to a av_malloced string.
 *)
  Tav_d2strProc = function(d: Double): PAnsiChar; cdecl;

(**
 * Unescape the given string until a non escaped terminating char,
 * and return the token corresponding to the unescaped string.
 *
 * The normal \ and ' escaping is supported. Leading and trailing
 * whitespaces are removed, unless they are escaped with '\' or are
 * enclosed between ''.
 *
 * @param buf the buffer to parse, buf will be updated to point to the
 * terminating char
 * @param term a 0-terminated list of terminating chars
 * @return the malloced unescaped string, which must be av_freed by
 * the user, NULL in case of allocation failure
 *)
  Tav_get_tokenProc = function(const buf: PPAnsiChar; const term: PAnsiChar): PAnsiChar; cdecl;

(**
 * Split the string into several tokens which can be accessed by
 * successive calls to av_strtok().
 *
 * A token is defined as a sequence of characters not belonging to the
 * set specified in delim.
 *
 * On the first call to av_strtok(), s should point to the string to
 * parse, and the value of saveptr is ignored. In subsequent calls, s
 * should be NULL, and saveptr should be unchanged since the previous
 * call.
 *
 * This function is similar to strtok_r() defined in POSIX.1.
 *
 * @param s the string to parse, may be NULL
 * @param delim 0-terminated list of token delimiters, must be non-NULL
 * @param saveptr user-provided pointer which points to stored
 * information necessary for av_strtok() to continue scanning the same
 * string. saveptr is updated to point to the next character after the
 * first delimiter found, or to NULL if the string was terminated
 * @return the found token, or NULL when no token is found
 *)
  Tav_strtokProc = function(s: PAnsiChar; const delim: PAnsiChar; saveptr: PPAnsiChar): PAnsiChar; cdecl;

(**
 * Locale-independent conversion of ASCII isdigit.
 *)
  Tav_isdigitProc = function(c: Integer): Integer; cdecl;

(**
 * Locale-independent conversion of ASCII isgraph.
 *)
  Tav_isgraphProc = function(c: Integer): Integer; cdecl;

(**
 * Locale-independent conversion of ASCII isspace.
 *)
  Tav_isspaceProc = function(c: Integer): Integer; cdecl;

(**
 * Locale-independent conversion of ASCII characters to uppercase.
 *)
//static inline int av_toupper(int c)
{
    if (c >= 'a' && c <= 'z')
        c ^= 0x20;
    return c;
}

(**
 * Locale-independent conversion of ASCII characters to lowercase.
 *)
//static inline int av_tolower(int c)
{
    if (c >= 'A' && c <= 'Z')
        c ^= 0x20;
    return c;
}

(**
 * Locale-independent conversion of ASCII isxdigit.
 *)
  Tav_isxdigitProc = function(c: Integer): Integer; cdecl;

(**
 * Locale-independent case-insensitive compare.
 * @note This means only ASCII-range characters are case-insensitive
 *)
  Tav_strcasecmpProc = function(const a, b: PAnsiChar): Integer; cdecl;

(**
 * Locale-independent case-insensitive compare.
 * @note This means only ASCII-range characters are case-insensitive
 *)
  Tav_strncasecmpProc = function(const a, b: PAnsiChar; n: Cardinal{size_t}): Integer; cdecl;


(**
 * Thread safe basename.
 * @param path the path, on DOS both \ and / are considered separators.
 * @return pointer to the basename substring.
 *)
  Tav_basenameProc = function(const path: PAnsiChar): PAnsiChar; cdecl;

(**
 * Thread safe dirname.
 * @param path the path, on DOS both \ and / are considered separators.
 * @return the path with the separator replaced by the string terminator or ".".
 * @note the function may change the input string.
 *)
  Tav_dirnameProc = function(path: PAnsiChar): PAnsiChar; cdecl;

  TAVEscapeMode = (
    AV_ESCAPE_MODE_AUTO,      ///< Use auto-selected escaping mode.
    AV_ESCAPE_MODE_BACKSLASH, ///< Use backslash escaping.
    AV_ESCAPE_MODE_QUOTE      ///< Use single-quote escaping.
  );

(**
 * Consider spaces special and escape them even in the middle of the
 * string.
 *
 * This is equivalent to adding the whitespace characters to the special
 * characters lists, except it is guaranteed to use the exact same list
 * of whitespace characters as the rest of libavutil.
 *)
const
  AV_ESCAPE_FLAG_WHITESPACE = $01;

(**
 * Escape only specified special characters.
 * Without this flag, escape also any characters that may be considered
 * special by av_get_token(), such as the single quote.
 *)
  AV_ESCAPE_FLAG_STRICT = $02;

type
(**
 * Escape string in src, and put the escaped string in an allocated
 * string in *dst, which must be freed with av_free().
 *
 * @param dst           pointer where an allocated string is put
 * @param src           string to escape, must be non-NULL
 * @param special_chars string containing the special characters which
 *                      need to be escaped, can be NULL
 * @param mode          escape mode to employ, see AV_ESCAPE_MODE_* macros.
 *                      Any unknown value for mode will be considered equivalent to
 *                      AV_ESCAPE_MODE_BACKSLASH, but this behaviour can change without
 *                      notice.
 * @param flags         flags which control how to escape, see AV_ESCAPE_FLAG_ macros
 * @return the length of the allocated string, or a negative error code in case of error
 * @see av_bprint_escape()
 *)
  Tav_escapeProc = function(dst: PAnsiChar; const src, special_chars: PAnsiChar;
                  mode: TAVEscapeMode; flags: Integer): Integer; cdecl;

(**
 * @}
 *)

implementation

end.
