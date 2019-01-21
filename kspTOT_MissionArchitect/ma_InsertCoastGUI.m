function varargout = ma_InsertCoastGUI(varargin)
% MA_INSERTCOASTGUI MATLAB code for ma_InsertCoastGUI.fig
%      MA_INSERTCOASTGUI, by itself, creates a new MA_INSERTCOASTGUI or raises the existing
%      singleton*.
%
%      H = MA_INSERTCOASTGUI returns the handle to a new MA_INSERTCOASTGUI or the handle to
%      the existing singleton*.
%
%      MA_INSERTCOASTGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_INSERTCOASTGUI.M with the given input arguments.
%
%      MA_INSERTCOASTGUI('Property','Value',...) creates a new MA_INSERTCOASTGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_InsertCoastGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_InsertCoastGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_InsertCoastGUI

% Last Modified by GUIDE v2.5 20-Jan-2019 15:57:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_InsertCoastGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_InsertCoastGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before ma_InsertCoastGUI is made visible.
function ma_InsertCoastGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_InsertCoastGUI (see VARARGIN)

% Choose default command line output for ma_InsertCoastGUI
global use_selective_soi_search;

isInit(true);
handles.output = hObject;
handles.ma_MainGUI = varargin{1};

% Update handles structure
guidata(hObject, handles);

% Setup GUI
populateBodiesCombo(getappdata(handles.ma_MainGUI,'celBodyData'), handles.bodiesCombo, true);
populateBodiesCombo(getappdata(handles.ma_MainGUI,'celBodyData'), handles.customFuncRefCelBodyCombo, false);
populateOtherSCCombo(handles, handles.customFuncRefSpacecraftCombo);
populateStationsCombo(handles, handles.customFuncRefGrdStnCombo);

taskList = ma_getGraphAnalysisTaskList({'Distance Traveled'});
set(handles.customFuncFuncCombo, 'String', taskList);

maData = getappdata(handles.ma_MainGUI,'ma_data');
substituteDefaultPropNamesWithCustomNamesInDepVarListbox(handles.customFuncFuncCombo, maData.spacecraft.propellant.names);

if(length(varargin)>1) 
    event = varargin{2};
    setappdata(hObject,'lossConverts',event.massloss.lossConvert);
    populateGUIWithEvent(handles, event);
    set(hObject,'UserData',event);
else
    set(hObject,'UserData',[]);
    setappdata(hObject,'soiSkipIds',[]);
    setappdata(hObject,'lossConverts',getDefaultLossConvert(handles));
    orbitDecayCheckbox_Callback(handles.orbitDecayCheckbox, [], handles);
end
coastTypeCombo_Callback(handles.coastTypeCombo, [], handles);
optVar1ChkBox_Callback(handles.optVar1ChkBox, [], handles);
setEditLossConvertButtonTooltipString(handles);

if(use_selective_soi_search)
    set(handles.selectiveSearchActiveLabel,'String','Active','ForegroundColor',[34,139,34]/255);
else
    set(handles.selectiveSearchActiveLabel,'String','Inactive','ForegroundColor',[0.847,0.161,0]);
end

% UIWAIT makes ma_InsertCoastGUI wait for user response (see UIRESUME)
isInit(false);
uiwait(handles.ma_InsertCoastGUI);

function populateGUIWithEvent(handles, event)
    maData = getappdata(handles.ma_MainGUI,'ma_data');

    set(handles.titleLabel, 'String', 'Edit Coast');
    set(handles.ma_InsertCoastGUI, 'Name', 'Edit Coast');
    set(handles.coastNameText, 'String', event.name);
    set(handles.numRevsText, 'String', num2str(event.revs));
    
    if(~isfield(event,'refBody') || isempty(event.refBody))
        bodyToSearchFor = '';
    else
        bodyToSearchFor = event.refBody.name;
    end
    bodyValue = findValueFromComboBox(bodyToSearchFor, handles.bodiesCombo);
    
    if(isempty(bodyValue))
        set(handles.bodiesCombo, 'value', 1);
    else
        set(handles.bodiesCombo, 'value', bodyValue);
    end
    
    opt = event.vars;
       
    value = event.coastToValue;
    switch event.coastType
        case 'goto_ut'
            coastType = 'Go to UT';
            set(handles.optVar1ChkBox, 'value', opt(1,1));  
            set(handles.optVar1LwrText, 'string', fullAccNum2Str(opt(2,1)));
            set(handles.optVar1UprText, 'string', fullAccNum2Str(opt(3,1)));
        case 'goto_dt'
            coastType = 'Go to Delta Time';
            set(handles.optVar1ChkBox, 'value', opt(1,1));  
            set(handles.optVar1LwrText, 'string', fullAccNum2Str(opt(2,1)));
            set(handles.optVar1UprText, 'string', fullAccNum2Str(opt(3,1)));
        case 'goto_tru'
            coastType = 'Go to True Anomaly';
            value = rad2deg(value);
            set(handles.optVar1ChkBox, 'value', opt(1,1));  
            set(handles.optVar1LwrText, 'string', fullAccNum2Str(rad2deg(opt(2,1))));
            set(handles.optVar1UprText, 'string', fullAccNum2Str(rad2deg(opt(3,1))));
        case 'goto_apo'
            coastType = 'Go to Apoapsis';
            set(handles.optVar1ChkBox, 'value', opt(1,1));  
            set(handles.optVar1LwrText, 'string', fullAccNum2Str(opt(2,1)));
            set(handles.optVar1UprText, 'string', fullAccNum2Str(opt(3,1)));
        case 'goto_peri'
            coastType = 'Go to Periapsis';
            set(handles.optVar1ChkBox, 'value', opt(1,1));  
            set(handles.optVar1LwrText, 'string', fullAccNum2Str(opt(2,1)));
            set(handles.optVar1UprText, 'string', fullAccNum2Str(opt(3,1)));
        case 'goto_asc_node'
            coastType = 'Go to Ascending Node';
            set(handles.optVar1ChkBox, 'value', opt(1,1));  
            set(handles.optVar1LwrText, 'string', fullAccNum2Str(opt(2,1)));
            set(handles.optVar1UprText, 'string', fullAccNum2Str(opt(3,1)));
        case 'goto_desc_node'
            coastType = 'Go to Descending Node';
            set(handles.optVar1ChkBox, 'value', opt(1,1));  
            set(handles.optVar1LwrText, 'string', fullAccNum2Str(opt(2,1)));
            set(handles.optVar1UprText, 'string', fullAccNum2Str(opt(3,1)));
        case 'goto_soi_trans'
            coastType = 'Go to Next SoI Transition';
            set(handles.optVar1ChkBox, 'value', opt(1,1));  
            set(handles.optVar1LwrText, 'string', fullAccNum2Str(opt(2,1)));
            set(handles.optVar1UprText, 'string', fullAccNum2Str(opt(3,1)));
        case 'goto_func_value'
            coastType = 'Go to Function Value';
            set(handles.optVar1ChkBox, 'value', opt(1,1));  
            set(handles.optVar1LwrText, 'string', fullAccNum2Str(opt(2,1)));
            set(handles.optVar1UprText, 'string', fullAccNum2Str(opt(3,1)));
    end
    typeValue = findValueFromComboBox(coastType, handles.coastTypeCombo);
    set(handles.coastTypeCombo,'value',typeValue);

    colorStr = getStringFromLineSpecColor(event.lineColor);
    colorValue = findValueFromComboBox(colorStr, handles.coastLineColorCombo);
    set(handles.coastLineColorCombo,'value',colorValue);
    
    styleStr = getLineStyleFromString(event.lineStyle);
    styleValue = findValueFromComboBox(styleStr, handles.coastLineStyleCombo);
 	set(handles.coastLineStyleCombo,'Value',styleValue);
    
    contents = handles.lineWidthCombo.String;
    contentsDouble = str2double(contents);
    ind = find(contentsDouble == event.lineWidth);
    set(handles.lineWidthCombo,'Value',ind);
    
    set(handles.massLossCheckbox,'Value',event.massloss.use);
    massLossCheckbox_Callback(handles.massLossCheckbox, [], handles);
    
    set(handles.orbitDecayCheckbox, 'Value', event.orbitDecay.use);
    set(handles.scAreaText, 'String', fullAccNum2Str(event.orbitDecay.scArea));
    set(handles.solarFluxText, 'String', fullAccNum2Str(event.orbitDecay.solarFlux));
    set(handles.geomagneticIndText, 'String', fullAccNum2Str(event.orbitDecay.geoMagInd));
    orbitDecayCheckbox_Callback(handles.orbitDecayCheckbox, [], handles);
    
    set(handles.coastValueText, 'String', fullAccNum2Str(value));
    setappdata(handles.ma_InsertCoastGUI,'soiSkipIds',event.soiSkipIds);
    
    funcHandle = event.funcHandle;
    if(~isempty(funcHandle) && isa(funcHandle,'function_handle'))
        [~,~,~, taskStr, refBodyInfo, otherSC, station] = funcHandle([], true, maData);
        taskStrValue = findValueFromComboBox(taskStr, handles.customFuncFuncCombo);
        handles.customFuncFuncCombo.Value = taskStrValue;
        
        bodyValue = findValueFromComboBox(refBodyInfo.name, handles.customFuncRefCelBodyCombo);
        handles.customFuncRefCelBodyCombo.Value = bodyValue;
        
        oscValue = [];
        if(~isempty(otherSC))
            oscID = otherSC.id;
            
            otherSCs = maData.spacecraft.otherSC;
            for(i=1:length(otherSCs))
                oSc = otherSCs{i};
                
                if(oSc.id == oscID)
                    oscValue = i;
                    break;
                end
            end
        end
        if(~isempty(oscValue))
            handles.customFuncRefSpacecraftCombo.Value = oscValue;
        end
        
        stnValue = [];
        if(~isempty(station))
            stnID = station.id;
            
            stations = maData.spacecraft.stations;
            for(i=1:length(stations))
                stn = stations{i};
                
                if(stn.id == stnID)
                    stnValue = i;
                    break;
                end
            end
        end
        if(~isempty(stnValue))
            handles.customFuncRefGrdStnCombo.Value = stnValue;
        end
    end
    
    set(handles.customFuncMaxPropTimeText, 'String', fullAccNum2Str(event.maxPropTime));

    
function init = isInit(varargin)    
    persistent initVar
    
    if(isempty(initVar))
        initVar = false;
    end
    init = initVar;
    
    if(isempty(varargin))
        return;
    else
        initVar = varargin{1};
        init = initVar;
        return
    end
    
% --- Outputs from this function are returned to the command line.
function varargout = ma_InsertCoastGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if(isempty(handles))
    varargout{1} = [];
else
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    
    typeCombo = handles.coastTypeCombo;
    contents = cellstr(get(typeCombo,'String'));
    selected = contents{get(typeCombo,'Value')};

    name = get(handles.coastNameText, 'String');

    value = str2double(get(handles.coastValueText,'String'));
    revs = str2double(get(handles.numRevsText,'String'));

    switch selected
        case 'Go to UT'
            coastType = 'goto_ut';
            vars(1,1) = [get(handles.optVar1ChkBox,'value')];
            vars(2,1) = [str2double(get(handles.optVar1LwrText,'string'))];
            vars(3,1) = [str2double(get(handles.optVar1UprText,'string'))];
        case 'Go to Delta Time'
            coastType = 'goto_dt';
            vars(1,1) = [get(handles.optVar1ChkBox,'value')];
            vars(2,1) = [str2double(get(handles.optVar1LwrText,'string'))];
            vars(3,1) = [str2double(get(handles.optVar1UprText,'string'))];
        case 'Go to True Anomaly'
            coastType = 'goto_tru';
            value = deg2rad(value);
            vars(1,1) = [get(handles.optVar1ChkBox,'value')];
            vars(2,1) = [deg2rad(str2double(get(handles.optVar1LwrText,'string')))];
            vars(3,1) = [deg2rad(str2double(get(handles.optVar1UprText,'string')))];
        case 'Go to Apoapsis'
            coastType = 'goto_apo';
            vars = [0;0;0];
        case 'Go to Periapsis'
            coastType = 'goto_peri';
            vars = [0;0;0];
        case 'Go to Ascending Node'
            coastType = 'goto_asc_node';
            vars = [0;0;0];
        case 'Go to Descending Node'
            coastType = 'goto_desc_node';
            vars = [0;0;0];
        case 'Go to Next SoI Transition'
            coastType = 'goto_soi_trans';
            revs = 0;
            vars = [0;0;0];
        case 'Go to Function Value'
            coastType = 'goto_func_value';
            vars(1,1) = [get(handles.optVar1ChkBox,'value')];
            vars(2,1) = [str2double(get(handles.optVar1LwrText,'string'))];
            vars(3,1) = [str2double(get(handles.optVar1UprText,'string'))];
    end
        
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    contents = cellstr(get(handles.bodiesCombo,'String'));
    selected = contents{get(handles.bodiesCombo,'Value')};
    if(strcmpi(selected,''))
        bodyInfo = [];
    else
        bodyInfo = celBodyData.(lower(strtrim(selected)));
    end
    
    contents = cellstr(get(handles.coastLineColorCombo,'String'));
	colorStr = contents{get(handles.coastLineColorCombo,'Value')};
    lineSpecColor = getLineSpecColorFromString(colorStr);
    
    contents = cellstr(get(handles.coastLineStyleCombo,'String'));
    lineStyleStr = contents{get(handles.coastLineStyleCombo,'Value')};
    lineStyle = getLineStyleStrFromText(lineStyleStr);
    
    contents = handles.lineWidthCombo.String;
    contentsDouble = str2double(contents);
    contensInd = get(handles.lineWidthCombo,'Value');
    lineWidth = contentsDouble(contensInd);
    
    soiSkipIds = getappdata(hObject,'soiSkipIds');    
    
    massloss = struct('use',logical(get(handles.massLossCheckbox,'Value')), 'lossConvert',getappdata(handles.ma_InsertCoastGUI,'lossConverts'));
    
    orbitDecay = struct('use',logical(get(handles.orbitDecayCheckbox,'Value')), ...
                        'scArea', str2double(get(handles.scAreaText,'String')), ...
                        'solarFlux', str2double(get(handles.solarFluxText,'String')), ...
                        'geoMagInd', str2double(get(handles.geomagneticIndText,'String')));
    
    contents = cellstr(get(handles.customFuncFuncCombo,'String'));
    taskStr = contents{get(handles.customFuncFuncCombo,'Value')};
    
    hRefBodyCombo = handles.customFuncRefCelBodyCombo;
    contents = cellstr(get(hRefBodyCombo,'String'));
    refBodyStr = contents{get(hRefBodyCombo,'Value')};
    refBodyInfo = celBodyData.(strtrim(lower(refBodyStr)));
    refBodyId = refBodyInfo.id;
    
    hRefSCCombo = handles.customFuncRefSpacecraftCombo;
    if(strcmpi(get(hRefSCCombo,'Enable'),'off'))
        refOtherScId = [];
    else
        try
            refSCInd = get(hRefSCCombo,'Value');
            otherSCs = maData.spacecraft.otherSC;
            refOtherScId = otherSCs{refSCInd}.id;
        catch
            refOtherScId = [];
        end
    end   
    
    hRefStnCombo = handles.customFuncRefGrdStnCombo;
    if(strcmpi(get(hRefStnCombo,'Enable'),'off'))
        refStationId = [];
    else
        try
            refSCInd = get(hRefStnCombo,'Value');
            stations = maData.spacecraft.stations;
            refStationId = stations{refSCInd}.id;
        catch
            refStationId = [];
        end
    end
    
    propNames = maData.spacecraft.propellant.names;
    for(i=1:length(propNames))
        propNames{i} = sprintf('%s Mass',propNames{i});
    end

    funcHandle = @(stateLogRow, onlyReturnTaskStr, maData) ma_getDepVarValueUnit(1, stateLogRow, taskStr, 0, refBodyId, refOtherScId, refStationId, propNames, maData, celBodyData, onlyReturnTaskStr);
    maxPropTime = str2double(get(handles.customFuncMaxPropTimeText,'String'));
    
    varargout{1} = ma_createCoast(name, coastType, value, revs, bodyInfo, vars, soiSkipIds, lineSpecColor, lineStyle, lineWidth, massloss, funcHandle, maxPropTime, orbitDecay);
    close(handles.ma_InsertCoastGUI);
end

% --------------------------------------------------------------------
function enterUTAsDateTime_Callback(~, ~)
    secUT = enterUTAsDateTimeGUI(str2double(get(gco, 'String')));
    if(secUT >= 0)
        set(gco, 'String', num2str(secUT));
    end


% --- Executes on selection change in coastTypeCombo.
function coastTypeCombo_Callback(hObject, eventdata, handles)
% hObject    handle to coastTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns coastTypeCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from coastTypeCombo
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    stateLog = maData.stateLog;
    script = maData.script;
    event = get(handles.ma_InsertCoastGUI,'UserData');

    if(~isempty(event))
        for(i=1:length(script))
            if(script{i}.id == event.id)
                eventNum = i;
                break;
            else
                eventNum = [];
            end
        end

        eventLog = stateLog(stateLog(:,13)==eventNum,:);
        stateRowStartEvent = eventLog(1,:);
        stateRowEndEvent = eventLog(end,:);

        prevEventLog = stateLog(stateLog(:,13)==eventNum-1,:);
        prevStateRowEndEvent = prevEventLog(end,:);
    else
        eventNum = [];
        stateRowStartEvent = [];
        stateRowEndEvent = [];
    end

    contents = cellstr(get(hObject,'String'));
    selected = contents{get(hObject,'Value')};

    typeLabel = handles.coastValueTypeLabel;
    unitsLabel = handles.unitsLabel;
    editLabel = handles.coastValueText;

    set(handles.coastValueText,'uicontextmenu',[]);
    set(handles.optVar1LwrText,'uicontextmenu',[]);
    set(handles.optVar1UprText,'uicontextmenu',[]);

    switch selected
        case 'Go to UT'
            set(typeLabel,'String','Universal Time');
            set(unitsLabel,'String','sec');
            set(editLabel,'Enable','on');
            set(handles.numRevsText, 'Enable','on');
            set(handles.optVar1ChkBox,'Enable','on');
            set(handles.optVar1LwrText,'Enable','on');
            set(handles.optVar1UprText,'Enable','on');

            set(handles.optVar1LwrText,'TooltipString','UT Lower Bound');
            set(handles.optVar1UprText,'TooltipString','UT Upper Bound');

            if(~isempty(eventNum) && isInit() == false)
                [returnValue,returnRevs] = ma_convertCoastValue(stateRowStartEvent, stateRowEndEvent, prevStateRowEndEvent, selected, celBodyData);
                if(~isempty(returnValue))
                    set(handles.coastValueText,'String',num2str(returnValue,'%15.8f'));
                    if(~isnan(returnRevs))
                        set(handles.numRevsText,'String',num2str(returnRevs,'%5.0f'));
                    end
                end
            end

            hcmenu = uicontextmenu;
            cMCallback = @(src,eventdata) enterUTAsDateTime_Callback(src,eventdata);
            uimenu(hcmenu,'Label','Enter UT As Date/Time','Callback',cMCallback);
            set(handles.coastValueText,'uicontextmenu',hcmenu);
            set(handles.optVar1LwrText,'uicontextmenu',hcmenu);
            set(handles.optVar1UprText,'uicontextmenu',hcmenu);

            setCustFuncEnable('off', handles);
        case 'Go to Delta Time'
            set(typeLabel,'String','Delta Time');
            set(unitsLabel,'String','sec');
            set(editLabel,'Enable','on');
            set(handles.numRevsText, 'Enable','on');
            set(handles.optVar1ChkBox,'Enable','on');
            set(handles.optVar1LwrText,'Enable','on');
            set(handles.optVar1UprText,'Enable','on');

            if(~isempty(eventNum) && isInit() == false)
                [returnValue,returnRevs] = ma_convertCoastValue(stateRowStartEvent, stateRowEndEvent, prevStateRowEndEvent, selected, celBodyData);
                if(~isempty(returnValue))
                    set(handles.coastValueText,'String',num2str(returnValue,'%15.8f'));
                    if(~isnan(returnRevs))
                        set(handles.numRevsText,'String',num2str(returnRevs,'%5.0f'));
                    end
                end
            end

            set(handles.optVar1LwrText,'TooltipString','dT Lower Bound');
            set(handles.optVar1UprText,'TooltipString','dT Upper Bound');

            setCustFuncEnable('off', handles);
        case 'Go to True Anomaly'
            set(typeLabel,'String','True Anomaly');
            set(unitsLabel,'String','deg');
            set(editLabel,'Enable','on');
            set(handles.numRevsText, 'Enable','on');
            set(handles.optVar1ChkBox,'Enable','on');
            set(handles.optVar1LwrText,'Enable','on');
            set(handles.optVar1UprText,'Enable','on');

            if(~isempty(eventNum) && isInit() == false)
                [returnValue,returnRevs] = ma_convertCoastValue(stateRowStartEvent, stateRowEndEvent, prevStateRowEndEvent, selected, celBodyData);
                if(~isempty(returnValue))
                    set(handles.coastValueText,'String',num2str(returnValue,'%15.8f'));
                    if(~isnan(returnRevs))
                        set(handles.numRevsText,'String',num2str(returnRevs,'%5.0f'));
                    end
                end
            end

            set(handles.optVar1LwrText,'TooltipString','True Anomaly Lower Bound');
            set(handles.optVar1UprText,'TooltipString','True Anomaly Upper Bound');

            setCustFuncEnable('off', handles);
        case 'Go to Apoapsis'
            set(typeLabel,'String','True Anomaly');
            set(unitsLabel,'String','deg');
            set(editLabel,'Enable','off');
            set(handles.numRevsText, 'Enable','on');
            set(handles.optVar1ChkBox,'Enable','off');
            set(handles.optVar1LwrText,'Enable','off');
            set(handles.optVar1UprText,'Enable','off');

            set(handles.optVar1LwrText,'TooltipString','');
            set(handles.optVar1UprText,'TooltipString','');

            setCustFuncEnable('off', handles);
        case 'Go to Periapsis'
            set(typeLabel,'String','True Anomaly');
            set(unitsLabel,'String','deg');
            set(editLabel,'Enable','off');
            set(handles.numRevsText, 'Enable','on');
            set(handles.optVar1ChkBox,'Enable','off');
            set(handles.optVar1LwrText,'Enable','off');
            set(handles.optVar1UprText,'Enable','off');

            set(handles.optVar1LwrText,'TooltipString','');
            set(handles.optVar1UprText,'TooltipString','');  

            setCustFuncEnable('off', handles);
        case 'Go to Ascending Node'
            set(typeLabel,'String','True Anomaly');
            set(unitsLabel,'String','deg');
            set(editLabel,'Enable','off');
            set(handles.numRevsText, 'Enable','on');
            set(handles.optVar1ChkBox,'Enable','off');
            set(handles.optVar1LwrText,'Enable','off');
            set(handles.optVar1UprText,'Enable','off');

            set(handles.optVar1LwrText,'TooltipString','');
            set(handles.optVar1UprText,'TooltipString','');   

            setCustFuncEnable('off', handles);
        case 'Go to Descending Node'
            set(typeLabel,'String','True Anomaly');
            set(unitsLabel,'String','deg');
            set(editLabel,'Enable','off');
            set(handles.numRevsText, 'Enable','on');
            set(handles.optVar1ChkBox,'Enable','off');
            set(handles.optVar1LwrText,'Enable','off');
            set(handles.optVar1UprText,'Enable','off');

            set(handles.optVar1LwrText,'TooltipString','');
            set(handles.optVar1UprText,'TooltipString','');

            setCustFuncEnable('off', handles);
        case 'Go to Next SoI Transition'
            set(typeLabel,'String','True Anomaly');
            set(unitsLabel,'String','deg');
            set(editLabel,'Enable','off');
            set(handles.numRevsText, 'Enable','off');
            set(handles.optVar1ChkBox,'Enable','off');
            set(handles.optVar1LwrText,'Enable','off');
            set(handles.optVar1UprText,'Enable','off');

            set(handles.optVar1LwrText,'TooltipString','');
            set(handles.optVar1UprText,'TooltipString','');  

            setCustFuncEnable('off', handles);
        case 'Go to Function Value'
            set(typeLabel,'String','Function Value');
            set(unitsLabel,'String','UNIT HERE');
            set(editLabel,'Enable','on');
            set(handles.numRevsText, 'Enable','on');
            set(handles.optVar1ChkBox,'Enable','on');
            set(handles.optVar1LwrText,'Enable','on');
            set(handles.optVar1UprText,'Enable','on');

            setCustFuncEnable('on', handles);
            customFuncFuncCombo_Callback(handles.customFuncFuncCombo, [], handles);
    end
    
    if(strcmpi(get(handles.optVar1ChkBox,'Enable'),'on'))
        optVar1ChkBox_Callback(handles.optVar1ChkBox, [], handles)
    end
    
    

function setCustFuncEnable(enable, handles)
    set(handles.customFuncFuncCombo,'Enable',enable);
    set(handles.customFuncRefCelBodyCombo,'Enable',enable);
    
    if(strcmpi(handles.customFuncRefSpacecraftCombo.String,'None Available'))
        set(handles.customFuncRefSpacecraftCombo,'Enable','off');
    else
        set(handles.customFuncRefSpacecraftCombo,'Enable',enable);
    end
    
    if(strcmpi(handles.customFuncRefGrdStnCombo.String,'None Available'))
        set(handles.customFuncRefGrdStnCombo,'Enable','off');
    else
        set(handles.customFuncRefGrdStnCombo,'Enable',enable);
    end
    
    set(handles.customFuncMaxPropTimeText,'Enable', enable);

function errMsg = validateInputs(handles)
    errMsg = {};
    
    revs = str2double(get(handles.numRevsText,'String'));
    enteredStr = get(handles.numRevsText,'String');
    numberName = 'Revs Prior to Coast';
    lb = 0;
    ub = Inf;
    isInt = true;
    errMsg = validateNumber(revs, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    contents = cellstr(get(handles.coastTypeCombo,'String'));
    selected = contents{get(handles.coastTypeCombo,'Value')};
    
    switch selected
        case 'Go to UT'
            value = str2double(get(handles.coastValueText,'String'));
            enteredStr = get(handles.coastValueText,'String');
            numberName = ['Input ', get(handles.coastValueTypeLabel,'String')];
            lb = 0;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1LB = str2double(get(handles.optVar1LwrText,'String'));
            enteredStr = get(handles.optVar1LwrText,'String');
            numberName = 'Optimization Lower Bound';
            lb = 0;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector1LB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1UB = str2double(get(handles.optVar1UprText,'String'));
            enteredStr = get(handles.optVar1UprText,'String');
            numberName = 'Optimization Upper Bound';
            lb = 0;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector1UB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            if(isempty(errMsg))
                if(get(handles.optVar1ChkBox,'value')==1 && strcmpi(get(handles.optVar1ChkBox,'Enable'),'On'))
                    vector1UB = str2double(get(handles.optVar1UprText,'String'));
                    enteredStr = get(handles.optVar1UprText,'String');
                    numberName = 'Optimization Upper Bound';
                    lb = vector1LB;
                    ub = Inf;
                    isInt = false;
                    errMsg = validateNumber(vector1UB, numberName, lb, ub, isInt, errMsg, enteredStr);

                    if(isempty(errMsg))
                        value = str2double(get(handles.coastValueText,'String'));
                        enteredStr = get(handles.coastValueText,'String');
                        numberName = ['Input ', get(handles.coastValueTypeLabel,'String')];
                        lb = vector1LB;
                        ub = vector1UB;
                        isInt = false;
                        errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
                    end
                end
            end
            
        case 'Go to Delta Time'
            %%%%%%%%%%
            value = str2double(get(handles.coastValueText,'String'));
            enteredStr = get(handles.coastValueText,'String');
            numberName = ['Input ', get(handles.coastValueTypeLabel,'String')];
            lb = 0;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1LB = str2double(get(handles.optVar1LwrText,'String'));
            enteredStr = get(handles.optVar1LwrText,'String');
            numberName = 'Optimization Lower Bound';
            lb = 0;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector1LB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1UB = str2double(get(handles.optVar1UprText,'String'));
            enteredStr = get(handles.optVar1UprText,'String');
            numberName = 'Optimization Upper Bound';
            lb = 0;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector1UB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            if(isempty(errMsg))
                if(get(handles.optVar1ChkBox,'value')==1 && strcmpi(get(handles.optVar1ChkBox,'Enable'),'On'))
                    vector1UB = str2double(get(handles.optVar1UprText,'String'));
                    enteredStr = get(handles.optVar1UprText,'String');
                    numberName = 'Optimization Upper Bound';
                    lb = vector1LB;
                    ub = Inf;
                    isInt = false;
                    errMsg = validateNumber(vector1UB, numberName, lb, ub, isInt, errMsg, enteredStr);

                    if(isempty(errMsg))
                        value = str2double(get(handles.coastValueText,'String'));
                        enteredStr = get(handles.coastValueText,'String');
                        numberName = ['Input ', get(handles.coastValueTypeLabel,'String')];
                        lb = vector1LB;
                        ub = vector1UB;
                        isInt = false;
                        errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
                    end
                end
            end
            %%%%%%%%%%%

        case 'Go to True Anomaly'
            %%%%%%%%%%
            value = str2double(get(handles.coastValueText,'String'));
            enteredStr = get(handles.coastValueText,'String');
            numberName = ['Input ', get(handles.coastValueTypeLabel,'String')];
            lb = -180;
            ub = 360;
            isInt = false;
            errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1LB = str2double(get(handles.optVar1LwrText,'String'));
            enteredStr = get(handles.optVar1LwrText,'String');
            numberName = 'Optimization Lower Bound';
            lb = -180;
            ub = 360;
            isInt = false;
            errMsg = validateNumber(vector1LB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1UB = str2double(get(handles.optVar1UprText,'String'));
            enteredStr = get(handles.optVar1UprText,'String');
            numberName = 'Optimization Upper Bound';
            lb = -180;
            ub = 360;
            isInt = false;
            errMsg = validateNumber(vector1UB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            if(isempty(errMsg))
                if(get(handles.optVar1ChkBox,'value')==1 && strcmpi(get(handles.optVar1ChkBox,'Enable'),'On'))
                    vector1UB = str2double(get(handles.optVar1UprText,'String'));
                    enteredStr = get(handles.optVar1UprText,'String');
                    numberName = 'Optimization Upper Bound';
                    lb = vector1LB;
                    ub = 360;
                    isInt = false;
                    errMsg = validateNumber(vector1UB, numberName, lb, ub, isInt, errMsg, enteredStr);
                
                    if(isempty(errMsg))
                        value = str2double(get(handles.coastValueText,'String'));
                        enteredStr = get(handles.coastValueText,'String');
                        numberName = ['Input ', get(handles.coastValueTypeLabel,'String')];
                        lb = vector1LB;
                        ub = vector1UB;
                        isInt = false;
                        errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
                    end
                end
            end
            %%%%%%%%%%%
        case 'Go to Apoapsis'
            value = str2double(get(handles.coastValueText,'String'));
            enteredStr = get(handles.coastValueText,'String');
            numberName = ['Input ', get(handles.coastValueTypeLabel,'String')];
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1LB = str2double(get(handles.optVar1LwrText,'String'));
            enteredStr = get(handles.optVar1LwrText,'String');
            numberName = 'Optimization Lower Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector1LB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1UB = str2double(get(handles.optVar1UprText,'String'));
            enteredStr = get(handles.optVar1UprText,'String');
            numberName = 'Optimization Upper Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector1UB, numberName, lb, ub, isInt, errMsg, enteredStr);
        case 'Go to Periapsis'
            value = str2double(get(handles.coastValueText,'String'));
            enteredStr = get(handles.coastValueText,'String');
            numberName = ['Input ', get(handles.coastValueTypeLabel, 'String')];
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1LB = str2double(get(handles.optVar1LwrText,'String'));
            enteredStr = get(handles.optVar1LwrText,'String');
            numberName = 'Optimization Lower Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector1LB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1UB = str2double(get(handles.optVar1UprText,'String'));
            enteredStr = get(handles.optVar1UprText,'String');
            numberName = 'Optimization Upper Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector1UB, numberName, lb, ub, isInt, errMsg, enteredStr);
        case 'Go to Ascending Node'
            value = str2double(get(handles.coastValueText,'String'));
            enteredStr = get(handles.coastValueText,'String');
            numberName = ['Input ', get(handles.coastValueTypeLabel,'String')];
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1LB = str2double(get(handles.optVar1LwrText,'String'));
            enteredStr = get(handles.optVar1LwrText,'String');
            numberName = 'Optimization Lower Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector1LB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1UB = str2double(get(handles.optVar1UprText,'String'));
            enteredStr = get(handles.optVar1UprText,'String');
            numberName = 'Optimization Upper Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector1UB, numberName, lb, ub, isInt, errMsg, enteredStr);
        case 'Go to Descending Node'
            value = str2double(get(handles.coastValueText,'String'));
            enteredStr = get(handles.coastValueText,'String');
            numberName = ['Input ', get(handles.coastValueTypeLabel,'String')];
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1LB = str2double(get(handles.optVar1LwrText,'String'));
            enteredStr = get(handles.optVar1LwrText,'String');
            numberName = 'Optimization Lower Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector1LB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1UB = str2double(get(handles.optVar1UprText,'String'));
            enteredStr = get(handles.optVar1UprText,'String');
            numberName = 'Optimization Upper Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector1UB, numberName, lb, ub, isInt, errMsg, enteredStr);
        case 'Go to Next SoI Transition'
            value = str2double(get(handles.coastValueText,'String'));
            enteredStr = get(handles.coastValueText,'String');
            numberName = ['Input ', get(handles.coastValueTypeLabel,'String')];
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1LB = str2double(get(handles.optVar1LwrText,'String'));
            enteredStr = get(handles.optVar1LwrText,'String');
            numberName = 'Optimization Lower Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector1LB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1UB = str2double(get(handles.optVar1UprText,'String'));
            enteredStr = get(handles.optVar1UprText,'String');
            numberName = 'Optimization Upper Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector1UB, numberName, lb, ub, isInt, errMsg, enteredStr);
        case 'Go to Function Value'
            value = str2double(get(handles.coastValueText,'String'));
            enteredStr = get(handles.coastValueText,'String');
            numberName = ['Input ', get(handles.coastValueTypeLabel,'String')];
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1LB = str2double(get(handles.optVar1LwrText,'String'));
            enteredStr = get(handles.optVar1LwrText,'String');
            numberName = 'Optimization Lower Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector1LB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1UB = str2double(get(handles.optVar1UprText,'String'));
            enteredStr = get(handles.optVar1UprText,'String');
            numberName = 'Optimization Upper Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector1UB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            value = str2double(get(handles.customFuncMaxPropTimeText,'String'));
            enteredStr = get(handles.customFuncMaxPropTimeText,'String');
            numberName = 'Function Maximum Propagation Time';
            lb = 0;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
        otherwise
            errMsg{end+1} = 'Coast type not recongized during input validation.';
            return;
    end


% --- Executes during object creation, after setting all properties.
function coastTypeCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to coastTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function coastValueText_Callback(hObject, eventdata, handles)
% hObject    handle to coastValueText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of coastValueText as text
%        str2double(get(hObject,'String')) returns contents of coastValueText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function coastValueText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to coastValueText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in saveCloseButton.
function saveCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);

    if(isempty(errMsg))
        uiresume(handles.ma_InsertCoastGUI);
    else
        msgbox(errMsg,'Errors were found while inserting a coast.','error');
    end  


% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.ma_InsertCoastGUI);


function numRevsText_Callback(hObject, eventdata, handles)
% hObject    handle to numRevsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numRevsText as text
%        str2double(get(hObject,'String')) returns contents of numRevsText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function numRevsText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numRevsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function coastNameText_Callback(hObject, eventdata, handles)
% hObject    handle to coastNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of coastNameText as text
%        str2double(get(hObject,'String')) returns contents of coastNameText as a double


% --- Executes during object creation, after setting all properties.
function coastNameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to coastNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in bodiesCombo.
function bodiesCombo_Callback(hObject, eventdata, handles)
% hObject    handle to bodiesCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns bodiesCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from bodiesCombo


% --- Executes during object creation, after setting all properties.
function bodiesCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bodiesCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in optVar1ChkBox.
function optVar1ChkBox_Callback(hObject, eventdata, handles)
% hObject    handle to optVar1ChkBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of optVar1ChkBox
    if(get(hObject,'Value'))
        set(handles.optVar1LwrText,'Enable','on');
        set(handles.optVar1UprText,'Enable','on');
    else
        set(handles.optVar1LwrText,'Enable','off');
        set(handles.optVar1UprText,'Enable','off');
    end


function optVar1LwrText_Callback(hObject, eventdata, handles)
% hObject    handle to optVar1LwrText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of optVar1LwrText as text
%        str2double(get(hObject,'String')) returns contents of optVar1LwrText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function optVar1LwrText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to optVar1LwrText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function optVar1UprText_Callback(hObject, eventdata, handles)
% hObject    handle to optVar1UprText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of optVar1UprText as text
%        str2double(get(hObject,'String')) returns contents of optVar1UprText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function optVar1UprText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to optVar1UprText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on ma_InsertCoastGUI or any of its controls.
function ma_InsertCoastGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to ma_InsertCoastGUI (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            saveCloseButton_Callback(handles.saveCloseButton, [], handles);
        case 'enter'
            saveCloseButton_Callback(handles.saveCloseButton, [], handles);
        case 'escape'
            close(handles.ma_InsertCoastGUI);
    end


% --- Executes on button press in selectiveSoISearchButton.
function selectiveSoISearchButton_Callback(hObject, eventdata, handles)
% hObject    handle to selectiveSoISearchButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    event = get(handles.ma_InsertCoastGUI,'UserData');
    
    if(~isempty(event))
        soiSkipIds = getappdata(handles.ma_InsertCoastGUI,'soiSkipIds');
    else
        soiSkipIds = [];
    end
    
    bodies = fields(celBodyData);
    S = cell(length(bodies),1);
    initValue = [];
    bodyIds = [];
    for(i=1:length(bodies))
        S{i,1} = celBodyData.(bodies{i}).name;
        
        bodyId = celBodyData.(bodies{i}).id;
        bodyIds(end+1) = bodyId; %#ok<AGROW>
        if(~ismember(bodyId,soiSkipIds))
            initValue(end+1) = i; %#ok<AGROW>
        end
    end
   
    promptStr = {'Select which bodies you would','like this coast to consider when','computing downward SoI','transitions.'};
    
    [select,ok] = listdlg('ListString',S,'Name','Selective SoI Search','PromptString',promptStr, 'InitialValue', initValue);
    
    bodyInds = 1:length(bodies);
    if(ok == 1)
        diff = setdiff(bodyInds,select);
        newSoiSkipIds = bodyIds(diff);
        setappdata(handles.ma_InsertCoastGUI,'soiSkipIds',newSoiSkipIds);
    end
   


% --- Executes on selection change in coastLineColorCombo.
function coastLineColorCombo_Callback(hObject, eventdata, handles)
% hObject    handle to coastLineColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns coastLineColorCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from coastLineColorCombo


% --- Executes during object creation, after setting all properties.
function coastLineColorCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to coastLineColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in massLossCheckbox.
function massLossCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to massLossCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of massLossCheckbox
    if(get(hObject,'Value')==1)
        set(handles.editLossConvertButton,'Enable','on');
    else
        set(handles.editLossConvertButton,'Enable','off');
    end


% --- Executes on button press in editLossConvertButton.
function editLossConvertButton_Callback(hObject, eventdata, handles)
% hObject    handle to editLossConvertButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    event = get(handles.ma_InsertCoastGUI,'UserData');
    eventLossConvert = getappdata(handles.ma_InsertCoastGUI,'lossConverts');
    if(~isempty(event) && isstruct(eventLossConvert) && ~isequal(eventLossConvert, getDefaultLossConvert(handles)))
        lossConverts = ma_MassLossesConversionsGUI(handles.ma_MainGUI, eventLossConvert);
    else
        lossConverts = ma_MassLossesConversionsGUI(handles.ma_MainGUI);
    end
    
    if(~isempty(lossConverts))
        setappdata(handles.ma_InsertCoastGUI,'lossConverts',lossConverts);
    end
    
    setEditLossConvertButtonTooltipString(handles);
    
function setEditLossConvertButtonTooltipString(handles)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    names = maData.spacecraft.propellant.names;
    
	lossConverts = getappdata(handles.ma_InsertCoastGUI,'lossConverts');
    if(~isempty(lossConverts))
        maxNumRes = max(horzcat(lossConverts.resLost, lossConverts.resConvert));
        resRates = zeros(1,maxNumRes);
        
        for(i=1:length(lossConverts)) %#ok<*NO4LP>
            lossConvert = lossConverts(i);
            resRates(lossConvert.resLost) = resRates(lossConvert.resLost) - lossConvert.resLostRates(lossConvert.resLost);
            
            sumRates = sum(lossConvert.resLostRates);
            resRates(lossConvert.resConvert) = resRates(lossConvert.resConvert) + sumRates*lossConvert.resConvertPercent(lossConvert.resConvert);
        end
        
        str = 'Right Click for Copy/Paste\n\nTotal Resource Losses & Conversions\n-----------------------\n';
        for(i=1:length(resRates))           
            str = [str, ...
                   sprintf('%s: %1.6f mT/Hr\n', names{i}, resRates(i)*3600)];
        end
        

    else
        str = 'Right Click for Copy/Paste\n\nTotal Resource Losses & Conversions\n-----------------------\nNone!';
    end

    str = sprintf(str);
    set(handles.editLossConvertButton,'TooltipStr',str);


% --------------------------------------------------------------------
function copyLossConvertMenu_Callback(hObject, eventdata, handles)
% hObject    handle to copyLossConvertMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lossConverts = getappdata(handles.ma_InsertCoastGUI,'lossConverts');
    copyLossConvertToClipboard(lossConverts);

% --------------------------------------------------------------------
function pasteLossConvertMenu_Callback(hObject, eventdata, handles)
% hObject    handle to pasteLossConvertMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    pasteLossConvertFromClipboard(handles.ma_InsertCoastGUI);
    setEditLossConvertButtonTooltipString(handles);


% --- Executes on selection change in customFuncFuncCombo.
function customFuncFuncCombo_Callback(hObject, eventdata, handles)
% hObject    handle to customFuncFuncCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns customFuncFuncCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from customFuncFuncCombo
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');

    contents = cellstr(get(hObject,'String'));
    selStr = contents{get(hObject,'Value')};
    
    propNames = maData.spacecraft.propellant.names;
    
    hRefBodyCombo = handles.customFuncRefCelBodyCombo;
    contents = cellstr(get(hRefBodyCombo,'String'));
    refBodyStr = contents{get(hRefBodyCombo,'Value')};
    refBodyInfo = celBodyData.(strtrim(lower(refBodyStr)));
    refBodyId = refBodyInfo.id;
    
    [~, depVarUnit, ~] = ma_getDepVarValueUnit(1, maData.stateLog, selStr, 0, refBodyId, [], [], propNames, maData, celBodyData, false);

%     set(handles.coastValueTypeLabel,'String',selStr);
    set(handles.coastValueTypeLabel,'TooltipString',selStr);
    set(handles.customFuncFuncCombo,'TooltipString',selStr);
    set(handles.unitsLabel,'String',depVarUnit);

% --- Executes during object creation, after setting all properties.
function customFuncFuncCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to customFuncFuncCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in customFuncRefCelBodyCombo.
function customFuncRefCelBodyCombo_Callback(hObject, eventdata, handles)
% hObject    handle to customFuncRefCelBodyCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns customFuncRefCelBodyCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from customFuncRefCelBodyCombo


% --- Executes during object creation, after setting all properties.
function customFuncRefCelBodyCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to customFuncRefCelBodyCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in customFuncRefSpacecraftCombo.
function customFuncRefSpacecraftCombo_Callback(hObject, eventdata, handles)
% hObject    handle to customFuncRefSpacecraftCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns customFuncRefSpacecraftCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from customFuncRefSpacecraftCombo


% --- Executes during object creation, after setting all properties.
function customFuncRefSpacecraftCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to customFuncRefSpacecraftCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in customFuncRefGrdStnCombo.
function customFuncRefGrdStnCombo_Callback(hObject, eventdata, handles)
% hObject    handle to customFuncRefGrdStnCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns customFuncRefGrdStnCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from customFuncRefGrdStnCombo


% --- Executes during object creation, after setting all properties.
function customFuncRefGrdStnCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to customFuncRefGrdStnCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function customFuncMaxPropTimeText_Callback(hObject, eventdata, handles)
% hObject    handle to customFuncMaxPropTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of customFuncMaxPropTimeText as text
%        str2double(get(hObject,'String')) returns contents of customFuncMaxPropTimeText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function customFuncMaxPropTimeText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to customFuncMaxPropTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in coastLineStyleCombo.
function coastLineStyleCombo_Callback(hObject, eventdata, handles)
% hObject    handle to coastLineStyleCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns coastLineStyleCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from coastLineStyleCombo


% --- Executes during object creation, after setting all properties.
function coastLineStyleCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to coastLineStyleCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in orbitDecayCheckbox.
function orbitDecayCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to orbitDecayCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of orbitDecayCheckbox
    if(get(hObject,'Value'))
        set(handles.scAreaText,'Enable','on');
        set(handles.solarFluxText,'Enable','on');
        set(handles.geomagneticIndText,'Enable','on');
    else
        set(handles.scAreaText,'Enable','off');
        set(handles.solarFluxText,'Enable','off');
        set(handles.geomagneticIndText,'Enable','off');
    end


function scAreaText_Callback(hObject, eventdata, handles)
% hObject    handle to scAreaText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of scAreaText as text
%        str2double(get(hObject,'String')) returns contents of scAreaText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function scAreaText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scAreaText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function solarFluxText_Callback(hObject, eventdata, handles)
% hObject    handle to solarFluxText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of solarFluxText as text
%        str2double(get(hObject,'String')) returns contents of solarFluxText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function solarFluxText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to solarFluxText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function geomagneticIndText_Callback(hObject, eventdata, handles)
% hObject    handle to geomagneticIndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of geomagneticIndText as text
%        str2double(get(hObject,'String')) returns contents of geomagneticIndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function geomagneticIndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to geomagneticIndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in lineWidthCombo.
function lineWidthCombo_Callback(hObject, eventdata, handles)
% hObject    handle to lineWidthCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lineWidthCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lineWidthCombo


% --- Executes during object creation, after setting all properties.
function lineWidthCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lineWidthCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
