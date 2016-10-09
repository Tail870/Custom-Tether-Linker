unit Androidapi.JNI.Runtime;

(* ************************************************ *)
(*　　　　　　　　　　　　　　　　　　　　　　　　　*)
(*　　原作者　天轶_黄金  15978396　　　　　　　　　 *)
(*　　　　　　　　　　　　　　　　　　　　　　　　　*)
(*　　修改：爱吃猪头肉 & Flying Wang 2013-11-07　　 *)
(*　　　　　　上面的版权声明请不要移除。　　　　　　*)
(*　　　　　　　　　　　　　　　　　　　　　　　　　*)
(* ************************************************ *)



interface

uses Androidapi.JNI.JavaTypes,
  Androidapi.JNIBridge;

type
  JProcess = interface;
  JRuntime = interface;

  JProcessClass = interface(JObjectClass)
    ['{D1C77950-5890-4897-950F-329331FC6873}']
    { Methods }
    function init: JProcess; cdecl;
  end;

  [JavaSignature('java/lang/Process')]
  JProcess = interface(JObject)
    ['{A48155DF-E1E9-4A2C-B832-EBACAED29DB5}']
    { Methods }
    procedure destroy; cdecl;
    function exitValue: integer; cdecl;
    function getErrorStream: JInputStream; cdecl;
    function getInputStream: JInputStream; cdecl;
    function getOutputStream: JOutputStream; cdecl;
    function waitFor: integer; cdecl;
  end;

  TJProcess = class(TJavaGenericImport<JProcessClass, JProcess>)end;


  /// ======================================

  JRuntimeClass = interface(JObjectClass)
    ['{5EE261E7-E8B5-4F5B-A8BA-8DFB2D76F7C4}']
    { Methods }
    function getRuntime: JRuntime; cdecl;
    procedure runFinalizersOnExit(run: Boolean); cdecl;
  end;

  [JavaSignature('java/lang/Runtime')]
  JRuntime = interface(JObject)
    ['{0CF96D0C-E9DB-4FC9-8674-B3B2A7C67D08}']
    { Methods }
    function exec(prog: JString): JProcess; cdecl; overload;
    function exec(prog: TJavaObjectArray<JString>): JProcess; cdecl; overload;
    function exec(prog, envp: TJavaObjectArray<JString>): JProcess; cdecl; overload;
    function exec(prog, envp: TJavaObjectArray<JString>; directory: JFile): JProcess; cdecl; overload;
    function exec(prog: JString; envp: TJavaObjectArray<JString>): JProcess; cdecl; overload;
    function exec(prog: JString; envp: TJavaObjectArray<JString>; directory: JFile): JProcess; cdecl; overload;
    procedure exit(code: Integer); cdecl;
    function freeMemory: Int64; cdecl;
    procedure gc; cdecl;
    procedure load(pathName: JString); cdecl;
    procedure loadLibrary(libName: JString); cdecl;
    procedure runFinalization; cdecl;
    function totalMemory: Int64; cdecl;
    procedure traceInstructions(enable: Boolean); cdecl;
    procedure traceMethodCalls(enable: Boolean); cdecl;
    function getLocalizedInputStream(stream: JInputStream): JInputStream; cdecl;
    function getLocalizedOutputStream(stream: JOutputStream): JOutputStream; cdecl;
    procedure addShutdownHook(hook: JThread); cdecl;
    function removeShutdownHook(hook: JThread): Boolean; cdecl;
    procedure halt(code: Integer); cdecl;
    function availableProcessors: Integer; cdecl;
    function maxMemory: Int64; cdecl;
  end;

  TJRuntime = class(TJavaGenericImport<JRuntimeClass, JRuntime>)end;

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

end.
