function varargout = lvd_EditElectricalPowerStoragesGUI(varargin)
% LVD_EDITELECTRICALPOWERSTORAGESGUI MATLAB code for lvd_EditElectricalPowerStoragesGUI.fig
%      LVD_EDITELECTRICALPOWERSTORAGESGUI, by itself, creates a new LVD_EDITELECTRICALPOWERSTORAGESGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITELECTRICALPOWERSTORAGESGUI returns the handle to a new LVD_EDITELECTRICALPOWERSTORAGESGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITELECTRICALPOWERSTORAGESGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITELECTRICALPOWERSTORAGESGUI.M with the given input arguments.
%
%      LVD_EDITELECTRICALPOWERSTORAGESGUI('Property','Value',...) creates a new LVD_EDITELECTRICALPOWERSTORAGESGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditElectricalPowerStoragesGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditElectricalPowerStoragesGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditElectricalPowerStoragesGUI

% Last Modified by GUIDE v2.5 02-Aug-2020 15:29:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditElectricalPowerStoragesGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditElectricalPowerStoragesGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditElectricalPowerStoragesGUI is made visible.
function lvd_EditElectricalPowerStoragesGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditElectricalPowerStoragesGUI (see VARARGIN)

    % Choose default command line output for lvd_EditElectricalPowerStoragesGUI
    handles.output = hObject;

    lvdData = varargin{1};
    setappdata(hObject,'lvdData',lvdData);
    
    populateGUI(handles, lvdData);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditElectricalPowerStoragesGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditElectricalPowerStoragesGUI);

function populateGUI(handles, lvdData)
    [powerStorageListBoxStr, powerStorages] = lvdData.launchVehicle.getPowerStoragesListBoxStr();
    set(handles.storageListBox,'String',powerStorageListBoxStr);
    set(handles.storageListBox,'Value',1);
    
    numPowerStorages = length(powerStorages);
    if(numPowerStorages <= 0)
        handles.removeStorageButton.Enable = 'off';
    end

    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditElectricalPowerStoragesGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = [];
    else
        close(handles.lvd_EditElectricalPowerStoragesGUI);
    end


% --- Executes on button press in closeButton.
function closeButton_Callback(hObject, eventdata, handles)
% hObject    handle to closeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.lvd_EditElectricalPowerStoragesGUI);

% --- Executes on selection change in storageListBox.
function storageListBox_Callback(hObject, eventdata, handles)
% hObject    handle to storageListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns storageListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from storageListBox
    if(strcmpi(get(handles.lvd_EditElectricalPowerStoragesGUI,'SelectionType'),'open'))
        lvdData = getappdata(handles.lvd_EditElectricalPowerStoragesGUI,'lvdData');
        lv = lvdData.launchVehicle;

        selPowerSink = get(handles.storageListBox,'Value');
        powerStorage = lv.getPowerStorageForInd(selPowerSink);
        
        stageState = getStageStateForPowerState(powerStorage, lvdData);
        oldStorageState = stageState.getStateForPowerStorage(powerStorage);
        stageState.removePowerStorageStateForPowerState(powerStorage);
        
        powerStorage.openEditDialog();

        stageState = getStageStateForPowerState(powerStorage, lvdData);
        newPowerStorageState = powerStorage.createDefaultInitialState(stageState);
        
        if(not(isempty(oldStorageState)))
            newPowerStorageState.setActiveState(oldStorageState.getActiveState());
            newPowerStorageState.setStateOfCharge(oldStorageState.getStateOfCharge());
        end
        stageState.addPowerStorageState(newPowerStorageState);
        
        set(handles.storageListBox,'String',lvdData.launchVehicle.getPowerStoragesListBoxStr());
    end
    
function stageState = getStageStateForPowerState(powerStorage, lvdData)
        stage = powerStorage.getAttachedStage();
        stageStates = lvdData.initStateModel.stageStates;
        stageStateInd = find([stageStates.stage] == stage,1,'first');
        stageState = stageStates(stageStateInd);

% --- Executes during object creation, after setting all properties.
function storageListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to storageListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addStorageButton.
function addStorageButton_Callback(hObject, eventdata, handles)
% hObject    handle to addStorageButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditElectricalPowerStoragesGUI,'lvdData');
    
    storagesListBoxStr = LaunchVehiclePowerStorageEnum.getListBoxStr();
    [Selection,ok] = listdlgARH('ListString', storagesListBoxStr, ...
                                'SelectionMode','single', ...
                                'Name', 'New Power Storage Type', ...
                                'PromptString','Select type of new power storage:', ...
                                'ListSize',[300,300]);
                            
	if(ok == 1)
        initStage = lvdData.launchVehicle.getStageForInd(1);
        
        storageEnum = LaunchVehiclePowerStorageEnum.getEnumForListboxStr(storagesListBoxStr{Selection});
        switch storageEnum
            case LaunchVehiclePowerStorageEnum.Basic
                powerStorage = LaunchVehicleBasicElectricalBattery(initStage);
                
            otherwise
                error('Unknown Power Storage Type: %s', storageEnum.name)
        end
        
        useTF = powerStorage.openEditDialog();

        if(useTF)        
            stageStates = lvdData.initStateModel.stageStates;
            stageStateInd = find([stageStates.stage] == powerStorage.stage,1,'first');
            stageState = stageStates(stageStateInd);

            newStorageState = powerStorage.createDefaultInitialState(stageState);
            stageState.addPowerStorageState(newStorageState);

            set(handles.storageListBox,'String',lvdData.launchVehicle.getPowerStoragesListBoxStr());

            handles.removeStorageButton.Enable = 'on';
        end
	end
    
% --- Executes on button press in removeStorageButton.
function removeStorageButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeStorageButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditElectricalPowerStoragesGUI,'lvdData');
    lv = lvdData.launchVehicle;
    
    selPowerStorage = get(handles.storageListBox,'Value');
    powerStorage = lv.getPowerStorageForInd(selPowerStorage);
    
    tf = powerStorage.isInUse();
    
    if(tf == false)
        stage = powerStorage.getAttachedStage();
        
        stageStates = lvdData.initStateModel.stageStates;
        stageStateInd = find([stageStates.stage] == stage,1,'first');
        stageState = stageStates(stageStateInd);

        stageState.removePowerStorageStateForPowerState(powerStorage);
        
        stage.removePwrStorage(powerStorage);
        
        [listBoxStr, powerStorages] = lvdData.launchVehicle.getPowerStoragesListBoxStr();
        set(handles.storageListBox,'String',listBoxStr);

        numPowerStorages = length(powerStorages);
        if(selPowerStorage > numPowerStorages)
            set(handles.storageListBox,'Value',numPowerStorages);
        end
        
        if(numPowerStorages <= 0)
            set(handles.storageListBox,'Value',1);
            
            handles.removeStorageButton.Enable = 'off';
        end
    else
        warndlg(sprintf('Could not delete the electical power storage "%s" because it is in use as part of an event termination condition, event action, objective function, or constraint.  Remove the dependencies before attempting to delete the electical power storage.', powerStorage.getName()),'Cannot Delete Power Storage','modal');
    end


% --------------------------------------------------------------------
function copyStorageMenu_Callback(hObject, eventdata, handles)
% hObject    handle to copyStorageMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditElectricalPowerStoragesGUI,'lvdData');
    lv = lvdData.launchVehicle;
    
    selPowerStorage = get(handles.storageListBox,'Value');
    powerStorage = lv.getPowerSinkForInd(selPowerStorage);
    
    newPowerStorage = powerStorage.copy();
    initStage = newPowerStorage.getAttachedStage();
    
	initStage.addPwrStorage(newPowerStorage);
        
    stageStates = lvdData.initStateModel.stageStates;
    stageStateInd = find([stageStates.stage] == initStage,1,'first');
    stageState = stageStates(stageStateInd);

    newSinkState = powerStorage.createDefaultInitialState(stageState);
    stageState.addPowerStorageState(newSinkState);

    set(handles.storageListBox,'String',lvdData.launchVehicle.getPowerStoragesListBoxStr());

    handles.removeStorageButton.Enable = 'on';

% --------------------------------------------------------------------
function storageListboxContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to storageListboxContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on key press with focus on lvd_EditElectricalPowerStoragesGUI or any of its controls.
function lvd_EditElectricalPowerStoragesGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditElectricalPowerStoragesGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            uiresume(handles.lvd_EditElectricalPowerStoragesGUI);
        case 'enter'
            uiresume(handles.lvd_EditElectricalPowerStoragesGUI);
        case 'escape'
            uiresume(handles.lvd_EditElectricalPowerStoragesGUI);
    end
