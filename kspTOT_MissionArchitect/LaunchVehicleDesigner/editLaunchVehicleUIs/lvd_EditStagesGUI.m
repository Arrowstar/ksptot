function varargout = lvd_EditStagesGUI(varargin)
% LVD_EDITSTAGESGUI MATLAB code for lvd_EditStagesGUI.fig
%      LVD_EDITSTAGESGUI, by itself, creates a new LVD_EDITSTAGESGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITSTAGESGUI returns the handle to a new LVD_EDITSTAGESGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITSTAGESGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITSTAGESGUI.M with the given input arguments.
%
%      LVD_EDITSTAGESGUI('Property','Value',...) creates a new LVD_EDITSTAGESGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditStagesGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditStagesGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditStagesGUI

% Last Modified by GUIDE v2.5 19-Sep-2018 20:45:43

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditStagesGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditStagesGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditStagesGUI is made visible.
function lvd_EditStagesGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditStagesGUI (see VARARGIN)

    % Choose default command line output for lvd_EditStagesGUI
    handles.output = hObject;

    lvdData = varargin{1};
    setappdata(hObject,'lvdData',lvdData);
    
    populateGUI(handles, lvdData);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditStagesGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditStagesGUI);

function populateGUI(handles, lvdData)
    set(handles.moveStageUpButton,'String','<html>&uarr;');
    set(handles.moveStageDownButton,'String','<html>&darr;');
    set(handles.stagesListbox,'String',lvdData.launchVehicle.getStagesListBoxStr());
    
    numStages = length(get(handles.stagesListbox,'String'));
    if(numStages <= 1)
        handles.removeStageButton.Enable = 'off';
    end

% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditStagesGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = [];
    else
        close(handles.lvd_EditStagesGUI);
    end


% --- Executes on button press in closeButton.
function closeButton_Callback(hObject, eventdata, handles)
% hObject    handle to closeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.lvd_EditStagesGUI);

% --- Executes on selection change in stagesListbox.
function stagesListbox_Callback(hObject, eventdata, handles)
% hObject    handle to stagesListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns stagesListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from stagesListbox
    if(strcmpi(get(handles.lvd_EditStagesGUI,'SelectionType'),'open'))
        lvdData = getappdata(handles.lvd_EditStagesGUI,'lvdData');
        lv = lvdData.launchVehicle;

        selStage = get(handles.stagesListbox,'Value');
        stage = lv.getStageForInd(selStage);
        
        lvd_EditStageGUI(stage);
        set(handles.stagesListbox,'String',lvdData.launchVehicle.getStagesListBoxStr());
    end

% --- Executes during object creation, after setting all properties.
function stagesListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stagesListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addStageButton.
function addStageButton_Callback(hObject, eventdata, handles)
% hObject    handle to addStageButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditStagesGUI,'lvdData');
    lv = lvdData.launchVehicle;
       
    stage = LaunchVehicleStage(lv);
    useStage = lvd_EditStageGUI(stage);
    
    if(useStage)
        lv.addStage(stage);
        
        stageState = LaunchVehicleStageState(stage);
        lvdData.initStateModel.addStageState(stageState);
        
        set(handles.stagesListbox,'String',lvdData.launchVehicle.getStagesListBoxStr());
        
        handles.removeStageButton.Enable = 'on';
    end
    
% --- Executes on button press in removeStageButton.
function removeStageButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeStageButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditStagesGUI,'lvdData');
    lv = lvdData.launchVehicle;
    
    selStage = get(handles.stagesListbox,'Value');
    stage = lv.getStageForInd(selStage);
    
    tf = stage.isStageAndChildrenInUse();
    
    if(tf == false)
        lvdData.initStateModel.removeStageStateForStage(stage);        
        lv.removeStage(stage);

        set(handles.stagesListbox,'String',lvdData.launchVehicle.getStagesListBoxStr());

        numStages = lv.getNumStages();
        if(selStage > numStages)
            set(handles.stagesListbox,'Value',numStages);
        end
        
        if(numStages <= 1)
            handles.removeStageButton.Enable = 'off';
        end
    else
        warndlg(sprintf('Could not delete the stage "%s" because it (or an associated engine or tank) is in use as part of an event termination condition, event action, objective function, or constraint.  Remove all tanks and engines from the stage and remove the stage dependencies before attempting to delete the stage.', stage.name),'Cannot Delete Stage','modal');
    end
    
% --- Executes on button press in moveStageUpButton.
function moveStageUpButton_Callback(hObject, eventdata, handles)
% hObject    handle to moveStageUpButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditStagesGUI,'lvdData');
    lv = lvdData.launchVehicle;
    
    selStage = get(handles.stagesListbox,'Value');
    stage = lv.getStageForInd(selStage);

    lv.moveStageUp(stage);
    
    if(selStage>1)
        set(handles.stagesListbox,'Value',selStage-1);
    end
    
    set(handles.stagesListbox,'String',lvdData.launchVehicle.getStagesListBoxStr());

% --- Executes on button press in moveStageDownButton.
function moveStageDownButton_Callback(hObject, eventdata, handles)
% hObject    handle to moveStageDownButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditStagesGUI,'lvdData');
    lv = lvdData.launchVehicle;
    
    selStage = get(handles.stagesListbox,'Value');
    stage = lv.getStageForInd(selStage);

    lv.moveStageDown(stage);
    
    numStages = lv.getNumStages();
    if(selStage<numStages)
        set(handles.stagesListbox,'Value',selStage+1);
    end
    
    set(handles.stagesListbox,'String',lvdData.launchVehicle.getStagesListBoxStr());
