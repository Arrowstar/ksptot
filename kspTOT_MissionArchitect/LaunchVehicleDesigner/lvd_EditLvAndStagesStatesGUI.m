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

% Last Modified by GUIDE v2.5 23-Sep-2018 20:02:19

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
    
    handles.stageListbox.String = lv.getStagesListBoxStr();
    stageListbox_Callback(handles.stageListbox,[],handles);
    
    handles.engineListbox.String = lv.getEnginesListBoxStr();
    engineListbox_Callback(handles.engineListbox, [], handles);
    
    handles.connListbox.String = lv.getEngineToTankConnectionsListBoxStr();
    connListbox_Callback(handles.connListbox, [], handles);

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
