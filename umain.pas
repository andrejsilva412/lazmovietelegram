unit umain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  TypInfo, JSONPropStorage, ExtCtrls, tgsendertypes, tgtypes;

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
    Memo1: TMemo;
    Memo2: TMemo;
    PageControl1: TPageControl;
    Splitter1: TSplitter;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    tmrIntervalo: TTimer;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure tmrIntervaloTimer(Sender: TObject);
  private
    FBot: TTelegramSender;
    procedure BotReceiveUpdate(ASender: TObject; AnUpdate: TTelegramUpdateObj);
    procedure BotStartCmd(ASender: TObject; const ACommand: String;
      AMessage: TTelegramMessageObj);
    function TimerIntervaloToInteger(aIntervalo: TIntervalo): Integer;
    procedure BotSendMessage(ASender: TObject; const ACommand: String;
      AMessage: TTelegramMessageObj);
    procedure Notifica;
    procedure UpdateDelayed(Data: PtrInt);
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
var
  Intervalo: TIntervalo;
begin
  edToken.Clear;
  JSONPropStorage1.JSONFileName := 'settings.json';
  JSONPropStorage1.Active := true;
  cboIntervalo.Items.Clear;
  for Intervalo := Low(TIntervalo) to High(TIntervalo) do
    cboIntervalo.Items.Add(
      GetEnumName(TypeInfo(TIntervalo), Integer(Intervalo)));
  Memo1.Clear;
  Memo2.Clear;

  tmrIntervalo.Interval := 2000;
 // tmrIntervalo.Enabled := true;

   FBot := TTelegramSender.Create('5964318731:AAGRx8n5EoLSgZSVqL7NodX5xwvXzGWyVYI');
  FBot.CommandHandlers['/start'] := @BotStartCmd;
  FBot.CommandHandlers['/sinc'] := @BotSendMessage;
  FBot.OnReceiveUpdate   := @BotReceiveUpdate;
  if (Application.Flags*[AppDoNotCallAsyncQueue]) = [] then
    Application.QueueAsyncCall(@UpdateDelayed, 0);


end;

procedure TfrmMain.FormShow(Sender: TObject);
var
  Token: String;
begin
  Token := edToken.Text;

  if Token = '' then
  begin
    ShowMessage('Token não informado.');
    exit;
  end;



end;

procedure TfrmMain.tmrIntervaloTimer(Sender: TObject);
begin
  try
    tmrIntervalo.Enabled := false;
    Notifica;
    tmrIntervalo.Enabled := true;
  except
    tmrIntervalo.Enabled := true;
  end;
end;

function TfrmMain.TimerIntervaloToInteger(aIntervalo: TIntervalo): Integer;
begin

  case aIntervalo of
    int5min: Result  :=      5000;
    int10min: Result :=     10000;
    int30min: Result :=     60000;
    int1Hora: Result :=   1800000;
    int2Hora: Result :=   3600000;
    int5Hora: Result :=   9000000;
  end;

end;

procedure TfrmMain.BotSendMessage(ASender: TObject; const ACommand: String;
  AMessage: TTelegramMessageObj);
begin
  Memo2.Lines.Add(ACommand + ' FROM ' + AMessage.From.First_name);
end;

procedure TfrmMain.BotReceiveUpdate(ASender: TObject;
  AnUpdate: TTelegramUpdateObj);
begin
  if Assigned(AnUpdate) then
    Memo1.Lines.Add(AnUpdate.Message.AsString);
end;

procedure TfrmMain.BotStartCmd(ASender: TObject; const ACommand: String;
  AMessage: TTelegramMessageObj);
begin
  Memo2.Lines.Add(ACommand + ' FROM ' + AMessage.From.First_name);
end;

procedure TfrmMain.Notifica;
var
  Token: String;
begin
                {
  FBot := TTelegramSender.Create(Token);
  try

    if (Application.Flags*[AppDoNotCallAsyncQueue]) = [] then
      Application.QueueAsyncCall(@UpdateDelayed, 0);

  finally
    FreeAndNil(FBot);
  end;

               }
end;

procedure TfrmMain.UpdateDelayed(Data: PtrInt);
begin
  FBot.getUpdates;
  if (Application.Flags*[AppDoNotCallAsyncQueue]) = [] then
     Application.QueueAsyncCall(@UpdateDelayed, 0);
end;

procedure TfrmMain.Button1Click(Sender: TObject);
begin
  JSONPropStorage1.Save;
end;

end.

