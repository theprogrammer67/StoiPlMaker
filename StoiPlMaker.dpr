program StoiPlMaker;

uses
  Vcl.Forms,
  ufmMainForm in 'ufmMainForm.pas' {frmMainForm},
  FastCopy in 'FastCopy.pas';

{$R *.res}

begin
{$IFDEF DEBUG}
  // ��� ����������� ������ ������, ���� ��� ����
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMainForm, frmMainForm);
  Application.Run;
end.
