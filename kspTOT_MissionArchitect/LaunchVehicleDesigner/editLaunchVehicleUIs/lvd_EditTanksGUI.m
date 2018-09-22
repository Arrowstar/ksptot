function varargout = lvd_EditTanksGUI(varargin)
% LVD_EDITTANKSGUI MATLAB code for lvd_EditTanksGUI.fig
%      LVD_EDITTANKSGUI, by itself, creates a new LVD_EDITTANKSGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITTANKSGUI returns the handle to a new LVD_EDITTANKSGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITTANKSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITTANKSGUI.M with the given input arguments.
%
%      LVD_EDITTANKSGUI('Property','Value',...) creates a new LVD_EDITTANKSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditTanksGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditTanksGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditTanksGUI

% Last Modified by GUIDE v2.5 21-Sep-2018 16:53:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditTanksGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditTanksGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditTanksGUI is made visible.
function lvd_EditTanksGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditTanksGUI (see VARARGIN)

    % Choose default command line output for lvd_EditTanksGUI
    handles.output = hObject;

    lvdData = varargin{1};
    setappdata(hObject,'lvdData',lvdData);
    
    populateGUI(handles, lvdData);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditTanksGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditTanksGUI);

function populateGUI(handles, lvdData)
    set(handles.tanksListBox,'String',lvdData.launchVehicle.getTanksListBoxStr());

    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditTanksGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = [];
    else
        close(handles.lvd_EditTanksGUI);
    end


% --- Executes on button press in closeButton.
function closeButton_Callback(hObject, eventdata, handles)
% hObject    handle to closeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.lvd_EditTanksGUI);

% --- Executes on selection change in tanksListBox.
function tanksListBox_Callback(hObject, eventdata, handles)
% hObject    handle to tanksListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns tanksListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from tanksListBox
    if(strcmpi(get(handles.lvd_EditTanksGUI,'SelectionType'),'open'))
        lvdData = getappdata(handles.lvd_EditTanksGUI,'lvdData');
        lv = lvdData.launchVehicle;

        selTank = get(handles.tanksListBox,'Value');
        tank = lv.getTankForInd(selTank);
        
        lvd_EditTankGUI(tank);
        set(handles.tanksListBox,'String',lvdData.launchVehicle.getTanksListBoxStr());
    end

% --- Executes during object creation, after setting all properties.
function tanksListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tanksListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addTankButton.
function addTankButton_Callback(hObject, eventdata, handles)
% hObject    handle to addTankButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditTanksGUI,'lvdData');
       
    initStage = lvdData.launchVehicle.getStageForInd(1);
    
    tank = LaunchVehicleTank(initStage);
    useTank = lvd_EditTankGUI(tank);
    
    if(useTank)
        tank.stage.addTank(tank);
        set(handles.tanksListBox,'String',lvdData.launchVehicle.getTanksListBoxStr());
    end
    
% --- Executes on button press in removeTankButton.
function removeTankButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeTankButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditTanksGUI,'lvdData');
    lv = lvdData.launchVehicle;
    
    selTank = get(handles.tanksListBox,'Value');
    tank = lv.getTankForInd(selTank);
    
    tf = tank.isInUse();
    
    if(tf == false)
        tank.stage.removeTank(tank);

        lv.removeAllEngineToTanksConnsWithTank(tank);
        
        listBoxStr = lvdData.launchVehicle.getTanksListBoxStr();
        set(handles.tanksListBox,'String',listBoxStr);

        numTanks = length(listBoxStr);
        if(selTank > numTanks)
            set(handles.tanksListBox,'Value',numTanks);
        end
    else
        warndlg(sprintf('Could not delete the tank "%s" because it is in use as part of an event termination condition, event action, objective function, or constraint.  Remove the tank dependencies before attempting to delete the engine.', tank.name),'Cannot Delete Tank','modal');
    end
