unit umain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  JSONPropStorage, ExtCtrls, tgsendertypes;

type

  TIntervalo = (int5min, int10min, int30min, int1Hora, int2Hora, int5Hora);

type

  { TfrmMain }

  TfrmMain = class(TForm)
    Button1: TButton;
    cboIntervalo: TComboBox;
    edToken: TEdit;
    JSONPropStorage1: TJSONPropStorage;
    Label1: TLabel;
    Label2: TLabel;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    tmrIntervalo: TTimer;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FBot: TTelegramSender;
    function TimerIntervaloToString(aIntervalo: TIntervalo): String;
    function TimerIntervaloToInteger(aIntervalo: TIntervalo): Integer;
  public

  end;

const
  C_INTERVALO_5min   =     5000;
  C_INTERVALO_10min  =    10000;
  C_INTERVALO_30min  =    60000;
  C_INTERVALO_1hora  =  1800000;
  C_INTERVALO_2hora  =  3600000;
  C_INTERVALO_5horas =  9000000;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  edToken.Clear;
  JSONPropStorage1.JSONFileName := 'settings.json';
  JSONPropStorage1.Active := true;
  cboIntervalo.Items.Clear;
end;

function TfrmMain.TimerIntervaloToString(aIntervalo: TIntervalo): String;
begin


end;

function TfrmMain.TimerIntervaloToInteger(aIntervalo: TIntervalo): Integer;
begin

  case aIntervalo of

  end;


  C_INTERVALO_5min   =     5000;
  C_INTERVALO_10min  =    10000;
  C_INTERVALO_30min  =    60000;
  C_INTERVALO_1hora  =  1800000;
  C_INTERVALO_2hora  =  3600000;
  C_INTERVALO_5horas =  9000000;

end;

procedure TfrmMain.Button1Click(Sender: TObject);
begin
  JSONPropStorage1.Save;
end;

end.

