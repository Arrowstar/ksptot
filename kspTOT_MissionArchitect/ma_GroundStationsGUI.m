function varargout = ma_GroundStationsGUI(varargin)
% MA_GROUNDSTATIONSGUI MATLAB code for ma_GroundStationsGUI.fig
%      MA_GROUNDSTATIONSGUI, by itself, creates a new MA_GROUNDSTATIONSGUI or raises the existing
%      singleton*.
%
%      H = MA_GROUNDSTATIONSGUI returns the handle to a new MA_GROUNDSTATIONSGUI or the handle to
%      the existing singleton*.
%
%      MA_GROUNDSTATIONSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_GROUNDSTATIONSGUI.M with the given input arguments.
%
%      MA_GROUNDSTATIONSGUI('Property','Value',...) creates a new MA_GROUNDSTATIONSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_GroundStationsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_GroundStationsGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_GroundStationsGUI

% Last Modified by GUIDE v2.5 19-Feb-2020 20:28:26

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_GroundStationsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_GroundStationsGUI_OutputFcn, ...
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


% --- Executes just before ma_GroundStationsGUI is made visible.
function ma_GroundStationsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_GroundStationsGUI (see VARARGIN)

% Choose default command line output for ma_GroundStationsGUI
handles.output = hObject;
handles.ma_MainGUI = varargin{1};

populateBodiesCombo(getappdata(handles.ma_MainGUI,'celBodyData'), handles.centralBodyCombo);
bodyComboValue = findValueFromComboBox('Kerbin', handles.centralBodyCombo);
if(isempty(bodyComboValue))
    bodyComboValue = 1;
end
set(handles.centralBodyCombo,'Value',bodyComboValue);

setupGUI(handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ma_GroundStationsGUI wait for user response (see UIRESUME)
% uiwait(handles.ma_GroundStationsGUI);


function setupGUI(handles)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    
    if(~isfield(maData.spacecraft,'stations'))
        maData.spacecraft.stations = cell(0,1);
        setappdata(handles.ma_MainGUI,'ma_data',maData);
    end
    
    if(isempty(maData.spacecraft.stations))
        set(handles.stnListbox,'String','');
    else
        stnValue = get(handles.stnListbox,'Value');
        stn = maData.spacecraft.stations{stnValue};
        
        populateStation(handles,stn);
        updateSTNListbox(handles);
        stnListbox_Callback(handles.stnListbox, [], handles);
    end
    
    
function populateStation(handles,stn)
    set(handles.stnNameText,'String',stn.name);

    set(handles.longText,'String',fullAccNum2Str(rad2deg(stn.long)));
    set(handles.latText,'String',fullAccNum2Str(rad2deg(stn.lat)));
    set(handles.altText,'String',fullAccNum2Str(stn.alt));
    set(handles.maxCommRangeText,'String',fullAccNum2Str(stn.maxCommRange));

    bodyComboValue = findValueFromComboBox(stn.parent, handles.centralBodyCombo);
    if(isempty(bodyComboValue))
        bodyComboValue = 1;
    end
    set(handles.centralBodyCombo,'Value',bodyComboValue);
    
    colorComboStr = getStringFromLineSpecColor(stn.color); 
	value = findValueFromComboBox(colorComboStr, handles.grndStnColor);
    set(handles.grndStnColor,'Value',value);
    
    markerComboValue = findValueFromComboBox(stn.markerSymbol, handles.animatorMarkerSymbolCombo);
    if(isempty(markerComboValue))
        markerComboValue = 1;
    end
    set(handles.animatorMarkerSymbolCombo,'Value',markerComboValue); 


% --- Outputs from this function are returned to the command line.
function varargout = ma_GroundStationsGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in stnListbox.
function stnListbox_Callback(hObject, eventdata, handles)
% hObject    handle to stnListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns stnListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from stnListbox
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    stns = maData.spacecraft.stations;
    stnValue = get(handles.stnListbox,'Value');
    
    if(~isempty(stns) && ~isempty(stnValue))
        Stn = stns{stnValue};
        populateStation(handles,Stn);
    end

% --- Executes during object creation, after setting all properties.
function stnListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stnListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in updateStnButton.
function updateStnButton_Callback(hObject, eventdata, handles)
% hObject    handle to updateStnButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    if(~isempty(errMsg))
        msgbox(errMsg,'Errors were found while updating a station.','error');
        return;
    end

    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    
    if(isempty(get(handles.stnListbox,'String')))
        return;
    end
    stnLBValue = get(handles.stnListbox,'Value');
    
    oldStn = maData.spacecraft.stations{stnLBValue};
    oldID = oldStn.id;
        
    contents = cellstr(get(handles.grndStnColor,'String'));
    stnColorStr = contents{get(handles.grndStnColor,'Value')};    
    stnColor = getLineSpecColorFromString(stnColorStr);    
    
    Stn = struct();
    
    Stn.name = get(handles.stnNameText,'String');
    
    Stn.long = deg2rad(str2double(get(handles.longText,'String')));
    Stn.lat = deg2rad(str2double(get(handles.latText,'String')));
    Stn.alt = str2double(get(handles.altText,'String'));
    Stn.maxCommRange = str2double(get(handles.maxCommRangeText,'String'));

    contents = cellstr(get(handles.centralBodyCombo,'String'));
    cbName = strtrim(contents{get(handles.centralBodyCombo,'Value')});
    bodyInfo = celBodyData.(strtrim(lower(cbName)));
    Stn.parent = cbName;
    Stn.parentID = bodyInfo.id;
    
    Stn.id = oldID;
    Stn.color = stnColor;
    
    contents = cellstr(get(handles.animatorMarkerSymbolCombo,'String'));
    markerName = strtrim(contents{get(handles.animatorMarkerSymbolCombo,'Value')});
    Stn.markerSymbol = markerName;
    
    maData.spacecraft.stations{stnLBValue} = Stn;
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    
    updateSTNListbox(handles);
    
    

% --- Executes on button press in addStnButton.
function addStnButton_Callback(hObject, eventdata, handles)
% hObject    handle to addStnButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    
    stnColor = 'r';
    
    Stn = struct();
    
    Stn.name = 'New Ground Station';
    
    Stn.long = 0.0;
    Stn.lat = 0.0;
    Stn.alt = 0.0;
    Stn.maxCommRange = Inf;
    
    contents = cellstr(get(handles.centralBodyCombo,'String'));
    cbName = contents{1};
    bodyInfo = celBodyData.(strtrim(lower(cbName)));
    Stn.parent = cbName;
    Stn.parentID = bodyInfo.id;

    Stn.id = rand();
    Stn.color = stnColor;
    Stn.linestyle = '-';
    Stn.lineWidth = 0.5;
    Stn.markerSymbol = 's';
    
    maData.spacecraft.stations{end+1} = Stn;
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    
    updateSTNListbox(handles);
    set(handles.stnListbox,'Value',length(maData.spacecraft.stations));
    stnListbox_Callback(handles.stnListbox, [], handles);
    
    
function updateSTNListbox(handles)
	maData = getappdata(handles.ma_MainGUI,'ma_data');
    
    stns = maData.spacecraft.stations;
    stnStr = cell(0,1);
    for(i=1:length(stns)) %#ok<*NO4LP>
        stnStr{end+1} = stns{i}.name; %#ok<AGROW>
    end
    
	if(isempty(get(handles.stnListbox,'Value')))
        set(handles.stnListbox,'Value',1);
    elseif(get(handles.stnListbox,'Value') > length(stns))
        set(handles.stnListbox,'Value',length(stns));
    elseif(get(handles.stnListbox,'Value') == 0 && ~isempty(stns))
        set(handles.stnListbox,'Value',1);
	end
    
    set(handles.stnListbox,'String',stnStr);
    
% --- Executes on button press in removeSCButton.
function removeSCButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeSCButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    stnValue = get(handles.stnListbox,'Value');
    
    Stn = maData.spacecraft.stations;
    Stn(stnValue) = [];
    maData.spacecraft.stations = Stn;
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    
    updateSTNListbox(handles);
    stnListbox_Callback(handles.stnListbox, [], handles);
    

function stnNameText_Callback(hObject, eventdata, handles)
% hObject    handle to stnNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of stnNameText as text
%        str2double(get(hObject,'String')) returns contents of stnNameText as a double
    updateStnButton_Callback([], [], handles);

% --- Executes during object creation, after setting all properties.
function stnNameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stnNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in centralBodyCombo.
function centralBodyCombo_Callback(hObject, eventdata, handles)
% hObject    handle to centralBodyCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns centralBodyCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from centralBodyCombo
    updateStnButton_Callback([], [], handles);

% --- Executes during object creation, after setting all properties.
function centralBodyCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to centralBodyCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function longText_Callback(hObject, eventdata, handles)
% hObject    handle to longText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of longText as text
%        str2double(get(hObject,'String')) returns contents of longText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

    updateStnButton_Callback([], [], handles);

% --- Executes during object creation, after setting all properties.
function longText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to longText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function latText_Callback(hObject, eventdata, handles)
% hObject    handle to latText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of latText as text
%        str2double(get(hObject,'String')) returns contents of latText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

    updateStnButton_Callback([], [], handles);

% --- Executes during object creation, after setting all properties.
function latText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to latText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function altText_Callback(hObject, eventdata, handles)
% hObject    handle to altText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of altText as text
%        str2double(get(hObject,'String')) returns contents of altText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

    updateStnButton_Callback([], [], handles);

% --- Executes during object creation, after setting all properties.
function altText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to altText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function truText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to truText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function errMsg = validateInputs(handles)
    errMsg = {};
    
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    contents = cellstr(get(handles.centralBodyCombo,'String'));
    cbName = strtrim(contents{get(handles.centralBodyCombo,'Value')});
    bodyInfo = celBodyData.(strtrim(lower(cbName)));

    value = str2double(get(handles.longText,'String'));
    enteredStr = get(handles.longText,'String');
    numberName = 'Station East Longitude';
    lb = 0;
    ub = 360;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    value = str2double(get(handles.latText,'String'));
    enteredStr = get(handles.latText,'String');
    numberName = 'Station North Latitude';
    lb = -90;
    ub = 90;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    value = str2double(get(handles.altText,'String'));
    enteredStr = get(handles.altText,'String');
    numberName = 'Station Altitude';
    lb = -bodyInfo.radius;
    ub = 10000;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    maxCommRange = str2double(get(handles.maxCommRangeText,'String'));
    enteredStr = get(handles.maxCommRangeText,'String');
    numberName = 'Max Comm. Range';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(maxCommRange, numberName, lb, ub, isInt, errMsg, enteredStr);

% --- Executes on selection change in grndStnColor.
function grndStnColor_Callback(hObject, eventdata, handles)
% hObject    handle to grndStnColor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns grndStnColor contents as cell array
%        contents{get(hObject,'Value')} returns selected item from grndStnColor
    updateStnButton_Callback([], [], handles);

% --- Executes during object creation, after setting all properties.
function grndStnColor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to grndStnColor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on ma_GroundStationsGUI or any of its controls.
function ma_GroundStationsGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to ma_GroundStationsGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'escape'
            close(handles.ma_GroundStationsGUI);
    end


function maxCommRangeText_Callback(hObject, eventdata, handles)
% hObject    handle to maxCommRangeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxCommRangeText as text
%        str2double(get(hObject,'String')) returns contents of maxCommRangeText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

    updateStnButton_Callback([], [], handles);

% --- Executes during object creation, after setting all properties.
function maxCommRangeText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxCommRangeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in animatorMarkerSymbolCombo.
function animatorMarkerSymbolCombo_Callback(hObject, eventdata, handles)
% hObject    handle to animatorMarkerSymbolCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns animatorMarkerSymbolCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from animatorMarkerSymbolCombo
    updateStnButton_Callback([], [], handles);

% --- Executes during object creation, after setting all properties.
function animatorMarkerSymbolCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to animatorMarkerSymbolCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
