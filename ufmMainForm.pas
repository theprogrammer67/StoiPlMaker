unit ufmMainForm;

{$WARN SYMBOL_PLATFORM OFF}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.ToolWin, Vcl.ActnMan, Vcl.ActnCtrls, System.Actions, Vcl.ActnList,
  Vcl.PlatformDefaultStyleActnCtrls, System.ImageList, Vcl.ImgList,
  System.IniFiles, Winapi.ShlObj, FastCopy;

const
  INI_FILENAME = 'settings.ini';
  APPDATA_DIR = 'StoiPlMaker';
  TAG_SETTINGS = 'settings';

type
  TFileItem = record
    Folder: string;
    Name: string;
    Size: Integer;
    Index: Integer;
  end;

  PFileItem = ^TFileItem;

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
    btnShuffleRandomly: TButton;
    btnCopyFiles: TButton;
    pbCopy: TProgressBar;
    actSave: TAction;
    fodSaveFiles: TFileOpenDialog;
    statBottom: TStatusBar;
    procedure actAddDestinationExecute(Sender: TObject);
    procedure btnMakePlaylistClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure lvFilesCompare(Sender: TObject; Item1, Item2: TListItem;
      Data: Integer; var Compare: Integer);
    procedure btnShuffleRandomlyClick(Sender: TObject);
    procedure btnCopyFilesClick(Sender: TObject);
    procedure actDeleteDestinationExecute(Sender: TObject);
    procedure actClearDestinationExecute(Sender: TObject);
    procedure actSaveExecute(Sender: TObject);
  private
    FSize: Int64;
    FCopyng: Boolean;
  private
    procedure AddFile(const AFolder, AName: string; ASize: Int64);
    procedure AddFiles(const AFolder: string);
    procedure ClearFiles;
    procedure CopyFiles(const AFolder: string);
    procedure SaveSettings;
    procedure ReadSettings;
    procedure SetCopyng(const Value: Boolean);
  public
    property Copyng: Boolean read FCopyng write SetCopyng;
  end;

var
  frmMainForm: TfrmMainForm;

implementation

uses Math;

function ConvertBytes(Bytes: Int64): string;
const
  Description: Array [0 .. 8] of string = ('Bytes', 'KB', 'MB', 'GB', 'TB',
    'PB', 'EB', 'ZB', 'YB');
var
  I: Integer;
begin
  I := 0;

  while Bytes > Power(1024, I + 1) do
    Inc(I);

  Result := FormatFloat('###0.##', Bytes / IntPower(1024, I)) + ' ' +
    Description[I];
end;

function GetSpecialPath(CSIDL: Word): string;
var
  S: string;
begin
  SetLength(S, MAX_PATH);
  if not SHGetSpecialFolderPath(0, PChar(S), CSIDL, True) then
    S := GetSpecialPath(CSIDL_APPDATA);
  Result := IncludeTrailingPathDelimiter(PChar(S));
end;

function GetIniFilePath: string;
begin
  Result := IncludeTrailingPathDelimiter(GetSpecialPath(CSIDL_COMMON_APPDATA) +
    APPDATA_DIR);
  ForceDirectories(Result);
  Result := Result + INI_FILENAME;
end;

{$R *.dfm}

procedure TfrmMainForm.actAddDestinationExecute(Sender: TObject);
var
  LItem: TListItem;
  LFolder: string;
begin
  if not fodAddFolder.Execute then
    Exit;

  LFolder := fodAddFolder.FileName;
  LItem := lvFolders.Items.Add;
  LItem.Checked := True;
  LItem.Caption := LFolder;
  LItem.ImageIndex := 1;
end;

procedure TfrmMainForm.actClearDestinationExecute(Sender: TObject);
begin
  lvFolders.Clear;
end;

procedure TfrmMainForm.actDeleteDestinationExecute(Sender: TObject);
var
  LItem: TListItem;
begin
  LItem := lvFolders.Selected;
  if not Assigned(LItem) then
    Exit;

  lvFolders.DeleteSelected;
end;

procedure TfrmMainForm.actSaveExecute(Sender: TObject);
begin
  SaveSettings;
end;

procedure TfrmMainForm.AddFile(const AFolder, AName: string; ASize: Int64);
var
  LFile: PFileItem;
  LItem: TListItem;
begin
  LFile := New(PFileItem);
  LFile.Folder := AFolder;
  LFile.Name := AName;
  LFile.Size := ASize;
  LFile.Index := lvFiles.Items.Count;

  LItem := lvFiles.Items.Add;
  LItem.Caption := AFolder + AName;
  LItem.ImageIndex := 7;
  LItem.Data := LFile;
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
        AddFile(LFolder, SearchRec.Name, LSize);
        FindRes := FindNext(SearchRec);
      end;

    finally
      System.SysUtils.FindClose(SearchRec);
    end;
  except
  end;
end;

procedure TfrmMainForm.btnShuffleRandomlyClick(Sender: TObject);
var
  I, LMax: Integer;
begin
  lvFiles.SortType := stNone;

  Randomize;
  LMax := lvFiles.Items.Count;
  for I := 0 to lvFiles.Items.Count - 1 do
    PFileItem(lvFiles.Items[I].Data).Index := Random(LMax);

  lvFiles.SortType := stData;
end;

procedure TfrmMainForm.btnCopyFilesClick(Sender: TObject);
begin
  if Copyng then
  begin
    Copyng := False;
    Exit;
  end;

  if not fodSaveFiles.Execute then
    Exit;

  CopyFiles(fodSaveFiles.FileName);
end;

procedure TfrmMainForm.btnMakePlaylistClick(Sender: TObject);
var
  I: Integer;
begin
  ClearFiles;

  for I := 0 to lvFolders.Items.Count - 1 do
    AddFiles(lvFolders.Items[I].Caption);

  statFiles.Panels[0].Text := ConvertBytes(FSize);
end;

procedure TfrmMainForm.ClearFiles;
var
  I: Integer;
begin
  lvFiles.SortType := stNone;
  FSize := 0;

  for I := 0 to lvFiles.Items.Count - 1 do
  begin
    if lvFiles.Items[I].Data <> nil then
    begin
      Dispose(PFileItem(lvFiles.Items[I].Data));
      lvFiles.Items[I].Data := nil;
    end;
  end;

  lvFiles.Clear;
end;

procedure TfrmMainForm.CopyFiles(const AFolder: string);
var
  I: Integer;
  LItem: PFileItem;
  LFolder, LSrcFile, LDstFile: string;
begin
  if FCopyng then
    Exit;

  pbCopy.Max := lvFiles.Items.Count;
  pbCopy.Visible := True;
  Copyng := True;
  try
    LFolder := IncludeTrailingPathDelimiter(AFolder);

    for I := 0 to lvFiles.Items.Count - 1 do
    begin
      LItem := PFileItem(lvFiles.Items[I].Data);
      LSrcFile := LItem.Folder + LItem.Name;
      LDstFile := LFolder + LItem.Name;

      statBottom.Panels[0].Text := LSrcFile;
      Application.ProcessMessages;

      CopyFile(PWideChar(LSrcFile), PWideChar(LDstFile), False);
//      FastCopyFile(LSrcFile, LDstFile);


      pbCopy.Position := I;
      Application.ProcessMessages;

      if not FCopyng then
        Exit;
    end;
  finally
    Copyng := False;
    pbCopy.Visible := False;
  end;
end;

procedure TfrmMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveSettings;
end;

procedure TfrmMainForm.FormCreate(Sender: TObject);
begin
  ReadSettings;
end;

procedure TfrmMainForm.FormDestroy(Sender: TObject);
begin
  ClearFiles;
end;

procedure TfrmMainForm.lvFilesCompare(Sender: TObject; Item1, Item2: TListItem;
  Data: Integer; var Compare: Integer);
var
  LFile1Ind, LFile2Ind: Integer;
begin
  if (Item1.Data = nil) or (Item2.Data = nil) then
    Exit;

  LFile1Ind := PFileItem(Item1.Data).Index;
  LFile2Ind := PFileItem(Item2.Data).Index;

  if LFile1Ind > LFile2Ind then
    Compare := 1
  else if LFile1Ind < LFile2Ind then
    Compare := -1
  else
    Compare := 0;
end;

procedure TfrmMainForm.ReadSettings;
var
  Ini: TIniFile;
  LFolders: TStrings;
  I: Integer;
  LItem: TListItem;
begin
  Ini := TIniFile.Create(GetIniFilePath);
  try
    lvFolders.Clear;
    LFolders := TStringList.Create;
    try
      Ini.ReadSectionValues('folders', LFolders);
      for I := 0 to LFolders.Count - 1 do
      begin
        LItem := lvFolders.Items.Add;
        LItem.Caption := LFolders.KeyNames[I];
        LItem.Checked := StrToBoolDef(LFolders.ValueFromIndex[I], False);
        LItem.ImageIndex := 1;
      end;
    finally
      FreeAndNil(LFolders);
    end;
  finally
    FreeAndNil(Ini);
  end;
end;

procedure TfrmMainForm.SaveSettings;
var
  Ini: TIniFile;
  I: Integer;
begin
  Ini := TIniFile.Create(GetIniFilePath);
  try
    Ini.EraseSection('folders');
    for I := 0 to lvFolders.Items.Count - 1 do
    begin
      Ini.WriteString('folders', lvFolders.Items[I].Caption,
        DefaultTrueBoolStr);
    end;
  finally
    FreeAndNil(Ini);
  end;
end;

procedure TfrmMainForm.SetCopyng(const Value: Boolean);
begin
  FCopyng := Value;
  if FCopyng then
    btnCopyFiles.Caption := 'Abort'
  else
    btnCopyFiles.Caption := 'Copy files';

  statBottom.Panels[0].Text := '';

  Application.ProcessMessages;
end;

end.
