unit UFrmConfig;
interface
uses
  Classes, Controls, Forms,
  StdCtrls, ComCtrls;

type
  TFConfig = class(TForm)
    grpEqualizer: TGroupBox;
    lblBrightness: TLabel;
    lblContrast: TLabel;
    lblSaturation: TLabel;
    lblHue: TLabel;
    trbBrightness: TTrackBar;
    btnBrightness: TButton;
    trbContrast: TTrackBar;
    btnContrast: TButton;
    trbSaturation: TTrackBar;
    btnSaturation: TButton;
    trbHue: TTrackBar;
    btnHue: TButton;
    procedure trbBrightnessChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FConfig: TFConfig;

implementation

{$R *.dfm}

procedure TFConfig.trbBrightnessChange(Sender: TObject);
begin
  // change brightness range (-100 - 100)
//  frmPlayer.FBrightness := trbBrightness.Position;
end;

end.
