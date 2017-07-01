(*
 * copyright (c) 2005-2012 Michael Niedermayer <michaelni@gmx.at>
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
 * Original file: libavutil/mathematics.h
 * Ported by CodeCoolie@CNSW 2008/03/29 -> $Date:: 2013-02-05 #$
 *)

unit libavutil_mathematics;

interface

{$I CompilerDefines.inc}

uses
  libavutil_rational;

{$I libversion.inc}

const
  M_E            = 2.7182818284590452354;   (* e *)
  {$EXTERNALSYM M_E}
  M_LN2          = 0.69314718055994530942;  (* log_e 2 *)
  {$EXTERNALSYM M_LN2}
  M_LN10         = 2.30258509299404568402;  (* log_e 10 *)
  {$EXTERNALSYM M_LN10}
  M_LOG2_10      = 3.32192809488736234787;  (* log_2 10 *)
  {$EXTERNALSYM M_PHI}
  M_PHI          = 1.61803398874989484820;  (* phi / golden ratio *)
  {$EXTERNALSYM M_LOG2_10}
  M_PI           = 3.14159265358979323846;  (* pi *)
  {$EXTERNALSYM M_PI}
  M_SQRT1_2      = 0.70710678118654752440;  (* 1/sqrt(2) *)
  {$EXTERNALSYM M_SQRT1_2}
  M_SQRT2        = 1.41421356237309504880;  (* sqrt(2) *)
  {$EXTERNALSYM M_SQRT2}
//#ifndef NAN
//#define NAN            av_int2float(0x7fc00000)
//#endif
//#ifndef INFINITY
//#define INFINITY       av_int2float(0x7f800000)
//#endif

(**
 * @addtogroup lavu_math
 * @{
 *)

type
  TAVRounding = (
    AV_ROUND_ZERO     = 0, ///< Round toward zero
    AV_ROUND_INF      = 1, ///< Round away from zero
    AV_ROUND_DOWN     = 2, ///< Round toward -infinity
    AV_ROUND_UP       = 3, ///< Round toward +infinity
    AV_ROUND_NEAR_INF = 5, ///< Round to nearest and halfway cases away from zero
    AV_ROUND_PASS_MINMAX = 8192 ///< Flag to pass INT64_MIN/MAX through instead of rescaling, this avoids special cases for AV_NOPTS_VALUE
  );

(**
 * Return the greatest common divisor of a and b.
 * If both a and b are 0 or either or both are <0 then behavior is
 * undefined.
 *)
  Tav_gcdProc = function(a, b: Int64): Int64; cdecl;

(**
 * Rescale a 64-bit integer with rounding to nearest.
 * A simple a*b/c isn't possible as it can overflow.
 *)
  Tav_rescaleProc = function(a, b, c: Int64): Int64; cdecl;

(**
 * Rescale a 64-bit integer with specified rounding.
 * A simple a*b/c isn't possible as it can overflow.
 *
 * @return rescaled value a, or if AV_ROUND_PASS_MINMAX is set and a is
 *         INT64_MIN or INT64_MAX then a is passed through unchanged.
 *)
  Tav_rescale_rndProc = function(a, b, c: Int64; r: TAVRounding): Int64; cdecl;

(**
 * Rescale a 64-bit integer by 2 rational numbers.
 *)
  Tav_rescale_qProc = function(a: Int64; bq, cq: TAVRational): Int64; cdecl;

(**
 * Rescale a 64-bit integer by 2 rational numbers with specified rounding.
 *
 * @return rescaled value a, or if AV_ROUND_PASS_MINMAX is set and a is
 *         INT64_MIN or INT64_MAX then a is passed through unchanged.
 *)
  Tav_rescale_q_rndProc = function(a: Int64; bq, cq: TAVRational;
                            r: TAVRounding): Int64; cdecl;

(**
 * Compare 2 timestamps each in its own timebases.
 * The result of the function is undefined if one of the timestamps
 * is outside the int64_t range when represented in the others timebase.
 * @return -1 if ts_a is before ts_b, 1 if ts_a is after ts_b or 0 if they represent the same position
 *)
  Tav_compare_tsProc = function(ts_a: Int64; tb_a: TAVRational; ts_b: Int64; tb_b: TAVRational): Integer; cdecl;

(**
 * Compare 2 integers modulo mod.
 * That is we compare integers a and b for which only the least
 * significant log2(mod) bits are known.
 *
 * @param mod must be a power of 2
 * @return a negative value if a is smaller than b
 *         a positive value if a is greater than b
 *         0                if a equals          b
 *)
  Tav_compare_modProc = function(a, b, mod_: Int64): Int64; cdecl;

(**
 * Rescale a timestamp while preserving known durations.
 *
 * @param in_ts Input timestamp
 * @param in_tb Input timesbase
 * @param fs_tb Duration and *last timebase
 * @param duration duration till the next call
 * @param out_tb Output timesbase
 *)
  Tav_rescale_deltaProc = function(in_tb: TAVRational; in_ts: Int64; fs_tb: TAVRational; duration: Integer; last: PInt64; out_tb: TAVRational): Int64; cdecl;

(**
 * @}
 *)

implementation

end.
