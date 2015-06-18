function varargout = ma_InsertStateGUI(varargin)
% MA_INSERTSTATEGUI MATLAB code for ma_InsertStateGUI.fig
%      MA_INSERTSTATEGUI, by itself, creates a new MA_INSERTSTATEGUI or raises the existing
%      singleton*.
%
%      H = MA_INSERTSTATEGUI returns the handle to a new MA_INSERTSTATEGUI or the handle to
%      the existing singleton*.
%
%      MA_INSERTSTATEGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_INSERTSTATEGUI.M with the given input arguments.
%
%      MA_INSERTSTATEGUI('Property','Value',...) creates a new MA_INSERTSTATEGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_InsertStateGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_InsertStateGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_InsertStateGUI

% Last Modified by GUIDE v2.5 11-Jun-2015 20:50:49

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_InsertStateGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_InsertStateGUI_OutputFcn, ...
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


% --- Executes just before ma_InsertStateGUI is made visible.
function ma_InsertStateGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_InsertStateGUI (see VARARGIN)

% Choose default command line output for ma_InsertStateGUI
handles.output = hObject;
handles.ma_MainGUI = varargin{1};
handles.ksptotMainGUI = varargin{2};

% Update handles structure
guidata(hObject, handles);

%GUI setup
populateBodiesCombo(handles, handles.bodiesCombo);

if(length(varargin) > 2) 
    event = varargin{3};
    populateGUIWithEvent(handles, event);
end

% UIWAIT makes ma_InsertStateGUI wait for user response (see UIRESUME)
uiwait(handles.ma_InsertStateGUI);


function populateGUIWithEvent(handles, event)
    set(handles.titleLabel, 'String', 'Edit State');
    set(handles.ma_InsertStateGUI, 'Name', 'Edit State');
    set(handles.stateNameText, 'String', event.name);
    
    bodyValue = findValueFromComboBox(event.centralBody.name, handles.bodiesCombo);
    set(handles.bodiesCombo, 'value', bodyValue);
    
    set(handles.epochText, 'String', fullAccNum2Str(event.epoch));
    rVect = event.rVect;
    vVect = event.vVect;
    gmu = event.centralBody.gm;
    [sma, ecc, inc, raan, arg, tru] = getKeplerFromState(rVect,vVect,gmu);
    
    set(handles.smaText, 'String', fullAccNum2Str(sma));
    set(handles.eccText, 'String', fullAccNum2Str(ecc));
    set(handles.incText, 'String', fullAccNum2Str(rad2deg(inc)));
    set(handles.raanText, 'String', fullAccNum2Str(rad2deg(raan)));
    set(handles.argText, 'String', fullAccNum2Str(rad2deg(arg)));
    set(handles.truText, 'String', fullAccNum2Str(rad2deg(tru)));
    
    set(handles.dryMassText, 'String', fullAccNum2Str(event.dryMass));
    set(handles.fuelOxMassText, 'String', fullAccNum2Str(event.fuelOxMass));
    set(handles.monopropMassText, 'String', fullAccNum2Str(event.monoMass));
    set(handles.xenonMassText, 'String', fullAccNum2Str(event.xenonMass));

function populateBodiesCombo(handles, hBodiesCombo)
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    bodies = fields(celBodyData);
    
    bodiesStr = cell(length(bodies),1);
    for(i = 1:length(bodies)) %#ok<*NO4LP>
        body = bodies{i};
        bodiesStr{i} = celBodyData.(body).name;
    end
    
    set(hBodiesCombo, 'String', bodiesStr);
    if(length(bodiesStr) >= 5)
        set(hBodiesCombo, 'value', 5);
    elseif(length(bodiesStr) >= 1)
        set(hBodiesCombo, 'value', 1);
    end
    


% --- Outputs from this function are returned to the command line.
function varargout = ma_InsertStateGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if(isempty(handles))
    varargout{1} = [];
else
    name = get(handles.stateNameText, 'String');
    
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    contents = cellstr(get(handles.bodiesCombo,'String'));
    selected = contents{get(handles.bodiesCombo,'Value')};
    bodyInfo = celBodyData.(lower(selected));
    
    epoch = str2double(get(handles.epochText,'String'));
    sma = str2double(get(handles.smaText,'String'));
    ecc = str2double(get(handles.eccText,'String'));
    inc = deg2rad(str2double(get(handles.incText,'String')));
    raan = deg2rad(str2double(get(handles.raanText,'String')));
    arg = deg2rad(str2double(get(handles.argText,'String')));
    tru = deg2rad(str2double(get(handles.truText,'String')));
    
    if(ecc >= 1)
        parentBodyInfo = getParentBodyInfo(bodyInfo, celBodyData);
        rSOI = getSOIRadius(bodyInfo, parentBodyInfo);
        maxTru = computeTrueAFromRadiusEcc(rSOI - 1, sma, ecc);
        
        if(tru > maxTru)
            tru = maxTru;
        elseif(tru < -maxTru)
            tru = -maxTru;
        end
    end
    
    dryMass = str2double(get(handles.dryMassText,'String'));
    fuelOxMass = str2double(get(handles.fuelOxMassText,'String'));
    monoMass = str2double(get(handles.monopropMassText,'String'));
    xenonMass = str2double(get(handles.xenonMassText,'String'));
    
    varargout{1} = ma_createSetState(name, epoch, sma, ecc, inc, raan, arg, tru, bodyInfo, dryMass, fuelOxMass, monoMass, xenonMass);
    close(handles.ma_InsertStateGUI);
end


function errMsg = validateInputs(handles)
errMsg = {};

eEcc = str2double(get(handles.eccText,'String'));
enteredStr = get(handles.eccText,'String');
numberName = 'Orbit Eccentricity';
lb = 0;
ub = Inf;
isInt = false;
errMsg = validateNumber(eEcc, numberName, lb, ub, isInt, errMsg, enteredStr);

if(not(isempty(errMsg))) 
    msgbox(errMsg,'Errors were found while inserting a state.','error');
    return;
end

epoch = str2double(get(handles.epochText,'String'));
enteredStr = get(handles.epochText,'String');
numberName = 'Orbit Epoch';
lb = 0;
ub = Inf;
isInt = false;
errMsg = validateNumber(epoch, numberName, lb, ub, isInt, errMsg, enteredStr);

eSMA = str2double(get(handles.smaText,'String'));
enteredStr = get(handles.smaText,'String');
if(eEcc < 1.0)
    lb = 1;
    ub = Inf;
    numberName = 'Eccentric Orbit Semi-Major Axis';
else
    lb = -Inf;
    ub = -1;
    numberName = 'Hyperbolic Orbit Semi-Major Axis';
end
isInt = false;
errMsg = validateNumber(eSMA, numberName, lb, ub, isInt, errMsg, enteredStr);

eInc = str2double(get(handles.incText,'String'));
enteredStr = get(handles.incText,'String');
numberName = 'Orbit Inclination';
lb = 0;
ub = 180;
isInt = false;
errMsg = validateNumber(eInc, numberName, lb, ub, isInt, errMsg, enteredStr);

eRAAN = str2double(get(handles.raanText,'String'));
enteredStr = get(handles.raanText,'String');
numberName = 'Orbit RAAN';
lb = 0;
ub = 360;
isInt = false;
errMsg = validateNumber(eRAAN, numberName, lb, ub, isInt, errMsg, enteredStr);

eArg = str2double(get(handles.argText,'String'));
enteredStr = get(handles.argText,'String');
numberName = 'Orbit Argument of Periapse';
lb = 0;
ub = 360;
isInt = false;
errMsg = validateNumber(eArg, numberName, lb, ub, isInt, errMsg, enteredStr);

eTru = str2double(get(handles.truText,'String'));
enteredStr = get(handles.truText,'String');
numberName = 'Orbit True Anomaly';
lb = -180;
ub = 360;
isInt = false;
errMsg = validateNumber(eTru, numberName, lb, ub, isInt, errMsg, enteredStr);

dryMass = str2double(get(handles.dryMassText,'String'));
enteredStr = get(handles.dryMassText,'String');
numberName = 'Dry Mass';
lb = 0;
ub = Inf;
isInt = false;
errMsg = validateNumber(dryMass, numberName, lb, ub, isInt, errMsg, enteredStr);

fuelOxMass = str2double(get(handles.fuelOxMassText,'String'));
enteredStr = get(handles.fuelOxMassText,'String');
numberName = 'Fuel & Oxidizer Mass';
lb = 0;
ub = Inf;
isInt = false;
errMsg = validateNumber(fuelOxMass, numberName, lb, ub, isInt, errMsg, enteredStr);

monopropMass = str2double(get(handles.monopropMassText,'String'));
enteredStr = get(handles.monopropMassText,'String');
numberName = 'Orbit Epoch';
lb = 0;
ub = Inf;
isInt = false;
errMsg = validateNumber(monopropMass, numberName, lb, ub, isInt, errMsg, enteredStr);

xenonMass = str2double(get(handles.xenonMassText,'String'));
enteredStr = get(handles.xenonMassText,'String');
numberName = 'Orbit Epoch';
lb = 0;
ub = Inf;
isInt = false;
errMsg = validateNumber(xenonMass, numberName, lb, ub, isInt, errMsg, enteredStr);


% --- Executes on button press in saveCloseButton.
function saveCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
errMsg = validateInputs(handles);

if(isempty(errMsg))
    uiresume(handles.ma_InsertStateGUI);
else
    msgbox(errMsg,'Errors were found while inserting a state.','error');
end

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.ma_InsertStateGUI);


function stateNameText_Callback(hObject, eventdata, handles)
% hObject    handle to stateNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of stateNameText as text
%        str2double(get(hObject,'String')) returns contents of stateNameText as a double


% --- Executes during object creation, after setting all properties.
function stateNameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stateNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function smaText_Callback(hObject, eventdata, handles)
% hObject    handle to smaText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of smaText as text
%        str2double(get(hObject,'String')) returns contents of smaText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function smaText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to smaText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function eccText_Callback(hObject, eventdata, handles)
% hObject    handle to eccText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eccText as text
%        str2double(get(hObject,'String')) returns contents of eccText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function eccText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eccText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function incText_Callback(hObject, eventdata, handles)
% hObject    handle to incText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of incText as text
%        str2double(get(hObject,'String')) returns contents of incText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function incText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to incText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function raanText_Callback(hObject, eventdata, handles)
% hObject    handle to raanText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of raanText as text
%        str2double(get(hObject,'String')) returns contents of raanText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function raanText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to raanText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function argText_Callback(hObject, eventdata, handles)
% hObject    handle to argText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of argText as text
%        str2double(get(hObject,'String')) returns contents of argText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function argText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to argText (see GCBO)
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



function epochText_Callback(hObject, eventdata, handles)
% hObject    handle to epochText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of epochText as text
%        str2double(get(hObject,'String')) returns contents of epochText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function epochText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to epochText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function fuelOxMassText_Callback(hObject, eventdata, handles)
% hObject    handle to fuelOxMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fuelOxMassText as text
%        str2double(get(hObject,'String')) returns contents of fuelOxMassText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function fuelOxMassText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fuelOxMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function monopropMassText_Callback(hObject, eventdata, handles)
% hObject    handle to monopropMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of monopropMassText as text
%        str2double(get(hObject,'String')) returns contents of monopropMassText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function monopropMassText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to monopropMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function xenonMassText_Callback(hObject, eventdata, handles)
% hObject    handle to xenonMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of xenonMassText as text
%        str2double(get(hObject,'String')) returns contents of xenonMassText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function xenonMassText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xenonMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dryMassText_Callback(hObject, eventdata, handles)
% hObject    handle to dryMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dryMassText as text
%        str2double(get(hObject,'String')) returns contents of dryMassText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function dryMassText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dryMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function truText_Callback(hObject, eventdata, handles)
% hObject    handle to truText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of truText as text
%        str2double(get(hObject,'String')) returns contents of truText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

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


% --------------------------------------------------------------------
function enterUTAsDateTimeContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to enterUTAsDateTimeContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
secUT = enterUTAsDateTimeGUI(str2double(get(gco, 'String')));
if(secUT >= 0)
    set(gco, 'String', fullAccNum2Str(secUT));
    epochText_Callback(handles.epochText, eventdata, handles);
end

% --------------------------------------------------------------------
function getUTFromKSPContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to getUTFromKSPContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function getOrbitFromSFSFileContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to getOrbitFromSFSFileContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    refBodyID = orbitPanelGetOrbitFromSFSContextCallBack(handles.ksptotMainGUI, handles.smaText, handles.eccText, handles.incText, handles.raanText, handles.argText, handles.truText, handles.epochText);
    tru = computeTrueAnomFromMean(deg2rad(str2double(get(handles.truText,'String'))), str2double(get(handles.eccText,'String')));
    set(handles.truText,'String',fullAccNum2Str(rad2deg(tru)));

    if(~isempty(refBodyID) && isnumeric(refBodyID))
        celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
        bodyInfo = getBodyInfoByNumber(refBodyID, celBodyData);
        value = findValueFromComboBox(bodyInfo.name, handles.bodiesCombo);
        set(handles.bodiesCombo,'Value',value);
    end


% --------------------------------------------------------------------
function getOrbitFromKSPTOTConnectContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to getOrbitFromKSPTOTConnectContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    refBodyID = orbitPanelGetOrbitFromKSPTOTConnectCallBack(handles.smaText, handles.eccText, handles.incText, handles.raanText, handles.argText, handles.truText, handles.epochText);
    tru = computeTrueAnomFromMean(deg2rad(str2double(get(handles.truText,'String'))), str2double(get(handles.eccText,'String')));
    set(handles.truText,'String',fullAccNum2Str(rad2deg(tru)));
    
    if(~isempty(refBodyID) && isnumeric(refBodyID))
        celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
        bodyInfo = getBodyInfoByNumber(refBodyID, celBodyData);
        value = findValueFromComboBox(bodyInfo.name, handles.bodiesCombo);
        set(handles.bodiesCombo,'Value',value);
    end

% --------------------------------------------------------------------
function orbitPanelContext_Callback(hObject, eventdata, handles)
% hObject    handle to orbitPanelContext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function getMassesFromKSPMenu_Callback(hObject, eventdata, handles)
% hObject    handle to getMassesFromKSPMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    m = readDoublesFromKSPTOTConnect('GetVesselMassesData','',true);
    set(handles.dryMassText,'String',num2str(m(1)));
    set(handles.fuelOxMassText,'String',num2str(m(2)));
    set(handles.monopropMassText,'String',num2str(m(3)));
    set(handles.xenonMassText,'String',num2str(m(4)));


% --- Executes on key press with focus on ma_InsertStateGUI or any of its controls.
function ma_InsertStateGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to ma_InsertStateGUI (see GCBO)
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
    end


% --------------------------------------------------------------------
function copyOrbitToClipboardMenu_Callback(hObject, eventdata, handles)
% hObject    handle to copyOrbitToClipboardMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    copyOrbitToClipboardFromText(handles.epochText, handles.smaText, handles.eccText, ...
                                 handles.incText, handles.raanText, handles.argText, ...
                                 handles.truText, true);

% --------------------------------------------------------------------
function pasteOrbitFromClipboardMenu_Callback(hObject, eventdata, handles)
% hObject    handle to pasteOrbitFromClipboardMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    pasteOrbitFromClipboard(handles.epochText, handles.smaText, handles.eccText, ...
                                 handles.incText, handles.raanText, handles.argText, ...
                                 handles.truText, true);


% --- Executes on key release with focus on ma_InsertStateGUI or any of its controls.
function ma_InsertStateGUI_WindowKeyReleaseFcn(hObject, eventdata, handles)
% hObject    handle to ma_InsertStateGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was released, in lower case
%	Character: character interpretation of the key(s) that was released
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) released
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'escape'
            close(handles.ma_InsertStateGUI);
    end


% --------------------------------------------------------------------
function getOrbitFromKSPActiveVesselMenu_Callback(hObject, eventdata, handles)
% hObject    handle to getOrbitFromKSPActiveVesselMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    refBodyID = orbitPanelGetOrbitFromKSPTOTConnectActiveVesselCallBack(handles.smaText, handles.eccText, handles.incText, handles.raanText, handles.argText, handles.truText, handles.epochText);
    tru = computeTrueAnomFromMean(deg2rad(str2double(get(handles.truText,'String'))), str2double(get(handles.eccText,'String')));
    set(handles.truText,'String',fullAccNum2Str(rad2deg(tru)));
    
    if(~isempty(refBodyID) && isnumeric(refBodyID))
        celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
        bodyInfo = getBodyInfoByNumber(refBodyID, celBodyData);
        value = findValueFromComboBox(bodyInfo.name, handles.bodiesCombo);
        set(handles.bodiesCombo,'Value',value);
    end
