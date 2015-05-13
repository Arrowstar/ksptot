function varargout = OptimalTwoBurnOrbitChange(varargin)
% OPTIMALTWOBURNORBITCHANGE MATLAB code for OptimalTwoBurnOrbitChange.fig
%      OPTIMALTWOBURNORBITCHANGE, by itself, creates a new OPTIMALTWOBURNORBITCHANGE or raises the existing
%      singleton*.
%
%      H = OPTIMALTWOBURNORBITCHANGE returns the handle to a new OPTIMALTWOBURNORBITCHANGE or the handle to
%      the existing singleton*.
%
%      OPTIMALTWOBURNORBITCHANGE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in OPTIMALTWOBURNORBITCHANGE.M with the given input arguments.
%
%      OPTIMALTWOBURNORBITCHANGE('Property','Value',...) creates a new OPTIMALTWOBURNORBITCHANGE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before OptimalTwoBurnOrbitChange_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to OptimalTwoBurnOrbitChange_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help OptimalTwoBurnOrbitChange

% Last Modified by GUIDE v2.5 07-Sep-2014 15:58:46

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @OptimalTwoBurnOrbitChange_OpeningFcn, ...
                   'gui_OutputFcn',  @OptimalTwoBurnOrbitChange_OutputFcn, ...
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


% --- Executes just before OptimalTwoBurnOrbitChange is made visible.
function OptimalTwoBurnOrbitChange_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to OptimalTwoBurnOrbitChange (see VARARGIN)

% Choose default command line output for OptimalTwoBurnOrbitChange
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

[~, ~, allNames] = genCBArriveDepartComboBoxStrs(mainGUIHandle);
allNamesComboString = char(cap1stLetter(allNames));
set(handles.orbitingAboutCombo,'String',allNamesComboString);
set(handles.orbitingAboutCombo,'Value',5);

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
bodyInfo = celBodyData.(lower(bodyName));
dRad = bodyInfo.radius;
[X,Y,Z] = sphere(30);
surf(dRad*X,dRad*Y,dRad*Z);
colormap(bodyInfo.bodycolor);
axis equal;
hold off;

% UIWAIT makes OptimalTwoBurnOrbitChange wait for user response (see UIRESUME)
% uiwait(handles.OptimalTwoBurnOrbitChangeGUI);


% --- Outputs from this function are returned to the command line.
function varargout = OptimalTwoBurnOrbitChange_OutputFcn(hObject, eventdata, handles) 
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


% --- Executes on button press in fixLoc1Checkbox.
function fixLoc1Checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to fixLoc1Checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of fixLoc1Checkbox
if(get(hObject,'Value')==1)
    set(handles.fixedTA1Text, 'Enable', 'on');
    set(handles.fixTA1RadioBtn, 'Enable', 'on');
    set(handles.fixedTp1Text, 'Enable', 'on');
    set(handles.fixTp1RadioBtn, 'Enable', 'on');
elseif(get(hObject,'Value')==0)
    set(handles.fixedTA1Text, 'Enable', 'off');
    set(handles.fixTA1RadioBtn, 'Enable', 'off');
    set(handles.fixedTp1Text, 'Enable', 'off');
    set(handles.fixTp1RadioBtn, 'Enable', 'off');
end


function fixedTA1Text_Callback(hObject, eventdata, handles)
% hObject    handle to fixedTA1Text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fixedTA1Text as text
%        str2double(get(hObject,'String')) returns contents of fixedTA1Text as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function fixedTA1Text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fixedTA1Text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in fixLoc2Checkbox.
function fixLoc2Checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to fixLoc2Checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of fixLoc2Checkbox
if(get(hObject,'Value')==1)
    set(handles.fixedTA2Text, 'Enable', 'on');
    set(handles.fixTA2RadioBtn, 'Enable', 'on');
    set(handles.fixedTp2Text, 'Enable', 'on');
    set(handles.fixTp2RadioBtn, 'Enable', 'on');
elseif(get(hObject,'Value')==0)
    set(handles.fixedTA2Text, 'Enable', 'off');
    set(handles.fixTA2RadioBtn, 'Enable', 'off');
    set(handles.fixedTp2Text, 'Enable', 'off');
    set(handles.fixTp2RadioBtn, 'Enable', 'off');
end

function fixedTA2Text_Callback(hObject, eventdata, handles)
% hObject    handle to fixedTA2Text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fixedTA2Text as text
%        str2double(get(hObject,'String')) returns contents of fixedTA2Text as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function fixedTA2Text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fixedTA2Text (see GCBO)
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


% --- Executes on button press in computeOptimal2BurnManButton.
function computeOptimal2BurnManButton_Callback(hObject, eventdata, handles)
% hObject    handle to computeOptimal2BurnManButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
userData = get(handles.OptimalTwoBurnOrbitChangeGUI,'UserData');
mainGUIUserData = get(userData{1,1},'UserData');
celBodyData = mainGUIUserData{1,1};

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

fixLoc1 = get(handles.fixLoc1Checkbox,'Value');
fixLoc2 = get(handles.fixLoc2Checkbox,'Value');

if(fixLoc1==1)
    burn1ParamsSel = get(get(handles.burn1ParamBtnGrp,'SelectedObject'),'Tag');
    if(strcmpi(burn1ParamsSel, 'fixTp1RadioBtn'))
        fixedTp1 = str2double(get(handles.fixedTp1Text,'String'));
        enteredStr = get(handles.fixedTp1Text,'String');
        numberName = 'Burn 1 Location (Delta-Time from Periapse)';
        lb = -Inf;
        ub = Inf;
        isInt = false;
        errMsg = validateNumber(fixedTp1, numberName, lb, ub, isInt, errMsg, enteredStr);
    else
        fixedTA1 = str2double(get(handles.fixedTA1Text,'String'));
        enteredStr = get(handles.fixedTA1Text,'String');
        numberName = 'Burn 1 Location (True Anomaly)';
        lb = 0;
        ub = 360;
        isInt = false;
        errMsg = validateNumber(fixedTA1, numberName, lb, ub, isInt, errMsg, enteredStr);
        fixedTA1 = AngleZero2Pi(deg2rad(fixedTA1));
    end
end

if(fixLoc2==1)
    burn2ParamsSel = get(get(handles.burn2ParamBtnGrp,'SelectedObject'),'Tag');
    if(strcmpi(burn2ParamsSel, 'fixTp2RadioBtn'))
        fixedTp2 = str2double(get(handles.fixedTp2Text,'String'));
        enteredStr = get(handles.fixedTp2Text,'String');
        numberName = 'Burn 2 Location (Delta-Time from Periapse)';
        lb = -Inf;
        ub = Inf;
        isInt = false;
        errMsg = validateNumber(fixedTp2, numberName, lb, ub, isInt, errMsg, enteredStr);
    else
        fixedTA2 = str2double(get(handles.fixedTA2Text,'String'));
        enteredStr = get(handles.fixedTA2Text,'String');
        numberName = 'Burn 2 Location (True Anomaly)';
        lb = 0;
        ub = 360;
        isInt = false;
        errMsg = validateNumber(fixedTA2, numberName, lb, ub, isInt, errMsg, enteredStr);
        fixedTA2 = AngleZero2Pi(deg2rad(fixedTA2));
    end
end

if(isempty(errMsg))
    try
        contents = cellstr(get(handles.orbitingAboutCombo,'String'));
        bodyName = contents{get(handles.orbitingAboutCombo,'Value')};
        bodyInfo = celBodyData.(lower(bodyName));
        gmuXfr = bodyInfo.gm;
        
        %initial conditions
        x0(1) = 0.0;
        x0(2) = 0.1;
        x0(3) = 500;

        [parentBodyInfo] = getParentBodyInfo(bodyInfo, celBodyData);

        [iniLB, iniUB, iniPeriod] = getOrbitTAPlotBnds(bodyInfo, parentBodyInfo, iniOrbit);
        [finLB, finUB, finPeriod] = getOrbitTAPlotBnds(bodyInfo, parentBodyInfo, finOrbit);

        lb = [iniLB, finLB, 0.1];
        ub = [iniUB, finUB, 2*max(iniPeriod,finPeriod)];

        objFunc = @(x) twoBurnOrbitChangeObjFunc(x, iniOrbit, finOrbit, gmuXfr);
        nonlcon = [];
        Aeq = [];
        beq = [];
        if(fixLoc1==0 && fixLoc2==0)
            nonlcon = [];
        else
            if(fixLoc1==1)
                if(strcmpi(burn1ParamsSel, 'fixTp1RadioBtn'))
                    fixedTA1 = getTAFromTimePastPeriapse(fixedTp1, iniOrbit(1), iniOrbit(2), gmuXfr);
                end
                Aeq(end+1,:) = [1 0 0];
                beq(end+1) = fixedTA1;
                Aeq(end+1,:) = [-1 0 0];
                beq(end+1) = -fixedTA1;
            end
            if(fixLoc2==1)
                if(strcmpi(burn2ParamsSel, 'fixTp2RadioBtn'))
                    fixedTA2 = getTAFromTimePastPeriapse(fixedTp2, finOrbit(1), finOrbit(2), gmuXfr);
                end
                Aeq(end+1,:) = [0 1 0];
                beq(end+1) = fixedTA2;
                Aeq(end+1,:) = [0 -1 0];
                beq(end+1) = -fixedTA2;
            end
        end

        [xOpt,~] = multiStartCommonRun('Finding Optimal 2 Burn Orbit Change Maneuvers...', 20, objFunc, x0, Aeq,beq, lb, ub, nonlcon);
        [dv, deltaV1, deltaV2, deltaV1R, deltaV2R, xfrOrbit, deltaV1NTW, deltaV2NTW] = objFunc(xOpt);

        burnTAINIOrbit = xOpt(1);
        burnTAXfrOrbit = xfrOrbit(7);
        
        form = '%9.3f';
        paddLen = 32;
        xferOrbitText{1} = ['Transfer Orbit about ', cap1stLetter(lower(bodyName))];
        printXferOrbitToTextbox(handles.xfrOrbitText, xferOrbitText, xfrOrbit, form, paddLen)  

        paddLen = 29;
        form = '%9.5f';
        burn1InfoText{1} = ['Transfer Orbit Injection Burn'];
        burn1InfoText{end+1} = '(Relative to initial orbit)';
        burn1InfoTextStr = printDVManeuverInfoToTextbox(handles.dvMan1InfoText, burn1InfoText, deltaV1NTW, burnTAINIOrbit, iniOrbit, gmuXfr, form, paddLen);

        paddLen = 29;
        form = '%9.5f';
        burn2InfoText{1} = ['Final Orbit Injection Burn'];
        burn2InfoText{end+1} = '(Relative to transfer orbit)';
        burn2InfoTextStr = printDVManeuverInfoToTextbox(handles.dvMan2InfoText, burn2InfoText, deltaV2NTW, burnTAXfrOrbit, xfrOrbit, gmuXfr, form, paddLen);

        plot2BurnOrbitChange(handles.orbitDispAxes, bodyInfo, iniOrbit, finOrbit, xfrOrbit, deltaV1, deltaV1R, deltaV2, deltaV2R, celBodyData);
        
        results = struct();
        
        results.burn1InfoTextStr = burn1InfoTextStr;
        results.burn2InfoTextStr = burn2InfoTextStr;
        results.bodyInfo = bodyInfo;
        results.iniOrbit = iniOrbit;
        results.finOrbit = finOrbit;
        results.xfrOrbit = xfrOrbit;
        results.deltaV1 = deltaV1;
        results.deltaV1R = deltaV1R;
        results.deltaV2 = deltaV2;
        results.deltaV2R = deltaV2R;
        
        userData = get(handles.OptimalTwoBurnOrbitChangeGUI,'UserData');
        userData{2,1} = results;
        set(handles.OptimalTwoBurnOrbitChangeGUI,'UserData',userData);
    catch ME
        msgbox(ME.message);
    end
else
    msgbox(errMsg,'Errors were found in orbit change calculation inputs','error');
end

function fixedTp1Text_Callback(hObject, eventdata, handles)
% hObject    handle to fixedTp1Text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fixedTp1Text as text
%        str2double(get(hObject,'String')) returns contents of fixedTp1Text as a double


% --- Executes during object creation, after setting all properties.
function fixedTp1Text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fixedTp1Text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function fixedTp2Text_Callback(hObject, eventdata, handles)
% hObject    handle to fixedTp2Text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fixedTp2Text as text
%        str2double(get(hObject,'String')) returns contents of fixedTp2Text as a double


% --- Executes during object creation, after setting all properties.
function fixedTp2Text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fixedTp2Text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function getFinalOrbitFromSFSFile_Callback(hObject, eventdata, handles)
% hObject    handle to getFinalOrbitFromSFSFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
userData = get(handles.OptimalTwoBurnOrbitChangeGUI,'UserData');
mainGUIHandle = userData{1,1};
orbitPanelGetOrbitFromSFSContextCallBack(mainGUIHandle, handles.finOrbitSMAText, handles.finOrbitECCText, handles.finOrbitINCText, handles.finOrbitRAANText, handles.finOrbitARGText);

% --------------------------------------------------------------------
function getFinalOrbitFromKSPTOTConnect_Callback(hObject, eventdata, handles)
% hObject    handle to getFinalOrbitFromSFSFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
orbitPanelGetOrbitFromKSPTOTConnectCallBack(handles.finOrbitSMAText, handles.finOrbitECCText, handles.finOrbitINCText, handles.finOrbitRAANText, handles.finOrbitARGText);

% --------------------------------------------------------------------
function getINIOrbitFromSFSFile_Callback(hObject, eventdata, handles)
% hObject    handle to getINIOrbitFromSFSFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
userData = get(handles.OptimalTwoBurnOrbitChangeGUI,'UserData');
mainGUIHandle = userData{1,1};
orbitPanelGetOrbitFromSFSContextCallBack(mainGUIHandle, handles.iniOrbitSMAText, handles.iniOrbitECCText, handles.iniOrbitINCText, handles.iniOrbitRAANText, handles.iniOrbitARGText);

% --------------------------------------------------------------------
function getINIOrbitFromKSPTOTConnect_Callback(hObject, eventdata, handles)
% hObject    handle to getINIOrbitFromSFSFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
orbitPanelGetOrbitFromKSPTOTConnectCallBack(handles.iniOrbitSMAText, handles.iniOrbitECCText, handles.iniOrbitINCText, handles.iniOrbitRAANText, handles.iniOrbitARGText);

function meanAnomText_Callback(hObject, eventdata, handles)
% hObject    handle to meanAnomText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of meanAnomText as text
%        str2double(get(hObject,'String')) returns contents of meanAnomText as a double


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


% --- Executes on button press in useMAEpochCheckbox.
function useMAEpochCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to useMAEpochCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of useMAEpochCheckbox
if(get(hObject,'Value')==1)
    set(handles.meanAnomText, 'Enable', 'on');
    set(handles.epochText, 'Enable', 'on');
else
    set(handles.meanAnomText, 'Enable', 'off');
    set(handles.epochText, 'Enable', 'off');
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



function edit26_Callback(hObject, eventdata, handles)
% hObject    handle to epochText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of epochText as text
%        str2double(get(hObject,'String')) returns contents of epochText as a double


% --- Executes during object creation, after setting all properties.
function edit26_CreateFcn(hObject, eventdata, handles)
% hObject    handle to epochText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in useMAEpochCheckbox.
function checkbox7_Callback(hObject, eventdata, handles)
% hObject    handle to useMAEpochCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of useMAEpochCheckbox


% --------------------------------------------------------------------
function enterUTAsDateTime_Callback(hObject, eventdata, handles)
% hObject    handle to enterUTAsDateTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
secUT = enterUTAsDateTimeGUI(str2double(get(gco, 'String')));
if(secUT >= 0)
    set(gco, 'String', num2str(secUT));
    epochText_Callback(handles.epochText, eventdata, handles);
end

% --------------------------------------------------------------------
function iniOrbitContMenuWithGetDateTime_Callback(hObject, eventdata, handles)
% hObject    handle to iniOrbitContMenuWithGetDateTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function generateReport_Callback(hObject, eventdata, handles)
% hObject    handle to generateReport (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hReport, handlesR] = genericReport(1, 'DOUBLE DELTA-V MANEUVER', 'TWO BURN ORBIT CHANGE');
userData = get(handles.OptimalTwoBurnOrbitChangeGUI,'UserData');
results = userData{2,1};

mainUserData = get(userData{1,1}, 'UserData');
celBodyData = mainUserData{1,1};

if(~isempty(results))
    set(handlesR.leftTextBox,'String',results.burn1InfoTextStr);
    set(handlesR.rightTextBox,'String',results.burn2InfoTextStr);
    plot2BurnOrbitChange(handlesR.leftAxis, results.bodyInfo, results.iniOrbit, results.finOrbit, results.xfrOrbit, results.deltaV1, results.deltaV1R, results.deltaV2, results.deltaV2R, celBodyData);
end


% --------------------------------------------------------------------
function uploadManeuver_Callback(hObject, eventdata, handles)
% hObject    handle to uploadManeuver (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
guiData = get(gco,'UserData');
uploadManeuverToKSP(guiData);


% --------------------------------------------------------------------
function copyOrbitToClipboardMenu2_Callback(hObject, eventdata, handles)
% hObject    handle to copyOrbitToClipboardMenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    copyOrbitToClipboardFromText([], handles.finOrbitSMAText, handles.finOrbitECCText, ...
                                 handles.finOrbitINCText, handles.finOrbitRAANText, handles.finOrbitARGText, ...
                                 [], true);

% --------------------------------------------------------------------
function pasteOrbitFromClipboardMenu2_Callback(hObject, eventdata, handles)
% hObject    handle to pasteOrbitFromClipboardMenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    pasteOrbitFromClipboard([], handles.finOrbitSMAText, handles.finOrbitECCText, ...
                                 handles.finOrbitINCText, handles.finOrbitRAANText, handles.finOrbitARGText, ...
                                 [], true);

% --------------------------------------------------------------------
function copyOrbitToClipboardMenu1_Callback(hObject, eventdata, handles)
% hObject    handle to copyOrbitToClipboardMenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    copyOrbitToClipboardFromText([], handles.iniOrbitSMAText, handles.iniOrbitECCText, ...
                                 handles.iniOrbitINCText, handles.iniOrbitRAANText, handles.iniOrbitARGText, ...
                                 [], true);

% --------------------------------------------------------------------
function pasteOrbitFromClipboardMenu1_Callback(hObject, eventdata, handles)
% hObject    handle to pasteOrbitFromClipboardMenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    pasteOrbitFromClipboard([], handles.iniOrbitSMAText, handles.iniOrbitECCText, ...
                                 handles.iniOrbitINCText, handles.iniOrbitRAANText, handles.iniOrbitARGText, ...
                                 [], true);
