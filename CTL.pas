unit CTL;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls;

type
  TForm800x480 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    Button9: TButton;
    Button10: TButton;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form800x480: TForm800x480;

implementation
uses FMX.Android.Runtime, Androidapi.JNI.Runtime, Androidapi.JNI.javatypes;
{$R *.fmx}
{$R *.SmXhdpiPh.fmx ANDROID}
{$R *.NmXhdpiPh.fmx ANDROID}

procedure TForm800x480.Button1Click(Sender: TObject);
begin
RunAndroidCmd('su proc/sys/net/ipv4/ip_forward iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE');
end;

end.
