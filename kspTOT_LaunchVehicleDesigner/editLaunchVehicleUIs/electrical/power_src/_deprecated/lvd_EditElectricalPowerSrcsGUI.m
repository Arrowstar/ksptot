function varargout = lvd_EditElectricalPowerSrcsGUI(varargin)
% LVD_EDITELECTRICALPOWERSRCSGUI MATLAB code for lvd_EditElectricalPowerSrcsGUI.fig
%      LVD_EDITELECTRICALPOWERSRCSGUI, by itself, creates a new LVD_EDITELECTRICALPOWERSRCSGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITELECTRICALPOWERSRCSGUI returns the handle to a new LVD_EDITELECTRICALPOWERSRCSGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITELECTRICALPOWERSRCSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITELECTRICALPOWERSRCSGUI.M with the given input arguments.
%
%      LVD_EDITELECTRICALPOWERSRCSGUI('Property','Value',...) creates a new LVD_EDITELECTRICALPOWERSRCSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditElectricalPowerSrcsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditElectricalPowerSrcsGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditElectricalPowerSrcsGUI

% Last Modified by GUIDE v2.5 01-Aug-2020 12:33:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditElectricalPowerSrcsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditElectricalPowerSrcsGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditElectricalPowerSrcsGUI is made visible.
function lvd_EditElectricalPowerSrcsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditElectricalPowerSrcsGUI (see VARARGIN)

    % Choose default command line output for lvd_EditElectricalPowerSrcsGUI
    handles.output = hObject;

    lvdData = varargin{1};
    setappdata(hObject,'lvdData',lvdData);
    
    populateGUI(handles, lvdData);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditElectricalPowerSrcsGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditElectricalPowerSrcsGUI);

function populateGUI(handles, lvdData)
    [powerSrcListBoxStr, powerSrcs] = lvdData.launchVehicle.getPowerSrcsListBoxStr();
    set(handles.sourcesListBox,'String',powerSrcListBoxStr);
    set(handles.sourcesListBox,'Value',1);
    
    numPowerSrcs = length(powerSrcs);
    if(numPowerSrcs <= 0)
        handles.removeSrcButton.Enable = 'off';
    end

    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditElectricalPowerSrcsGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = [];
    else
        close(handles.lvd_EditElectricalPowerSrcsGUI);
    end


% --- Executes on button press in closeButton.
function closeButton_Callback(hObject, eventdata, handles)
% hObject    handle to closeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.lvd_EditElectricalPowerSrcsGUI);

% --- Executes on selection change in sourcesListBox.
function sourcesListBox_Callback(hObject, eventdata, handles)
% hObject    handle to sourcesListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns sourcesListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sourcesListBox
    if(strcmpi(get(handles.lvd_EditElectricalPowerSrcsGUI,'SelectionType'),'open'))
        lvdData = getappdata(handles.lvd_EditElectricalPowerSrcsGUI,'lvdData');
        lv = lvdData.launchVehicle;

        selPowerSrc = get(handles.sourcesListBox,'Value');
        powerSrc = lv.getPowerSrcForInd(selPowerSrc);
        
        stageState = getStageStateForPowerSrcState(powerSrc, lvdData);
        oldSrcState = stageState.getStateForPowerSrc(powerSrc);
        stageState.removePowerSrcStateForPowerState(powerSrc);
        
        powerSrc.openEditDialog();

        stageState = getStageStateForPowerSrcState(powerSrc, lvdData);
        newPowerSrcState = powerSrc.createDefaultInitialState(stageState);
        
        if(not(isempty(oldSrcState)))
            newPowerSrcState.setActiveState(oldSrcState.getActiveState());
        end
        stageState.addPowerSrcState(newPowerSrcState);
        
        set(handles.sourcesListBox,'String',lvdData.launchVehicle.getPowerSrcsListBoxStr());
    end
    
function stageState = getStageStateForPowerSrcState(powerSrc, lvdData)
        stage = powerSrc.stage;
        stageStates = lvdData.initStateModel.stageStates;
        stageStateInd = find([stageStates.stage] == stage,1,'first');
        stageState = stageStates(stageStateInd);

% --- Executes during object creation, after setting all properties.
function sourcesListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sourcesListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addSrcButton.
function addSrcButton_Callback(hObject, eventdata, handles)
% hObject    handle to addSrcButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditElectricalPowerSrcsGUI,'lvdData');
    
    srcListBoxStr = LaunchVehiclePowerSrcEnum.getListBoxStr();
    [Selection,ok] = listdlgARH('ListString', srcListBoxStr, ...
                                'SelectionMode','single', ...
                                'Name', 'New Power Source Type', ...
                                'PromptString','Select type of new power source:', ...
                                'ListSize',[300,300]);
                            
	if(ok == 1)
        initStage = lvdData.launchVehicle.getStageForInd(1);
        
        srcEnum = LaunchVehiclePowerSrcEnum.getEnumForListboxStr(srcListBoxStr{Selection});
        switch srcEnum
            case LaunchVehiclePowerSrcEnum.RTG
                powerSrc = LaunchVehicleEpsRtg(initStage);
                
            case LaunchVehiclePowerSrcEnum.FixedSolarPanel
                powerSrc = LaunchVehicleStaticSolarPanel(initStage);
                
            case LaunchVehiclePowerSrcEnum.RotatingSolarPanel
                powerSrc = LaunchVehicleRotatingSolarPanel(initStage);
                
            otherwise
                error('Unknown Power Source Type: %s', class(srcEnum))
        end
        
        useTF = powerSrc.openEditDialog();

        if(useTF)        
            stageStates = lvdData.initStateModel.stageStates;
            stageStateInd = find([stageStates.stage] == powerSrc.stage,1,'first');
            stageState = stageStates(stageStateInd);

            newSrcState = powerSrc.createDefaultInitialState(stageState);
            stageState.addPowerSrcState(newSrcState);

            set(handles.sourcesListBox,'String',lvdData.launchVehicle.getPowerSrcsListBoxStr());

            handles.removeSrcButton.Enable = 'on';
        end
	end
    
% --- Executes on button press in removeSrcButton.
function removeSrcButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeSrcButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditElectricalPowerSrcsGUI,'lvdData');
    lv = lvdData.launchVehicle;
    
    selPowerSrc = get(handles.sourcesListBox,'Value');
    powerSrc = lv.getPowerSrcForInd(selPowerSrc);
    
    tf = powerSrc.isInUse();
    
    if(tf == false)
        stage = powerSrc.getAttachedStage();
        
        stageStates = lvdData.initStateModel.stageStates;
        stageStateInd = find([stageStates.stage] == stage,1,'first');
        stageState = stageStates(stageStateInd);

        stageState.removePowerSrcStateForPowerState(powerSrc);
        
        stage.removePwrSrc(powerSrc);
        
        [listBoxStr, powerSrcs] = lvdData.launchVehicle.getPowerSrcsListBoxStr();
        set(handles.sourcesListBox,'String',listBoxStr);

        numPowerSrcs = length(powerSrcs);
        if(selPowerSrc > numPowerSrcs)
            set(handles.sourcesListBox,'Value',numPowerSrcs);
        end
        
        if(numPowerSrcs <= 0)
            set(handles.sourcesListBox,'Value',1);
            
            handles.removeSrcButton.Enable = 'off';
        end
    else
        warndlg(sprintf('Could not delete the electical power source "%s" because it is in use as part of an event termination condition, event action, objective function, or constraint.  Remove the dependencies before attempting to delete the electical power source.', powerSrc.getName()),'Cannot Delete Power Source','modal');
    end


% --------------------------------------------------------------------
function copySrcMenu_Callback(hObject, eventdata, handles)
% hObject    handle to copySrcMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditElectricalPowerSrcsGUI,'lvdData');
    lv = lvdData.launchVehicle;
    
    selPowerSrc = get(handles.sourcesListBox,'Value');
    powerSrc = lv.getPowerSrcForInd(selPowerSrc);
    
    newPowerSrc = powerSrc.copy();
    initStage = newPowerSrc.getAttachedStage();
    
	initStage.addPwrSrc(newPowerSrc);
        
    stageStates = lvdData.initStateModel.stageStates;
    stageStateInd = find([stageStates.stage] == initStage,1,'first');
    stageState = stageStates(stageStateInd);

    newSinkState = powerSrc.createDefaultInitialState(stageState);
    stageState.addPowerSrcState(newSinkState);

    set(handles.sourcesListBox,'String',lvdData.launchVehicle.getPowerSrcsListBoxStr());

    handles.removeSrcButton.Enable = 'on';

% --------------------------------------------------------------------
function srcsListboxContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to srcsListboxContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on key press with focus on lvd_EditElectricalPowerSrcsGUI or any of its controls.
function lvd_EditElectricalPowerSrcsGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditElectricalPowerSrcsGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            uiresume(handles.lvd_EditElectricalPowerSrcsGUI);
        case 'enter'
            uiresume(handles.lvd_EditElectricalPowerSrcsGUI);
        case 'escape'
            uiresume(handles.lvd_EditElectricalPowerSrcsGUI);
    end
