function varargout = ma_MainGUI(varargin)
% MA_MAINGUI MATLAB code for ma_MainGUI.fig
%      MA_MAINGUI, by itself, creates a new MA_MAINGUI or raises the existing
%      singleton*.
%
%      H = MA_MAINGUI returns the handle to a new MA_MAINGUI or the handle to
%      the existing singleton*.
%
%      MA_MAINGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_MAINGUI.M with the given input arguments.
%
%      MA_MAINGUI('Property','Value',...) creates a new MA_MAINGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_MainGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_MainGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_MainGUI

% Last Modified by GUIDE v2.5 25-Aug-2020 09:50:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_MainGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_MainGUI_OutputFcn, ...
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


% --- Executes just before ma_MainGUI is made visible.
function ma_MainGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_MainGUI (see VARARGIN)
global warn_error_label_handles warn_error_slider_handle;

clc;

% Set Prefs
handles.ksptotMainGUI = varargin{1};
celBodyData = varargin{2};
celBodyData = CelestialBodyData(celBodyData);

% Choose default command line output for ma_MainGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

setappdata(hObject,'celBodyData',celBodyData);
setappdata(hObject,'current_save_location','');
setappdata(hObject,'application_title','KSP TOT Mission Architect');
setappdata(hObject,'output_text_max_line_length',length(getMA_HR()));
setappdata(hObject,'undo_states',{});
setappdata(hObject,'undo_pointer',0);

output_text_max_line_length = getappdata(handles.ma_MainGUI,'output_text_max_line_length');
writeOutput = @(str,type) writeToMAOutput(handles.outputText, str, type, output_text_max_line_length);
setappdata(hObject,'write_to_output_func',writeOutput);

warn_error_label_handles = [handles.warning1Lbl handles.warning2Lbl handles.warning3Lbl handles.warning4Lbl handles.warning5Lbl handles.warning6Lbl];

% scriptExecSettings_Callback(handles.scriptExecSettings, [], handles);

% Initialize GUI
set(handles.showSoICheckBox,'value',0);
set(handles.showChildrenCheckBox,'value',0);
view(handles.dispAxes,3);
rotate3d(handles.dispAxes,'on');

warn_error_slider_handle = handles.warnAlertsSlider;

% Generate new mission
newMissionPlanMenu_Callback([], [], handles, false);
initializeOutputWindowText(handles, handles.outputText);

% UIWAIT makes ma_MainGUI wait for user response (see UIRESUME)
% uiwait(handles.ma_MainGUI);


function initializeOutputWindowText(handles, hOutputText) 
    write_to_output_func = getappdata(handles.ma_MainGUI,'write_to_output_func');

    set(hOutputText,'String',' ');
    statusBoxMsg = {['KSP TOT Mission Architect v', getKSPTOTVersionNumStr(), sprintf(' (R%s)', version('-release'))], 'Written By Arrowstar (C) 2020', ...
                    getMA_HR()};
	for(i=1:size(statusBoxMsg,2)) %#ok<ALIGN,*NO4LP>
        if(i==1)
            write_to_output_func(statusBoxMsg{i},'overwrite');
        else
            write_to_output_func(statusBoxMsg{i},'appendNoDate');
        end
    end
    
function celBodyData = getCelBodyDataFromMainGui(handles)    
    mainGUIUserData = get(handles.ksptotMainGUI, 'UserData');
    celBodyData = mainGUIUserData{1,1};


function maData = generateCleanMissionPlan(handles) 
    global number_state_log_entries_per_coast num_SoI_search_revs strict_SoI_search use_selective_soi_search options_gravParamType soi_search_tol num_soi_search_attempts_per_rev;
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    write_to_output_func = getappdata(handles.ma_MainGUI,'write_to_output_func');
    
    thrusters = {};
    thrusters{end+1} = ma_createThruster('LV-1R "Spider"',              'fuelOxMass',   290,    2);
    thrusters{end+1} = ma_createThruster('24-77 "Twitch"',              'fuelOxMass',   290,    16);
    thrusters{end+1} = ma_createThruster('Mk-55 "Thud"',                'fuelOxMass',   305,    120);
    thrusters{end+1} = ma_createThruster('O-10 "Puff"',                 'monoMass',     250,    20);
    thrusters{end+1} = ma_createThruster('LV-1 "Ant"',                  'fuelOxMass',   315,    2);
    thrusters{end+1} = ma_createThruster('48-7S "Spark"',               'fuelOxMass',   300,    18);
    thrusters{end+1} = ma_createThruster('LV-909 "Terrier"',            'fuelOxMass',   345,    60);
    thrusters{end+1} = ma_createThruster('LV-T30 "Reliant"',            'fuelOxMass',   300,    215);
    thrusters{end+1} = ma_createThruster('LV-T45 "Swivel"',             'fuelOxMass',   320,    200);
    thrusters{end+1} = ma_createThruster('CR-7 R.A.P.I.E.R. Engine',    'fuelOxMass',   305,    180);
    thrusters{end+1} = ma_createThruster('T-1 Toroidal "Aerospike"',    'fuelOxMass',   340,    180);
    thrusters{end+1} = ma_createThruster('LV-N "Nerv" Atomic Rocket',   'fuelOxMass',   800,    60);
    thrusters{end+1} = ma_createThruster('Rockomax "Poodle"',           'fuelOxMass',   350,    250);
    thrusters{end+1} = ma_createThruster('Rockomax "Skipper"',          'fuelOxMass',   320,    650);
    thrusters{end+1} = ma_createThruster('Rockomax "Mainsail"',         'fuelOxMass',   310,    1500);
    thrusters{end+1} = ma_createThruster('LFB KR-1x2 "Twin-Boar"',      'fuelOxMass',   300,    2000);
    thrusters{end+1} = ma_createThruster('Kerbodyne KR-2L+ "Rhino"',    'fuelOxMass',   340,    2000);
    thrusters{end+1} = ma_createThruster('S3 KS-25x4 "Mammoth"',        'fuelOxMass',   315,    4000);
    thrusters{end+1} = ma_createThruster('PB-ION',                      'xenonMass',    4200,   2);
    
    oSC = cell(0,1);
    stations = cell(1,1);
    kscStation = struct();
    kscStation.name = 'KSC';
    kscStation.long = deg2rad(285.42472);
    kscStation.lat = deg2rad(-0.1025);
    kscStation.alt = 0.06841;
    kscStation.parent = 'Kerbin';
    kscStation.parentID = 1;
    kscStation.id = rand();
    kscStation.color = 'r';
    kscStation.maxCommRange = Inf;
    kscStation.markerSymbol = 's';
    stations{1} = kscStation;
    
    launchTraj = getDefaultMaDataLaunchStruct(kscStation);
    
    if(isfield(celBodyData,'kerbin'))
        initBody = celBodyData.kerbin;
    else
        bFields = fields(celBodyData);
        initBody = celBodyData.(bFields{1});
    end
    initSMA = initBody.radius + (1/6)*initBody.radius;
    
    script{1} = ma_createSetState('Initial State', 0, initSMA,  0, deg2rad(0), deg2rad(0), deg2rad(0), deg2rad(0), initBody, 30, 15, 0.1, 0.5, 'setState', [], zeros(3,7));

    maData = struct();
    
    maData.script = script;
    
    maData.spacecraft = struct();
    maData.spacecraft.thrusters = thrusters;
    maData.spacecraft.otherSC = oSC;
    maData.spacecraft.stations = stations;
    maData.spacecraft.comm.maxCommRange = Inf;
    maData.spacecraft.propellant.names = {'Fuel/Ox', 'Monoprop', 'Xenon'};
    
    maData.launch = launchTraj;
    
    maData.notes = '';
    
    maData.settings.strictSoISearch = false;
    maData.settings.useSelectiveSoISearch = true;
    maData.settings.parallelScriptOptim = false;
    maData.settings.numStateLogPtsPerCoast = 1000;
    maData.settings.numSoISearchRevs = 3;
    maData.settings.gravParamType = options_gravParamType; 
    maData.settings.optimAlg = 'interior-point';
    maData.settings.soiSearchTol = 1E-12;
    maData.settings.numSoiSearchAttemptsPerRev = 1000;
    maData.settings.autoPropScript = true;
    maData.settings.renderer = FigureRendererEnum.OpenGL;
    maData.settings.numParallelWorkers = feature('numCores');
    number_state_log_entries_per_coast = maData.settings.numStateLogPtsPerCoast;
    num_SoI_search_revs = maData.settings.numSoISearchRevs;
    strict_SoI_search = maData.settings.strictSoISearch;
    use_selective_soi_search = maData.settings.useSelectiveSoISearch;
    soi_search_tol = maData.settings.soiSearchTol;
    num_soi_search_attempts_per_rev = maData.settings.numSoiSearchAttemptsPerRev;

    maData.stateLog = ma_executeScript(maData.script, handles, celBodyData, [], true);
    
	maData.optimizer = struct();
    maData.optimizer.variables = {};
    maData.optimizer.objective = {};
    maData.optimizer.constraints = {};
    maData.optimizer.options = [];
    maData.optimizer.bndsX0 = [];
    maData.optimizer.problem = [];
    
    maData.celBodyData = celBodyData;
    
    maData.ksptotVer = getKSPTOTVersionNumStr();
    
    numParallelWorkers = maData.settings.numParallelWorkers;
    pp = gcp('nocreate');
    if(not(isempty(pp)) && pp.NumWorkers ~= numParallelWorkers)
        delete(pp);
        startParallelWorkers(write_to_output_func, numParallelWorkers);
    end


% --- Outputs from this function are returned to the command line.
function varargout = ma_MainGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in scriptListbox.
function scriptListbox_Callback(hObject, eventdata, handles)
% hObject    handle to scriptListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns scriptListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from scriptListbox
    if(strcmpi(get(handles.ma_MainGUI,'SelectionType'),'open'))
        eventNum = get(hObject,'Value');
        maData = getappdata(handles.ma_MainGUI,'ma_data');
        celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
        script = maData.script;
        event = script{eventNum};
        
        if(eventNum == 1)
            initialState = [];
        else
            stateLog = maData.stateLog;
            
            try
                eventLog = stateLog(stateLog(:,13)==(eventNum),:);
                
                if(not(isempty(eventLog)))
                    initialState = eventLog(1,:);
                else
                    eventLog = stateLog(stateLog(:,13)==(eventNum-1),:);
                    finalEntry = eventLog(end,:);
                    initialState = finalEntry;
                end            
            catch
                eventLog = stateLog(stateLog(:,13)==(eventNum-1),:);
                finalEntry = eventLog(end,:);
                initialState = finalEntry;
            end
        end
        
        oldID = event.id;
        eventNew = [];
        switch event.type
            case 'Set_State'
                eventNew = ma_InsertStateGUI(handles.ma_MainGUI, handles.ksptotMainGUI, event, initialState);
            case 'Coast'
                eventNew = ma_InsertCoastGUI(handles.ma_MainGUI, event);
            case 'DV_Maneuver'
                eventNew = ma_InsertDVManeuverGUI(handles.ma_MainGUI, event);
            case 'Mass_Dump'
                eventNew = ma_InsertMassDumpGUI(handles.ma_MainGUI, event);
            case 'Staging'
                eventNew = ma_InsertStagingGUI(handles.ma_MainGUI, event);
            case 'Docking'
                eventNew = ma_InsertDocking(handles.ma_MainGUI, event);
            case 'Aerobrake'
                eventNew = ma_InsertAerobrakeGUI(handles.ma_MainGUI, event);
            case 'NBodyCoast'
                eventNew = ma_InsertNBodyCoastGUI(handles.ma_MainGUI, event);
            case 'Landing'
                eventNew = ma_InsertLandingGUI(handles.ma_MainGUI, event);
        end

        if(~isempty(eventNew))
            ma_UndoRedoAddState(handles, ['Edit ', event.type]);
            
            eventNew.id = oldID;
            
            script{eventNum} = eventNew;
            maData.script = script;
            maData.stateLog = ma_executeScript(maData.script, handles, celBodyData, handles.scriptWorkingLbl);
            setappdata(handles.ma_MainGUI,'ma_data',maData);

            ma_processData(handles, maData, celBodyData);
            drawnow;
        end
    end
    
    
% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over scriptListbox.
function scriptListbox_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to scriptListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function scriptListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scriptListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in eventInsertCombo.
function eventInsertCombo_Callback(hObject, eventdata, handles)
% hObject    handle to eventInsertCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns eventInsertCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from eventInsertCombo
    contents = cellstr(get(hObject,'String'));
    selected = contents{get(hObject,'Value')};

    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    script = maData.script;
    insertAfter = get(handles.scriptListbox,'value');

    eventNum = insertAfter+1;
    if(eventNum == 1)
        initialState = [];
    else
        stateLog = maData.stateLog;
        eventLog = stateLog(stateLog(:,13)==(eventNum-1),:);
        finalEntry = eventLog(end,:);

        initialState = finalEntry;
    end
    
    event = [];
    switch selected
        case 'Initial State / Set State'
            event = ma_InsertStateGUI(handles.ma_MainGUI, handles.ksptotMainGUI, [], initialState);
        case 'Coast'
            event = ma_InsertCoastGUI(handles.ma_MainGUI);
        case 'Mass Dump'
            event = ma_InsertMassDumpGUI(handles.ma_MainGUI);
        case 'Delta-V Maneuver'
            event = ma_InsertDVManeuverGUI(handles.ma_MainGUI, insertAfter);
        case 'Staging'
            event = ma_InsertStagingGUI(handles.ma_MainGUI);
        case 'Docking'
            event = ma_InsertDocking(handles.ma_MainGUI);
        case 'Aerobrake'
            event = ma_InsertAerobrakeGUI(handles.ma_MainGUI);
        case 'N-Body Coast'
            event = ma_InsertNBodyCoastGUI(handles.ma_MainGUI);
        case 'Landing'
            event = ma_InsertLandingGUI(handles.ma_MainGUI);
    end

    if(~isempty(event))
        ma_UndoRedoAddState(handles, ['Insert ',selected]);
        
        preList = script(1:insertAfter);
        postList = script(insertAfter+1:end);
        newScript = [preList, event, postList];

        maData.script = newScript;
        maData.stateLog = ma_executeScript(maData.script, handles, celBodyData, handles.scriptWorkingLbl);
        setappdata(handles.ma_MainGUI,'ma_data',maData);

        ma_processData(handles, maData, celBodyData);

        set(handles.scriptListbox,'value',insertAfter+1);
        drawnow;
    end

    set(hObject,'Value',1);
    


% --- Executes during object creation, after setting all properties.
function eventInsertCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eventInsertCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in moveEventDown.
function moveEventDown_Callback(hObject, eventdata, handles)
% hObject    handle to moveEventDown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    set(hObject,'Enable','off');

    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    eventNum = get(handles.scriptListbox,'value');
    script = maData.script;

    if(eventNum == 1 || eventNum==length(script))
        set(hObject,'Enable','on');
        return;
    end

    if(length(script) > eventNum)
        preList = [script(1:eventNum-1), script(eventNum+1)];
    elseif(length(script) == eventNum)
        preList = [script(1:eventNum-1)];
    else
        preList = cell();
    end

    if(length(script) > eventNum + 1)
        postList = script(eventNum+2:end);
    else
        postList = [];
    end

    ma_UndoRedoAddState(handles, 'Move Event Down');
    
    event = script(eventNum);

    newScript = [preList, event, postList];
    maData.script = newScript;
    maData.stateLog = ma_executeScript(maData.script, handles, celBodyData, handles.scriptWorkingLbl);
    setappdata(handles.ma_MainGUI,'ma_data',maData);

    ma_processData(handles, maData, celBodyData);
    set(hObject,'Enable','on');


% --- Executes on button press in moveEventUp.
function moveEventUp_Callback(hObject, eventdata, handles)
% hObject    handle to moveEventUp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    set(hObject,'Enable','off');

    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    eventNum = get(handles.scriptListbox,'value');
    script = maData.script;

    if(eventNum == 1 || eventNum == 2)
        set(hObject,'Enable','on');
        return;
    end

    preList = [script(1:eventNum-2)];

    if(length(script) >= eventNum)
        postList = [script(eventNum-1), script(eventNum+1:end)];
    else
        postList = [];
    end

    ma_UndoRedoAddState(handles, 'Move Event Up');
    
    event = script(eventNum);

    newScript = [preList, event, postList];
    maData.script = newScript;
    maData.stateLog = ma_executeScript(maData.script, handles, celBodyData, handles.scriptWorkingLbl);
    setappdata(handles.ma_MainGUI,'ma_data',maData);

    ma_processData(handles, maData, celBodyData);
    set(hObject,'Enable','on');

% --- Executes on button press in deleteEvent.
function deleteEvent_Callback(hObject, eventdata, handles)
% hObject    handle to deleteEvent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    set(hObject,'Enable','off');

    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    eventNum = get(handles.scriptListbox,'value');
    script = maData.script;

    if(eventNum == 1)
        set(hObject,'Enable','on');
        return;
    end
    
    ma_UndoRedoAddState(handles, 'Delete Event');

    script(eventNum) = [];
    maData.script = script;
    maData.stateLog = ma_executeScript(maData.script, handles, celBodyData, handles.scriptWorkingLbl);
    setappdata(handles.ma_MainGUI,'ma_data',maData);

    ma_processData(handles, maData, celBodyData);
    set(hObject,'Enable','on');

function outputText_Callback(hObject, eventdata, handles)
% hObject    handle to outputText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of outputText as text
%        str2double(get(hObject,'String')) returns contents of outputText as a double


% --- Executes during object creation, after setting all properties.
function outputText_CreateFcn(hObject, eventdata, handles) %#ok<*INUSD>
% hObject    handle to outputText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function saved = isMissionPlanSaved(handles)
    application_title = get(handles.ma_MainGUI,'Name');
    if(application_title(end) == '*')
        saved = false;
    else
        saved = true;
    end


% --------------------------------------------------------------------
function newMissionPlanMenu_Callback(hObject, eventdata, handles, varargin)
% hObject    handle to newMissionPlanMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA
    if(~isempty(varargin))
        askToClear = varargin{1};
    else
        if(isMissionPlanSaved(handles))
            askToClear = false;
        else
            askToClear = true;
        end
    end
    if(askToClear)
        response = questdlg(['All unsaved work will be lost.  Continue?'],'Create new mission plan?','Yes','No','No');
    else
        response = 'Yes';
    end
    
    if(~strcmpi(response,'Yes'))
        return;
    end
    
    setappdata(handles.ma_MainGUI,'undo_states',{});
    setappdata(handles.ma_MainGUI,'undo_pointer',0);

%     celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    celBodyData = getCelBodyDataFromMainGui(handles);
    setappdata(handles.ma_MainGUI,'celBodyData',celBodyData);

    write_to_output_func = getappdata(handles.ma_MainGUI,'write_to_output_func');
    application_title = getappdata(handles.ma_MainGUI,'application_title');
    if(askToClear)
        write_to_output_func('Creating new mission plan... ','append');
    end
    
    maData = generateCleanMissionPlan(handles);
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    setappdata(handles.ma_MainGUI,'current_save_location','');
    ma_processData(handles, maData, celBodyData);
    
    set(handles.ma_MainGUI,'Name', application_title);
    
    if(askToClear)
        write_to_output_func(['Done.'],'appendSameLine'); %#ok<*NBRAK>
    end
    set(handles.zoomSlider,'Value',get(handles.zoomSlider,'Max'));
    zoomSlider_Callback(handles.zoomSlider, [], handles);
    
    set(handles.newMissionPlanToolbar,'Enable','on');
    set(handles.openMissionPlanToolbar,'Enable','on');
    set(handles.saveMissionPlanToolbar,'Enable','on');

% --------------------------------------------------------------------
function openMissionPlanMenu_Callback(hObject, eventdata, handles)
% hObject    handle to openMissionPlanMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global number_state_log_entries_per_coast num_SoI_search_revs strict_SoI_search ...
           use_selective_soi_search options_gravParamType soi_search_tol num_soi_search_attempts_per_rev;

    if(isMissionPlanSaved(handles))
        askToClear = false;
    else
        askToClear = true;
    end
    
    if(askToClear)
        response = questdlg(['All unsaved work will be lost.  Continue?'],'Open mission plan?','Yes','No','No');
    else
        response = 'Yes';
    end
    
    if(~strcmpi(response,'Yes'))
        return;
    end

    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    write_to_output_func = getappdata(handles.ma_MainGUI,'write_to_output_func');
    application_title = getappdata(handles.ma_MainGUI,'application_title');
    current_save_location = getappdata(handles.ma_MainGUI,'current_save_location');
    
    if(isempty(current_save_location))
        fileNameToDefaultTo = 'mission.mat';
    else
        [current_save_location_path,~,~] = fileparts(current_save_location);
        fileNameToDefaultTo = [current_save_location_path,filesep,'mission.mat'];
    end

    [FileName,PathName] = uigetfile({'*.mat','KSP TOT Mission Architect Case File (*.mat)'},...
                                                'Open Mission Architect Case',...
                                                fileNameToDefaultTo);
    filePath = [PathName,FileName];

    if(ischar(filePath))
        write_to_output_func(['Loading mission case from "', filePath,'"... '],'append');
        
        load(filePath);
        if(exist('maData','var'))
            setappdata(handles.ma_MainGUI,'undo_states',{});
            setappdata(handles.ma_MainGUI,'undo_pointer',0);
                       
            topLevelBodyInfo = getTopLevelCentralBody(celBodyData);
            maDataTopLevelBodyInfo = getTopLevelCentralBody(maData.celBodyData);
            if(isfield(maData,'celBodyData') && ...
               length(fields(topLevelBodyInfo)) == length(fields(maDataTopLevelBodyInfo)))
                celBodyData = maData.celBodyData;
                setappdata(handles.ma_MainGUI,'celBodyData',celBodyData);
            else
                maData.celBodyData = celBodyData;
            end
            
            if(isfield(maData,'celBodyData')) %#ok<NODEF>
                maData.celBodyData = CelestialBodyData(maData.celBodyData);
                names = fieldnames(maData.celBodyData);
                for(i=1:length(names))
                    name = names{i};
                    if(not(isprop(maData.celBodyData.(name),'celBodyData')))
                        maData.celBodyData.(name).celBodyData = celBodyData;
                    end
                end
            end
            
            set(handles.ma_MainGUI,'Name',[application_title, ' - ', FileName]);
            set(handles.dispAxes,'UserData', 1);
            write_to_output_func(['Done.'],'appendSameLine');

            maData = ma_updateMAData(maData, handles);
            
            number_state_log_entries_per_coast = maData.settings.numStateLogPtsPerCoast;
            num_SoI_search_revs = maData.settings.numSoISearchRevs;
            strict_SoI_search = maData.settings.strictSoISearch;
            use_selective_soi_search = maData.settings.useSelectiveSoISearch;
            soi_search_tol = maData.settings.soiSearchTol;
            num_soi_search_attempts_per_rev = maData.settings.numSoiSearchAttemptsPerRev;
            
            setappdata(handles.ma_MainGUI,'ma_data',maData);
            maData.stateLog = ma_executeScript(maData.script, handles, celBodyData, handles.scriptWorkingLbl, true);
            setappdata(handles.ma_MainGUI,'ma_data',maData);
            setappdata(handles.ma_MainGUI,'current_save_location',filePath);
            
            numParallelWorkers = maData.settings.numParallelWorkers;
            
            pp = gcp('nocreate');
            if(not(isempty(pp)) && pp.NumWorkers ~= numParallelWorkers)
                delete(pp);
                startParallelWorkers(writeOutput, numParallelWorkers);
            end            
            
            ma_processData(handles, maData, celBodyData);
            
            if(~strcmpi(maData.settings.gravParamType,options_gravParamType))
                warndlg(sprintf(['Warning!  It appears this mission plan file was created with a different Gravitational Paramter mode than is currently in use in KSPTOT.  This may cause your misson to fail to propagate properly.\n\n', ...
                                 'The expected GM type is "%s". \n\n', ...
                                 'The GM type actually in use now is "%s".\n\n', ...
                                 'Switch your GM type back to "%s" on the main KSPTOT UI if needed (Edit -> Gravitational Parameter).'], ...
                                 maData.settings.gravParamType, ...
                                 options_gravParamType, ...
                                 maData.settings.gravParamType),'GM Type Warning','modal');
            end
        else
            write_to_output_func(['There was a problem loading the case file from disk: ',filePath,'.  Case not loaded.'],'append');
        end
    end
    
	set(handles.zoomSlider,'Value',get(handles.zoomSlider,'Max'));
    zoomSlider_Callback(handles.zoomSlider, [], handles);

    set(handles.newMissionPlanToolbar,'Enable','on');
    set(handles.openMissionPlanToolbar,'Enable','on');
    set(handles.saveMissionPlanToolbar,'Enable','on');

% --------------------------------------------------------------------
function saveAsMissionPlanMenu_Callback(hObject, eventdata, handles) %#ok<*INUSL,*DEFNU>
% hObject    handle to saveAsMissionPlanMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    saveMissionAs(handles);


function saveMission(handles, varargin)
    global options_gravParamType;

    if(length(varargin) == 1)
        filePath = varargin{1};
        [PathName,name,ext] = fileparts(filePath);
        FileName = [name,ext];
    else
        current_save_location = getappdata(handles.ma_MainGUI,'current_save_location');

        if(isempty(current_save_location))
            fileNameToDefaultTo = 'mission.mat';
        else
            [current_save_location_path,~,~] = fileparts(current_save_location);
            fileNameToDefaultTo = [current_save_location_path,filesep,'mission.mat'];
        end
        
        [FileName,PathName] = uiputfile({'*.mat','KSP TOT Mission Architect Case File (*.mat)'},...
                                                    'Save Mission Architect Case',...
                                                    fileNameToDefaultTo);
        if(ischar(FileName) && ischar(PathName))
            filePath = [PathName,FileName];
        else
            return;
        end
    end
    
    write_to_output_func = getappdata(handles.ma_MainGUI,'write_to_output_func');
    write_to_output_func(['Saving mission case as "', filePath,'"... '],'append');
    
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    maData.optimizer.problem = []; % clear out the optim problem for saving purposes, too big
    maData.ksptotVer = getKSPTOTVersionNumStr();
    try
        if(~isempty(maData.optimizer.constraints))
            consts = maData.optimizer.constraints{1};
            for(i=1:length(consts))
                consts{i,2} = [];
            end
            maData.optimizer.constraints{1} = consts;
        end
    catch ME
        disp(ME.message);
    end
    maData.settings.gravParamType = options_gravParamType; 
    
    save(filePath,'maData');
    application_title = getappdata(handles.ma_MainGUI,'application_title');
    
    set(handles.ma_MainGUI,'Name',[application_title, ' - ', FileName]);
    setappdata(handles.ma_MainGUI,'current_save_location',filePath);
    
    write_to_output_func(['Done.'],'appendSameLine');
    
function saveMissionAs(handles)
    current_save_location = getappdata(handles.ma_MainGUI,'current_save_location');

    if(isempty(current_save_location))
        fileNameToDefaultTo = 'mission.mat';
    else
        [current_save_location_path,~,~] = fileparts(current_save_location);
        fileNameToDefaultTo = [current_save_location_path,filesep,'mission.mat'];
    end
    
    [FileName,PathName] = uiputfile({'*.mat','KSP TOT Mission Architect Case File (*.mat)'},...
                                                'Save Mission Architect Case',...
                                                fileNameToDefaultTo);
    if(ischar(FileName) && ischar(PathName))
        saveMission(handles, [PathName,FileName]);
    end



% --------------------------------------------------------------------
function exitMenu_Callback(hObject, eventdata, handles)
% hObject    handle to exitMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.ma_MainGUI);

% --- Executes on button press in decrOrbitToPlotNum.
function decrOrbitToPlotNum_Callback(hObject, eventdata, handles)
% hObject    handle to decrOrbitToPlotNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    orbitNumToPlot = get(handles.dispAxes,'UserData');

    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    
    if(orbitNumToPlot > 1)
        orbitNumToPlot = orbitNumToPlot - 1;
        set(handles.dispAxes,'UserData',orbitNumToPlot);
        ma_processData(handles, maData, celBodyData);
    elseif(orbitNumToPlot == 1)
        chunkedStateLog = breakStateLogIntoSoIChunks(maData.stateLog);
        orbitNumToPlot = size(chunkedStateLog,1);
        set(handles.dispAxes,'UserData',orbitNumToPlot);
        ma_processData(handles, maData, celBodyData);
    end

% --- Executes on button press in incrOrbitToPlotNum.
function incrOrbitToPlotNum_Callback(hObject, eventdata, handles)
% hObject    handle to incrOrbitToPlotNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    orbitNumToPlot = get(handles.dispAxes,'UserData');
    chunkedStateLog = breakStateLogIntoSoIChunks(maData.stateLog);

    if(orbitNumToPlot < size(chunkedStateLog,1))
        orbitNumToPlot = orbitNumToPlot + 1;
        set(handles.dispAxes,'UserData',orbitNumToPlot);
        ma_processData(handles, maData, celBodyData);
    elseif(orbitNumToPlot == size(chunkedStateLog,1))
        orbitNumToPlot = 1;
        set(handles.dispAxes,'UserData',orbitNumToPlot);
        ma_processData(handles, maData, celBodyData);
    end

% --- Executes on button press in showSoICheckBox.
function showSoICheckBox_Callback(hObject, eventdata, handles)
% hObject    handle to showSoICheckBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showSoICheckBox
    ma_processData(handles);


% --- Executes on button press in showChildrenCheckBox.
function showChildrenCheckBox_Callback(hObject, eventdata, handles)
% hObject    handle to showChildrenCheckBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showChildrenCheckBox
    ma_processData(handles);


% --------------------------------------------------------------------
function undoMenu_Callback(hObject, eventdata, handles)
% hObject    handle to undoMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    ma_UndoAction(handles);
    
    curName = get(handles.ma_MainGUI,'Name');
    if(~strcmpi(curName(end),'*'))
        set(handles.ma_MainGUI,'Name',[curName,'*']);
    end
    
    editMenu_Callback([], [], handles);

% --------------------------------------------------------------------
function redoMenu_Callback(hObject, eventdata, handles)
% hObject    handle to redoMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    ma_RedoAction(handles);
    
    curName = get(handles.ma_MainGUI,'Name');
    if(~strcmpi(curName(end),'*'))
        set(handles.ma_MainGUI,'Name',[curName,'*']);
    end
    
    editMenu_Callback([], [], handles);

% --------------------------------------------------------------------
function editThrustersMenu_Callback(hObject, eventdata, handles)
% hObject    handle to editThrustersMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    ma_UndoRedoAddState(handles, 'Edit Thrusters');
    
    ma_ThrusterManagerGUI(handles.ma_MainGUI);
    
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    maData.stateLog = ma_executeScript(maData.script, handles, celBodyData, handles.scriptWorkingLbl);
    setappdata(handles.ma_MainGUI,'ma_data',maData);


% --------------------------------------------------------------------
function viewStateLogMenu_Callback(hObject, eventdata, handles)
% hObject    handle to viewStateLogMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    ma_StateLogGUI(handles.ma_MainGUI);

% --------------------------------------------------------------------
function saveMissionPlanToolbar_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to saveMissionPlanToolbar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    set(hObject,'Enable','off');
    drawnow;
    saveMissionPlanMenu_Callback([], [], handles)
    set(handles.newMissionPlanToolbar,'Enable','on');
    set(handles.openMissionPlanToolbar,'Enable','on');
    set(handles.saveMissionPlanToolbar,'Enable','on');


% --------------------------------------------------------------------
function openMissionPlanToolbar_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to openMissionPlanToolbar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    set(hObject,'Enable','off');
    drawnow;
    openMissionPlanMenu_Callback(handles.openMissionPlanMenu, [], handles);
    set(handles.newMissionPlanToolbar,'Enable','on');
    set(handles.openMissionPlanToolbar,'Enable','on');
    set(handles.saveMissionPlanToolbar,'Enable','on');


% --------------------------------------------------------------------
function saveMissionPlanMenu_Callback(hObject, eventdata, handles)
% hObject    handle to saveMissionPlanMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    current_save_location = getappdata(handles.ma_MainGUI,'current_save_location');
    if(isempty(current_save_location))
        saveMissionAs(handles);
    else
        saveMission(handles,current_save_location);
    end
    set(handles.newMissionPlanToolbar,'Enable','on');
    set(handles.openMissionPlanToolbar,'Enable','on');
    set(handles.saveMissionPlanToolbar,'Enable','on');
    

% --------------------------------------------------------------------
function newMissionPlanToolbar_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to newMissionPlanToolbar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    set(hObject,'Enable','off');
    drawnow;
    newMissionPlanMenu_Callback(handles.newMissionPlanMenu, [], handles);
    set(handles.newMissionPlanToolbar,'Enable','on');
    set(handles.openMissionPlanToolbar,'Enable','on');
    set(handles.saveMissionPlanToolbar,'Enable','on');

% --------------------------------------------------------------------
function clearOutputText_Callback(hObject, eventdata, handles)
% hObject    handle to clearOutputText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    initializeOutputWindowText(handles, handles.outputText);

% --------------------------------------------------------------------
function outputContext_Callback(hObject, eventdata, handles)
% hObject    handle to outputContext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function optimizationMenu_Callback(hObject, eventdata, handles)
% hObject    handle to optimizationMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    if(isempty(maData.optimizer.objective) || isempty(maData.optimizer.variables) || isempty(maData.optimizer.constraints))
        set(handles.reoptimizeMission,'Enable','off');
    else
        set(handles.reoptimizeMission,'Enable','on');
    end

% --- Executes on button press in popOutOrbitDispButton.
function popOutOrbitDispButton_Callback(hObject, eventdata, handles)
% hObject    handle to popOutOrbitDispButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    figure();
    h = axes();
    numToPlot = get(handles.dispAxes,'UserData');
    handles.dispAxes = h;
    set(h,'UserData',get(handles.dispAxes,'UserData'));
    ma_updateDispAxis(handles, maData.stateLog, numToPlot);


% --------------------------------------------------------------------
function optimizeMenu_Callback(hObject, eventdata, handles)
% hObject    handle to optimizeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
h = findall(0,'tag','ma_MissionOptimizerGUI');
if (isempty(h))
    ma_MissionOptimizerGUI(handles.ma_MainGUI);
    ma_processData(handles);
else
    figure(h);
end

% --------------------------------------------------------------------
function advanceScriptToEventMenu_Callback(hObject, eventdata, handles)
% hObject    handle to advanceScriptToEventMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    eventNum = get(handles.scriptListbox,'value');
    stateLog = maData.stateLog;
    script = maData.script;
    
    ma_UndoRedoAddState(handles, 'Advance Script');
    
    if(eventNum == 1)
        return;
    end
    
    state = stateLog(stateLog(:,13)==eventNum-1,:);
    state = state(end,:);
    
    bodyID = state(8);

    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    gmu = bodyInfo.gm;
    rVect = state(2:4)';
    vVect = state(5:7)';
    
    [sma, ecc, inc, raan, arg, tru] = getKeplerFromState(rVect,vVect,gmu);
    
    name       = ['State Prior to Event ', num2str(eventNum)];
    epoch      = state(1);
    dryMass    = state(9);
    fuelOxMass = state(10);
    monoMass   = state(11);
    xenonMass  = state(12);
    
    
    if(strcmpi(script{eventNum}.type,'Set_State'))
        script = script(eventNum:end);
    else
        setState = ma_createSetState(name, epoch, sma, ecc, inc, raan, arg, tru, bodyInfo, dryMass, fuelOxMass, monoMass, xenonMass, 'setState', [], zeros(3,7));
        script = [{setState}, script(eventNum:end)];
    end
    
    
    maData.script = script;
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    maData.stateLog = ma_executeScript(maData.script,handles,celBodyData,handles.scriptWorkingLbl);
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    ma_processData(handles);

% --------------------------------------------------------------------
function splitCoastAtUTMenu_Callback(hObject, eventdata, handles)
% hObject    handle to splitCoastAtUTMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)   
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    
    eventNum = get(handles.scriptListbox,'value');
    script = maData.script;
    event = script{eventNum};
    if(strcmpi(event.type,'Coast'))        
        stateLog = maData.stateLog;
        eventLog1 = stateLog(stateLog(:,13)==eventNum-1);
        eventLog2 = stateLog(stateLog(:,13)==eventNum);
        minMax = [eventLog1(end,1), eventLog2(end,1)];

        splitUT = ma_SplitCoastAtGUI(handles.ma_MainGUI, 'UT', minMax);
        
        if(~isempty(splitUT))
            ma_UndoRedoAddState(handles, 'Split Coast At UT');
            
            vars = [0; splitUT; splitUT];
            
            preList = script(1:eventNum-1);
            postList = script(eventNum:end);
            newCoast = ma_createCoast('Split at UT', 'goto_ut', splitUT, 0, event.refBody, vars, event.soiSkipIds, event.lineColor, event.lineStyle, event.lineWidth, event.massloss, event.funcHandle, event.maxPropTime, event.orbitDecay);
            script = [preList, newCoast, postList];
            
            maData.script = script;
            maData.stateLog = ma_executeScript(maData.script,handles,celBodyData,handles.scriptWorkingLbl);
            setappdata(handles.ma_MainGUI,'ma_data',maData);
            ma_processData(handles);
        else
            return;
        end
    else
        return;
    end

% --------------------------------------------------------------------
function editMenu_Callback(hObject, eventdata, handles)
% hObject    handle to editMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    undo_states = getappdata(handles.ma_MainGUI,'undo_states');
    undo_pointer = getappdata(handles.ma_MainGUI,'undo_pointer');
    
    if(undo_pointer > 0 && ~isempty(undo_states{undo_pointer,2}))
        undoActionName = undo_states{undo_pointer,2};
        set(handles.undoMenu,'Enable','on');
    else
        undoActionName = '';
        set(handles.undoMenu,'Enable','off');
    end
    set(handles.undoMenu,'Label',['Undo ',undoActionName]);
    
    if(undo_pointer + 1 > 0 && undo_pointer + 1 < size(undo_states,1))
        redoActionName = undo_states{undo_pointer+1,2};
        set(handles.redoMenu,'Enable','on');
    else
        redoActionName = '';
        set(handles.redoMenu,'Enable','off');
    end
    set(handles.redoMenu,'Label',['Redo ',redoActionName]);


% --------------------------------------------------------------------
function reoptimizeMission_Callback(hObject, eventdata, handles)
% hObject    handle to reoptimizeMission (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    
    if(~isempty(maData.optimizer.objective) && ~isempty(maData.optimizer.variables) && ~isempty(maData.optimizer.constraints))
        hWaitbar = waitbar(0,'Please wait while the optimizer initializes...');

        selectedObjFunc = maData.optimizer.objective{1};
        bodyID = maData.optimizer.objective{3};
        selectedCelBodyValue = maData.optimizer.objective{4};
        objEventNum = maData.optimizer.objective{2};
        objEventID = maData.optimizer.objective{5};
        optVarData = maData.optimizer.variables{1};
        actConsts = maData.optimizer.constraints{1};

        [maData, problem] = ma_setupOptimProblem(maData, celBodyData, hWaitbar, selectedObjFunc, bodyID, selectedCelBodyValue, objEventNum, objEventID, optVarData, actConsts);

        setappdata(handles.ma_MainGUI,'ma_data',maData);

        %%%%%%%
        % Get Var Strings
        %%%%%%%
        varStrs = {};
        for(i=1:length(maData.optimizer.variables{2}))
            varStr = maData.optimizer.variables{2}{i}.varStr;
            varStr = varStr(:)';
            varStrs = horzcat(varStrs,varStr); %#ok<AGROW>
        end
        
        if(~isempty(problem))
            waitbar(1,hWaitbar);
            close(hWaitbar);

            writeOutput = getappdata(handles.ma_MainGUI,'write_to_output_func');
            handlesObsOptimGui = ma_ObserveOptimGUI();
            handlesObsOptimGui.ma_MainGUI = handles.ma_MainGUI; 
            
            propNames = maData.spacecraft.propellant.names;
            varLabels = [];
            lbUsAll = problem.lb;
            ubUsAll = problem.ub;
            
            recorder = ma_OptimRecorder();
            outputFnc = @(x, optimValues, state) ma_OptimOutputFunc(x, optimValues, state, handlesObsOptimGui, problem.objective, problem.lb, problem.ub, celBodyData, recorder, propNames, writeOutput, varLabels, lbUsAll, ubUsAll);
            problem.options.OutputFcn = outputFnc;

            executeOptimProblem(handlesObsOptimGui, problem, recorder);
            close(handlesObsOptimGui.ma_ObserveOptimGUI);
            
            ma_processData(handles);
        end
    end


% --------------------------------------------------------------------
function viewStateAfterSelectedEventMenu_Callback(hObject, eventdata, handles)
% hObject    handle to viewStateAfterSelectedEventMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    eventNum = get(handles.scriptListbox,'value');
    stateLog = maData.stateLog;
    
    state = stateLog(stateLog(:,13)==eventNum,:);
    state = state(end,:);

    viewSpacecraftStatePopupGUI(maData.spacecraft.propellant.names, state, eventNum, maData.celBodyData);


% --- Executes on slider movement.
function zoomSlider_Callback(hObject, eventdata, handles)
% hObject    handle to zoomSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');

    setappdata(handles.ma_MainGUI,'plotZoomSliderPosit',get(hObject,'Value'));
    applyZoomLevel(handles.ma_MainGUI, handles, celBodyData);

    
% --- Executes during object creation, after setting all properties.
function zoomSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to zoomSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over zoomSlider.
function zoomSlider_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to zoomSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when user attempts to close ma_MainGUI.
function ma_MainGUI_CloseRequestFcn(hObject, ~, handles)
% hObject    handle to ma_MainGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
    if(strcmpi(handles.scriptWorkingLbl.Visible,'on') || ...
       strcmpi(handles.plotWorkingLbl.Visible,'on'))
        askToQuit = true;
    else
        askToQuit = false;
    end
    
    yesStr = 'Yes';
    if(askToQuit)
        response = questdlg(['KSPTOT is still processing.  Any in-work data will be lost upon closing.  Continue?'],'Close Mission Architect?',yesStr,'No','No');
    else
        response = yesStr;
    end
    
    if(~strcmpi(response,yesStr))
        return;
    else
        if(isMissionPlanSaved(handles))
            askToClear = false;
        else
            askToClear = true;
        end

        if(askToClear)
            response = questdlg(['All unsaved work will be lost.  Continue?'],'Close Mission Architect?',yesStr,'No','No');
        else
            response = yesStr;
        end

        if(~strcmpi(response,yesStr))
            return;
        end

        delete(hObject);
    end


% --- Executes on slider movement.
function warnAlertsSlider_Callback(hObject, eventdata, handles)
% hObject    handle to warnAlertsSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    handleExecErrorsWarnings(false)

% --- Executes during object creation, after setting all properties.
function warnAlertsSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to warnAlertsSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --------------------------------------------------------------------
function viewStateAfterSelectedEventCMenu_Callback(hObject, eventdata, handles)
% hObject    handle to viewStateAfterSelectedEventCMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    viewStateAfterSelectedEventMenu_Callback([], [], handles);

% --------------------------------------------------------------------
function advanceScriptToEventCMenu_Callback(hObject, eventdata, handles)
% hObject    handle to advanceScriptToEventCMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    advanceScriptToEventMenu_Callback([], [], handles);

% --------------------------------------------------------------------
function scriptListboxContext_Callback(hObject, eventdata, handles)
% hObject    handle to scriptListboxContext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function celBodyCatalogMenu_Callback(hObject, eventdata, handles)
% hObject    handle to celBodyCatalogMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    ma_CelBodyCatalogGUI(celBodyData);
    

% --------------------------------------------------------------------
function graphicalAnalysisMenu_Callback(hObject, eventdata, handles)
% hObject    handle to graphicalAnalysisMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    ma_GraphicalAnalysisGUI(handles.ma_MainGUI);


% --------------------------------------------------------------------
function otherSCMenu_Callback(hObject, eventdata, handles)
% hObject    handle to otherSCMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    ma_UndoRedoAddState(handles, 'Edit Other Spacecraft');
    ma_OtherSpacecraftGUI(handles.ma_MainGUI,handles.ksptotMainGUI);
    
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    
    maData.stateLog = ma_executeScript(maData.script,handles,celBodyData,handles.scriptWorkingLbl);
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    ma_processData(handles);

% --------------------------------------------------------------------
function groundTargetsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to groundTargetsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    ma_UndoRedoAddState(handles, 'Edit Ground Stations');
    ma_GroundStationsGUI(handles.ma_MainGUI);


% --------------------------------------------------------------------
function uploadDVManeuverMenu_Callback(hObject, eventdata, handles)
% hObject    handle to uploadDVManeuverMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uploadSelectedDVManuever(handles);

% --------------------------------------------------------------------
function uploadDVManeuverContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to uploadDVManeuverContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uploadSelectedDVManuever(handles);


function uploadSelectedDVManuever(handles)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    eventNum = get(handles.scriptListbox,'value');
    script = maData.script;
    stateLog = maData.stateLog;
    
    event = script{eventNum};
    if(isfield(event,'type') && strcmpi(event.type,'DV_Maneuver'))
        statePre = stateLog(stateLog(:,13)==eventNum-1,:);
        statePre = statePre(end,:);
        
        statePost = stateLog(stateLog(:,13)==eventNum,:);
        statePost = statePost(end,:);
        
        if(strcmpi(event.maneuverType,'finite_steered') || strcmpi(event.maneuverType,'dv_orbit'))
            deltaV_NTW = 1000*event.maneuverValue;
        elseif(strcmpi(event.maneuverType,'circularize'))
            deltaV_XYZ = (statePost(1,5:7)' - statePre(1,5:7)');
            deltaV_NTW = getNTWdvVect(deltaV_XYZ, statePre(1,2:4)', statePre(1,5:7)');
            deltaV_NTW = 1000*deltaV_NTW;
        else
            deltaV_XYZ = 1000*event.maneuverValue;
            deltaV_NTW = getNTWdvVect(deltaV_XYZ, statePre(1,2:4)', statePre(1,5:7)');
            deltaV_NTW = 1000*deltaV_NTW;
        end

        data(1) = 0;
        data(2) = statePre(1,1);
        data(3) = deltaV_NTW(1);
        data(4) = deltaV_NTW(2);
        data(5) = deltaV_NTW(3);
        
        uploadManeuverToKSP(data);
    else
        errordlg('Error: Selected Event is Not of Type DV_Maneuver','Upload Failed!');
        return;
    end
    
    


% --------------------------------------------------------------------
function createCreatesFromEventContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to createCreatesFromEventContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    
    eventNum = get(handles.scriptListbox,'value');
    script = maData.script;
    stateLog = maData.stateLog;
    state = stateLog(stateLog(:,13)==eventNum,:);
    state = state(end,:);
    
    eventID = ma_GetEventIDByEventNum(eventNum, script);
    
    if(isempty(maData.optimizer.constraints))
        actConsts = {};
    else
        actConsts = maData.optimizer.constraints{1};
    end
    
    types = ma_SelectConstraintTypesGUI();
    if(~isempty(types))
        ma_UndoRedoAddState(handles, 'Create Constraints from Selected Post-Event State');
        
        for(i=1:length(types))
            type = types{i};
            constStr = ma_getConstraintStr(type, eventNum);
            [unit, lbLim, ubLim, ~, ~, ~, ~] = ma_getConstraintStaticDetails(type);

            value = ma_getStateValue(state, type, celBodyData);
            lbVal = value;
            ubVal = value;
            body = state(8);

            actConsts = ma_getConstCellArr(actConsts, constStr, [], type, unit, lbLim, ubLim, lbVal, ubVal, body, eventNum, eventID, -1, true, true);
        end

        maData.optimizer.constraints{1} = actConsts;
        setappdata(handles.ma_MainGUI,'ma_data',maData);
        helpdlg(['Constraints for Event ', num2str(eventNum), ' created successfully!  Constraints may be viewed and edited in the Mission Optimizer.'],'Constraints Created');
    end
    
    
% --------------------------------------------------------------------
function createCreatesFromEventMenu_Callback(hObject, eventdata, handles)
% hObject    handle to createCreatesFromEventMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    createCreatesFromEventContextMenu_Callback(handles.createCreatesFromEventContextMenu, [], handles);

% --------------------------------------------------------------------
function scriptExecSettings_Callback(hObject, eventdata, handles)
% hObject    handle to scriptExecSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    
    maData = ma_updateMAData(maData, handles);
    
    strictSoISearch = maData.settings.strictSoISearch;
    if(strictSoISearch==true)
        set(handles.useStrictSoISearchMenu, 'Checked', 'on');
    else
        set(handles.useStrictSoISearchMenu, 'Checked', 'off');
    end
    
    useSelectiveSoISearch = maData.settings.useSelectiveSoISearch;
    if(useSelectiveSoISearch==true)
        set(handles.useSelectiveSoISearchMenu, 'Checked', 'on');
    else
        set(handles.useSelectiveSoISearchMenu, 'Checked', 'off');
    end
    
    parallelOptim = maData.settings.parallelScriptOptim;
    if(parallelOptim==true)
        set(handles.parallelizeScriptOptimizationMenu, 'Checked', 'on');
    else
        set(handles.parallelizeScriptOptimizationMenu, 'Checked', 'off');
    end


% --------------------------------------------------------------------
function useStrictSoISearchMenu_Callback(hObject, eventdata, handles)
% hObject    handle to useStrictSoISearchMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global strict_SoI_search;

    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    writeOutput = getappdata(handles.ma_MainGUI,'write_to_output_func');
    
    if strcmp(get(gcbo, 'Checked'),'on')
        set(gcbo, 'Checked', 'off');
        maData.settings.strictSoISearch = false;
        writeOutput('Strict SoI search mode disabled.','append');
    else
        set(gcbo, 'Checked', 'on');
        maData.settings.strictSoISearch = true;
        writeOutput('Strict SoI search mode enabled.','append');
    end
    strict_SoI_search = maData.settings.strictSoISearch;
    
    maData.stateLog = ma_executeScript(maData.script,handles,celBodyData,handles.scriptWorkingLbl);
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    ma_processData(handles);
    
    setappdata(handles.ma_MainGUI,'ma_data',maData);


% --------------------------------------------------------------------
function parallelizeScriptOptimizationMenu_Callback(hObject, eventdata, handles)
% hObject    handle to parallelizeScriptOptimizationMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    writeOutput = getappdata(handles.ma_MainGUI,'write_to_output_func');
    
    if strcmp(get(gcbo, 'Checked'),'on')
        set(gcbo, 'Checked', 'off');
        maData.settings.parallelScriptOptim = false;
        writeOutput('Parallel optimization mode disabled.','append');
    else
        set(gcbo, 'Checked', 'on');
        maData.settings.parallelScriptOptim = true;
        
        numWorkers = maData.settings.numParallelWorkers;
        
        drawnow;
        p = gcp('nocreate');
        if(isempty(p))
            startParallelWorkers(writeOutput, numWorkers);
        else
            writeOutput('Parallel optimization mode enabled.','append');
        end
    end
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    
function startParallelWorkers(writeOutput, numWorkers)
    try
        h = msgbox('Attempting to start parallel computing workers.  Please wait...','modal');
        pp=parpool('local',numWorkers);
        pp.IdleTimeout = 99999; %we don't want the pool to shutdown
        if(ishandle(h))
            close(h);
        end
        writeOutput('Parallel optimization mode enabled.','append');
    catch ME
        if(ishandle(h))
            close(h);
        end
        msgbox(sprintf('Parallel mode start failed.  Optimization will run in serial.  Message:\n\n%s',ME.message));
        disp(ME.message);
    end    

   

% --------------------------------------------------------------------
function missionAnimatorMenu_Callback(hObject, eventdata, handles)
% hObject    handle to missionAnimatorMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    ma_MissionAnimatorGUI(handles.ma_MainGUI);


% --------------------------------------------------------------------
function dragCoeffCalcMenu_Callback(hObject, eventdata, handles)
% hObject    handle to dragCoeffCalcMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    ma_AerobrakingCdCalcGUI(handles.ma_MainGUI);


% --------------------------------------------------------------------
function getManeuverNodesFromKSPActiveVessel_Callback(hObject, eventdata, handles)
% hObject    handle to getManeuverNodesFromKSPActiveVessel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');

    nodes = getManeuverNodesFromKSPActiveVessel();
    if(isempty(nodes))
        warndlg('Could not find any maneuver nodes on active vessel in KSP.  Are you running KSP in the flight scene with KSPTOTConnect loaded?','No Manuever Nodes Found');
        return;
    end
    
    ma_UndoRedoAddState(handles, 'Get Maneuver Nodes From KSP (Active Vessel)');
    
    nodes = sortrows(nodes,1);
    beforeMissionUTs = [];
    
    stateLog = maData.stateLog;
    script = maData.script;
    for(i=1:size(nodes,1))
        node = nodes(i,:);
        ut = node(1);
        radial = node(2) / 1000; %m/s -> km/s
        normal = node(3) / 1000; %m/s -> km/s
        prograde = node(4) / 1000; %m/s -> km/s
        
        dvVect = [prograde, normal, radial];
        dvVars = [false false false; prograde normal radial; prograde normal radial];
        dvThruster = maData.spacecraft.thrusters{1};
        
        if(ut >= stateLog(1,1) && ut <= stateLog(end,1)) %occurs in between current mission start and end
            stateLogUTs = stateLog(:,1);
            lastUT = stateLogUTs(stateLogUTs <= ut);
            lastUT = lastUT(end);
            lastUTInd = stateLogUTs == lastUT;
            
            lastUTStateLog = stateLog(lastUTInd,:);
            eventNum = lastUTStateLog(13);  
            
            lossConvert = getDefaultLossConvert(handles);
            newMassLoss.use = false;
            newMassLoss.lossConvert = lossConvert;
            
            preList = script(1:eventNum-1);
            postList = script(eventNum:end);
            newCoast = ma_createCoast(['To Node ', num2str(i)], 'goto_ut', ut, 0.0, [], [0;ut;ut], [], 'k', '-', 1.5, newMassLoss, [], 0.0, getDefaultOrbitDecay());
            newDV = ma_createDVManeuver(['Node ', num2str(i)], 'dv_orbit', dvVect, dvThruster, dvVars, 'r', '-', 1.5);
            script = [preList, newCoast, newDV, postList];

            maData.script = script;
            maData.stateLog = ma_executeScript(maData.script,handles,celBodyData,handles.scriptWorkingLbl);
            setappdata(handles.ma_MainGUI,'ma_data',maData);
            ma_processData(handles);

            maData = getappdata(handles.ma_MainGUI,'ma_data');
            stateLog = maData.stateLog;
            script = maData.script;
            
        elseif(ut >= stateLog(end,1)) %after current mission
            lossConvert = getDefaultLossConvert(handles);
            massLoss.use = false;
            massLoss.lossConvert = lossConvert;
            newCoast = ma_createCoast(['Coast To Node ', num2str(i)], 'goto_ut', ut, 0.0, [], [0;ut;ut], [], 'k', '-', 1.5, massLoss, [], 0.0, getDefaultOrbitDecay());
            newDV = ma_createDVManeuver(['Node ', num2str(i)], 'dv_orbit', dvVect, dvThruster, dvVars, 'r', '-', 1.5);
            
            script{end+1} = newCoast; %#ok<AGROW>
            script{end+1} = newDV; %#ok<AGROW>
        elseif(ut < stateLog(1,1)) %before start of mission, disregard
            beforeMissionUTs(end+1) = ut; %#ok<AGROW>
            continue;
        end
    end
    
    maData.script = script;
    maData.stateLog = ma_executeScript(maData.script,handles,celBodyData,handles.scriptWorkingLbl);
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    ma_processData(handles);


% --------------------------------------------------------------------
function deltaVBudgetMenu_Callback(hObject, eventdata, handles)
% hObject    handle to deltaVBudgetMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    
    dvBudget = cell(0,3);
    dvBudgetSum = 0;
    script = maData.script;
    stateLog = maData.stateLog;
    hasEvents = false;
    for(i=1:length(script))
        event = script{i};
        
        if(strcmpi(event.type,'DV_Maneuver'))
            if(strcmpi(event.maneuverType,'circularize'))
                eventLog = stateLog(stateLog(:,13)==i,:);
                eventLog = eventLog(end,:);
                preEventLog = stateLog(stateLog(:,13)==i-1,:);
                preEventLog = preEventLog(end,:);
                
                postEventV = eventLog(5:7);
                preEventV = preEventLog(5:7);
                dvEvent = 1000*norm(postEventV-preEventV);
            else
                dvEvent = 1000*norm(event.maneuverValue);
            end
            dvBudget(end+1,:) = {i, event.name, dvEvent}; %#ok<AGROW>
            dvBudgetSum = dvBudgetSum + dvEvent;
            hasEvents = true;
        end
    end
    dvBudget(end+1,:) = {-1, 'Sum ', dvBudgetSum};
    
    dbBudgetStr = {};
    dbBudgetStr{end+1,1} = 'Event # |           Event Name           | Delta-v [m/s]';
    dbBudgetStr{end+1,1} = '--------------------------------------------------------';
    for(i=1:size(dvBudget,1)-1)
        id = dvBudget{i,1};
        eventName = dvBudget{i,2};
%         if(length(eventName)>14)
%             eventName = eventName(1:14);
%         end
        eventName = strjust(sprintf('%32s',eventName),'center');
        idStr = strjust(sprintf('%8i',id),'center');
        dvBudgetStr = strjust(sprintf('%14.3f',dvBudget{i,3}),'center');
        if(id <= 0)
%             id = '      ';
            dbBudgetStr{end+1,1} = sprintf('%8s|%32s|%14s', idStr, eventName, dvBudgetStr); %#ok<AGROW>
        else
            dbBudgetStr{end+1,1} = sprintf('%8s|%32s|%14s', idStr, eventName, dvBudgetStr); %#ok<AGROW>
        end
    end
    i = size(dvBudget,1);
    id = '      ';
    eventName = dvBudget{i,2};
    eventName = [strjust(sprintf('%31s',eventName),'right'), ' '];
    idStr = strjust(sprintf('%8s',id),'center');
    dvBudgetStr = strjust(sprintf('%14.3f',dvBudget{i,3}),'center');
    if(hasEvents==true)
        dbBudgetStr{end+1,1} = '--------------------------------------------------------';
    end
    dbBudgetStr{end+1,1} = sprintf('%8s|%32s|%14s', idStr, eventName, dvBudgetStr);

    ma_DeltaVBudgetGUI(dbBudgetStr);


% --------------------------------------------------------------------
function convertImpulseManeuverMenu_Callback(hObject, eventdata, handles)
% hObject    handle to convertImpulseManeuverMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    eventNum = get(handles.scriptListbox,'value');
    script = maData.script;
    stateLog = maData.stateLog;
    
    errorIsNotImpulsive = false;
    errorPreEventIsNotCoast = false;
    errorPreCoastIsNotLongEnough = false;
    event = script{eventNum};
    if(strcmpi(event.type,'DV_Maneuver'))
        dvVect = event.maneuverValue;
        
        if(eventNum == 1)
            errorIsNotImpulsive = true;
        else   
            prevEventId = eventNum-1;
            prevEvent = script{prevEventId};
            prevEventStateLog = stateLog(stateLog(:,13)==prevEventId,:);
            prevEventStartState = prevEventStateLog(1,:);
            prevEventEndState = prevEventStateLog(end,:);
            
            m0 = sum(prevEventEndState(9:12));
            thruster = event.thruster;
            vars = event.vars;
            isp = thruster.isp;
            thrust = thruster.thrust;
            mdot = getMdotFromThrustIsp(thrust, isp);
            dvMag = norm(dvVect);
            burnDur = getBurnDuration(m0, mdot, isp, dvMag);
            
            if(~strcmpi(prevEvent.type,'Coast'))
                errorPreEventIsNotCoast = true;
            else
                coastDur = prevEventEndState(1) - prevEventStartState(1);
                if(burnDur/2 >= coastDur)
                    errorPreCoastIsNotLongEnough = true;
                else
                    coastDt = coastDur - burnDur/2;
                    if(strcmpi(event.maneuverType,'dv_inertial') || strcmpi(event.maneuverType,'dv_orbit'))
                        ma_UndoRedoAddState(handles, 'Convert Impulsive Maneuver');
                        
                        if(strcmpi(event.maneuverType,'dv_inertial'))
                            type = 'finite_inertial';
                        elseif(strcmpi(event.maneuverType,'dv_orbit'))
                            type = 'finite_steered';
                        end
                        
                        nameManeuver = [event.name, ' (Converted)'];
                        newManeuver = ma_createDVManeuver(nameManeuver, type, dvVect, thruster, vars, 'r', '-', 1.5);
                        
                        nameCoast = [prevEvent.name, ' (Converted)'];
                        coastVars = [0;coastDt;coastDt];
                        newCoast = ma_createCoast(nameCoast, 'goto_dt', coastDt, 0, [], coastVars, [], prevEvent.lineColor, prevEvent.lineStyle, prevEvent.lineWidth, prevEvent.massloss, prevEvent.funcHandle, prevEvent.maxPropTime, prevEvent.orbitDecay);
                        
                        preList = script(1:prevEventId-1);
                        if(eventNum==length(script))
                            postList = [];
                        else
                            postList = script(eventNum+1:end);
                        end
                        newScript = [preList, newCoast, newManeuver, postList];
                        
                        maData.script = newScript;
                        maData.stateLog = ma_executeScript(maData.script,handles,celBodyData,handles.scriptWorkingLbl);
                        setappdata(handles.ma_MainGUI,'ma_data',maData);
                        ma_processData(handles);
                    else
                        errorIsNotImpulsive = true;
                    end
                end
            end
        end
    else 
        errorIsNotImpulsive = true;
    end
    
    errmsg = '';
    if(errorIsNotImpulsive)
        errmsg = 'The selected event must be an impulsive ("Proscribed Delta-v") DV Maneuver in order to convert it.';
    elseif(errorPreEventIsNotCoast)
        errmsg = 'The event prior to the selected impulsive maneuver must be a coast with a duration greater than half the length of the new, finite maneuver.';
    elseif(errorPreCoastIsNotLongEnough)
        errmsg = 'The event prior to the selected impulsive maneuver must be a coast with a duration greater than half the length of the new, finite maneuver.  The coast is too short.';
    end
    
    if(~isempty(errmsg))
        errordlg(errmsg,'Could Not Convert Maneuver');
    end


% --------------------------------------------------------------------
function launchWindowAnalysisMenu_Callback(hObject, eventdata, handles)
% hObject    handle to launchWindowAnalysisMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    ma_launchWindowAnalysisToolGUI(handles.ma_MainGUI, handles.ksptotMainGUI);


% --------------------------------------------------------------------
function splitImpulseManeuverMenu_Callback(hObject, eventdata, handles)
% hObject    handle to splitImpulseManeuverMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    eventNum = get(handles.scriptListbox,'value');
    script = maData.script;
    stateLog = maData.stateLog;
    
    errorIsNotImpulsive = false;
    errorBadNumBurnInput = false;
    errorOrbitHyperbolic = false;
    orbitHyperbolicOnBurn = -1;
    
    event = script{eventNum};
    preEvents = script(1:eventNum-1);
    postEvents = script(eventNum+1:end);
    burnIniState = stateLog(stateLog(:,13)==eventNum-1,:);
    burnIniState = burnIniState(end,:);
    iniStateMass = sum(burnIniState(9:12));
    if(strcmpi(event.type,'DV_Maneuver'))
        if(strcmpi(event.maneuverType,'dv_inertial') || strcmpi(event.maneuverType,'dv_orbit'))
            dvVect = event.maneuverValue;
            
            numBurns = inputdlg('Split burn into how many burns? (2-10)','How many burns?',1,{'3'});
            if(isempty(numBurns))
                return;
            end
            numBurns = str2double(numBurns);
            if(~isnan(numBurns) && isfinite(numBurns) && numBurns>=2 && numBurns<=10)
                totalDeltaV = 1000*norm(dvVect);
                isp = event.thruster.isp;
                m0 = iniStateMass;
                mdot = getMdotFromThrustIsp(event.thruster.thrust, isp); %kN/sec
                [burnValues, type] = ma_SplitDvManeuverGUI(numBurns,totalDeltaV,isp, m0, mdot);
                if(isempty(burnValues))
                    return;
                end
                
                totalTime = getBurnDuration(m0, mdot, isp, totalDeltaV/1000);
                
                newEvents = cell(0,1);
                deltaM0 = 0;
                for(i=1:size(burnValues,1))
                    row = burnValues(i,:);
                    
                    newEvent = event;
                    
                    switch type
                        case 'DV'
                            newDv = dvVect * row(2);
                        case 'Time'
                            newTime = totalTime * row(2);
                            dv = isp*getG0()*log((m0-deltaM0)/((m0-deltaM0)-mdot*newTime));
                            newDv = normVector(dvVect) * dv/1000;
                            
                            deltaM0 = deltaM0+mdot*newTime;
                    end
                    
                    newDv = reshape(newDv,1,3);
                    newEvent.maneuverValue = newDv;
                    vars = [0 0 0; newDv; newDv];
                    newEvent.vars = vars;
                    newEvent.name = [event.name, ' (Split ', num2str(i), ')'];
                    newEvent.id = rand(1);
                    
                    newEvents{end+1} = newEvent; %#ok<AGROW>
                    state = ma_executeDVManeuver(newEvent, burnIniState, -1, celBodyData);
                    state = state(end,:);
    
                    bodyInfo = getBodyInfoByNumber(state(8), celBodyData);
                    gmu = bodyInfo.gm;
                    rVect = state(2:4)';
                    vVect = state(5:7)';
                    [sma, ~, ~, ~, ~, ~] = getKeplerFromState(rVect,vVect,gmu);
                    
                    try
                        period = computePeriod(sma, gmu);
                    catch
                        period = NaN;
                    end
                    
                    if(i == size(burnValues,1) || ~isnan(period))
                        burnIniState = state;
                        if(i < size(burnValues,1))
                            vars = [0; period; period];
                            lossConvert = getDefaultLossConvert(handles);
                            massLoss.use = false;
                            massLoss.lossConvert = lossConvert;
                            newCoast = ma_createCoast('Coast (From Split)', 'goto_dt', period, 0, [], vars, [], 'k', '-', 1.5, massLoss, [], 0.0, getDefaultOrbitDecay());
                            newEvents{end+1} = newCoast; %#ok<AGROW>
                        end
                    else
                        errorOrbitHyperbolic = true;
                        orbitHyperbolicOnBurn = i;
                    end                    
                end
            else
                errorBadNumBurnInput = true;
            end
        else
            errorIsNotImpulsive = true;
        end
    end
    
    errmsg = '';
    if(errorIsNotImpulsive)
        errmsg = 'The selected event must be an impulsive ("Proscribed Delta-v") DV Maneuver in order to convert it.';
    elseif(errorBadNumBurnInput)
        errmsg = 'The number of burns entered must be numeric and between 2 and 10 inclusive.';
    elseif(errorOrbitHyperbolic)
        errmsg = ['While splitting the burns, the orbit went hyperbolic after burn #', num2str(orbitHyperbolicOnBurn)];
    end
    
    if(~isempty(errmsg))
        errordlg(errmsg,'Could Not Split Maneuver');
    else
        ma_UndoRedoAddState(handles, 'Split Impulsive Maneuver');
        
        newScript = [preEvents, newEvents, postEvents];
        maData.script = newScript;
        maData.stateLog = ma_executeScript(maData.script,handles,celBodyData,handles.scriptWorkingLbl);
        setappdata(handles.ma_MainGUI,'ma_data',maData);
        ma_processData(handles);
    end


% --------------------------------------------------------------------
function openFigFileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to openFigFileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    [fileName,pathName,~] = uigetfile('*.fig','Select MATLAB Figure (*.fig) File to Open...');
    if(~isequal(fileName,0))
        file = [pathName,filesep,fileName];
        openfig(file,'new');
    end


% --- Executes on button press in showOtherSpacecraftCheckBox.
function showOtherSpacecraftCheckBox_Callback(hObject, eventdata, handles)
% hObject    handle to showOtherSpacecraftCheckBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showOtherSpacecraftCheckBox
    ma_processData(handles);


% --- Executes on button press in showChildBodyMarker.
function showChildBodyMarker_Callback(hObject, eventdata, handles)
% hObject    handle to showChildBodyMarker (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showChildBodyMarker
    ma_processData(handles);


% --------------------------------------------------------------------
function setNumStateLogEntriesPerEventMenu_Callback(hObject, eventdata, handles)
% hObject    handle to setNumStateLogEntriesPerEventMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global number_state_log_entries_per_coast;

    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    writeOutput = getappdata(handles.ma_MainGUI,'write_to_output_func');

    input_str = sprintf(['Enter the desired number of state log entries per coast:\n',...
                         '(Minimum = 5, Maximum = 100,000)\n',...
                         '(This will influence script execution speed and SoI transition search.)']);
    str = inputdlg(input_str, 'State Log Entries Per Coast', [1 75], {num2str(maData.settings.numStateLogPtsPerCoast)});
    
    if(isempty(str))
        return;
    end
    str = str{1};
    
    if(checkStrIsNumeric(str) && round(str2double(str)) >= 5 && round(str2double(str)) <= 100000)
        writeOutput(sprintf('Setting number of state log entries per event to %s.', str),'append');
        
        number_state_log_entries_per_coast = round(str2double(str));
        maData.settings.numStateLogPtsPerCoast = number_state_log_entries_per_coast;
        
        setappdata(handles.ma_MainGUI,'ma_data',maData);
        maData.stateLog = ma_executeScript(maData.script,handles,celBodyData,handles.scriptWorkingLbl);
        setappdata(handles.ma_MainGUI,'ma_data',maData);
        ma_processData(handles);
    else
        writeOutput(sprintf('Could not set number of state log entries per event.  "%s" is an invalid entry.', str),'append');
        beep;
    end


% --------------------------------------------------------------------
function setNumSoISearchRevsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to setNumSoISearchRevsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global num_SoI_search_revs;
    
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    writeOutput = getappdata(handles.ma_MainGUI,'write_to_output_func');
    
    input_str = sprintf(['Enter the desired number of SoI search revolutions:\n',...
                         '(Minimum = 1, Maximum = 100)\n',...
                         '(This will influence script execution speed and SoI transition search.)']);
    str = inputdlg(input_str, 'Number SoI Search Revs', [1 75], {num2str(maData.settings.numSoISearchRevs)});
    if(isempty(str))
        return;
    end
    
    str = str{1};
    
    if(checkStrIsNumeric(str) && round(str2double(str)) >= 1 && round(str2double(str)) <= 100)
        writeOutput(sprintf('Setting number of SoI search revolutions to %s.', str),'append');
        
        num_SoI_search_revs = round(str2double(str));
        maData.settings.numSoISearchRevs = num_SoI_search_revs;
        
        setappdata(handles.ma_MainGUI,'ma_data',maData);
        maData.stateLog = ma_executeScript(maData.script,handles,celBodyData,handles.scriptWorkingLbl);
        setappdata(handles.ma_MainGUI,'ma_data',maData);
        ma_processData(handles);
    else
        writeOutput(sprintf('Could not set number of SoI search revolutions.  "%s" is an invalid entry.', str),'append');
        beep;
    end


% --------------------------------------------------------------------
function useSelectiveSoISearchMenu_Callback(hObject, eventdata, handles)
% hObject    handle to useSelectiveSoISearchMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global use_selective_soi_search;

    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    writeOutput = getappdata(handles.ma_MainGUI,'write_to_output_func');
    
    if strcmp(get(gcbo, 'Checked'),'on')
        set(gcbo, 'Checked', 'off');
        maData.settings.useSelectiveSoISearch = false;
        writeOutput('Selective SoI search mode disabled.','append');
    else
        set(gcbo, 'Checked', 'on');
        maData.settings.useSelectiveSoISearch = true;
        writeOutput('Selective SoI search mode enabled.','append');
    end
    use_selective_soi_search = maData.settings.useSelectiveSoISearch;
    
    maData.stateLog = ma_executeScript(maData.script,handles,celBodyData,handles.scriptWorkingLbl);
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    ma_processData(handles);
    
    setappdata(handles.ma_MainGUI,'ma_data',maData);


% --------------------------------------------------------------------
function commNetworkAnalysisMenu_Callback(hObject, eventdata, handles)
% hObject    handle to commNetworkAnalysisMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    ma_commNetworkAnalysisGUI(handles.ma_MainGUI);


% --------------------------------------------------------------------
function copyUtAtStartOfSelectedEvent_Callback(hObject, eventdata, handles)
% hObject    handle to copyUtAtStartOfSelectedEvent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    stateLog = maData.stateLog;
    selEvent = get(handles.scriptListbox,'Value');
    
    eventLog = stateLog(stateLog(:,13)==selEvent,1);

    clipboard('copy', fullAccNum2Str(eventLog(1,1)));

% --------------------------------------------------------------------
function copyUtAtEndOfSelectedEvent_Callback(hObject, eventdata, handles)
% hObject    handle to copyUtAtEndOfSelectedEvent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    stateLog = maData.stateLog;
    selEvent = get(handles.scriptListbox,'Value');
    
    eventLog = stateLog(stateLog(:,13)==selEvent,1);

    clipboard('copy', fullAccNum2Str(eventLog(end,1)));


% --------------------------------------------------------------------
function editCommMaxRangeMenu_Callback(hObject, eventdata, handles)
% hObject    handle to editCommMaxRangeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    writeOutput = getappdata(handles.ma_MainGUI,'write_to_output_func');
    
    input_str = sprintf(['Enter the maximum range of the comm antenna of this vessel in kilometers (km):\n',...
                         '(Minimum = 0, Maximum = Inf)\n']);
    str = inputdlg(input_str, 'Max Comm Range', [1 85], {num2str(maData.spacecraft.comm.maxCommRange)});
    if(isempty(str))
        return;
    end
    
    str = str{1};
    
    if(checkStrIsNumeric(str) && round(str2double(str)) >= 0 && round(str2double(str)) <= Inf)
        writeOutput(sprintf('Setting spacecraft maximum comm range to %s km.', str),'append');
        
        maData.spacecraft.comm.maxCommRange = str2double(str);
        
        setappdata(handles.ma_MainGUI,'ma_data',maData);
        maData.stateLog = ma_executeScript(maData.script,handles,celBodyData,handles.scriptWorkingLbl);
        setappdata(handles.ma_MainGUI,'ma_data',maData);
        ma_processData(handles);
    else
        writeOutput(sprintf('Could not maximum comm range.  "%s" is an invalid entry.', str),'append');
        beep;
    end


% --------------------------------------------------------------------
function astroCalcsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to astroCalcsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    ma_AstroCalculatorsGUI(celBodyData);


% --------------------------------------------------------------------
function launchTrajAnalysisMenu_Callback(hObject, eventdata, handles)
% hObject    handle to launchTrajAnalysisMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    ma_LaunchTrajectoryGUI(handles.ma_MainGUI);


% --------------------------------------------------------------------
function editMissionNotesMenu_Callback(hObject, eventdata, handles)
% hObject    handle to editMissionNotesMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    ma_UndoRedoAddState(handles, 'Edit Mission Notes');
    ma_MissionNotesGUI(handles.ma_MainGUI);


% --------------------------------------------------------------------
function copyDurationOfSelectedEventMenu_Callback(hObject, eventdata, handles)
% hObject    handle to copyDurationOfSelectedEventMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    stateLog = maData.stateLog;
    selEvent = get(handles.scriptListbox,'Value');
    
    eventLog = stateLog(stateLog(:,13)==selEvent,1);

    if(selEvent > 1)
        preEventLog = stateLog(stateLog(:,13)==selEvent-1,1);
        eventLog = [preEventLog(end); eventLog];
    end
    
    clipboard('copy', fullAccNum2Str(eventLog(end,1) - eventLog(1,1)));


% --------------------------------------------------------------------
function editPropNamesMenu_Callback(hObject, eventdata, handles)
% hObject    handle to editPropNamesMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');

    propNames = inputdlg({'Enter Name of First Propellant:','Enter Name of Second Propellant:','Enter Name of Third Propellant:'},'Test Title', ...
                         [1,1,1]', maData.spacecraft.propellant.names,'on');
	if(~isempty(propNames) && length(propNames)==3)
        ma_UndoRedoAddState(handles, 'Update Propellant Names');
        maData.spacecraft.propellant.names = strtrim(propNames');

        setappdata(handles.ma_MainGUI,'ma_data',maData);
        maData.stateLog = ma_executeScript(maData.script,handles,celBodyData,handles.scriptWorkingLbl);
        setappdata(handles.ma_MainGUI,'ma_data',maData);
        ma_processData(handles);
	end


% --------------------------------------------------------------------
function createTrajectoryMapMenu_Callback(hObject, eventdata, handles)
% hObject    handle to createTrajectoryMapMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
	maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    stateLog = maData.stateLog;
    script = maData.script;

    centralBodyIds = unique(stateLog(:,8));
    centralBodies = cell(1,length(centralBodyIds));
    centralBodyNames = cell(1,length(centralBodyIds));
	for(i=1:length(centralBodyIds))
        bodyInfo = getBodyInfoByNumber(centralBodyIds(i), celBodyData);
        centralBodies{i} = bodyInfo;
        centralBodyNames{i} = bodyInfo.name;
	end
    
	[Selection,ok] = listdlg('ListString',centralBodyNames,...
                             'SelectionMode','single',...
                             'Name','Map Central Body',...
                             'PromptString','Select the map central body:');
                         
	if(ok == 0)
        return;
	end
                         
    centralBodyId = centralBodyIds(Selection);
    eventIds = unique(stateLog(stateLog(:,8)==centralBodyId,13));
    events = script(eventIds);
    
    eventNames = cell(1,length(events));
    for(i=1:length(events))
        eventNames{i} = events{i}.name;
    end
    
	[Selection,ok] = listdlg('ListString',eventNames,...
                             'SelectionMode','multiple',...
                             'Name','Map Events',...
                             'InitialValue',[1:length(eventNames)],...
                             'PromptString','Select the map events to plot:');
                         
	if(ok == 0)
        return;
	end
    
    eventIds = eventIds(Selection);
    cBodyInfo = getBodyInfoByNumber(centralBodyId, celBodyData);
    [children, childrenNames] = getChildrenOfParentInfo(celBodyData, cBodyInfo.name);
    
    if(~isempty(children))
        plotChildren = questdlg('Do you wish to plot the orbits of the child bodies of the central body?','Plot Children?','Yes','No','Yes'); 
        if(strcmpi(plotChildren,'Yes'))
            plotChildren = true;
        else
            plotChildren = false;
        end
    else
        plotChildren = false;
    end
    
    if(plotChildren)
        if(length(childrenNames)>1)
            [Selection,ok] = listdlg('ListString',childrenNames,...
                                     'SelectionMode','multiple',...
                                     'Name','Plot Children',...
                                     'InitialValue',[1:length(childrenNames)],...
                                     'PromptString','Which child bodies would you like to plot?');
        else
            Selection = 1;
        end
                             
        if(ok == 0)
            Selection = 1:length(children);
        end
        
        children = children(Selection);
    end
    
    hFig = figure('Name','Mission Architect Trajectory Map','NumberTitle','off');
    hAxis = axes();
    axes(hAxis);
    cla(hAxis, 'reset');
       
    hCBodySurf = ma_initOrbPlot(hFig, hAxis, cBodyInfo);
    set(hCBodySurf,'EdgeColor','none');
    
    set(hAxis,'Color',[0 0 0]);
    set(hAxis,'XTick',[], 'XTickMode', 'manual');
    set(hAxis,'YTick',[], 'YTickMode', 'manual');
    set(hAxis,'ZTick',[], 'ZTickMode', 'manual');

    hold on;
    bColorRGB = colorFromColorMap(cBodyInfo.bodycolor);
    plot3(0, 0, 0,'Marker','o','MarkerEdgeColor',bColorRGB,'MarkerFaceColor',bColorRGB,'MarkerSize',3);
    
    if(plotChildren)        
        gmu = cBodyInfo.gm;
        for(i=1:length(children))
            childBody = children{i};
            bColorRGB = colorFromColorMap(childBody.bodycolor);

            hold on;
            plotBodyOrbit(childBody, bColorRGB, gmu);
        end
    end
    
    lineSpec = {'-.','-','--'};
    for(i=1:length(eventIds))
        eventId = eventIds(i);
        ind = mod(i,3)+1;
        
        stateLogToPlot = stateLog(stateLog(:,8)==centralBodyId & stateLog(:,13)==eventId,:);
        hold on;
        plot3(stateLogToPlot(:,2), stateLogToPlot(:,3), stateLogToPlot(:,4),lineSpec{ind},'Color','w','LineWidth',1.5);
    end
    
    hold on;
    view([0 89]);
    axis equal;
    v = axis;
    axis(v*1.05);
    hold off;
    zoom reset;


% --------------------------------------------------------------------
function copyOrbitAfterSelectedEvent_Callback(hObject, eventdata, handles)
% hObject    handle to copyOrbitAfterSelectedEvent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    eventNum = get(handles.scriptListbox,'value');
    stateLog = maData.stateLog;
    
    state = stateLog(stateLog(:,13)==eventNum,:);
    state = state(end,:);
    
    bodyID = state(8);
    
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    gmu = bodyInfo.gm;
    utSec = state(1);
    rVect = state(2:4)';
    vVect = state(5:7)';
 
    [sma, ecc, inc, raan, arg, tru] = getKeplerFromState(rVect,vVect,gmu);
    clipboardData = [utSec, sma, ecc, inc, raan, arg, tru, bodyID];
    set(handles.copyOrbitAfterSelectedEvent,'UserData',clipboardData);
    copyOrbitToClipboardFromStateLog([],[],handles.copyOrbitAfterSelectedEvent);


% --------------------------------------------------------------------
function exportFigToHtmlMenu_Callback(hObject, eventdata, handles)
% hObject    handle to exportFigToHtmlMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    [fileName,pathName,~] = uigetfile('*.fig','Select MATLAB Figure (*.fig) File to Open...');
    if(~isequal(fileName,0))
        file = [pathName,filesep,fileName];
        h = openfig(file,'new','invisible');
        fig2plotly(h, 'offline', true, 'filename', 'figTest');
    end


% --------------------------------------------------------------------
function setOptimAlgMenu_Callback(hObject, eventdata, handles)
% hObject    handle to setOptimAlgMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    alg = maData.settings.optimAlg;
    
    switch alg
        case 'interior-point'
            set(handles.optimAlgIntPtMenu,'checked','on');
            set(handles.optimAlgSqpMenu,'checked','off');
            set(handles.optimAlgActiveSetMenu,'checked','off');
        case 'sqp'
            set(handles.optimAlgIntPtMenu,'checked','off');
            set(handles.optimAlgSqpMenu,'checked','on');
            set(handles.optimAlgActiveSetMenu,'checked','off');
        case 'active-set'
            set(handles.optimAlgIntPtMenu,'checked','off');
            set(handles.optimAlgSqpMenu,'checked','off');
            set(handles.optimAlgActiveSetMenu,'checked','on');
        otherwise
            maData.settings.optimAlg = 'interior-point';
            setappdata(handles.ma_MainGUI,'ma_data',maData);
            setOptimAlgMenu_Callback(hObject, eventdata, handles);
    end
    

% --------------------------------------------------------------------
function optimAlgIntPtMenu_Callback(hObject, eventdata, handles)
% hObject    handle to optimAlgIntPtMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    ma_UndoRedoAddState(handles, 'Set Optim. Alg. to Interior Point');
    
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    maData.settings.optimAlg = 'interior-point';
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    
    writeOutput = getappdata(handles.ma_MainGUI,'write_to_output_func');
	writeOutput('Optimizer algorithm set to Interior Point.','append');

% --------------------------------------------------------------------
function optimAlgSqpMenu_Callback(hObject, eventdata, handles)
% hObject    handle to optimAlgSqpMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    ma_UndoRedoAddState(handles, 'Set Optim. Alg. to SQP');

    maData = getappdata(handles.ma_MainGUI,'ma_data');
    maData.settings.optimAlg = 'sqp';
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    
    writeOutput = getappdata(handles.ma_MainGUI,'write_to_output_func');
	writeOutput('Optimizer algorithm set to SQP.','append');

% --------------------------------------------------------------------
function optimAlgActiveSetMenu_Callback(hObject, eventdata, handles)
% hObject    handle to optimAlgActiveSetMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    ma_UndoRedoAddState(handles, 'Set Optim. Alg. to Active Set');

    maData = getappdata(handles.ma_MainGUI,'ma_data');
    maData.settings.optimAlg = 'active-set';
    setappdata(handles.ma_MainGUI,'ma_data',maData);

    writeOutput = getappdata(handles.ma_MainGUI,'write_to_output_func');
	writeOutput('Optimizer algorithm set to Active Set.','append');


% --------------------------------------------------------------------
function setSoISearchTolMenu_Callback(hObject, eventdata, handles)
% hObject    handle to setSoISearchTolMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global soi_search_tol;
    
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    writeOutput = getappdata(handles.ma_MainGUI,'write_to_output_func');
    
    input_str = sprintf(['Enter the SoI search tolerance parameter:\n',...
                         '(Minimum = 1E-14, Maximum = 1E-2)\n',...
                         '(The smaller the number, the more precise the search.)\n',...
                         '(This will influence script execution speed and SoI transition search.)']);
    str = inputdlg(input_str, 'SoI Search Tolerance', [1 75], {num2str(maData.settings.soiSearchTol,'%6.6E')});
    if(isempty(str))
        return;
    end
    
    str = str{1};
    
    if(checkStrIsNumeric(str) && str2double(str) >= 1E-14 && str2double(str) <= 1E-2)
        ma_UndoRedoAddState(handles, 'Update SoI Search Tolerance');
        
        writeOutput(sprintf('Setting SoI search tolerance to %s.', str),'append');
        
        soi_search_tol = str2double(str);
        maData.settings.soiSearchTol = soi_search_tol;
        
        setappdata(handles.ma_MainGUI,'ma_data',maData);
        maData.stateLog = ma_executeScript(maData.script,handles,celBodyData,handles.scriptWorkingLbl);
        setappdata(handles.ma_MainGUI,'ma_data',maData);
        ma_processData(handles);
    else
        writeOutput(sprintf('Could not set SoI search tolerance.  "%s" is an invalid entry.', str),'append');
        beep;
    end


% --------------------------------------------------------------------
function perturbOptimVarsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to perturbOptimVarsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    script = maData.script;
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    writeOutput = getappdata(handles.ma_MainGUI,'write_to_output_func');
    
    %questdlg
    input_str = sprintf(['Enter the percentage amount to perturb the current solution by:\n',...
                         '(Minimum = 0%%, Maximum = 100%%)\n',...
                         '(Values greater than 5%%-10%% will likely cause the solution to become hard to recover with the optimizer.)']);
    str = inputdlg(input_str, 'Perturb Optimization Variables', [1 75], {num2str(0.01,'%4.2f')});
    if(isempty(str))
        return;
    end
    
    str = str{1};
    
    if(checkStrIsNumeric(str) && str2double(str) >= 0 && str2double(str) <= 100)
        ma_UndoRedoAddState(handles, 'Perturb Optim. Vars');
        
        writeOutput(sprintf('Perturbing optimization variables by %s%%.', str),'append');
        pPct = str2double(str);
        
        ma_UndoRedoAddState(handles, 'Perturb Optim Vars');
        
        for(i=1:length(script))
            event = script{i};
            if(isfield(event,'vars') && any(event.vars(1,:)))
                activeVars = event.vars(1,:) == 1;

                xArr = ma_getX0ForEvent(event);
                lb = event.vars(2,activeVars);
                ub = event.vars(3,activeVars);

                for(j=1:length(xArr))
                    xi = xArr(j);
                    lbi = lb(j);
                    ubi = ub(j);

                    fact = xi;
                    if(abs(fact) < 1E-10)
                        fact = 1;
                    end

                    p1 = xi - (pPct/100)*fact;
                    p2 = xi + (pPct/100)*fact;

                    lbRnd = max(min(p1,p2),lbi);
                    ubRnd = min(max(p1,p2),ubi);

                    xRnd = lbRnd + (ubRnd - lbRnd)*rand();
                    xArr(j) = xRnd;
                end
                
                event = ma_updateOptimEvent(xArr, event);
                maData.script{i} = event;
            end
        end

        setappdata(handles.ma_MainGUI,'ma_data',maData);
        maData.stateLog = ma_executeScript(maData.script,handles,celBodyData,handles.scriptWorkingLbl);
        setappdata(handles.ma_MainGUI,'ma_data',maData);
        ma_processData(handles);
    else
        writeOutput(sprintf('Could not perturb optimization variables.  "%s" is an invalid entry.', str),'append');
        beep;
    end
    


% --------------------------------------------------------------------
function setNumSoITransSearchAttemptsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to setNumSoITransSearchAttemptsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global num_soi_search_attempts_per_rev;
    
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    writeOutput = getappdata(handles.ma_MainGUI,'write_to_output_func');
    
    input_str = sprintf(['Enter the number of SoI search attempts per search rev:\n',...
                         '(Minimum = 1, Maximum = 10000)\n',...
                         '(The smaller the number, the faster the search but some SoI transitions may go missing.)\n',...
                         '(This will influence script execution speed and SoI transition search.)']);
    str = inputdlg(input_str, 'SoI Search Attempts', [1 75], {num2str(maData.settings.numSoiSearchAttemptsPerRev,'%i')});
    if(isempty(str))
        return;
    end
    
    str = str{1};
    
    if(checkStrIsNumeric(str) && str2double(str) >= 1 && str2double(str) <= 10000)
        ma_UndoRedoAddState(handles, 'Update Num. of SoI Search Attempts');
        
		str = num2str(ceil(str2double(str)));
        writeOutput(sprintf('Setting number of SoI search attempts per rev to %s.', str),'append');
        
        num_soi_search_attempts_per_rev = str2double(str);
        maData.settings.numSoiSearchAttemptsPerRev = num_soi_search_attempts_per_rev;
        
        setappdata(handles.ma_MainGUI,'ma_data',maData);
        maData.stateLog = ma_executeScript(maData.script,handles,celBodyData,handles.scriptWorkingLbl);
        setappdata(handles.ma_MainGUI,'ma_data',maData);
        ma_processData(handles);
    else
        writeOutput(sprintf('Could not set number of SoI search attempts per rev.  "%s" is an invalid entry.', str),'append');
        beep;
    end
 

% --------------------------------------------------------------------
function runScriptMenu_Callback(hObject, eventdata, handles)
% hObject    handle to runScriptMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    
%     if(~isdeployed)
%         profile off; profile on;
%     end

    maData.stateLog = ma_executeScript(maData.script,handles,celBodyData,handles.scriptWorkingLbl, true);
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    ma_processData(handles);
    
%     if(~isdeployed)
%         profile viewer;
%     end


% --------------------------------------------------------------------
function soiTransitionSettingsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to soiTransitionSettingsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function simulationMenu_Callback(hObject, eventdata, handles)
% hObject    handle to simulationMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function autopropagateMenu_Callback(hObject, eventdata, handles)
% hObject    handle to autopropagateMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    writeOutput = getappdata(handles.ma_MainGUI,'write_to_output_func');
    
    ma_UndoRedoAddState(handles, 'Edit Script Auto-Propagation');
    
    if(strcmp(get(gcbo, 'Checked'),'on'))
        maData.settings.autoPropScript = false;
        
        writeOutput('Script auto-propagation is off.  Run script manually with ctrl-p.','append');
    else
        maData.settings.autoPropScript = true;
        
        writeOutput('Script auto-propagation is on.','append');
    end
    
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    
    
% --------------------------------------------------------------------
function scriptMenu_Callback(hObject, eventdata, handles)
% hObject    handle to scriptMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    
	isAutoProp = maData.settings.autoPropScript;
    if(isAutoProp==true)
        set(handles.autopropagateMenu, 'Checked', 'on');
    else
        set(handles.autopropagateMenu, 'Checked', 'off');
    end


% --------------------------------------------------------------------
function viewMenu_Callback(hObject, eventdata, handles)
% hObject    handle to viewMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function setRendererMenu_Callback(hObject, eventdata, handles)
% hObject    handle to setRendererMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    
	renderer = maData.settings.renderer;
    switch renderer
        case FigureRendererEnum.OpenGL
            set(handles.useOpenGLRendererMenu, 'Checked', 'on');
            set(handles.usePaintersRendererMenu, 'Checked', 'off');
            
        case FigureRendererEnum.Painters
            set(handles.useOpenGLRendererMenu, 'Checked', 'off');
            set(handles.usePaintersRendererMenu, 'Checked', 'on');
            
        otherwise
            error('Unknown renderer type: %s', renderer.renderer);
    end

% --------------------------------------------------------------------
function useOpenGLRendererMenu_Callback(hObject, eventdata, handles)
% hObject    handle to useOpenGLRendererMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    writeOutput = getappdata(handles.ma_MainGUI,'write_to_output_func');
    
    ma_UndoRedoAddState(handles, 'Change Renderer to OpenGL');

    maData = getappdata(handles.ma_MainGUI,'ma_data');
	maData.settings.renderer = FigureRendererEnum.OpenGL;
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    
    writeOutput('Renderer set to OpenGL.','append');
    
    ma_processData(handles);

% --------------------------------------------------------------------
function usePaintersRendererMenu_Callback(hObject, eventdata, handles)
% hObject    handle to usePaintersRendererMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    writeOutput = getappdata(handles.ma_MainGUI,'write_to_output_func');

    ma_UndoRedoAddState(handles, 'Change Renderer to Painters');

    maData = getappdata(handles.ma_MainGUI,'ma_data');
	maData.settings.renderer = FigureRendererEnum.Painters;
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    
    writeOutput('Renderer set to Painters.','append');
    
    ma_processData(handles);


% --------------------------------------------------------------------
function setNumParallelWorkers_Callback(hObject, eventdata, handles)
% hObject    handle to setNumParallelWorkers (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    writeOutput = getappdata(handles.ma_MainGUI,'write_to_output_func');
    
    numCores = feature('numCores');
    
    input_str = sprintf(['Enter the number of workers to use for parallel optimization:\n',...
                         '(Minimum = 1, Maximum = %u)\n',...
                         '(More workers will speed up optimization but require more memory.)\n'], numCores);
    str = inputdlg(input_str, 'Number of Parallel Workers', [1 75], {num2str(maData.settings.numParallelWorkers,'%i')});
    if(isempty(str))
        return;
    end
    
    str = str{1};
    
    if(checkStrIsNumeric(str) && str2double(str) >= 1 && str2double(str) <= numCores)
        ma_UndoRedoAddState(handles, 'Update Num. Parallel Workers');
        
		str = num2str(ceil(str2double(str)));
        writeOutput(sprintf('Setting number of parallel workers to %s.', str),'append');
        
        numParallelWorkers = str2double(str);
        maData.settings.numParallelWorkers = numParallelWorkers;
        
        pp = gcp('nocreate');
        if(not(isempty(pp)) && pp.NumWorkers ~= numParallelWorkers)
            delete(pp);
            startParallelWorkers(writeOutput, numParallelWorkers);
        end
        
        setappdata(handles.ma_MainGUI,'ma_data',maData);
        maData.stateLog = ma_executeScript(maData.script,handles,celBodyData,handles.scriptWorkingLbl);
        setappdata(handles.ma_MainGUI,'ma_data',maData);
        ma_processData(handles);
    else
        writeOutput(sprintf('Could not set number of parallel workers.  "%s" is an invalid entry.', str),'append');
        beep;
    end