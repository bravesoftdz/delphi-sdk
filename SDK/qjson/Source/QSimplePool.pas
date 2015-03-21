unit QSimplePool;

interface

uses classes, types, sysutils, syncobjs;

type
{$HPPEMIT '#pragma link "qsimplepool"'}
  TQSimplePool = class;
  TQSimplePoolItemNotify = procedure(ASender: TQSimplePool; AData: Pointer)
    of object;
  TQSimplePoolNewItemEvent = procedure(ASender: TQSimplePool;
    var AData: Pointer) of object;

  TQSimplePool = class
  private
    FOnFree: TQSimplePoolItemNotify;
    FOnNewItem: TQSimplePoolNewItemEvent;
    FOnReset: TQSimplePoolItemNotify;
    FBeforePush: TQSimplePoolItemNotify;
    FAfterPop: TQSimplePoolItemNotify;
  protected
    FPool: array of Pointer;
    FCount: Integer;
    FSize: Integer;
    FDataSize: Integer;
    FLocker: TCriticalSection;
    procedure DoFree(AData: Pointer); // inline;
    procedure DoReset(AData: Pointer); // inline;
    procedure DoNew(var AData: Pointer); // inline;
  public
    constructor Create(AMaxSize, ADataSize: Integer); overload;
    destructor Destroy; override;
    procedure Push(p: Pointer);
    function Pop: Pointer;
    property Count: Integer read FCount;
    property Size: Integer read FSize write FSize;
    property OnNewItem: TQSimplePoolNewItemEvent read FOnNewItem
      write FOnNewItem;
    property OnFree: TQSimplePoolItemNotify read FOnFree write FOnFree;
    property OnReset: TQSimplePoolItemNotify read FOnReset write FOnReset;
    property BeforePush: TQSimplePoolItemNotify read FBeforePush
      write FBeforePush;
    property AfterPop: TQSimplePoolItemNotify read FAfterPop write FAfterPop;
  end;

implementation

{ TQSimplePool }

constructor TQSimplePool.Create(AMaxSize, ADataSize: Integer);
begin
inherited Create;
FSize := AMaxSize;
FDataSize := ADataSize;
SetLength(FPool, FSize);
FLocker := TCriticalSection.Create;
end;

destructor TQSimplePool.Destroy;
var
  I: Integer;
begin
FLocker.Enter;
I := 0;
while I < FCount do
  begin
  DoFree(FPool[I]);
  Inc(I);
  end;
FreeAndNil(FLocker);
inherited;
end;

procedure TQSimplePool.DoFree(AData: Pointer);
begin
if Assigned(FOnFree) then
  FOnFree(Self, AData)
else
  FreeMem(AData);
end;

procedure TQSimplePool.DoNew(var AData: Pointer);
begin
if Assigned(FOnNewItem) then
  FOnNewItem(Self, AData)
else
  GetMem(AData, FDataSize);
end;

procedure TQSimplePool.DoReset(AData: Pointer);
begin
if Assigned(FOnReset) then
  FOnReset(Self, AData)
else
  FillChar(AData^, FDataSize, 0);
end;

function TQSimplePool.Pop: Pointer;
begin
Result := nil;
FLocker.Enter;
if FCount > 0 then
  begin
  Result := FPool[FCount - 1];
  Dec(FCount);
  end;
FLocker.Leave;
if Result = nil then
  DoNew(Result);
if Result <> nil then
  begin
  DoReset(Result);
  if Assigned(FAfterPop) then
    FAfterPop(Self,Result);
  end;
end;

procedure TQSimplePool.Push(p: Pointer);
var
  ADoFree: Boolean;
begin
if Assigned(FBeforePush) then
  FBeforePush(Self, p);
FLocker.Enter;
ADoFree := (FCount = FSize);
if not ADoFree then
  begin
  FPool[FCount] := p;
  Inc(FCount);
  end;
FLocker.Leave;
if ADoFree then
  DoFree(p);
end;

end.
