function varargout = lvd_EditElectricalPowerSinksGUI(varargin)
% LVD_EDITELECTRICALPOWERSINKSGUI MATLAB code for lvd_EditElectricalPowerSinksGUI.fig
%      LVD_EDITELECTRICALPOWERSINKSGUI, by itself, creates a new LVD_EDITELECTRICALPOWERSINKSGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITELECTRICALPOWERSINKSGUI returns the handle to a new LVD_EDITELECTRICALPOWERSINKSGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITELECTRICALPOWERSINKSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITELECTRICALPOWERSINKSGUI.M with the given input arguments.
%
%      LVD_EDITELECTRICALPOWERSINKSGUI('Property','Value',...) creates a new LVD_EDITELECTRICALPOWERSINKSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditElectricalPowerSinksGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditElectricalPowerSinksGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditElectricalPowerSinksGUI

% Last Modified by GUIDE v2.5 31-Jul-2020 13:47:17

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditElectricalPowerSinksGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditElectricalPowerSinksGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditElectricalPowerSinksGUI is made visible.
function lvd_EditElectricalPowerSinksGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditElectricalPowerSinksGUI (see VARARGIN)

    % Choose default command line output for lvd_EditElectricalPowerSinksGUI
    handles.output = hObject;

    lvdData = varargin{1};
    setappdata(hObject,'lvdData',lvdData);
    
    populateGUI(handles, lvdData);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditElectricalPowerSinksGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditElectricalPowerSinksGUI);

function populateGUI(handles, lvdData)
    [powerSinkListBoxStr, powerSinks] = lvdData.launchVehicle.getPowerSinksListBoxStr();
    set(handles.sinkListBox,'String',powerSinkListBoxStr);
    set(handles.sinkListBox,'Value',1);
    
    numPowerSinks = length(powerSinks);
    if(numPowerSinks <= 0)
        handles.removeSinkButton.Enable = 'off';
    end

    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditElectricalPowerSinksGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = [];
    else
        close(handles.lvd_EditElectricalPowerSinksGUI);
    end


% --- Executes on button press in closeButton.
function closeButton_Callback(hObject, eventdata, handles)
% hObject    handle to closeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.lvd_EditElectricalPowerSinksGUI);

% --- Executes on selection change in sinkListBox.
function sinkListBox_Callback(hObject, eventdata, handles)
% hObject    handle to sinkListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns sinkListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sinkListBox
    if(strcmpi(get(handles.lvd_EditElectricalPowerSinksGUI,'SelectionType'),'open'))
        lvdData = getappdata(handles.lvd_EditElectricalPowerSinksGUI,'lvdData');
        lv = lvdData.launchVehicle;

        selPowerSink = get(handles.sinkListBox,'Value');
        powerSink = lv.getPowerSinkForInd(selPowerSink);
        
        stageState = getStageStateForPowerState(powerSink, lvdData);
        oldSinkState = stageState.getStateForPowerSink(powerSink);
        stageState.removePowerSinkStateForPowerState(powerSink);
        
        powerSink.openEditDialog();

        stageState = getStageStateForPowerState(powerSink, lvdData);
        newPowerSinkState = powerSink.createDefaultInitialState(stageState);
        
        if(not(isempty(oldSinkState)))
            newPowerSinkState.setActiveState(oldSinkState.getActiveState());
        end
        stageState.addPowerSinkState(newPowerSinkState);
        
        set(handles.sinkListBox,'String',lvdData.launchVehicle.getPowerSinksListBoxStr());
    end
    
function stageState = getStageStateForPowerState(powerSink, lvdData)
        stage = powerSink.stage;
        stageStates = lvdData.initStateModel.stageStates;
        stageStateInd = find([stageStates.stage] == stage,1,'first');
        stageState = stageStates(stageStateInd);

% --- Executes during object creation, after setting all properties.
function sinkListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sinkListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addSinkButton.
function addSinkButton_Callback(hObject, eventdata, handles)
% hObject    handle to addSinkButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditElectricalPowerSinksGUI,'lvdData');
    
    sinkListBoxStr = LaunchVehiclePowerSinkEnum.getListBoxStr();
    [Selection,ok] = listdlgARH('ListString', sinkListBoxStr, ...
                                'SelectionMode','single', ...
                                'Name', 'New Sink Type', ...
                                'PromptString','Select type of new sink:', ...
                                'ListSize',[300,300]);
                            
	if(ok == 1)
        initStage = lvdData.launchVehicle.getStageForInd(1);
        
        sinkEnum = LaunchVehiclePowerSinkEnum.getEnumForListboxStr(sinkListBoxStr{Selection});
        switch sinkEnum
            case LaunchVehiclePowerSinkEnum.Simple
                powerSink = LaunchVehicleSimplePwrSink(initStage);
                
            otherwise
                error('Unknown Power Sink Type: %s', class(sinkEnum))
        end
        
        useTF = powerSink.openEditDialog();

        if(useTF)        
            stageStates = lvdData.initStateModel.stageStates;
            stageStateInd = find([stageStates.stage] == powerSink.stage,1,'first');
            stageState = stageStates(stageStateInd);

            newSinkState = powerSink.createDefaultInitialState(stageState);
            stageState.addPowerSinkState(newSinkState);

            set(handles.sinkListBox,'String',lvdData.launchVehicle.getPowerSinksListBoxStr());

            handles.removeSinkButton.Enable = 'on';
        end
	end
    
% --- Executes on button press in removeSinkButton.
function removeSinkButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeSinkButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditElectricalPowerSinksGUI,'lvdData');
    lv = lvdData.launchVehicle;
    
    selPowerSink = get(handles.sinkListBox,'Value');
    powerSink = lv.getPowerSinkForInd(selPowerSink);
    
    tf = powerSink.isInUse();
    
    if(tf == false)
        stage = powerSink.getAttachedStage();
        
        stageStates = lvdData.initStateModel.stageStates;
        stageStateInd = find([stageStates.stage] == stage,1,'first');
        stageState = stageStates(stageStateInd);

        stageState.removePowerSinkStateForPowerState(powerSink);
        
        stage.removePwrSink(powerSink);
        
        [listBoxStr, powerSinks] = lvdData.launchVehicle.getPowerSinksListBoxStr();
        set(handles.sinkListBox,'String',listBoxStr);

        numPowerSinks = length(powerSinks);
        if(selPowerSink > numPowerSinks)
            set(handles.sinkListBox,'Value',numPowerSinks);
        end
        
        if(numPowerSinks <= 0)
            set(handles.sinkListBox,'Value',1);
            
            handles.removeSinkButton.Enable = 'off';
        end
    else
        warndlg(sprintf('Could not delete the electical power sink "%s" because it is in use as part of an event termination condition, event action, objective function, or constraint.  Remove the dependencies before attempting to delete the electical power sink.', powerSink.getName()),'Cannot Delete Power Sink','modal');
    end


% --------------------------------------------------------------------
function copySinkMenu_Callback(hObject, eventdata, handles)
% hObject    handle to copySinkMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditElectricalPowerSinksGUI,'lvdData');
    lv = lvdData.launchVehicle;
    
    selPowerSink = get(handles.sinkListBox,'Value');
    powerSink = lv.getPowerSinkForInd(selPowerSink);
    
    newPowerSink = powerSink.copy();
    initStage = newPowerSink.getAttachedStage();
    
	initStage.addPwrSink(newPowerSink);
        
    stageStates = lvdData.initStateModel.stageStates;
    stageStateInd = find([stageStates.stage] == initStage,1,'first');
    stageState = stageStates(stageStateInd);

    newSinkState = powerSink.createDefaultInitialState(stageState);
    stageState.addPowerSinkState(newSinkState);

    set(handles.sinkListBox,'String',lvdData.launchVehicle.getPowerSinksListBoxStr());

    handles.removeSinkButton.Enable = 'on';

% --------------------------------------------------------------------
function sinksListboxContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to sinksListboxContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on key press with focus on lvd_EditElectricalPowerSinksGUI or any of its controls.
function lvd_EditElectricalPowerSinksGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditElectricalPowerSinksGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            uiresume(handles.lvd_EditElectricalPowerSinksGUI);
        case 'enter'
            uiresume(handles.lvd_EditElectricalPowerSinksGUI);
        case 'escape'
            uiresume(handles.lvd_EditElectricalPowerSinksGUI);
    end
