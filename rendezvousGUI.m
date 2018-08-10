function varargout = rendezvousGUI(varargin)
% RENDEZVOUSGUI MATLAB code for rendezvousGUI.fig
%      RENDEZVOUSGUI, by itself, creates a new RENDEZVOUSGUI or raises the existing
%      singleton*.
%
%      H = RENDEZVOUSGUI returns the handle to a new RENDEZVOUSGUI or the handle to
%      the existing singleton*.
%
%      RENDEZVOUSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RENDEZVOUSGUI.M with the given input arguments.
%
%      RENDEZVOUSGUI('Property','Value',...) creates a new RENDEZVOUSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before rendezvousGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to rendezvousGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help rendezvousGUI

% Last Modified by GUIDE v2.5 11-Jun-2018 20:31:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @rendezvousGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @rendezvousGUI_OutputFcn, ...
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


% --- Executes just before rendezvousGUI is made visible.
function rendezvousGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to rendezvousGUI (see VARARGIN)

% Choose default command line output for rendezvousGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%Possible fix for people with display issues.
checkForCharUnitsInGUI(hObject);

mainGUIHandle = varargin{1};
mainUserData = get(mainGUIHandle, 'UserData');
userData = cell(10);
userData{1,1} = mainGUIHandle;
set(hObject, 'UserData', userData);

userData = get(mainGUIHandle,'UserData');
celBodyData = userData{1,1};

% [~, ~, allNames] = genCBArriveDepartComboBoxStrs(mainGUIHandle);
allNames = ma_getSortedBodyNames(celBodyData);
allNamesComboString = char(cap1stLetter(allNames));
set(handles.orbitingAboutCombo,'String',allNamesComboString);
set(handles.orbitingAboutCombo,'Value',5);
orbitingAboutCombo_Callback(handles.orbitingAboutCombo, [], handles);

initialEpochText_Callback(handles.initialEpochText, [], handles);
searchDurationText_Callback(handles.searchDurationText, [], handles);

hold on;
orbitDispAxes = handles.orbitDispAxes;
axes(orbitDispAxes);
set(orbitDispAxes,'XTickLabel',[]);
set(orbitDispAxes,'YTickLabel',[]);
set(orbitDispAxes,'ZTickLabel',[]);
grid on;
view(3);

celBodyData = mainUserData{1,1};
contents = cellstr(get(handles.orbitingAboutCombo,'String'));
bodyName = contents{get(handles.orbitingAboutCombo,'Value')};
bodyInfo = celBodyData.(strtrim(lower(bodyName)));
dRad = bodyInfo.radius;
[X,Y,Z] = sphere(30);
surf(dRad*X,dRad*Y,dRad*Z);
colormap(bodyInfo.bodycolor);
axis equal;
hold off;

paramWgtSlider_Callback(handles.paramWgtSlider, [], handles);

% UIWAIT makes rendezvousGUI wait for user response (see UIRESUME)
% uiwait(handles.rendezvousGUI);


% --- Outputs from this function are returned to the command line.
function varargout = rendezvousGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in orbitingAboutCombo.
function orbitingAboutCombo_Callback(hObject, eventdata, handles)
% hObject    handle to orbitingAboutCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns orbitingAboutCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from orbitingAboutCombo
userData = get(handles.rendezvousGUI,'UserData');
mainUserData = get(userData{1,1},'UserData');
celBodyData = mainUserData{1,1};

contents = cellstr(get(hObject,'String'));
cbName = strtrim(lower(contents{get(hObject,'Value')}));

emptyStr = {''};
[children, childrenNames] = getChildrenOfParentInfo(celBodyData, cbName);
childrenNames = cat(2,emptyStr,childrenNames);
set(handles.iniSelectCelBodyOrbit, 'String', childrenNames);
set(handles.finalSelectCelBodyOrbit, 'String', childrenNames);



% --- Executes during object creation, after setting all properties.
function orbitingAboutCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to orbitingAboutCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu2.
function popupmenu2_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu2


% --- Executes during object creation, after setting all properties.
function popupmenu2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function finOrbitSMAText_Callback(hObject, eventdata, handles)
% hObject    handle to finOrbitSMAText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of finOrbitSMAText as text
%        str2double(get(hObject,'String')) returns contents of finOrbitSMAText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function finOrbitSMAText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to finOrbitSMAText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function finOrbitECCText_Callback(hObject, eventdata, handles)
% hObject    handle to finOrbitECCText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of finOrbitECCText as text
%        str2double(get(hObject,'String')) returns contents of finOrbitECCText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function finOrbitECCText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to finOrbitECCText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function finOrbitINCText_Callback(hObject, eventdata, handles)
% hObject    handle to finOrbitINCText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of finOrbitINCText as text
%        str2double(get(hObject,'String')) returns contents of finOrbitINCText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function finOrbitINCText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to finOrbitINCText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function finOrbitRAANText_Callback(hObject, eventdata, handles)
% hObject    handle to finOrbitRAANText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of finOrbitRAANText as text
%        str2double(get(hObject,'String')) returns contents of finOrbitRAANText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function finOrbitRAANText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to finOrbitRAANText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function finOrbitARGText_Callback(hObject, eventdata, handles)
% hObject    handle to finOrbitARGText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of finOrbitARGText as text
%        str2double(get(hObject,'String')) returns contents of finOrbitARGText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function finOrbitARGText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to finOrbitARGText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function iniOrbitSMAText_Callback(hObject, eventdata, handles)
% hObject    handle to iniOrbitSMAText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of iniOrbitSMAText as text
%        str2double(get(hObject,'String')) returns contents of iniOrbitSMAText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function iniOrbitSMAText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to iniOrbitSMAText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function iniOrbitECCText_Callback(hObject, eventdata, handles)
% hObject    handle to iniOrbitECCText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of iniOrbitECCText as text
%        str2double(get(hObject,'String')) returns contents of iniOrbitECCText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function iniOrbitECCText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to iniOrbitECCText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function iniOrbitINCText_Callback(hObject, eventdata, handles)
% hObject    handle to iniOrbitINCText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of iniOrbitINCText as text
%        str2double(get(hObject,'String')) returns contents of iniOrbitINCText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function iniOrbitINCText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to iniOrbitINCText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function iniOrbitRAANText_Callback(hObject, eventdata, handles)
% hObject    handle to iniOrbitRAANText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of iniOrbitRAANText as text
%        str2double(get(hObject,'String')) returns contents of iniOrbitRAANText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function iniOrbitRAANText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to iniOrbitRAANText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function iniOrbitARGText_Callback(hObject, eventdata, handles)
% hObject    handle to iniOrbitARGText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of iniOrbitARGText as text
%        str2double(get(hObject,'String')) returns contents of iniOrbitARGText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function iniOrbitARGText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to iniOrbitARGText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function xfrOrbitText_Callback(hObject, eventdata, handles)
% hObject    handle to xfrOrbitText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of xfrOrbitText as text
%        str2double(get(hObject,'String')) returns contents of xfrOrbitText as a double


% --- Executes during object creation, after setting all properties.
function xfrOrbitText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xfrOrbitText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dvMan2InfoText_Callback(hObject, eventdata, handles)
% hObject    handle to dvMan2InfoText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dvMan2InfoText as text
%        str2double(get(hObject,'String')) returns contents of dvMan2InfoText as a double


% --- Executes during object creation, after setting all properties.
function dvMan2InfoText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dvMan2InfoText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dvMan1InfoText_Callback(hObject, eventdata, handles)
% hObject    handle to dvMan1InfoText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dvMan1InfoText as text
%        str2double(get(hObject,'String')) returns contents of dvMan1InfoText as a double


% --- Executes during object creation, after setting all properties.
function dvMan1InfoText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dvMan1InfoText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in computeRendezvousButton.
function computeRendezvousButton_Callback(hObject, eventdata, handles)
% hObject    handle to computeRendezvousButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
userData = get(handles.rendezvousGUI,'UserData');
mainUserData = get(userData{1,1}, 'UserData');
celBodyData = mainUserData{1,1};

contents = cellstr(get(handles.orbitingAboutCombo,'String'));
cbName = strtrim(lower(contents{get(handles.orbitingAboutCombo,'Value')}));

bodyInfo = celBodyData.(cbName);
parentBodyInfo = getParentBodyInfo(bodyInfo, celBodyData);
if(isempty(parentBodyInfo))
    soiRadiusParent = Inf;
else
    soiRadiusParent = getSOIRadius(bodyInfo, parentBodyInfo);
end

gmuXfr = bodyInfo.gm;

errMsg = {};

iniOrbit(2) = str2double(get(handles.iniOrbitECCText, 'String'));
enteredStr = get(handles.iniOrbitECCText,'String');
numberName = 'Initial orbit eccentricity';
lb = 0;
ub = Inf;
isInt = false;
errMsg = validateNumber(iniOrbit(2), numberName, lb, ub, isInt, errMsg, enteredStr);
if(not(isempty(errMsg))) 
    msgbox(errMsg,'Errors were found in departure burn calculation inputs','error');
    return;
end

finOrbit(2) = str2double(get(handles.finOrbitECCText, 'String'));
enteredStr = get(handles.finOrbitECCText,'String');
numberName = 'Final orbit eccentricity';
lb = 0;
ub = Inf;
isInt = false;
errMsg = validateNumber(finOrbit(2), numberName, lb, ub, isInt, errMsg, enteredStr);
if(not(isempty(errMsg))) 
    msgbox(errMsg,'Errors were found in departure burn calculation inputs','error');
    return;
end

iniOrbit(1) = str2double(get(handles.iniOrbitSMAText, 'String'));
enteredStr = get(handles.iniOrbitSMAText,'String');
if(iniOrbit(2) < 1.0)
    lb = 1;
    ub = Inf;
    numberName = 'Initial eccentric orbit semi-major axis';
else
    lb = -Inf;
    ub = -1;
    numberName = 'Initial hyperbolic orbit semi-major axis';
end
isInt = false;
errMsg = validateNumber(iniOrbit(1), numberName, lb, ub, isInt, errMsg, enteredStr);

iniOrbit(3) = str2double(get(handles.iniOrbitINCText, 'String'));
enteredStr = get(handles.iniOrbitINCText,'String');
numberName = 'Initial orbit inclination';
lb = 0;
ub = 180;
isInt = false;
errMsg = validateNumber(iniOrbit(3), numberName, lb, ub, isInt, errMsg, enteredStr);
iniOrbit(3)=iniOrbit(3)*pi/180;

iniOrbit(4) = str2double(get(handles.iniOrbitRAANText, 'String'));
enteredStr = get(handles.iniOrbitRAANText,'String');
numberName = 'Initial orbit RAAN';
lb = 0;
ub = 360;
isInt = false;
errMsg = validateNumber(iniOrbit(4), numberName, lb, ub, isInt, errMsg, enteredStr);
iniOrbit(4)=iniOrbit(4)*pi/180;

iniOrbit(5) = str2double(get(handles.iniOrbitARGText, 'String'));
enteredStr = get(handles.iniOrbitARGText,'String');
numberName = 'Initial orbit argument of periapse';
lb = 0;
ub = 360;
isInt = false;
errMsg = validateNumber(iniOrbit(5), numberName, lb, ub, isInt, errMsg, enteredStr);
iniOrbit(5)=iniOrbit(5)*pi/180;

iniOrbit(6) = str2double(get(handles.iniOrbitMEANText, 'String'));
enteredStr = get(handles.iniOrbitMEANText,'String');
numberName = 'Initial orbit mean anomaly at epoch';
lb = -180;
ub = 360;
isInt = false;
errMsg = validateNumber(iniOrbit(6), numberName, lb, ub, isInt, errMsg, enteredStr);
iniOrbit(6)=iniOrbit(6)*pi/180;

iniOrbit(7) = str2double(get(handles.iniOrbitEPOCHText, 'String'));
enteredStr = get(handles.iniOrbitEPOCHText,'String');
numberName = 'Initial orbit epoch';
lb = -Inf;
ub = Inf;
isInt = false;
errMsg = validateNumber(iniOrbit(7), numberName, lb, ub, isInt, errMsg, enteredStr);

finOrbit(1) = str2double(get(handles.finOrbitSMAText, 'String'));
enteredStr = get(handles.finOrbitSMAText,'String');
if(finOrbit(2) < 1.0)
    lb = 1;
    ub = Inf;
    numberName = 'Final eccentric orbit semi-major axis';
else
    lb = -Inf;
    ub = -1;
    numberName = 'Final hyperbolic orbit semi-major axis';
end
isInt = false;
errMsg = validateNumber(finOrbit(1), numberName, lb, ub, isInt, errMsg, enteredStr);

finOrbit(3) = str2double(get(handles.finOrbitINCText, 'String'));
enteredStr = get(handles.finOrbitINCText,'String');
numberName = 'Final orbit inclination';
lb = 0;
ub = 180;
isInt = false;
errMsg = validateNumber(finOrbit(3), numberName, lb, ub, isInt, errMsg, enteredStr);
finOrbit(3)=finOrbit(3)*pi/180;

finOrbit(4) = str2double(get(handles.finOrbitRAANText, 'String'));
enteredStr = get(handles.finOrbitRAANText,'String');
numberName = 'Final orbit RAAN';
lb = 0;
ub = 360;
isInt = false;
errMsg = validateNumber(finOrbit(4), numberName, lb, ub, isInt, errMsg, enteredStr);
finOrbit(4)=finOrbit(4)*pi/180;

finOrbit(5) = str2double(get(handles.finOrbitARGText, 'String'));
enteredStr = get(handles.finOrbitARGText,'String');
numberName = 'Final orbit argument of periapse';
lb = 0;
ub = 360;
isInt = false;
errMsg = validateNumber(finOrbit(5), numberName, lb, ub, isInt, errMsg, enteredStr);
finOrbit(5)=finOrbit(5)*pi/180;

finOrbit(6) = str2double(get(handles.finOrbitMEANText, 'String'));
enteredStr = get(handles.finOrbitMEANText,'String');
numberName = 'Final orbit mean anomaly at epoch';
lb = -180;
ub = 360;
isInt = false;
errMsg = validateNumber(finOrbit(6), numberName, lb, ub, isInt, errMsg, enteredStr);
finOrbit(6)=finOrbit(6)*pi/180;

finOrbit(7) = str2double(get(handles.finOrbitEPOCHText, 'String'));
enteredStr = get(handles.finOrbitEPOCHText,'String');
numberName = 'Final orbit epoch';
lb = -Inf;
ub = Inf;
isInt = false;
errMsg = validateNumber(finOrbit(7), numberName, lb, ub, isInt, errMsg, enteredStr);

startEpoch = str2double(get(handles.initialEpochText, 'String'));
enteredStr = get(handles.initialEpochText,'String');
numberName = 'Search initial epoch';
lb = -Inf;
ub = Inf;
isInt = false;
errMsg = validateNumber(startEpoch, numberName, lb, ub, isInt, errMsg, enteredStr);

searchDuration = str2double(get(handles.searchDurationText, 'String'));
enteredStr = get(handles.searchDurationText,'String');
numberName = 'Search duration';
lb = 0;
ub = Inf;
isInt = false;
errMsg = validateNumber(searchDuration, numberName, lb, ub, isInt, errMsg, enteredStr);

if(isempty(errMsg))
    try
        bodyInfo1 = getBodyInfoMatchingOrbit(iniOrbit, celBodyData);
        if(~isempty(bodyInfo1))
            gmuXfr1 = getParentGM(bodyInfo1, celBodyData);
        else
            gmuXfr1 = gmuXfr;
        end
        iniOrbit(8) = gmuXfr1;
        
        if(iniOrbit(1) > 0)
            p1 = computePeriod(iniOrbit(1), gmuXfr1);
        else
            n1 = computeMeanMotion(iniOrbit(1), gmuXfr1);
            
            iniHyTruMax = AngleZero2Pi(real(computeTrueAFromRadiusEcc(1.0*soiRadiusParent, iniOrbit(1), iniOrbit(2))));
            iniHyTruMin = -iniHyTruMax;  
            
            MA1 = computeMeanFromTrueAnom(iniHyTruMin, iniOrbit(2));
            MA2 = computeMeanFromTrueAnom(iniHyTruMax, iniOrbit(2));
            
            MAEpoch = computeMeanFromTrueAnom(iniOrbit(6), iniOrbit(2));
            finOrbitEpoch = iniOrbit(7);
                        
            dMASubtract1 = MAEpoch - MA1;
            dTime1 = dMASubtract1/n1;
            epoch1 = finOrbitEpoch - dTime1;
            
            MAStartEpoch = (startEpoch - epoch1)*n1 + MA1;
            
%             dMA = MA2-MA1;
            dMA = MA2-MAStartEpoch;
            p1 = dMA/n1;
        end
        
        bodyInfo2 = getBodyInfoMatchingOrbit(finOrbit, celBodyData);
        if(~isempty(bodyInfo2))
            gmuXfr2 = getParentGM(bodyInfo2, celBodyData);
        else
            gmuXfr2 = gmuXfr;
        end
        finOrbit(8) = gmuXfr2;
        
        if(finOrbit(1) > 0)
            p2 = computePeriod(finOrbit(1), gmuXfr2);
        else
            n2 = computeMeanMotion(finOrbit(1), gmuXfr2);
            
            iniHyTruMax = AngleZero2Pi(real(computeTrueAFromRadiusEcc(1.0*soiRadiusParent, finOrbit(1), finOrbit(2))));
            iniHyTruMin = -iniHyTruMax;
            
            MA1 = computeMeanFromTrueAnom(iniHyTruMin, finOrbit(2));
            MA2 = computeMeanFromTrueAnom(iniHyTruMax, finOrbit(2));
            MAEpoch = computeMeanFromTrueAnom(finOrbit(6), finOrbit(2));
            finOrbitEpoch = finOrbit(7);
                        
            dMASubtract1 = MAEpoch - MA1;
            dTime1 = dMASubtract1/n2;
            epoch1 = finOrbitEpoch - dTime1;
            
            MAStartEpoch = (startEpoch - epoch1)*n2 + MA1;
            
%             dMA = MA2-MA1;
            dMA = MA2-MAStartEpoch;
            p2 = dMA/n2;
        end
        
        if(finOrbit(2) >= 1.0 && iniOrbit(2) < 1.0)
            duration = p2;
        elseif(finOrbit(2) < 1.0 && iniOrbit(2) >= 1.0)
            duration = p1;
        elseif(finOrbit(2) >= 1.0 && iniOrbit(2) >= 1.0)
            duration = min(p1,p2);
        else
            duration = 1.5*max(p1,p2);
        end
        
        endEpoch = startEpoch + searchDuration;

        weights = get(handles.paramWgtSlider,'UserData');
        
        objFunc = @(x) rendezvousObjFunc(x, iniOrbit, finOrbit, gmuXfr, weights);
        x0 = [startEpoch+searchDuration/2 duration/2];
        lb = [startEpoch 1000];
        ub = [endEpoch duration];
        
        if(isempty(objFunc(x0)) || isnan(objFunc(x0)) || ~isfinite(objFunc(x0)))
            error('Cannot compute rendezvous: objective function at initial point is invalid.  Please alter your inputs.');
        end
        
        if(finOrbit(2) >= 1.0 ||  iniOrbit(2) >= 1.0)
            A = [1 1];
            b = [endEpoch];
        else
            A = [];
            b = [];
        end
        
        minPe = bodyInfo.radius + bodyInfo.atmohgt + 1;
        maxAp = getSOIRadius(bodyInfo, parentBodyInfo) - 1;
        nonlcon = @(x)rendezvousNonlconFunc(x, iniOrbit, finOrbit, gmuXfr, minPe, maxAp);
        
        [x,fval,exitflag,output,solutions] = multiStartCommonRun('Computing Rendezvous Maneuvers...', 20, objFunc, x0, A, b, lb, ub, nonlcon);
        [objFuncValue, dv, deltaV1, deltaV2, deltaV1R, deltaV2R, xfrOrbit, deltaV1NTW, deltaV2NTW] = objFunc(x);
        
        time1 = x(1);
        time2 = time1 + x(2);
        timeArr = [time1 time2];

        iniOrbBodyInfo = getBodyInfoStructFromOrbit(iniOrbit);
        [rVect, vVect] = getStateAtTime(iniOrbBodyInfo, time1, gmuXfr1);
        [~, ~, ~, ~, ~, burnTAINIOrbit] = getKeplerFromState(rVect,vVect,gmuXfr);

        xfrOrbBodyInfo = getBodyInfoStructFromOrbit(xfrOrbit);
        [rVect, vVect] = getStateAtTime(xfrOrbBodyInfo, time2, gmuXfr);
        [~, ~, ~, ~, ~, burnTAXfrOrbit] = getKeplerFromState(rVect,vVect,gmuXfr);

        form = '%9.3f';
        paddLen = 32;
        xferOrbitText{1} = ['Transfer Orbit about ', cap1stLetter(lower(cbName))];
        printXferOrbitToTextbox(handles.xfrOrbitText, xferOrbitText, xfrOrbit, form, paddLen)  

        paddLen = 29;
        form = '%9.5f';
        burn1InfoText{1} = ['Transfer Orbit Injection Burn '];
        burn1InfoText{end+1} = '(Relative to initial orbit)';
        dv1Text = printDVManeuverInfoToTextbox(handles.dvMan1InfoText, burn1InfoText, deltaV1NTW, burnTAINIOrbit, iniOrbit, gmuXfr, form, paddLen, time1);

        paddLen = 26;
        form = '%9.5f';
        burn2InfoText{1} = ['Final Orbit Injection Burn '];
        burn2InfoText{end+1} = '(Relative to transfer orbit)';
        dv2Text = printDVManeuverInfoToTextbox(handles.dvMan2InfoText, burn2InfoText, deltaV2NTW, burnTAXfrOrbit, xfrOrbit, gmuXfr, form, paddLen, time2);

        plotRendezvous(handles.orbitDispAxes, timeArr, bodyInfo, iniOrbit, finOrbit, xfrOrbit, deltaV1, deltaV2, celBodyData);
        
        dv1ManTextUserData = get(handles.dvMan1InfoText,'UserData');
        dv1ManTextUserData(1) = 0;
        dv1ManTextUserData(2) = time1;
        set(handles.dvMan1InfoText,'UserData',dv1ManTextUserData);
        
        dv2ManTextUserData = get(handles.dvMan2InfoText,'UserData');
        dv2ManTextUserData(1) = 0;
        dv2ManTextUserData(2) = time2;
        set(handles.dvMan2InfoText,'UserData',dv2ManTextUserData);
        
        results = struct();
        results.dv1Text = dv1Text;
        results.dv2Text = dv2Text;
        results.timeArr = timeArr;
        results.bodyInfo = bodyInfo;
        results.iniOrbit = iniOrbit;
        results.finOrbit = finOrbit;
        results.xfrOrbit = xfrOrbit;
        results.deltaV1 = deltaV1;
        results.deltaV2 = deltaV2;        
        
        userData{2,1} = results;
        set(handles.rendezvousGUI,'UserData',userData);
    catch ME
        msgbox(ME.message);
    end
else
    msgbox(errMsg,'Errors were found in orbit change calculation inputs','error');
end


% --------------------------------------------------------------------
function getFinalOrbitFromSFSFile_Callback(hObject, eventdata, handles)
% hObject    handle to getFinalOrbitFromSFSFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    userData = get(handles.rendezvousGUI,'UserData');
    mainGUIHandle = userData{1,1};
    refBodyID = orbitPanelGetOrbitFromSFSContextCallBack(mainGUIHandle, handles.finOrbitSMAText, handles.finOrbitECCText, handles.finOrbitINCText, handles.finOrbitRAANText, handles.finOrbitARGText, handles.finOrbitMEANText, handles.finOrbitEPOCHText);

    if(~isempty(refBodyID) && isnumeric(refBodyID))
        userData = get(handles.rendezvousGUI,'UserData');
        mainUserData = get(userData{1,1},'UserData');
        celBodyData = mainUserData{1,1};
        
        bodyInfo = getBodyInfoByNumber(refBodyID, celBodyData);
        value = findValueFromComboBox(bodyInfo.name, handles.orbitingAboutCombo);
        set(handles.orbitingAboutCombo,'Value',value);
        orbitingAboutCombo_Callback(handles.orbitingAboutCombo, [], handles);
    end

function getFinalOrbitFromKSPTOTConnect_Callback(hObject, eventdata, handles)
% hObject    handle to getFinalOrbitFromSFSFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    refBodyID = orbitPanelGetOrbitFromKSPTOTConnectCallBack(handles.finOrbitSMAText, handles.finOrbitECCText, handles.finOrbitINCText, handles.finOrbitRAANText, handles.finOrbitARGText, handles.finOrbitMEANText, handles.finOrbitEPOCHText);

    if(~isempty(refBodyID) && isnumeric(refBodyID))
        userData = get(handles.rendezvousGUI,'UserData');
        mainUserData = get(userData{1,1},'UserData');
        celBodyData = mainUserData{1,1};
        
        bodyInfo = getBodyInfoByNumber(refBodyID, celBodyData);
        value = findValueFromComboBox(bodyInfo.name, handles.orbitingAboutCombo);
        set(handles.orbitingAboutCombo,'Value',value);
        orbitingAboutCombo_Callback(handles.orbitingAboutCombo, [], handles);
    end
    
% --------------------------------------------------------------------
function getINIOrbitFromSFSFile_Callback(hObject, eventdata, handles)
% hObject    handle to getINIOrbitFromSFSFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    userData = get(handles.rendezvousGUI,'UserData');
    mainGUIHandle = userData{1,1};
    refBodyID = orbitPanelGetOrbitFromSFSContextCallBack(mainGUIHandle, handles.iniOrbitSMAText, handles.iniOrbitECCText, handles.iniOrbitINCText, handles.iniOrbitRAANText, handles.iniOrbitARGText, handles.iniOrbitMEANText, handles.iniOrbitEPOCHText);

    if(~isempty(refBodyID) && isnumeric(refBodyID))
        userData = get(handles.rendezvousGUI,'UserData');
        mainUserData = get(userData{1,1},'UserData');
        celBodyData = mainUserData{1,1};
        
        bodyInfo = getBodyInfoByNumber(refBodyID, celBodyData);
        value = findValueFromComboBox(bodyInfo.name, handles.orbitingAboutCombo);
        set(handles.orbitingAboutCombo,'Value',value);
        orbitingAboutCombo_Callback(handles.orbitingAboutCombo, [], handles);
    end    
    
% --------------------------------------------------------------------
function getINIOrbitFromKSPTOTConnect_Callback(hObject, eventdata, handles)
% hObject    handle to getINIOrbitFromSFSFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    refBodyID = orbitPanelGetOrbitFromKSPTOTConnectCallBack(handles.iniOrbitSMAText, handles.iniOrbitECCText, handles.iniOrbitINCText, handles.iniOrbitRAANText, handles.iniOrbitARGText, handles.iniOrbitMEANText, handles.iniOrbitEPOCHText);

    if(~isempty(refBodyID) && isnumeric(refBodyID))
        userData = get(handles.rendezvousGUI,'UserData');
        mainUserData = get(userData{1,1},'UserData');
        celBodyData = mainUserData{1,1};
        
        bodyInfo = getBodyInfoByNumber(refBodyID, celBodyData);
        value = findValueFromComboBox(bodyInfo.name, handles.orbitingAboutCombo);
        set(handles.orbitingAboutCombo,'Value',value);
        orbitingAboutCombo_Callback(handles.orbitingAboutCombo, [], handles);
    end  

function meanAnomText_Callback(hObject, eventdata, handles)
% hObject    handle to meanAnomText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of meanAnomText as text
%        str2double(get(hObject,'String')) returns contents of meanAnomText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function meanAnomText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to meanAnomText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
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
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

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


function edit25_Callback(hObject, eventdata, handles)
% hObject    handle to meanAnomText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of meanAnomText as text
%        str2double(get(hObject,'String')) returns contents of meanAnomText as a double


% --- Executes during object creation, after setting all properties.
function edit25_CreateFcn(hObject, eventdata, handles)
% hObject    handle to meanAnomText (see GCBO)
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
function orbitContMenuWithGetDateTime_Callback(hObject, eventdata, handles)
% hObject    handle to orbitContMenuWithGetDateTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


function iniOrbitMEANText_Callback(hObject, eventdata, handles)
% hObject    handle to iniOrbitMEANText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of iniOrbitMEANText as text
%        str2double(get(hObject,'String')) returns contents of iniOrbitMEANText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function iniOrbitMEANText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to iniOrbitMEANText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function iniOrbitEPOCHText_Callback(hObject, eventdata, handles)
% hObject    handle to iniOrbitEPOCHText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of iniOrbitEPOCHText as text
%        str2double(get(hObject,'String')) returns contents of iniOrbitEPOCHText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function iniOrbitEPOCHText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to iniOrbitEPOCHText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function finOrbitMEANText_Callback(hObject, eventdata, handles)
% hObject    handle to finOrbitMEANText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of finOrbitMEANText as text
%        str2double(get(hObject,'String')) returns contents of finOrbitMEANText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function finOrbitMEANText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to finOrbitMEANText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function finOrbitEPOCHText_Callback(hObject, eventdata, handles)
% hObject    handle to finOrbitEPOCHText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of finOrbitEPOCHText as text
%        str2double(get(hObject,'String')) returns contents of finOrbitEPOCHText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function finOrbitEPOCHText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to finOrbitEPOCHText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit34_Callback(hObject, eventdata, handles)
% hObject    handle to edit34 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit34 as text
%        str2double(get(hObject,'String')) returns contents of edit34 as a double


% --- Executes during object creation, after setting all properties.
function edit34_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit34 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in iniSelectCelBodyOrbit.
function iniSelectCelBodyOrbit_Callback(hObject, eventdata, handles)
% hObject    handle to iniSelectCelBodyOrbit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns iniSelectCelBodyOrbit contents as cell array
%        contents{get(hObject,'Value')} returns selected item from iniSelectCelBodyOrbit
contents = cellstr(get(hObject,'String'));
selName = contents{get(hObject,'Value')};

userData = get(handles.rendezvousGUI,'UserData');
mainUserData = get(userData{1,1},'UserData');
celBodyData = mainUserData{1,1};

if(~isempty(selName))
    bodyInfo = celBodyData.(lower(selName));
    set(handles.iniOrbitSMAText, 'String', fullAccNum2Str(bodyInfo.sma));
    set(handles.iniOrbitECCText, 'String', fullAccNum2Str(bodyInfo.ecc));
    set(handles.iniOrbitINCText, 'String', fullAccNum2Str(bodyInfo.inc));
    set(handles.iniOrbitRAANText, 'String', fullAccNum2Str(bodyInfo.raan));
    set(handles.iniOrbitARGText, 'String', fullAccNum2Str(bodyInfo.arg));
    set(handles.iniOrbitMEANText, 'String', fullAccNum2Str(bodyInfo.mean));
    set(handles.iniOrbitEPOCHText, 'String', fullAccNum2Str(bodyInfo.epoch));
    set(hObject, 'Value', 1);
end

% --- Executes during object creation, after setting all properties.
function iniSelectCelBodyOrbit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to iniSelectCelBodyOrbit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu4.
function popupmenu4_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu4 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu4


% --- Executes during object creation, after setting all properties.
function popupmenu4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu5.
function popupmenu5_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu5 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu5


% --- Executes during object creation, after setting all properties.
function popupmenu5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in finalSelectCelBodyOrbit.
function finalSelectCelBodyOrbit_Callback(hObject, eventdata, handles)
% hObject    handle to finalSelectCelBodyOrbit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns finalSelectCelBodyOrbit contents as cell array
%        contents{get(hObject,'Value')} returns selected item from finalSelectCelBodyOrbit
contents = cellstr(get(hObject,'String'));
selName = contents{get(hObject,'Value')};

userData = get(handles.rendezvousGUI,'UserData');
mainUserData = get(userData{1,1},'UserData');
celBodyData = mainUserData{1,1};

if(~isempty(selName))
    bodyInfo = celBodyData.(lower(selName));
    set(handles.finOrbitSMAText, 'String', fullAccNum2Str(bodyInfo.sma));
    set(handles.finOrbitECCText, 'String', fullAccNum2Str(bodyInfo.ecc));
    set(handles.finOrbitINCText, 'String', fullAccNum2Str(bodyInfo.inc));
    set(handles.finOrbitRAANText, 'String', fullAccNum2Str(bodyInfo.raan));
    set(handles.finOrbitARGText, 'String', fullAccNum2Str(bodyInfo.arg));
    set(handles.finOrbitMEANText, 'String', fullAccNum2Str(bodyInfo.mean));
    set(handles.finOrbitEPOCHText, 'String', fullAccNum2Str(bodyInfo.epoch));
    set(hObject, 'Value', 1);
end

% --- Executes during object creation, after setting all properties.
function finalSelectCelBodyOrbit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to finalSelectCelBodyOrbit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function initialEpochText_Callback(hObject, eventdata, handles)
% hObject    handle to initialEpochText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of initialEpochText as text
%        str2double(get(hObject,'String')) returns contents of initialEpochText as a double
newInput = get(hObject,'String');

newInput = attemptStrEval(newInput);

inputSec = str2double(newInput);
if(checkStrIsNumeric(newInput) && inputSec>=0.0)
    [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(inputSec);
    dateStr = formDateStr(year, day, hour, minute, sec);
    set(handles.startEpochDateLabel, 'String', dateStr);
    set(hObject,'String', num2str(inputSec));   
end

% --- Executes during object creation, after setting all properties.
function initialEpochText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to initialEpochText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function enterRendStartEpochUTAsDateTime_Callback(hObject, eventdata, handles)
% hObject    handle to enterRendStartEpochUTAsDateTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
secUT = enterUTAsDateTimeGUI(str2double(get(gco, 'String')));
if(secUT >= 0)
    set(gco, 'String', num2str(secUT));
    initialEpochText_Callback(handles.initialEpochText,[],handles);
end


% --------------------------------------------------------------------
function generateReport_Callback(hObject, eventdata, handles)
% hObject    handle to generateReport (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hReport, handlesR] = genericReport(1, 'DOUBLE DELTA-V MANEUVER', 'RENDEZVOUS MANEUVER SEQUENCER');
userData = get(handles.rendezvousGUI,'UserData');
results = userData{2,1};

mainUserData = get(userData{1,1}, 'UserData');
celBodyData = mainUserData{1,1};

if(~isempty(results))
    set(handlesR.leftTextBox,'String',results.dv1Text);
    set(handlesR.rightTextBox,'String',results.dv2Text);
    plotRendezvous(handlesR.leftAxis, results.timeArr, results.bodyInfo, results.iniOrbit, results.finOrbit, results.xfrOrbit, results.deltaV1, results.deltaV2, celBodyData);
end


% --------------------------------------------------------------------
function uploadManeuver1_Callback(hObject, eventdata, handles)
% hObject    handle to uploadManeuver1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
guiData = get(handles.dvMan1InfoText,'UserData');
uploadManeuverToKSP(guiData);


% --------------------------------------------------------------------
function uploadManeuver2_Callback(hObject, eventdata, handles)
% hObject    handle to uploadManeuver2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
guiData = get(handles.dvMan2InfoText,'UserData');
uploadManeuverToKSP(guiData);


% --------------------------------------------------------------------
function Untitled_7_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function pasteOrbitFromClipboardMenu2_Callback(hObject, eventdata, handles)
% hObject    handle to pasteOrbitFromClipboardMenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    userData = get(handles.rendezvousGUI,'UserData');
    results = userData{2,1};
    mainUserData = get(userData{1,1}, 'UserData');
    celBodyData = mainUserData{1,1};

    pasteOrbitFromClipboard(handles.finOrbitEPOCHText, handles.finOrbitSMAText, handles.finOrbitECCText, ...
                                 handles.finOrbitINCText, handles.finOrbitRAANText, handles.finOrbitARGText, ...
                                 handles.finOrbitMEANText, false, handles.orbitingAboutCombo, celBodyData);

% --------------------------------------------------------------------
function copyOrbitToClipboardMenu2_Callback(hObject, eventdata, handles)
% hObject    handle to copyOrbitToClipboardMenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    userData = get(handles.rendezvousGUI,'UserData');
    results = userData{2,1};
    mainUserData = get(userData{1,1}, 'UserData');
    celBodyData = mainUserData{1,1};
    
    contents = cellstr(get(handles.orbitingAboutCombo,'String'));
    cbName = strtrim(lower(contents{get(handles.orbitingAboutCombo,'Value')}));
    bodyInfo = celBodyData.(cbName);

    copyOrbitToClipboardFromText(handles.finOrbitEPOCHText, handles.finOrbitSMAText, handles.finOrbitECCText, ...
                                 handles.finOrbitINCText, handles.finOrbitRAANText, handles.finOrbitARGText, ...
                                 handles.finOrbitMEANText, false, bodyInfo.id);

% --------------------------------------------------------------------
function copyOrbitToClipboardMenu1_Callback(hObject, eventdata, handles)
% hObject    handle to copyOrbitToClipboardMenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    userData = get(handles.rendezvousGUI,'UserData');
    results = userData{2,1};
    mainUserData = get(userData{1,1}, 'UserData');
    celBodyData = mainUserData{1,1};
    
    contents = cellstr(get(handles.orbitingAboutCombo,'String'));
    cbName = strtrim(lower(contents{get(handles.orbitingAboutCombo,'Value')}));
    bodyInfo = celBodyData.(cbName);

    copyOrbitToClipboardFromText(handles.iniOrbitEPOCHText, handles.iniOrbitSMAText, handles.iniOrbitECCText, ...
                                 handles.iniOrbitINCText, handles.iniOrbitRAANText, handles.iniOrbitARGText, ...
                                 handles.iniOrbitMEANText, false, bodyInfo.id);

% --------------------------------------------------------------------
function pasteOrbitFromClipboardMenu1_Callback(hObject, eventdata, handles)
% hObject    handle to pasteOrbitFromClipboardMenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    userData = get(handles.rendezvousGUI,'UserData');
    results = userData{2,1};
    mainUserData = get(userData{1,1}, 'UserData');
    celBodyData = mainUserData{1,1};

    pasteOrbitFromClipboard(handles.iniOrbitEPOCHText, handles.iniOrbitSMAText, handles.iniOrbitECCText, ...
                                 handles.iniOrbitINCText, handles.iniOrbitRAANText, handles.iniOrbitARGText, ...
                                 handles.iniOrbitMEANText, false, handles.orbitingAboutCombo, celBodyData);



function searchDurationText_Callback(hObject, eventdata, handles)
% hObject    handle to searchDurationText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of searchDurationText as text
%        str2double(get(hObject,'String')) returns contents of searchDurationText as a double


% --- Executes during object creation, after setting all properties.
function searchDurationText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to searchDurationText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function paramWgtSlider_Callback(hObject, eventdata, handles)
% hObject    handle to paramWgtSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    v1 = get(hObject,'Value');
    v2 = (v1+1)/2;
    v3 = 0.9*v2+0.1;
    
    timeWt = v3;
    dvWt = 1/timeWt;
    
    set(hObject,'UserData',[dvWt timeWt]);

% --- Executes during object creation, after setting all properties.
function paramWgtSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to paramWgtSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --------------------------------------------------------------------
function getOrbitFromKSPActiveVesselMenu_Callback(hObject, eventdata, handles)
% hObject    handle to getOrbitFromKSPActiveVesselMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    refBodyID = orbitPanelGetOrbitFromKSPTOTConnectActiveVesselCallBack(handles.iniOrbitSMAText, handles.iniOrbitECCText, handles.iniOrbitINCText, handles.iniOrbitRAANText, handles.iniOrbitARGText, handles.iniOrbitMEANText, handles.iniOrbitEPOCHText);
    set(handles.initialEpochText,'String',get(handles.iniOrbitEPOCHText,'String'));

    if(~isempty(refBodyID) && isnumeric(refBodyID))
        userData = get(handles.rendezvousGUI,'UserData');
        mainUserData = get(userData{1,1},'UserData');
        celBodyData = mainUserData{1,1};
        
        bodyInfo = getBodyInfoByNumber(refBodyID, celBodyData);
        value = findValueFromComboBox(bodyInfo.name, handles.orbitingAboutCombo);
        set(handles.orbitingAboutCombo,'Value',value);
        orbitingAboutCombo_Callback(handles.orbitingAboutCombo, [], handles);
    end

% --------------------------------------------------------------------
function getFinalOrbitFromKSPActiveVesselMenu_Callback(hObject, eventdata, handles)
% hObject    handle to getFinalOrbitFromKSPActiveVesselMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    refBodyID = orbitPanelGetOrbitFromKSPTOTConnectActiveVesselCallBack(handles.finOrbitSMAText, handles.finOrbitECCText, handles.finOrbitINCText, handles.finOrbitRAANText, handles.finOrbitARGText, handles.finOrbitMEANText, handles.finOrbitEPOCHText);

    if(~isempty(refBodyID) && isnumeric(refBodyID))
        userData = get(handles.rendezvousGUI,'UserData');
        mainUserData = get(userData{1,1},'UserData');
        celBodyData = mainUserData{1,1};
        
        bodyInfo = getBodyInfoByNumber(refBodyID, celBodyData);
        value = findValueFromComboBox(bodyInfo.name, handles.orbitingAboutCombo);
        set(handles.orbitingAboutCombo,'Value',value);
        orbitingAboutCombo_Callback(handles.orbitingAboutCombo, [], handles);
    end
