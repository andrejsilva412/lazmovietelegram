program telegram;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, StrUtils, SysUtils, CustApp, tgsendertypes, configuration, eventlog,
  tgtypes, SQLDB, SQLite3Conn, fptimer, DOM, XMLRead, FileUtil
  { you can add units after this };

type

  { TTelegramApplication }

  TTelegramApplication = class(TCustomApplication)
  private
    FDataBase: TSQLite3Connection;
    FTransaction: TSQLTransaction;
    FQuery: TSQLQuery;
    FTimer : TFPTimer;
    FCount : Integer;
    FTick : Integer;
    N : TDateTime;
    FBot: TTelegramSender;
    function GetContentNode(NodeName: String; Node: TDOMNode): String;
    procedure OnTimerSend(Sender: TObject);
    procedure CloseDataBase;
    function GetSendDate(imdbid: String): TDateTime;
    procedure InitDataBase;
    procedure Send;
    function SendTelegramMessage(imdbid, AMsg: String): Boolean;
    procedure SearchMovie;
    procedure SearchTV;
    procedure SetSendDate(imdbid: String);
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
  end;

{ TTelegramApplication }

procedure TTelegramApplication.OnTimerSend(Sender: TObject);
begin
  Inc(FCount);
  FTick:=0;
  N:=Now;
  Send;
end;

procedure TTelegramApplication.CloseDataBase;
begin
  FDataBase.CloseDataSets;
  FDataBase.CloseTransactions;
  FDataBase.Close();
  FQuery.Free;
  FTransaction.Free;
  FDataBase.Free;
end;

function TTelegramApplication.GetSendDate(imdbid: String): TDateTime;
var
  StrSendDate: String;
  SendDate: TDateTime;
begin

  StrSendDate := '';
  SendDate := 0;
  FQuery.Close;
  FQuery.SQL.Clear;
  FQuery.SQL.Add('select senddate from movie where imdbid = :imdbid');
  FQuery.ParamByName('imdbid').AsString := imdbid;
  FQuery.Open;
  if not FQuery.IsEmpty then
  begin
    StrSendDate := FQuery.FieldByName('senddate').AsString;
  end else StrSendDate := '';

  if TryStrToDate(StrSendDate, SendDate) then
    SendDate := StrToDate(StrSendDate)
  else SendDate := 0;

  Result := SendDate;

end;

procedure TTelegramApplication.InitDataBase;
var
  FCreateTable: Boolean;
begin

  FCreateTable := false;

  FDataBase := TSQLite3Connection.Create(nil);
  FTransaction := TSQLTransaction.Create(nil);
  FQuery := TSQLQuery.Create(nil);
  FTransaction.DataBase := FDataBase;

  FDataBase.DatabaseName := 'movie.db';
  FDataBase.Open;
  FQuery.DataBase := FDataBase;
  FQuery.SQL.Clear;
  FQuery.SQL.Add('SELECT name FROM sqlite_master WHERE type=:type AND name=:name');
  FQuery.ParamByName('type').AsString := 'table';
  FQuery.ParamByName('name').AsString := 'movie';
  FQuery.Open;
  FCreateTable := FQuery.IsEmpty;
  FQuery.Close;
  if FCreateTable then
  begin
    FTransaction.Active := true;
    try
      FQuery.Close;
      FQuery.SQL.Clear;
      FQuery.SQL.Add('CREATE TABLE [movie] ([id] INTEGER  NOT NULL');
      FQuery.SQL.Add('PRIMARY KEY AUTOINCREMENT,');
      FQuery.SQL.Add('[imdbid] VARCHAR(44) UNIQUE NULL,');
      FQuery.SQL.Add('[senddate] VARCHAR(20)  NULL)');
      FQuery.ExecSQL;

      FQuery.Close;
      FQuery.SQL.Clear;
      FQuery.SQL.Add('CREATE UNIQUE INDEX [idximdbid] ON [movie](');
      FQuery.SQL.Add('[imdbid]  DESC)');
      FQuery.ExecSQL;
      FTransaction.CommitRetaining;
    except
      on E: Exception do
      begin
        FTransaction.RollbackRetaining;
        WriteLn(E.Message);
      end;
    end;
  end;

end;

procedure TTelegramApplication.Send;
begin
  SearchMovie;
  SearchTV;
end;

function TTelegramApplication.SendTelegramMessage(imdbid, AMsg: String
  ): Boolean;
begin
  try
    if FBot.sendMessage(Conf.TelegramChatID, AMsg) then
    begin
      SetSendDate(imdbid);
      WriteLn(AMsg);
      WriteLn(DupeString('-', 40));
    end;
    Result := true;
  except
    on E: Exception do
    begin
      Result := false;
      WriteLn(E.Message);
    end;
  end;
end;

procedure TTelegramApplication.SearchMovie;
var
  Files: TStringList;
  i, x: Integer;
  Str, imdbid, MovieTitle, ano, plot: String;
  XML: TXMLDocument;
  List: TDOMNodeList;
  Node: TDOMNode;
  SendDate: TDateTime;
begin

  Files := TStringList.Create;
  try
    FindAllFiles(Files, Conf.MovieFolder, C_NFO_FILE);
    x := 1;
    for i := 0 to Files.Count -1 do
    begin
      if x = MAX_SEND then
        break;
      Str := Files[i];
      try
        ReadXMLFile(XML, Str);
        List := XML.GetElementsByTagName('movie');
        Node := List.Item[0];
        imdbid := GetContentNode('imdbid', Node);
        SendDate := GetSendDate(imdbid);
        if SendDate = 0 then
        begin
          MovieTitle := 'Filme adicionado: ' + GetContentNode('title', Node) + LineEnding;
          ano := 'Ano de Lançamento: ' + GetContentNode('year', Node) + LineEnding;
          plot := GetContentNode('plot', Node);
          Str := MovieTitle + ano + plot;
          if SendTelegramMessage(imdbid, str) then
            inc(x);
        end;
      except
        on E: Exception do
        begin
          WriteLn(E.Message);
        end;
      end;
      Sleep(10000);
    end;
  finally
    FreeAndNil(Files);
  end;

end;

procedure TTelegramApplication.SearchTV;
begin

end;

procedure TTelegramApplication.SetSendDate(imdbid: String);
begin
  FTransaction.Active := true;
  try
    FQuery.Close;
    FQuery.SQL.Clear;
    FQuery.SQL.Add('insert into movie (imdbid, senddate)');
    FQuery.SQL.Add('values (:imdbid, :senddate)');
    FQuery.ParamByName('imdbid').AsString := imdbid;
    FQuery.ParamByName('senddate').AsString := DateToStr(Date);
    FQuery.ExecSQL;
    FTransaction.CommitRetaining;
  except
    on E: Exception do
    begin
      FTransaction.RollbackRetaining;
      WriteLn(E.Message);
    end;
  end;
end;

function TTelegramApplication.GetContentNode(NodeName: String; Node: TDOMNode
  ): String;
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

procedure TTelegramApplication.DoRun;
begin

  FTimer := TFPTimer.Create(nil);
  FTimer.Interval := Conf.Interval;
  FTimer.OnTimer := @OnTimerSend;
  FTimer.Enabled := true;
  try
    FTick := 0;
    FCount := 0;
    N := Now;
    while (FCount < 5) do
    begin
      Inc(FTick);
      Sleep(1);
      CheckSynchronize();
    end;
  finally
    FTimer.Enabled := true;
    FreeAndNil(FTimer);
  end;

end;

constructor TTelegramApplication.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FBot := TTelegramSender.Create(Conf.TelegramToken);
  InitDataBase;
end;

destructor TTelegramApplication.Destroy;
begin
  FTimer.Free;
  FBot.Logger.Free;
  FBot.Free;
  CloseDataBase;
  inherited Destroy;
end;

var
  Application: TTelegramApplication;
begin
  Application := TTelegramApplication.Create(nil);
  Application.Title := 'Laz Movie Telegram Bot';
  Application.Run;
  Application.Free;
end.

