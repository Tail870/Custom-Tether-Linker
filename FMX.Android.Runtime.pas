unit FMX.Android.Runtime;

(* ************************************************ *)
(*　　　　　　　　　　　　　　　　　　　　　　　　　*)
(*　　　　　　　　　　　　　　　　　　　　　　　　　*)
(*　　设计：爱吃猪头肉 & Flying Wang 2013-11-07　　 *)
(*　　　　　　上面的版权声明请不要移除。　　　　　　*)
(*　　　　　　　　　　　　　　　　　　　　　　　　　*)
(* ************************************************ *)


interface

uses System.SysUtils, System.Classes,
{$IFNDEF VER260} //not XE5
  Androidapi.Helpers,
{$ENDIF}
  Androidapi.JNI.JavaTypes,
  Androidapi.JNIBridge,
  Androidapi.JNI.Stream2,
  Androidapi.JNI.Runtime;

{$DEFINE DebugMsg}

{$IFDEF DebugMsg}
type
  TAndroidDebugMsgCallBackO = procedure(const CmdExitCode: Integer; const ErrorMsg: string) of object;
{$ENDIF}

const
  AndroidCmdErrorCode = -1;

function RunAndroidCmd(CmdLines: string;
      WaitForit: Boolean = True;
      Redirect: TStrings = nil
{$IFDEF DebugMsg}
      ; DebugMsgCB: TAndroidDebugMsgCallBackO = nil
{$ENDIF}): Integer; overload;

function RunAndroidCmd(CmdLines: TStrings;
      WaitForit: Boolean = True;
      Redirect: TStrings = nil
{$IFDEF DebugMsg}
      ; DebugMsgCB: TAndroidDebugMsgCallBackO = nil
{$ENDIF}): Integer; overload;

function HaveRoot: Boolean;


implementation

//http://www.2cto.com/kf/201210/159834.html
//2012-10-10 10:48:01     作者：victoryckl

//  关键点在于下面这句，通过执行su产生一个具有root权限的进程：
//Process p = Runtime.getRuntime().exec("su");
//然后，在向这个进程的写入要执行的命令，即可达到以root权限执行命令：
//dos = new DataOutputStream(p.getOutputStream());
//dos.writeBytes(cmd + "\n");
//dos.flush();
//或者用下面的方式：
//Runtime.getRuntime().exec(new String[]{"/system/bin/su","-c", cmd});


function HaveRoot: Boolean;
begin
  try
    Result := RunAndroidCmd(nil) <> AndroidCmdErrorCode;
  except
    Result := False;
  end;
end;


function RunAndroidCmd(CmdLines: string;
      WaitForit: Boolean = True;
      Redirect: TStrings = nil        //redirect memo
{$IFDEF DebugMsg}
      ; DebugMsgCB: TAndroidDebugMsgCallBackO = nil
{$ENDIF}): Integer;
var
  TempLines: string;
  ACmdLines: TStrings;
begin
  ACmdLines := TStringList.Create;
  try
    try
      TempLines := CmdLines;
      TempLines := StringReplace(TempLines, #13#10, sLineBreak , [rfReplaceAll]);
      TempLines := StringReplace(TempLines, #10#13, sLineBreak , [rfReplaceAll]);
      TempLines := StringReplace(TempLines, #10, sLineBreak , [rfReplaceAll]);
      TempLines := StringReplace(TempLines, #13, sLineBreak , [rfReplaceAll]);
      ACmdLines.Text := TempLines;
      Result := RunAndroidCmd(ACmdLines, WaitForit, Redirect
{$IFDEF DebugMsg}
        , DebugMsgCB
{$ENDIF}
      );
    except
      Result := AndroidCmdErrorCode;
    end;
  finally
    FreeAndNil(ACmdLines);
  end;
end;


type

  TProcessStreamRunner = class(TJavaLocal, JRunnable)
  strict private
    FInputS: JInputStream;
    FStreamType: string;
    FRedirect: TStrings;
  public
    constructor Create(AInputS: JInputStream;
      AStreamType: string;
      ARedirect: TStrings = nil); overload;
    procedure run; cdecl;
  end;

 {TProcessStreamRunner}

constructor TProcessStreamRunner.Create(AInputS: JInputStream;
      AStreamType: string;
      ARedirect: TStrings = nil);
begin
  inherited Create;
  FInputS := AInputS;
  FStreamType := AStreamType;
  FRedirect := ARedirect;
end;


procedure TProcessStreamRunner.run;
begin
end;


function ProcessStreamRunner(InputS: JInputStream;
      StreamType: string;
      Redirect: TStrings = nil): Boolean;
var
  isr: JInputStreamReader;
  br: JBufferedReader;
  line: JString;
  StreamTypeAdded: Boolean;
begin
  Result := False;
  isr := nil;
  br := nil;
  try
    try
      if Assigned(InputS) then
      begin
        isr := TJInputStreamReader.JavaClass.init(InputS);
        br := TJBufferedReader.JavaClass.init(isr) ;
      end;
      StreamTypeAdded := False;

      line := nil;
      while true do
      begin
        line := br.readLine;
        if Assigned(line) then
        begin
          Result := True;
          if not StreamTypeAdded then
          begin
            if Assigned(Redirect) then
            begin
              Redirect.Add(StreamType);
            end;
            StreamTypeAdded := True;
          end;
          if Assigned(Redirect) then
          begin
            Redirect.Add(JStringToString(line));
          end;
        end
        else
        begin
          break;
        end;
      end;
    except
      on e: Exception do
      begin
        // not process
      end;
    end;
  finally
    if Assigned(br) then
    begin
      br.close;
    end;
    if Assigned(isr) then
    begin
      isr.close;
    end;
  end;
end;




function RunAndroidCmd(CmdLines: TStrings;
      WaitForit: Boolean = True;
      Redirect: TStrings = nil
{$IFDEF DebugMsg}
      ; DebugMsgCB: TAndroidDebugMsgCallBackO = nil
{$ENDIF}): Integer;
var
  Acmd: string;
  P: JProcess;
  os: JOutputStream;
  FHasError,
  FRootMode: Boolean;
  FCmdLines: TStrings;
{$IFDEF DebugMsg}
  procedure DoDebugMsgCB(const CmdExitCode: Integer; const ErrorMsg: string);
  begin
    if Assigned(DebugMsgCB) then
    begin
      DebugMsgCB(CmdExitCode, ErrorMsg);
    end
    else
    begin
      raise Exception.Create('Cmd Error:' + ErrorMsg);
    end;
  end;
{$ENDIF}

begin
  Result := AndroidCmdErrorCode;
  FHasError := False;
  FRootMode := True;
  FCmdLines := TStringList.Create;
  try
    if Assigned(CmdLines) and (CmdLines.Count > 0) then
    begin
      FCmdLines.AddStrings(CmdLines);
      FRootMode := False;
    end;
    p := nil;
    os := nil;
    if FRootMode then
    begin
      FCmdLines.Clear;
      FCmdLines.Add('su');
      FCmdLines.Add('echo test');
      FCmdLines.Add('exit');
      FCmdLines.Add('exit');
    end;
    if FCmdLines.Count <= 0 then
    begin
      Exit;
    end;
    try
      try
        Acmd := FCmdLines[0];
        FCmdLines.Delete(0);
        P := TJRuntime.JavaClass.getRuntime.exec(StringToJString(Acmd));

        if FCmdLines.Count > 0 then
        begin
          os := p.getOutputStream;
          while FCmdLines.Count > 0 do
          begin
            Acmd := FCmdLines[0] + sLineBreak;
            os.write(StringToJString(Acmd).getBytes(StringToJString('UTF8')));
            os.flush;
            FCmdLines.Delete(0);
          end;
        end;

        if WaitForit or Assigned(Redirect) then
        begin
          if ProcessStreamRunner(p.getErrorStream, 'stderr', Redirect) then
          begin
            FHasError := True;
          end;
          ProcessStreamRunner(p.getInputStream, 'stdout', Redirect);
        end;
        if WaitForit then
        begin
          Result := p.waitFor;
          Result := p.exitValue;
        end
        else
        begin
          Result := 0;
        end;
        if FHasError then
        begin
          Result := AndroidCmdErrorCode;
        end;
      except
        on e: Exception do
        begin
          Result := AndroidCmdErrorCode;
          if Assigned(Redirect) then
          begin
            Redirect.Add(e.Message);
          end
          else
          begin
{$IFDEF DebugMsg}
            DoDebugMsgCB(Result, '1' + e.Message);
{$ELSE}
            raise Exception.Create('Cmd Error:' + e.Message);
{$ENDIF}
          end;
        end;
      end;
    finally
      try
        if Assigned(os) then
        begin
          os.close;
        end;
        if Assigned(p) then
        begin
          p.getOutputStream.close;
          p.getInputStream.close;
          p.getErrorStream.close;
          p.destroy;
        end;
      except
        on e: Exception do
        begin
          Result := AndroidCmdErrorCode;
          if Assigned(Redirect) then
          begin
            Redirect.Add(e.Message);
          end
          else
          begin
{$IFDEF DebugMsg}
            DoDebugMsgCB(Result, e.Message);
{$ELSE}
            raise Exception.Create('Cmd Error:' + e.Message);
{$ENDIF}
          end;
        end;
      end;
    end;
  finally
    FreeAndNil(FCmdLines);
  end;
end;

end.
