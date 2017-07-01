{******************************************************************************}
{                                                                              }
{          JEDI-SDL: Pascal units for SDL - Simple DirectMedia Layer           }
{             Conversion of the Simple DirectMedia Layer Headers               }
{                                                                              }
{ Portions created by Sam Lantinga <slouken@devolution.com> are                }
{ Copyright (C) 1997-2004  Sam Lantinga                                        }
{ 5635-34 Springhouse Dr.                                                      }
{ Pleasanton, CA 94588 (USA)                                                   }
{                                                                              }
{ All Rights Reserved.                                                         }
{                                                                              }
{ The initial developer of this Pascal code was:                               }
{ Dominique Louis <Dominique@SavageSoftware.com.au>                            }
{                                                                              }
{ Portions created by Dominique Louis are                                      }
{ Copyright (C) 2000 - 2004 Dominique Louis.                                   }
{                                                                              }
{******************************************************************************}

(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * Original file: sdl.pas
 * Reduced by CodeCoolie@CNSW 2009/01/12 -> $Date:: 2013-06-06 #$
 *)

unit libsdl;

interface

{$I CompilerDefines.inc}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  {$IFDEF MSWINDOWS}
    Winapi.Windows,
  {$ENDIF}
  {$IFDEF POSIX}
    System.Types, // for DWORD
  {$ENDIF}
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
{$ELSE}
  Windows,
  SysUtils,
  Classes,
  SyncObjs,
{$ENDIF}

  MyUtils;

const
{$IFDEF MSWINDOWS}
  SDLLibName = 'SDL.dll';
{$ENDIF}
{$IFDEF POSIX}
  SDLLibName = 'libSDL.dylib';
{$ENDIF}

  // SDL_verion.h constants
  // Printable format: "%d.%d.%d", MAJOR, MINOR, PATCHLEVEL
  SDL_MAJOR_VERSION = 1;
{$EXTERNALSYM SDL_MAJOR_VERSION}
  SDL_MINOR_VERSION = 2;
{$EXTERNALSYM SDL_MINOR_VERSION}
  SDL_PATCHLEVEL    = 13;
{$EXTERNALSYM SDL_PATCHLEVEL}

  // SDL.h constants
  SDL_INIT_TIMER = $00000001;
{$EXTERNALSYM SDL_INIT_TIMER}
  SDL_INIT_AUDIO = $00000010;
{$EXTERNALSYM SDL_INIT_AUDIO}
  SDL_INIT_VIDEO = $00000020;
{$EXTERNALSYM SDL_INIT_VIDEO}
  SDL_INIT_CDROM = $00000100;
{$EXTERNALSYM SDL_INIT_CDROM}
  SDL_INIT_JOYSTICK = $00000200;
{$EXTERNALSYM SDL_INIT_JOYSTICK}
  SDL_INIT_NOPARACHUTE = $00100000; // Don't catch fatal signals
{$EXTERNALSYM SDL_INIT_NOPARACHUTE}
  SDL_INIT_EVENTTHREAD = $01000000; // Not supported on all OS's
{$EXTERNALSYM SDL_INIT_EVENTTHREAD}
  SDL_INIT_EVERYTHING = $0000FFFF;
{$EXTERNALSYM SDL_INIT_EVERYTHING}

  // SDL_error.h constants
  ERR_MAX_STRLEN = 128;
{$EXTERNALSYM ERR_MAX_STRLEN}
  ERR_MAX_ARGS = 5;
{$EXTERNALSYM ERR_MAX_ARGS}

  // SDL_types.h constants
  SDL_PRESSED = $01;
{$EXTERNALSYM SDL_PRESSED}
  SDL_RELEASED = $00;
{$EXTERNALSYM SDL_RELEASED}

  // SDL_timer.h constants
  // This is the OS scheduler timeslice, in milliseconds
  SDL_TIMESLICE = 10;
{$EXTERNALSYM SDL_TIMESLICE}
  // This is the maximum resolution of the SDL timer on all platforms
  TIMER_RESOLUTION = 10; // Experimentally determined
{$EXTERNALSYM TIMER_RESOLUTION}

  // SDL_audio.h constants
  AUDIO_U8 = $0008; // Unsigned 8-bit samples
{$EXTERNALSYM AUDIO_U8}
  AUDIO_S8 = $8008; // Signed 8-bit samples
{$EXTERNALSYM AUDIO_S8}
  AUDIO_U16LSB = $0010; // Unsigned 16-bit samples
{$EXTERNALSYM AUDIO_U16LSB}
  AUDIO_S16LSB = $8010; // Signed 16-bit samples
{$EXTERNALSYM AUDIO_S16LSB}
  AUDIO_U16MSB = $1010; // As above, but big-endian byte order
{$EXTERNALSYM AUDIO_U16MSB}
  AUDIO_S16MSB = $9010; // As above, but big-endian byte order
{$EXTERNALSYM AUDIO_S16MSB}
  AUDIO_U16 = AUDIO_U16LSB;
{$EXTERNALSYM AUDIO_U16}
  AUDIO_S16 = AUDIO_S16LSB;
{$EXTERNALSYM AUDIO_S16}


  // SDL_cdrom.h constants
  // The maximum number of CD-ROM tracks on a disk
  SDL_MAX_TRACKS = 99;
{$EXTERNALSYM SDL_MAX_TRACKS}
  // The types of CD-ROM track possible
  SDL_AUDIO_TRACK = $00;
{$EXTERNALSYM SDL_AUDIO_TRACK}
  SDL_DATA_TRACK = $04;
{$EXTERNALSYM SDL_DATA_TRACK}

  // Conversion functions from frames to Minute/Second/Frames and vice versa
  CD_FPS = 75;
{$EXTERNALSYM CD_FPS}
  // SDL_byteorder.h constants
  // The two types of endianness
  SDL_LIL_ENDIAN = 1234;
{$EXTERNALSYM SDL_LIL_ENDIAN}
  SDL_BIG_ENDIAN = 4321;
{$EXTERNALSYM SDL_BIG_ENDIAN}

  SDL_BYTEORDER = SDL_LIL_ENDIAN;
{$EXTERNALSYM SDL_BYTEORDER}
  // Native audio byte ordering
  AUDIO_U16SYS = AUDIO_U16LSB;
{$EXTERNALSYM AUDIO_U16SYS}
  AUDIO_S16SYS = AUDIO_S16LSB;
{$EXTERNALSYM AUDIO_S16SYS}

  SDL_MIX_MAXVOLUME = 128;
{$EXTERNALSYM SDL_MIX_MAXVOLUME}

  // SDL_joystick.h constants
  MAX_JOYSTICKS = 2; // only 2 are supported in the multimedia API
{$EXTERNALSYM MAX_JOYSTICKS}
  MAX_AXES = 6; // each joystick can have up to 6 axes
{$EXTERNALSYM MAX_AXES}
  MAX_BUTTONS = 32; // and 32 buttons
{$EXTERNALSYM MAX_BUTTONS}
  AXIS_MIN = -32768; // minimum value for axis coordinate
{$EXTERNALSYM AXIS_MIN}
  AXIS_MAX = 32767; // maximum value for axis coordinate
{$EXTERNALSYM AXIS_MAX}
  JOY_AXIS_THRESHOLD = (((AXIS_MAX) - (AXIS_MIN)) / 100); // 1% motion
{$EXTERNALSYM JOY_AXIS_THRESHOLD}
  //JOY_BUTTON_FLAG(n)        (1<<n)
  // array to hold joystick ID values
  //static UInt        SYS_JoystickID[MAX_JOYSTICKS];
  //static JOYCAPS        SYS_Joystick[MAX_JOYSTICKS];

  { Get the current state of a POV hat on a joystick
    The return value is one of the following positions: }
  SDL_HAT_CENTERED = $00;
{$EXTERNALSYM SDL_HAT_CENTERED}
  SDL_HAT_UP = $01;
{$EXTERNALSYM SDL_HAT_UP}
  SDL_HAT_RIGHT = $02;
{$EXTERNALSYM SDL_HAT_RIGHT}
  SDL_HAT_DOWN = $04;
{$EXTERNALSYM SDL_HAT_DOWN}
  SDL_HAT_LEFT = $08;
{$EXTERNALSYM SDL_HAT_LEFT}
  SDL_HAT_RIGHTUP = SDL_HAT_RIGHT or SDL_HAT_UP;
{$EXTERNALSYM SDL_HAT_RIGHTUP}
  SDL_HAT_RIGHTDOWN = SDL_HAT_RIGHT or SDL_HAT_DOWN;
{$EXTERNALSYM SDL_HAT_RIGHTDOWN}
  SDL_HAT_LEFTUP = SDL_HAT_LEFT or SDL_HAT_UP;
{$EXTERNALSYM SDL_HAT_LEFTUP}
  SDL_HAT_LEFTDOWN = SDL_HAT_LEFT or SDL_HAT_DOWN;
{$EXTERNALSYM SDL_HAT_LEFTDOWN}

  // SDL_events.h constants
  SDL_NOEVENT = 0; // Unused (do not remove)
{$EXTERNALSYM SDL_NOEVENT}
  SDL_ACTIVEEVENT = 1; // Application loses/gains visibility
{$EXTERNALSYM SDL_ACTIVEEVENT}
  SDL_KEYDOWN = 2; // Keys pressed
{$EXTERNALSYM SDL_KEYDOWN}
  SDL_KEYUP = 3; // Keys released
{$EXTERNALSYM SDL_KEYUP}
  SDL_MOUSEMOTION = 4; // Mouse moved
{$EXTERNALSYM SDL_MOUSEMOTION}
  SDL_MOUSEBUTTONDOWN = 5; // Mouse button pressed
{$EXTERNALSYM SDL_MOUSEBUTTONDOWN}
  SDL_MOUSEBUTTONUP = 6; // Mouse button released
{$EXTERNALSYM SDL_MOUSEBUTTONUP}
  SDL_JOYAXISMOTION = 7; // Joystick axis motion
{$EXTERNALSYM SDL_JOYAXISMOTION}
  SDL_JOYBALLMOTION = 8; // Joystick trackball motion
{$EXTERNALSYM SDL_JOYBALLMOTION}
  SDL_JOYHATMOTION = 9; // Joystick hat position change
{$EXTERNALSYM SDL_JOYHATMOTION}
  SDL_JOYBUTTONDOWN = 10; // Joystick button pressed
{$EXTERNALSYM SDL_JOYBUTTONDOWN}
  SDL_JOYBUTTONUP = 11; // Joystick button released
{$EXTERNALSYM SDL_JOYBUTTONUP}
  SDL_QUITEV = 12; // User-requested quit (Changed due to procedure conflict)
{$EXTERNALSYM SDL_QUITEV}
  SDL_SYSWMEVENT = 13; // System specific event
{$EXTERNALSYM SDL_SYSWMEVENT}
  SDL_EVENT_RESERVEDA = 14; // Reserved for future use..
{$EXTERNALSYM SDL_EVENT_RESERVEDA}
  SDL_EVENT_RESERVED = 15; // Reserved for future use..
{$EXTERNALSYM SDL_EVENT_RESERVED}
  SDL_VIDEORESIZE = 16; // User resized video mode
{$EXTERNALSYM SDL_VIDEORESIZE}
  SDL_VIDEOEXPOSE = 17; // Screen needs to be redrawn
{$EXTERNALSYM SDL_VIDEOEXPOSE}
  SDL_EVENT_RESERVED2 = 18; // Reserved for future use..
{$EXTERNALSYM SDL_EVENT_RESERVED2}
  SDL_EVENT_RESERVED3 = 19; // Reserved for future use..
{$EXTERNALSYM SDL_EVENT_RESERVED3}
  SDL_EVENT_RESERVED4 = 20; // Reserved for future use..
{$EXTERNALSYM SDL_EVENT_RESERVED4}
  SDL_EVENT_RESERVED5 = 21; // Reserved for future use..
{$EXTERNALSYM SDL_EVENT_RESERVED5}
  SDL_EVENT_RESERVED6 = 22; // Reserved for future use..
{$EXTERNALSYM SDL_EVENT_RESERVED6}
  SDL_EVENT_RESERVED7 = 23; // Reserved for future use..
{$EXTERNALSYM SDL_EVENT_RESERVED7}
  // Events SDL_USEREVENT through SDL_MAXEVENTS-1 are for your use
  SDL_USEREVENT = 24;
{$EXTERNALSYM SDL_USEREVENT}
  // This last event is only for bounding internal arrays
  // It is the number of bits in the event mask datatype -- UInt32
  SDL_NUMEVENTS = 32;
{$EXTERNALSYM SDL_NUMEVENTS}

  SDL_ALLEVENTS = $FFFFFFFF;
{$EXTERNALSYM SDL_ALLEVENTS}

  SDL_ACTIVEEVENTMASK = 1 shl SDL_ACTIVEEVENT;
{$EXTERNALSYM SDL_ACTIVEEVENTMASK}
  SDL_KEYDOWNMASK = 1 shl SDL_KEYDOWN;
{$EXTERNALSYM SDL_KEYDOWNMASK}
  SDL_KEYUPMASK = 1 shl SDL_KEYUP;
{$EXTERNALSYM SDL_KEYUPMASK}
  SDL_MOUSEMOTIONMASK = 1 shl SDL_MOUSEMOTION;
{$EXTERNALSYM SDL_MOUSEMOTIONMASK}
  SDL_MOUSEBUTTONDOWNMASK = 1 shl SDL_MOUSEBUTTONDOWN;
{$EXTERNALSYM SDL_MOUSEBUTTONDOWNMASK}
  SDL_MOUSEBUTTONUPMASK = 1 shl SDL_MOUSEBUTTONUP;
{$EXTERNALSYM SDL_MOUSEBUTTONUPMASK}
  SDL_MOUSEEVENTMASK = 1 shl SDL_MOUSEMOTION or
    1 shl SDL_MOUSEBUTTONDOWN or
    1 shl SDL_MOUSEBUTTONUP;
{$EXTERNALSYM SDL_MOUSEEVENTMASK}
  SDL_JOYAXISMOTIONMASK = 1 shl SDL_JOYAXISMOTION;
{$EXTERNALSYM SDL_JOYAXISMOTIONMASK}
  SDL_JOYBALLMOTIONMASK = 1 shl SDL_JOYBALLMOTION;
{$EXTERNALSYM SDL_JOYBALLMOTIONMASK}
  SDL_JOYHATMOTIONMASK = 1 shl SDL_JOYHATMOTION;
{$EXTERNALSYM SDL_JOYHATMOTIONMASK}
  SDL_JOYBUTTONDOWNMASK = 1 shl SDL_JOYBUTTONDOWN;
{$EXTERNALSYM SDL_JOYBUTTONDOWNMASK}
  SDL_JOYBUTTONUPMASK = 1 shl SDL_JOYBUTTONUP;
{$EXTERNALSYM SDL_JOYBUTTONUPMASK}
  SDL_JOYEVENTMASK = 1 shl SDL_JOYAXISMOTION or
    1 shl SDL_JOYBALLMOTION or
    1 shl SDL_JOYHATMOTION or
    1 shl SDL_JOYBUTTONDOWN or
    1 shl SDL_JOYBUTTONUP;
{$EXTERNALSYM SDL_JOYEVENTMASK}
  SDL_VIDEORESIZEMASK = 1 shl SDL_VIDEORESIZE;
{$EXTERNALSYM SDL_VIDEORESIZEMASK}
  SDL_QUITMASK = 1 shl SDL_QUITEV;
{$EXTERNALSYM SDL_QUITMASK}
  SDL_SYSWMEVENTMASK = 1 shl SDL_SYSWMEVENT;
{$EXTERNALSYM SDL_SYSWMEVENTMASK}

  { This function allows you to set the state of processing certain events.
    If 'state' is set to SDL_IGNORE, that event will be automatically dropped
    from the event queue and will not event be filtered.
    If 'state' is set to SDL_ENABLE, that event will be processed normally.
    If 'state' is set to SDL_QUERY, SDL_EventState() will return the
    current processing state of the specified event. }

  SDL_QUERY = -1;
{$EXTERNALSYM SDL_QUERY}
  SDL_IGNORE = 0;
{$EXTERNALSYM SDL_IGNORE}
  SDL_DISABLE = 0;
{$EXTERNALSYM SDL_DISABLE}
  SDL_ENABLE = 1;
{$EXTERNALSYM SDL_ENABLE}

  //SDL_keyboard.h constants
  // This is the mask which refers to all hotkey bindings
  SDL_ALL_HOTKEYS = $FFFFFFFF;
{$EXTERNALSYM SDL_ALL_HOTKEYS}

{ Enable/Disable keyboard repeat.  Keyboard repeat defaults to off.
  'delay' is the initial delay in ms between the time when a key is
  pressed, and keyboard repeat begins.
  'interval' is the time in ms between keyboard repeat events. }

  SDL_DEFAULT_REPEAT_DELAY = 500;
{$EXTERNALSYM SDL_DEFAULT_REPEAT_DELAY}
  SDL_DEFAULT_REPEAT_INTERVAL = 30;
{$EXTERNALSYM SDL_DEFAULT_REPEAT_INTERVAL}

  // The keyboard syms have been cleverly chosen to map to ASCII
  SDLK_UNKNOWN = 0;
{$EXTERNALSYM SDLK_UNKNOWN}
  SDLK_FIRST = 0;
{$EXTERNALSYM SDLK_FIRST}
  SDLK_BACKSPACE = 8;
{$EXTERNALSYM SDLK_BACKSPACE}
  SDLK_TAB = 9;
{$EXTERNALSYM SDLK_TAB}
  SDLK_CLEAR = 12;
{$EXTERNALSYM SDLK_CLEAR}
  SDLK_RETURN = 13;
{$EXTERNALSYM SDLK_RETURN}
  SDLK_PAUSE = 19;
{$EXTERNALSYM SDLK_PAUSE}
  SDLK_ESCAPE = 27;
{$EXTERNALSYM SDLK_ESCAPE}
  SDLK_SPACE = 32;
{$EXTERNALSYM SDLK_SPACE}
  SDLK_EXCLAIM = 33;
{$EXTERNALSYM SDLK_EXCLAIM}
  SDLK_QUOTEDBL = 34;
{$EXTERNALSYM SDLK_QUOTEDBL}
  SDLK_HASH = 35;
{$EXTERNALSYM SDLK_HASH}
  SDLK_DOLLAR = 36;
{$EXTERNALSYM SDLK_DOLLAR}
  SDLK_AMPERSAND = 38;
{$EXTERNALSYM SDLK_AMPERSAND}
  SDLK_QUOTE = 39;
{$EXTERNALSYM SDLK_QUOTE}
  SDLK_LEFTPAREN = 40;
{$EXTERNALSYM SDLK_LEFTPAREN}
  SDLK_RIGHTPAREN = 41;
{$EXTERNALSYM SDLK_RIGHTPAREN}
  SDLK_ASTERISK = 42;
{$EXTERNALSYM SDLK_ASTERISK}
  SDLK_PLUS = 43;
{$EXTERNALSYM SDLK_PLUS}
  SDLK_COMMA = 44;
{$EXTERNALSYM SDLK_COMMA}
  SDLK_MINUS = 45;
{$EXTERNALSYM SDLK_MINUS}
  SDLK_PERIOD = 46;
{$EXTERNALSYM SDLK_PERIOD}
  SDLK_SLASH = 47;
{$EXTERNALSYM SDLK_SLASH}
  SDLK_0 = 48;
{$EXTERNALSYM SDLK_0}
  SDLK_1 = 49;
{$EXTERNALSYM SDLK_1}
  SDLK_2 = 50;
{$EXTERNALSYM SDLK_2}
  SDLK_3 = 51;
{$EXTERNALSYM SDLK_3}
  SDLK_4 = 52;
{$EXTERNALSYM SDLK_4}
  SDLK_5 = 53;
{$EXTERNALSYM SDLK_5}
  SDLK_6 = 54;
{$EXTERNALSYM SDLK_6}
  SDLK_7 = 55;
{$EXTERNALSYM SDLK_7}
  SDLK_8 = 56;
{$EXTERNALSYM SDLK_8}
  SDLK_9 = 57;
{$EXTERNALSYM SDLK_9}
  SDLK_COLON = 58;
{$EXTERNALSYM SDLK_COLON}
  SDLK_SEMICOLON = 59;
{$EXTERNALSYM SDLK_SEMICOLON}
  SDLK_LESS = 60;
{$EXTERNALSYM SDLK_LESS}
  SDLK_EQUALS = 61;
{$EXTERNALSYM SDLK_EQUALS}
  SDLK_GREATER = 62;
{$EXTERNALSYM SDLK_GREATER}
  SDLK_QUESTION = 63;
{$EXTERNALSYM SDLK_QUESTION}
  SDLK_AT = 64;
{$EXTERNALSYM SDLK_AT}

  { Skip uppercase letters }

  SDLK_LEFTBRACKET = 91;
{$EXTERNALSYM SDLK_LEFTBRACKET}
  SDLK_BACKSLASH = 92;
{$EXTERNALSYM SDLK_BACKSLASH}
  SDLK_RIGHTBRACKET = 93;
{$EXTERNALSYM SDLK_RIGHTBRACKET}
  SDLK_CARET = 94;
{$EXTERNALSYM SDLK_CARET}
  SDLK_UNDERSCORE = 95;
{$EXTERNALSYM SDLK_UNDERSCORE}
  SDLK_BACKQUOTE = 96;
{$EXTERNALSYM SDLK_BACKQUOTE}
  SDLK_a = 97;
{$EXTERNALSYM SDLK_a}
  SDLK_b = 98;
{$EXTERNALSYM SDLK_b}
  SDLK_c = 99;
{$EXTERNALSYM SDLK_c}
  SDLK_d = 100;
{$EXTERNALSYM SDLK_d}
  SDLK_e = 101;
{$EXTERNALSYM SDLK_e}
  SDLK_f = 102;
{$EXTERNALSYM SDLK_f}
  SDLK_g = 103;
{$EXTERNALSYM SDLK_g}
  SDLK_h = 104;
{$EXTERNALSYM SDLK_h}
  SDLK_i = 105;
{$EXTERNALSYM SDLK_i}
  SDLK_j = 106;
{$EXTERNALSYM SDLK_j}
  SDLK_k = 107;
{$EXTERNALSYM SDLK_k}
  SDLK_l = 108;
{$EXTERNALSYM SDLK_l}
  SDLK_m = 109;
{$EXTERNALSYM SDLK_m}
  SDLK_n = 110;
{$EXTERNALSYM SDLK_n}
  SDLK_o = 111;
{$EXTERNALSYM SDLK_o}
  SDLK_p = 112;
{$EXTERNALSYM SDLK_p}
  SDLK_q = 113;
{$EXTERNALSYM SDLK_q}
  SDLK_r = 114;
{$EXTERNALSYM SDLK_r}
  SDLK_s = 115;
{$EXTERNALSYM SDLK_s}
  SDLK_t = 116;
{$EXTERNALSYM SDLK_t}
  SDLK_u = 117;
{$EXTERNALSYM SDLK_u}
  SDLK_v = 118;
{$EXTERNALSYM SDLK_v}
  SDLK_w = 119;
{$EXTERNALSYM SDLK_w}
  SDLK_x = 120;
{$EXTERNALSYM SDLK_x}
  SDLK_y = 121;
{$EXTERNALSYM SDLK_y}
  SDLK_z = 122;
{$EXTERNALSYM SDLK_z}
  SDLK_DELETE = 127;
{$EXTERNALSYM SDLK_DELETE}
  // End of ASCII mapped keysyms

  // International keyboard syms
  SDLK_WORLD_0 = 160; // 0xA0
{$EXTERNALSYM SDLK_WORLD_0}
  SDLK_WORLD_1 = 161;
{$EXTERNALSYM SDLK_WORLD_1}
  SDLK_WORLD_2 = 162;
{$EXTERNALSYM SDLK_WORLD_2}
  SDLK_WORLD_3 = 163;
{$EXTERNALSYM SDLK_WORLD_3}
  SDLK_WORLD_4 = 164;
{$EXTERNALSYM SDLK_WORLD_4}
  SDLK_WORLD_5 = 165;
{$EXTERNALSYM SDLK_WORLD_5}
  SDLK_WORLD_6 = 166;
{$EXTERNALSYM SDLK_WORLD_6}
  SDLK_WORLD_7 = 167;
{$EXTERNALSYM SDLK_WORLD_7}
  SDLK_WORLD_8 = 168;
{$EXTERNALSYM SDLK_WORLD_8}
  SDLK_WORLD_9 = 169;
{$EXTERNALSYM SDLK_WORLD_9}
  SDLK_WORLD_10 = 170;
{$EXTERNALSYM SDLK_WORLD_10}
  SDLK_WORLD_11 = 171;
{$EXTERNALSYM SDLK_WORLD_11}
  SDLK_WORLD_12 = 172;
{$EXTERNALSYM SDLK_WORLD_12}
  SDLK_WORLD_13 = 173;
{$EXTERNALSYM SDLK_WORLD_13}
  SDLK_WORLD_14 = 174;
{$EXTERNALSYM SDLK_WORLD_14}
  SDLK_WORLD_15 = 175;
{$EXTERNALSYM SDLK_WORLD_15}
  SDLK_WORLD_16 = 176;
{$EXTERNALSYM SDLK_WORLD_16}
  SDLK_WORLD_17 = 177;
{$EXTERNALSYM SDLK_WORLD_17}
  SDLK_WORLD_18 = 178;
{$EXTERNALSYM SDLK_WORLD_18}
  SDLK_WORLD_19 = 179;
{$EXTERNALSYM SDLK_WORLD_19}
  SDLK_WORLD_20 = 180;
{$EXTERNALSYM SDLK_WORLD_20}
  SDLK_WORLD_21 = 181;
{$EXTERNALSYM SDLK_WORLD_21}
  SDLK_WORLD_22 = 182;
{$EXTERNALSYM SDLK_WORLD_22}
  SDLK_WORLD_23 = 183;
{$EXTERNALSYM SDLK_WORLD_23}
  SDLK_WORLD_24 = 184;
{$EXTERNALSYM SDLK_WORLD_24}
  SDLK_WORLD_25 = 185;
{$EXTERNALSYM SDLK_WORLD_25}
  SDLK_WORLD_26 = 186;
{$EXTERNALSYM SDLK_WORLD_26}
  SDLK_WORLD_27 = 187;
{$EXTERNALSYM SDLK_WORLD_27}
  SDLK_WORLD_28 = 188;
{$EXTERNALSYM SDLK_WORLD_28}
  SDLK_WORLD_29 = 189;
{$EXTERNALSYM SDLK_WORLD_29}
  SDLK_WORLD_30 = 190;
{$EXTERNALSYM SDLK_WORLD_30}
  SDLK_WORLD_31 = 191;
{$EXTERNALSYM SDLK_WORLD_31}
  SDLK_WORLD_32 = 192;
{$EXTERNALSYM SDLK_WORLD_32}
  SDLK_WORLD_33 = 193;
{$EXTERNALSYM SDLK_WORLD_33}
  SDLK_WORLD_34 = 194;
{$EXTERNALSYM SDLK_WORLD_34}
  SDLK_WORLD_35 = 195;
{$EXTERNALSYM SDLK_WORLD_35}
  SDLK_WORLD_36 = 196;
{$EXTERNALSYM SDLK_WORLD_36}
  SDLK_WORLD_37 = 197;
{$EXTERNALSYM SDLK_WORLD_37}
  SDLK_WORLD_38 = 198;
{$EXTERNALSYM SDLK_WORLD_38}
  SDLK_WORLD_39 = 199;
{$EXTERNALSYM SDLK_WORLD_39}
  SDLK_WORLD_40 = 200;
{$EXTERNALSYM SDLK_WORLD_40}
  SDLK_WORLD_41 = 201;
{$EXTERNALSYM SDLK_WORLD_41}
  SDLK_WORLD_42 = 202;
{$EXTERNALSYM SDLK_WORLD_42}
  SDLK_WORLD_43 = 203;
{$EXTERNALSYM SDLK_WORLD_43}
  SDLK_WORLD_44 = 204;
{$EXTERNALSYM SDLK_WORLD_44}
  SDLK_WORLD_45 = 205;
{$EXTERNALSYM SDLK_WORLD_45}
  SDLK_WORLD_46 = 206;
{$EXTERNALSYM SDLK_WORLD_46}
  SDLK_WORLD_47 = 207;
{$EXTERNALSYM SDLK_WORLD_47}
  SDLK_WORLD_48 = 208;
{$EXTERNALSYM SDLK_WORLD_48}
  SDLK_WORLD_49 = 209;
{$EXTERNALSYM SDLK_WORLD_49}
  SDLK_WORLD_50 = 210;
{$EXTERNALSYM SDLK_WORLD_50}
  SDLK_WORLD_51 = 211;
{$EXTERNALSYM SDLK_WORLD_51}
  SDLK_WORLD_52 = 212;
{$EXTERNALSYM SDLK_WORLD_52}
  SDLK_WORLD_53 = 213;
{$EXTERNALSYM SDLK_WORLD_53}
  SDLK_WORLD_54 = 214;
{$EXTERNALSYM SDLK_WORLD_54}
  SDLK_WORLD_55 = 215;
{$EXTERNALSYM SDLK_WORLD_55}
  SDLK_WORLD_56 = 216;
{$EXTERNALSYM SDLK_WORLD_56}
  SDLK_WORLD_57 = 217;
{$EXTERNALSYM SDLK_WORLD_57}
  SDLK_WORLD_58 = 218;
{$EXTERNALSYM SDLK_WORLD_58}
  SDLK_WORLD_59 = 219;
{$EXTERNALSYM SDLK_WORLD_59}
  SDLK_WORLD_60 = 220;
{$EXTERNALSYM SDLK_WORLD_60}
  SDLK_WORLD_61 = 221;
{$EXTERNALSYM SDLK_WORLD_61}
  SDLK_WORLD_62 = 222;
{$EXTERNALSYM SDLK_WORLD_62}
  SDLK_WORLD_63 = 223;
{$EXTERNALSYM SDLK_WORLD_63}
  SDLK_WORLD_64 = 224;
{$EXTERNALSYM SDLK_WORLD_64}
  SDLK_WORLD_65 = 225;
{$EXTERNALSYM SDLK_WORLD_65}
  SDLK_WORLD_66 = 226;
{$EXTERNALSYM SDLK_WORLD_66}
  SDLK_WORLD_67 = 227;
{$EXTERNALSYM SDLK_WORLD_67}
  SDLK_WORLD_68 = 228;
{$EXTERNALSYM SDLK_WORLD_68}
  SDLK_WORLD_69 = 229;
{$EXTERNALSYM SDLK_WORLD_69}
  SDLK_WORLD_70 = 230;
{$EXTERNALSYM SDLK_WORLD_70}
  SDLK_WORLD_71 = 231;
{$EXTERNALSYM SDLK_WORLD_71}
  SDLK_WORLD_72 = 232;
{$EXTERNALSYM SDLK_WORLD_72}
  SDLK_WORLD_73 = 233;
{$EXTERNALSYM SDLK_WORLD_73}
  SDLK_WORLD_74 = 234;
{$EXTERNALSYM SDLK_WORLD_74}
  SDLK_WORLD_75 = 235;
{$EXTERNALSYM SDLK_WORLD_75}
  SDLK_WORLD_76 = 236;
{$EXTERNALSYM SDLK_WORLD_76}
  SDLK_WORLD_77 = 237;
{$EXTERNALSYM SDLK_WORLD_77}
  SDLK_WORLD_78 = 238;
{$EXTERNALSYM SDLK_WORLD_78}
  SDLK_WORLD_79 = 239;
{$EXTERNALSYM SDLK_WORLD_79}
  SDLK_WORLD_80 = 240;
{$EXTERNALSYM SDLK_WORLD_80}
  SDLK_WORLD_81 = 241;
{$EXTERNALSYM SDLK_WORLD_81}
  SDLK_WORLD_82 = 242;
{$EXTERNALSYM SDLK_WORLD_82}
  SDLK_WORLD_83 = 243;
{$EXTERNALSYM SDLK_WORLD_83}
  SDLK_WORLD_84 = 244;
{$EXTERNALSYM SDLK_WORLD_84}
  SDLK_WORLD_85 = 245;
{$EXTERNALSYM SDLK_WORLD_85}
  SDLK_WORLD_86 = 246;
{$EXTERNALSYM SDLK_WORLD_86}
  SDLK_WORLD_87 = 247;
{$EXTERNALSYM SDLK_WORLD_87}
  SDLK_WORLD_88 = 248;
{$EXTERNALSYM SDLK_WORLD_88}
  SDLK_WORLD_89 = 249;
{$EXTERNALSYM SDLK_WORLD_89}
  SDLK_WORLD_90 = 250;
{$EXTERNALSYM SDLK_WORLD_90}
  SDLK_WORLD_91 = 251;
{$EXTERNALSYM SDLK_WORLD_91}
  SDLK_WORLD_92 = 252;
{$EXTERNALSYM SDLK_WORLD_92}
  SDLK_WORLD_93 = 253;
{$EXTERNALSYM SDLK_WORLD_93}
  SDLK_WORLD_94 = 254;
{$EXTERNALSYM SDLK_WORLD_94}
  SDLK_WORLD_95 = 255; // 0xFF
{$EXTERNALSYM SDLK_WORLD_95}

  // Numeric keypad
  SDLK_KP0 = 256;
{$EXTERNALSYM SDLK_KP0}
  SDLK_KP1 = 257;
{$EXTERNALSYM SDLK_KP1}
  SDLK_KP2 = 258;
{$EXTERNALSYM SDLK_KP2}
  SDLK_KP3 = 259;
{$EXTERNALSYM SDLK_KP3}
  SDLK_KP4 = 260;
{$EXTERNALSYM SDLK_KP4}
  SDLK_KP5 = 261;
{$EXTERNALSYM SDLK_KP5}
  SDLK_KP6 = 262;
{$EXTERNALSYM SDLK_KP6}
  SDLK_KP7 = 263;
{$EXTERNALSYM SDLK_KP7}
  SDLK_KP8 = 264;
{$EXTERNALSYM SDLK_KP8}
  SDLK_KP9 = 265;
{$EXTERNALSYM SDLK_KP9}
  SDLK_KP_PERIOD = 266;
{$EXTERNALSYM SDLK_KP_PERIOD}
  SDLK_KP_DIVIDE = 267;
{$EXTERNALSYM SDLK_KP_DIVIDE}
  SDLK_KP_MULTIPLY = 268;
{$EXTERNALSYM SDLK_KP_MULTIPLY}
  SDLK_KP_MINUS = 269;
{$EXTERNALSYM SDLK_KP_MINUS}
  SDLK_KP_PLUS = 270;
{$EXTERNALSYM SDLK_KP_PLUS}
  SDLK_KP_ENTER = 271;
{$EXTERNALSYM SDLK_KP_ENTER}
  SDLK_KP_EQUALS = 272;
{$EXTERNALSYM SDLK_KP_EQUALS}

  // Arrows + Home/End pad
  SDLK_UP = 273;
{$EXTERNALSYM SDLK_UP}
  SDLK_DOWN = 274;
{$EXTERNALSYM SDLK_DOWN}
  SDLK_RIGHT = 275;
{$EXTERNALSYM SDLK_RIGHT}
  SDLK_LEFT = 276;
{$EXTERNALSYM SDLK_LEFT}
  SDLK_INSERT = 277;
{$EXTERNALSYM SDLK_INSERT}
  SDLK_HOME = 278;
{$EXTERNALSYM SDLK_HOME}
  SDLK_END = 279;
{$EXTERNALSYM SDLK_END}
  SDLK_PAGEUP = 280;
{$EXTERNALSYM SDLK_PAGEUP}
  SDLK_PAGEDOWN = 281;
{$EXTERNALSYM SDLK_PAGEDOWN}

  // Function keys
  SDLK_F1 = 282;
{$EXTERNALSYM SDLK_F1}
  SDLK_F2 = 283;
{$EXTERNALSYM SDLK_F2}
  SDLK_F3 = 284;
{$EXTERNALSYM SDLK_F3}
  SDLK_F4 = 285;
{$EXTERNALSYM SDLK_F4}
  SDLK_F5 = 286;
{$EXTERNALSYM SDLK_F5}
  SDLK_F6 = 287;
{$EXTERNALSYM SDLK_F6}
  SDLK_F7 = 288;
{$EXTERNALSYM SDLK_F7}
  SDLK_F8 = 289;
{$EXTERNALSYM SDLK_F8}
  SDLK_F9 = 290;
{$EXTERNALSYM SDLK_F9}
  SDLK_F10 = 291;
{$EXTERNALSYM SDLK_F10}
  SDLK_F11 = 292;
{$EXTERNALSYM SDLK_F11}
  SDLK_F12 = 293;
{$EXTERNALSYM SDLK_F12}
  SDLK_F13 = 294;
{$EXTERNALSYM SDLK_F13}
  SDLK_F14 = 295;
{$EXTERNALSYM SDLK_F14}
  SDLK_F15 = 296;
{$EXTERNALSYM SDLK_F15}

  // Key state modifier keys
  SDLK_NUMLOCK = 300;
{$EXTERNALSYM SDLK_NUMLOCK}
  SDLK_CAPSLOCK = 301;
{$EXTERNALSYM SDLK_CAPSLOCK}
  SDLK_SCROLLOCK = 302;
{$EXTERNALSYM SDLK_SCROLLOCK}
  SDLK_RSHIFT = 303;
{$EXTERNALSYM SDLK_RSHIFT}
  SDLK_LSHIFT = 304;
{$EXTERNALSYM SDLK_LSHIFT}
  SDLK_RCTRL = 305;
{$EXTERNALSYM SDLK_RCTRL}
  SDLK_LCTRL = 306;
{$EXTERNALSYM SDLK_LCTRL}
  SDLK_RALT = 307;
{$EXTERNALSYM SDLK_RALT}
  SDLK_LALT = 308;
{$EXTERNALSYM SDLK_LALT}
  SDLK_RMETA = 309;
{$EXTERNALSYM SDLK_RMETA}
  SDLK_LMETA = 310;
{$EXTERNALSYM SDLK_LMETA}
  SDLK_LSUPER = 311; // Left "Windows" key
{$EXTERNALSYM SDLK_LSUPER}
  SDLK_RSUPER = 312; // Right "Windows" key
{$EXTERNALSYM SDLK_RSUPER}
  SDLK_MODE = 313; // "Alt Gr" key
{$EXTERNALSYM SDLK_MODE}
  SDLK_COMPOSE = 314; // Multi-key compose key
{$EXTERNALSYM SDLK_COMPOSE}

  // Miscellaneous function keys
  SDLK_HELP = 315;
{$EXTERNALSYM SDLK_HELP}
  SDLK_PRINT = 316;
{$EXTERNALSYM SDLK_PRINT}
  SDLK_SYSREQ = 317;
{$EXTERNALSYM SDLK_SYSREQ}
  SDLK_BREAK = 318;
{$EXTERNALSYM SDLK_BREAK}
  SDLK_MENU = 319;
{$EXTERNALSYM SDLK_MENU}
  SDLK_POWER = 320; // Power Macintosh power key
{$EXTERNALSYM SDLK_POWER}
  SDLK_EURO = 321; // Some european keyboards
{$EXTERNALSYM SDLK_EURO}

  // Enumeration of valid key mods (possibly OR'd together)
  KMOD_NONE = $0000;
{$EXTERNALSYM KMOD_NONE}
  KMOD_LSHIFT = $0001;
{$EXTERNALSYM KMOD_LSHIFT}
  KMOD_RSHIFT = $0002;
{$EXTERNALSYM KMOD_RSHIFT}
  KMOD_LCTRL = $0040;
{$EXTERNALSYM KMOD_LCTRL}
  KMOD_RCTRL = $0080;
{$EXTERNALSYM KMOD_RCTRL}
  KMOD_LALT = $0100;
{$EXTERNALSYM KMOD_LALT}
  KMOD_RALT = $0200;
{$EXTERNALSYM KMOD_RALT}
  KMOD_LMETA = $0400;
{$EXTERNALSYM KMOD_LMETA}
  KMOD_RMETA = $0800;
{$EXTERNALSYM KMOD_RMETA}
  KMOD_NUM = $1000;
{$EXTERNALSYM KMOD_NUM}
  KMOD_CAPS = $2000;
{$EXTERNALSYM KMOD_CAPS}
  KMOD_MODE = 44000;
{$EXTERNALSYM KMOD_MODE}
  KMOD_RESERVED = $8000;
{$EXTERNALSYM KMOD_RESERVED}

  KMOD_CTRL = (KMOD_LCTRL or KMOD_RCTRL);
{$EXTERNALSYM KMOD_CTRL}
  KMOD_SHIFT = (KMOD_LSHIFT or KMOD_RSHIFT);
{$EXTERNALSYM KMOD_SHIFT}
  KMOD_ALT = (KMOD_LALT or KMOD_RALT);
{$EXTERNALSYM KMOD_ALT}
  KMOD_META = (KMOD_LMETA or KMOD_RMETA);
{$EXTERNALSYM KMOD_META}

  //SDL_video.h constants
  // Transparency definitions: These define alpha as the opacity of a surface */
  SDL_ALPHA_OPAQUE = 255;
{$EXTERNALSYM SDL_ALPHA_OPAQUE}
  SDL_ALPHA_TRANSPARENT = 0;
{$EXTERNALSYM SDL_ALPHA_TRANSPARENT}

  // These are the currently supported flags for the SDL_surface
  // Available for SDL_CreateRGBSurface() or SDL_SetVideoMode()
  SDL_SWSURFACE = $00000000; // Surface is in system memory
{$EXTERNALSYM SDL_SWSURFACE}
  SDL_HWSURFACE = $00000001; // Surface is in video memory
{$EXTERNALSYM SDL_HWSURFACE}
  SDL_ASYNCBLIT = $00000004; // Use asynchronous blits if possible
{$EXTERNALSYM SDL_ASYNCBLIT}
  // Available for SDL_SetVideoMode()
  SDL_ANYFORMAT = $10000000; // Allow any video depth/pixel-format
{$EXTERNALSYM SDL_ANYFORMAT}
  SDL_HWPALETTE = $20000000; // Surface has exclusive palette
{$EXTERNALSYM SDL_HWPALETTE}
  SDL_DOUBLEBUF = $40000000; // Set up double-buffered video mode
{$EXTERNALSYM SDL_DOUBLEBUF}
  SDL_FULLSCREEN = $80000000; // Surface is a full screen display
{$EXTERNALSYM SDL_FULLSCREEN}
  SDL_OPENGL = $00000002; // Create an OpenGL rendering context
{$EXTERNALSYM SDL_OPENGL}
  SDL_OPENGLBLIT = $00000002; // Create an OpenGL rendering context
{$EXTERNALSYM SDL_OPENGLBLIT}
  SDL_RESIZABLE = $00000010; // This video mode may be resized
{$EXTERNALSYM SDL_RESIZABLE}
  SDL_NOFRAME = $00000020; // No window caption or edge frame
{$EXTERNALSYM SDL_NOFRAME}
  // Used internally (read-only)
  SDL_HWACCEL = $00000100; // Blit uses hardware acceleration
{$EXTERNALSYM SDL_HWACCEL}
  SDL_SRCCOLORKEY = $00001000; // Blit uses a source color key
{$EXTERNALSYM SDL_SRCCOLORKEY}
  SDL_RLEACCELOK = $00002000; // Private flag
{$EXTERNALSYM SDL_RLEACCELOK}
  SDL_RLEACCEL = $00004000; // Colorkey blit is RLE accelerated
{$EXTERNALSYM SDL_RLEACCEL}
  SDL_SRCALPHA = $00010000; // Blit uses source alpha blending
{$EXTERNALSYM SDL_SRCALPHA}
  SDL_SRCCLIPPING = $00100000; // Blit uses source clipping
{$EXTERNALSYM SDL_SRCCLIPPING}
  SDL_PREALLOC = $01000000; // Surface uses preallocated memory
{$EXTERNALSYM SDL_PREALLOC}

  { The most common video overlay formats.
    For an explanation of these pixel formats, see:
    http://www.webartz.com/fourcc/indexyuv.htm

   For information on the relationship between color spaces, see:
   http://www.neuro.sfc.keio.ac.jp/~aly/polygon/info/color-space-faq.html }

  SDL_YV12_OVERLAY = $32315659; // Planar mode: Y + V + U  (3 planes)
{$EXTERNALSYM SDL_YV12_OVERLAY}
  SDL_IYUV_OVERLAY = $56555949; // Planar mode: Y + U + V  (3 planes)
{$EXTERNALSYM SDL_IYUV_OVERLAY}
  SDL_YUY2_OVERLAY = $32595559; // Packed mode: Y0+U0+Y1+V0 (1 plane)
{$EXTERNALSYM SDL_YUY2_OVERLAY}
  SDL_UYVY_OVERLAY = $59565955; // Packed mode: U0+Y0+V0+Y1 (1 plane)
{$EXTERNALSYM SDL_UYVY_OVERLAY}
  SDL_YVYU_OVERLAY = $55595659; // Packed mode: Y0+V0+Y1+U0 (1 plane)
{$EXTERNALSYM SDL_YVYU_OVERLAY}

  // flags for SDL_SetPalette()
  SDL_LOGPAL = $01;
{$EXTERNALSYM SDL_LOGPAL}
  SDL_PHYSPAL = $02;
{$EXTERNALSYM SDL_PHYSPAL}

  //SDL_mouse.h constants
  { Used as a mask when testing buttons in buttonstate
    Button 1: Left mouse button
    Button 2: Middle mouse button
    Button 3: Right mouse button
    Button 4: Mouse Wheel Up (may also be a real button)
    Button 5: Mouse Wheel Down (may also be a real button)
    Button 6: Mouse X1 (may also be a real button)
    Button 7: Mouse X2 (may also be a real button)
  }
  SDL_BUTTON_LEFT      = 1;
{$EXTERNALSYM SDL_BUTTON_LEFT}
  SDL_BUTTON_MIDDLE    = 2;
{$EXTERNALSYM SDL_BUTTON_MIDDLE}
  SDL_BUTTON_RIGHT     = 3;
{$EXTERNALSYM SDL_BUTTON_RIGHT}
  SDL_BUTTON_WHEELUP   = 4;
{$EXTERNALSYM SDL_BUTTON_WHEELUP}
  SDL_BUTTON_WHEELDOWN = 5;
{$EXTERNALSYM SDL_BUTTON_WHEELDOWN}
  SDL_BUTTON_X1        = 6;
{$EXTERNALSYM SDL_BUTTON_X1}
  SDL_BUTTON_X2        = 7;
{$EXTERNALSYM SDL_BUTTON_X2}

  SDL_BUTTON_LMASK = SDL_PRESSED shl (SDL_BUTTON_LEFT - 1);
{$EXTERNALSYM SDL_BUTTON_LMASK}
  SDL_BUTTON_MMASK = SDL_PRESSED shl (SDL_BUTTON_MIDDLE - 1);
{$EXTERNALSYM SDL_BUTTON_MMASK}
  SDL_BUTTON_RMASK = SDL_PRESSED shl (SDL_BUTTON_RIGHT - 1);
{$EXTERNALSYM SDL_BUTTON_RMASK}
  SDL_BUTTON_X1MASK = SDL_PRESSED shl (SDL_BUTTON_X1 - 1);
{$EXTERNALSYM SDL_BUTTON_X1MASK}
  SDL_BUTTON_X2MASK = SDL_PRESSED shl (SDL_BUTTON_X2 - 1);
{$EXTERNALSYM SDL_BUTTON_X2MASK}

  // SDL_active.h constants
  // The available application states
  SDL_APPMOUSEFOCUS = $01; // The app has mouse coverage
{$EXTERNALSYM SDL_APPMOUSEFOCUS}
  SDL_APPINPUTFOCUS = $02; // The app has input focus
{$EXTERNALSYM SDL_APPINPUTFOCUS}
  SDL_APPACTIVE = $04; // The application is active
{$EXTERNALSYM SDL_APPACTIVE}

  // SDL_mutex.h constants
  // Synchronization functions which can time out return this value
  //  they time out.

  SDL_MUTEX_TIMEDOUT = 1;
{$EXTERNALSYM SDL_MUTEX_TIMEDOUT}

  // This is the timeout value which corresponds to never time out
  SDL_MUTEX_MAXWAIT = not Cardinal(0);
{$EXTERNALSYM SDL_MUTEX_MAXWAIT}

  {TSDL_GrabMode = (
    SDL_GRAB_QUERY,
    SDL_GRAB_OFF,
    SDL_GRAB_ON,
    SDL_GRAB_FULLSCREEN ); // Used internally}
  SDL_GRAB_QUERY = -1;
  SDL_GRAB_OFF   = 0;
  SDL_GRAB_ON    = 1;
  //SDL_GRAB_FULLSCREEN // Used internally

type
  TThreadFunction = function(p: Pointer): Integer; cdecl;

  THandle = Cardinal;
  //SDL_types.h types
  // Basic data types

  SDL_Bool  = (SDL_FALSE, SDL_TRUE);
  TSDL_Bool = SDL_Bool;

  PUInt8Array = ^TUInt8Array;
  PUInt8 = ^UInt8;
  PPUInt8 = ^PUInt8;
  UInt8 = Byte;
{$EXTERNALSYM UInt8}
  TUInt8Array = array [0..MAXINT shr 1] of UInt8;

  PUInt16 = ^UInt16;
  UInt16 = word;
{$EXTERNALSYM UInt16}

  PSInt8 = ^SInt8;
  SInt8 = Shortint;
{$EXTERNALSYM SInt8}

  PSInt16 = ^SInt16;
  SInt16 = smallint;
{$EXTERNALSYM SInt16}

  PUInt32 = ^UInt32;
  UInt32 = Cardinal;
{$EXTERNALSYM UInt32}

  SInt32 = Integer;
{$EXTERNALSYM SInt32}

  PInt = ^Integer;

  PShortInt = ^ShortInt;
(*
  PUInt64 = ^UInt64;
  UInt64 = record
    hi: UInt32;
    lo: UInt32;
  end;
{$EXTERNALSYM UInt64}

  PSInt64 = ^SInt64;
  SInt64 = record
    hi: UInt32;
    lo: UInt32;
  end;
{$EXTERNALSYM SInt64}
*)
  TSDL_GrabMode = Integer;

  // SDL_error.h types
  TSDL_errorcode = (
    SDL_ENOMEM,
    SDL_EFREAD,
    SDL_EFWRITE,
    SDL_EFSEEK,
    SDL_LASTERROR);

  SDL_errorcode = TSDL_errorcode;
{$EXTERNALSYM SDL_errorcode}

  TArg = record
    case Byte of
      0: (value_ptr: Pointer);
      (* #if 0 means: never
      1:  (value_c: Byte);
      *)
      2: (value_i: Integer);
      3: (value_f: double);
      4: (buf: array[0..ERR_MAX_STRLEN - 1] of Byte);
  end;

  PSDL_error = ^TSDL_error;
  TSDL_error = record
    { This is a numeric value corresponding to the current error }
    error: Integer;

    { This is a key used to index into a language hashtable containing
       internationalized versions of the SDL error messages.  If the key
       is not in the hashtable, or no hashtable is available, the key is
       used directly as an error message format string. }
    key: array[0..ERR_MAX_STRLEN - 1] of Byte;

    { These are the arguments for the error functions }
    argc: Integer;
    args: array[0..ERR_MAX_ARGS - 1] of TArg;
  end;

  // SDL_rwops.h types
  // This is the read/write operation structure -- very basic
  // some helper types to handle the unions
  // "packed" is only guessed

  TStdio = record
    autoclose: Integer;
   // FILE * is only defined in Kylix so we use a simple Pointer
    fp: Pointer;
  end;

  TMem = record
    base: PUInt8;
    here: PUInt8;
    stop: PUInt8;
  end;

  TUnknown = record
    data1: Pointer;
  end;

  // first declare the pointer type
  PSDL_RWops = ^TSDL_RWops;
  // now the pointer to function types
  TSeek = function(context: PSDL_RWops; offset: Integer; whence: Integer): Integer; cdecl;
  TRead = function(context: PSDL_RWops; Ptr: Pointer; size: Integer; maxnum: Integer): Integer;  cdecl;
  TWrite = function(context: PSDL_RWops; Ptr: Pointer; size: Integer; num: Integer): Integer; cdecl;
  TClose = function(context: PSDL_RWops): Integer; cdecl;
  // the variant record itself
  TSDL_RWops = record
    seek: TSeek;
    read: TRead;
    write: TWrite;
    close: TClose;
    // a keyword as name is not allowed
    type_: UInt32;
    // be warned! structure alignment may arise at this point
    case Integer of
      0: (stdio: TStdio);
      1: (mem: TMem);
      2: (unknown: TUnknown);
  end;

  SDL_RWops = TSDL_RWops;
{$EXTERNALSYM SDL_RWops}


  // SDL_timer.h types
  // Function prototype for the timer callback function
  TSDL_TimerCallback = function(interval: UInt32): UInt32; cdecl;

 { New timer API, supports multiple timers
   Written by Stephane Peter <megastep@lokigames.com> }

 { Function prototype for the new timer callback function.
   The callback function is passed the current timer interval and returns
   the next timer interval.  If the returned value is the same as the one
   passed in, the periodic alarm continues, otherwise a new alarm is
   scheduled.  If the callback returns 0, the periodic alarm is cancelled. }
  TSDL_NewTimerCallback = function(interval: UInt32; param: Pointer): UInt32; cdecl;

  // Definition of the timer ID type
  PSDL_TimerID = ^TSDL_TimerID;
  TSDL_TimerID = record
    interval: UInt32;
    callback: TSDL_NewTimerCallback;
    param: Pointer;
    last_alarm: UInt32;
    next: PSDL_TimerID;
  end;

  TSDL_AudioSpecCallback = procedure(userdata: Pointer; stream: PByte{PUInt8}; len: Integer); cdecl;

  // SDL_audio.h types
  // The calculated values in this structure are calculated by SDL_OpenAudio()
  PSDL_AudioSpec = ^TSDL_AudioSpec;
  TSDL_AudioSpec = record
    freq: Integer; // DSP frequency -- samples per second
    format: UInt16; // Audio data format
    channels: UInt8; // Number of channels: 1 mono, 2 stereo
    silence: UInt8; // Audio buffer silence value (calculated)
    samples: UInt16; // Audio buffer size in samples
    padding: UInt16; // Necessary for some compile environments
    size: UInt32; // Audio buffer size in bytes (calculated)
    { This function is called when the audio device needs more data.
      'stream' is a pointer to the audio data buffer
      'len' is the length of that buffer in bytes.
      Once the callback returns, the buffer will no longer be valid.
      Stereo samples are stored in a LRLRLR ordering.}
    callback: TSDL_AudioSpecCallback;
    userdata: Pointer;
  end;

  // A structure to hold a set of audio conversion filters and buffers
  PSDL_AudioCVT = ^TSDL_AudioCVT;

  PSDL_AudioCVTFilter = ^TSDL_AudioCVTFilter;
  TSDL_AudioCVTFilter = record
    cvt: PSDL_AudioCVT;
    format: UInt16;
  end;

  PSDL_AudioCVTFilterArray = ^TSDL_AudioCVTFilterArray;
  TSDL_AudioCVTFilterArray = array[0..9] of PSDL_AudioCVTFilter;

  TSDL_AudioCVT = record
    needed: Integer; // Set to 1 if conversion possible
    src_format: UInt16; // Source audio format
    dst_format: UInt16; // Target audio format
    rate_incr: double; // Rate conversion increment
    buf: PUInt8; // Buffer to hold entire audio data
    len: Integer; // Length of original audio buffer
    len_cvt: Integer; // Length of converted audio buffer
    len_mult: Integer; // buffer must be len*len_mult big
    len_ratio: double; // Given len, final size is len*len_ratio
    filters: TSDL_AudioCVTFilterArray;
    filter_index: Integer; // Current audio conversion function
  end;

  TSDL_Audiostatus = (
    SDL_AUDIO_STOPPED,
    SDL_AUDIO_PLAYING,
    SDL_AUDIO_PAUSED);

  // SDL_cdrom.h types
  TSDL_CDStatus = (
    CD_ERROR,
    CD_TRAYEMPTY,
    CD_STOPPED,
    CD_PLAYING,
    CD_PAUSED);

  PSDL_CDTrack = ^TSDL_CDTrack;
  TSDL_CDTrack = record
    id: UInt8; // Track number
    type_: UInt8; // Data or audio track
    unused: UInt16;
    length: UInt32; // Length, in frames, of this track
    offset: UInt32; // Offset, in frames, from start of disk
  end;

  // This structure is only current as of the last call to SDL_CDStatus()
  PSDL_CD = ^TSDL_CD;
  TSDL_CD = record
    id: Integer; // Private drive identifier
    status: TSDL_CDStatus; // Current drive status

    // The rest of this structure is only valid if there's a CD in drive
    numtracks: Integer; // Number of tracks on disk
    cur_track: Integer; // Current track position
    cur_frame: Integer; // Current frame offset within current track
    track: array[0..SDL_MAX_TRACKS] of TSDL_CDTrack;
  end;

  //SDL_joystick.h types
  PTransAxis = ^TTransAxis;
  TTransAxis = record
    offset: Integer;
    scale: single;
  end;

  // The private structure used to keep track of a joystick
  PJoystick_hwdata = ^TJoystick_hwdata;
  TJoystick_hwdata = record
    // joystick ID
    id: Integer;
    // values used to translate device-specific coordinates into  SDL-standard ranges
    transaxis: array[0..5] of TTransAxis;
  end;

  PBallDelta = ^TBallDelta;
  TBallDelta = record
    dx: Integer;
    dy: Integer;
  end; // Current ball motion deltas

  // The SDL joystick structure
  PSDL_Joystick = ^TSDL_Joystick;
  TSDL_Joystick = record
    index: UInt8; // Device index
    name: PAnsiChar; // Joystick name - system dependent

    naxes: Integer; // Number of axis controls on the joystick
    axes: PUInt16; // Current axis states

    nhats: Integer; // Number of hats on the joystick
    hats: PUInt8; // Current hat states

    nballs: Integer; // Number of trackballs on the joystick
    balls: PBallDelta; // Current ball motion deltas

    nbuttons: Integer; // Number of buttons on the joystick
    buttons: PUInt8; // Current button states

    hwdata: PJoystick_hwdata; // Driver dependent information

    ref_count: Integer; // Reference count for multiple opens
  end;

  // SDL_verion.h types
  PSDL_version = ^TSDL_version;
  TSDL_version = record
    major: UInt8;
    minor: UInt8;
    patch: UInt8;
  end;

  // SDL_keyboard.h types
  TSDLKey = LongWord;

  TSDLMod = LongWord;

  PSDL_KeySym = ^TSDL_KeySym;
  TSDL_KeySym = record
    scancode: UInt8; // hardware specific scancode
    sym: TSDLKey; // SDL virtual keysym
    modifier: TSDLMod; // current key modifiers
    unicode: UInt16; // translated character
  end;

  // SDL_events.h types
  {Checks the event queue for messages and optionally returns them.
   If 'action' is SDL_ADDEVENT, up to 'numevents' events will be added to
   the back of the event queue.
   If 'action' is SDL_PEEKEVENT, up to 'numevents' events at the front
   of the event queue, matching 'mask', will be returned and will not
   be removed from the queue.
   If 'action' is SDL_GETEVENT, up to 'numevents' events at the front
   of the event queue, matching 'mask', will be returned and will be
   removed from the queue.
   This function returns the number of events actually stored, or -1
   if there was an error.  This function is thread-safe. }

  TSDL_EventAction = (SDL_ADDEVENT, SDL_PEEKEVENT, SDL_GETEVENT);

  // Application visibility event structure
  TSDL_ActiveEvent = record
    type_: UInt8; // SDL_ACTIVEEVENT
    gain: UInt8; // Whether given states were gained or lost (1/0)
    state: UInt8; // A mask of the focus states
  end;

  // Keyboard event structure
  TSDL_KeyboardEvent = record
    type_: UInt8; // SDL_KEYDOWN or SDL_KEYUP
    which: UInt8; // The keyboard device index
    state: UInt8; // SDL_PRESSED or SDL_RELEASED
    keysym: TSDL_KeySym;
  end;

  // Mouse motion event structure
  TSDL_MouseMotionEvent = record
    type_: UInt8; // SDL_MOUSEMOTION
    which: UInt8; // The mouse device index
    state: UInt8; // The current button state
    x, y: UInt16; // The X/Y coordinates of the mouse
    xrel: SInt16; // The relative motion in the X direction
    yrel: SInt16; // The relative motion in the Y direction
  end;

  // Mouse button event structure
  TSDL_MouseButtonEvent = record
    type_: UInt8;  // SDL_MOUSEBUTTONDOWN or SDL_MOUSEBUTTONUP
    which: UInt8;  // The mouse device index
    button: UInt8; // The mouse button index
    state: UInt8;  // SDL_PRESSED or SDL_RELEASED
    x: UInt16;     // The X coordinates of the mouse at press time
    y: UInt16;     // The Y coordinates of the mouse at press time
  end;

  // Joystick axis motion event structure
  TSDL_JoyAxisEvent = record
    type_: UInt8; // SDL_JOYAXISMOTION
    which: UInt8; // The joystick device index
    axis: UInt8; // The joystick axis index
    value: SInt16; // The axis value (range: -32768 to 32767)
  end;

  // Joystick trackball motion event structure
  TSDL_JoyBallEvent = record
    type_: UInt8; // SDL_JOYAVBALLMOTION
    which: UInt8; // The joystick device index
    ball: UInt8; // The joystick trackball index
    xrel: SInt16; // The relative motion in the X direction
    yrel: SInt16; // The relative motion in the Y direction
  end;

  // Joystick hat position change event structure
  TSDL_JoyHatEvent = record
    type_: UInt8; // SDL_JOYHATMOTION */
    which: UInt8; // The joystick device index */
    hat: UInt8; // The joystick hat index */
    value: UInt8; { The hat position value:
                    8   1   2
                    7   0   3
                    6   5   4

                    Note that zero means the POV is centered. }

  end;

  // Joystick button event structure
  TSDL_JoyButtonEvent = record
    type_: UInt8; // SDL_JOYBUTTONDOWN or SDL_JOYBUTTONUP
    which: UInt8; // The joystick device index
    button: UInt8; // The joystick button index
    state: UInt8; // SDL_PRESSED or SDL_RELEASED
  end;

  { The "window resized" event
    When you get this event, you are responsible for setting a new video
    mode with the new width and height. }
  TSDL_ResizeEvent = record
    type_: UInt8; // SDL_VIDEORESIZE
// WolfePak Change: Need to shift by 24 bits for this to work correctly...
    Garbage: array [1..3] of Byte;
{
    w: Integer; // New width
    h: Integer; // New height
}
    w: UInt32; // New width - Uint32 so it doesn't depend on compiler magic
    h: UInt32; // New height - Uint32 so it doesn't depend on compiler magic
// End WolfePak Change
  end;

  // The "quit requested" event
  PSDL_QuitEvent = ^TSDL_QuitEvent;
  TSDL_QuitEvent = record
    type_: UInt8;
  end;

  // A user-defined event type
  PSDL_UserEvent = ^TSDL_UserEvent;
  TSDL_UserEvent = record
    type_: UInt8; // SDL_USEREVENT through SDL_NUMEVENTS-1
    code: Integer; // User defined event code */
    data1: Pointer; // User defined data pointer */
    data2: Pointer; // User defined data pointer */
  end;

  // The "screen redraw" event
  PSDL_ExposeEvent = ^TSDL_ExposeEvent;
  TSDL_ExposeEvent = record
    type_: Uint8;        // SDL_VIDEOEXPOSE
  end;

{
// The windows custom event structure
  PSDL_SysWMmsg = ^TSDL_SysWMmsg;
  TSDL_SysWMmsg = record
    version: TSDL_version;
    h_wnd: HWND; // The window for the message
    msg: UInt; // The type of message
    w_Param: WPARAM; // WORD message parameter
    lParam: LPARAM; // LONG message parameter
  end;

// The Windows custom window manager information structure
  PSDL_SysWMinfo = ^TSDL_SysWMinfo;
  TSDL_SysWMinfo = record
    version: TSDL_version;
    window: HWnd; // The display window
  end;

  PSDL_SysWMEvent = ^TSDL_SysWMEvent;
  TSDL_SysWMEvent = record
    type_: UInt8;
    msg: PSDL_SysWMmsg;
  end;
}

  PSDL_Event = ^TSDL_Event;
  TSDL_Event = record
    case UInt8 of
      SDL_NOEVENT: (type_: byte);
      SDL_ACTIVEEVENT: (active: TSDL_ActiveEvent);
      SDL_KEYDOWN, SDL_KEYUP: (key: TSDL_KeyboardEvent);
      SDL_MOUSEMOTION: (motion: TSDL_MouseMotionEvent);
      SDL_MOUSEBUTTONDOWN, SDL_MOUSEBUTTONUP: (button: TSDL_MouseButtonEvent);
      SDL_JOYAXISMOTION: (jaxis: TSDL_JoyAxisEvent);
      SDL_JOYBALLMOTION: (jball: TSDL_JoyBallEvent);
      SDL_JOYHATMOTION: (jhat: TSDL_JoyHatEvent);
      SDL_JOYBUTTONDOWN, SDL_JOYBUTTONUP: (jbutton: TSDL_JoyButtonEvent);
      SDL_VIDEORESIZE: (resize: TSDL_ResizeEvent);
// WolfePak Change: Missing event as per the SDL wiki...
      SDL_VIDEOEXPOSE: (expose: TSDL_ExposeEvent);
// End WolfePak Change
      SDL_QUITEV: (quit: TSDL_QuitEvent);
      SDL_USEREVENT: (user: TSDL_UserEvent);
//      SDL_SYSWMEVENT: (syswm: TSDL_SysWMEvent);
  end;


{ This function sets up a filter to process all events before they
  change internal state and are posted to the internal event queue.

  The filter is protypted as: }
  TSDL_EventFilter = function(event: PSDL_Event): Integer;

  // SDL_video.h types
  // Useful data types
  PPSDL_Rect = ^PSDL_Rect;
  PSDL_Rect = ^TSDL_Rect;
  TSDL_Rect = record
    x, y: SInt16;
    w, h: UInt16;
  end;

  SDL_Rect = TSDL_Rect;
{$EXTERNALSYM SDL_Rect}

  PSDL_Color = ^TSDL_Color;
  TSDL_Color = record
    r: UInt8;
    g: UInt8;
    b: UInt8;
    unused: UInt8;
  end;

  PSDL_ColorArray = ^TSDL_ColorArray;
  TSDL_ColorArray = array[0..65000] of TSDL_Color;

  PSDL_Palette = ^TSDL_Palette;
  TSDL_Palette = record
    ncolors: Integer;
    colors: PSDL_ColorArray;
  end;

  // Everything in the pixel format structure is read-only
  PSDL_PixelFormat = ^TSDL_PixelFormat;
  TSDL_PixelFormat = record
    palette: PSDL_Palette;
    BitsPerPixel: UInt8;
    BytesPerPixel: UInt8;
    Rloss: UInt8;
    Gloss: UInt8;
    Bloss: UInt8;
    Aloss: UInt8;
    Rshift: UInt8;
    Gshift: UInt8;
    Bshift: UInt8;
    Ashift: UInt8;
    RMask: UInt32;
    GMask: UInt32;
    BMask: UInt32;
    AMask: UInt32;
    colorkey: UInt32; // RGB color key information
    alpha: UInt8; // Alpha value information (per-surface alpha)
  end;

  {PPrivate_hwdata = ^TPrivate_hwdata;
  TPrivate_hwdata = record
    dd_surface: IDIRECTDRAWSURFACE3;
    dd_writebuf: IDIRECTDRAWSURFACE3;
  end;}

  // The structure passed to the low level blit functions
  PSDL_BlitInfo = ^TSDL_BlitInfo;
  TSDL_BlitInfo = record
    s_pixels: PUInt8;
    s_width: Integer;
    s_height: Integer;
    s_skip: Integer;
    d_pixels: PUInt8;
    d_width: Integer;
    d_height: Integer;
    d_skip: Integer;
    aux_data: Pointer;
    src: PSDL_PixelFormat;
    table: PUInt8;
    dst: PSDL_PixelFormat;
  end;

  // typedef for private surface blitting functions
  PSDL_Surface = ^TSDL_Surface;

  TSDL_Blit = function(src: PSDL_Surface; srcrect: PSDL_Rect; dst: PSDL_Surface; dstrect: PSDL_Rect): Integer;

  // The type definition for the low level blit functions
  //TSDL_LoBlit = procedure(info: PSDL_BlitInfo); cdecl;

  // This is the private info structure for software accelerated blits
  {PPrivate_swaccel = ^TPrivate_swaccel;
  TPrivate_swaccel = record
    blit: TSDL_LoBlit;
    aux_data: Pointer;
  end;}

  // Blit mapping definition
  {PSDL_BlitMap = ^TSDL_BlitMap;
  TSDL_BlitMap = record
    dst: PSDL_Surface;
    identity: Integer;
    table: PUInt8;
    hw_blit: TSDL_Blit;
    sw_blit: TSDL_Blit;
    hw_data: PPrivate_hwaccel;
    sw_data: PPrivate_swaccel;

    // the version count matches the destination; mismatch indicates an invalid mapping
    format_version: Cardinal;
  end;}

  TSDL_Surface = record
    flags: UInt32; // Read-only
    format: PSDL_PixelFormat; // Read-only
    w, h: Integer; // Read-only
    pitch: UInt16; // Read-only
    pixels: Pointer; // Read-write
    offset: Integer; // Private
    hwdata: Pointer; //TPrivate_hwdata;  Hardware-specific surface info

    // clipping information:
    clip_rect: TSDL_Rect; // Read-only
    unused1: UInt32; // for binary compatibility
    // Allow recursive locks
    locked: UInt32; // Private
    // info for fast blit mapping to other surfaces
    Blitmap: Pointer; // PSDL_BlitMap; //   Private
    // format version, bumped at every change to invalidate blit maps
    format_version: Cardinal; // Private
    refcount: Integer;
  end;

  // Useful for determining the video hardware capabilities
  PSDL_VideoInfo = ^TSDL_VideoInfo;
  TSDL_VideoInfo = record
    hw_available: UInt8; // Hardware and WindowManager flags in first 2 bits (see below)
    {hw_available: 1; // Can you create hardware surfaces
    wm_available: 1; // Can you talk to a window manager?
    UnusedBits1: 6;}
    blit_hw: UInt8; // Blit Hardware flags. See below for which bits do what
    {UnusedBits2: 1;
    blit_hw: 1; // Flag:UInt32  Accelerated blits HW --> HW
    blit_hw_CC: 1; // Flag:UInt32  Accelerated blits with Colorkey
    blit_hw_A: 1; // Flag:UInt32  Accelerated blits with Alpha
    blit_sw: 1; // Flag:UInt32  Accelerated blits SW --> HW
    blit_sw_CC: 1; // Flag:UInt32  Accelerated blits with Colorkey
    blit_sw_A: 1; // Flag:UInt32  Accelerated blits with Alpha
    blit_fill: 1; // Flag:UInt32  Accelerated color fill}
    UnusedBits3: UInt8; // Unused at this point
    video_mem: UInt32; // The total amount of video memory (in K)
    vfmt: PSDL_PixelFormat; // Value: The format of the video surface
    current_w: SInt32; // Value: The current video mode width
    current_h: SInt32; // Value: The current video mode height
  end;

  // The YUV hardware video overlay
  PSDL_Overlay = ^TSDL_Overlay;
  TSDL_Overlay = record
    format: UInt32; // Overlay format
    w, h: Integer; // Width and height of overlay
    planes: Integer; // Number of planes in the overlay. Usually either 1 or 3
    pitches: PUInt16;
      // An array of pitches, one for each plane. Pitch is the length of a row in bytes.
    pixels: PPUInt8;
      // An array of pointers to the data of each plane. The overlay should be locked before these pointers are used.

    (* Hardware-specific surface info *)
    hwfuncs: Pointer;
    hwdata: Pointer;

    hw_overlay: UInt32;
      // This will be set to 1 if the overlay is hardware accelerated.
  end;

  // Public enumeration for setting the OpenGL window attributes.
  TSDL_GLAttr = (
    SDL_GL_RED_SIZE,
    SDL_GL_GREEN_SIZE,
    SDL_GL_BLUE_SIZE,
    SDL_GL_ALPHA_SIZE,
    SDL_GL_BUFFER_SIZE,
    SDL_GL_DOUBLEBUFFER,
    SDL_GL_DEPTH_SIZE,
    SDL_GL_STENCIL_SIZE,
    SDL_GL_ACCUM_RED_SIZE,
    SDL_GL_ACCUM_GREEN_SIZE,
    SDL_GL_ACCUM_BLUE_SIZE,
    SDL_GL_ACCUM_ALPHA_SIZE,
    SDL_GL_STEREO,
    SDL_GL_MULTISAMPLEBUFFERS,
    SDL_GL_MULTISAMPLESAMPLES,
    SDL_GL_ACCELERATED_VISUAL,
    SDL_GL_SWAP_CONTROL);


  PSDL_Cursor = ^TSDL_Cursor;
  TSDL_Cursor = record
    area: TSDL_Rect; // The area of the mouse cursor
    hot_x, hot_y: SInt16; // The "tip" of the cursor
    data: PUInt8; // B/W cursor data
    mask: PUInt8; // B/W cursor mask
    save: array[1..2] of PUInt8; // Place to save cursor area
    wm_cursor: Pointer; // Window-manager cursor
  end;

// SDL_mutex.h types

  PSDL_Mutex = ^TSDL_Mutex;
  TSDL_Mutex = record
    id: THANDLE;
  end;

  PSDL_semaphore = ^TSDL_semaphore;
  // WINDOWS or Machintosh
  TSDL_semaphore = record
    id: THANDLE;
    count: UInt32;
  end;

  PSDL_Sem = ^TSDL_Sem;
  TSDL_Sem = TSDL_Semaphore;

  PSDL_Cond = ^TSDL_Cond;
  TSDL_Cond = record
    // Generic Cond structure
    lock: PSDL_mutex;
    waiting: Integer;
    signals: Integer;
    wait_sem: PSDL_Sem;
    wait_done: PSDL_Sem;
  end;

  // SDL_thread.h types
  TSYS_ThreadHandle = THandle;

  { This is the system-independent thread info structure }
  PSDL_Thread = ^TSDL_Thread;
  TSDL_Thread = record
    threadid: UInt32;
    handle: TSYS_ThreadHandle;
    status: Integer;
    errbuf: TSDL_Error;
    data: Pointer;
  end;

  // Helper Types

  // Keyboard  State Array (See demos for how to use)
  PKeyStateArr = ^TKeyStateArr;
  TKeyStateArr = array[0..65000] of UInt8;

  { Generic procedure pointer }
  TProcedure = procedure;

type
  TSDL_Linked_Version = function: PSDL_version; cdecl;
  TSDL_Init = function(flags: UInt32): Integer; cdecl;
  TSDL_Quit = procedure; cdecl;
{$IFDEF MSWINDOWS}
  TSDL_getenv = function(const name: PAnsiChar): PAnsiChar; cdecl;
  TSDL_putenv = function(const variable: PAnsiChar): Integer; cdecl;
{$ENDIF}
  TSDL_GetError = function: PAnsiChar; cdecl;
  TSDL_AddTimer = function(interval: UInt32; callback: TSDL_NewTimerCallback; param: Pointer): PSDL_TimerID; cdecl;
  TSDL_RemoveTimer = function(t: PSDL_TimerID): TSDL_Bool; cdecl;
  TSDL_OpenAudio = function(desired, obtained: PSDL_AudioSpec): Integer; cdecl;
  TSDL_PauseAudio = procedure(pause_on: Integer); cdecl;
  TSDL_CloseAudio = procedure; cdecl;
  TSDL_MixAudio = procedure(dst, src: PUInt8; len: UInt32; volume: Integer); cdecl;
//  TSDL_WaitEvent = function(event: PSDL_Event): Integer; cdecl;
  TSDL_PumpEvents = procedure; cdecl;
  TSDL_PeepEvents = function(events: PSDL_Event; numevents: Integer; action: TSDL_eventaction; mask: UInt32): Integer; cdecl;
  TSDL_PushEvent = function(event: PSDL_Event): Integer; cdecl;
  TSDL_EventState = function(type_: UInt8; state: Integer): UInt8; cdecl;
//  TSDL_RWFromFile = function(filename, mode: PAnsiChar): PSDL_RWops; cdecl;
//  TSDL_SaveBMP_RW = function(surface: PSDL_Surface; dst: PSDL_RWops; freedst: Integer): Integer; cdecl;

  TSDL_GetVideoInfo = function: PSDL_VideoInfo; cdecl;
  TSDL_SetVideoMode = function(width, height, bpp: Integer; flags: UInt32): PSDL_Surface; cdecl;
  TSDL_UpdateRect = procedure(screen: PSDL_Surface; x, y: SInt32; w, h: UInt32); cdecl;
  TSDL_WM_SetCaption = procedure(const title, icon: PAnsiChar); cdecl;
  TSDL_MapRGB = function(format: PSDL_PixelFormat; r: UInt8; g: UInt8; b: UInt8): UInt32; cdecl;
  TSDL_FillRect = function(dst: PSDL_Surface; dstrect: PSDL_Rect; color: UInt32): Integer; cdecl;
  TSDL_CreateYUVOverlay = function(width: Integer; height: Integer; format: UInt32; display: PSDL_Surface): PSDL_Overlay; cdecl;
  TSDL_LockYUVOverlay = function(Overlay: PSDL_Overlay): Integer; cdecl;
  TSDL_UnlockYUVOverlay = procedure(Overlay: PSDL_Overlay); cdecl;
  TSDL_DisplayYUVOverlay = function(Overlay: PSDL_Overlay; dstrect: PSDL_Rect): Integer; cdecl;
  TSDL_FreeYUVOverlay = procedure(Overlay: PSDL_Overlay); cdecl;
  TSDL_CreateMutex = function: PSDL_Mutex; cdecl;
  TSDL_mutexP = function(mutex: PSDL_mutex): Integer; cdecl;
  TSDL_mutexV = function(mutex: PSDL_mutex): Integer; cdecl;
  TSDL_DestroyMutex = procedure(mutex: PSDL_mutex); cdecl;
  TSDL_CreateCond = function: PSDL_Cond; cdecl;
  TSDL_DestroyCond = procedure(cond: PSDL_Cond); cdecl;
  TSDL_CondSignal = function(cond: PSDL_cond): Integer; cdecl;
  TSDL_CondWaitTimeout = function(cond: PSDL_cond; mut: PSDL_mutex; ms: UInt32): Integer; cdecl;
  TSDL_CondWait = function(cond: PSDL_cond; mut: PSDL_mutex): Integer; cdecl;
  TSDL_CreateThread = function(fn: TThreadFunction; data: Pointer): PSDL_Thread; cdecl;
  TSDL_WaitThread = procedure(thread: PSDL_Thread; var status: Integer); cdecl;

  TSDL_AudioDriverName = function(namebuf: PAnsiChar; maxlen: Integer): PAnsiChar; cdecl;
  TSDL_VideoDriverName = function(namebuf: PAnsiChar; maxlen: Integer): PAnsiChar; cdecl;

  TSDLLoader = class
  private
    // SDL lib instance
    FLibFile: TPathFileName;
    FHandle: THandle;
    FFixuped: Boolean;
    FSDLVersion: TSDL_version;

    FLastErrMsg: string;

    procedure FixupStubs(const ALibFile: TPathFileName; const AHandle: THandle);
    procedure UnfixStubs;
    procedure UnloadLocked;
  public
    constructor Create;
    destructor Destroy; override;

    function Load(const APath, AFile: TPathFileName): Boolean;
    function Loaded: Boolean;
    procedure Unload;

    property LastErrMsg: string read FLastErrMsg;
    property SDLVersion: TSDL_version read FSDLVersion;
  public
    // SDL API stubs
    SDL_Linked_Version: TSDL_Linked_Version;
    SDL_Init: TSDL_Init;
    SDL_Quit: TSDL_Quit;
{$IFDEF MSWINDOWS}
    SDL_getenv: TSDL_getenv;
    SDL_putenv: TSDL_putenv;
{$ENDIF}
    SDL_GetError: TSDL_GetError;
    SDL_OpenAudio: TSDL_OpenAudio;
    SDL_PauseAudio: TSDL_PauseAudio;
    SDL_CloseAudio: TSDL_CloseAudio;
    SDL_MixAudio: TSDL_MixAudio;
    SDL_PumpEvents: TSDL_PumpEvents;
    SDL_PeepEvents: TSDL_PeepEvents;
    SDL_PushEvent: TSDL_PushEvent;
    SDL_EventState: TSDL_EventState;

    SDL_GetVideoInfo: TSDL_GetVideoInfo;
    SDL_SetVideoMode: TSDL_SetVideoMode;
    SDL_UpdateRect: TSDL_UpdateRect;
    SDL_WM_SetCaption: TSDL_WM_SetCaption;
    SDL_MapRGB: TSDL_MapRGB;
    SDL_FillRect: TSDL_FillRect;
    SDL_CreateYUVOverlay: TSDL_CreateYUVOverlay;
    SDL_LockYUVOverlay: TSDL_LockYUVOverlay;
    SDL_UnlockYUVOverlay: TSDL_UnlockYUVOverlay;
    SDL_DisplayYUVOverlay: TSDL_DisplayYUVOverlay;
    SDL_FreeYUVOverlay: TSDL_FreeYUVOverlay;
    SDL_CreateMutex: TSDL_CreateMutex;
    SDL_LockMutex: TSDL_mutexP;
    SDL_UnlockMutex: TSDL_mutexV;
    SDL_DestroyMutex: TSDL_DestroyMutex;
    SDL_CreateCond: TSDL_CreateCond;
    SDL_DestroyCond: TSDL_DestroyCond;
    SDL_CondSignal: TSDL_CondSignal;
    SDL_CondWaitTimeout: TSDL_CondWaitTimeout;
    SDL_CondWait: TSDL_CondWait;
    SDL_CreateThread: TSDL_CreateThread;
    SDL_WaitThread: TSDL_WaitThread;
    SDL_AudioDriverName: TSDL_AudioDriverName;
    SDL_VideoDriverName: TSDL_VideoDriverName;
  end;

//function SDL_SaveBMP(surface: PSDL_Surface; filename: PAnsiChar): Integer;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
{* These functions allow interaction with the window manager, if any.        *}
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
(*
{ Grabbing means that the mouse is confined to the application window,
  and nearly all keyboard input is passed directly to the application,
  and not interpreted by a window manager, if any. }
function SDL_WM_GrabInput(mode: TSDL_GrabMode): TSDL_GrabMode; cdecl;
external {$IFNDEF NDS}{$IFDEF __GPC__}name 'SDL_WM_GrabInput'{$ELSE} SDLLibName{$ENDIF __GPC__}{$ENDIF};
{$EXTERNALSYM SDL_WM_GrabInput}

{*
 * This function gives you custom hooks into the window manager information.
 * It fills the structure pointed to by 'info' with custom information and
 * returns 1 if the function is implemented.  If it's not implemented, or
 * the version member of the 'info' structure is invalid, it returns 0.
 *}
function SDL_GetWMInfo(info: PSDL_SysWMinfo): Integer; cdecl;
external {$IFNDEF NDS}{$IFDEF __GPC__}name 'SDL_GetWMInfo'{$ELSE} SDLLibName{$ENDIF __GPC__}{$ENDIF};
{$EXTERNALSYM SDL_GetWMInfo}
*)

{------------------------------------------------------------------------------}

// Bitwise Checking functions
function IsBitOn(value: integer; bit: Byte): boolean;
function TurnBitOn(value: integer; bit: Byte): integer;
function TurnBitOff(value: integer; bit: Byte): integer;

var
  SDLLock: TCriticalSection;

implementation

{
function SDL_SaveBMP(surface: PSDL_Surface; filename: PAnsiChar): Integer;
begin
  Result := SDL_SaveBMP_RW(surface, SDL_RWFromFile(filename, 'wb'), 1);
end;
}

function IsBitOn(value: integer; bit: Byte): boolean;
begin
  result := ((value and (1 shl bit)) <> 0);
end;

function TurnBitOn(value: integer; bit: Byte): integer;
begin
  result := (value or (1 shl bit));
end;

function TurnBitOff(value: integer; bit: Byte): integer;
begin
  result := (value and not (1 shl bit));
end;

{ TSDLLoader }

var
  SDLList: TStringList;

constructor TSDLLoader.Create;
begin
  FHandle := 0;
  FFixuped := False;
  FillChar(FSDLVersion, SizeOf(TSDL_version), 0);
end;

destructor TSDLLoader.Destroy;
begin
  Unload;
  inherited Destroy;
end;

function TSDLLoader.Load(const APath, AFile: TPathFileName): Boolean;
var
  LLibFile: TPathFileName;
  LErrorCode: DWORD;
begin
  LLibFile := IncludeTrailingPathDelimiter(APath) + AFile;

  // already loaded
  if Loaded and {$IFDEF FPC}SameText{$ELSE}WideSameStr{$ENDIF}(FLibFile, LLibFile) then
  begin
    Result := True;
    Exit;
  end;

  SDLLock.Acquire;
  try
    // already loaded in another instance
    if SDLList.IndexOf(LLibFile) >= 0 then
    begin
      FLastErrMsg := Format('%s alreay loaded in another instance.', [LLibFile]);
      Result := False;
      Exit;
    end;

    // unload
    UnloadLocked;

    // load
    FHandle := MyLoadLibrary(APath, AFile, LErrorCode);
    if FHandle = 0 then
    begin
      FLastErrMsg := Format('Load library %s error: %s', [LLibFile, SysErrorMessage(LErrorCode)]);
      Result := False;
      Exit;
    end;

    // fixup stubs
    try
      FixupStubs(AFile, FHandle);
      FSDLVersion := SDL_Linked_Version^;
      FFixuped := True;
    except on E: Exception do
      begin
        FLastErrMsg := E.Message;
        FFixuped := False;
      end;
    end;

    // add to list
    if FFixuped then
    begin
      FLibFile := LLibFile;
      SDLList.Add(FLibFile);
    end
    else
      UnloadLocked;

    Result := FFixuped;
  finally
    SDLLock.Release;
  end;
end;

function TSDLLoader.Loaded: Boolean;
begin
  Result := (FHandle <> 0) and FFixuped;
end;

procedure TSDLLoader.Unload;
begin
  SDLLock.Acquire;
  try
    UnloadLocked;
  finally
    SDLLock.Release;
  end;
end;

procedure TSDLLoader.UnloadLocked;
begin
  FillChar(FSDLVersion, SizeOf(TSDL_version), 0);
  if FFixuped then
  begin
    UnfixStubs;
    FFixuped := False;
  end;
  if FHandle <> 0 then
  begin
    FreeLibrary(FHandle);
    FHandle := 0;
  end;
  if FLibFile <> '' then
  begin
    SDLList.Delete(SDLList.IndexOf(FLibFile));
    FLibFile := '';
  end;
end;

procedure TSDLLoader.FixupStubs(const ALibFile: TPathFileName; const AHandle: THandle);
begin
  FixupStub(ALibFile, AHandle, 'SDL_Linked_Version',      @SDL_Linked_Version);
  FixupStub(ALibFile, AHandle, 'SDL_Init',                @SDL_Init);
  FixupStub(ALibFile, AHandle, 'SDL_Quit',                @SDL_Quit);
{$IFDEF MSWINDOWS}
  FixupStub(ALibFile, AHandle, 'SDL_getenv',              @SDL_getenv);
  FixupStub(ALibFile, AHandle, 'SDL_putenv',              @SDL_putenv);
{$ENDIF}
  FixupStub(ALibFile, AHandle, 'SDL_GetError',            @SDL_GetError);
  FixupStub(ALibFile, AHandle, 'SDL_OpenAudio',           @SDL_OpenAudio);
  FixupStub(ALibFile, AHandle, 'SDL_PauseAudio',          @SDL_PauseAudio);
  FixupStub(ALibFile, AHandle, 'SDL_CloseAudio',          @SDL_CloseAudio);
  FixupStub(ALibFile, AHandle, 'SDL_MixAudio',            @SDL_MixAudio);
  FixupStub(ALibFile, AHandle, 'SDL_PumpEvents',          @SDL_PumpEvents);
  FixupStub(ALibFile, AHandle, 'SDL_PeepEvents',          @SDL_PeepEvents);
  FixupStub(ALibFile, AHandle, 'SDL_PushEvent',           @SDL_PushEvent);
  FixupStub(ALibFile, AHandle, 'SDL_EventState',          @SDL_EventState);
  FixupStub(ALibFile, AHandle, 'SDL_GetVideoInfo',        @SDL_GetVideoInfo);
  FixupStub(ALibFile, AHandle, 'SDL_SetVideoMode',        @SDL_SetVideoMode);
  FixupStub(ALibFile, AHandle, 'SDL_UpdateRect',          @SDL_UpdateRect);
  FixupStub(ALibFile, AHandle, 'SDL_WM_SetCaption',       @SDL_WM_SetCaption);
  FixupStub(ALibFile, AHandle, 'SDL_MapRGB',              @SDL_MapRGB);
  FixupStub(ALibFile, AHandle, 'SDL_FillRect',            @SDL_FillRect);
  FixupStub(ALibFile, AHandle, 'SDL_CreateYUVOverlay',    @SDL_CreateYUVOverlay);
  FixupStub(ALibFile, AHandle, 'SDL_LockYUVOverlay',      @SDL_LockYUVOverlay);
  FixupStub(ALibFile, AHandle, 'SDL_UnlockYUVOverlay',    @SDL_UnlockYUVOverlay);
  FixupStub(ALibFile, AHandle, 'SDL_DisplayYUVOverlay',   @SDL_DisplayYUVOverlay);
  FixupStub(ALibFile, AHandle, 'SDL_FreeYUVOverlay',      @SDL_FreeYUVOverlay);
  FixupStub(ALibFile, AHandle, 'SDL_CreateMutex',         @SDL_CreateMutex);
  FixupStub(ALibFile, AHandle, 'SDL_mutexP',              @SDL_LockMutex);
  FixupStub(ALibFile, AHandle, 'SDL_mutexV',              @SDL_UnlockMutex);
  FixupStub(ALibFile, AHandle, 'SDL_DestroyMutex',        @SDL_DestroyMutex);
  FixupStub(ALibFile, AHandle, 'SDL_CreateCond',          @SDL_CreateCond);
  FixupStub(ALibFile, AHandle, 'SDL_DestroyCond',         @SDL_DestroyCond);
  FixupStub(ALibFile, AHandle, 'SDL_CondSignal',          @SDL_CondSignal);
  FixupStub(ALibFile, AHandle, 'SDL_CondWaitTimeout',     @SDL_CondWaitTimeout);
  FixupStub(ALibFile, AHandle, 'SDL_CondWait',            @SDL_CondWait);
  FixupStub(ALibFile, AHandle, 'SDL_CreateThread',        @SDL_CreateThread);
  FixupStub(ALibFile, AHandle, 'SDL_WaitThread',          @SDL_WaitThread);
  FixupStub(ALibFile, AHandle, 'SDL_AudioDriverName',     @SDL_AudioDriverName);
  FixupStub(ALibFile, AHandle, 'SDL_VideoDriverName',     @SDL_VideoDriverName);
end;

procedure TSDLLoader.UnfixStubs;
begin
  @SDL_Linked_Version       := nil;
  @SDL_Init                 := nil;
  if Assigned(SDL_Quit) then
  begin
    try
      SDL_Quit;
    except
    end;
  end;
  @SDL_Quit                 := nil;
{$IFDEF MSWINDOWS}
  @SDL_getenv               := nil;
  @SDL_putenv               := nil;
{$ENDIF}
  @SDL_GetError             := nil;
  @SDL_OpenAudio            := nil;
  @SDL_PauseAudio           := nil;
  @SDL_CloseAudio           := nil;
  @SDL_MixAudio             := nil;
  @SDL_PumpEvents           := nil;
  @SDL_PeepEvents           := nil;
  @SDL_PushEvent            := nil;
  @SDL_EventState           := nil;
  @SDL_GetVideoInfo         := nil;
  @SDL_SetVideoMode         := nil;
  @SDL_UpdateRect           := nil;
  @SDL_MapRGB               := nil;
  @SDL_FillRect             := nil;
  @SDL_CreateYUVOverlay     := nil;
  @SDL_LockYUVOverlay       := nil;
  @SDL_UnlockYUVOverlay     := nil;
  @SDL_DisplayYUVOverlay    := nil;
  @SDL_FreeYUVOverlay       := nil;
  @SDL_CreateMutex          := nil;
  @SDL_LockMutex            := nil;
  @SDL_UnlockMutex          := nil;
  @SDL_DestroyMutex         := nil;
  @SDL_CreateCond           := nil;
  @SDL_DestroyCond          := nil;
  @SDL_CondSignal           := nil;
  @SDL_CondWaitTimeout      := nil;
  @SDL_CondWait             := nil;
  @SDL_CreateThread         := nil;
  @SDL_WaitThread           := nil;
  @SDL_AudioDriverName      := nil;
  @SDL_VideoDriverName      := nil;
end;

initialization
  SDLList := TStringList.Create;
  SDLLock := TCriticalSection.Create;

finalization
  SDLLock.Free;
  FreeAndNil(SDLList);

end.
