unit configuration;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

type

  TAppConfig = record
    TelegramToken: String;
    TelegramEndPoint: String;
    TelegramChatID: Int64;
    LogActive: Boolean;
    Interval: Cardinal;
    MovieFolder: String;
    TVFolder: String;
  end;

const
  MAX_SEND = 5;
  C_NFO_FILE = '*.nfo';

var
  Conf: TAppConfig;

implementation

uses IniFiles;

function ConfigFile: String;
begin
  Result := ChangeFileExt(ParamStr(0), '.ini');
end;

procedure LoadConfig(var aConf: TAppConfig);
var
  ini: TMemIniFile;
begin

  ini := TMemIniFile.Create(ConfigFile);
  try
    aConf.TelegramToken := ini.ReadString('TELEGRAM', 'TOKEN', EmptyStr);
    aConf.TelegramChatID := ini.ReadInt64('TELEGRAM', 'CHATID', 0);
    aConf.TelegramEndPoint := ini.ReadString('TELEGRAM', 'ENDPOINT', aConf.TelegramEndPoint);
    aConf.LogActive := ini.ReadBool('LOG', 'ACTIVE', true);
    aConf.Interval := ini.ReadInt64('TIMER', 'INTERVAL', 300000);
    aConf.MovieFolder := ini.ReadString('MOVIE', 'FOLDER', '');
    aConf.TVFolder := ini.ReadString('TV', 'FOLDER', '');
  finally
    FreeAndNil(ini);
  end;

end;

initialization
  LoadConfig(Conf);

end.

