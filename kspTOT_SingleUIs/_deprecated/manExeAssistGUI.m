function varargout = manExeAssistGUI(varargin)
% MANEXEASSISTGUI MATLAB code for manExeAssistGUI.fig
%      MANEXEASSISTGUI, by itself, creates a new MANEXEASSISTGUI or raises the existing
%      singleton*.
%
%      H = MANEXEASSISTGUI returns the handle to a new MANEXEASSISTGUI or the handle to
%      the existing singleton*.
%
%      MANEXEASSISTGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MANEXEASSISTGUI.M with the given input arguments.
%
%      MANEXEASSISTGUI('Property','Value',...) creates a new MANEXEASSISTGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before manExeAssistGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to manExeAssistGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help manExeAssistGUI

% Last Modified by GUIDE v2.5 07-Jan-2017 14:29:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @manExeAssistGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @manExeAssistGUI_OutputFcn, ...
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


% --- Executes just before manExeAssistGUI is made visible.
function manExeAssistGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to manExeAssistGUI (see VARARGIN)

% Choose default command line output for manExeAssistGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%Possible fix for people with display issues.
checkForCharUnitsInGUI(hObject);

userData = cell(2);
mainGUIHandle = varargin{1};
userData{1,1} = mainGUIHandle;
userData{2,1} = [];
set(hObject, 'UserData', userData);
mainUserData = get(mainGUIHandle, 'UserData');
celBodyData = mainUserData{1,1};

% [~, arriveDepartNames] = genCBArriveDepartComboBoxStrs(mainGUIHandle);
allNames = ma_getSortedBodyNames(celBodyData);
departArriveComboString = char(cap1stLetter(allNames));
set(handles.orbitingAboutCombo,'String',departArriveComboString);
set(handles.orbitingAboutCombo, 'Value', 5);

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

% UIWAIT makes manExeAssistGUI wait for user response (see UIRESUME)
% uiwait(handles.manExeAssistGUI);


% --- Outputs from this function are returned to the command line.
function varargout = manExeAssistGUI_OutputFcn(hObject, eventdata, handles) 
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



function eSMAText_Callback(hObject, eventdata, handles)
% hObject    handle to eSMAText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eSMAText as text
%        str2double(get(hObject,'String')) returns contents of eSMAText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function eSMAText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eSMAText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function eEccText_Callback(hObject, eventdata, handles)
% hObject    handle to eEccText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eEccText as text
%        str2double(get(hObject,'String')) returns contents of eEccText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function eEccText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eEccText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function eIncText_Callback(hObject, eventdata, handles)
% hObject    handle to eIncText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eIncText as text
%        str2double(get(hObject,'String')) returns contents of eIncText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function eIncText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eIncText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function eRAANText_Callback(hObject, eventdata, handles)
% hObject    handle to eRAANText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eRAANText as text
%        str2double(get(hObject,'String')) returns contents of eRAANText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function eRAANText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eRAANText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function eArgText_Callback(hObject, eventdata, handles)
% hObject    handle to eArgText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eArgText as text
%        str2double(get(hObject,'String')) returns contents of eArgText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function eArgText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eArgText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function progradeDVText_Callback(hObject, eventdata, handles)
% hObject    handle to progradeDVText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of progradeDVText as text
%        str2double(get(hObject,'String')) returns contents of progradeDVText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function progradeDVText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to progradeDVText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function radialDVText_Callback(hObject, eventdata, handles)
% hObject    handle to radialDVText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of radialDVText as text
%        str2double(get(hObject,'String')) returns contents of radialDVText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function radialDVText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radialDVText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function normalDVText_Callback(hObject, eventdata, handles)
% hObject    handle to normalDVText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of normalDVText as text
%        str2double(get(hObject,'String')) returns contents of normalDVText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function normalDVText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to normalDVText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function burnTruText_Callback(hObject, eventdata, handles)
% hObject    handle to burnTruText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of burnTruText as text
%        str2double(get(hObject,'String')) returns contents of burnTruText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function burnTruText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to burnTruText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function thrustText_Callback(hObject, eventdata, handles)
% hObject    handle to thrustText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of thrustText as text
%        str2double(get(hObject,'String')) returns contents of thrustText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function thrustText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to thrustText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ispText_Callback(hObject, eventdata, handles)
% hObject    handle to ispText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ispText as text
%        str2double(get(hObject,'String')) returns contents of ispText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function ispText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ispText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function iniMassText_Callback(hObject, eventdata, handles)
% hObject    handle to iniMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of iniMassText as text
%        str2double(get(hObject,'String')) returns contents of iniMassText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function iniMassText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to iniMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in computeBurnTimingInfoButton.
function computeBurnTimingInfoButton_Callback(hObject, eventdata, handles)
% hObject    handle to computeBurnTimingInfoButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
guiUserData = get(handles.manExeAssistGUI,'UserData');
userData = get(guiUserData{1,1},'UserData');
celBodyData = userData{1,1};

contents = cellstr(get(handles.orbitingAboutCombo,'String'));
bodyName = contents{get(handles.orbitingAboutCombo,'Value')};
bodyInfo = celBodyData.(strtrim(lower(bodyName)));
bodyGmu = bodyInfo.gm;

errMsg = {};

eSMA = str2double(get(handles.eSMAText, 'String'));
enteredStr = get(handles.eSMAText,'String');
numberName = 'Elliptical orbit semi-major axis';
lb = 1;
ub = Inf;
isInt = false;
errMsg = validateNumber(eSMA, numberName, lb, ub, isInt, errMsg, enteredStr);

eEcc = str2double(get(handles.eEccText, 'String'));
enteredStr = get(handles.eEccText,'String');
numberName = 'Elliptical orbit eccentricity';
lb = 0;
ub = 0.99999;
isInt = false;
errMsg = validateNumber(eEcc, numberName, lb, ub, isInt, errMsg, enteredStr);

eInc = str2double(get(handles.eIncText, 'String'));
enteredStr = get(handles.eIncText,'String');
numberName = 'Elliptical orbit inclination';
lb = 0;
ub = 180;
isInt = false;
errMsg = validateNumber(eInc, numberName, lb, ub, isInt, errMsg, enteredStr);
eInc=eInc*pi/180;

eRAAN = str2double(get(handles.eRAANText, 'String'));
enteredStr = get(handles.eRAANText,'String');
numberName = 'Elliptical orbit RAAN';
lb = 0;
ub = 360;
isInt = false;
errMsg = validateNumber(eRAAN, numberName, lb, ub, isInt, errMsg, enteredStr);
eRAAN=eRAAN*pi/180;

eArg = str2double(get(handles.eArgText, 'String'));
enteredStr = get(handles.eArgText,'String');
numberName = 'Elliptical orbit argument of periapse';
lb = 0;
ub = 360;
isInt = false;
errMsg = validateNumber(eArg, numberName, lb, ub, isInt, errMsg, enteredStr);
eArg=eArg*pi/180;

progradeDV = str2double(get(handles.progradeDVText,'String'));
enteredStr = get(handles.progradeDVText,'String');
numberName = 'Prograde delta-v';
lb = -Inf;
ub = Inf;
isInt = false;
errMsg = validateNumber(progradeDV, numberName, lb, ub, isInt, errMsg, enteredStr);

radialDV = str2double(get(handles.radialDVText,'String'));
enteredStr = get(handles.radialDVText,'String');
numberName = 'Radial delta-v';
lb = -Inf;
ub = Inf;
isInt = false;
errMsg = validateNumber(radialDV, numberName, lb, ub, isInt, errMsg, enteredStr);

normalDV = str2double(get(handles.normalDVText,'String'));
enteredStr = get(handles.normalDVText,'String');
numberName = 'Normal delta-v';
lb = -Inf;
ub = Inf;
isInt = false;
errMsg = validateNumber(normalDV, numberName, lb, ub, isInt, errMsg, enteredStr);

iniMass = str2double(get(handles.iniMassText,'String'));
enteredStr = get(handles.iniMassText,'String');
numberName = 'Initial mass';
lb = 0.001;
ub = Inf;
isInt = false;
errMsg = validateNumber(iniMass, numberName, lb, ub, isInt, errMsg, enteredStr);
iniMass = iniMass * 1000;

isp = str2double(get(handles.ispText,'String'));
enteredStr = get(handles.ispText,'String');
numberName = 'Specific impulse';
lb = 1;
ub = Inf;
isInt = false;
errMsg = validateNumber(isp, numberName, lb, ub, isInt, errMsg, enteredStr);

thrust = str2double(get(handles.thrustText,'String'));
enteredStr = get(handles.thrustText,'String');
numberName = 'Thrust';
lb = 0.001;
ub = Inf;
isInt = false;
errMsg = validateNumber(thrust, numberName, lb, ub, isInt, errMsg, enteredStr);
thrust = thrust * 1000;

burnTru = str2double(get(handles.burnTruText,'String'));
enteredStr = get(handles.burnTruText,'String');
numberName = 'Burn true anomaly';
lb = 0;
ub = 360;
isInt = false;
errMsg = validateNumber(burnTru, numberName, lb, ub, isInt, errMsg, enteredStr);
burnTru = burnTru * pi/180;

if(isempty(errMsg))
    targetDV = norm([progradeDV, radialDV, normalDV]);
    if(targetDV <= 0)
        msgbox('Total magnitude of delta-v must be greater than 0.0 m/s.');
    else
        try
            g0 = 9.80665; %m/s^2;

            mdot = thrust/(isp*g0);

            halfDV = targetDV/2;

            dtAll = (iniMass/mdot) * (1 - exp(-targetDV/(isp*g0)));
            dtHalf = (iniMass/mdot) * (1 - exp(-halfDV/(isp*g0)));

            ePeriod = computePeriod(eSMA, bodyGmu);
            hRule = '---------------------------------------------';

            paddLen = 29;
            form = '%9.5f';
            burnInfoText{1} = ['Delta-V Maneuver Execution Information'];
            burnInfoText{end+1} = hRule;
            burnInfoText{end+1} = [paddStr('Total Delta-V = ',paddLen), num2str(targetDV/1000, form), ' km/s'];
            burnInfoText{end+1} = [paddStr('Prograde Delta-V = ',paddLen), num2str(progradeDV, form), ' m/s'];
            burnInfoText{end+1} = [paddStr('Radial Delta-V = ',paddLen), num2str(radialDV, form), ' m/s'];
            burnInfoText{end+1} = [paddStr('Orbit Normal Delta-V = ',paddLen), num2str(normalDV, form), ' m/s'];
            burnInfoText{end+1} = '---------------------';
            burnInfoText{end+1} = [paddStr('Burn Start Time = ',paddLen), 'T-', num2str(dtHalf, form), ' sec'];
            burnInfoText{end+1} = [paddStr('Burn End Time = ',paddLen), 'T+', num2str(-dtHalf+dtAll, form), ' sec'];
            burnInfoText{end+1} = [paddStr('Burn Duration = ',paddLen), num2str(dtAll, form), ' sec'];
            burnInfoText{end+1} = [paddStr('Orbit Period = ',paddLen), num2str(ePeriod, form), ' sec'];
            set(handles.dvManInfoText, 'String', burnInfoText);

            axes(handles.orbitDispAxes);
            cla(handles.orbitDispAxes,'reset');
            set(handles.orbitDispAxes,'XTickLabel',[]);
            set(handles.orbitDispAxes,'YTickLabel',[]);
            set(handles.orbitDispAxes,'ZTickLabel',[]);
            hold on;
            dRad = bodyInfo.radius;
            [X,Y,Z] = sphere(30);
            surf(dRad*X,dRad*Y,dRad*Z);
            colormap(bodyInfo.bodycolor);

            plotOrbit('k', eSMA, eEcc, eInc, eRAAN, eArg, 0, 2*pi, bodyGmu);

            burnMean = computeMeanFromTrueAnom(burnTru, eEcc);
            meanMotion = computeMeanMotion(eSMA, bodyGmu);
            dtHalfMean = burnMean - meanMotion*dtHalf;
            dtAllMean = dtHalfMean + meanMotion * dtAll;

            dtHalfTru = AngleZero2Pi(computeTrueAnomFromMean(dtHalfMean, eEcc));
            dtAllTru = AngleZero2Pi(computeTrueAnomFromMean(dtAllMean, eEcc));

            [rVectManNode,~]=getStatefromKepler(eSMA, eEcc, eInc, eRAAN, eArg, burnTru, bodyGmu);
            [rVectDtHalf,~]=getStatefromKepler(eSMA, eEcc, eInc, eRAAN, eArg, dtHalfTru, bodyGmu);
            [rVectDtAll,~]=getStatefromKepler(eSMA, eEcc, eInc, eRAAN, eArg, dtAllTru, bodyGmu);

            if(ePeriod < dtAll) 
                means = linspace(0, 2*pi, 100);
            else
                means = linspace(dtHalfMean, dtAllMean, 100);
            end

            x = [0];
            y = [0];
            z = [0];
            for(i=1:length(means))
                meanPoly = means(i);
                truPoly = computeTrueAnomFromMean(meanPoly, eEcc);
    %             disp(truPoly);
                rVect = getStatefromKepler(eSMA, eEcc, eInc, eRAAN, eArg, truPoly, bodyGmu);
                x(end+1) = rVect(1);
                y(end+1) = rVect(2);
                z(end+1) = rVect(3);
            end
            hold on;
            hPolyArc = fill3(x,y,z,'r');
            alpha(hPolyArc,0.5);

            hold on;
            hNode = plot3(rVectManNode(1),rVectManNode(2),rVectManNode(3),...
                            '-ro',...
                            'LineWidth',1.0,...
                            'MarkerEdgeColor','k',...
                            'MarkerFaceColor','r',...
                            'MarkerSize',10);
            
            hold on;
            hStart = plot3(rVectDtHalf(1),rVectDtHalf(2),rVectDtHalf(3),...
                            '-go',...
                            'LineWidth',1.0,...
                            'MarkerEdgeColor','k',...
                            'MarkerFaceColor','g',...
                            'MarkerSize',10);

            hold on;
            hEnd = plot3(rVectDtAll(1),rVectDtAll(2),rVectDtAll(3),...
                            '-bo',...
                            'LineWidth',1.0,...
                            'MarkerEdgeColor','k',...
                            'MarkerFaceColor','b',...
                            'MarkerSize',10);
            legendHandles = [hNode hStart hEnd hPolyArc];
            legendStrs = {'Maneuver Node Location', 'Burn Start Location', 'Approx. Burn End Location', 'Approx. Burn Arc'};
            legend(legendHandles, legendStrs, 'Location', 'SouthOutside', 'LineWidth', 1.5);


            grid on;
            axis equal;
            view(3);

            hold off;

        catch ME
            msgbox(ME.message);
        end
    end
else
    msgbox(errMsg,'Errors were found in inputs','error');
end

function dvManInfoText_Callback(hObject, eventdata, handles)
% hObject    handle to dvManInfoText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dvManInfoText as text
%        str2double(get(hObject,'String')) returns contents of dvManInfoText as a double


% --- Executes during object creation, after setting all properties.
function dvManInfoText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dvManInfoText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function getOrbitFromSFSFile_Callback(hObject, eventdata, handles)
% hObject    handle to getOrbitFromSFSFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
guiUserData = get(handles.manExeAssistGUI,'UserData');
mainGUIHandle = guiUserData{1,1};
orbitPanelGetOrbitFromSFSContextCallBack(mainGUIHandle, handles.eSMAText, handles.eEccText, handles.eIncText, handles.eRAANText, handles.eArgText);

% --------------------------------------------------------------------
function orbitContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to orbitContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function computeSysLvlProps_Callback(hObject, eventdata, handles)
% hObject    handle to computeSysLvlProps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
guiUserData = get(handles.manExeAssistGUI,'UserData');
[thrust, isp, enginesParams] = computeSysLvlParams(guiUserData{2,1});

if(~isempty(thrust) && ~isempty(isp))
    set(handles.thrustText, 'String', num2str(thrust));
    set(handles.ispText, 'String', num2str(isp));
    guiUserData{2,1} = enginesParams;
    set(handles.manExeAssistGUI,'UserData',guiUserData);
end


% --------------------------------------------------------------------
function getOrbitFromKSPMenu_Callback(hObject, eventdata, handles)
% hObject    handle to getOrbitFromKSPMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
orbitPanelGetOrbitFromKSPTOTConnectCallBack(handles.eSMAText, handles.eEccText, handles.eIncText, ...
                                            handles.eRAANText, handles.eArgText);

% --------------------------------------------------------------------
function copyOrbitToClipboardMenu_Callback(hObject, eventdata, handles)
% hObject    handle to copyOrbitToClipboardMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    guiUserData = get(handles.manExeAssistGUI,'UserData');
    userData = get(guiUserData{1,1},'UserData');
    celBodyData = userData{1,1};

    contents = cellstr(get(handles.orbitingAboutCombo,'String'));
    cbName = contents{get(handles.orbitingAboutCombo,'Value')};
    cBodyInfo = celBodyData.(lower(strtrim(cbName)));

    copyOrbitToClipboardFromText([], handles.eSMAText, handles.eEccText, ...
                                 handles.eIncText, handles.eRAANText, handles.eArgText, ...
                                 [], true, cBodyInfo.id);

% --------------------------------------------------------------------
function pasteOrbitFromClipboardMenu_Callback(hObject, eventdata, handles)
% hObject    handle to pasteOrbitFromClipboardMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    guiUserData = get(handles.manExeAssistGUI,'UserData');
    userData = get(guiUserData{1,1},'UserData');
    celBodyData = userData{1,1};

    pasteOrbitFromClipboard([], handles.eSMAText, handles.eEccText, ...
                                 handles.eIncText, handles.eRAANText, handles.eArgText, ...
                                 [], true, handles.orbitingAboutCombo, celBodyData);


% --------------------------------------------------------------------
function getOrbitFromKSPActiveVesselMenu_Callback(hObject, eventdata, handles)
% hObject    handle to getOrbitFromKSPActiveVesselMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
orbitPanelGetOrbitFromKSPTOTConnectActiveVesselCallBack(handles.eSMAText, handles.eEccText, handles.eIncText, ...
                                            handles.eRAANText, handles.eArgText);


% --------------------------------------------------------------------
function getBurnParamsFromKspActiveVesselMenu_Callback(hObject, eventdata, handles)
% hObject    handle to getBurnParamsFromKspActiveVesselMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    nodes = getManeuverNodesFromKSPActiveVessel();
    if(isempty(nodes))
        warndlg('Could not find any maneuver nodes on active vessel in KSP.  Are you running KSP in the flight scene with KSPTOTConnect loaded?','No Manuever Nodes Found');
        return;
    end
    
    node = 1;
    
    orbit = getSingularOrbitFromKSPTOTConnect([]);
    orbitBodyInfo = getBodyInfoStructFromOrbit([orbit{3:9}]);
    
    guiUserData = get(handles.manExeAssistGUI,'UserData');
    userData = get(guiUserData{1,1},'UserData');
    celBodyData = userData{1,1};
    bodyInfo = getBodyInfoByNumber(orbit{10}, celBodyData);
    
    [rVect, vVect] = getStateAtTime(orbitBodyInfo, nodes(node,1), bodyInfo.gm);
    [~, ~, ~, ~, ~, tru] = getKeplerFromState(rVect,vVect,bodyInfo.gm);
    
    set(handles.progradeDVText,'String', fullAccNum2Str(nodes(node,4)));
    set(handles.radialDVText,'String', fullAccNum2Str(nodes(node,2)));
    set(handles.normalDVText,'String', fullAccNum2Str(nodes(node,3)));
    set(handles.burnTruText,'String', fullAccNum2Str(rad2deg(tru)));
