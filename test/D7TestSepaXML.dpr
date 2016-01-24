program D7TestSepaXML;

uses
  Forms,
  fMain in 'fMain.pas' {frMain},
  uDJMSepa1914XML in '..\uDJMSepa1914XML.pas',
  uDJMSepa3414XML in '..\uDJMSepa3414XML.pas',
  uDJMSepa in '..\uDJMSepa.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrMain, frMain);
  Application.Run;
end.
