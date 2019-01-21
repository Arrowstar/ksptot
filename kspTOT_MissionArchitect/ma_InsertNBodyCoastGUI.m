function varargout = ma_InsertNBodyCoastGUI(varargin)
% MA_INSERTNBODYCOASTGUI MATLAB code for ma_InsertNBodyCoastGUI.fig
%      MA_INSERTNBODYCOASTGUI, by itself, creates a new MA_INSERTNBODYCOASTGUI or raises the existing
%      singleton*.
%
%      H = MA_INSERTNBODYCOASTGUI returns the handle to a new MA_INSERTNBODYCOASTGUI or the handle to
%      the existing singleton*.
%
%      MA_INSERTNBODYCOASTGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_INSERTNBODYCOASTGUI.M with the given input arguments.
%
%      MA_INSERTNBODYCOASTGUI('Property','Value',...) creates a new MA_INSERTNBODYCOASTGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_InsertNBodyCoastGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_InsertNBodyCoastGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_InsertNBodyCoastGUI

% Last Modified by GUIDE v2.5 20-Jan-2019 16:39:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_InsertNBodyCoastGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_InsertNBodyCoastGUI_OutputFcn, ...
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


% --- Executes just before ma_InsertNBodyCoastGUI is made visible.
function ma_InsertNBodyCoastGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_InsertNBodyCoastGUI (see VARARGIN)

% Choose default command line output for ma_InsertNBodyCoastGUI
global use_selective_soi_search;

handles.output = hObject;
handles.ma_MainGUI = varargin{1};

% Update handles structure
guidata(hObject, handles);

% Setup GUI
% substituteDefaultPropNamesWithCustomNamesListbox(handles);
populateBodiesCombo(getappdata(handles.ma_MainGUI,'celBodyData'), handles.bodiesCombo, true);
if(length(varargin)>1) 
    event = varargin{2};
    setappdata(hObject,'lossConverts',event.massloss.lossConvert);
    setappdata(hObject,'gravModelBodyIds',event.forceModel.gravModelBodyIds);
    populateGUIWithEvent(handles, event);
    set(hObject,'UserData',event);
else
    set(hObject,'UserData',[]);
    setappdata(hObject,'soiSkipIds',[]);
    setappdata(hObject,'gravModelBodyIds',getAllBodyIds(getappdata(handles.ma_MainGUI,'celBodyData')));
    setappdata(hObject,'lossConverts',getDefaultLossConvert(handles));
end
coastTypeCombo_Callback(handles.coastTypeCombo, [], handles);
optVar1ChkBox_Callback(handles.optVar1ChkBox, [], handles);
setEditLossConvertButtonTooltipString(handles);

if(use_selective_soi_search)
    set(handles.selectiveSearchActiveLabel,'String','Active','ForegroundColor',[34,139,34]/255);
else
    set(handles.selectiveSearchActiveLabel,'String','Inactive','ForegroundColor',[0.847,0.161,0]);
end

% UIWAIT makes ma_InsertNBodyCoastGUI wait for user response (see UIRESUME)
uiwait(handles.ma_InsertNBodyCoastGUI);

function bodyIds = getAllBodyIds(celBodyData)
	bodies = fields(celBodyData);
    bodyIds = [];
    for(i=1:length(bodies))
        bodyIds(end+1) = celBodyData.(bodies{i}).id; %#ok<AGROW>
    end

function populateGUIWithEvent(handles, event)
    set(handles.titleLabel, 'String', 'Edit N-Body Coast');
    set(handles.ma_InsertNBodyCoastGUI, 'Name', 'Edit N-Body Coast');
    set(handles.coastNameText, 'String', event.name);
    set(handles.numRevsText, 'String', num2str(event.revs));
    set(handles.maxPropTimeText, 'String', num2str(event.maxPropTime));
    
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
    end
    typeValue = findValueFromComboBox(coastType, handles.coastTypeCombo);
    set(handles.coastTypeCombo,'value',typeValue);

    colorStr = getStringFromLineSpecColor(event.lineColor);
    colorValue = findValueFromComboBox(colorStr, handles.coastLineColorCombo);
    set(handles.coastLineColorCombo,'value',colorValue);
    
    styleStr = getLineStyleFromString(event.lineStyle);
    styleValue = findValueFromComboBox(styleStr, handles.nBodyCoastLineStyleCombo);
 	set(handles.nBodyCoastLineStyleCombo,'Value',styleValue);
    
    contents = handles.lineWidthCombo.String;
    contentsDouble = str2double(contents);
    ind = find(contentsDouble == event.lineWidth);
    set(handles.lineWidthCombo,'Value',ind);
    
    set(handles.massLossCheckbox,'Value',event.massloss.use);
    massLossCheckbox_Callback(handles.massLossCheckbox, [], handles);
    
    set(handles.coastValueText, 'String', fullAccNum2Str(value));
    setappdata(handles.ma_InsertNBodyCoastGUI,'soiSkipIds',event.soiSkipIds);

	setappdata(handles.ma_InsertNBodyCoastGUI,'soiSkipIds',event.forceModel.gravModelBodyIds);

% --- Outputs from this function are returned to the command line.
function varargout = ma_InsertNBodyCoastGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if(isempty(handles))
    varargout{1} = [];
else
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
    
    contents = cellstr(get(handles.nBodyCoastLineStyleCombo,'String'));
    lineStyleStr = contents{get(handles.nBodyCoastLineStyleCombo,'Value')};
    lineStyle = getLineStyleStrFromText(lineStyleStr);
    
    contents = handles.lineWidthCombo.String;
    contentsDouble = str2double(contents);
    contensInd = get(handles.lineWidthCombo,'Value');
    lineWidth = contentsDouble(contensInd);
    
    soiSkipIds = getappdata(hObject,'soiSkipIds');    
    
    massloss = struct('use',logical(get(handles.massLossCheckbox,'Value')), 'lossConvert',getappdata(handles.ma_InsertNBodyCoastGUI,'lossConverts'));
    
    forceModel = struct();
    forceModel.gravModelBodyIds = getappdata(handles.ma_InsertNBodyCoastGUI,'gravModelBodyIds');
    
    maxPropTime = str2double(get(handles.maxPropTimeText,'string'));
    
    varargout{1} = ma_createNBodyCoast(name, coastType, value, revs, bodyInfo, vars, soiSkipIds, lineSpecColor, lineStyle, lineWidth, massloss, forceModel, maxPropTime);
    close(handles.ma_InsertNBodyCoastGUI);
end

% --------------------------------------------------------------------
function enterUTAsDateTime_Callback(~, ~)
    secUT = enterUTAsDateTimeGUI(str2double(get(gco, 'String')));
    if(secUT >= 0)
        set(gco, 'String', num2str(secUT));
    end
    
    
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
        otherwise
            errMsg{end+1} = 'Coast type not recongized during input validation.';
            return;
    end


% --- Executes on button press in saveCloseButton.
function saveCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);

    if(isempty(errMsg))
        uiresume(handles.ma_InsertNBodyCoastGUI);
    else
        msgbox(errMsg,'Errors were found while inserting a coast.','error');
    end  

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.ma_InsertNBodyCoastGUI);


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
event = get(handles.ma_InsertNBodyCoastGUI,'UserData');

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
        
        if(~isempty(eventNum))
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
        
    case 'Go to Delta Time'
        set(typeLabel,'String','Delta Time');
        set(unitsLabel,'String','sec');
        set(editLabel,'Enable','on');
        set(handles.numRevsText, 'Enable','on');
        set(handles.optVar1ChkBox,'Enable','on');
        set(handles.optVar1LwrText,'Enable','on');
        set(handles.optVar1UprText,'Enable','on');
        
        if(~isempty(eventNum))
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
    case 'Go to True Anomaly'
        set(typeLabel,'String','True Anomaly');
        set(unitsLabel,'String','deg');
        set(editLabel,'Enable','on');
        set(handles.numRevsText, 'Enable','on');
        set(handles.optVar1ChkBox,'Enable','on');
        set(handles.optVar1LwrText,'Enable','on');
        set(handles.optVar1UprText,'Enable','on');
        
        if(~isempty(eventNum))
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


% --- Executes on button press in selectiveSoISearchButton.
function selectiveSoISearchButton_Callback(hObject, eventdata, handles)
% hObject    handle to selectiveSoISearchButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    event = get(handles.ma_InsertNBodyCoastGUI,'UserData');
    
    if(~isempty(event))
        soiSkipIds = getappdata(handles.ma_InsertNBodyCoastGUI,'soiSkipIds');
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
        setappdata(handles.ma_InsertNBodyCoastGUI,'soiSkipIds',newSoiSkipIds);
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
    event = get(handles.ma_InsertNBodyCoastGUI,'UserData');
    eventLossConvert = getappdata(handles.ma_InsertNBodyCoastGUI,'lossConverts');
    if(~isempty(event) && isstruct(eventLossConvert) && ~isequal(eventLossConvert, getDefaultLossConvert(handles)))
        lossConverts = ma_MassLossesConversionsGUI(handles.ma_MainGUI, eventLossConvert);
    else
        lossConverts = ma_MassLossesConversionsGUI(handles.ma_MainGUI);
    end
    
    if(~isempty(lossConverts))
        setappdata(handles.ma_InsertNBodyCoastGUI,'lossConverts',lossConverts);
    end
    
    setEditLossConvertButtonTooltipString(handles);
    
function setEditLossConvertButtonTooltipString(handles)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    names = maData.spacecraft.propellant.names;
    
	lossConverts = getappdata(handles.ma_InsertNBodyCoastGUI,'lossConverts');
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

% --- Executes on button press in defineForceModelButton.
function defineForceModelButton_Callback(hObject, eventdata, handles)
% hObject    handle to defineForceModelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    event = get(handles.ma_InsertNBodyCoastGUI,'UserData');
    
    if(~isempty(event))
        gravBodyIds = getappdata(handles.ma_InsertNBodyCoastGUI,'gravModelBodyIds');
    else
        gravBodyIds = getAllBodyIds(celBodyData);
    end
    
    bodies = fields(celBodyData);
    S = cell(0,1);
    initValue = [];
    bodyIds = [];
    for(i=1:length(bodies))
        if(strcmpi(celBodyData.(bodies{i}).name,'sun'))
            continue;
        end
        S{end+1,1} = celBodyData.(bodies{i}).name; %#ok<AGROW>
        
        bodyId = celBodyData.(bodies{i}).id;
        bodyIds(end+1) = bodyId; %#ok<AGROW>
        if(ismember(bodyId,gravBodyIds))
            initValue(end+1) = length(bodyIds); %#ok<AGROW>
        end
    end
   
    promptStr = {'Select which bodies you would','like this coast to consider when','computing gravitational','acceleration.','Note: The Sun is always','included.'};
    
    [select,ok] = listdlg('ListString',S,'Name','Define Gravity Model','PromptString',promptStr, 'InitialValue', initValue);
    
    if(ok == 1)
        newGravBodyIds = [];
        for(i=1:length(select))
            newGravBodyIds(end+1) = bodyIds(select(i)); %#ok<AGROW>
        end
        setappdata(handles.ma_InsertNBodyCoastGUI,'gravModelBodyIds',newGravBodyIds);
    end

% --- Executes on key press with focus on ma_InsertNBodyCoastGUI or any of its controls.
function ma_InsertNBodyCoastGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to ma_InsertNBodyCoastGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
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
            close(handles.ma_InsertNBodyCoastGUI);
    end


% --------------------------------------------------------------------
function copyLossConvertMenu_Callback(hObject, eventdata, handles)
% hObject    handle to copyLossConvertMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lossConverts = getappdata(handles.ma_InsertNBodyCoastGUI,'lossConverts');
    copyLossConvertToClipboard(lossConverts);

% --------------------------------------------------------------------
function pasteLossConvertMenu_Callback(hObject, eventdata, handles)
% hObject    handle to pasteLossConvertMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    pasteLossConvertFromClipboard(handles.ma_InsertNBodyCoastGUI);
    setEditLossConvertButtonTooltipString(handles);



function maxPropTimeText_Callback(hObject, eventdata, handles)
% hObject    handle to maxPropTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxPropTimeText as text
%        str2double(get(hObject,'String')) returns contents of maxPropTimeText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function maxPropTimeText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxPropTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in nBodyCoastLineStyleCombo.
function nBodyCoastLineStyleCombo_Callback(hObject, eventdata, handles)
% hObject    handle to nBodyCoastLineStyleCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns nBodyCoastLineStyleCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from nBodyCoastLineStyleCombo


% --- Executes during object creation, after setting all properties.
function nBodyCoastLineStyleCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nBodyCoastLineStyleCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
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
