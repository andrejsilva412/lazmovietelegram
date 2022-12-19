unit umain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  TypInfo, SQLite3Conn, SQLDB, JSONPropStorage, ExtCtrls, EditBtn,
  tgsendertypes, tgtypes, rxswitch, DOM, XMLRead, FileUtil;

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
    edChatID: TEdit;
    edToken: TEdit;
    JSONPropStorage1: TJSONPropStorage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Memo1: TMemo;
    PageControl1: TPageControl;
    RxSwitch1: TRxSwitch;
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
    procedure RxSwitch1Click(Sender: TObject);
    procedure tmrHoraTimer(Sender: TObject);
    procedure tmrIntervaloTimer(Sender: TObject);
  private
    FToken: String;
    FChatID: Integer;
    FData: TDateTime;
    FBot: TMyBot;
    procedure Search;
    procedure SearchMovie;
    procedure SearchTV;
    procedure InitDataBase;
    procedure CloseDataBase;
    procedure LoadConfig;
    function TimerIntervaloToInteger(aIntervalo: TIntervalo): Integer;
    function GetSendDate(imdbid: String): TDateTime;
    procedure SetSendDate(imdbid: String);
    function GetContentNode(NodeName: String; Node: TDOMNode): String;
    function RxSwitchToBoolean(ARxSwitch: TRxSwitch): Boolean;
    procedure SendTelegramMessage(imdbid, AMsg: String);
  public
    procedure InfoMessage(const Msg: String);
    procedure ErrorMessage(const MSg: String);
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TMyBot }

procedure TMyBot.InfoMessage(const Msg: String);
begin
  inherited InfoMessage(Msg);
  frmMain.InfoMessage(Msg);
end;

procedure TMyBot.ErrorMessage(const Msg: String);
begin
  inherited ErrorMessage(Msg);
  frmMain.ErrorMessage(Msg);
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
  edChatID.Text := '';
  JSONPropStorage1.JSONFileName := 'settings.json';
  JSONPropStorage1.Active := true;
  cboIntervalo.Items.Clear;
  for Intervalo := Low(TIntervalo) to High(TIntervalo) do
    cboIntervalo.Items.Add(
      GetEnumName(TypeInfo(TIntervalo), Integer(Intervalo)));
  Memo1.Clear;
  tmrIntervalo.Interval := TimerIntervaloToInteger(int5min);
  tmrIntervalo.Enabled := RxSwitchToBoolean(RxSwitch1);
  InitDataBase;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  LoadConfig;
end;

procedure TfrmMain.RxSwitch1Click(Sender: TObject);
begin
  tmrIntervalo.Enabled := RxSwitchToBoolean(RxSwitch1);
  LoadConfig;
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
  Files: TStringList;
  i: Integer;
  Str, imdbid, title: String;
  XML: TXMLDocument;
  List: TDOMNodeList;
  Node: TDOMNode;
  SendDate: TDateTime;
begin

  Files := TStringList.Create;
  try
    FindAllFiles(Files, DirectoryEdit1.Text, '*.*');
    for i := 0 to Files.Count -1 do
    begin
      Str := Files[i];
      try
        ReadXMLFile(XML, Str);
        List := XML.GetElementsByTagName('movie');
        Node := List.Item[0];
        imdbid := GetContentNode('imdbid', Node);
        SendDate := GetSendDate(imdbid);
        if SendDate = 0 then
        begin
          title := GetContentNode('title', Node);
          SendTelegramMessage(imdbid, 'Filme Adicionado: ' + title);
        end;
      except
        on E: Exception do
        begin
          ErrorMessage(E.Message);
        end;
      end;
    end;
  finally
    FreeAndNil(Files);
  end;

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
  FCreateTable := SQLQuery1.IsEmpty;
  SQLQuery1.Close;
  if FCreateTable then
  begin
    SQLTransaction1.Active := true;
    try
      SQLQuery1.Close;
      SQLQuery1.SQL.Clear;
      SQLQuery1.SQL.Add('CREATE TABLE [movie] ([id] INTEGER  NOT NULL');
      SQLQuery1.SQL.Add('PRIMARY KEY AUTOINCREMENT,');
      SQLQuery1.SQL.Add('[imdbid] VARCHAR(44) UNIQUE NULL,');
      SQLQuery1.SQL.Add('[senddate] VARCHAR(20)  NULL)');
      SQLQuery1.ExecSQL;

      SQLQuery1.Close;
      SQLQuery1.SQL.Clear;
      SQLQuery1.SQL.Add('CREATE UNIQUE INDEX [idximdbid] ON [movie](');
      SQLQuery1.SQL.Add('[imdbid]  DESC)');
      SQLQuery1.ExecSQL;
      SQLTransaction1.CommitRetaining;
    except
      on E: Exception do
      begin
        SQLTransaction1.RollbackRetaining;
        ShowMessage(E.Message);
      end;
    end;
  end;

end;

procedure TfrmMain.CloseDataBase;
begin
  SQLite3Connection1.CloseDataSets;
  SQLite3Connection1.CloseTransactions;
  SQLite3Connection1.Close();
end;

procedure TfrmMain.LoadConfig;
var
  intervalo: TIntervalo;
begin

  if Assigned(FBot) then
    FreeAndNil(FBot);

  FToken := edToken.Text;
  FChatID := StrToIntDef(edChatID.Text, 0);
  if FToken <> '' then
    FBot := TMyBot.Create(FToken);

  intervalo := TIntervalo(GetEnumValue(TypeInfo(TIntervalo), cboIntervalo.Items[cboIntervalo.ItemIndex]));
  tmrIntervalo.Enabled := false;
  tmrIntervalo.Interval := TimerIntervaloToInteger(intervalo);
  tmrIntervalo.Enabled := true;

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

function TfrmMain.GetSendDate(imdbid: String): TDateTime;
var
  StrSendDate: String;
  SendDate: TDateTime;
begin

  StrSendDate := '';
  SendDate := 0;
  SQLQuery1.Close;
  SQLQuery1.SQL.Clear;
  SQLQuery1.SQL.Add('select senddate from movie where imdbid = :imdbid');
  SQLQuery1.ParamByName('imdbid').AsString := imdbid;
  SQLQuery1.Open;
  if not SQLQuery1.IsEmpty then
  begin
    StrSendDate := SQLQuery1.FieldByName('senddate').AsString;
  end else StrSendDate := '';

  if TryStrToDate(StrSendDate, SendDate) then
    SendDate := StrToDate(StrSendDate)
  else SendDate := 0;

  Result := SendDate;

end;

procedure TfrmMain.SetSendDate(imdbid: String);
begin

  SQLTransaction1.Active := true;
  try
    SQLQuery1.Close;
    SQLQuery1.SQL.Clear;
    SQLQuery1.SQL.Add('insert into movie (imdbid, senddate)');
    SQLQuery1.SQL.Add('values (:imdbid, :senddate)');
    SQLQuery1.ParamByName('imdbid').AsString := imdbid;
    SQLQuery1.ParamByName('senddate').AsString := DateToStr(Date);
    SQLQuery1.ExecSQL;
    SQLTransaction1.CommitRetaining;
  except
    on E: Exception do
    begin
      SQLTransaction1.RollbackRetaining;
      ErrorMessage(E.Message);
    end;
  end;

end;

function TfrmMain.GetContentNode(NodeName: String; Node: TDOMNode): String;
var
  i: Integer;
begin

  Result := '';
  if Assigned(Node) then
  begin
    for i := 0 to Node.ChildNodes.Count -1 do
    begin
      if LowerCase(Node.ChildNodes.Item[i].NodeName) = NodeName then
      begin
        Result := Node.ChildNodes.Item[i].TextContent;
        break;
      end;
    end;
  end;

end;

function TfrmMain.RxSwitchToBoolean(ARxSwitch: TRxSwitch): Boolean;
begin
  if ARxSwitch.StateOn = sw_on then
    Result := true
  else Result := false;
end;

procedure TfrmMain.SendTelegramMessage(imdbid, AMsg: String);
begin
  if FBot.sendMessage(FChatID, AMsg) then
    SetSendDate(imdbid);
end;

procedure TfrmMain.InfoMessage(const Msg: String);
begin
  Memo1.Lines.Add('Info: ' + Msg);
end;

procedure TfrmMain.ErrorMessage(const MSg: String);
begin
  Memo1.Lines.Add('Error: ' + Msg);
end;

procedure TfrmMain.Button1Click(Sender: TObject);
begin
  JSONPropStorage1.Save;
  LoadConfig;
  PageControl1.ActivePageIndex := 0;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CloseDataBase;
  FreeAndNil(FBot);
end;

end.

