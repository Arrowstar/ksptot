function varargout = flyByManeuverSequencer(varargin)
% FLYBYMANEUVERSEQUENCER MATLAB code for flyByManeuverSequencer.fig
%      FLYBYMANEUVERSEQUENCER, by itself, creates a new FLYBYMANEUVERSEQUENCER or raises the existing
%      singleton*.
%
%      H = FLYBYMANEUVERSEQUENCER returns the handle to a new FLYBYMANEUVERSEQUENCER or the handle to
%      the existing singleton*.
%
%      FLYBYMANEUVERSEQUENCER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FLYBYMANEUVERSEQUENCER.M with the given input arguments.
%
%      FLYBYMANEUVERSEQUENCER('Property','Value',...) creates a new FLYBYMANEUVERSEQUENCER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before flyByManeuverSequencer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to flyByManeuverSequencer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help flyByManeuverSequencer

% Last Modified by GUIDE v2.5 03-Dec-2013 19:16:58

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @flyByManeuverSequencer_OpeningFcn, ...
                   'gui_OutputFcn',  @flyByManeuverSequencer_OutputFcn, ...
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


% --- Executes just before flyByManeuverSequencer is made visible.
function flyByManeuverSequencer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to flyByManeuverSequencer (see VARARGIN)

% Choose default command line output for flyByManeuverSequencer
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

[~, arriveDepartNames] = genCBArriveDepartComboBoxStrs(mainGUIHandle);
departArriveComboString = char(cap1stLetter(arriveDepartNames));
set(handles.departBodyCombo,'String',departArriveComboString);
set(handles.flybyBodyCombo,'String',departArriveComboString);
set(handles.arrivalBodyCombo,'String',departArriveComboString);

hDepartBodyComboMain = findobj(mainGUIHandle,'Tag','departBodyCombo');
set(handles.departBodyCombo, 'Value', get(hDepartBodyComboMain, 'Value'));
hArriveBodyComboMain = findobj(mainGUIHandle,'Tag','arrivalBodyCombo');
set(handles.arrivalBodyCombo, 'Value', get(hArriveBodyComboMain, 'Value'));
set(handles.flybyBodyCombo, 'Value', 2);

launchWindowOpenText_Callback(handles.launchWindowOpenText, [], handles);
launchWindowCloseText_Callback(handles.launchWindowCloseText, [], handles);

departBodyCombo_Callback(handles.departBodyCombo, eventdata, handles);

hCentralBodyCombo = findobj(mainGUIHandle,'Tag','centralBodyCombo');
contents = cellstr(get(hCentralBodyCombo,'String'));
curSelCB = cap1stLetter(lower(contents{get(hCentralBodyCombo,'Value')}));
set(handles.xferOrbitTxtBoxLabel, 'String', [curSelCB, '-Centric Transfer Orbit']);

userData{1,2} = curSelCB;
set(hObject, 'UserData', userData);

hold on;
dispAxesFMS = handles.dispAxesFMS;
axes(dispAxesFMS);
set(dispAxesFMS,'XTickLabel',[]);
set(dispAxesFMS,'YTickLabel',[]);
set(dispAxesFMS,'ZTickLabel',[]);
grid on;
view(3);

celBodyData = mainUserData{1,1};
contents = cellstr(get(handles.departBodyCombo,'String'));
bodyName = contents{get(handles.departBodyCombo,'Value')};
bodyInfo = celBodyData.(lower(bodyName));
dRad = bodyInfo.radius;
[X,Y,Z] = sphere(30);
surf(dRad*X,dRad*Y,dRad*Z);
colormap(bodyInfo.bodycolor);
axis equal;
hold off;

% UIWAIT makes flyByManeuverSequencer wait for user response (see UIRESUME)
% uiwait(handles.flybyManSeqGUI);


% --- Outputs from this function are returned to the command line.
function varargout = flyByManeuverSequencer_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in departBodyCombo.
function departBodyCombo_Callback(hObject, eventdata, handles)
% hObject    handle to departBodyCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns departBodyCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from departBodyCombo
contents = cellstr(get(hObject,'String'));
bodyStr = cap1stLetter(lower(contents{get(hObject,'Value')}));
titleStr = ['Initial Elliptical Orbit Info (', bodyStr, ')'];
set(handles.iniEllipOrbitPanel, 'Title', titleStr);


% --- Executes during object creation, after setting all properties.
function departBodyCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to departBodyCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function launchWindowOpenText_Callback(hObject, eventdata, handles)
% hObject    handle to launchWindowOpenText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchWindowOpenText as text
%        str2double(get(hObject,'String')) returns contents of launchWindowOpenText as a double
newInput = get(hObject,'String');

newInput = attemptStrEval(newInput);

inputSec = str2double(newInput);
if(checkStrIsNumeric(newInput) && inputSec>=0.0)
    [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(inputSec);
    dateStr = formDateStr(year, day, hour, minute, sec);
    set(handles.launchWinOpenLabel, 'String', dateStr);
    set(hObject,'String', num2str(inputSec));
else
    
end

% --- Executes during object creation, after setting all properties.
function launchWindowOpenText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchWindowOpenText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function launchWindowCloseText_Callback(hObject, eventdata, handles)
% hObject    handle to launchWindowCloseText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchWindowCloseText as text
%        str2double(get(hObject,'String')) returns contents of launchWindowCloseText as a double
newInput = get(hObject,'String');

newInput = attemptStrEval(newInput);

inputSec = str2double(newInput);
if(checkStrIsNumeric(newInput) && inputSec>=0.0)
    [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(inputSec);
    dateStr = formDateStr(year, day, hour, minute, sec);
    set(handles.launchWinCloseLabel, 'String', dateStr);
    set(hObject,'String', num2str(inputSec));
else
    
end

% --- Executes during object creation, after setting all properties.
function launchWindowCloseText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchWindowCloseText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in flybyBodyCombo.
function flybyBodyCombo_Callback(hObject, eventdata, handles)
% hObject    handle to flybyBodyCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns flybyBodyCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from flybyBodyCombo


% --- Executes during object creation, after setting all properties.
function flybyBodyCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to flybyBodyCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in arrivalBodyCombo.
function arrivalBodyCombo_Callback(hObject, eventdata, handles)
% hObject    handle to arrivalBodyCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns arrivalBodyCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from arrivalBodyCombo


% --- Executes during object creation, after setting all properties.
function arrivalBodyCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to arrivalBodyCombo (see GCBO)
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



function hyperbolicOrbitsText_Callback(hObject, eventdata, handles)
% hObject    handle to hyperbolicOrbitsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hyperbolicOrbitsText as text
%        str2double(get(hObject,'String')) returns contents of hyperbolicOrbitsText as a double


% --- Executes during object creation, after setting all properties.
function hyperbolicOrbitsText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hyperbolicOrbitsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
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



function transferOrbitsText_Callback(hObject, eventdata, handles)
% hObject    handle to transferOrbitsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of transferOrbitsText as text
%        str2double(get(hObject,'String')) returns contents of transferOrbitsText as a double


% --- Executes during object creation, after setting all properties.
function transferOrbitsText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to transferOrbitsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in computeFlybyManSeqButton.
function computeFlybyManSeqButton_Callback(hObject, eventdata, handles)
% hObject    handle to computeFlybyManSeqButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
errMsg = {};

launchWindowOpenText = str2double(get(handles.launchWindowOpenText,'String'));
enteredStr = get(handles.launchWindowOpenText,'String');
numberName = 'Launch window open time';
lb = 0;
ub = Inf;
isInt = false;
errMsg = validateNumber(launchWindowOpenText, numberName, lb, ub, isInt, errMsg, enteredStr);

launchWindowCloseText = str2double(get(handles.launchWindowCloseText,'String'));
enteredStr = get(handles.launchWindowCloseText,'String');
numberName = 'Launch window close time';
lb = launchWindowOpenText+1;
ub = Inf;
isInt = false;
errMsg = validateNumber(launchWindowCloseText, numberName, lb, ub, isInt, errMsg, enteredStr);

contents = cellstr(get(handles.departBodyCombo,'String'));
departBody = contents{get(handles.departBodyCombo,'Value')};
contents = cellstr(get(handles.flybyBodyCombo,'String'));
flybyBody = contents{get(handles.flybyBodyCombo,'Value')};
contents = cellstr(get(handles.arrivalBodyCombo,'String'));
arriveBody = contents{get(handles.arrivalBodyCombo,'Value')};
errMsg = checkIfInputBodiesAreSame(departBody, flybyBody, errMsg, 'Depart body', 'flyby body');
errMsg = checkIfInputBodiesAreSame(flybyBody, arriveBody, errMsg, 'Flyby body', 'arrival body');
% errMsg = checkIfInputBodiesAreSame(departBody, arriveBody, errMsg, 'Depart body', 'arrival body');

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

eMA = [];
eEpoch = [];
if(get(handles.useMAEpochCheckbox, 'Value')==1)
    eMA = str2double(get(handles.meanAnomText,'String'));
    enteredStr = get(handles.meanAnomText,'String');
    numberName = 'Orbit Mean Anomaly';
    lb = 0;
    ub = 360;
    isInt = false;
    errMsg = validateNumber(eMA, numberName, lb, ub, isInt, errMsg, enteredStr);
    eMA=eMA*pi/180;

    eEpoch = str2double(get(handles.epochText,'String'));
    enteredStr = get(handles.epochText,'String');
    numberName = 'Orbit Epoch';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(eEpoch, numberName, lb, ub, isInt, errMsg, enteredStr);
end

disableRpConst = get(handles.disableFlyyConstraintsCheckbox, 'Value');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(isempty(errMsg))
    try
        userData = get(handles.flybyManSeqGUI,'UserData');
        mainGUIUserData = get(userData{1,1},'UserData');
        celBodyData = mainGUIUserData{1,1};
        cbName = lower(userData{1,2});

        ePeriod = computePeriod(eSMA, celBodyData.(lower(departBody)).gm);

        departBodyInfo = celBodyData.(lower(departBody));
        flybyBodyInfo = celBodyData.(lower(flybyBody));
        arrivalBodyInfo = celBodyData.(lower(arriveBody));
        gmuXfr = celBodyData.(cbName).gm;

        lnchWinOpen = str2double(get(handles.launchWindowOpenText, 'String'));
        lnchWinClose = str2double(get(handles.launchWindowCloseText, 'String'));

        period1 = computePeriod(departBodyInfo.sma, gmuXfr);
        period2 = computePeriod(flybyBodyInfo.sma, gmuXfr);
        period3 = computePeriod(arrivalBodyInfo.sma, gmuXfr);

        quant2Opt = mainGUIUserData{1,9}.quant2Opt;
        objFunc = @(x) findOptimalOneFlyByTraj(x, departBodyInfo, flybyBodyInfo, arrivalBodyInfo, gmuXfr, quant2Opt);
        nonlconWDates = @(x) flybyDVNonlconFunc(x, departBodyInfo, flybyBodyInfo, arrivalBodyInfo, gmuXfr, disableRpConst);
        nonlcon = @(x) nonlconWDates([x(1), x(1)+x(2), x(1)+x(2)+x(3)]);
        lb = [lnchWinOpen, 0, 0];
        ub = [lnchWinClose, 2*max(period1,period2), 2*max(period2, period3)];
        numVar = 3;
        
        usePara = 'always';
        if(matlabpool('size')==0)
            try
                h = msgbox('Attempting to start parallel computing workers...','modal');
                usePara = 'always';
                matlabpool('local',feature('numCores'));
                if(ishandle(h))
                    close(h);
                end
            catch ME
                if(ishandle(h))
                    close(h);
                end
                usePara='never';
                msgbox('Parallel mode start failed.  Running serially...');
            end
        end

        fminconOpts = {@fmincon, optimset('Algorithm', 'interior-point', 'TolX', eps, 'TolFun', eps)};
        opt = psooptimset('Display','diagnose','HybridFcn',fminconOpts,'PopulationSize',75,'Generations',75,'PlotFcns', {@psoplotbestf,@psoplotswarmsurf}, 'UseParallel', usePara);
        xOpt = pso(objFunc,numVar,[],[],[],[],lb,ub,nonlcon,opt);
        close(findobj('Name','Particle Swarm Optimization'));

        departUT = xOpt(1);
        flybyUT = xOpt(1) + xOpt(2);
        arriveUT = xOpt(1) + xOpt(2) + xOpt(3);

        [~, dvArr, flyByDVVect, flyByRp, xferOrbitIn, xferOrbitOut, flyByOrbitIn, flyByOrbitOut, departHypExVelVect, flyByDVVectNTW] = objFunc(xOpt);

        meanMotion = computeMeanMotion(eSMA, celBodyData.(lower(departBody)).gm);
        curMean = eMA;
        deltaT = 1;
        disp('----');
        while(abs(deltaT) > 0.1)
            disp(departUT);
            fun = @(x) computeDepartArriveDVFromEllipticTarget(eSMA, eEcc, eInc, eRAAN, eArg, x, departBodyInfo.gm, departHypExVelVect);
            nonlcon = @(x) hyperOrbitExcessVelConst(eSMA, eEcc, eInc, eRAAN, eArg, x, departBodyInfo.gm, departHypExVelVect, 1);

            [eTA,~] = multiStartCommonRun('Searching for departure orbit...',...
                                           50,...
                                           fun, pi, [], [], 0, 2*pi, nonlcon);
            disp(eTA*180/pi);
                                       
            if(isempty(eMA) && isempty(eEpoch))
                deltaT=0;
            else
                meanIdeal = AngleZero2Pi(computeMeanFromTrueAnom(eTA, eEcc));
                deltaT = (meanIdeal - curMean)/meanMotion;
                curMean = AngleZero2Pi(curMean + meanMotion*deltaT);
                departUT = departUT + deltaT;
                if(deltaT < 0 && (departUT < eEpoch))
                    departUT = departUT + ePeriod;
                end
                [~, departHypExVelVect] = findOptimalDepartureArrivalObjFunc(flybyUT, departUT, departBodyInfo, flybyBodyInfo, gmuXfr, 'departPArrivalDVRadioBtn');                
            end
        end
                                                                           
        [dVDepart, dVDepartVect, dVDepartVectNTW, eRDepartVect, hDepartOrbit, ~, ~] = fun(eTA);
        ePreDepartOrbit = [eSMA, eEcc, eInc, eRAAN, eArg];

        hPlotBtnGrp = findobj(handles.flybyManSeqGUI,'Tag','plotDisplayPanel');
        hTypeBtn = get(hPlotBtnGrp,'SelectedObject');
        plotType = get(hTypeBtn, 'Tag');
        switch(plotType)
            case 'plotXferOrbitRadio'
                plotFlybyXferTraj(handles.dispAxesFMS, departBodyInfo, flybyBodyInfo, arrivalBodyInfo, xferOrbitIn, xferOrbitOut, gmuXfr);
            case 'plotDepartOrbitRadio'
                plotBodyDepartOrbitForFlyby(handles.dispAxesFMS, departBodyInfo, ePreDepartOrbit, hDepartOrbit, dVDepartVect, eRDepartVect)
            case 'plotFlybyOrbitRadio'
                plotFlybyTraj(handles.dispAxesFMS, flybyBodyInfo, flyByOrbitIn, flyByOrbitOut, flyByDVVect, celBodyData);
        end
        drawnow;

        form = '%9.3f';
        paddLen = 32;
        printHyperOrbitsFMSToTextbox(handles.hyperbolicOrbitsText, departBody, flybyBody, hDepartOrbit, flyByOrbitIn, flyByOrbitOut, flyByRp, form, paddLen);

        paddLen = 30;
        form = '%9.3f';
        xferOrbitText = printXfrOrbitsFMSToTextbox(handles.transferOrbitsText, departBody, flybyBody, arriveBody, xferOrbitIn, xferOrbitOut, departUT, flybyUT, arriveUT, gmuXfr, form, paddLen);

        paddLen = 29;
        form = '%9.5f';
        
        burnInfoText = printDVManeuversFMSToTextbox(handles.dvManInfoText, departBody, flybyBody, dVDepartVectNTW, ePreDepartOrbit, eTA, departBodyInfo, flyByDVVectNTW,  form, paddLen);

        dv1ManTextUserData = get(handles.dvManInfoText,'UserData');
        dv1ManTextUserData(1) = 0;
        dv1ManTextUserData(2) = departUT;
        set(handles.dvManInfoText,'UserData',dv1ManTextUserData);
        
        results = struct();
        results.burnInfoText = burnInfoText;
        results.xferOrbitText = xferOrbitText;
        results.departBodyInfo = departBodyInfo;
        results.ePreDepartOrbit = ePreDepartOrbit;
        results.hDepartOrbit = hDepartOrbit;
        results.dVDepartVect = dVDepartVect;
        results.eRDepartVect = eRDepartVect;
        results.flybyBodyInfo = flybyBodyInfo;
        results.flyByOrbitIn = flyByOrbitIn;
        results.flyByOrbitOut = flyByOrbitOut;
        results.flyByDVVect = flyByDVVect;
        results.departUT = departUT;
        results.flybyUT = flybyUT;
        results.arriveUT = arriveUT;
        
        userData = get(handles.flybyManSeqGUI, 'UserData');
        
        userData{2,1} = departBodyInfo;
        userData{2,2} = flybyBodyInfo;
        userData{2,3} = arrivalBodyInfo;
        userData{2,4} = xferOrbitIn;
        userData{2,5} = xferOrbitOut;
        userData{2,6} = gmuXfr;
        userData{3,1} = ePreDepartOrbit;
        userData{3,2} = hDepartOrbit;
        userData{3,3} = dVDepartVect;
        userData{3,4} = eRDepartVect;
        userData{4,1} = flyByOrbitIn;
        userData{4,2} = flyByOrbitOut;
        userData{4,3} = flyByDVVect;
        
        userData{1,3} = results;
        set(handles.flybyManSeqGUI, 'UserData', userData);

        disp('Done!');
    catch ME
        msgbox(getReport(ME, 'extended'));
    end
else
    msgbox(errMsg,'Errors were found in flyby manuever sequencer inputs','error');
end

% --------------------------------------------------------------------
function enterUTAsDateTime_Callback(hObject, eventdata, handles)
% hObject    handle to enterUTAsDateTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
secUT = enterUTAsDateTimeGUI(str2double(get(gco, 'String')));
if(secUT >= 0)
    set(gco, 'String', num2str(secUT));
    launchWindowOpenText_Callback(handles.launchWindowOpenText, eventdata, handles);
    launchWindowCloseText_Callback(handles.launchWindowCloseText, eventdata, handles);
end


% --- Executes when selected object is changed in plotDisplayPanel.
function plotDisplayPanel_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in plotDisplayPanel 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
hPlotBtnGrp = findobj(handles.flybyManSeqGUI,'Tag','plotDisplayPanel');
hTypeBtn = get(hPlotBtnGrp,'SelectedObject');
plotType = get(hTypeBtn, 'Tag');

userData = get(handles.flybyManSeqGUI, 'UserData');
mainGUIUserData = get(userData{1,1},'UserData');
celBodyData = mainGUIUserData{1,1};
departBodyInfo = userData{2,1};
flybyBodyInfo = userData{2,2};
arrivalBodyInfo = userData{2,3};
xferOrbitIn = userData{2,4};
xferOrbitOut = userData{2,5};
gmuXfr = userData{2,6};
ePreDepartOrbit = userData{3,1};
hDepartOrbit = userData{3,2};
dVDepartVect = userData{3,3};
eRDepartVect = userData{3,4};
flyByOrbitIn = userData{4,1};
flyByOrbitOut = userData{4,2};
flyByDVVect = userData{4,3};

if(~isempty(departBodyInfo))
    switch(plotType)
        case 'plotXferOrbitRadio'
            plotFlybyXferTraj(handles.dispAxesFMS, departBodyInfo, flybyBodyInfo, arrivalBodyInfo, xferOrbitIn, xferOrbitOut, gmuXfr);
        case 'plotDepartOrbitRadio'
            plotBodyDepartOrbitForFlyby(handles.dispAxesFMS, departBodyInfo, ePreDepartOrbit, hDepartOrbit, dVDepartVect, eRDepartVect)
        case 'plotFlybyOrbitRadio'
            plotFlybyTraj(handles.dispAxesFMS, flybyBodyInfo, flyByOrbitIn, flyByOrbitOut, flyByDVVect, celBodyData);
    end    
end


% --------------------------------------------------------------------
function getOrbitFromSFSFile_Callback(hObject, eventdata, handles)
% hObject    handle to getOrbitFromSFSFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
userData = get(handles.flybyManSeqGUI, 'UserData');
mainGUIHandle = userData{1,1};
orbitPanelGetOrbitFromSFSContextCallBack(mainGUIHandle,handles.eSMAText, handles.eEccText, handles.eIncText, handles.eRAANText, handles.eArgText, handles.meanAnomText, handles.epochText);

% --------------------------------------------------------------------
function getOrbitFromKSPTOTConnect_Callback(hObject, eventdata, handles)
% hObject    handle to getOrbitFromSFSFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
orbitPanelGetOrbitFromKSPTOTConnectCallBack(handles.eSMAText, handles.eEccText, handles.eIncText, handles.eRAANText, handles.eArgText, handles.meanAnomText, handles.epochText);

% --- Executes on button press in disableFlyyConstraintsCheckbox.
function disableFlyyConstraintsCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to disableFlyyConstraintsCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of disableFlyyConstraintsCheckbox
value = get(hObject,'Value');
if(value == 1)
    set(hObject,'BackgroundColor','r');
    set(hObject,'ForegroundColor','w');
else
    set(hObject,'BackgroundColor',[0.941, 0.941, 0.941]);
    set(hObject,'ForegroundColor','k');
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


% --------------------------------------------------------------------
function generateReport_Callback(hObject, eventdata, handles)
% hObject    handle to generateReport (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hReport, handlesR] = genericReport(1, 'GRAVITY ASSIST MANEUVER', 'FLYBY MANEUVER SEQUENCER');
userData = get(handles.flybyManSeqGUI,'UserData');
results = userData{1,3};

mainUserData = get(userData{1,1}, 'UserData');
celBodyData = mainUserData{1,1};

if(~isempty(results))
    set(handlesR.leftTextBoxLabel,'String','DV Maneuvers Execution Details');
    set(handlesR.rightTextBoxLabel,'String','Transfer Orbit Details');
    
    set(handlesR.leftTextBox,'String', results.burnInfoText);
    set(handlesR.rightTextBox,'String', results.xferOrbitText);
    
    plotBodyDepartOrbitForFlyby(handlesR.leftAxis, results.departBodyInfo, results.ePreDepartOrbit, results.hDepartOrbit, results.dVDepartVect, results.eRDepartVect);
    plotFlybyTraj(handlesR.rightAxis, results.flybyBodyInfo, results.flyByOrbitIn, results.flyByOrbitOut, results.flyByDVVect, celBodyData);
    
    paddLen = 30;
    form = '%9.3f';
    set(handlesR.userEnteredNotesText,'String', printManeuverDatesFMS(results.departUT, results.flybyUT, results.arriveUT, form, paddLen));
end


% --------------------------------------------------------------------
function uploadManeuver_Callback(hObject, eventdata, handles)
% hObject    handle to uploadManeuver (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
guiData = get(gco,'UserData');
uploadManeuverToKSP(guiData);
