(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * This file is a unit of myutil library api stubs.
 * Created by CodeCoolie@CNSW 2008/03/20 -> $Date:: 2013-11-18 #$
 *)

unit MyUtilStubs;

interface

{$I CompilerDefines.inc}

{$IFDEF MSWINDOWS}
  {$DEFINE MSVCRT_DLL}
{$ENDIF}
{$IFDEF POSIX}
  {$UNDEF MSVCRT_DLL}
{$ENDIF}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  {$IFDEF MSWINDOWS}
    Winapi.Windows,
  {$ENDIF}
{$ELSE}
  Windows,
{$ENDIF}
  MyUtils;

const
  SEEK_SET = 0;
  {$EXTERNALSYM SEEK_SET}
  SEEK_CUR = 1;
  {$EXTERNALSYM SEEK_CUR}
  SEEK_END = 2;
  {$EXTERNALSYM SEEK_END}

type
  Tmy_atoiProc      = function(const nptr: PAnsiChar): Integer; cdecl;
  Tmy_fcloseProc    = function(fp: Pointer): Integer; cdecl;
  Tmy_ferrorProc    = function(fp: Pointer): Integer; cdecl;
  Tmy_fopenProc     = function(const path: PAnsiChar; const mode: PAnsiChar): Pointer; cdecl;
  Tmy_fprintfProc   = function(fp: Pointer; const fmt: PAnsiChar): Integer; cdecl varargs;
  Tmy_freadProc     = function(ptr: Pointer; size, nitems: Cardinal; fp: Pointer): Cardinal; cdecl;
  Tmy_fseekProc     = function(fp: Pointer; offset: Cardinal; whence: Integer): Integer; cdecl;
  Tmy_ftellProc     = function(fp: Pointer): Cardinal; cdecl;
  Tmy_fwriteProc    = function(const ptr: Pointer; size, nitems: Cardinal; fp: Pointer): Cardinal; cdecl;
{$IFDEF POSIX}
  Tmy_getenvProc    = function(const name: PAnsiChar): PAnsiChar; cdecl;
//  Tmy_putenvProc    = function(const variable: PAnsiChar): Integer; cdecl;
  Tmy_setenvProc    = function(const name, value: PAnsiChar; overwrite: Integer): Integer; cdecl;
  Tmy_unsetenvProc  = function(const name: PAnsiChar): Integer; cdecl;
{$ENDIF}
//  Tmy_memcmpProc    = function(const buf1, buf2: Pointer; count: Cardinal): Integer; cdecl;
  Tmy_snprintfProc  = function(buf: PAnsiChar; size: Cardinal; const fmt: PAnsiChar): Integer; cdecl varargs;
  Tmy_sscanfProc    = function(const str: PAnsiChar; const format: PAnsiChar): Integer; cdecl varargs;
  Tmy_strchrProc    = function(const s: PAnsiChar; c: AnsiChar): PAnsiChar; cdecl;
  Tmy_strcmpProc    = function(str1, str2: PAnsiChar): Integer; cdecl;
  Tmy_strcspnProc   = function(str1, str2: PAnsiChar): Cardinal; cdecl;
  Tmy_strncmpProc   = function(str1, str2: PAnsiChar; maxlen: Integer): Integer; cdecl;
  Tmy_strrchrProc   = function(const str: PAnsiChar; c: AnsiChar): PAnsiChar; cdecl;
  Tmy_strstrProc    = function(str1, str2: PAnsiChar): PAnsiChar; cdecl;
  Tmy_strtodProc    = function(const s: PAnsiChar; endptr: PPAnsiChar): Double; cdecl;
  Tmy_strtokProc    = function(s, delim: PAnsiChar): PAnsiChar; cdecl;
  Tmy_strtolProc    = function(const s: PAnsiChar; endptr: PPAnsiChar; radix: Integer): Integer; cdecl;
  Tmy_vsprintfProc  = function(buf: PAnsiChar; const fmt: PAnsiChar; vl: PAnsiChar): Integer; cdecl;
  Tmy_vsnprintfProc = function(buf: PAnsiChar; count: Integer; const fmt: PAnsiChar; vl: PAnsiChar): Integer; cdecl;

var
  my_atoi     : Tmy_atoiProc      = nil;
  my_fclose   : Tmy_fcloseProc    = nil;
  my_ferror   : Tmy_ferrorProc    = nil;
  my_fopen    : Tmy_fopenProc     = nil;
  my_fprintf  : Tmy_fprintfProc   = nil;
  my_fread    : Tmy_freadProc     = nil;
  my_fseek    : Tmy_fseekProc     = nil;
  my_ftell    : Tmy_ftellProc     = nil;
  my_fwrite   : Tmy_fwriteProc    = nil;
{$IFDEF POSIX}
  my_getenv   : Tmy_getenvProc    = nil;
//  my_putenv   : Tmy_putenvProc    = nil;
  my_setenv   : Tmy_setenvProc    = nil;
  my_unsetenv : Tmy_unsetenvProc  = nil;
{$ENDIF}
//  my_memcmp   : Tmy_memcmpProc    = nil;
  my_snprintf : Tmy_snprintfProc  = nil;
  my_sscanf   : Tmy_sscanfProc    = nil;
  my_strchr   : Tmy_strchrProc    = nil;
  my_strcmp   : Tmy_strcmpProc    = nil;
  my_strcspn  : Tmy_strcspnProc   = nil;
  my_strncmp  : Tmy_strncmpProc   = nil;
  my_strrchr  : Tmy_strrchrProc   = nil;
  my_strstr   : Tmy_strstrProc    = nil;
  my_strtod   : Tmy_strtodProc    = nil;
  my_strtok   : Tmy_strtokProc    = nil;
  my_strtol   : Tmy_strtolProc    = nil;
  my_vsprintf : Tmy_vsprintfProc  = nil;
  my_vsnprintf: Tmy_vsnprintfProc = nil;

function my_memcmp(const buf1, buf2: Pointer; count: Cardinal): Integer;

procedure MyUtilFixupStubs(const ALibFile: TPathFileName; const AHandle: THandle);
procedure MyUtilUnfixStubs;

implementation

function my_memcmp(const buf1, buf2: Pointer; count: Cardinal): Integer;
var
  b1, b2: PByte;
begin
  Assert(Assigned(buf1) and Assigned(buf2) and (count > 0));
  b1 := buf1;
  b2 := buf2;
  while count > 0 do
  begin
    if b1^ > b2^ then
    begin
      Result := 1;
      Exit;
    end;
    if b1^ < b2^ then
    begin
      Result := -1;
      Exit;
    end;
    Inc(b1);
    Inc(b2);
    Dec(count);
  end;
  Result := 0;
end;

procedure MyUtilFixupStubs(const ALibFile: TPathFileName; const AHandle: THandle);
begin
{$IFDEF MSVCRT_DLL}
  FixupStub(ALibFile, AHandle, 'atoi',        @my_atoi);
  FixupStub(ALibFile, AHandle, 'fclose',      @my_fclose);
  FixupStub(ALibFile, AHandle, 'ferror',      @my_ferror);
  FixupStub(ALibFile, AHandle, 'fopen',       @my_fopen);
  FixupStub(ALibFile, AHandle, 'fprintf',     @my_fprintf);
  FixupStub(ALibFile, AHandle, 'fread',       @my_fread);
  FixupStub(ALibFile, AHandle, 'fseek',       @my_fseek);
  FixupStub(ALibFile, AHandle, 'ftell',       @my_ftell);
  FixupStub(ALibFile, AHandle, 'fwrite',      @my_fwrite);
//  FixupStub(ALibFile, AHandle, 'memcmp',      @my_memcmp);
  FixupStub(ALibFile, AHandle, '_snprintf',   @my_snprintf);
  FixupStub(ALibFile, AHandle, 'sscanf',      @my_sscanf);
  FixupStub(ALibFile, AHandle, 'strchr',      @my_strchr);
  FixupStub(ALibFile, AHandle, 'strcmp',      @my_strcmp);
  FixupStub(ALibFile, AHandle, 'strcspn',     @my_strcspn);
  FixupStub(ALibFile, AHandle, 'strncmp',     @my_strncmp);
  FixupStub(ALibFile, AHandle, 'strrchr',     @my_strrchr);
  FixupStub(ALibFile, AHandle, 'strstr',      @my_strstr);
  FixupStub(ALibFile, AHandle, 'strtod',      @my_strtod);
  FixupStub(ALibFile, AHandle, 'strtok',      @my_strtok);
  FixupStub(ALibFile, AHandle, 'strtol',      @my_strtol);
  FixupStub(ALibFile, AHandle, 'vsprintf',    @my_vsprintf);
  FixupStub(ALibFile, AHandle, '_vsnprintf',  @my_vsnprintf);
{$ELSE}
  FixupStub(ALibFile, AHandle, 'my_atoi',     @my_atoi);
  FixupStub(ALibFile, AHandle, 'my_fclose',   @my_fclose);
  FixupStub(ALibFile, AHandle, 'my_ferror',   @my_ferror);
  FixupStub(ALibFile, AHandle, 'my_fopen',    @my_fopen);
  FixupStub(ALibFile, AHandle, 'my_fprintf',  @my_fprintf);
  FixupStub(ALibFile, AHandle, 'my_fread',    @my_fread);
  FixupStub(ALibFile, AHandle, 'my_fseek',    @my_fseek);
  FixupStub(ALibFile, AHandle, 'my_ftell',    @my_ftell);
  FixupStub(ALibFile, AHandle, 'my_fwrite',   @my_fwrite);
  FixupStub(ALibFile, AHandle, 'my_getenv',   @my_getenv);
//  FixupStub(ALibFile, AHandle, 'my_putenv',   @my_putenv);
  FixupStub(ALibFile, AHandle, 'my_setenv',   @my_setenv);
  FixupStub(ALibFile, AHandle, 'my_unsetenv', @my_unsetenv);
  FixupStub(ALibFile, AHandle, 'my_snprintf', @my_snprintf);
  FixupStub(ALibFile, AHandle, 'my_sscanf',   @my_sscanf);
  FixupStub(ALibFile, AHandle, 'my_strchr',   @my_strchr);
  FixupStub(ALibFile, AHandle, 'my_strcmp',   @my_strcmp);
  FixupStub(ALibFile, AHandle, 'my_strcspn',  @my_strcspn);
  FixupStub(ALibFile, AHandle, 'my_strncmp',  @my_strncmp);
  FixupStub(ALibFile, AHandle, 'my_strrchr',  @my_strrchr);
  FixupStub(ALibFile, AHandle, 'my_strstr',   @my_strstr);
  FixupStub(ALibFile, AHandle, 'my_strtod',   @my_strtod);
  FixupStub(ALibFile, AHandle, 'my_strtok',   @my_strtok);
  FixupStub(ALibFile, AHandle, 'my_strtol',   @my_strtol);
  FixupStub(ALibFile, AHandle, 'my_vsprintf', @my_vsprintf);
  FixupStub(ALibFile, AHandle, 'my_vsnprintf', @my_vsnprintf);
{$ENDIF}
end;

procedure MyUtilUnfixStubs;
begin
  @my_atoi      := nil;
  @my_fclose    := nil;
  @my_ferror    := nil;
  @my_fopen     := nil;
  @my_fprintf   := nil;
  @my_fread     := nil;
  @my_fseek     := nil;
  @my_ftell     := nil;
  @my_fwrite    := nil;
{$IFDEF POSIX}
  @my_getenv    := nil;
//  @my_putenv    := nil;
  @my_setenv    := nil;
  @my_unsetenv  := nil;
{$ENDIF}
  @my_snprintf  := nil;
  @my_sscanf    := nil;
  @my_strchr    := nil;
  @my_strcmp    := nil;
  @my_strcspn   := nil;
  @my_strncmp   := nil;
  @my_strrchr   := nil;
  @my_strstr    := nil;
  @my_strtod    := nil;
  @my_strtok    := nil;
  @my_strtol    := nil;
  @my_vsprintf  := nil;
  @my_vsnprintf := nil;
end;

end.
