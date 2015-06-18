function varargout = computeDepartureGUI(varargin)
% COMPUTEDEPARTUREGUI MATLAB code for computeDepartureGUI.fig
%      COMPUTEDEPARTUREGUI, by itself, creates a new COMPUTEDEPARTUREGUI or raises the existing
%      singleton*.
%
%      H = COMPUTEDEPARTUREGUI returns the handle to a new COMPUTEDEPARTUREGUI or the handle to
%      the existing singleton*.
%
%      COMPUTEDEPARTUREGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in COMPUTEDEPARTUREGUI.M with the given input arguments.
%
%      COMPUTEDEPARTUREGUI('Property','Value',...) creates a new COMPUTEDEPARTUREGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before computeDepartureGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to computeDepartureGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help computeDepartureGUI

% Last Modified by GUIDE v2.5 11-Jun-2015 21:04:59

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @computeDepartureGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @computeDepartureGUI_OutputFcn, ...
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


% --- Executes just before computeDepartureGUI is made visible.
function computeDepartureGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to computeDepartureGUI (see VARARGIN)

% Choose default command line output for computeDepartureGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%Possible fix for people with display issues.
checkForCharUnitsInGUI(hObject);

%Process Inputs
userData = cell(10,10);
mainGUIFigure = varargin{1};
userData{1,1} = mainGUIFigure;
userData{1,2} = varargin{2};

set(hObject, 'UserData', userData);
mainGUIUserData = get(mainGUIFigure,'UserData');

options = mainGUIUserData{1,9};
deltaVStrName = deltaVTypeEnum(options.quant2Opt);
dvTypeStr =  {'Delta-V To Optimize:', deltaVStrName};
set(handles.dvtypelabel, 'String', dvTypeStr);

set(handles.iniOrbitPanel, 'Title', ['Initial Elliptical Orbit Information (', cap1stLetter(mainGUIUserData{2,1}), ')']);
set(handles.departTimeLabel, 'String', [cap1stLetter(mainGUIUserData{2,1}), ' Departure Time']);
set(handles.arriveTimeLabel, 'String', [cap1stLetter(mainGUIUserData{2,2}), ' Arrival Time']);

dcm_obj = datacursormode(mainGUIFigure);
info_struct = getCursorInfo(dcm_obj);
if(mainGUIUserData{2,7} >= 0 && mainGUIUserData{2,8} >= 0)
    departUT = mainGUIUserData{2,7};
    arriveUT = mainGUIUserData{2,8};
    
    set(handles.departTimeText, 'String', num2str(departUT));
    set(handles.arrivalTimeText, 'String', num2str(arriveUT));

    departTimeText_Callback(handles.departTimeText, eventdata, handles);
    arrivalTimeText_Callback(handles.arrivalTimeText, eventdata, handles);
elseif(not(isempty(info_struct)))
    dcmPos = info_struct(1).Position;
    xpos = dcmPos(1);
    ypos = dcmPos(2);

    departUT = convertYearDayHrMnSec2Sec(1, xpos+1, 0, 0, 0);
    arriveUT = convertYearDayHrMnSec2Sec(1, ypos+1, 0, 0, 0);

    set(handles.departTimeText, 'String', num2str(departUT));
    set(handles.arrivalTimeText, 'String', num2str(arriveUT));

    departTimeText_Callback(handles.departTimeText, eventdata, handles);
    arrivalTimeText_Callback(handles.arrivalTimeText, eventdata, handles);
end

% UIWAIT makes computeDepartureGUI wait for user response (see UIRESUME)
% uiwait(handles.computeDepartBurnFig);


% --- Outputs from this function are returned to the command line.
function varargout = computeDepartureGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function departTimeText_Callback(hObject, eventdata, handles)
% hObject    handle to departTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of departTimeText as text
%        str2double(get(hObject,'String')) returns contents of departTimeText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
inputSec = str2double(newInput);
if(checkStrIsNumeric(newInput) && inputSec>=0.0)
    [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(inputSec);
    dateStr = formDateStr(year, day, hour, minute, sec);
    set(handles.departTimeDateText, 'String', dateStr);
    set(hObject,'String', num2str(inputSec));
else
    
end

% --- Executes during object creation, after setting all properties.
function departTimeText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to departTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function arrivalTimeText_Callback(hObject, eventdata, handles)
% hObject    handle to arrivalTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of arrivalTimeText as text
%        str2double(get(hObject,'String')) returns contents of arrivalTimeText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
inputSec = str2double(newInput);
if(checkStrIsNumeric(newInput) && inputSec>=0.0)
    [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(inputSec);
    dateStr = formDateStr(year, day, hour, minute, sec);
    set(handles.arrivalTimeDateText, 'String', dateStr);
    set(hObject,'String', num2str(inputSec));
else
    
end

% --- Executes during object creation, after setting all properties.
function arrivalTimeText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to arrivalTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in selectDepartArrivePointBtn.
function selectDepartArrivePointBtn_Callback(hObject, eventdata, handles)
% hObject    handle to selectDepartArrivePointBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    fig = handles.computeDepartBurnFig;
    userData = get(fig, 'UserData');
    hAxis = userData{1,2};
    axes(hAxis);
catch ME
    msgbox({'The following error occured while attempting to select the departure/arrival dates:', '', ME.message}, 'Error!', 'error');
    return;
end

[departUT,arriveUT] = ginputax(hAxis,1);

[~, ~, secInDay, ~] = getSecondsInVariousTimeUnits();
departUTSec = departUT*secInDay;
arriveUTSec = arriveUT*secInDay;
set(handles.departTimeText, 'String', num2str(departUTSec));
set(handles.arrivalTimeText, 'String', num2str(arriveUTSec));

departTimeText_Callback(handles.departTimeText, eventdata, handles);
arrivalTimeText_Callback(handles.arrivalTimeText, eventdata, handles);
figure(handles.computeDepartBurnFig);


function eSMA_Callback(hObject, eventdata, handles)
% hObject    handle to eSMA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eSMA as text
%        str2double(get(hObject,'String')) returns contents of eSMA as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function eSMA_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eSMA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function eEcc_Callback(hObject, eventdata, handles)
% hObject    handle to eEcc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eEcc as text
%        str2double(get(hObject,'String')) returns contents of eEcc as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function eEcc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eEcc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function eInc_Callback(hObject, eventdata, handles)
% hObject    handle to eInc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eInc as text
%        str2double(get(hObject,'String')) returns contents of eInc as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function eInc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eInc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function eRAAN_Callback(hObject, eventdata, handles)
% hObject    handle to eRAAN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eRAAN as text
%        str2double(get(hObject,'String')) returns contents of eRAAN as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function eRAAN_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eRAAN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function eArg_Callback(hObject, eventdata, handles)
% hObject    handle to eArg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eArg as text
%        str2double(get(hObject,'String')) returns contents of eArg as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function eArg_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eArg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in computeDepartBurn.
function computeDepartBurn_Callback(hObject, eventdata, handles)
% hObject    handle to computeDepartBurn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

userData = get(handles.computeDepartBurnFig, 'UserData');
userDataMain = get(userData{1,1},'UserData');

departBody = userDataMain{2,1};
arrivalBody = userDataMain{2,2};

errMsg = {};

eEcc = str2double(get(handles.eEcc,'String'));
enteredStr = get(handles.eEcc,'String');
numberName = 'Orbit eccentricity';
lb = 0;
ub = Inf;
isInt = false;
errMsg = validateNumber(eEcc, numberName, lb, ub, isInt, errMsg, enteredStr);

if(not(isempty(errMsg))) 
    msgbox(errMsg,'Errors were found in departure burn calculation inputs','error');
    return;
end

departUT = str2double(get(handles.departTimeText,'String'));
enteredStr = get(handles.departTimeText,'String');
numberName = 'Departure time';
lb = 0;
ub = Inf;
isInt = false;
errMsg = validateNumber(departUT, numberName, lb, ub, isInt, errMsg, enteredStr);

arrivalUT = str2double(get(handles.arrivalTimeText,'String'));
enteredStr = get(handles.arrivalTimeText,'String');
numberName = 'Arrival time';
lb = 0;
ub = Inf;
isInt = false;
errMsg = validateNumber(arrivalUT, numberName, lb, ub, isInt, errMsg, enteredStr);

eSMA = str2double(get(handles.eSMA,'String'));
enteredStr = get(handles.eSMA,'String');
if(eEcc < 1.0)
    lb = 1;
    ub = Inf;
    numberName = 'Eccentric orbit semi-major axis';
else
    lb = -Inf;
    ub = -1;
    numberName = 'Hyperbolic orbit semi-major axis';
end
isInt = false;
errMsg = validateNumber(eSMA, numberName, lb, ub, isInt, errMsg, enteredStr);

eInc = str2double(get(handles.eInc,'String'));
enteredStr = get(handles.eInc,'String');
numberName = 'Orbit inclination';
lb = 0;
ub = 180;
isInt = false;
errMsg = validateNumber(eInc, numberName, lb, ub, isInt, errMsg, enteredStr);
eInc=eInc*pi/180;

eRAAN = str2double(get(handles.eRAAN,'String'));
enteredStr = get(handles.eRAAN,'String');
numberName = 'Orbit RAAN';
lb = 0;
ub = 360;
isInt = false;
errMsg = validateNumber(eRAAN, numberName, lb, ub, isInt, errMsg, enteredStr);
eRAAN=eRAAN*pi/180;

eArg = str2double(get(handles.eArg,'String'));
enteredStr = get(handles.eArg,'String');
numberName = 'Orbit argument of periapse';
lb = 0;
ub = 360;
isInt = false;
errMsg = validateNumber(eArg, numberName, lb, ub, isInt, errMsg, enteredStr);
eArg=eArg*pi/180;

eMA = [];
eEpoch = [];
if(get(handles.useMAEpochCheckbox, 'Value')==1)
    eMA = str2double(get(handles.eMeanAnom,'String'));
    enteredStr = get(handles.eMeanAnom,'String');
    numberName = 'Orbit Mean Anomaly';
    lb = 0;
    ub = 360;
    isInt = false;
    errMsg = validateNumber(eMA, numberName, lb, ub, isInt, errMsg, enteredStr);
    eMA=eMA*pi/180;

    eEpoch = str2double(get(handles.eEpoch,'String'));
    enteredStr = get(handles.eEpoch,'String');
    numberName = 'Orbit Epoch';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(eEpoch, numberName, lb, ub, isInt, errMsg, enteredStr);
end

gmuXfr = userDataMain{2,5};
cbName = userDataMain{2,6};
options = userDataMain{1,9};

if(isempty(errMsg))
    try
        computeDeparture(userDataMain{1,1}, departBody, arrivalBody, departUT, arrivalUT, eSMA, eEcc, eInc, eRAAN, eArg, gmuXfr, cbName, options, eMA, eEpoch);
    catch ME
        msgbox(ME.message);
    end
else
    msgbox(errMsg,'Errors were found in departure burn calculation inputs','error');
end

% --------------------------------------------------------------------
function enterUTAsDateTime_Callback(hObject, eventdata, handles)
% hObject    handle to enterUTAsDateTimePlusOptimizeDeparture (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
secUT = enterUTAsDateTimeGUI(str2double(get(gco, 'String')));
if(secUT >= 0)
    set(gco, 'String', num2str(secUT));
    departTimeText_Callback(handles.departTimeText, eventdata, handles);
    arrivalTimeText_Callback(handles.arrivalTimeText, eventdata, handles);
end


% --------------------------------------------------------------------
function findOptimalArrivalForInputDeparture_Callback(hObject, eventdata, handles)
% hObject    handle to findOptimalArrivalForInputDeparture (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

userData = get(handles.computeDepartBurnFig, 'UserData');
userData = get(userData{1,1},'UserData');
options = userData{1,9};

departBodyInfo = userData{1,1}.(userData{2,1});
arrivalBodyInfo = userData{1,1}.(userData{2,2});
gmu = userData{1,1}.(userData{2,6}).gm;

departBodyMeanMotion = computeMeanMotion(departBodyInfo.sma, gmu);
arrivalBodyMeanMotion = computeMeanMotion(arrivalBodyInfo.sma, gmu);
synPeriod = computeSynodicPeriod(departBodyMeanMotion, arrivalBodyMeanMotion);
% numSynPeriods = userData{1,9}.porkchopNumSynPeriods;

errMsg={};

departUT = str2double(get(handles.departTimeText,'String'));
enteredStr = get(handles.departTimeText,'String');
numberName = 'Departure time';
lb = 0;
ub = Inf;
isInt = false;
errMsg = validateNumber(departUT, numberName, lb, ub, isInt, errMsg, enteredStr);

if(isempty(errMsg))
    objFunc = @(arrivalTime) findOptimalDepartureArrivalObjFunc(arrivalTime, departUT, departBodyInfo, arrivalBodyInfo, gmu, options.quant2Opt);
    atLB = departUT+1000;
    atUB = atLB + (10)*synPeriod;
    atCenter = mean([atLB, atUB]);

    numIter = 75;
    [arriveUT,dv] = multiStartCommonRun('Searching for best arrival time...',...
                                         numIter, objFunc, atCenter, [], [], atLB, atUB, []);
    
    [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(arriveUT);
    arriveDateStr = formDateStr(year, day, hour, minute, sec);
    msgBoxStr = {['Solution found!'], ...
                 ['New arrival date: ', arriveDateStr], ...
                 ['Delta-V: ', num2str(dv), ' km/s']};
    msgbox(msgBoxStr, 'Arrival Date Optimization Complete', 'help');

    set(handles.arrivalTimeText, 'String', num2str(arriveUT));
    arrivalTimeText_Callback(handles.arrivalTimeText, eventdata, handles);
else
    msgbox(errMsg,'Errors were found while starting to compute best arrival time','error');
end


% --------------------------------------------------------------------
function findOptimalDepartureForInputArrival_Callback(hObject, eventdata, handles)
% hObject    handle to findOptimalDepartureForInputArrival (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

userData = get(handles.computeDepartBurnFig, 'UserData');
userData = get(userData{1,1},'UserData');
options = userData{1,9};

departBodyInfo = userData{1,1}.(userData{2,1});
arrivalBodyInfo = userData{1,1}.(userData{2,2});
gmu = userData{1,1}.(userData{2,6}).gm;

departBodyMeanMotion = computeMeanMotion(departBodyInfo.sma, gmu);
arrivalBodyMeanMotion = computeMeanMotion(arrivalBodyInfo.sma, gmu);
synPeriod = computeSynodicPeriod(departBodyMeanMotion, arrivalBodyMeanMotion);
% numSynPeriods = userData{1,9}.porkchopNumSynPeriods;

errMsg={};

arrivalUT = str2double(get(handles.arrivalTimeText,'String'));
enteredStr = get(handles.arrivalTimeText,'String');
numberName = 'Arrival time';
lb = 0;
ub = Inf;
isInt = false;
errMsg = validateNumber(arrivalUT, numberName, lb, ub, isInt, errMsg, enteredStr);

departUT = str2double(get(handles.departTimeText,'String'));
enteredStr = get(handles.departTimeText,'String');
numberName = 'Departure time';
lb = 0;
ub = arrivalUT;
isInt = false;
errMsg = validateNumber(departUT, numberName, lb, ub, isInt, errMsg, enteredStr);

if(isempty(errMsg))

    objFunc = @(departUT) findOptimalDepartureArrivalObjFunc(arrivalUT, departUT, departBodyInfo, arrivalBodyInfo, gmu, options.quant2Opt);
    dtUB = arrivalUT-100;
    dtLB = max(dtUB - (10)*synPeriod, departUT);
    dtCenter = mean([dtLB, dtUB]);

    numIter = 75;   
    [departUT,dv] = multiStartCommonRun('Searching for best departure time...',...
                                         numIter, objFunc, dtCenter, [], [], dtLB, dtUB, []);
    
    [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(departUT);
    arriveDateStr = formDateStr(year, day, hour, minute, sec);
    msgBoxStr = {['Solution found!'], ...
                 ['New departure date: ', arriveDateStr], ...
                 ['Delta-V: ', num2str(dv), ' km/s']};
    msgbox(msgBoxStr, 'Departure Date Optimization Complete', 'help');

    set(handles.departTimeText, 'String', num2str(departUT));
    departTimeText_Callback(handles.departTimeText, eventdata, handles);
    
else
    msgbox(errMsg,'Errors were found while starting to compute best arrival time','error');
end


% --------------------------------------------------------------------
function findEarliestArrivalForDeltaV_Callback(hObject, eventdata, handles)
% hObject    handle to findEarliestArrivalForDeltaV (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
userData = get(handles.computeDepartBurnFig, 'UserData');
userData = get(userData{1,1},'UserData');
options = userData{1,9};

departBodyInfo = userData{1,1}.(userData{2,1});
arrivalBodyInfo = userData{1,1}.(userData{2,2});
gmu = userData{1,1}.(userData{2,6}).gm;

departBodyMeanMotion = computeMeanMotion(departBodyInfo.sma, gmu);
arrivalBodyMeanMotion = computeMeanMotion(arrivalBodyInfo.sma, gmu);
synPeriod = computeSynodicPeriod(departBodyMeanMotion, arrivalBodyMeanMotion);
% numSynPeriods = userData{1,9}.porkchopNumSynPeriods;

errMsg={};

departUT = str2double(get(handles.departTimeText,'String'));
enteredStr = get(handles.departTimeText,'String');
numberName = 'Departure time';
lb = 0;
ub = Inf;
isInt = false;
errMsg = validateNumber(departUT, numberName, lb, ub, isInt, errMsg, enteredStr);

if(isempty(errMsg))
    objFunc = @(x) x;
    lb = departUT+100;
    ub = Inf;

    [maxDV, flag] = maxDeltaVInputGUI(options);
    if(flag == -1)
        return;
    end

    dvFunc = @(arrivalUT, departUT) findOptimalDepartureArrivalObjFunc(arrivalUT, departUT, departBodyInfo, arrivalBodyInfo, gmu, options.quant2Opt);
    nonlcon = @(arrivalUT) findEarliestArrivalNonlconFun(arrivalUT, departUT, dvFunc, maxDV);

    dtLB=lb;
    dtUB = lb+10*synPeriod;
    dtCenter = mean([dtLB, dtUB]);
    waitBarStr = 'Searching for earliest arrival time...';

    numIter = 75;   
    [arriveUT, ~, exitflag,output] = multiStartCommonRun(waitBarStr, numIter, objFunc, dtCenter, [], [], lb, ub, nonlcon);
    dv = dvFunc(arriveUT, departUT);
    
    [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(arriveUT);
    arriveDateStr = formDateStr(year, day, hour, minute, sec);
    msgBoxStr = {['Solution found!'], ...
                 ['New arrival date: ', arriveDateStr], ...
                 ['Delta-V: ', num2str(dv), ' km/s']};
	if(exitflag<1)
        msgBoxStr{end+1} = '';
        msgBoxStr{end+1} = 'Solver warning message:';
        msgBoxStr{end+1} = '';
        msgBoxStr{end+1} = output.message;
    end
    msgbox(msgBoxStr, 'Arrival Date Optimization Complete', 'help');

    set(handles.arrivalTimeText, 'String', num2str(arriveUT));
    arrivalTimeText_Callback(handles.arrivalTimeText, eventdata, handles);
else
    msgbox(errMsg,'Errors were found while starting to compute earliest arrival time','error');
end



% --------------------------------------------------------------------
function findEarliestArrivalForDeltaVAdjustDeparture_Callback(hObject, eventdata, handles)
% hObject    handle to findEarliestArrivalForDeltaVAdjustDeparture (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
userData = get(handles.computeDepartBurnFig, 'UserData');
userData = get(userData{1,1},'UserData');
options = userData{1,9};

departBodyInfo = userData{1,1}.(userData{2,1});
arrivalBodyInfo = userData{1,1}.(userData{2,2});
gmu = userData{1,1}.(userData{2,6}).gm;

departBodyMeanMotion = computeMeanMotion(departBodyInfo.sma, gmu);
arrivalBodyMeanMotion = computeMeanMotion(arrivalBodyInfo.sma, gmu);
synPeriod = computeSynodicPeriod(departBodyMeanMotion, arrivalBodyMeanMotion);
% numSynPeriods = userData{1,9}.porkchopNumSynPeriods;

errMsg={};

departUT = str2double(get(handles.departTimeText,'String'));
enteredStr = get(handles.departTimeText,'String');
numberName = 'Departure time';
lb = 0;
ub = Inf;
isInt = false;
errMsg = validateNumber(departUT, numberName, lb, ub, isInt, errMsg, enteredStr);

if(isempty(errMsg))
    objFunc = @(x) x(1);
    lb = [departUT+100, departUT];
    ub = [departUT+3*synPeriod departUT+3*synPeriod];

    [maxDV, flag] = maxDeltaVInputGUI(options);
    if(flag == -1)
        return;
    end

    dvFunc = @(arrivalUT, departUT) findOptimalDepartureArrivalObjFunc(arrivalUT, departUT, departBodyInfo, arrivalBodyInfo, gmu, options.quant2Opt);
    nonlconPre = @(arrivalUT, departUT) findEarliestArrivalNonlconFun(arrivalUT, departUT, dvFunc, maxDV);
    nonlcon = @(x) nonlconPre(x(1), x(2));
    
    dtCenter = lb;
    waitBarStr = 'Searching for earliest arrival time...';

    A= [-1 1];
    b = [0];
    numIter = 75;   
    [x, ~, exitflag,output] = multiStartCommonRun(waitBarStr, numIter, objFunc, dtCenter, A, b, lb, ub, nonlcon);
    dv = dvFunc(x(1), x(2));
    arriveUT = x(1);
    departUT = x(2);
    
    [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(arriveUT);
    arriveDateStr = formDateStr(year, day, hour, minute, sec);
    [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(departUT);
    departDateStr = formDateStr(year, day, hour, minute, sec);
    msgBoxStr = {['Solution found!'], ...
                 ['New departure date: ', departDateStr], ...
                 ['New arrival date: ', arriveDateStr], ...
                 ['Delta-V: ', num2str(dv), ' km/s']};
	if(exitflag<1)
        msgBoxStr{end+1} = '';
        msgBoxStr{end+1} = 'Solver warning message:';
        msgBoxStr{end+1} = '';
        msgBoxStr{end+1} = output.message;
    end
    msgbox(msgBoxStr, 'Arrival Date Optimization Complete', 'help');

    set(handles.arrivalTimeText, 'String', num2str(arriveUT));
    arrivalTimeText_Callback(handles.arrivalTimeText, eventdata, handles);
    
    set(handles.departTimeText, 'String', num2str(departUT));
    departTimeText_Callback(handles.departTimeText, eventdata, handles);
else
    msgbox(errMsg,'Errors were found while starting to compute earliest arrival time','error');
end


% --------------------------------------------------------------------
function getOrbitFromSFSFile_Callback(hObject, eventdata, handles)
% hObject    handle to getOrbitFromSFSFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
userData = get(handles.computeDepartBurnFig, 'UserData');
mainGUIHandle = userData{1,1};
orbitPanelGetOrbitFromSFSContextCallBack(mainGUIHandle,handles.eSMA, handles.eEcc, handles.eInc, handles.eRAAN, handles.eArg, handles.eMeanAnom, handles.eEpoch);


% --------------------------------------------------------------------
function getOrbitFromKSPTOTConnect_Callback(hObject, eventdata, handles)
% hObject    handle to getOrbitFromSFSFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
orbitPanelGetOrbitFromKSPTOTConnectCallBack(handles.eSMA, handles.eEcc, handles.eInc, handles.eRAAN, handles.eArg, handles.eMeanAnom, handles.eEpoch);


% --- Executes on button press in useMAEpochCheckbox.
function useMAEpochCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to useMAEpochCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of useMAEpochCheckbox
if(get(hObject,'Value')==1)
    set(handles.eMeanAnom, 'Enable', 'on');
    set(handles.eEpoch, 'Enable', 'on');
else
    set(handles.eMeanAnom, 'Enable', 'off');
    set(handles.eEpoch, 'Enable', 'off');
end


function eMeanAnom_Callback(hObject, eventdata, handles)
% hObject    handle to eMeanAnom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eMeanAnom as text
%        str2double(get(hObject,'String')) returns contents of eMeanAnom as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function eMeanAnom_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eMeanAnom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function eEpoch_Callback(hObject, eventdata, handles)
% hObject    handle to eEpoch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eEpoch as text
%        str2double(get(hObject,'String')) returns contents of eEpoch as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function eEpoch_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eEpoch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function getUTFromKSP_Callback(hObject, eventdata, handles)
% hObject    handle to getUTFromKSP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
secUT = readDoublesFromKSPTOTConnect('GetUT', '', true);
if(secUT >= 0)
    set(gco, 'String', num2str(secUT));
    departTimeText_Callback(handles.departTimeText, eventdata, handles);
    arrivalTimeText_Callback(handles.arrivalTimeText, eventdata, handles);
end


% --------------------------------------------------------------------
function copyOrbitToClipboardMenu_Callback(hObject, eventdata, handles)
% hObject    handle to copyOrbitToClipboardMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    copyOrbitToClipboardFromText(handles.eEpoch, handles.eSMA, handles.eEcc, ...
                                 handles.eInc, handles.eRAAN, handles.eArg, ...
                                 handles.eMeanAnom, false);

% --------------------------------------------------------------------
function pasteOrbitFromClipboardMenu_Callback(hObject, eventdata, handles)
% hObject    handle to pasteOrbitFromClipboardMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    pasteOrbitFromClipboard(handles.eEpoch, handles.eSMA, handles.eEcc, ...
                                 handles.eInc, handles.eRAAN, handles.eArg, ...
                                 handles.eMeanAnom, false);


% --------------------------------------------------------------------
function getOrbitFromKSPActiveVesselMenu_Callback(hObject, eventdata, handles)
% hObject    handle to getOrbitFromKSPActiveVesselMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    orbitPanelGetOrbitFromKSPTOTConnectActiveVesselCallBack(handles.eSMA, handles.eEcc, handles.eInc, handles.eRAAN, handles.eArg, handles.eMeanAnom, handles.eEpoch);
