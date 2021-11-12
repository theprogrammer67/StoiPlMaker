unit ufmMainForm;

{$WARN SYMBOL_PLATFORM OFF}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.ToolWin, Vcl.ActnMan, Vcl.ActnCtrls, System.Actions, Vcl.ActnList,
  Vcl.PlatformDefaultStyleActnCtrls, System.ImageList, Vcl.ImgList;

type
  TfrmMainForm = class(TForm)
    lvFolders: TListView;
    lvFiles: TListView;
    pnlBody: TPanel;
    pnlBottom: TPanel;
    spl1: TSplitter;
    btnMakePlaylist: TButton;
    pnlLeft: TPanel;
    acttbDestionation: TActionToolBar;
    amActions: TActionManager;
    actAddDestination: TAction;
    actDeleteDestination: TAction;
    actClearDestination: TAction;
    statFiles: TStatusBar;
    pnlRight: TPanel;
    fodAddFolder: TFileOpenDialog;
    ilImages: TImageList;
    procedure actAddDestinationExecute(Sender: TObject);
    procedure btnMakePlaylistClick(Sender: TObject);
  private
    FSize: Int64;
  private
    procedure AddFile(const APath: string; ASize: Int64);
    procedure AddFiles(const AFolder: string);
  public
    { Public declarations }
  end;

var
  frmMainForm: TfrmMainForm;

implementation

uses
  Math;

function ConvertBytes(Bytes: Int64): string;
const
  Description: Array [0 .. 8] of string = ('Bytes', 'KB', 'MB', 'GB', 'TB',
    'PB', 'EB', 'ZB', 'YB');
var
  i: Integer;
begin
  i := 0;

  while Bytes > Power(1024, i + 1) do
    Inc(i);

  Result := FormatFloat('###0.##', Bytes / IntPower(1024, i)) + ' ' +
    Description[i];
end;

{$R *.dfm}

procedure TfrmMainForm.actAddDestinationExecute(Sender: TObject);
var
  LItem: TListItem;
  LFolder: string;
begin
  if not fodAddFolder.Execute then
    Abort;

  LFolder := fodAddFolder.FileName;
  LItem := lvFolders.Items.Add;
  LItem.Checked := True;
  LItem.Caption := LFolder;
  LItem.ImageIndex := 1;
end;

procedure TfrmMainForm.AddFile(const APath: string; ASize: Int64);
begin
  lvFiles.AddItem(APath, nil);
  FSize := FSize + ASize;
end;

procedure TfrmMainForm.AddFiles(const AFolder: string);
var
  SearchRec: TSearchRec; // поисковая переменная
  FindRes: Integer;
  LFolder: string;
  LSize: Int64;
begin
  LFolder := IncludeTrailingPathDelimiter(AFolder);
  try
    try
      FindRes := System.SysUtils.FindFirst(LFolder + '*.mp3', faAnyFile,
        SearchRec);

      while FindRes = 0 do
      begin
        LSize := Int64(SearchRec.FindData.nFileSizeHigh) shl Int64(32) +
          Int64(SearchRec.FindData.nFileSizeLow);
        AddFile(LFolder + SearchRec.Name, LSize);
        FindRes := FindNext(SearchRec);
      end;

    finally
      System.SysUtils.FindClose(SearchRec);
    end;
  except
  end;
end;

procedure TfrmMainForm.btnMakePlaylistClick(Sender: TObject);
var
  i: Integer;
begin
  FSize := 0;
  for i := 0 to lvFolders.Items.Count - 1 do
    AddFiles(lvFolders.Items[i].Caption);

  statFiles.Panels[0].Text := ConvertBytes(FSize);
end;


end.
