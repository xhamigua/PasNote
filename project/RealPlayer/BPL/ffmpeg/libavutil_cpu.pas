(*
 * Copyright (c) 2000, 2001, 2002 Fabrice Bellard
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
 * Original file: libavutil/cpu.h
 * Ported by CodeCoolie@CNSW 2010/09/17 -> $Date:: 2013-11-18 #$
 *)

unit libavutil_cpu;

interface

{$I CompilerDefines.inc}

{$I libversion.inc}

const
  AV_CPU_FLAG_FORCE   = $80000000; (* force usage of selected flags (OR) *)

  (* lower 16 bits - CPU features *)
  AV_CPU_FLAG_MMX      =     $0001; ///< standard MMX
  AV_CPU_FLAG_MMXEXT   =     $0002; ///< SSE integer functions or AMD MMX ext
  AV_CPU_FLAG_MMX2     =     $0002; ///< SSE integer functions or AMD MMX ext
  AV_CPU_FLAG_3DNOW    =     $0004; ///< AMD 3DNOW
  AV_CPU_FLAG_SSE      =     $0008; ///< SSE functions
  AV_CPU_FLAG_SSE2     =     $0010; ///< PIV SSE2 functions
  AV_CPU_FLAG_SSE2SLOW = $40000000; ///< SSE2 supported, but usually not faster
                                    ///< than regular MMX/SSE (e.g. Core1)
  AV_CPU_FLAG_3DNOWEXT =     $0020; ///< AMD 3DNowExt
  AV_CPU_FLAG_SSE3     =     $0040; ///< Prescott SSE3 functions
  AV_CPU_FLAG_SSE3SLOW = $20000000; ///< SSE3 supported, but usually not faster
                                    ///< than regular MMX/SSE (e.g. Core1)
  AV_CPU_FLAG_SSSE3    =     $0080; ///< Conroe SSSE3 functions
  AV_CPU_FLAG_ATOM     = $10000000; ///< Atom processor, some SSSE3 instructions are slower
  AV_CPU_FLAG_SSE4     =     $0100; ///< Penryn SSE4.1 functions
  AV_CPU_FLAG_SSE42    =     $0200; ///< Nehalem SSE4.2 functions
  AV_CPU_FLAG_AVX      =     $4000; ///< AVX functions: requires OS support even if YMM registers aren't used
  AV_CPU_FLAG_XOP      =     $0400; ///< Bulldozer XOP functions
  AV_CPU_FLAG_FMA4     =     $0800; ///< Bulldozer FMA4 functions
// #if LIBAVUTIL_VERSION_MAJOR <52
  AV_CPU_FLAG_CMOV     =  $1001000; ///< supports cmov instruction
// #else
//  AV_CPU_FLAG_CMOV     =     $1000; ///< supports cmov instruction
// #endif
  AV_CPU_FLAG_AVX2     =     $8000; ///< AVX2 functions: requires OS support even if YMM registers aren't used

  AV_CPU_FLAG_ALTIVEC  =     $0001; ///< standard

  AV_CPU_FLAG_ARMV5TE  =    (1 shl 0);
  AV_CPU_FLAG_ARMV6    =    (1 shl 1);
  AV_CPU_FLAG_ARMV6T2  =    (1 shl 2);
  AV_CPU_FLAG_VFP      =    (1 shl 3);
  AV_CPU_FLAG_VFPV3    =    (1 shl 4);
  AV_CPU_FLAG_NEON     =    (1 shl 5);

type
(**
 * Return the flags which specify extensions supported by the CPU.
 * The returned value is affected by av_force_cpu_flags() if that was used
 * before. So av_get_cpu_flags() can easily be used in a application to
 * detect the enabled cpu flags.
 *)
  Tav_get_cpu_flagsProc = function: Integer; cdecl;

(**
 * Disables cpu detection and forces the specified flags.
 * -1 is a special case that disables forcing of specific flags.
 *)
  Tav_force_cpu_flagsProc = procedure(flags: Integer); cdecl;

(**
 * Set a mask on flags returned by av_get_cpu_flags().
 * This function is mainly useful for testing.
 * Please use av_force_cpu_flags() and av_get_cpu_flags() instead which are more flexible
 *
 * @warning this function is not thread safe.
 *)
  Tav_set_cpu_flags_maskProc = procedure(mask: Integer); cdecl;

(**
 * Parse CPU flags from a string.
 *
 * The returned flags contain the specified flags as well as related unspecified flags.
 *
 * This function exists only for compatibility with libav.
 * Please use av_parse_cpu_caps() when possible.
 * @return a combination of AV_CPU_* flags, negative on error.
 *)
  Tav_parse_cpu_flagsProc = function(const s: PAnsiChar): Integer; cdecl;

(**
 * @return the number of logical CPU cores present.
 *)
  Tav_cpu_countProc = function(): Integer; cdecl;

(**
 * Parse CPU caps from a string and update the given AV_CPU_* flags based on that.
 *
 * @return negative on error.
 *)
  Tav_parse_cpu_capsProc = function(flags: PCardinal; const s: PAnsiChar): Integer; cdecl;

implementation

end.