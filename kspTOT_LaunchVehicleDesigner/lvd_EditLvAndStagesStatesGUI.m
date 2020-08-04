function varargout = lvd_EditLvAndStagesStatesGUI(varargin)
% LVD_EDITLVANDSTAGESSTATESGUI MATLAB code for lvd_EditLvAndStagesStatesGUI.fig
%      LVD_EDITLVANDSTAGESSTATESGUI, by itself, creates a new LVD_EDITLVANDSTAGESSTATESGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITLVANDSTAGESSTATESGUI returns the handle to a new LVD_EDITLVANDSTAGESSTATESGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITLVANDSTAGESSTATESGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITLVANDSTAGESSTATESGUI.M with the given input arguments.
%
%      LVD_EDITLVANDSTAGESSTATESGUI('Property','Value',...) creates a new LVD_EDITLVANDSTAGESSTATESGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditLvAndStagesStatesGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditLvAndStagesStatesGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditLvAndStagesStatesGUI

% Last Modified by GUIDE v2.5 04-Aug-2020 16:08:46

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditLvAndStagesStatesGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditLvAndStagesStatesGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditLvAndStagesStatesGUI is made visible.
function lvd_EditLvAndStagesStatesGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to lvd_EditLvAndStagesStatesGUI (see VARARGIN)

    % Choose default command line output for lvd_EditLvAndStagesStatesGUI
    handles.output = hObject;

    lvdData = varargin{1};
    setappdata(hObject, 'lvdData', lvdData);
    
    populateGUI(handles, lvdData)
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditLvAndStagesStatesGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditLvAndStagesStatesGUI);

function populateGUI(handles, lvdData)
    lv = lvdData.launchVehicle;
    initStateModel = lvdData.initStateModel;
    lvState = initStateModel.lvState;
    
    handles.stageListbox.String = lv.getStagesListBoxStr();
    stageListbox_Callback(handles.stageListbox,[],handles);
    
    %Propulsion
    handles.engineListbox.String = lv.getEnginesListBoxStr();
    engineListbox_Callback(handles.engineListbox, [], handles);
    
    handles.connListbox.String = lv.getEngineToTankConnectionsListBoxStr();
    e2TConnStates = lvState.e2TConns;
    if(not(isempty(e2TConnStates)))
        connListbox_Callback(handles.connListbox, [], handles);
    else
        handles.connListbox.Enable = 'off';
        handles.connCheckbox.Enable = 'off';
    end
    
    handles.t2tConnListbox.String = lv.getTankToTankConnectionsListBoxStr();
    t2TConnStates = lvState.t2TConns;
    if(not(isempty(t2TConnStates)))
        t2tConnListbox_Callback(handles.t2tConnListbox, [], handles);
    else
        handles.t2tConnListbox.Enable = 'off';
        handles.t2tConnCheckbox.Enable = 'off';
    end

    %Electrical Power Systems
    [handles.powerSrcListbox.String, pwrSrcs] = lv.getPowerSrcsListBoxStr();
    if(not(isempty(pwrSrcs)))
        powerSrcListbox_Callback(handles.powerSrcListbox, [], handles);
    else
        handles.powerSrcListbox.Enable = 'off';
        handles.pwrSrcActiveCheckbox.Enable = 'off';
    end
    
    [handles.powerSinkListbox.String, pwrSinks] = lv.getPowerSinksListBoxStr();
    if(not(isempty(pwrSinks)))
        powerSinkListbox_Callback(handles.powerSinkListbox, [], handles);
    else
        handles.powerSinkListbox.Enable = 'off';
        handles.pwrSinkActiveCheckbox.Enable = 'off';
    end
    
    [handles.powerStorageListbox.String, pwrStorage] = lv.getPowerStoragesListBoxStr();
    if(not(isempty(pwrStorage)))
        powerStorageListbox_Callback(handles.powerStorageListbox, [], handles);
    else
        handles.powerStorageListbox.Enable = 'off';
        handles.pwrStorageActiveCheckbox.Enable = 'off';
    end
    
    %Hold Down Clamp
    initStateModel = lvdData.initStateModel;
    handles.holdDownClampsEnabledCheckbox.Value = double(initStateModel.lvState.holdDownEnabled);
    
    

% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditLvAndStagesStatesGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else  
        varargout{1} = true;
        close(handles.lvd_EditLvAndStagesStatesGUI);
    end


% --- Executes on selection change in engineListbox.
function engineListbox_Callback(hObject, eventdata, handles)
% hObject    handle to engineListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns engineListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from engineListbox
    state = getSelectedEngineState(handles);
    handles.engineActiveCheckbox.Value = double(state.active);

    if(strcmpi(get(handles.lvd_EditLvAndStagesStatesGUI,'SelectionType'),'open'))
        handles.engineActiveCheckbox.Value = double(not(logical(handles.engineActiveCheckbox.Value)));
    end
    engineActiveCheckbox_Callback(handles.engineActiveCheckbox, [], handles);

function state = getSelectedEngineState(handles)
    lvdData = getappdata(handles.lvd_EditLvAndStagesStatesGUI, 'lvdData');
    lv = lvdData.launchVehicle;
    initStateModel = lvdData.initStateModel;
    stageStates = initStateModel.stageStates;
    
    engineStates = LaunchVehicleEngineState.empty(1,0);
    for(i=1:length(stageStates)) %#ok<*NO4LP>
        engineStates = horzcat(engineStates, stageStates(i).engineStates); %#ok<AGROW>
    end
    
    selEngine = get(handles.engineListbox,'Value');
    engine = lv.getEngineForInd(selEngine);
    
    engineInd = find([engineStates.engine] == engine,1,'first');
    state = engineStates(engineInd);


% --- Executes during object creation, after setting all properties.
function engineListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to engineListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in engineActiveCheckbox.
function engineActiveCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to engineActiveCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of engineActiveCheckbox
    state = getSelectedEngineState(handles);
    state.active = logical(get(hObject,'Value'));
    
% --- Executes on selection change in stageListbox.
function stageListbox_Callback(hObject, eventdata, handles)
% hObject    handle to stageListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns stageListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from stageListbox
    state = getSelectedStageState(handles);
    handles.stageActiveCheckbox.Value = double(state.active);
    
    if(strcmpi(get(handles.lvd_EditLvAndStagesStatesGUI,'SelectionType'),'open'))
        handles.stageActiveCheckbox.Value = double(not(logical(handles.stageActiveCheckbox.Value)));
    end
    stageActiveCheckbox_Callback(handles.stageActiveCheckbox, [], handles);
    
function state = getSelectedStageState(handles)
    lvdData = getappdata(handles.lvd_EditLvAndStagesStatesGUI, 'lvdData');
    lv = lvdData.launchVehicle;
    initStateModel = lvdData.initStateModel;
    stageStates = initStateModel.stageStates;
    
    selStage = get(handles.stageListbox,'Value');
    stage = lv.getStageForInd(selStage);
    
    stageInd = find([stageStates.stage] == stage,1,'first');
    state = stageStates(stageInd);
    
    
% --- Executes during object creation, after setting all properties.
function stageListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stageListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in stageActiveCheckbox.
function stageActiveCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to stageActiveCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of stageActiveCheckbox
    state = getSelectedStageState(handles);
    state.active = logical(get(hObject,'Value'));

% --- Executes on button press in closeButton.
function closeButton_Callback(hObject, eventdata, handles)
% hObject    handle to closeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.lvd_EditLvAndStagesStatesGUI);

% --- Executes on selection change in connListbox.
function connListbox_Callback(hObject, eventdata, handles)
% hObject    handle to connListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns connListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from connListbox
    state = getSelectedConnState(handles);
    handles.connCheckbox.Value = double(state.active);
    
    if(strcmpi(get(handles.lvd_EditLvAndStagesStatesGUI,'SelectionType'),'open'))
        handles.connCheckbox.Value = double(not(logical(handles.connCheckbox.Value)));
    end
    connCheckbox_Callback(handles.connCheckbox, [], handles);

function state = getSelectedConnState(handles)
    lvdData = getappdata(handles.lvd_EditLvAndStagesStatesGUI, 'lvdData');
    lv = lvdData.launchVehicle;
    initStateModel = lvdData.initStateModel;
    lvState = initStateModel.lvState;
    
    selConn = get(handles.connListbox,'Value');
    conn = lv.getEngineToTankForInd(selConn);

    e2TConnStates = lvState.e2TConns;
    connInd = find([e2TConnStates.conn] == conn,1,'first');
    
    state = e2TConnStates(connInd);

% --- Executes during object creation, after setting all properties.
function connListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to connListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in connCheckbox.
function connCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to connCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of connCheckbox
    state = getSelectedConnState(handles);
    state.active = logical(get(hObject,'Value'));


% --- Executes on button press in holdDownClampsEnabledCheckbox.
function holdDownClampsEnabledCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to holdDownClampsEnabledCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of holdDownClampsEnabledCheckbox
    lvdData = getappdata(handles.lvd_EditLvAndStagesStatesGUI, 'lvdData');
    initStateModel = lvdData.initStateModel;
    initStateModel.lvState.holdDownEnabled = get(hObject,'Value');


% --- Executes on key press with focus on lvd_EditLvAndStagesStatesGUI or any of its controls.
function lvd_EditLvAndStagesStatesGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditLvAndStagesStatesGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            uiresume(handles.lvd_EditLvAndStagesStatesGUI);
        case 'enter'
            uiresume(handles.lvd_EditLvAndStagesStatesGUI);
        case 'escape'
            uiresume(handles.lvd_EditLvAndStagesStatesGUI);
    end


% --- Executes on selection change in t2tConnListbox.
function t2tConnListbox_Callback(hObject, eventdata, handles)
% hObject    handle to t2tConnListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns t2tConnListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from t2tConnListbox
    state = getSelectedT2TConnState(handles);
    handles.t2tConnCheckbox.Value = double(state.active);
    
    if(strcmpi(get(handles.lvd_EditLvAndStagesStatesGUI,'SelectionType'),'open'))
        handles.t2tConnCheckbox.Value = double(not(logical(handles.t2tConnCheckbox.Value)));
    end
    t2tConnCheckbox_Callback(handles.t2tConnCheckbox, [], handles);

function state = getSelectedT2TConnState(handles)
    lvdData = getappdata(handles.lvd_EditLvAndStagesStatesGUI, 'lvdData');
    lv = lvdData.launchVehicle;
    initStateModel = lvdData.initStateModel;
    lvState = initStateModel.lvState;
    
    t2TConnStates = lvState.t2TConns;
    
    selConn = get(handles.t2tConnListbox,'Value');
    conn = lv.getTankToTankForInd(selConn);

    connInd = find([t2TConnStates.conn] == conn,1,'first');

    state = t2TConnStates(connInd);

% --- Executes during object creation, after setting all properties.
function t2tConnListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to t2tConnListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in t2tConnCheckbox.
function t2tConnCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to t2tConnCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of t2tConnCheckbox
    state = getSelectedT2TConnState(handles);
    state.active = logical(get(hObject,'Value'));


% --- Executes on button press in pwrStorageActiveCheckbox.
function pwrStorageActiveCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to pwrStorageActiveCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of pwrStorageActiveCheckbox
    state = getSelectedPwrStorageState(handles);
    state.setActiveState(logical(get(hObject,'Value')));

% --- Executes on selection change in powerStorageListbox.
function powerStorageListbox_Callback(hObject, eventdata, handles)
% hObject    handle to powerStorageListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns powerStorageListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from powerStorageListbox
    state = getSelectedPwrStorageState(handles);
    handles.pwrStorageActiveCheckbox.Value = double(state.getActiveState());

    if(strcmpi(get(handles.lvd_EditLvAndStagesStatesGUI,'SelectionType'),'open'))
        handles.pwrStorageActiveCheckbox.Value = double(not(logical(handles.pwrStorageActiveCheckbox.Value)));
    end
    pwrStorageActiveCheckbox_Callback(handles.pwrStorageActiveCheckbox, [], handles);

function state = getSelectedPwrStorageState(handles)
    lvdData = getappdata(handles.lvd_EditLvAndStagesStatesGUI, 'lvdData');
    lv = lvdData.launchVehicle;
    initStateModel = lvdData.initStateModel;
    stageStates = initStateModel.stageStates;
    
    pwrStorageStates = AbstractLaunchVehicleEpsStorageState.empty(1,0);
    for(i=1:length(stageStates)) %#ok<*NO4LP>
        pwrStorageStates = horzcat(pwrStorageStates, stageStates(i).powerStorageStates); %#ok<AGROW>
    end
    
    selPwrStorage = get(handles.powerStorageListbox,'Value');
    pwrStorage = lv.getPowerStorageForInd(selPwrStorage);
    
    pwrStorages = AbstractLaunchVehicleElectricalPowerStorage.empty(1,0);
    for(i=1:length(pwrStorageStates))
        pwrStorages = horzcat(pwrStorages, pwrStorageStates(i).getEpsStorageComponent()); %#ok<AGROW>
    end
    
    pwrStorageInd = find(pwrStorages == pwrStorage,1,'first');
    state = pwrStorageStates(pwrStorageInd);

% --- Executes during object creation, after setting all properties.
function powerStorageListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to powerStorageListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pwrSinkActiveCheckbox.
function pwrSinkActiveCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to pwrSinkActiveCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of pwrSinkActiveCheckbox
    state = getSelectedPwrSinkState(handles);
    state.setActiveState(logical(get(hObject,'Value')));

% --- Executes on selection change in powerSinkListbox.
function powerSinkListbox_Callback(hObject, eventdata, handles)
% hObject    handle to powerSinkListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns powerSinkListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from powerSinkListbox
    state = getSelectedPwrSinkState(handles);
    handles.pwrSinkActiveCheckbox.Value = double(state.getActiveState());

    if(strcmpi(get(handles.lvd_EditLvAndStagesStatesGUI,'SelectionType'),'open'))
        handles.pwrSinkActiveCheckbox.Value = double(not(logical(handles.pwrSinkActiveCheckbox.Value)));
    end
    pwrSinkActiveCheckbox_Callback(handles.pwrSinkActiveCheckbox, [], handles);

function state = getSelectedPwrSinkState(handles)
    lvdData = getappdata(handles.lvd_EditLvAndStagesStatesGUI, 'lvdData');
    lv = lvdData.launchVehicle;
    initStateModel = lvdData.initStateModel;
    stageStates = initStateModel.stageStates;
    
    pwrSinkStates = AbstractLaunchVehicleElectricalPowerSnkState.empty(1,0);
    for(i=1:length(stageStates)) %#ok<*NO4LP>
        pwrSinkStates = horzcat(pwrSinkStates, stageStates(i).powerSinkStates); %#ok<AGROW>
    end
    
    selPwrSink = get(handles.powerSinkListbox,'Value');
    pwrSink = lv.getPowerSinkForInd(selPwrSink);
    
    pwrSinks = AbstractLaunchVehicleElectricalPowerSrcSnk.empty(1,0);
    for(i=1:length(pwrSinkStates))
        pwrSinks = horzcat(pwrSinks, pwrSinkStates(i).getEpsSinkComponent()); %#ok<AGROW>
    end
    
    pwrSinkInd = find(pwrSinks == pwrSink,1,'first');
    state = pwrSinkStates(pwrSinkInd);

% --- Executes during object creation, after setting all properties.
function powerSinkListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to powerSinkListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pwrSrcActiveCheckbox.
function pwrSrcActiveCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to pwrSrcActiveCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of pwrSrcActiveCheckbox
    state = getSelectedPwrSrcState(handles);
    state.setActiveState(logical(get(hObject,'Value')));

% --- Executes on selection change in powerSrcListbox.
function powerSrcListbox_Callback(hObject, eventdata, handles)
% hObject    handle to powerSrcListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns powerSrcListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from powerSrcListbox
    state = getSelectedPwrSrcState(handles);
    handles.pwrSrcActiveCheckbox.Value = double(state.getActiveState());

    if(strcmpi(get(handles.lvd_EditLvAndStagesStatesGUI,'SelectionType'),'open'))
        handles.pwrSrcActiveCheckbox.Value = double(not(logical(handles.pwrSrcActiveCheckbox.Value)));
    end
    pwrSrcActiveCheckbox_Callback(handles.pwrSrcActiveCheckbox, [], handles);

function state = getSelectedPwrSrcState(handles)
    lvdData = getappdata(handles.lvd_EditLvAndStagesStatesGUI, 'lvdData');
    lv = lvdData.launchVehicle;
    initStateModel = lvdData.initStateModel;
    stageStates = initStateModel.stageStates;
    
    pwrSrcStates = AbstractLaunchVehicleElectricalPowerSrcState.empty(1,0);
    for(i=1:length(stageStates)) %#ok<*NO4LP>
        pwrSrcStates = horzcat(pwrSrcStates, stageStates(i).powerSrcStates); %#ok<AGROW>
    end
    
    selPwrSrc = get(handles.powerSrcListbox,'Value');
    pwrSrc = lv.getPowerSrcForInd(selPwrSrc);
    
    pwrSrcs = AbstractLaunchVehicleElectricalPowerSrcSnk.empty(1,0);
    for(i=1:length(pwrSrcStates))
        pwrSrcs = horzcat(pwrSrcs, pwrSrcStates(i).getEpsSrcComponent()); %#ok<AGROW>
    end
    
    pwrSrcInd = find(pwrSrcs == pwrSrc,1,'first');
    state = pwrSrcStates(pwrSrcInd);

% --- Executes during object creation, after setting all properties.
function powerSrcListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to powerSrcListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
