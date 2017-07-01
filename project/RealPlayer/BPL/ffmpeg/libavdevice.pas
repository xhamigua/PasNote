(*
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
 * Original file: libavdevice/avdevice.h
 * Ported by CodeCoolie@CNSW 2008/03/19 -> $Date:: 2013-01-19 #$
 *)

unit libavdevice;

interface

{$I CompilerDefines.inc}

{$I libversion.inc}

(**
 * @file
 * @ingroup lavd
 * Main libavdevice API header
 *)

(**
 * @defgroup lavd Special devices muxing/demuxing library
 * @{
 * Libavdevice is a complementary library to @ref libavf "libavformat". It
 * provides various "special" platform-specific muxers and demuxers, e.g. for
 * grabbing devices, audio capture and playback etc. As a consequence, the
 * (de)muxers in libavdevice are of the AVFMT_NOFILE type (they use their own
 * I/O functions). The filename passed to avformat_open_input() often does not
 * refer to an actually existing file, but has some special device-specific
 * meaning - e.g. for x11grab it is the display name.
 *
 * To use libavdevice, simply call avdevice_register_all() to register all
 * compiled muxers and demuxers. They all use standard libavformat API.
 * @}
 *)

type
(**
 * Return the LIBAVDEVICE_VERSION_INT constant.
 *)
  Tavdevice_versionProc = function: Cardinal; cdecl;

(**
 * Return the libavdevice build-time configuration.
 *)
  Tavdevice_configurationProc = function: PAnsiChar; cdecl;

(**
 * Return the libavdevice license.
 *)
  Tavdevice_licenseProc = function: PAnsiChar; cdecl;

(**
 * Initialize libavdevice and register all the input and output devices.
 * @warning This function is not thread safe.
 *)
  Tavdevice_register_allProc = procedure; cdecl;

implementation

end.
