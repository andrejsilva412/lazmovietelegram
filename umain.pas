unit umain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  TypInfo, SQLite3Conn, SQLDB, JSONPropStorage, ExtCtrls, EditBtn,
  tgsendertypes, tgtypes;

type

  TIntervalo = (int5min, int10min, int30min, int1Hora, int2Hora, int5Hora);

type

  { TMyBot }

  TMyBot = class(TTelegramSender)
    protected
      procedure InfoMessage(const Msg: String); override;
      procedure ErrorMessage(const Msg: String); override;
  end;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    Button1: TButton;
    cboIntervalo: TComboBox;
    DirectoryEdit1: TDirectoryEdit;
    DirectoryEdit2: TDirectoryEdit;
    edToken: TEdit;
    JSONPropStorage1: TJSONPropStorage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Memo1: TMemo;
    PageControl1: TPageControl;
    SQLite3Connection1: TSQLite3Connection;
    SQLQuery1: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    tmrHora: TTimer;
    tmrIntervalo: TTimer;
    procedure Button1Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure tmrHoraTimer(Sender: TObject);
    procedure tmrIntervaloTimer(Sender: TObject);
  private
    FToken: String;
    FData: TDateTime;
    procedure Search;
    procedure SearchMovie;
    procedure SearchTV;
    procedure InitDataBase;
    procedure CloseDataBase;
    function TimerIntervaloToInteger(aIntervalo: TIntervalo): Integer;
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TMyBot }

procedure TMyBot.InfoMessage(const Msg: String);
begin
  inherited InfoMessage(Msg);
  frmMain.Memo1.Lines.Add('Info: ' + Msg);
end;

procedure TMyBot.ErrorMessage(const Msg: String);
begin
  inherited ErrorMessage(Msg);
  frmMain.Memo1.Lines.Add('Error: ' + Msg);
end;

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
var
  Intervalo: TIntervalo;
begin
  FData := Date;
  edToken.Clear;
  DirectoryEdit1.Text := '';
  DirectoryEdit2.Text := '';
  JSONPropStorage1.JSONFileName := 'settings.json';
  JSONPropStorage1.Active := true;
  cboIntervalo.Items.Clear;
  for Intervalo := Low(TIntervalo) to High(TIntervalo) do
    cboIntervalo.Items.Add(
      GetEnumName(TypeInfo(TIntervalo), Integer(Intervalo)));
  Memo1.Clear;
  tmrIntervalo.Interval := 2000;
  tmrIntervalo.Enabled := true;
  InitDataBase;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  FToken := edToken.Text;
end;

procedure TfrmMain.tmrHoraTimer(Sender: TObject);
begin
  if FData < Date then
  begin
    Memo1.Lines.Clear;
    FData := Date;
  end;
end;

procedure TfrmMain.tmrIntervaloTimer(Sender: TObject);
begin
  try
    tmrIntervalo.Enabled := false;
    Search;
    tmrIntervalo.Enabled := true;
  except
    tmrIntervalo.Enabled := true;
  end;
end;

procedure TfrmMain.Search;
begin
  SearchMovie;
  SearchTV;
end;

procedure TfrmMain.SearchMovie;
var
  SR: TSearchRec;
begin



end;

procedure TfrmMain.SearchTV;
begin

end;

procedure TfrmMain.InitDataBase;
var
  FCreateTable: Boolean;
begin

  FCreateTable := false;
  SQLite3Connection1.DatabaseName := 'movie.db';
  SQLite3Connection1.Open;
  SQLQuery1.SQL.Clear;
  SQLQuery1.SQL.Add('SELECT name FROM sqlite_master WHERE type=:type AND name=:name');
  SQLQuery1.ParamByName('type').AsString := 'table';
  SQLQuery1.ParamByName('name').AsString := 'movie';
  SQLQuery1.Open;
  FCreateTable := not SQLQuery1.IsEmpty;
  SQLQuery1.Close;
  if FCreateTable then
  begin

    CREATE TABLE [movie] (
[id] INTEGER  NOT NULL PRIMARY KEY AUTOINCREMENT,
[imdbid] VARCHAR(44)  UNIQUE NULL
)



CREATE UNIQUE INDEX [idximdbid] ON [movie](
[imdbid]  DESC
)

  end;

end;

procedure TfrmMain.CloseDataBase;
begin
  SQLite3Connection1.CloseDataSets;
  SQLite3Connection1.CloseTransactions;
  SQLite3Connection1.Close();
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

procedure TfrmMain.Button1Click(Sender: TObject);
begin
  JSONPropStorage1.Save;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CloseDataBase;
end;

end.

