unit LuiJSONLCLViews;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, Controls, StdCtrls;

type

  TJSONObjectViewManager = class;

  { TCustomJSONGUIMediator }

  TCustomJSONGUIMediator = class
  public
    class procedure DoJSONToGUI(JSONObject: TJSONObject; const PropName: String; Control: TControl; Options: TJSONData); virtual;
    class procedure DoGUIToJSON(Control: TControl; JSONObject: TJSONObject; const PropName: String; Options: TJSONData); virtual;
  end;

  TCustomJSONGUIMediatorClass = class of TCustomJSONGUIMediator;

  { TJSONEditMediator }

  TJSONEditMediator = class(TCustomJSONGUIMediator)
    class procedure DoJSONToGUI(JSONObject: TJSONObject; const PropName: String;
      Control: TControl; Options: TJSONData); override;
    class procedure DoGUIToJSON(Control: TControl; JSONObject: TJSONObject;
      const PropName: String; Options: TJSONData); override;
  end;

  { TJSONCaptionMediator }

  TJSONCaptionMediator = class(TCustomJSONGUIMediator)
    class procedure DoJSONToGUI(JSONObject: TJSONObject; const PropName: String;
      Control: TControl; Options: TJSONData); override;
    class procedure DoGUIToJSON(Control: TControl; JSONObject: TJSONObject;
      const PropName: String; Options: TJSONData); override;
  end;

  { TJSONObjectPropertyView }

  TJSONObjectPropertyView = class(TCollectionItem)
  private
    FControl: TControl;
    FMediatorClass: TCustomJSONGUIMediatorClass;
    FMediatorId: String;
    FOptions: String;
    FOptionsData: TJSONData;
    FPropertyName: String;
    procedure MediatorClassNeeded;
    procedure OptionsDataNeeded;
  public
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function GetDisplayName: string; override;
    procedure Load(JSONObject: TJSONObject);
    procedure Save(JSONObject: TJSONObject);
  published
    property Control: TControl read FControl write FControl;
    property MediatorId: String read FMediatorId write FMediatorId;
    property Options: String read FOptions write FOptions;
    property PropertyName: String read FPropertyName write FPropertyName;
  end;

  { TJSONObjectPropertyViews }

  TJSONObjectPropertyViews = class(TCollection)
  private
    FOwner: TJSONObjectViewManager;
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TJSONObjectViewManager);
  end;

  { TJSONObjectViewManager }

  TJSONObjectViewManager = class(TComponent)
  private
    FJSONObject: TJSONObject;
    FPropertyViews: TJSONObjectPropertyViews;
    procedure SetJSONObject(const Value: TJSONObject);
    procedure SetPropertyViews(const Value: TJSONObjectPropertyViews);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Load;
    procedure Save;
    property JSONObject: TJSONObject read FJSONObject write SetJSONObject;
  published
    property PropertyViews: TJSONObjectPropertyViews read FPropertyViews write SetPropertyViews;
  end;

  procedure RegisterJSONMediator(const MediatorId: String; MediatorClass: TCustomJSONGUIMediatorClass);
  procedure RegisterJSONMediator(ControlClass: TControlClass; MediatorClass: TCustomJSONGUIMediatorClass);

implementation

uses
  contnrs, LuiJSONUtils;

type

  { TJSONGUIMediatorManager }

  TJSONGUIMediatorManager = class
  private
    FList: TFPHashList;
  public
    constructor Create;
    destructor Destroy; override;
    function Find(const MediatorId: String): TCustomJSONGUIMediatorClass;
    procedure RegisterMediator(const MediatorId: String; MediatorClass: TCustomJSONGUIMediatorClass);
  end;

var
  MediatorManager: TJSONGUIMediatorManager;

procedure RegisterJSONMediator(const MediatorId: String;
  MediatorClass: TCustomJSONGUIMediatorClass);
begin
  MediatorManager.RegisterMediator(MediatorId, MediatorClass);
end;

procedure RegisterJSONMediator(ControlClass: TControlClass;
  MediatorClass: TCustomJSONGUIMediatorClass);
begin
  RegisterJSONMediator(ControlClass.ClassName, MediatorClass);
end;

{ TJSONGUIMediatorStore }

constructor TJSONGUIMediatorManager.Create;
begin
  FList := TFPHashList.Create;
end;

destructor TJSONGUIMediatorManager.Destroy;
begin
  FList.Destroy;
  inherited Destroy;
end;

function TJSONGUIMediatorManager.Find(const MediatorId: String): TCustomJSONGUIMediatorClass;
begin
  Result := TCustomJSONGUIMediatorClass(FList.Find(MediatorId));
end;

procedure TJSONGUIMediatorManager.RegisterMediator(const MediatorId: String;
  MediatorClass: TCustomJSONGUIMediatorClass);
begin
  FList.Add(MediatorId, MediatorClass);
end;

{ TJSONObjectViewManager }

procedure TJSONObjectViewManager.SetPropertyViews(const Value: TJSONObjectPropertyViews);
begin
  FPropertyViews.Assign(Value);
end;

procedure TJSONObjectViewManager.SetJSONObject(const Value: TJSONObject);
begin
  if FJSONObject = Value then exit;
  FJSONObject := Value;
end;

constructor TJSONObjectViewManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPropertyViews := TJSONObjectPropertyViews.Create(Self);
end;

destructor TJSONObjectViewManager.Destroy;
begin
  FPropertyViews.Destroy;
  inherited Destroy;
end;

procedure TJSONObjectViewManager.Load;
var
  i: Integer;
  View: TJSONObjectPropertyView;
begin
  for i := 0 to FPropertyViews.Count -1 do
  begin
    View := TJSONObjectPropertyView(FPropertyViews.Items[i]);
    View.Load(FJSONObject);
  end;
end;

procedure TJSONObjectViewManager.Save;
var
  i: Integer;
  View: TJSONObjectPropertyView;
begin
  for i := 0 to FPropertyViews.Count -1 do
  begin
    View := TJSONObjectPropertyView(FPropertyViews.Items[i]);
    View.Save(FJSONObject);
  end;
end;
{ TJSONObjectPropertyViews }

function TJSONObjectPropertyViews.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

constructor TJSONObjectPropertyViews.Create(AOwner: TJSONObjectViewManager);
begin
  inherited Create(TJSONObjectPropertyView);
  FOwner := AOwner;
end;

{ TJSONObjectPropertyView }

procedure TJSONObjectPropertyView.MediatorClassNeeded;
begin
  if FMediatorClass = nil then
  begin
    if FMediatorId <> '' then
      FMediatorClass := MediatorManager.Find(FMediatorId)
    else
      FMediatorClass := MediatorManager.Find(Control.ClassName);
    if FMediatorClass = nil then
      raise Exception.CreateFmt('Could not find mediator (MediatorId: "%s" ControlClass: "%s")', [FMediatorId, Control.ClassName]);
  end;
end;

procedure TJSONObjectPropertyView.OptionsDataNeeded;
begin
  if (FOptions <> '') and (FOptionsData = nil) then
    FOptionsData := StringToJSONData(FOptions);
end;

destructor TJSONObjectPropertyView.Destroy;
begin
  FOptionsData.Free;
  inherited Destroy;
end;

procedure TJSONObjectPropertyView.Assign(Source: TPersistent);
begin
  if Source is TJSONObjectPropertyView then
  begin
    PropertyName := TJSONObjectPropertyView(Source).PropertyName;
    Control := TJSONObjectPropertyView(Source).Control;
    Options := TJSONObjectPropertyView(Source).Options;
    MediatorId := TJSONObjectPropertyView(Source).MediatorId;
  end
  else
    inherited Assign(Source);
end;

function TJSONObjectPropertyView.GetDisplayName: string;
begin
  Result := FPropertyName;
  if Result <> '' then
    Result := ClassName;
end;

procedure TJSONObjectPropertyView.Load(JSONObject: TJSONObject);
begin
  //todo handle mediator and options loading once
  MediatorClassNeeded;
  OptionsDataNeeded;
  FMediatorClass.DoJSONToGUI(JSONObject, FPropertyName, FControl, FOptionsData);
end;

procedure TJSONObjectPropertyView.Save(JSONObject: TJSONObject);
begin
  //todo handle mediator and options loading once
  MediatorClassNeeded;
  OptionsDataNeeded;
  FMediatorClass.DoGUIToJSON(FControl, JSONObject, FPropertyName, FOptionsData);
end;

{ TCustomJSONGUIMediator }

class procedure TCustomJSONGUIMediator.DoJSONToGUI(JSONObject: TJSONObject;
  const PropName: String; Control: TControl; Options: TJSONData);
begin
  //
end;

class procedure TCustomJSONGUIMediator.DoGUIToJSON(Control: TControl;
  JSONObject: TJSONObject; const PropName: String; Options: TJSONData);
begin
  //
end;

{ TJSONEditMediator }

class procedure TJSONEditMediator.DoJSONToGUI(JSONObject: TJSONObject;
  const PropName: String; Control: TControl; Options: TJSONData);
begin
  (Control as TCustomEdit).Text := JSONObject.Strings[PropName];
end;

class procedure TJSONEditMediator.DoGUIToJSON(Control: TControl;
  JSONObject: TJSONObject; const PropName: String; Options: TJSONData);
begin
  JSONObject.Strings[PropName] := (Control as TCustomEdit).Text;
end;

{ TJSONCaptionMediator }

class procedure TJSONCaptionMediator.DoJSONToGUI(JSONObject: TJSONObject;
  const PropName: String; Control: TControl; Options: TJSONData);
var
  FormatStr, TemplateStr, ValueStr: String;
  PropData: TJSONData;
begin
  PropData := JSONObject.Elements[PropName];
  ValueStr := PropData.AsString;
  if Options <> nil then
  begin
    case Options.JSONType of
      jtObject:
        begin
          FormatStr := GetJSONProp(TJSONObject(Options), 'format', '');
          if FormatStr = 'date' then
            ValueStr := DateToStr(PropData.AsFloat)
          else if FormatStr = 'datetime' then
            ValueStr := DateTimeToStr(PropData.AsFloat);
          TemplateStr := GetJSONProp(TJSONObject(Options), 'template', '%s');
        end;
      jtString: //template
        TemplateStr := Options.AsString;
    else
    begin
      TemplateStr := '%s';
    end;
    end;
    Control.Caption := Format(TemplateStr, [ValueStr]);
  end
  else
    Control.Caption := ValueStr;
end;

class procedure TJSONCaptionMediator.DoGUIToJSON(Control: TControl;
  JSONObject: TJSONObject; const PropName: String; Options: TJSONData);
begin
  //
end;

initialization
  MediatorManager := TJSONGUIMediatorManager.Create;
  RegisterJSONMediator(TEdit, TJSONEditMediator);
  RegisterJSONMediator(TMemo, TJSONEditMediator);
  RegisterJSONMediator(TLabel, TJSONCaptionMediator);

finalization
  MediatorManager.Destroy;

end.
