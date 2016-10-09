program CustomTetherLinker;

uses
  System.StartUpCopy,
  FMX.Forms,
  CTL in 'CTL.pas' {Form800x480};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm800x480, Form800x480);
  Application.Run;
end.
