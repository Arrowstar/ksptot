function varargout = lvd_EditEngineGUI(varargin)
% LVD_EDITENGINEGUI MATLAB code for lvd_EditEngineGUI.fig
%      LVD_EDITENGINEGUI, by itself, creates a new LVD_EDITENGINEGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITENGINEGUI returns the handle to a new LVD_EDITENGINEGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITENGINEGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITENGINEGUI.M with the given input arguments.
%
%      LVD_EDITENGINEGUI('Property','Value',...) creates a new LVD_EDITENGINEGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditEngineGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditEngineGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditEngineGUI

% Last Modified by GUIDE v2.5 20-Sep-2018 17:48:22

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditEngineGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditEngineGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditEngineGUI is made visible.
function lvd_EditEngineGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditEngineGUI (see VARARGIN)

    % Choose default command line output for lvd_EditEngineGUI
    handles.output = hObject;

    engine = varargin{1};
    setappdata(hObject, 'engine', engine);
    
	populateGUI(handles, engine);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditEngineGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditEngineGUI);

function populateGUI(handles, engine)
    lv = engine.stage.launchVehicle;
    [stagesListboxStr, ~] = lv.getStagesListBoxStr();
    ind = lv.getIndOfStage(engine.stage);

    if(isempty(ind))
        ind = 1;
    end
    
    set(handles.engineNameText,'String',engine.name);
    set(handles.stageCombo,'String',stagesListboxStr);
    set(handles.stageCombo,'Value',ind);
    set(handles.vacThrustText,'String',fullAccNum2Str(engine.getVacThrust()));
    set(handles.vacIspText,'String',fullAccNum2Str(engine.getVacIsp()));
    set(handles.seaLevelThrustText,'String',fullAccNum2Str(engine.getSeaLvlThrust()));
    set(handles.seaLevelIspText,'String',fullAccNum2Str(engine.getSeaLvlIsp()));

% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditEngineGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        engine = getappdata(hObject, 'engine');
        lv = engine.stage.launchVehicle;
        
        stage = lv.getStageForInd(handles.stageCombo.Value);
        
        name = handles.engineNameText.String;
        vacThrust = str2double(handles.vacThrustText.String);
        vacIsp = str2double(handles.vacIspText.String);
        seaLvlThrust = str2double(handles.seaLevelThrustText.String);
        seaLvlIsp = str2double(handles.seaLevelIspText.String);
        
        engine.name = name;
        engine.stage = stage;
        engine.vacThrust = vacThrust;
        engine.vacIsp = vacIsp;
        engine.seaLvlThrust = seaLvlThrust;
        engine.seaLvlIsp = seaLvlIsp;
        
        varargout{1} = true;
        close(handles.lvd_EditEngineGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_EditEngineGUI);
    else
        msgbox(errMsg,'Invalid Engine Inputs','error');
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    
    val = str2double(get(handles.vacThrustText,'String'));
    enteredStr = get(handles.vacThrustText,'String');
    numberName = 'Vacuum Thrust';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(val, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    val = str2double(get(handles.vacIspText,'String'));
    enteredStr = get(handles.vacIspText,'String');
    numberName = 'Vacuum Isp';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(val, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    val = str2double(get(handles.seaLevelThrustText,'String'));
    enteredStr = get(handles.seaLevelThrustText,'String');
    numberName = 'Sea Level Thrust';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(val, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    val = str2double(get(handles.seaLevelIspText,'String'));
    enteredStr = get(handles.seaLevelIspText,'String');
    numberName = 'Sea Level Isp';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(val, numberName, lb, ub, isInt, errMsg, enteredStr);
    
% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditEngineGUI);


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



function vacThrustText_Callback(hObject, eventdata, handles)
% hObject    handle to vacThrustText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of vacThrustText as text
%        str2double(get(hObject,'String')) returns contents of vacThrustText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function vacThrustText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vacThrustText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function vacIspText_Callback(hObject, eventdata, handles)
% hObject    handle to vacIspText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of vacIspText as text
%        str2double(get(hObject,'String')) returns contents of vacIspText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function vacIspText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vacIspText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function seaLevelThrustText_Callback(hObject, eventdata, handles)
% hObject    handle to seaLevelThrustText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of seaLevelThrustText as text
%        str2double(get(hObject,'String')) returns contents of seaLevelThrustText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function seaLevelThrustText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to seaLevelThrustText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function seaLevelIspText_Callback(hObject, eventdata, handles)
% hObject    handle to seaLevelIspText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of seaLevelIspText as text
%        str2double(get(hObject,'String')) returns contents of seaLevelIspText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function seaLevelIspText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to seaLevelIspText (see GCBO)
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
