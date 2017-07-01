object FConfig: TFConfig
  Left = 477
  Top = 257
  Width = 263
  Height = 202
  BorderStyle = bsSizeToolWin
  Caption = 'FConfig'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object grpEqualizer: TGroupBox
    Left = 0
    Top = 0
    Width = 255
    Height = 137
    Align = alTop
    Caption = #35270#39057#22343#20540#22120
    TabOrder = 0
    object lblBrightness: TLabel
      Left = 8
      Top = 25
      Width = 24
      Height = 13
      Caption = #20142#24230
    end
    object lblContrast: TLabel
      Left = 8
      Top = 53
      Width = 36
      Height = 13
      Caption = #23545#27604#24230
    end
    object lblSaturation: TLabel
      Left = 8
      Top = 81
      Width = 36
      Height = 13
      Caption = #39281#21644#24230
    end
    object lblHue: TLabel
      Left = 8
      Top = 110
      Width = 24
      Height = 13
      Caption = #33394#24230
    end
    object trbBrightness: TTrackBar
      Left = 49
      Top = 21
      Width = 150
      Height = 22
      Max = 100
      Min = -100
      Frequency = 10
      TabOrder = 0
      TickStyle = tsNone
      OnChange = trbBrightnessChange
    end
    object btnBrightness: TButton
      Left = 196
      Top = 19
      Width = 53
      Height = 25
      Caption = #37325#32622
      TabOrder = 1
    end
    object trbContrast: TTrackBar
      Left = 49
      Top = 49
      Width = 150
      Height = 22
      Max = 100
      Min = -100
      Frequency = 10
      TabOrder = 2
      TickStyle = tsNone
    end
    object btnContrast: TButton
      Left = 196
      Top = 48
      Width = 53
      Height = 25
      Caption = #37325#32622
      TabOrder = 3
    end
    object trbSaturation: TTrackBar
      Left = 49
      Top = 78
      Width = 150
      Height = 22
      Max = 100
      Min = -100
      Frequency = 10
      TabOrder = 4
      TickStyle = tsNone
    end
    object btnSaturation: TButton
      Left = 196
      Top = 77
      Width = 53
      Height = 25
      Caption = #37325#32622
      TabOrder = 5
    end
    object trbHue: TTrackBar
      Left = 49
      Top = 107
      Width = 150
      Height = 22
      Max = 100
      Min = -100
      Frequency = 10
      TabOrder = 6
      TickStyle = tsNone
    end
    object btnHue: TButton
      Left = 196
      Top = 106
      Width = 53
      Height = 25
      Caption = #37325#32622
      TabOrder = 7
    end
  end
end
