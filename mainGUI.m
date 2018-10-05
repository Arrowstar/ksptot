function varargout = mainGUI(varargin)
% MAINGUI MATLAB code for mainGUI.fig
%      MAINGUI, by itself, creates a new MAINGUI or raises the existing
%      singleton*.
%
%      H = MAINGUI returns the handle to a new MAINGUI or the handle to
%      the existing singleton*.
%
%      MAINGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MAINGUI.M with the given input arguments.
%
%      MAINGUI('Property','Value',...) creates a new MAINGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mainGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mainGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help mainGUI

% Last Modified by GUIDE v2.5 24-May-2017 19:07:51

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mainGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @mainGUI_OutputFcn, ...
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


% --- Executes just before mainGUI is made visible.
function mainGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mainGUI (see VARARGIN)

% Choose default command line output for mainGUI
global options_UseEarthTimeSystem options_gravParamType;

handles.output = hObject;
set(hObject,'Visible','off');

% Update handles structure
guidata(hObject, handles);

%Possible fix for people with display issues.
checkForCharUnitsInGUI(hObject);
drawnow;

%init GUI data
celBodyData = varargin{1};
% bodyNames = varargin{2};
mainGUIUserData = cell(10,10);
mainGUIUserData{1,1} = celBodyData;

%Application Options
appOptions = varargin{4};

options = struct();
options.plotmaxdeltav = appOptions.ksptot.plotmaxdeltav;
options.porkchopptsaxes = appOptions.ksptot.porkchopptsaxes;
options.porkchopnumsynperiods = appOptions.ksptot.porkchopnumsynperiods;
options.departplotnumoptiters = appOptions.ksptot.departplotnumoptiters;
options.quant2opt = appOptions.ksptot.quant2opt;
mainGUIUserData{1,9} = options;
mainGUIUserData{1,10} = handles.porkchopPlotAxes;

if(strcmpi(appOptions.ksptot.timesystem,'Earth'))
    options_UseEarthTimeSystem = true;
else
    options_UseEarthTimeSystem = false;
end

options_gravParamType = appOptions.ksptot.gravparamtype;

set(hObject,'HandleVisibility','on');
set(hObject,'visible','off');
% axes(mainGUIUserData{1,10});

set(hObject,'UserData',mainGUIUserData);
setappdata(hObject,'openToolWindows',matlab.ui.Figure.empty(0,1));
setappdata(hObject,'appOptions',appOptions);

%Set up plot
plotPorkChopPlot(hObject);

%init GUI
departBodyEarliestTimeText_Callback(handles.departBodyEarliestTimeText, eventdata, handles);
arrivalBodyEarliestTimeText_Callback(handles.arrivalBodyEarliestTimeText, eventdata, handles);
set(handles.flybyManSeq,'visible','off');

%Set up combo boxes
cullArriveDepartCombosPerCB(hObject);
departBodyCombo_Callback(handles.departBodyCombo, eventdata, handles);
arrivalBodyCombo_Callback(handles.arrivalBodyCombo, eventdata, handles);

%Set up status text box
hStatusBox = findobj(hObject,'Tag','statusText');
set(hStatusBox, 'String', setINIStatusBoxMsg());

% UIWAIT makes mainGUI wait for user response (see UIRESUME)
% uiwait(handles.mainGUIFigure);


% --- Outputs from this function are returned to the command line.
function varargout = mainGUI_OutputFcn(hObject, eventdata, handles) 
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
cullArriveDepartCombosPerCB(handles.mainGUIFigure);
departBodyCombo_Callback(handles.departBodyCombo, [], handles);
arrivalBodyCombo_Callback(handles.arrivalBodyCombo, [], handles);

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


% --- Executes on selection change in departBodyCombo.
function departBodyCombo_Callback(hObject, ~, handles)
% hObject    handle to departBodyCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns departBodyCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from departBodyCombo
contents = cellstr(get(hObject,'String'));
sel = contents{get(hObject,'Value')};
xlabel(handles.porkchopPlotAxes,[sel, ' Departure Time (UT) [day]']);

userData = get(handles.mainGUIFigure,'UserData');
celBodyData = userData{1,1};

departBody = strtrim(lower(sel));
departBodyInfo = celBodyData.(departBody);

contents = cellstr(get(handles.arrivalBodyCombo,'String'));
sel = contents{get(handles.arrivalBodyCombo,'Value')};
arriveBody = strtrim(lower(sel));
arrivalBodyInfo = celBodyData.(arriveBody);

contents = cellstr(get(handles.centralBodyCombo,'String'));
sel = contents{get(handles.centralBodyCombo,'Value')};
cenBody = strtrim(lower(sel));
gmu = celBodyData.(cenBody).gm;

if(strcmp(arriveBody, departBody))
    set(handles.synPeriodLabelText, 'String', '');
else
    [~, ~, secInDay, ~] = getSecondsInVariousTimeUnits();
    
    departBodyMeanMotion = computeMeanMotion(departBodyInfo.sma, gmu);
    arrivalBodyMeanMotion = computeMeanMotion(arrivalBodyInfo.sma, gmu);
    synPeriod = computeSynodicPeriod(departBodyMeanMotion, arrivalBodyMeanMotion);
    synPeriodDays = synPeriod/secInDay;

    set(handles.synPeriodLabelText, 'String', ['Synodic Period: ', num2str(synPeriodDays), ' days']);    
end


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



function departBodyEarliestTimeText_Callback(hObject, eventdata, handles)
% hObject    handle to departBodyEarliestTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of departBodyEarliestTimeText as text
%        str2double(get(hObject,'String')) returns contents of departBodyEarliestTimeText as a double
newInput = get(hObject,'String');

newInput = attemptStrEval(newInput);

inputSec = str2double(newInput);
if(checkStrIsNumeric(newInput) && inputSec>=0.0)
    [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(inputSec);
    dateStr = formDateStr(year, day, hour, minute, sec);
    set(handles.departDateText, 'String', dateStr);
    set(hObject,'String', num2str(inputSec));
else
    
end

% --- Executes during object creation, after setting all properties.
function departBodyEarliestTimeText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to departBodyEarliestTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
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
contents = cellstr(get(hObject,'String'));
sel = contents{get(hObject,'Value')};
ylabel(handles.porkchopPlotAxes,[sel, ' Arrival Time (UT) [day]']);

userData = get(handles.mainGUIFigure,'UserData');
celBodyData = userData{1,1};

arriveBody = lower(sel);
arrivalBodyInfo = celBodyData.(arriveBody);

contents = cellstr(get(handles.departBodyCombo,'String'));
sel = contents{get(handles.departBodyCombo,'Value')};
departBody = lower(sel);
departBodyInfo = celBodyData.(departBody);

contents = cellstr(get(handles.centralBodyCombo,'String'));
sel = contents{get(handles.centralBodyCombo,'Value')};
cenBody = lower(sel);
gmu = celBodyData.(cenBody).gm;

if(strcmp(arriveBody, departBody))
    set(handles.synPeriodLabelText, 'String', '');
else
    departBodyMeanMotion = computeMeanMotion(departBodyInfo.sma, gmu);
    arrivalBodyMeanMotion = computeMeanMotion(arrivalBodyInfo.sma, gmu);
    synPeriod = computeSynodicPeriod(departBodyMeanMotion, arrivalBodyMeanMotion);
    [~, ~, secInDay, ~] = getSecondsInVariousTimeUnits();
    synPeriodDays = synPeriod/secInDay;

    set(handles.synPeriodLabelText, 'String', ['Synodic Period: ', num2str(synPeriodDays), ' days']);    
end


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



function arrivalBodyEarliestTimeText_Callback(hObject, eventdata, handles)
% hObject    handle to arrivalBodyEarliestTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of arrivalBodyEarliestTimeText as text
%        str2double(get(hObject,'String')) returns contents of arrivalBodyEarliestTimeText as a double
newInput = get(hObject,'String');

newInput = attemptStrEval(newInput);

inputSec = str2double(newInput);
if(checkStrIsNumeric(newInput) && inputSec>=0.0)
    [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(inputSec);
    dateStr = formDateStr(year, day, hour, minute, sec);
    set(handles.arriveDateText, 'String', dateStr);
    set(hObject,'String', num2str(inputSec));
else
    
end

% --- Executes during object creation, after setting all properties.
function arrivalBodyEarliestTimeText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to arrivalBodyEarliestTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function Untitled_1_Callback(hObject, eventdata, handles)
% hObject    handle to enterUTAsDateTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in testPorkChopper.
function testPorkChopper_Callback(hObject, eventdata, handles)
% hObject    handle to testPorkChopper (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

errMsg = {};

departBodyEarliestTime = str2double(get(handles.departBodyEarliestTimeText,'String'));
enteredStr = get(handles.departBodyEarliestTimeText,'String');
numberName = 'Earliest departure time';
lb = 0;
ub = Inf;
isInt = false;
errMsg = validateNumber(departBodyEarliestTime, numberName, lb, ub, isInt, errMsg, enteredStr);

arriveBodyEarliestTime = str2double(get(handles.arrivalBodyEarliestTimeText,'String'));
enteredStr = get(handles.arrivalBodyEarliestTimeText,'String');
numberName = 'Earliest arrival time';
lb = 0;
ub = Inf;
isInt = false;
errMsg = validateNumber(arriveBodyEarliestTime, numberName, lb, ub, isInt, errMsg, enteredStr);

contents = cellstr(get(handles.departBodyCombo,'String'));
departBody = contents{get(handles.departBodyCombo,'Value')};
contents = cellstr(get(handles.arrivalBodyCombo,'String'));
arriveBody = contents{get(handles.arrivalBodyCombo,'Value')};
errMsg = checkIfInputBodiesAreSame(departBody, arriveBody, errMsg);

if(isempty(errMsg)) 
        generatePorkChopPlot(handles.mainGUIFigure);
        set(handles.computeDepartBurn, 'Enable', 'On');
        refresh(handles.mainGUIFigure);
    try

    catch ME
        errordlg(ME.message);
        throw(ME);
    end    
else
     msgbox(errMsg,'Errors were found in porkchop plot inputs','error');
end

% --- Executes when selected object is changed in porkchopPlotTypeButtonGroup.
function porkchopPlotTypeButtonGroup_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in porkchopPlotTypeButtonGroup 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
    plotPorkChopPlot(handles.mainGUIFigure);


% --- Executes on button press in computeDepartBurn.
function computeDepartBurn_Callback(hObject, eventdata, handles)
% hObject    handle to computeDepartBurn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    hFig = computeDepartureGUI(handles.mainGUIFigure, handles.porkchopPlotAxes, handles.mainGUIFigure);

    openToolWindows = getappdata(handles.mainGUIFigure,'openToolWindows');
    openToolWindows = cleanOpenToolWindowsArr(openToolWindows);
    openToolWindows(end+1) = hFig;
    setappdata(handles.mainGUIFigure,'openToolWindows',openToolWindows);
    
function statusText_Callback(hObject, eventdata, handles)
% hObject    handle to statusText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of statusText as text
%        str2double(get(hObject,'String')) returns contents of statusText as a double


% --- Executes during object creation, after setting all properties.
function statusText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to statusText (see GCBO)
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
    departBodyEarliestTimeText_Callback(handles.departBodyEarliestTimeText, eventdata, handles);
    arrivalBodyEarliestTimeText_Callback(handles.arrivalBodyEarliestTimeText, eventdata, handles);
end


% --------------------------------------------------------------------
function optionsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to optionsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[userData, varargout] = optionsGUI(handles.mainGUIFigure);
if(varargout == -1)
    return;
else
    set(handles.mainGUIFigure, 'UserData', userData);
end


% --------------------------------------------------------------------
function resetStatusBox_Callback(hObject, eventdata, handles)
% hObject    handle to resetStatusBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hStatusBox = findobj(handles.mainGUIFigure,'Tag','statusText');
set(hStatusBox, 'String', setINIStatusBoxMsg());

% --------------------------------------------------------------------
function statusBoxMenu_Callback(hObject, eventdata, handles)
% hObject    handle to statusBoxMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function flybyManSeq_Callback(hObject, eventdata, handles)
% hObject    handle to flybyManSeq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    hFig = flyByManeuverSequencer(handles.mainGUIFigure);

    openToolWindows = getappdata(handles.mainGUIFigure,'openToolWindows');
    openToolWindows = cleanOpenToolWindowsArr(openToolWindows);
    openToolWindows(end+1) = hFig;
    setappdata(handles.mainGUIFigure,'openToolWindows',openToolWindows);

% --------------------------------------------------------------------
function optimal2BurnOrbitChange_Callback(hObject, eventdata, handles)
% hObject    handle to optimal2BurnOrbitChange (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    hFig = OptimalTwoBurnOrbitChange(handles.mainGUIFigure);

    openToolWindows = getappdata(handles.mainGUIFigure,'openToolWindows');
    openToolWindows = cleanOpenToolWindowsArr(openToolWindows);
    openToolWindows(end+1) = hFig;
    setappdata(handles.mainGUIFigure,'openToolWindows',openToolWindows);
    
% --------------------------------------------------------------------
function recenterPlotAt_Callback(hObject, eventdata, handles)
% hObject    handle to recenterPlotAt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    [departDayCenter,arriveDayCenter] = ginputax(handles.porkchopPlotAxes, 1);

    userData = get(handles.mainGUIFigure,'UserData');
    options = userData{1,9};

    numSynPeriods = options.porkchopnumsynperiods;
    celBodyData = userData{1,1};
    
    contents = cellstr(get(handles.centralBodyCombo,'String'));
    cbName = lower(contents{get(handles.centralBodyCombo,'Value')});
    cBodyInfo = celBodyData.(cbName);
    gmu = cBodyInfo.gm;
    
    contents = cellstr(get(handles.departBodyCombo,'String'));
    departBody = contents{get(handles.departBodyCombo,'Value')};
    
    contents = cellstr(get(handles.arrivalBodyCombo,'String'));
    arrivalBody = contents{get(handles.arrivalBodyCombo,'Value')};

    departBody = lower(departBody);
    departBodyInfo = celBodyData.(departBody);
    departBodyMeanMotion = computeMeanMotion(departBodyInfo.sma, gmu);
    
    arrivalBody = lower(arrivalBody);
    arrivalBodyInfo = celBodyData.(arrivalBody);
    arrivalBodyMeanMotion = computeMeanMotion(arrivalBodyInfo.sma, gmu);

    synPeriod = computeSynodicPeriod(departBodyMeanMotion, arrivalBodyMeanMotion);
    
    [~, ~, secInDay, ~] = getSecondsInVariousTimeUnits();
    
    hEarlyDepartTime = findobj(handles.mainGUIFigure,'Tag','departBodyEarliestTimeText');
    earlyDepartTime = max((departDayCenter*(secInDay)) - synPeriod/2, 0);
    set(hEarlyDepartTime, 'String', num2str(earlyDepartTime));
    departBodyEarliestTimeText_Callback(hEarlyDepartTime, [], handles);
    
    hEarlyArrivalTime = findobj(handles.mainGUIFigure,'Tag','arrivalBodyEarliestTimeText');
    earlyArrivalTime = max((arriveDayCenter*(secInDay)) - synPeriod/2, 0);
    set(hEarlyArrivalTime, 'String', num2str(earlyArrivalTime));
    arrivalBodyEarliestTimeText_Callback(hEarlyArrivalTime, [], handles);
    
    generatePorkChopPlot(handles.mainGUIFigure);


% --------------------------------------------------------------------
function manExeAssist_Callback(hObject, eventdata, handles)
% hObject    handle to manExeAssist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    hFig = manExeAssistGUI(handles.mainGUIFigure);

    openToolWindows = getappdata(handles.mainGUIFigure,'openToolWindows');
    openToolWindows = cleanOpenToolWindowsArr(openToolWindows);
    openToolWindows(end+1) = hFig;
    setappdata(handles.mainGUIFigure,'openToolWindows',openToolWindows);

% --------------------------------------------------------------------
function loadBodiesFromFile_Callback(hObject, eventdata, handles)
% hObject    handle to loadBodiesFromFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
mainGUIUserData = get(handles.mainGUIFigure, 'UserData');
prePathName = mainGUIUserData{3,1};
if(~isempty(prePathName))
    defaultName = [prePathName,'bodies.ini'];
else
    defaultName = 'bodies.ini';
end

FilterSpec = {'*.ini','KSP TOT Bodies Info Files'};
[FileName,PathName,~] = uigetfile(FilterSpec,'Select Bodies File to Load',defaultName);
filePathName = [PathName,FileName];

if(PathName == 0)
    return
end
[celBodyDataFromINI,~,~] = inifile(filePathName,'readall');
celBodyData = processINIBodyInfo(celBodyDataFromINI);

updateAppOptions(hObject, 'ksptot', 'bodiesinifile', filePathName);

mainGUIUserData = get(handles.mainGUIFigure, 'UserData');
mainGUIUserData{1,1} = celBodyData;
mainGUIUserData{3,1} = PathName;
set(handles.mainGUIFigure, 'UserData', mainGUIUserData);

cullArriveDepartCombosPerCB(handles.mainGUIFigure);
departBodyCombo_Callback(handles.departBodyCombo, eventdata, handles);
arrivalBodyCombo_Callback(handles.arrivalBodyCombo, eventdata, handles);


% --------------------------------------------------------------------
function rendezvousManSeq_Callback(hObject, eventdata, handles)
% hObject    handle to rendezvousManSeq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    hFig = rendezvousGUI(handles.mainGUIFigure);

    openToolWindows = getappdata(handles.mainGUIFigure,'openToolWindows');
    openToolWindows = cleanOpenToolWindowsArr(openToolWindows);
    openToolWindows(end+1) = hFig;
    setappdata(handles.mainGUIFigure,'openToolWindows',openToolWindows);
    
% --------------------------------------------------------------------
function rtsUploadManeuver_Callback(hObject, eventdata, handles)
% hObject    handle to rtsUploadManeuver (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    hFig = uploadManeuverToKSP();
    
    openToolWindows = getappdata(handles.mainGUIFigure,'openToolWindows');
    openToolWindows = cleanOpenToolWindowsArr(openToolWindows);
    openToolWindows(end+1) = hFig;
    setappdata(handles.mainGUIFigure,'openToolWindows',openToolWindows);    


% --------------------------------------------------------------------
function getUTFromKSP_Callback(hObject, eventdata, handles)
% hObject    handle to getUTFromKSP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
secUT = readDoublesFromKSPTOTConnect('GetUT', '', true);
if(secUT >= 0)
    set(gco, 'String', num2str(secUT));
    departBodyEarliestTimeText_Callback(handles.departBodyEarliestTimeText, eventdata, handles);
    arrivalBodyEarliestTimeText_Callback(handles.arrivalBodyEarliestTimeText, eventdata, handles);
end


% --------------------------------------------------------------------
function mccRTS_Callback(hObject, eventdata, handles)
% hObject    handle to mccRTS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    mainGUIUserData = get(handles.mainGUIFigure, 'UserData');
    celBodyData = mainGUIUserData{1,1};
    appOptions = getappdata(handles.mainGUIFigure,'appOptions');
    
    if(isfield(appOptions.ksptot,'rtshostname') && ~isempty(appOptions.ksptot.rtshostname))
        rtsHost = appOptions.ksptot.rtshostname;
    else
        rtsHost = 'localhost';
    end
    
    hFig = rts_mainGUI(celBodyData, rtsHost, handles.mainGUIFigure);
    
    openToolWindows = getappdata(handles.mainGUIFigure,'openToolWindows');
    openToolWindows = cleanOpenToolWindowsArr(openToolWindows);
    openToolWindows(end+1) = hFig;
    setappdata(handles.mainGUIFigure,'openToolWindows',openToolWindows);


% --------------------------------------------------------------------
function missionArchitectMenu_Callback(hObject, eventdata, handles)
% hObject    handle to missionArchitectMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    mainGUIUserData = get(handles.mainGUIFigure, 'UserData');
    celBodyData = mainGUIUserData{1,1};

    ma_hFig = findall(0,'Tag','ma_MainGUI');
    if(~isempty(ma_hFig))
        figure(ma_hFig);
    else
        hMsg = helpdlg('Starting Mission Architect.  Please wait...','Launch Vehicle Designer');
        
        hFig = ma_MainGUI(handles.mainGUIFigure, celBodyData);
        openToolWindows = getappdata(handles.mainGUIFigure,'openToolWindows');
        openToolWindows = cleanOpenToolWindowsArr(openToolWindows);
        openToolWindows(end+1) = hFig;
        setappdata(handles.mainGUIFigure,'openToolWindows',openToolWindows);
        
        if(isvalid(hMsg))
            close(hMsg);
        end
    end
    


% --------------------------------------------------------------------
function multiFlyByManeuverSequencerMenu_Callback(hObject, eventdata, handles)
% hObject    handle to multiFlyByManeuverSequencerMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    hFig = multiFlyByManeuverSequencer(handles.mainGUIFigure);

    openToolWindows = getappdata(handles.mainGUIFigure,'openToolWindows');
    openToolWindows = cleanOpenToolWindowsArr(openToolWindows);
    openToolWindows(end+1) = hFig;
    setappdata(handles.mainGUIFigure,'openToolWindows',openToolWindows);

% --------------------------------------------------------------------
function multiFlybyPorkchopPlotterMenu_Callback(hObject, eventdata, handles)
% hObject    handle to multiFlybyPorkchopPlotterMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    hFig = flyByPorkchopPlotterGUI(handles.mainGUIFigure);

    openToolWindows = getappdata(handles.mainGUIFigure,'openToolWindows');
    openToolWindows = cleanOpenToolWindowsArr(openToolWindows);
    openToolWindows(end+1) = hFig;
    setappdata(handles.mainGUIFigure,'openToolWindows',openToolWindows);
    
% --------------------------------------------------------------------
function helpMenu_Callback(hObject, eventdata, handles)
% hObject    handle to helpMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function aboutMenu_Callback(hObject, eventdata, handles)
% hObject    handle to aboutMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    helpAboutGUI();


% --------------------------------------------------------------------
function createNewBodiesFileFromKSP_Callback(hObject, eventdata, handles)
% hObject    handle to createNewBodiesFileFromKSP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
h = warndlg('Please make sure KSP is running in the Flight Scene with the KSPTOTConnect plugin loaded before continuing.','Ensure KSP Running','modal');
uiwait(h); 
[FileName,PathName] = getBodiesINIFileFromKSP();

if(~isempty(FileName) && ~isempty(PathName))
    helpstring = sprintf('New bodies file created at:\n%s\n\nPlease use the File -> Load Bodies From File menu item to load the new file into KSP TOT.',[PathName,FileName]);
    helpdlg(helpstring,'Bodies File Created');
end


% --------------------------------------------------------------------
function optionTimeSystemMenu_Callback(hObject, eventdata, handles)
% hObject    handle to optionTimeSystemMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global options_UseEarthTimeSystem;
    
    if(options_UseEarthTimeSystem == true)
        set(handles.useEarthTimeMenu,'Checked','on');
        set(handles.useKerbinTimeMenu,'Checked','off');
    else
        set(handles.useEarthTimeMenu,'Checked','off');
        set(handles.useKerbinTimeMenu,'Checked','on');
    end

% --------------------------------------------------------------------
function useEarthTimeMenu_Callback(hObject, eventdata, handles)
% hObject    handle to useEarthTimeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global options_UseEarthTimeSystem;
    
    options_UseEarthTimeSystem = true;
    departBodyEarliestTimeText_Callback(handles.departBodyEarliestTimeText, [], handles);
    arrivalBodyEarliestTimeText_Callback(handles.arrivalBodyEarliestTimeText, [], handles);
    departBodyCombo_Callback(handles.departBodyCombo, [], handles);
    
    updateAppOptions(handles.mainGUIFigure, 'ksptot', 'timesystem', 'Earth');
    
    try
        testPorkChopper_Callback(handles.testPorkChopper, [], handles);
    catch ME
        return;
    end

% --------------------------------------------------------------------
function useKerbinTimeMenu_Callback(hObject, eventdata, handles)
% hObject    handle to useKerbinTimeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global options_UseEarthTimeSystem;
    
    options_UseEarthTimeSystem = false;
    departBodyEarliestTimeText_Callback(handles.departBodyEarliestTimeText, [], handles);
    arrivalBodyEarliestTimeText_Callback(handles.arrivalBodyEarliestTimeText, [], handles);
    departBodyCombo_Callback(handles.departBodyCombo, [], handles);
    
    updateAppOptions(handles.mainGUIFigure, 'ksptot', 'timesystem', 'Kerbin');
    
	try
        testPorkChopper_Callback(handles.testPorkChopper, [], handles);
	catch(ME) %#ok<SEPEX,NOPRT>
        return;
	end


% --- Executes during object creation, after setting all properties.
function mainGUIFigure_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mainGUIFigure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes when user attempts to close mainGUIFigure.
function mainGUIFigure_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mainGUIFigure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
    
    openToolWindows = getappdata(handles.mainGUIFigure,'openToolWindows');
    openToolWindows = cleanOpenToolWindowsArr(openToolWindows);
    valid = ishghandle(openToolWindows);
    if(any(valid))
        qstring = {'The following KSP TOT tools are currently open and will be closed upon closing the main KSP TOT window:',''};
        for(i=1:length(valid)) %#ok<*NO4LP>
            if(valid(i))
                qstring{end+1} = openToolWindows(i).Name; %#ok<AGROW>
            end
        end
        button = questdlg(qstring,'Tool Windows Open','Okay','Cancel','Cancel');
    else
        button = 'Okay';
    end
    
    if(strcmpi(button,'Okay'))
        for(i=1:length(valid))
            if(valid(i))
                close(openToolWindows(i));
                if(ishghandle(openToolWindows(i)))
                    delete(openToolWindows(i));
                end
            end
        end
        
        delete(hObject);
    else
        return;
    end


% --------------------------------------------------------------------
function gravParamMenu_Callback(hObject, eventdata, handles)
% hObject    handle to gravParamMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global options_gravParamType;    
    
    if(strcmpi(options_gravParamType,'kspStockLike'))
        set(handles.useKspGmMenu,'Checked','on');
        set(handles.useRssLikeGmMenu,'Checked','off');
    elseif(strcmpi(options_gravParamType,'rssLike'))
        set(handles.useKspGmMenu,'Checked','off');
        set(handles.useRssLikeGmMenu,'Checked','on');
    end

% --------------------------------------------------------------------
function useKspGmMenu_Callback(hObject, eventdata, handles)
% hObject    handle to useKspGmMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global options_gravParamType;
    
    options_gravParamType = 'kspStockLike';
    updateAppOptions(hObject, 'ksptot', 'gravParamType', 'kspStockLike');

% --------------------------------------------------------------------
function useRssLikeGmMenu_Callback(hObject, eventdata, handles)
% hObject    handle to useRssLikeGmMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global options_gravParamType;
    
    options_gravParamType = 'rssLike';
    updateAppOptions(hObject, 'ksptot', 'gravParamType', 'rssLike');
