(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * This file is a unit of SoundTouch library api stubs.
 * Created by CodeCoolie@CNSW 2013/11/25 -> $Date:: 2013-11-27 #$
 *)

unit SoundTouchStubs;

interface

{$I CompilerDefines.inc}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  {$IFDEF MSWINDOWS}
    Winapi.Windows,
  {$ENDIF}
{$ELSE}
  Windows,
{$ENDIF}
  MyUtils;

type
  /// Create a new instance of SoundTouch processor.
  Tsoundtouch_createInstanceProc = function(): Pointer; cdecl;

  /// Destroys a SoundTouch processor instance.
  Tsoundtouch_destroyInstanceProc = procedure(h: Pointer); cdecl;

  /// Get SoundTouch library version string
  Tsoundtouch_getVersionStringProc = function(): PAnsiChar; cdecl;

  /// Get SoundTouch library version string - alternative function for
  /// environments that can't properly handle character string as return value
  Tsoundtouch_getVersionString2Proc = procedure(versionString: PAnsiChar; bufferSize: Integer); cdecl;

  /// Get SoundTouch library version Id
  Tsoundtouch_getVersionIdProc = function(): Cardinal; cdecl;

  /// Sets new rate control value. Normal rate = 1.0, smaller values
  /// represent slower rate, larger faster rates.
  Tsoundtouch_setRateProc = procedure(h: Pointer; newRate: Single); cdecl;

  /// Sets new tempo control value. Normal tempo = 1.0, smaller values
  /// represent slower tempo, larger faster tempo.
  Tsoundtouch_setTempoProc = procedure(h: Pointer; newTempo: Single); cdecl;

  /// Sets new rate control value as a difference in percents compared
  /// to the original rate (-50 .. +100 %);
  Tsoundtouch_setRateChangeProc = procedure(h: Pointer; newRate: Single); cdecl;

  /// Sets new tempo control value as a difference in percents compared
  /// to the original tempo (-50 .. +100 %);
  Tsoundtouch_setTempoChangeProc = procedure(h: Pointer; newTempo: Single); cdecl;

  /// Sets new pitch control value. Original pitch = 1.0, smaller values
  /// represent lower pitches, larger values higher pitch.
  Tsoundtouch_setPitchProc = procedure(h: Pointer; newPitch: Single); cdecl;

  /// Sets pitch change in octaves compared to the original pitch
  /// (-1.00 .. +1.00);
  Tsoundtouch_setPitchOctavesProc = procedure(h: Pointer; newPitch: Single); cdecl;

  /// Sets pitch change in semi-tones compared to the original pitch
  /// (-12 .. +12);
  Tsoundtouch_setPitchSemiTonesProc = procedure(h: Pointer; newPitch: Single); cdecl;


  /// Sets the number of channels, 1 = mono, 2 = stereo
  Tsoundtouch_setChannelsProc = procedure(h: Pointer; numChannels: Cardinal); cdecl;

  /// Sets sample rate.
  Tsoundtouch_setSampleRateProc = procedure(h: Pointer; srate: Cardinal); cdecl;

  /// Flushes the last samples from the processing pipeline to the output.
  /// Clears also the internal processing buffers.
  //
  /// Note: This function is meant for extracting the last samples of a sound
  /// stream. This function may introduce additional blank samples in the end
  /// of the sound stream, and thus it's not recommended to call this function
  /// in the middle of a sound stream.
  Tsoundtouch_flushProc = procedure(h: Pointer); cdecl;

  /// Adds 'numSamples' pcs of samples from the 'samples' memory position into
  /// the input of the object. Notice that sample rate _has_to_ be set before
  /// calling this function, otherwise throws a runtime_error exception.
  Tsoundtouch_putSamplesProc = procedure(h: Pointer;
        const samples: PSingle;     ///< Pointer to sample buffer.
        numSamples: Cardinal        ///< Number of samples in buffer. Notice
                                    ///< that in case of stereo-sound a single sample
                                    ///< contains data for both channels.
        ); cdecl;

  /// Clears all the samples in the object's output and internal processing
  /// buffers.
  Tsoundtouch_clearProc = procedure(h: Pointer); cdecl;

  /// Changes a setting controlling the processing system behaviour. See the
  /// 'SETTING_...' defines for available setting ID's.
  ///
  /// \return 'TRUE' if the setting was succesfully changed
  Tsoundtouch_setSettingProc = function(h: Pointer;
                settingId,          ///< Setting ID number. see SETTING_... defines.
                value: Integer      ///< New setting value.
                ): LongBool{BOOL}; cdecl;

  /// Reads a setting controlling the processing system behaviour. See the
  /// 'SETTING_...' defines for available setting ID's.
  ///
  /// \return the setting value.
  Tsoundtouch_getSettingProc = function(h: Pointer;
                settingId: Integer  ///< Setting ID number, see SETTING_... defines.
                ): Integer; cdecl;


  /// Returns number of samples currently unprocessed.
  Tsoundtouch_numUnprocessedSamplesProc = function(h: Pointer): Cardinal; cdecl;

  /// Adjusts book-keeping so that given number of samples are removed from beginning of the
  /// sample buffer without copying them anywhere.
  ///
  /// Used to reduce the number of samples in the buffer when accessing the sample buffer directly
  /// with 'ptrBegin' function.
  Tsoundtouch_receiveSamplesProc = function(h: Pointer;
            outBuffer: PSingle;     ///< Buffer where to copy output samples.
            maxSamples: Cardinal    ///< How many samples to receive at max.
            ): Cardinal; cdecl;

  /// Returns number of samples currently available.
  Tsoundtouch_numSamplesProc = function(h: Pointer): Cardinal; cdecl;

  /// Returns nonzero if there aren't any samples available for outputting.
  Tsoundtouch_isEmptyProc = function(h: Pointer): Integer; cdecl;

var
  soundtouch_createInstance       : Tsoundtouch_createInstanceProc        = nil;
  soundtouch_destroyInstance      : Tsoundtouch_destroyInstanceProc       = nil;
  soundtouch_getVersionString     : Tsoundtouch_getVersionStringProc      = nil;
  soundtouch_getVersionString2    : Tsoundtouch_getVersionString2Proc     = nil;
  soundtouch_getVersionId         : Tsoundtouch_getVersionIdProc          = nil;
  soundtouch_setRate              : Tsoundtouch_setRateProc               = nil;
  soundtouch_setTempo             : Tsoundtouch_setTempoProc              = nil;
  soundtouch_setRateChange        : Tsoundtouch_setRateChangeProc         = nil;
  soundtouch_setTempoChange       : Tsoundtouch_setTempoChangeProc        = nil;
  soundtouch_setPitch             : Tsoundtouch_setPitchProc              = nil;
  soundtouch_setPitchOctaves      : Tsoundtouch_setPitchOctavesProc       = nil;
  soundtouch_setPitchSemiTones    : Tsoundtouch_setPitchSemiTonesProc     = nil;
  soundtouch_setChannels          : Tsoundtouch_setChannelsProc           = nil;
  soundtouch_setSampleRate        : Tsoundtouch_setSampleRateProc         = nil;
  soundtouch_flush                : Tsoundtouch_flushProc                 = nil;
  soundtouch_putSamples           : Tsoundtouch_putSamplesProc            = nil;
  soundtouch_clear                : Tsoundtouch_clearProc                 = nil;
  soundtouch_setSetting           : Tsoundtouch_setSettingProc            = nil;
  soundtouch_getSetting           : Tsoundtouch_getSettingProc            = nil;
  soundtouch_numUnprocessedSamples: Tsoundtouch_numUnprocessedSamplesProc = nil;
  soundtouch_receiveSamples       : Tsoundtouch_receiveSamplesProc        = nil;
  soundtouch_numSamples           : Tsoundtouch_numSamplesProc            = nil;
  soundtouch_isEmpty              : Tsoundtouch_isEmptyProc               = nil;

procedure SoundTouchFixupStubs(const ALibFile: TPathFileName; const AHandle: THandle);
procedure SoundTouchUnfixStubs;

implementation

procedure SoundTouchFixupStubs(const ALibFile: TPathFileName; const AHandle: THandle);
begin
{
  FixupStub(ALibFile, AHandle, '_soundtouch_createInstance@0',        @soundtouch_createInstance);
  FixupStub(ALibFile, AHandle, '_soundtouch_destroyInstance@4',       @soundtouch_destroyInstance);
  FixupStub(ALibFile, AHandle, '_soundtouch_getVersionString@0',      @soundtouch_getVersionString);
  FixupStub(ALibFile, AHandle, '_soundtouch_getVersionString2@8',     @soundtouch_getVersionString2);
  FixupStub(ALibFile, AHandle, '_soundtouch_getVersionId@0',          @soundtouch_getVersionId);
  FixupStub(ALibFile, AHandle, '_soundtouch_setRate@8',               @soundtouch_setRate);
  FixupStub(ALibFile, AHandle, '_soundtouch_setTempo@8',              @soundtouch_setTempo);
  FixupStub(ALibFile, AHandle, '_soundtouch_setRateChange@8',         @soundtouch_setRateChange);
  FixupStub(ALibFile, AHandle, '_soundtouch_setTempoChange@8',        @soundtouch_setTempoChange);
  FixupStub(ALibFile, AHandle, '_soundtouch_setPitch@8',              @soundtouch_setPitch);
  FixupStub(ALibFile, AHandle, '_soundtouch_setPitchOctaves@8',       @soundtouch_setPitchOctaves);
  FixupStub(ALibFile, AHandle, '_soundtouch_setPitchSemiTones@8',     @soundtouch_setPitchSemiTones);
  FixupStub(ALibFile, AHandle, '_soundtouch_setChannels@8',           @soundtouch_setChannels);
  FixupStub(ALibFile, AHandle, '_soundtouch_setSampleRate@8',         @soundtouch_setSampleRate);
  FixupStub(ALibFile, AHandle, '_soundtouch_flush@4',                 @soundtouch_flush);
  FixupStub(ALibFile, AHandle, '_soundtouch_putSamples@12',           @soundtouch_putSamples);
  FixupStub(ALibFile, AHandle, '_soundtouch_clear@4',                 @soundtouch_clear);
  FixupStub(ALibFile, AHandle, '_soundtouch_setSetting@12',           @soundtouch_setSetting);
  FixupStub(ALibFile, AHandle, '_soundtouch_getSetting@8',            @soundtouch_getSetting);
  FixupStub(ALibFile, AHandle, '_soundtouch_numUnprocessedSamples@4', @soundtouch_numUnprocessedSamples);
  FixupStub(ALibFile, AHandle, '_soundtouch_receiveSamples@12',       @soundtouch_receiveSamples);
  FixupStub(ALibFile, AHandle, '_soundtouch_numSamples@4',            @soundtouch_numSamples);
  FixupStub(ALibFile, AHandle, '_soundtouch_isEmpty@4',               @soundtouch_isEmpty);
}
  FixupStub(ALibFile, AHandle, 'soundtouch_createInstance',         @soundtouch_createInstance);
  FixupStub(ALibFile, AHandle, 'soundtouch_destroyInstance',        @soundtouch_destroyInstance);
  FixupStub(ALibFile, AHandle, 'soundtouch_getVersionString',       @soundtouch_getVersionString);
  FixupStub(ALibFile, AHandle, 'soundtouch_getVersionString2',      @soundtouch_getVersionString2);
  FixupStub(ALibFile, AHandle, 'soundtouch_getVersionId',           @soundtouch_getVersionId);
  FixupStub(ALibFile, AHandle, 'soundtouch_setRate',                @soundtouch_setRate);
  FixupStub(ALibFile, AHandle, 'soundtouch_setTempo',               @soundtouch_setTempo);
  FixupStub(ALibFile, AHandle, 'soundtouch_setRateChange',          @soundtouch_setRateChange);
  FixupStub(ALibFile, AHandle, 'soundtouch_setTempoChange',         @soundtouch_setTempoChange);
  FixupStub(ALibFile, AHandle, 'soundtouch_setPitch',               @soundtouch_setPitch);
  FixupStub(ALibFile, AHandle, 'soundtouch_setPitchOctaves',        @soundtouch_setPitchOctaves);
  FixupStub(ALibFile, AHandle, 'soundtouch_setPitchSemiTones',      @soundtouch_setPitchSemiTones);
  FixupStub(ALibFile, AHandle, 'soundtouch_setChannels',            @soundtouch_setChannels);
  FixupStub(ALibFile, AHandle, 'soundtouch_setSampleRate',          @soundtouch_setSampleRate);
  FixupStub(ALibFile, AHandle, 'soundtouch_flush',                  @soundtouch_flush);
  FixupStub(ALibFile, AHandle, 'soundtouch_putSamples',             @soundtouch_putSamples);
  FixupStub(ALibFile, AHandle, 'soundtouch_clear',                  @soundtouch_clear);
  FixupStub(ALibFile, AHandle, 'soundtouch_setSetting',             @soundtouch_setSetting);
  FixupStub(ALibFile, AHandle, 'soundtouch_getSetting',             @soundtouch_getSetting);
  FixupStub(ALibFile, AHandle, 'soundtouch_numUnprocessedSamples',  @soundtouch_numUnprocessedSamples);
  FixupStub(ALibFile, AHandle, 'soundtouch_receiveSamples',         @soundtouch_receiveSamples);
  FixupStub(ALibFile, AHandle, 'soundtouch_numSamples',             @soundtouch_numSamples);
  FixupStub(ALibFile, AHandle, 'soundtouch_isEmpty',                @soundtouch_isEmpty);
end;

procedure SoundTouchUnfixStubs;
begin
  @soundtouch_createInstance        := nil;
  @soundtouch_destroyInstance       := nil;
  @soundtouch_getVersionString      := nil;
  @soundtouch_getVersionString2     := nil;
  @soundtouch_getVersionId          := nil;
  @soundtouch_setRate               := nil;
  @soundtouch_setTempo              := nil;
  @soundtouch_setRateChange         := nil;
  @soundtouch_setTempoChange        := nil;
  @soundtouch_setPitch              := nil;
  @soundtouch_setPitchOctaves       := nil;
  @soundtouch_setPitchSemiTones     := nil;
  @soundtouch_setChannels           := nil;
  @soundtouch_setSampleRate         := nil;
  @soundtouch_flush                 := nil;
  @soundtouch_putSamples            := nil;
  @soundtouch_clear                 := nil;
  @soundtouch_setSetting            := nil;
  @soundtouch_getSetting            := nil;
  @soundtouch_numUnprocessedSamples := nil;
  @soundtouch_receiveSamples        := nil;
  @soundtouch_numSamples            := nil;
  @soundtouch_isEmpty               := nil;
end;

end.
