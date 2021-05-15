function varargout = multiFlyByManeuverSequencer(varargin)
% MULTIFLYBYMANEUVERSEQUENCER MATLAB code for multiFlyByManeuverSequencer.fig
%      MULTIFLYBYMANEUVERSEQUENCER, by itself, creates a new MULTIFLYBYMANEUVERSEQUENCER or raises the existing
%      singleton*.
%
%      H = MULTIFLYBYMANEUVERSEQUENCER returns the handle to a new MULTIFLYBYMANEUVERSEQUENCER or the handle to
%      the existing singleton*.
%
%      MULTIFLYBYMANEUVERSEQUENCER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MULTIFLYBYMANEUVERSEQUENCER.M with the given input arguments.
%
%      MULTIFLYBYMANEUVERSEQUENCER('Property','Value',...) creates a new MULTIFLYBYMANEUVERSEQUENCER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before multiFlyByManeuverSequencer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to multiFlyByManeuverSequencer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help multiFlyByManeuverSequencer

% Last Modified by GUIDE v2.5 30-Mar-2021 21:36:13

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @multiFlyByManeuverSequencer_OpeningFcn, ...
                   'gui_OutputFcn',  @multiFlyByManeuverSequencer_OutputFcn, ...
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


% --- Executes just before multiFlyByManeuverSequencer is made visible.
function multiFlyByManeuverSequencer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to multiFlyByManeuverSequencer (see VARARGIN)

% Choose default command line output for multiFlyByManeuverSequencer
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%Possible fix for people with display issues.
% checkForCharUnitsInGUI(hObject);

% mainGUIHandle = varargin{1};
% mainGUIUserData = get(mainGUIHandle,'UserData');
% setappdata(hObject,'MainGUIHandle',mainGUIHandle);
% celBodyData = mainGUIUserData{1,1};
celBodyData = varargin{1};
setappdata(hObject,'celBodyData',celBodyData);
setappdata(handles.multiFlybyManSeqGUI,'Output',[]);

set(handles.dvManInfoText,'UIContextMenu',handles.uploadManeuver2KSP);

setCentralBodyCombo(celBodyData, handles.centralBodyCombo);
initWayPtTable(celBodyData, handles.waypointTable, handles.centralBodyCombo);
initDispAxes(handles.dispAxesMFMS);
initFlightTimeBounds(handles, celBodyData);

launchWindowOpenText_Callback(handles.launchWindowOpenText, [], handles);
launchWindowCloseText_Callback(handles.launchWindowCloseText, [], handles);

eventdataWpT.Indices = [1 1];
waypointTable_CellSelectionCallback(handles.waypointTable, eventdataWpT, handles);

% UIWAIT makes multiFlyByManeuverSequencer wait for user response (see UIRESUME)
% uiwait(handles.multiFlybyManSeqGUI);


function setCentralBodyCombo(celBodyData, hCentralBodyCombo)
    celBodyFields = fieldnames(celBodyData);
    validBodies = {};
    for(i=1:length(celBodyFields)) %#ok<*NO4LP>
        bodyInfo = celBodyData.(celBodyFields{i});
        [children, ~] = getChildrenOfParentInfo(celBodyData, bodyInfo.name);
        if(bodyInfo.canbecentral==1 && length(children)>=3)
            validBodies{end+1} = bodyInfo.name; %#ok<AGROW>
        end
    end
    
    set(hCentralBodyCombo, 'String', char(validBodies));


function initWayPtTable(celBodyData, hWayPtTable, hCentralBodyCombo)
    childrenNames = getValidWayPtsFromParent(celBodyData, hCentralBodyCombo);
    childrenNames = childrenNames';
    
    [mem,Inds] = ismember({'Kerbin','Eve','Duna'},childrenNames);
    if(all(mem))
        initData = childrenNames(Inds);
    else
        if(length(childrenNames)>=3)
            initData = childrenNames(1:3);
        else
            initData = childrenNames(1:end);
        end
    end
    
    set(hWayPtTable,'Data',initData);
    set(hWayPtTable,'ColumnFormat',{childrenNames'});
    set(hWayPtTable,'ColumnName',{'Waypoint'});
    set(hWayPtTable,'ColumnWidth',{135});
    set(hWayPtTable,'ColumnEditable',[true]);
    
    set(hWayPtTable,'UserData',size(initData));

    
function initDispAxes(hDispAxesMFMS)
    hAxis = hDispAxesMFMS;
    axes(hAxis);
    cla(hAxis, 'reset');
    grid on;
    set(hAxis,'XTick',[], 'XTickMode', 'manual');
    set(hAxis,'YTick',[], 'YTickMode', 'manual');
    set(hAxis,'ZTick',[], 'ZTickMode', 'manual');
    view(3);
    
    
function childrenNames = getValidWayPtsFromParent(celBodyData, hCentralBodyCombo)
    contents = cellstr(get(hCentralBodyCombo,'String'));
	cbName = contents{get(hCentralBodyCombo,'Value')};
    [~, childrenNames] = getChildrenOfParentInfo(celBodyData, cbName);
        
    
function initFlightTimeBounds(handles, celBodyData)
    wayPtBodies = {};
    waypts = get(handles.waypointTable,'Data');
    for(i=1:length(waypts))
        wayPtBodies{end+1} = celBodyData.(lower(waypts{i})); %#ok<AGROW>
    end
    
    [lb, ub] = getMultiFlybyLBUB(0, 1, wayPtBodies, celBodyData);
    numLegs = length(wayPtBodies)-1;
    
    lb = lb(2:1+numLegs);
    ub = ub(2:1+numLegs);
    maxRevs = zeros(1,numLegs);
    bnds = [lb',ub', maxRevs'];
    set(handles.flightTimeBndsPanel,'UserData',bnds);

% --- Outputs from this function are returned to the command line.
function varargout = multiFlyByManeuverSequencer_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in centralBodyCombo.
function centralBodyCombo_Callback(hObject, eventdata, handles)
% hObject    handle to centralBodyCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = cellstr(get(hObject,'String')) returns centralBodyCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from centralBodyCombo
    celBodyData = getappdata(handles.multiFlybyManSeqGUI,'celBodyData');
    initWayPtTable(celBodyData, handles.waypointTable, handles.centralBodyCombo);
    
    eventdataWpT.Indices = [1 1];
    waypointTable_CellSelectionCallback(handles.waypointTable, eventdataWpT, handles);

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
    
    celBodyData = getappdata(handles.multiFlybyManSeqGUI,'celBodyData');

    lWindOpen = str2double(get(handles.launchWindowOpenText,'String'));
    enteredStr = get(handles.launchWindowOpenText,'String');
    numberName = 'Launch window open time';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(lWindOpen, numberName, lb, ub, isInt, errMsg, enteredStr);

    lWindClse = str2double(get(handles.launchWindowCloseText,'String'));
    enteredStr = get(handles.launchWindowCloseText,'String');
    numberName = 'Launch window close time';
    lb = lWindOpen+1;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(lWindClse, numberName, lb, ub, isInt, errMsg, enteredStr);
    
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
    
    eMA = str2double(get(handles.eMAText,'String'));
    enteredStr = get(handles.eMAText,'String');
    numberName = 'Orbit Mean Anomaly';
    lb = 0;
    ub = 360;
    isInt = false;
    errMsg = validateNumber(eMA, numberName, lb, ub, isInt, errMsg, enteredStr);
    eMA=eMA*pi/180;

    eEpoch = str2double(get(handles.eEpochText,'String'));
    enteredStr = get(handles.eEpochText,'String');
    numberName = 'Orbit Epoch';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(eEpoch, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    numRuns = str2double(get(handles.numOfRunsText, 'String'));
    enteredStr = get(handles.numOfRunsText,'String');
    numberName = 'Number of Runs';
    lb = 1;
    ub = 1000;
    isInt = true;
    errMsg = validateNumber(numRuns, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    wayPtBodies = {};
    waypts = get(handles.waypointTable,'Data');
    for(i=1:length(waypts))
        wayPtBodies{end+1} = celBodyData.(lower(waypts{i})); %#ok<AGROW>
    end
    
    if(length(wayPtBodies)<2)
        errMsg = {'At least two way points are required.'};
    end
    
    
    Rps = NaN(1,length(wayPtBodies));
    for(i=1:length(wayPtBodies))
        bodyInfo = wayPtBodies{i};
        [~, rPe] = computeApogeePerigee(bodyInfo.sma, bodyInfo.ecc);
        Rps(i) = rPe;
    end
    maxMinXferRad = min(Rps);

    minCbPeriHgt = str2double(get(handles.minCbPeriText, 'String'));
    enteredStr = get(handles.minCbPeriText,'String');
    numberName = 'Min CB Periapsis Height';
    lb = 0;
    ub = maxMinXferRad;
    isInt = false;
    errMsg = validateNumber(minCbPeriHgt, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    maxMsnDur = str2double(get(handles.maxMissionDurationText, 'String'));
    enteredStr = get(handles.maxMissionDurationText,'String');
    numberName = 'Maximum Mission Duration';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(maxMsnDur, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    maxDepartVInf = str2double(get(handles.maxDepartVInfText, 'String'));
    enteredStr = get(handles.maxDepartVInfText,'String');
    numberName = 'Maximum Departure Hyp. Excess Velocity';
    lb = 0.001;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(maxDepartVInf, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    maxArriveVInf = str2double(get(handles.maxArriveVInfText, 'String'));
    enteredStr = get(handles.maxArriveVInfText,'String');
    numberName = 'Maximum Arrival Hyp. Excess Velocity';
    lb = 0.001;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(maxArriveVInf, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    popSize = str2double(get(handles.popSizeText, 'String'));
    enteredStr = get(handles.popSizeText,'String');
    numberName = 'Population Size';
    lb = 50;
    ub = realmax;
    isInt = true;
    errMsg = validateNumber(popSize, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    numGen = str2double(get(handles.maxIterText, 'String'));
    enteredStr = get(handles.maxIterText,'String');
    numberName = 'Maximum Iterations';
    lb = 1;
    ub = realmax;
    isInt = true;
    errMsg = validateNumber(numGen, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        contents = cellstr(get(handles.centralBodyCombo,'String'));
        cbName = contents{get(handles.centralBodyCombo,'Value')};
        cBodyInfo = celBodyData.(lower(strtrim(cbName)));

        lWindDef = [lWindOpen, lWindClse-lWindOpen];

%         popSize = 750;
%         popSize = 10000;
%         numGen = 1000;
%         numGen = 100;

        bnds = get(handles.flightTimeBndsPanel,'UserData');
        
        if(numRuns > 1)
            hWaitbar = waitbar(0,sprintf('Executing Sequence of MFMS Runs... [%u/%u]', 1, numRuns));
        end
        
        includeDepartVInf = logical(handles.includeDepartVInfCheckbox.Value);
        includeArrivalVInf = logical(handles.includeArrivalVInfCheckbox.Value);
        
        runs = cell(numRuns,12);
        for(i=1:numRuns)            
            [x, dv, rp, orbitsIn, orbitsOut, xferOrbits, deltaVVect, vInfDNorm, c, vInfDepart, vInfArrive, numRev] = ...
                multiFlybyExec(wayPtBodies,lWindDef,bnds,minCbPeriHgt,maxMsnDur,popSize,numGen,includeDepartVInf,includeArrivalVInf,maxDepartVInf,maxArriveVInf,celBodyData);
            
            if(isempty(x))
                return; %we hit an error condition in multiFlybyExec()
            end
            
            runs(i,:) = {x, dv, rp, orbitsIn, orbitsOut, xferOrbits, deltaVVect, vInfDNorm, c, vInfDepart, vInfArrive, numRev};
            
            if(numRuns > 1)
                validRuns = runs(cellfun(@constraintCellFunc,runs(1:i,9)),:);
                if(~isempty(validRuns))
                    [minDv,~] = min(cell2mat(validRuns(:,2)));
                    I = find(ismember(cell2mat(runs(:,2)),minDv),1,'last');
                else
                    [minDv,I] = min(cell2mat(runs(:,2)));
                end
                
                waitbar(i/numRuns,hWaitbar,sprintf('Executing Sequence of MFMS Runs... [%u/%u]\nBest current score: %f (run %u)', i+1, numRuns, minDv, I));
            end
        end
        
        hGAPlot = findobj('Name','Genetic Algorithm');
        if(ishandle(hGAPlot))
            close(hGAPlot);
        end
        if(numRuns > 1)
            close(hWaitbar);
        end
        
        validRuns = runs(cellfun(@constraintCellFunc,runs(:,9)),:);
        if(~isempty(validRuns))
            [~,I] = min(cell2mat(validRuns(:,2)));
        else
            [~,I] = min(cell2mat(runs(:,2)));
        end
        
        [x, dv, rp, orbitsIn, orbitsOut, xferOrbits, deltaVVect, vInfDNorm, c, vInfDepart, vInfArrive, numRev] = runs{I,:};
        
%         MainGUIHandle = getappdata(handles.multiFlybyManSeqGUI,'MainGUIHandle');
%         mainGUIUserData = get(MainGUIHandle,'UserData');
%         mainUiOptions = mainGUIUserData{1,9};
%         numComputeDepart = mainUiOptions.departplotnumoptiters;
        numComputeDepart = 25;
        
        [dVDepartVect, dVDepartVectNTW, eRDepartVect, hOrbit, eTA] = computeDepartureOrbit(eSMA, eEcc, eInc, eRAAN, eArg, eMA, eEpoch, wayPtBodies{1}.gm, vInfDepart, xferOrbits(1,8), xferOrbits(1,9), numComputeDepart, pi, 0, 2*pi, waypts{1}, waypts{2}, numRev(1), cBodyInfo, celBodyData);
        eOrbit = [eSMA, eEcc, eInc, eRAAN, eArg, 0, 2*pi, eTA];

        deltaVVectNTW = zeros(size(deltaVVect));
        for(i=1:size(deltaVVect,2))
            oIn = orbitsIn(i,:);
            [rVect,vVect]=getStatefromKepler(oIn(1), oIn(2), oIn(3), oIn(4), oIn(5), oIn(6), wayPtBodies{i+1}.gm);
            
            deltaVVectNTW(:,i) = getNTWdvVect(deltaVVect(:,i), rVect, vVect);
        end
        
        outputs = {wayPtBodies, x, dv, rp, orbitsIn, orbitsOut, xferOrbits, deltaVVect, vInfDNorm, c, vInfDepart, dVDepartVect, dVDepartVectNTW, eRDepartVect, eOrbit, hOrbit, cBodyInfo, deltaVVectNTW, numRev};
        setappdata(handles.multiFlybyManSeqGUI,'Output',outputs);
        set(handles.dispAxesSelectSlider,'Min',1);
        set(handles.dispAxesSelectSlider,'Max',length(wayPtBodies));
        set(handles.dispAxesSelectSlider,'Value',1);
        set(handles.dispAxesSelectSlider,'SliderStep',ones(1,2)*(1/(length(wayPtBodies)-1)));
        dispAxesSelectSlider_Callback(handles.dispAxesSelectSlider, [], handles);
        
        [~, OUnitVector, vInfMag] = computeHyperSVectOVect(hOrbit(1), hOrbit(2), hOrbit(3), hOrbit(4), hOrbit(5), 0.0, wayPtBodies{1}.gm);
        OUnitVector = normVector(OUnitVector);
        
        form = '%9.4f';
        form2 = '%2.9f';
        paddLen = 32;
        printHyperOrbitsMFMSToTextbox(handles.hyperbolicOrbitsText, wayPtBodies, hOrbit, orbitsIn, orbitsOut, vInfArrive, OUnitVector,  vInfMag, form, form2, paddLen);
        printXfrOrbitsMFMSToTextbox(handles.transferOrbitsText,wayPtBodies, xferOrbits, numRev, form, form2, paddLen);
        set(handles.xferOrbitTxtBoxLabel,'String',[cbName,'-Centric Transfer Orbits']);
        printDVManeuversMFMSToTextbox(handles.dvManInfoText,wayPtBodies,dVDepartVectNTW,deltaVVectNTW,eOrbit,orbitsIn,paddLen,form);
        
        if(any(c > 0))
            set(handles.noFeasibleSolLabel,'Visible','on');
        else
            set(handles.noFeasibleSolLabel,'Visible','off');
        end
    else
        msgbox(errMsg,'Errors were found in multi-flyby manuever sequencer inputs','error');
    end
    
function cNotViolated = constraintCellFunc(rowC)
    cNotViolated = all(rowC <= 0);
    

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


% --------------------------------------------------------------------
function getOrbitFromSFSFile_Callback(hObject, eventdata, handles)
% hObject    handle to getOrbitFromSFSFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    mainGUIHandle = getappdata(handles.multiFlybyManSeqGUI,'MainGUIHandle');
    orbitPanelGetOrbitFromSFSContextCallBack(mainGUIHandle,handles.eSMAText, handles.eEccText, handles.eIncText, handles.eRAANText, handles.eArgText, handles.eMAText, handles.eEpochText);

% --------------------------------------------------------------------
function getOrbitFromKSPTOTConnect_Callback(hObject, eventdata, handles)
% hObject    handle to getOrbitFromSFSFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    orbitPanelGetOrbitFromKSPTOTConnectCallBack(handles.eSMAText, handles.eEccText, handles.eIncText, handles.eRAANText, handles.eArgText, handles.eMAText, handles.eEpochText);


% --------------------------------------------------------------------
function uploadManeuver_Callback(hObject, eventdata, handles)
% hObject    handle to uploadManeuver (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    guiData = get(gco,'UserData');
    uploadManeuverToKSP(guiData);


% --- Executes on button press in addWayPointRowButton.
function addWayPointRowButton_Callback(hObject, eventdata, handles)
% hObject    handle to addWayPointRowButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    celBodyData = getappdata(handles.multiFlybyManSeqGUI,'celBodyData');

    wayPtData = get(handles.waypointTable,'Data');
    validChildren = get(handles.waypointTable,'ColumnFormat');
    wayPtData{end+1,1} = validChildren{1}{1};
    set(handles.waypointTable,'Data',wayPtData);
    
    wayPtBodies = {};
    for(i=1:length(wayPtData))
        wayPtBodies{end+1} = celBodyData.(lower(wayPtData{i})); %#ok<AGROW>
    end
    
    bnds = get(handles.flightTimeBndsPanel,'UserData');
    [lb, ub] = getMultiFlybyLBUB(0, 1, wayPtBodies, celBodyData);
    numLegs = length(wayPtBodies)-1;
    bnds(end+1,1) = lb(numLegs+1);
    bnds(end,2) = ub(numLegs+1);
    bnds(end,3) = 0;
    set(handles.flightTimeBndsPanel,'UserData',bnds);
    

% --- Executes on button press in deleteWayPointRowButton.
function deleteWayPointRowButton_Callback(hObject, eventdata, handles)
% hObject    handle to deleteWayPointRowButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    celBodyData = getappdata(handles.multiFlybyManSeqGUI,'celBodyData');

    wayPtData = get(handles.waypointTable,'Data');
    numPreDeleteWayPts = length(wayPtData);
    if(size(wayPtData,1) > 2)
        selected = get(handles.waypointTable,'UserData');
        if(isempty(selected))
            selected = size(wayPtData);
        end
        if(selected<=length(wayPtData))
            row = selected(1,1);
            wayPtData(row,:) = [];

            bnds = get(handles.flightTimeBndsPanel,'UserData');

            if(row==1)
                bnds(1,:) = [];
            elseif(row == numPreDeleteWayPts)
                bnds(row-1,:) = [];
            else
                preBnds = bnds(1:row-2,:);
                pstBnds = bnds(row+1:end,:);
                
                wayPtBodies = {};
                for(i=1:length(wayPtData))
                    wayPtBodies{end+1} = celBodyData.(lower(wayPtData{i})); %#ok<AGROW>
                end
                [lb, ub] = getMultiFlybyLBUB(0, 1, wayPtBodies, celBodyData);
                
                newBnds(1) = lb(row);
                newBnds(2) = ub(row);
                newBnds(3) = 0;
                
                bnds = [preBnds; newBnds; pstBnds];
            end

            set(handles.flightTimeBndsPanel,'UserData',bnds);
            set(handles.waypointTable,'Data',wayPtData);
        end
    end
    

% --- Executes when selected cell(s) is changed in waypointTable.
function waypointTable_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to waypointTable (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
    set(hObject,'UserData',eventdata.Indices);
    
    celBodyData = getappdata(handles.multiFlybyManSeqGUI,'celBodyData');
    
    wayPtBodies = {};
    waypts = get(handles.waypointTable,'Data');
    for(i=1:length(waypts))
        wayPtBodies{end+1} = celBodyData.(lower(waypts{i})); %#ok<AGROW>
    end
    
    selected = eventdata.Indices;
    if(isempty(selected))
        selected = size(wayPtBodies);
    end
    selected = selected(1);
    
    if(selected==length(wayPtBodies))
        set(handles.minFlightTimeText,'String','N/A');
        set(handles.maxFlightTimeText,'String','N/A');
        set(handles.maxNumRevsText,'String','N/A');
        
        set(handles.minFlightTimeText,'Enable','off');
        set(handles.maxFlightTimeText,'Enable','off');
        set(handles.maxNumRevsText,'Enable','off');
    else
        set(handles.minFlightTimeText,'Enable','on');
        set(handles.maxFlightTimeText,'Enable','on');
        set(handles.maxNumRevsText,'Enable','on');
        
        waypt1 = cap1stLetter(wayPtBodies{selected}.name);
        waypt2 = cap1stLetter(wayPtBodies{selected+1}.name);
        set(handles.flightTimeBndsPanel,'Title',[waypt1,' -> ',waypt2,' Flight Time Bounds']);
        
        bnds = get(handles.flightTimeBndsPanel,'UserData');
        [~, ~, secInDay, ~] = getSecondsInVariousTimeUnits();
        set(handles.minFlightTimeText,'String',num2str(bnds(selected,1)/secInDay));
        set(handles.maxFlightTimeText,'String',num2str(bnds(selected,2)/secInDay));
        set(handles.maxNumRevsText,'String',num2str(bnds(selected,3)));
    end
    
    
% --- Executes when entered data in editable cell(s) in waypointTable.
function waypointTable_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to waypointTable (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
    waypointTable_CellSelectionCallback(handles.waypointTable, eventdata, handles);

% --- Executes on slider movement.
function dispAxesSelectSlider_Callback(hObject, eventdata, handles)
% hObject    handle to dispAxesSelectSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    celBodyData = getappdata(handles.multiFlybyManSeqGUI,'celBodyData');
    outputs = getappdata(handles.multiFlybyManSeqGUI,'Output');
    
    if(isempty(outputs))
        return;
    end
    
    wayPtBodies = outputs{1};
    x = outputs{2};
    dv = outputs{3};
    rp = outputs{4};
    orbitsIn = outputs{5};
    orbitsOut = outputs{6};
    xferOrbits = outputs{7};
    deltaVVect = outputs{8};
    vInfDNorm = outputs{9};
    c = outputs{10};
    vInfDepart = outputs{11};
    dVDepartVect = outputs{12};
    dVDepartVectNTW = outputs{13};
    eRDepartVect = outputs{14};
    eOrbit = outputs{15};
    hOrbit = outputs{16};
    cBodyInfo = outputs{17};
    numRev = outputs{19};
    
    value = get(hObject,'Value');
    value = round(value);
    set(hObject,'Value',value);
    
    if(value == 1)
        plotAllFlybys(handles.dispAxesMFMS, cBodyInfo, xferOrbits, wayPtBodies, numRev, celBodyData);
        set(handles.axesTitleLabel,'String','Flyby Trajectories - Global View');
    elseif(value == 2)
        plotBodyDepartOrbitForFlyby(handles.dispAxesMFMS, wayPtBodies{1}, eOrbit, hOrbit, dVDepartVect, eRDepartVect);
        set(handles.axesTitleLabel,'String',[wayPtBodies{1}.name,' Departure Orbit']);
    elseif(value > 2)
        plotFlybyTraj(handles.dispAxesMFMS, wayPtBodies{value-1}, orbitsIn(value-2,:), orbitsOut(value-2,:), deltaVVect(:,value-2), celBodyData);
        set(handles.axesTitleLabel,'String',[wayPtBodies{value-1}.name,' Flyby Orbit']);
    end    
    

% --- Executes during object creation, after setting all properties.
function dispAxesSelectSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dispAxesSelectSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function minFlightTimeText_Callback(hObject, eventdata, handles)
% hObject    handle to minFlightTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of minFlightTimeText as text
%        str2double(get(hObject,'String')) returns contents of minFlightTimeText as a double
    selected = get(handles.waypointTable,'UserData');
    selected = selected(1);
    bnds = get(handles.flightTimeBndsPanel,'UserData');
    
    celBodyData = getappdata(handles.multiFlybyManSeqGUI,'celBodyData');
    
    wayPtBodies = {};
    waypts = get(handles.waypointTable,'Data');
    for(i=1:length(waypts))
        wayPtBodies{end+1} = celBodyData.(lower(waypts{i})); %#ok<AGROW>
    end
    
    if(selected~=length(wayPtBodies))
        newInput = get(hObject,'String');
        newInput = attemptStrEval(newInput);
        set(hObject,'String', newInput);
        
        newInputD = str2double(newInput);
        [~, ~, secInDay, ~] = getSecondsInVariousTimeUnits();
        if(checkStrIsNumeric(newInput) && newInputD>=0.0 && newInputD < bnds(selected,2)/secInDay)
            bnds(selected,1) = newInputD * secInDay;
            set(handles.flightTimeBndsPanel,'UserData',bnds);
        else
            set(hObject,'String', num2str(bnds(selected,1)/secInDay));
            errordlg(['Invalid minimum flight time entered.  Make sure what you entered is a number and that it is less than the maximum shown.'],'Invalid Minimum Flight Time');
        end
    end

% --- Executes during object creation, after setting all properties.
function minFlightTimeText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to minFlightTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxFlightTimeText_Callback(hObject, eventdata, handles)
% hObject    handle to maxFlightTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxFlightTimeText as text
%        str2double(get(hObject,'String')) returns contents of maxFlightTimeText as a double
    selected = get(handles.waypointTable,'UserData');
    selected = selected(1);
    bnds = get(handles.flightTimeBndsPanel,'UserData');
    
    celBodyData = getappdata(handles.multiFlybyManSeqGUI,'celBodyData');
    
    wayPtBodies = {};
    waypts = get(handles.waypointTable,'Data');
    for(i=1:length(waypts))
        wayPtBodies{end+1} = celBodyData.(lower(waypts{i})); %#ok<AGROW>
    end
    
    if(selected~=length(wayPtBodies))
        newInput = get(hObject,'String');
        newInput = attemptStrEval(newInput);
        set(hObject,'String', newInput);
        
        newInputD = str2double(newInput);
        [~, ~, secInDay, ~] = getSecondsInVariousTimeUnits();
        if(checkStrIsNumeric(newInput) && newInputD>=0.0 && newInputD > bnds(selected,1)/secInDay)
            bnds(selected,2) = newInputD * secInDay;
            set(handles.flightTimeBndsPanel,'UserData',bnds);
        else
            set(hObject,'String', num2str(bnds(selected,2)/secInDay));
            errordlg(['Invalid maximum flight time entered.  Make sure what you entered is a number and that it is greater than the minimum shown.'],'Invalid Maximum Flight Time');
        end
    end

% --- Executes during object creation, after setting all properties.
function maxFlightTimeText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxFlightTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function copyOrbitToClipboardMenu_Callback(hObject, eventdata, handles)
% hObject    handle to copyOrbitToClipboardMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    celBodyData = getappdata(handles.multiFlybyManSeqGUI,'celBodyData');
    contents = cellstr(get(handles.centralBodyCombo,'String'));
    cbName = contents{get(handles.centralBodyCombo,'Value')};
    cBodyInfo = celBodyData.(lower(strtrim(cbName)));

    copyOrbitToClipboardFromText(handles.eEpochText, handles.eSMAText, handles.eEccText, ...
                                 handles.eIncText, handles.eRAANText, handles.eArgText, ...
                                 handles.eMAText, false, cBodyInfo.id);

% --------------------------------------------------------------------
function pasteOrbitFromClipboardMenu_Callback(hObject, eventdata, handles)
% hObject    handle to pasteOrbitFromClipboardMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    celBodyData = getappdata(handles.multiFlybyManSeqGUI,'celBodyData');
    pasteOrbitFromClipboard(handles.eEpochText, handles.eSMAText, handles.eEccText, ...
                            handles.eIncText, handles.eRAANText, handles.eArgText, ...
                            handles.eMAText, false, handles.centralBodyCombo, celBodyData);


% --------------------------------------------------------------------
function getOrbitFromKSPActiveVesselMenu_Callback(hObject, eventdata, handles)
% hObject    handle to getOrbitFromKSPActiveVesselMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    orbitPanelGetOrbitFromKSPTOTConnectActiveVesselCallBack(handles.eSMAText, handles.eEccText, handles.eIncText, handles.eRAANText, handles.eArgText, handles.eMAText, handles.eEpochText);

function numOfRunsText_Callback(hObject, eventdata, handles)
% hObject    handle to numOfRunsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numOfRunsText as text
%        str2double(get(hObject,'String')) returns contents of numOfRunsText as a double


% --- Executes during object creation, after setting all properties.
function numOfRunsText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numOfRunsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in saveTextResultsToFileButton.
function saveTextResultsToFileButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveTextResultsToFileButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    str = cell(0,1);
    str{end+1,1} = get(handles.hypDepAndFlybyOrbitsLabel,'String');
    str{end+1,1} = getHRule();
    str{end+1,1} = get(handles.hyperbolicOrbitsText,'String');
    str{end+1,1} = '\n\n';
    
    str{end+1,1} = get(handles.xferOrbitTxtBoxLabel,'String');
    str{end+1,1} = getHRule();
    str{end+1,1} = get(handles.transferOrbitsText,'String');
    str{end+1,1} = '\n\n';
    
    str{end+1,1} = get(handles.dvManInfoLabel,'String');
    str{end+1,1} = getHRule();
    str{end+1,1} = get(handles.dvManInfoText,'String');

    [FileName,PathName,~] = uiputfile('*.txt','Save MFMS Results','MFMS_Results.txt');
    if(FileName ~= 0)
        fid = fopen([PathName,FileName],'wt');
        for(i=1:length(str))
            if(ischar(str{i}))
                fprintf(fid,'%s\n',sprintf(str{i}));
            elseif(iscell(str{i}))
                substrs = str{i};
                for(j=1:length(substrs))
                    fprintf(fid,'%s\n',sprintf(substrs{j}));
                end
            end
        end
        fclose(fid);
    end

function eMAText_Callback(hObject, eventdata, handles)
% hObject    handle to eMAText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eMAText as text
%        str2double(get(hObject,'String')) returns contents of eMAText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function eMAText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eMAText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function eEpochText_Callback(hObject, eventdata, handles)
% hObject    handle to eEpochText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eEpochText as text
%        str2double(get(hObject,'String')) returns contents of eEpochText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function eEpochText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eEpochText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxNumRevsText_Callback(hObject, eventdata, handles)
% hObject    handle to maxNumRevsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxNumRevsText as text
%        str2double(get(hObject,'String')) returns contents of maxNumRevsText as a double
    selected = get(handles.waypointTable,'UserData');
    selected = selected(1);
    bnds = get(handles.flightTimeBndsPanel,'UserData');
    
    celBodyData = getappdata(handles.multiFlybyManSeqGUI,'celBodyData');
    
    wayPtBodies = {};
    waypts = get(handles.waypointTable,'Data');
    for(i=1:length(waypts))
        wayPtBodies{end+1} = celBodyData.(lower(waypts{i})); %#ok<AGROW>
    end
    
    if(selected~=length(wayPtBodies))
        newInput = get(hObject,'String');
        newInput = attemptStrEval(newInput);
        set(hObject,'String', newInput);
        
        newInputD = str2double(newInput);
        err = validateNumber(newInputD, '', 0, Inf, true, {}, newInput);
        
        if(checkStrIsNumeric(newInput) && newInputD>=0.0 && isempty(err))
            bnds(selected,3) = newInputD;
            set(handles.flightTimeBndsPanel,'UserData',bnds);
        else
            set(hObject,'String', num2str(bnds(selected,3)));
            errordlg(['Invalid maximum number of revolutions entered.  Make sure what you entered is a positive integer.'],'Invalid Maximum Revolutions');
        end
    end
    

% --- Executes during object creation, after setting all properties.
function maxNumRevsText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxNumRevsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function minCbPeriText_Callback(hObject, eventdata, handles)
% hObject    handle to minCbPeriText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of minCbPeriText as text
%        str2double(get(hObject,'String')) returns contents of minCbPeriText as a double
    newInput = attemptStrEval(get(hObject,'String'));
    set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function minCbPeriText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to minCbPeriText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxMissionDurationText_Callback(hObject, eventdata, handles)
% hObject    handle to maxMissionDurationText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxMissionDurationText as text
%        str2double(get(hObject,'String')) returns contents of maxMissionDurationText as a double
    newInput = attemptStrEval(get(hObject,'String'));
    set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function maxMissionDurationText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxMissionDurationText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when user attempts to close multiFlybyManSeqGUI.
function multiFlybyManSeqGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to multiFlybyManSeqGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
    h = findobj('Name','Genetic Algorithm');

    yesStr = 'Yes';
    button = yesStr;
    if(~isempty(h))
        button = questdlg('The MFMS is still running.  Do you wish to close MFMS?','Close MFMS?','Yes','No','No');
    end
    
    if(strcmpi(button,yesStr))
        delete(hObject);
        drawnow;
        delete(h);
    end


% --- Executes on button press in includeDepartVInfCheckbox.
function includeDepartVInfCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to includeDepartVInfCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of includeDepartVInfCheckbox



function maxDepartVInfText_Callback(hObject, eventdata, handles)
% hObject    handle to maxDepartVInfText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxDepartVInfText as text
%        str2double(get(hObject,'String')) returns contents of maxDepartVInfText as a double
    newInput = attemptStrEval(get(hObject,'String'));
    set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function maxDepartVInfText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxDepartVInfText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in includeArrivalVInfCheckbox.
function includeArrivalVInfCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to includeArrivalVInfCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of includeArrivalVInfCheckbox



function maxArriveVInfText_Callback(hObject, eventdata, handles)
% hObject    handle to maxArriveVInfText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxArriveVInfText as text
%        str2double(get(hObject,'String')) returns contents of maxArriveVInfText as a double
    newInput = attemptStrEval(get(hObject,'String'));
    set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function maxArriveVInfText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxArriveVInfText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function popSizeText_Callback(hObject, eventdata, handles)
% hObject    handle to popSizeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of popSizeText as text
%        str2double(get(hObject,'String')) returns contents of popSizeText as a double
    newInput = attemptStrEval(get(hObject,'String'));
    set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function popSizeText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popSizeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxIterText_Callback(hObject, eventdata, handles)
% hObject    handle to maxIterText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxIterText as text
%        str2double(get(hObject,'String')) returns contents of maxIterText as a double
    newInput = attemptStrEval(get(hObject,'String'));
    set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function maxIterText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxIterText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
