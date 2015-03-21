unit qlog;

interface

{$I 'qdac.inc'}
// QLOG_CREATE_GLOBALָ���Ƿ񴴽�Ĭ�ϵ�QLogsȫ�ֱ�����������壬�򴴽�Ĭ�ϵ�QLogs����
{$DEFINE QLOG_CREATE_GLOBAL}
{$IFNDEF NEXTGEN}
{$DEFINE QLOG_CREATE_DEFAULT_WRITER}
{$ENDIF !NEXTGEN}
{$DEFINE RENAME_HISTORY}
uses classes, SysUtils, qstring, SyncObjs{$IFDEF UNICODE}, ZLib{$ENDIF}
{$IFDEF POSIX}
    , Posix.Base, Posix.Stdio, Posix.Pthread, Posix.UniStd, IOUtils,
  Posix.NetDB, Posix.SysSocket,
  Posix.NetinetIn, Posix.arpainet, Posix.SysSelect, Posix.Systime
{$ELSE}
    , Windows, winsock
{$ENDIF};
{
  ��Դ������QDAC��Ŀ����Ȩ��swish(QQ:109867294)���С�
  (1)��ʹ����ɼ�����
  ���������ɸ��ơ��ַ����޸ı�Դ�룬�������޸�Ӧ�÷��������ߣ������������ڱ�Ҫʱ��
  �ϲ�������Ŀ���Թ�ʹ�ã��ϲ����Դ��ͬ����ѭQDAC��Ȩ�������ơ�
  ���Ĳ�Ʒ�Ĺ����У�Ӧ�������µİ汾����:
  ����Ʒʹ�õ���־��¼������QDAC��Ŀ�е�QLog����Ȩ���������С�
  (2)������֧��
  �м������⣬�����Լ���QDAC�ٷ�QQȺ250530692��ͬ̽�֡�
  (3)������
  ����������ʹ�ñ�Դ�������Ҫ֧���κη��á���������ñ�Դ������а�������������
  ������Ŀ����ǿ�ƣ�����ʹ���߲�Ϊ�������ȣ��и���ľ���Ϊ�����ָ��õ���Ʒ��
  ������ʽ��
  ֧������ guansonghuan@sina.com �����������
  �������У�
  �����������
  �˺ţ�4367 4209 4324 0179 731
  �����У��������г����ŷ索����
}

(*
  QLog��־��¼��Ԫ
  ��ע�⡿
  XE6�Դ���zlib֧����gzwrite�Ⱥ�������Delphi 2007�Դ���zlib��֧�֣���ˣ�QLog��
  Delphi 2007����ĳ���������ʱ����Я��zlib1.dll����XE6����İ汾����Ҫ��
  ��QLog��ʲô��
  ����Ԫ�����ṩһ�������ܵ���־��¼��Ԫ��ʹ�ü򵥵Ľӿ������־��¼���������ϲ�
  �����ڲ�ʵ���߼���
  1���ⲿ����ֻ��Ҫ����PostLog����(C++ Builder�û������Ե���AddLog)�Ϳ��������
  ־�ļ�¼.
  2��������Լ̳�ʵ�ָ�������(TQLogWriter)����־��ȡ�ӿ�(TQLogReader)����Ŀǰ��
  ��ֻʵ����TQLogFileWriter��TQLogSocketWriter��
  ����Ԫ��ļ��ɺͼ̳й�ϵ���£�
  ���ɣ�
  TQLog <- TQLogCastor <- TQLogWriter
  �̳У�
  TQLog
  TQLogWriter->TQLogFileWriter
  +->TQLogSocketWriter
  TQLogReader
  ����Ԫ����������ã�
  TQLog : ��־�������Ԫ�����ڻ�����Ҫ��¼����־
  TQLogCastor : ��־��̨д���̣߳�������־ʵ�ʸ�ʽ�������ø���TQLogWriterʵ�����д��
  TQLogWriter : ʵ�ʵ���־д�����
  TQLogReader : ��־��ȡ����������־�Ķ�λ�ͻ�ȡ
  TQLogFileWriter : ��־�ļ�д�����
  TQLogSocketWriter : ��־�ļ�syslog֧�ֶ��󣬿��Է�����־��syslog��������������������
*)
{ �޶���־
  =========

  2014.11.11
  ==========
  * ������ʹ��QLogʱ�������޷���������⣨�����ٷʱ��棩

  2014.11.6
  =========
  * �޸ĳ�������ʱ��־����Ϊ��Ĭ������ʱ�������������־�ļ��Ѿ����ڣ�����������ѹ���Ѿ�
  ���ڵ���־�ļ��������������������д��

  2014.11.5
  ==========
  * �޶��˿�ƽ̨����ʱ��sockaddr/sockaddr_in�������Ͷ����ͻ������

  2014.10.23
  ==========
  + TQLogSocketWriter����TCPЭ��ѡ�ͨ���޸�UseTCP���������ƣ�Ĭ��ʹ��UDP

  2014.8.2
  =========
  * ������CreateItemʱ�����־����Ϊ��ʱ������Խ�������

  2014.6.26
  =========
  * ����HPPEMITĬ�����ӱ���Ԫ(�����ٷ� ����)

  2014.6.21
  =========
  * ������2010������TThreadIdû��������޷����������
}
{$M+}
{$HPPEMIT '#pragma link "qlog"'}

type
  { ��־��¼ģʽ
    lmSync : ͬ��ģʽ���ȴ���־д�����
    lmAsyn : �첽ģʽ�����ȴ���־д�����
  }
  TQLogMode = (lmSync, lmAsyn);
  {
    C++:
    ����$HPPEMITָ������ǿ�Ʒ�����#include֮����������֮ǰ���������TLogLevel
    δ����������޷����룬���ʹ��ģ��ͺ��������£��Ա��ͺ����
  }
{$HPPEMIT '#include <stdio.h>'}
{$HPPEMIT 'template<class TLogLevel> void PostLog(TLogLevel ALevel,const wchar_t *format,...)'}
{$HPPEMIT '{'}
{$HPPEMIT 'int ASize;'}
{$HPPEMIT 'QStringW AMsg;'}
{$HPPEMIT 'va_list args;'}
{$HPPEMIT 'va_start(args, format);}
{$HPPEMIT 'ASize=vsnwprintf(NULL, 0, format, args);}
{$HPPEMIT 'AMsg.SetLength(ASize);'}
{$IFDEF UNICODE}
{$HPPEMIT 'vsnwprintf(AMsg.c_str(), ASize+1, format, args);'}
{$ELSE}
{$HPPEMIT 'vsnwprintf(AMsg.c_bstr(),ASize+1,format,args);'}
{$ENDIF}
{$HPPEMIT 'PostLog(ALevel,AMsg);'}
{$HPPEMIT 'va_end(args);'}
(*$HPPEMIT '}'*)
{$HPPEMIT '#define AddLog PostLog<TQLogLevel>'}
  {
    //������Linux��Syslog��־������
    0       Emergency: system is unusable
    1       Alert: action must be taken immediately
    2       Critical: critical conditions
    3       Error: error conditions
    4       Warning: warning conditions
    5       Notice: normal but significant condition
    6       Informational: informational messages
    7       Debug: debug-level messages
  }

  TQLogLevel = (llEmergency, llAlert, llFatal, llError, llWarning, llHint,
    llMessage, llDebug);
  TQLog = class;
  TQLogCastor = class;
  TQLogWriter = class;
  TQLogReader = class;
{$IF RTLVersion<22}
  TThreadId = LongWord;
{$IFEND}
  // ��־��¼��Ŀ
  PQLogItem = ^TQLogItem;

  TQLogItem = record
    Next, Prior: PQLogItem;
    ThreadId: TThreadId;
    TimeStamp: TDateTime;
    Level: TQLogLevel;
    MsgLen: Integer;
    Text: array [0 .. 0] of WideChar;
  end;

  TQLogList = record
    case Integer of
      0:
        (Value: Int64;);
      1:
        (First: PQLogItem;
          Last: PQLogItem;
        );
      2:
        (FirstVal: Integer;
          LastVal: Integer;
        );
  end;

  // ��־����
  TQLog = class
  protected
    FList: TQLogList;
    FCastor: TQLogCastor;
    FInFree: Boolean;
    FCount: Integer;
    FFlushed: Integer;
    FFlags: Integer;
    FCS: TCriticalSection;
    procedure Lock;
    procedure Unlock;
    function Pop: PQLogItem;
    function CreateCastor: TQLogCastor; virtual;
    function GetCastor: TQLogCastor;
  public
    constructor Create; overload;
    destructor Destroy; override;
    procedure Post(ALevel: TQLogLevel; const AMsg: QStringW); overload;
    procedure Post(ALevel: TQLogLevel; const AFormat: QStringW;
      Args: array of const); overload;
    property Castor: TQLogCastor read GetCastor;
    property Count: Integer read FCount;
    property Flushed: Integer read FFlushed;
  end;

  // ��־д�����
  TQLogWriter = class
  protected
    FCastor: TQLogCastor;
  public
    constructor Create; overload;
    destructor Destroy; override;
    procedure HandleNeeded; virtual;
    function WriteItem(AItem: PQLogItem): Boolean; virtual;
  end;

  // ��־��ȡ����
  TQLogReader = class
  protected
    FItemIndex: Int64;
    function GetCount: Int64; virtual;
    procedure SetItemIndex(const Value: Int64);
  public
    constructor Create; overload;
    destructor Destroy; override;
    function ReadItem(var AMsg: QStringW; ALevel: TQLogLevel): Boolean; virtual;
    function First: Boolean;
    function Last: Boolean;
    function Prior: Boolean;
    function Next: Boolean;
    function MoveTo(AIndex: Int64): Boolean; virtual;
    property Count: Int64 read GetCount;
    property ItemIndex: Int64 read FItemIndex write SetItemIndex;
  end;

  PLogWriterItem = ^TLogWriterItem;

  TLogWriterItem = record
    Next, Prior: PLogWriterItem;
    Writer: TQLogWriter;
  end;

  // ��־�㲥�������ڽ���־���͵���Ӧ�Ķ����籾��ϵͳ�ļ�������Զ����־����
  TQLogCastor = class(TThread)
  protected
    FLastError: Cardinal;
    FLastErrorMsg: QStringW;
    FNotifyHandle: TEvent;
    FCS: TCriticalSection;
    FOwner: TQLog;
    FWriters: PLogWriterItem;
    FActiveWriter: PLogWriterItem;
    FActiveLog: PQLogItem;
    procedure Execute; override;
    procedure LogAdded;
    function WaitForLog: Boolean; virtual;
    function FetchNext: PQLogItem; virtual;
    function FirstWriter: PLogWriterItem;
    function NextWriter: PLogWriterItem;
{$IFNDEF UNICODE}
    function GetFinished: Boolean;
{$ENDIF}
  published
  public
    constructor Create(AOwner: TQLog); overload;
    destructor Destroy; override;
    procedure SetLastError(ACode: Cardinal; const AMsg: QStringW);
    procedure AddWriter(AWriter: TQLogWriter);
    procedure RemoveWriter(AWriter: TQLogWriter);
    property ActiveLog: PQLogItem read FActiveLog;
{$IFNDEF UNICODE}
    property Finished: Boolean read GetFinished;
{$ENDIF}
  end;

  TQLogFileWriter = class(TQLogWriter)
  protected
    // ��������־�ļ����
    FLogHandle, FIndexHandle: TFileStream;
    FFileName: QStringW;
    FIndexNeeded: Boolean;
    FBuffer: TBytes;
    FBuffered: Integer;
    FPosition: Int64;
    FLastTime: TDateTime;
    FLastThreadId: Cardinal;
    FLastTimeStamp, FLastThread: QStringW;
    FBuilder: TQStringCatHelperW;
    function FlushBuffer(AStream: TStream; p: Pointer; l: Integer): Boolean;
    procedure CompressLog(ALogFileName, AIndexFileName: QStringW);
    procedure RenameHistory;
  public
    /// ����һ����־�ļ�
    /// <param name="AFileName">�ļ���</param>
    /// <param name="AWithIndex">�Ƿ�ͬʱ���������ļ�</param>
    /// <remarks>
    /// ���������ļ������ڼ�����־ʱ���ٶ�λ��־����ʼλ�ã�Ҳ���Բ�����������־��
    /// �����������������λ��ĳһ�ض���־ʱ������Ҫ�����IO����
    constructor Create(const AFileName: QStringW;
      AWithIndex: Boolean = False); overload;
    constructor Create; overload;
    destructor Destroy; override;
    function WriteItem(AItem: PQLogItem): Boolean; override;
    procedure HandleNeeded; override;
    property FileName: QStringW read FFileName;
  end;

  TQLogConsoleWriter = class(TQLogWriter)
  public
    constructor Create; overload;
    function WriteItem(AItem: PQLogItem): Boolean; override;
    procedure HandleNeeded; override;
  end;

  // Linux syslog����д��
  TQLogSocketWriter = class(TQLogWriter)
  private
    FServerPort: Word;
    FServerHost: String;
    FSocket: THandle;
    FReaderAddr: sockaddr_in;
    FBuilder: TQStringCatHelperW;
    FTextEncoding: TTextEncoding;
    FUseTCP: Boolean;
    FLastConnectTryTime: TDateTime;
    procedure SetTextEncoding(const Value: TTextEncoding);
    function ConnectNeeded: Boolean;
  public
    constructor Create; overload;
    destructor Destroy; override;
    function WriteItem(AItem: PQLogItem): Boolean; override;
    procedure HandleNeeded; override;
    property ServerHost: String read FServerHost write FServerHost;
    property ServerPort: Word read FServerPort write FServerPort;
    property TextEncoding: TTextEncoding read FTextEncoding
      write SetTextEncoding;
    property UseTCP: Boolean read FUseTCP write FUseTCP;
  end;

procedure PostLog(ALevel: TQLogLevel; const AMsg: QStringW); overload;
procedure PostLog(ALevel: TQLogLevel; const fmt: PWideChar;
  Args: array of const); overload;
{$IFDEF POSIX}
function GetCurrentProcessId: Integer;
{$ENDIF}

const
  ELOG_WRITE_FAILURE = $80000001;

var
  Logs: TQLog;
  MaxLogFileSize: Int64;

implementation

resourcestring
  SLogSeekError = '�޷���λ����%d����־��¼';
  SHandleNeeded = '��Ҫ����־д��������޷�������';
  SCantCreateLogFile = '�޷�����ָ������־�ļ� "%s"��';
  SCantCreateCastor = '�޷�������־�㲥����';
  SUnsupportSysLogEncoding = 'Syslogֻ֧��Ansi��Utf8�������ָ�ʽ��';
  SZlibDLLMissed = 'zlib1.dllδ�ҵ�����֧��ѹ���־���־��';

const
  SItemBreak: array [0 .. 2] of WideChar = (#$3000, #13, #10);
  LogLevelText: array [llEmergency .. llDebug] of QStringW = ('[EMG]',
    '[ALERT]', '[FATAL]', '[ERROR]', '[WARN]', '[HINT]', '[MSG]', '[DEBUG]');

type
  TQLogCompressThread = class(TThread)
  protected
    FLogFileName, FIndexFileName: QStringW;
    procedure Execute; override;
  public
    constructor Create(ALogFileName, AIndexFileName: QStringW); overload;
  end;
{$IF RTLVersion<26}

  gzFile = Pointer;
  z_off_t = Longint;
  _gzopen = function(path: PAnsiChar; mode: PAnsiChar): gzFile; cdecl;
  _gzseek = function(file_: gzFile; offset: z_off_t; flush: Integer)
    : z_off_t; cdecl;
  _gztell = function(file_: gzFile): z_off_t; cdecl;
  _gzwrite = function(file_: gzFile; const buf; len: Cardinal): Integer; cdecl;
  _gzclose = function(file_: gzFile): Integer; cdecl;

var
  gzopen: _gzopen;
  gzseek: _gzseek;
  gztell: _gztell;
  gzwrite: _gzwrite;
  gzclose: _gzclose;
  zlibhandle: THandle;
{$IFEND <XE5UP}
{$IFDEF POSIX}

function GetCurrentProcessId: Integer;
begin
Result := getpid;
end;
{$ENDIF}

procedure PostLog(ALevel: TQLogLevel; const AMsg: QStringW);
begin
Logs.Post(ALevel, AMsg);
end;

procedure PostLog(ALevel: TQLogLevel; const fmt: PWideChar;
  Args: array of const);
begin
Logs.Post(ALevel, fmt, Args);
end;

function CreateItemBuffer(ALevel: TQLogLevel; AMsgLen: Integer): PQLogItem;
begin
GetMem(Result, SizeOf(TQLogItem) + AMsgLen);
Result.Next := nil;
Result.ThreadId := GetCurrentThreadId;
Result.TimeStamp := Now;
Result.Level := ALevel;
Result.MsgLen := AMsgLen;
end;

function CreateItem(const AMsg: QStringW; ALevel: TQLogLevel): PQLogItem;
var
  ALen: Integer;
begin
ALen := Length(AMsg) shl 1;
Result := CreateItemBuffer(ALevel, ALen);
if Result.MsgLen > 0 then
  Move(PQCharW(AMsg)^, Result.Text[0], Result.MsgLen);
end;

procedure FreeItem(AItem: PQLogItem);
begin
FreeMem(AItem);
end;

// TQLogReader
constructor TQLogReader.Create;
begin

end;

destructor TQLogReader.Destroy;
begin

inherited;
end;

function TQLogReader.First: Boolean;
begin
Result := MoveTo(0);
end;

function TQLogReader.GetCount: Int64;
begin
Result := 0;
end;

function TQLogReader.Last: Boolean;
begin
Result := MoveTo(Count - 1);
end;

function TQLogReader.MoveTo(AIndex: Int64): Boolean;
begin
Result := False;
end;

function TQLogReader.Next: Boolean;
begin
Result := MoveTo(FItemIndex + 1);
end;

function TQLogReader.Prior: Boolean;
begin
Result := MoveTo(FItemIndex - 1);
end;

function TQLogReader.ReadItem(var AMsg: QStringW; ALevel: TQLogLevel): Boolean;
begin
Result := False;
end;

procedure TQLogReader.SetItemIndex(const Value: Int64);
begin
if FItemIndex <> Value then
  begin
  if not MoveTo(Value) then
    raise EXCEPTIOn.Create(Format(SLogSeekError, [Value]));
  end;
end;

// TQLogWriter
constructor TQLogWriter.Create;
begin
inherited;
end;

destructor TQLogWriter.Destroy;
begin
inherited;
end;

procedure TQLogWriter.HandleNeeded;
begin
raise EXCEPTIOn.Create(SHandleNeeded);
end;

function TQLogWriter.WriteItem(AItem: PQLogItem): Boolean;
begin
Result := False;
end;

{ TQLogFile }

constructor TQLogFileWriter.Create(const AFileName: QStringW;
  AWithIndex: Boolean);
begin
inherited Create;
FFileName := AFileName;
FIndexNeeded := AWithIndex;
FLogHandle := nil;
FIndexHandle := nil;
SetLength(FBuffer, 65536); // 64K������
FBuilder := TQStringCatHelperW.Create;
end;

procedure TQLogFileWriter.CompressLog(ALogFileName, AIndexFileName: QStringW);
begin
{$IF RTLVersion<26}
if not Assigned(gzopen) then
  PostLog(llWarning, SZlibDLLMissed)
else
{$IFEND <XE5}
  TQLogCompressThread.Create(ALogFileName, AIndexFileName);
end;

constructor TQLogFileWriter.Create;
{$IFDEF MSWINDOWS}
var
  AExt: QStringW;
{$ENDIF MSWINDOWS}
begin
inherited Create;
FBuilder := TQStringCatHelperW.Create;
{$IFDEF MSWINDOWS}
SetLength(FFileName, MAX_PATH);
{$IFDEF UNICODE}
SetLength(FFileName, GetModuleFileName(0, PQCharW(FFileName), MAX_PATH));
{$ELSE}
SetLength(FFileName, GetModuleFileNameW(0, PQCharW(FFileName), MAX_PATH));
{$ENDIF}
AExt := ExtractFileExt(FFileName);
if Length(AExt) > 0 then
  FFileName := Copy(PQCharW(FFileName), 0, Length(FFileName) - Length(AExt)
    ) + '.log'
else
  FFileName := FFileName + '.log';
{$ELSE}
FFileName := TPath.GetSharedDocumentsPath + TPath.DirectorySeparatorChar +
  FormatDateTime('yyyymmddhhnnss', Now) + '.log';
{$ENDIF}
end;

destructor TQLogFileWriter.Destroy;
begin
FreeObject(FBuilder);
{$IFDEF NEXTGEN}
if Assigned(FLogHandle) then
  FLogHandle.DisposeOf;
if Assigned(FIndexHandle) then
  FIndexHandle.DisposeOf;
{$ELSE}
if Assigned(FLogHandle) then
  FLogHandle.Free;
if Assigned(FIndexHandle) then
  FIndexHandle.Free;
{$ENDIF UNICODE}
inherited;
end;

function TQLogFileWriter.FlushBuffer(AStream: TStream; p: Pointer;
  l: Integer): Boolean;
var
  AWriteBytes: Cardinal;
  ps: PByte;
begin
Result := True;
ps := p;
repeat
  AWriteBytes := AStream.Write(ps^, l);
  if AWriteBytes = 0 then
    begin
    FCastor.SetLastError(ELOG_WRITE_FAILURE, SysErrorMessage(GetLastError));
    Result := False;
    Break
    end
  else
    begin
    Dec(l, AWriteBytes);
    Inc(ps, AWriteBytes);
    end;
until l = 0;
end;

procedure TQLogFileWriter.HandleNeeded;
var
  AIndexFile, ALogFileName, AExt: QStringW;
  AIndex: Cardinal;
  function CanAccess(AFileName: QStringW): Boolean;
  var
    AHandle: THandle;
  begin
  AHandle := FileOpen(AFileName, fmOpenReadWrite);
  if AHandle = THandle(-1) then
    Result := False
  else
    begin
    Result := True;
    FileClose(AHandle);
    end;
  end;
  procedure NextFileName;
  begin
  FFileName := ALogFileName + '_' + IntToStr(GetCurrentProcessId) + '_'+
    IntToStr(AIndex) + AExt;
  Inc(AIndex);
  end;

begin
{$IFDEF RENAME_HISTORY}
if FileExists(FFileName) and CanAccess(FFileName)  then
  RenameHistory
else
{$ENDIF}
  begin
  if not Assigned(FLogHandle) then
    begin
    AIndex := 1;
    AExt := ExtractFileExt(FFileName);
    ALogFileName := Copy(FFileName, 1, Length(FFileName) - Length(AExt));
    repeat
      try
        if (not FileExists(FFileName)) or CanAccess(FFileName) then
          begin
          FLogHandle := TFileStream.Create(FFileName, fmCreate);
          // �ðɣ������Ľ�ֹ���˶����Ҵ����ٴ򿪻�������
          FreeObject(FLogHandle);
          FLogHandle := TFileStream.Create(FFileName, fmOpenWrite or
            fmShareDenyWrite);
          end
        else
          NextFileName;
      except
        NextFileName;
      end;
    until Assigned(FLogHandle) or (AIndex = 100);
    if AIndex <> 1 then
      AIndexFile := ALogFileName + '_' + IntToStr(AIndex - 1) + '.lidx'
    else
      AIndexFile := ALogFileName + '.lidx';
    if FIndexNeeded then
      begin
      AIndex := 1;
      repeat
        try
          FIndexHandle := TFileStream.Create(AIndexFile,
            fmCreate or fmShareDenyWrite);
        except
          AIndexFile := ALogFileName + '_' + IntToStr(AIndex) + '.lidx';
          Inc(AIndex);
        end;
      until Assigned(FIndexHandle) or (AIndex = 100);
      end;
    FLogHandle.WriteBuffer(#$FF#$FE, 2);
    FPosition := FLogHandle.Position;
    end;
  end;
end;

procedure TQLogFileWriter.RenameHistory;
var
  ALogFileName, AOldName, AIndexFileName, ATimeStamp, AExt: QStringW;
begin
if Assigned(FLogHandle) then
  begin
  AOldName := FLogHandle.FileName;
  FreeObject(FLogHandle);
  FLogHandle := nil;
  end
else
  AOldName := FFileName;
AExt := ExtractFileExt(AOldName);
ATimeStamp := FormatDateTime('yyyymmddhhnnsszzz', Now);
ALogFileName := StrDupX(PQCharW(AOldName), Length(AOldName) - Length(AExt)) +
  '_' + ATimeStamp + AExt;
if RenameFile(FFileName, ALogFileName) then
  begin
  if Assigned(FIndexHandle) then
    begin
    AOldName := FIndexHandle.FileName;
    AExt := ExtractFileExt(AOldName);
    FreeObject(FIndexHandle);
    AIndexFileName := StrDupX(PQCharW(AOldName), Length(AOldName) - Length(AExt)
      ) + '_' + ATimeStamp + AExt;
    RenameFile(AOldName, AIndexFileName);
    FIndexHandle := nil;
    end;
  // �����߳�ѹ����־�ļ�
  CompressLog(ALogFileName, AIndexFileName);
  end;
HandleNeeded;
end;

function TQLogFileWriter.WriteItem(AItem: PQLogItem): Boolean;
  procedure TimeChangeCheck;
  var
    ADayChanged: Boolean;
  begin
  if FLastTime <> AItem.TimeStamp then
    begin
    if Trunc(FLastTime) <> Trunc(AItem.TimeStamp) then
      ADayChanged := True
    else
      ADayChanged := False;
    FLastTime := AItem.TimeStamp;
    if ADayChanged then
      FBuilder.Cat(FormatDateTime('[yyyy-mm-dd]', FLastTime)).Cat(SLineBreak);
    FLastTimeStamp := FormatDateTime('[hh:nn:ss.zzz]', FLastTime);
    end;
  end;

begin
Result := False;
if FLogHandle <> nil then
  begin
  FBuilder.Position := 0;
  TimeChangeCheck;
  if FLastThreadId <> AItem.ThreadId then
    begin
    FLastThreadId := AItem.ThreadId;
    FLastThread := '[' + IntToStr(FLastThreadId) + ']';
    end;
  FBuilder.Cat(FLastTimeStamp).Cat(FLastThread).Cat(LogLevelText[AItem.Level])
    .Cat(':').Cat(@AItem.Text[0], AItem.MsgLen shr 1);
  if FIndexHandle = nil then
    FBuilder.Cat(SLineBreak);
  Result := FlushBuffer(FLogHandle, FBuilder.Start, FBuilder.Position shl 1);
  if Result and (FIndexHandle <> nil) then
    Result := FlushBuffer(FIndexHandle, @FPosition, SizeOf(Int64));
  Inc(FPosition, (FBuilder.Position shl 1));
  if (MaxLogFileSize > 0) and (FPosition >= MaxLogFileSize) then
    // ����������־�ļ���С���ƣ������ڵ���־�ļ���������ѹ������
    RenameHistory;
  end;
end;

{ TQLogCastor }
// ����ӵ�ʼ����ǰ��
procedure TQLogCastor.AddWriter(AWriter: TQLogWriter);
var
  AItem: PLogWriterItem;
begin
AWriter.HandleNeeded;
New(AItem);
AItem.Prior := nil;
AItem.Writer := AWriter;
AWriter.FCastor := Self;
FCS.Enter;
AItem.Next := FWriters;
if Assigned(FWriters) then
  FWriters.Prior := AItem;
FWriters := AItem;
FCS.Leave;
end;

constructor TQLogCastor.Create(AOwner: TQLog);
begin
inherited Create(True);
FCS := TCriticalSection.Create;
FNotifyHandle := TEvent.Create(nil, False, False, '');
FOwner := AOwner;
Suspended := False;
end;

destructor TQLogCastor.Destroy;
var
  AItem: PLogWriterItem;
begin
while Assigned(FWriters) do
  begin
  AItem := FWriters.Next;
  FWriters.Writer.Free;
  Dispose(FWriters);
  FWriters := AItem;
  end;
{$IFDEF NEXTGEN}
FNotifyHandle.DisposeOf;
FCS.DisposeOf;
{$ELSE}
FNotifyHandle.Free;
FCS.Free;
{$ENDIF}
inherited;
end;

procedure TQLogCastor.Execute;
var
  APrior: PQLogItem;
  procedure WriteItem;
  begin
  FirstWriter;
  while Assigned(FActiveWriter) do
    begin
    if not FActiveWriter.Writer.WriteItem(ActiveLog) then
      begin
      if FLastError = ELOG_WRITE_FAILURE then
        begin
        // Write Error handle
        end;
      end;
    NextWriter;
    end;
  end;

begin
while not Terminated do
  begin
  if WaitForLog then
    begin
    FActiveLog := FetchNext;
    // ��ʼд����־
    while FActiveLog <> nil do
      begin
      Inc(FOwner.FFlushed);
      WriteItem;
      APrior := FActiveLog;
      FActiveLog := APrior.Next;
      FreeItem(APrior);
      end;
    end;
  end;
end;

function TQLogCastor.FetchNext: PQLogItem;
begin
Result := FOwner.Pop;
end;

function TQLogCastor.FirstWriter: PLogWriterItem;
begin
FActiveWriter := FWriters;
Result := FActiveWriter;
end;

{$IFNDEF UNICODE}

function TQLogCastor.GetFinished: Boolean;
begin
// Delphi 2007
{$IF RTLVersion=18.5}
Result := PBoolean(Integer(Self) + 16)^;
{$ELSE}
raise EXCEPTIOn.Create('δ��֧�ֵİ汾����Ҫ���TThread.FFinished��ƫ�ƺ��ټ���֧�֡�');
{$IFEND}
end;
{$ENDIF}

procedure TQLogCastor.LogAdded;
begin
FNotifyHandle.SetEvent;
end;

function TQLogCastor.NextWriter: PLogWriterItem;
begin
FCS.Enter;
if Assigned(FActiveWriter) then
  FActiveWriter := FActiveWriter.Next;
Result := FActiveWriter;
FCS.Leave;
end;

procedure TQLogCastor.RemoveWriter(AWriter: TQLogWriter);
var
  AItem: PLogWriterItem;
begin
AItem := nil;
repeat
  FCS.Enter;
  if not Assigned(FActiveWriter) or (FActiveWriter.Writer <> AWriter) then
    begin
    AItem := FWriters;
    while Assigned(AItem) do
      begin
      if AItem.Writer = AWriter then
        begin
        if Assigned(AItem.Prior) then
          AItem.Prior.Next := AItem.Next;
        if Assigned(AItem.Next) then
          AItem.Next.Prior := AItem.Prior;
        Break;
        end;
      end;
    FCS.Leave;
    Break;
    end
  else
    begin
    FCS.Leave;
    Yield; // ��ִ��ʱ��Ƭ���������߳�
    end;
until 1 > 2;
if Assigned(AItem) then
  Dispose(AItem);
end;

procedure TQLogCastor.SetLastError(ACode: Cardinal; const AMsg: QStringW);
begin
FLastError := ACode;
FLastErrorMsg := AMsg;
end;

function TQLogCastor.WaitForLog: Boolean;
begin
Result := (FNotifyHandle.WaitFor(INFINITE) = wrSignaled);
end;

{ TQLog }

function TQLog.Pop: PQLogItem;
begin
Lock;
Result := FList.First;
FList.Value := 0;
Unlock;
end;

procedure TQLog.Post(ALevel: TQLogLevel; const AFormat: QStringW;
  Args: array of const);
begin
{$IFDEF NEXTGEN}
Logs.Post(ALevel, Format(AFormat, Args));
{$ELSE}
Logs.Post(ALevel, WideFormat(AFormat, Args));
{$ENDIF}
end;

procedure TQLog.Post(ALevel: TQLogLevel; const AMsg: QStringW);
var
  AItem: PQLogItem;
begin
if FInFree then
  Exit;
AItem := CreateItem(AMsg, ALevel);
AItem.Next := nil;
// ʹ���ٽ�������
Lock();
Inc(FCount);
if FList.FirstVal = 0 then
  begin
  FList.First := AItem;
  FList.Last := AItem;
  end
else
  begin
  FList.Last.Next := AItem;
  FList.Last := AItem;
  end;
Unlock;
FCastor.LogAdded;
end;

constructor TQLog.Create;
begin
inherited;
FList.Value := 0;
FInFree := False;
FCastor := TQLogCastor.Create(Self);
FCS := TCriticalSection.Create;
end;

function TQLog.CreateCastor: TQLogCastor;
begin
Result := TQLogCastor.Create(Self);
end;

destructor TQLog.Destroy;
begin
FInFree := True;
// �ȴ���־ȫ��д�����
while Assigned(FList.First) do
  Sleep(10);
FCastor.Terminate;
FCastor.FNotifyHandle.SetEvent;
while not FCastor.Finished do
  Sleep(10);
FreeObject(FCastor);
FreeObject(FCS);
inherited;
end;

function TQLog.GetCastor: TQLogCastor;
begin
if FCastor = nil then
  FCastor := CreateCastor;
Result := FCastor;
end;

procedure TQLog.Lock;
begin
FCS.Enter;
end;

procedure TQLog.Unlock;
begin
FCS.Leave;
end;
{ TQLogConsoleWriter }

constructor TQLogConsoleWriter.Create;
begin
inherited;
end;

procedure TQLogConsoleWriter.HandleNeeded;
begin
// Nothing Needed
end;

function TQLogConsoleWriter.WriteItem(AItem: PQLogItem): Boolean;
{$IFDEF MSWINDOWS}
var
  S: QStringW;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
S := FormatDateTime('hh:nn:ss.zzz', AItem.TimeStamp) + ' [' +
  IntToStr(AItem.ThreadId) + '] ' + StrDupX(@AItem.Text[0], AItem.MsgLen shr 1);
OutputDebugStringW(PWideChar(S));
Result := True;
{$ELSE}
// Posix��֧��д��־������̨
Result := False;
{$ENDIF}
end;

{ TQLogSocketWriter }

function TQLogSocketWriter.ConnectNeeded: Boolean;
begin
if UseTCP then
  begin
  if FLastConnectTryTime >= 0 then
    begin
    Result := False;
    if (Now - FLastConnectTryTime) > 120 / 86400 then // ʧ��ʱ��������2���ӣ�����
      begin
      if connect(FSocket,
{$IFNDEF MSWINDOWS}sockaddr({$ENDIF}FReaderAddr{$IFNDEF MSWINDOWS}){$ENDIF},
        SizeOf(sockaddr_in)) = 0 then
        begin
        Result := True;
        FLastConnectTryTime := -1;
        end
      else
        FLastConnectTryTime := Now;
      end;
    end
  else
    Result := True;
  end
else
  Result := True;
end;

constructor TQLogSocketWriter.Create;
begin
inherited;
FServerPort := 514; // Syslog�˿�
FTextEncoding := teAnsi;
FBuilder := TQStringCatHelperW.Create(1024); // SyslogĬ�ϲ�����1024�ֽ�
end;

destructor TQLogSocketWriter.Destroy;
begin
FreeObject(FBuilder);
if FSocket <> THandle(-1) then
  begin
{$IFDEF MSWINDOWS}
  closesocket(FSocket);
  WSACleanup;
{$ELSE}
  __close(FSocket);
{$ENDIF}
  end;
inherited;
end;

procedure TQLogSocketWriter.HandleNeeded;
{$IFDEF MSWINDOWS}
var
  AData: WSAData;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
if WSAStartup(MakeWord(1, 1), AData) <> 0 then
  RaiseLastOSError(WSAGetLastError);
{$ENDIF}
FReaderAddr.sin_family := AF_INET;
FReaderAddr.sin_port := htons(ServerPort);
FReaderAddr.sin_addr.s_addr :=
  inet_addr(Pointer(PQCharA(qstring.AnsiEncode(ServerHost))));
PInt64(@FReaderAddr.sin_zero[0])^ := 0;
if UseTCP then
  FSocket := socket(AF_INET, SOCK_STREAM, 6)
else
  FSocket := socket(AF_INET, SOCK_DGRAM, 17);
if FSocket = THandle(-1) then
  RaiseLastOSError;
end;

procedure TQLogSocketWriter.SetTextEncoding(const Value: TTextEncoding);
begin
if Value in [teAnsi, teUtf8] then
  begin
  if FTextEncoding <> Value then
    FTextEncoding := Value;
  end
else
  raise EXCEPTIOn(SUnsupportSysLogEncoding);
end;

function TQLogSocketWriter.WriteItem(AItem: PQLogItem): Boolean;
var
  p: PQCharA;
  ASize, ALen: Integer;
  APri: QStringW;
  AHeader, AText: QStringA;
  ABuf: array [0 .. 1023] of Byte;
  procedure CalcPri;
  begin
  APri := '<' + IntToStr(8 + Integer(FCastor.ActiveLog.Level)) + '>';
  {
    0       Emergency: system is unusable
    1       Alert: action must be taken immediately
    2       Critical: critical conditions
    3       Error: error conditions
    4       Warning: warning conditions
    5       Notice: normal but significant condition
    6       Informational: informational messages
    7       Debug: debug-level messages
  }
  end;

  function FormatSyslogTime: QStringW;
  var
    Y, M, D: Word;
  const
    LinuxMonth: array [0 .. 11] of QStringW = ('Jan', 'Feb', 'Mar', 'Apr',
      'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
  begin
  DecodeDate(AItem.TimeStamp, Y, M, D);
  // Aug 24 05:34:00 CST 1987
  Result := LinuxMonth[M - 1];
  if D < 10 then
    Result := Result + '  ' + IntToStr(D)
  else
    Result := Result + ' ' + IntToStr(D);
  Result := Result + ' ' + FormatDateTime('hh:nn:ss', AItem.TimeStamp) + ' ';
  end;

  function HostName: QStringW;
  var
    AName: QStringA;
  begin
  AName.Length := 64;
  gethostname(Pointer(PQCharA(AName)), 64);
  Result := DeleteCharW(qstring.AnsiDecode(PQCharA(AName), -1),
    ' '#9#10#13) + ' ';
  end;
  function CopyText: Integer;
  var
    ps, pd: PQCharA;
    ACharSize: Integer;
  begin
  if ALen + AHeader.Length < 1024 then
    begin
    Move(p^, ABuf[AHeader.Length], ALen);
    Inc(p, ALen);
    Result := AHeader.Length + ALen;
    ALen := 0;
    end
  else
    begin
    pd := @ABuf[AHeader.Length];
    ps := @ABuf[0];
    Result := AHeader.Length;
    while p^ <> 0 do
      begin
      if TextEncoding = teAnsi then
        ACharSize := CharSizeA(p)
      else
        ACharSize := CharSizeU(p);
      if (IntPtr(pd) - IntPtr(ps)) + ACharSize <= 1024 then
        begin
        while ACharSize > 0 do
          begin
          pd^ := p^;
          Inc(p);
          Inc(pd);
          Dec(ACharSize);
          end;
        end
      else
        begin
        Result := IntPtr(pd) - IntPtr(ps);
        Dec(ALen, Result - AHeader.Length);
        Break;
        end;
      end;
    end;
  end;

begin
if not ConnectNeeded then
  begin
  Result := False;
  Exit;
  end;
Result := True;
FBuilder.Position := 0;
CalcPri;
FBuilder.Cat(APri);
FBuilder.Cat(FormatSyslogTime);
FBuilder.Cat(HostName);
FBuilder.Cat('[').Cat(IntToStr(AItem.ThreadId)).Cat(']');
FBuilder.Cat(LogLevelText[AItem.Level]);
AHeader := qstring.Utf8Encode(FBuilder.Value);
if TextEncoding = teAnsi then
  AText := qstring.AnsiEncode(@AItem.Text[0], AItem.MsgLen shr 1)
else
  AText := qstring.Utf8Encode(@AItem.Text[0], AItem.MsgLen shr 1);
p := PQCharA(AText);
ALen := AText.Length;
repeat
  Move(PQCharA(AHeader)^, ABuf[0], AHeader.Length);
  ASize := CopyText;
  sendto(FSocket, ABuf[0], ASize, 0, PSockAddr(@FReaderAddr)^,
    SizeOf(sockaddr_in));
until ALen <= 0;
end;

{ TQLogCompressThread }

constructor TQLogCompressThread.Create(ALogFileName, AIndexFileName: QStringW);
begin
FLogFileName := ALogFileName;
FIndexFileName := AIndexFileName;
inherited Create(True);
FreeOnTerminate := True;
Suspended := False;
end;

procedure TQLogCompressThread.Execute;
const
{$IFDEF NEXTGEN}
  AMode: MarshaledAString = 'wb';
{$ELSE}
  AMode: PAnsiChar = 'wb';
{$ENDIF}
  procedure DoCompress(AFileName: QStringW);
  var
    AFile: gzFile;
    ABuf: array [0 .. 65535] of Byte;
    AStream: TFileStream;
    AReaded: Integer;
  begin
  AStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    AFile := gzopen(Pointer(PQCharA(AnsiEncode(AFileName + '.gz'))), AMode);
    if AFile <> nil then
      begin
      repeat
        AReaded := AStream.Read(ABuf[0], 65536);
        if AReaded > 0 then
          gzwrite(AFile, ABuf[0], AReaded);
      until AReaded = 0;
      gzclose(AFile);
      end;
  finally
    AStream.Free;
    SysUtils.DeleteFile(AFileName);
  end;
  end;

begin
if Length(FLogFileName) > 0 then
  DoCompress(FLogFileName);
if Length(FIndexFileName) > 0 then
  DoCompress(FIndexFileName);
end;

initialization

MaxLogFileSize := -1;
{$IFDEF QLOG_CREATE_GLOBAL}
Logs := TQLog.Create;
{$IFDEF QLOG_CREATE_DEFAULT_WRITER}
Logs.Castor.AddWriter(TQLogFileWriter.Create);
{$ENDIF}
{$ELSE}
Logs := nil;
{$ENDIF}
{$IF RTLVersion<26}
zlibhandle := LoadLibrary('zlib1.dll');
if zlibhandle <> 0 then
  begin
  gzopen := GetProcAddress(zlibhandle, 'gzopen');
  gzseek := GetProcAddress(zlibhandle, 'gzseek');
  gztell := GetProcAddress(zlibhandle, 'gztell');
  gzwrite := GetProcAddress(zlibhandle, 'gzwrite');
  gzclose := GetProcAddress(zlibhandle, 'gzclose');
  end
else
  begin
  gzopen := nil;
  gzseek := nil;
  gztell := nil;
  gzwrite := nil;
  gzclose := nil;
  end;
{$IFEND <XE5}

finalization

{$IFDEF QLOG_CREATE_GLOBAL}
  FreeObject(Logs);
Logs := nil;
{$ENDIF}
{$IF RTLVersion<26}
if zlibhandle <> 0 then
  FreeLibrary(zlibhandle);
{$IFEND <XE5}

end.
