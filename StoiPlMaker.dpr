program StoiPlMaker;

uses
  Vcl.Forms,
  ufmMainForm in 'ufmMainForm.pas' {frmMainForm};

{$R *.res}

begin
{$IFDEF DEBUG}
  // Для отображения утечек памяти, если они есть
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMainForm, frmMainForm);
  Application.Run;
end.
