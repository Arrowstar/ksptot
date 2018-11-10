function varargout = lvd_EditEnginesGUI(varargin)
% LVD_EDITENGINESGUI MATLAB code for lvd_EditEnginesGUI.fig
%      LVD_EDITENGINESGUI, by itself, creates a new LVD_EDITENGINESGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITENGINESGUI returns the handle to a new LVD_EDITENGINESGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITENGINESGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITENGINESGUI.M with the given input arguments.
%
%      LVD_EDITENGINESGUI('Property','Value',...) creates a new LVD_EDITENGINESGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditEnginesGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditEnginesGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditEnginesGUI

% Last Modified by GUIDE v2.5 05-Oct-2018 16:43:09

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditEnginesGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditEnginesGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditEnginesGUI is made visible.
function lvd_EditEnginesGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditEnginesGUI (see VARARGIN)

    % Choose default command line output for lvd_EditEnginesGUI
    handles.output = hObject;

    lvdData = varargin{1};
    setappdata(hObject,'lvdData',lvdData);
    
    populateGUI(handles, lvdData);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditEnginesGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditEnginesGUI);

function populateGUI(handles, lvdData)
    set(handles.enginesListBox,'String',lvdData.launchVehicle.getEnginesListBoxStr());
    
    numEngines = length(get(handles.enginesListBox,'String'));
    if(numEngines <= 1)
        handles.removeEngineButton.Enable = 'off';
    end

    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditEnginesGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = [];
    else
        close(handles.lvd_EditEnginesGUI);
    end


% --- Executes on button press in closeButton.
function closeButton_Callback(hObject, eventdata, handles)
% hObject    handle to closeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.lvd_EditEnginesGUI);

% --- Executes on selection change in enginesListBox.
function enginesListBox_Callback(hObject, eventdata, handles)
% hObject    handle to enginesListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns enginesListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from enginesListBox
    if(strcmpi(get(handles.lvd_EditEnginesGUI,'SelectionType'),'open'))
        lvdData = getappdata(handles.lvd_EditEnginesGUI,'lvdData');
        lv = lvdData.launchVehicle;

        selEngine = get(handles.enginesListBox,'Value');
        engine = lv.getEngineForInd(selEngine);
        stageState = getStageStateForEngine(engine, lvdData);
        oldEngineState = stageState.getStateForEngine(engine);
        stageState.removeEngineStateForEngine(engine);
        
        lvd_EditEngineGUI(engine);

        stageState = getStageStateForEngine(engine, lvdData);
        newEngineState = LaunchVehicleEngineState(stageState);
        newEngineState.engine = engine;
        
        if(not(isempty(oldEngineState)))
            newEngineState.active = oldEngineState.active;
        end
        stageState.addEngineState(newEngineState);
        
        set(handles.enginesListBox,'String',lvdData.launchVehicle.getEnginesListBoxStr());
    end
    
function stageState = getStageStateForEngine(engine, lvdData)
        stage = engine.stage;
        stageStates = lvdData.initStateModel.stageStates;
        stageStateInd = find([stageStates.stage] == stage,1,'first');
        stageState = stageStates(stageStateInd);

% --- Executes during object creation, after setting all properties.
function enginesListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to enginesListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addEngineButton.
function addEngineButton_Callback(hObject, eventdata, handles)
% hObject    handle to addEngineButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditEnginesGUI,'lvdData');
       
    initStage = lvdData.launchVehicle.getStageForInd(1);
    
    engine = LaunchVehicleEngine(initStage);
    useEngine = lvd_EditEngineGUI(engine);
    
    if(useEngine)
%         engine.stage.addEngine(engine);
        
        stageStates = lvdData.initStateModel.stageStates;
        stageStateInd = find([stageStates.stage] == initStage,1,'first');
        stageState = stageStates(stageStateInd);
        
        newEngineState = LaunchVehicleEngineState(stageState);
        newEngineState.engine = engine;
        stageState.addEngineState(newEngineState);
        
        set(handles.enginesListBox,'String',lvdData.launchVehicle.getEnginesListBoxStr());
        
        handles.removeEngineButton.Enable = 'on';
    end
    
% --- Executes on button press in removeEngineButton.
function removeEngineButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeEngineButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditEnginesGUI,'lvdData');
    lv = lvdData.launchVehicle;
    
    selEngine = get(handles.enginesListBox,'Value');
    engine = lv.getEngineForInd(selEngine);
    
    tf = engine.isInUse();
    
    if(tf == false)
        stage = engine.stage;

        lv.removeAllEngineToTanksConnsWithEngine(engine);
        
        stageStates = lvdData.initStateModel.stageStates;
        stageStateInd = find([stageStates.stage] == stage,1,'first');
        stageState = stageStates(stageStateInd);

        stageState.removeEngineStateForEngine(engine);
        
        stage.removeEngine(engine);
        
        listBoxStr = lvdData.launchVehicle.getEnginesListBoxStr();
        set(handles.enginesListBox,'String',listBoxStr);

        numEngines = length(listBoxStr);
        if(selEngine > numEngines)
            set(handles.enginesListBox,'Value',numEngines);
        end
        
        if(numEngines <= 1)
            handles.removeEngineButton.Enable = 'off';
        end
    else
        warndlg(sprintf('Could not delete the engine "%s" because it is in use as part of an event termination condition, event action, objective function, or constraint.  Remove the engine dependencies before attempting to delete the engine.', engine.name),'Cannot Delete Engine','modal');
    end


% --------------------------------------------------------------------
function copyEngineMenu_Callback(hObject, eventdata, handles)
% hObject    handle to copyEngineMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditEnginesGUI,'lvdData');
    lv = lvdData.launchVehicle;
    
    selEngine = get(handles.enginesListBox,'Value');
    engine = lv.getEngineForInd(selEngine);
    
    newEngine = engine.copy();
    initStage = newEngine.stage;
    
	newEngine.stage.addEngine(newEngine);
        
    stageStates = lvdData.initStateModel.stageStates;
    stageStateInd = find([stageStates.stage] == initStage,1,'first');
    stageState = stageStates(stageStateInd);

    newEngineState = LaunchVehicleEngineState(stageState);
    newEngineState.engine = newEngine;
    stageState.addEngineState(newEngineState);

    set(handles.enginesListBox,'String',lvdData.launchVehicle.getEnginesListBoxStr());

    handles.removeEngineButton.Enable = 'on';

% --------------------------------------------------------------------
function enginesListboxContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to enginesListboxContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
