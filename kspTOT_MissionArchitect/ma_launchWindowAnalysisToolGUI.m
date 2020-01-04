function varargout = ma_launchWindowAnalysisToolGUI(varargin)
% MA_LAUNCHWINDOWANALYSISTOOLGUI MATLAB code for ma_launchWindowAnalysisToolGUI.fig
%      MA_LAUNCHWINDOWANALYSISTOOLGUI, by itself, creates a new MA_LAUNCHWINDOWANALYSISTOOLGUI or raises the existing
%      singleton*.
%
%      H = MA_LAUNCHWINDOWANALYSISTOOLGUI returns the handle to a new MA_LAUNCHWINDOWANALYSISTOOLGUI or the handle to
%      the existing singleton*.
%
%      MA_LAUNCHWINDOWANALYSISTOOLGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_LAUNCHWINDOWANALYSISTOOLGUI.M with the given input arguments.
%
%      MA_LAUNCHWINDOWANALYSISTOOLGUI('Property','Value',...) creates a new MA_LAUNCHWINDOWANALYSISTOOLGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_launchWindowAnalysisToolGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_launchWindowAnalysisToolGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_launchWindowAnalysisToolGUI

% Last Modified by GUIDE v2.5 22-Apr-2015 16:50:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_launchWindowAnalysisToolGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_launchWindowAnalysisToolGUI_OutputFcn, ...
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


% --- Executes just before ma_launchWindowAnalysisToolGUI is made visible.
function ma_launchWindowAnalysisToolGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_launchWindowAnalysisToolGUI (see VARARGIN)

% Choose default command line output for ma_launchWindowAnalysisToolGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
handles.ma_MainGUI = varargin{1};
guidata(hObject, handles);

%GUI setup
populateBodiesCombo(getappdata(handles.ma_MainGUI,'celBodyData'), handles.centralBodyCombo);
value = findValueFromComboBox('Kerbin', handles.centralBodyCombo);
if(~isempty(value))
    set(handles.centralBodyCombo,'Value',value);
end

populateStationsCombo(handles, handles.groundSiteCombo);
value = findValueFromComboBox('KSC', handles.groundSiteCombo);
if(~isempty(value))
    set(handles.groundSiteCombo,'Value',value);
end
groundSiteCombo_Callback(handles.groundSiteCombo, [], handles);

% UIWAIT makes ma_launchWindowAnalysisToolGUI wait for user response (see UIRESUME)
% uiwait(handles.ma_launchWindowAnalysisToolGUI);


% --- Outputs from this function are returned to the command line.
function varargout = ma_launchWindowAnalysisToolGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function launchWindowTableText_Callback(hObject, eventdata, handles)
% hObject    handle to launchWindowTableText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchWindowTableText as text
%        str2double(get(hObject,'String')) returns contents of launchWindowTableText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function launchWindowTableText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchWindowTableText (see GCBO)
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
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

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



function targetIncText_Callback(hObject, eventdata, handles)
% hObject    handle to targetIncText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of targetIncText as text
%        str2double(get(hObject,'String')) returns contents of targetIncText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function targetIncText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to targetIncText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function targetRAANText_Callback(hObject, eventdata, handles)
% hObject    handle to targetRAANText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of targetRAANText as text
%        str2double(get(hObject,'String')) returns contents of targetRAANText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function targetRAANText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to targetRAANText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function launchSiteLongText_Callback(hObject, eventdata, handles)
% hObject    handle to launchSiteLongText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchSiteLongText as text
%        str2double(get(hObject,'String')) returns contents of launchSiteLongText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function launchSiteLongText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchSiteLongText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function launchSiteLatText_Callback(hObject, eventdata, handles)
% hObject    handle to launchSiteLatText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchSiteLatText as text
%        str2double(get(hObject,'String')) returns contents of launchSiteLatText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function launchSiteLatText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchSiteLatText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in startLaunchWindowAnalysisButton.
function startLaunchWindowAnalysisButton_Callback(hObject, eventdata, handles)
% hObject    handle to startLaunchWindowAnalysisButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    if(isempty(errMsg))
        celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
        contents = cellstr(get(handles.centralBodyCombo,'String'));
        sel = strtrim(lower(contents{get(handles.centralBodyCombo,'Value')}));
        bodyInfo = celBodyData.(sel);

        launchLong = deg2rad(str2double(get(handles.launchSiteLongText,'String')));
        launchLat  = deg2rad(str2double(get(handles.launchSiteLatText,'String')));
        targetInc  = deg2rad(str2double(get(handles.targetIncText,'String')));
        targetRAAN = deg2rad(str2double(get(handles.targetRAANText,'String')));
        windowSearchStartUT = str2double(get(handles.windowStartUTText,'String'));
        numWindows = str2double(get(handles.numRevsText,'String'));

        [x1, x2, fval1, fval2, beta1, beta2] = computeLaunchWindows(bodyInfo, launchLong, launchLat, targetInc, targetRAAN, windowSearchStartUT);
        lwString = createLaunchWindowTable(x1, x2, fval1, fval2, beta1, beta2, bodyInfo, numWindows);
        set(handles.launchWindowTableText,'String',lwString);
    else
        msgbox(errMsg,'Errors were found while inserting an aerobrake.','error');
    end    

function errMsg = validateInputs(handles)
    errMsg = {};

    value = str2double(get(handles.launchSiteLongText,'String'));
    enteredStr = get(handles.launchSiteLongText,'String');
    numberName = 'Launch Site Longitude';
    lb = 0;
    ub = 360;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);

    value = str2double(get(handles.launchSiteLatText,'String'));
    enteredStr = get(handles.launchSiteLatText,'String');
    numberName = 'Launch Site Latitude';
    lb = -90;
    ub = 90;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    value = str2double(get(handles.targetIncText,'String'));
    enteredStr = get(handles.targetIncText,'String');
    numberName = 'Target Inclination';
    lb = 0;
    ub = 180;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    value = str2double(get(handles.targetRAANText,'String'));
    enteredStr = get(handles.targetRAANText,'String');
    numberName = 'Target RAAN';
    lb = 0;
    ub = 360;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);

    value = str2double(get(handles.windowStartUTText,'String'));
    enteredStr = get(handles.windowStartUTText,'String');
    numberName = 'Window Search Start';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);

    value = str2double(get(handles.numRevsText,'String'));
    enteredStr = get(handles.numRevsText,'String');
    numberName = 'Number of Revolutions';
    lb = 1;
    ub = Inf;
    isInt = true;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
        
    lat = str2double(get(handles.launchSiteLatText,'String'));
    inc = str2double(get(handles.targetIncText,'String'));
    
    if(lat==0.0 && inc==0.0)
        errMsg{end+1} = 'Both the target inclination and the launch site latitude may not not be zero (just launch eastward!).';
    end

function windowStartUTText_Callback(hObject, eventdata, handles)
% hObject    handle to windowStartUTText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of windowStartUTText as text
%        str2double(get(hObject,'String')) returns contents of windowStartUTText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function windowStartUTText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to windowStartUTText (see GCBO)
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


% --------------------------------------------------------------------
function enterUTAsDateTime_Callback(hObject, eventdata, handles)
% hObject    handle to enterUTAsDateTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
secUT = enterUTAsDateTimeGUI(str2double(get(gco, 'String')));
if(secUT >= 0)
    set(gco, 'String', num2str(secUT));
end

% --------------------------------------------------------------------
function getUTFromKSP_Callback(hObject, eventdata, handles)
% hObject    handle to getUTFromKSP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
secUT = readDoublesFromKSPTOTConnect('GetUT', '', true);
if(secUT >= 0)
    set(gco, 'String', num2str(secUT));
end


% --- Executes on selection change in groundSiteCombo.
function groundSiteCombo_Callback(hObject, eventdata, handles)
% hObject    handle to groundSiteCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns groundSiteCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from groundSiteCombo
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    sel = get(hObject,'Value');
    
    stations = maData.spacecraft.stations;
    if(length(stations) >= sel)
        station = stations{sel};
        set(handles.launchSiteLongText,'String', strtrim(sprintf('%8.4f',rad2deg(station.long))));
        set(handles.launchSiteLatText,'String', strtrim(sprintf('%8.4f',rad2deg(station.lat))));
    end
    
    
% --- Executes during object creation, after setting all properties.
function groundSiteCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to groundSiteCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on ma_launchWindowAnalysisToolGUI or any of its controls.
function ma_launchWindowAnalysisToolGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to ma_launchWindowAnalysisToolGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'escape'
            close(handles.ma_launchWindowAnalysisToolGUI);
    end