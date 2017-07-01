(*
 * Rational numbers
 * Copyright (c) 2003 Michael Niedermayer <michaelni@gmx.at>
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
 * Original file: libavutil/rational.h
 * Ported by CodeCoolie@CNSW 2008/03/18 -> $Date:: 2013-11-18 #$
 *)

unit libavutil_rational;

interface

{$I CompilerDefines.inc}

{$I libversion.inc}

(**
 * @file
 * rational numbers
 * @author Michael Niedermayer <michaelni@gmx.at>
 *)

(**
 * @addtogroup lavu_math
 * @{
 *)

(**
 * rational number numerator/denominator
 *)
type
  PAVRational = ^TAVRational;
  TAVRational = record
    num: Integer; ///< numerator
    den: Integer; ///< denominator
  end;

(**
 * Reduce a fraction.
 * This is useful for framerate calculations.
 * @param dst_num destination numerator
 * @param dst_den destination denominator
 * @param num source numerator
 * @param den source denominator
 * @param max the maximum allowed for dst_num & dst_den
 * @return 1 if exact, 0 otherwise
 *)
  Tav_reduceProc = function(dst_num, dst_den: PInteger; num, den, max: Int64): Integer; cdecl;

(**
 * Multiply two rationals.
 * @param b first rational
 * @param c second rational
 * @return b*c
 *)
//TODO: API returen record  Tav_mul_qProc = function(b, c: TAVRational): TAVRational; cdecl;

(**
 * Divide one rational by another.
 * @param b first rational
 * @param c second rational
 * @return b/c
 *)
//TODO: API returen record  Tav_div_qProc = function(b, c: TAVRational): TAVRational; cdecl;

(**
 * Add two rationals.
 * @param b first rational
 * @param c second rational
 * @return b+c
 *)
//TODO: API returen record  Tav_add_qProc = function(b, c: TAVRational): TAVRational; cdecl;

(**
 * Subtract one rational from another.
 * @param b first rational
 * @param c second rational
 * @return b-c
 *)
//TODO: API returen record  Tav_sub_qProc = function(b, c: TAVRational): TAVRational; cdecl;

(**
 * Invert a rational.
 * @param q value
 * @return 1 / q
 *)
//static av_always_inline AVRational av_inv_q(AVRational q)
//{
//    AVRational r = { q.den, q.num };
//    return r;
//}

(**
 * Convert a double precision floating point number to a rational.
 * inf is expressed as {1,0} or {-1,0} depending on the sign.
 *
 * @param d double to convert
 * @param max the maximum allowed numerator and denominator
 * @return (AVRational) d
 *)
//TODO: API returen record  Tav_d2qProc = function(d: Double; max: Integer): TAVRational; cdecl;

(**
 * @return 1 if q1 is nearer to q than q2, -1 if q2 is nearer
 * than q1, 0 if they have the same distance.
 *)
  Tav_nearer_qProc = function(q, q1, q2: TAVRational): Integer; cdecl;

(**
 * Find the nearest value in q_list to q.
 * @param q_list an array of rationals terminated by {0, 0}
 * @return the index of the nearest value found in the array
 *)
  Tav_find_nearest_q_idxProc = function(q: TAVRational; const q_list: PAVRational): Integer; cdecl;

(**
 * @}
 *)

function av_cmp_q(a, b: TAVRational): Integer; {$IFDEF USE_INLINE}inline;{$ENDIF}
function av_q2d(a: TAVRational): Double; {$IFDEF USE_INLINE}inline;{$ENDIF}

implementation

(**
 * Compare two rationals.
 * @param a first rational
 * @param b second rational
 * @return 0 if a==b, 1 if a>b, -1 if a<b, and INT_MIN if one of the
 * values is of the form 0/0
 *)
function av_cmp_q(a, b: TAVRational): Integer;
var
  tmp: Int64;
begin
(*
  const int64_t tmp= a.num * (int64_t)b.den - b.num * (int64_t)a.den;
  if(tmp) return (int)((tmp ^ a.den ^ b.den)>>63)|1;
  else if(b.den && a.den) return 0;
  else if(a.num && b.num) return (a.num>>31) - (b.num>>31);
  else                    return INT_MIN;
*)
  tmp := a.num * Int64(b.den) - b.num * Int64(a.den);
  if tmp <> 0 then
  begin
    tmp := tmp xor a.den xor b.den;
    if tmp > 0 then
      Result := 1
    else if tmp < 0 then
      Result := -1
    else
      Result := 1;
  end
  else if (b.den <> 0) and (a.den <> 0) then
    Result := 0
  else if (a.num <> 0) and (b.num <> 0) then
  begin
    if a.num > 0 then
    begin
      if b.num > 0 then
        Result := 0
      else
        Result := 1;
    end
    else
    begin
      if b.num > 0 then
        Result := 1
      else
        Result := 0;
    end;
  end
  else
    Result := Low(Integer);
end;

(**
 * Convert rational to double.
 * @param a rational to convert
 * @return (double) a
 *)
function av_q2d(a: TAVRational): Double;
begin
  Result := a.num / a.den;
end;

end.
