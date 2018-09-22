function varargout = lvd_EditTankGUI(varargin)
% LVD_EDITTANKGUI MATLAB code for lvd_EditTankGUI.fig
%      LVD_EDITTANKGUI, by itself, creates a new LVD_EDITTANKGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITTANKGUI returns the handle to a new LVD_EDITTANKGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITTANKGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITTANKGUI.M with the given input arguments.
%
%      LVD_EDITTANKGUI('Property','Value',...) creates a new LVD_EDITTANKGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditTankGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditTankGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditTankGUI

% Last Modified by GUIDE v2.5 21-Sep-2018 17:20:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditTankGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditTankGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditTankGUI is made visible.
function lvd_EditTankGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditTankGUI (see VARARGIN)

    % Choose default command line output for lvd_EditTankGUI
    handles.output = hObject;

    tank = varargin{1};
    setappdata(hObject, 'tank', tank);
    
	populateGUI(handles, tank);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditTankGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditTankGUI);

function populateGUI(handles, tank)
    lv = tank.stage.launchVehicle;
    [stagesListboxStr, ~] = lv.getStagesListBoxStr();
    ind = lv.getIndOfStage(tank.stage);

    if(isempty(ind))
        ind = 1;
    end
    
    set(handles.engineNameText,'String',tank.name);
    set(handles.stageCombo,'String',stagesListboxStr);
    set(handles.stageCombo,'Value',ind);
    set(handles.initPropMassText,'String',fullAccNum2Str(tank.getInitialMass()));

% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditTankGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        tank = getappdata(hObject, 'tank');
        lv = tank.stage.launchVehicle;
        
        stage = lv.getStageForInd(handles.stageCombo.Value);
        
        name = handles.engineNameText.String;
        initialMass = str2double(handles.initPropMassText.String);
        
        tank.name = name;
        tank.stage = stage;
        tank.initialMass = initialMass;
        
        varargout{1} = true;
        close(handles.lvd_EditTankGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_EditTankGUI);
    else
        msgbox(errMsg,'Invalid Tank Inputs','error');
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    
    val = str2double(get(handles.initPropMassText,'String'));
    enteredStr = get(handles.initPropMassText,'String');
    numberName = 'Initial Propellant Mass';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(val, numberName, lb, ub, isInt, errMsg, enteredStr);
    

    
% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditTankGUI);


function engineNameText_Callback(hObject, eventdata, handles)
% hObject    handle to engineNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of engineNameText as text
%        str2double(get(hObject,'String')) returns contents of engineNameText as a double


% --- Executes during object creation, after setting all properties.
function engineNameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to engineNameText see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function initPropMassText_Callback(hObject, eventdata, handles)
% hObject    handle to initPropMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of initPropMassText as text
%        str2double(get(hObject,'String')) returns contents of initPropMassText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function initPropMassText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to initPropMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on selection change in stageCombo.
function stageCombo_Callback(hObject, eventdata, handles)
% hObject    handle to stageCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns stageCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from stageCombo


% --- Executes during object creation, after setting all properties.
function stageCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stageCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
