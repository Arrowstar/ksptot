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

% Last Modified by GUIDE v2.5 03-Dec-2018 17:09:55

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
    set(handles.minThrottleText,'String',fullAccNum2Str(100*engine.getMinThrottle()));
    set(handles.maxThrottleText,'String',fullAccNum2Str(100*engine.getMaxThrottle()));

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
        
        conns = lv.getEngineToTankConnsForEngine(engine);
        
        engine.stage.removeEngine(engine);
        
        stage = lv.getStageForInd(handles.stageCombo.Value);
        
        name = handles.engineNameText.String;
        vacThrust = str2double(handles.vacThrustText.String);
        vacIsp = str2double(handles.vacIspText.String);
        seaLvlThrust = str2double(handles.seaLevelThrustText.String);
        seaLvlIsp = str2double(handles.seaLevelIspText.String);
        minThrottle = str2double(handles.minThrottleText.String)/100;
        maxThrottle = str2double(handles.maxThrottleText.String)/100;
        
        engine.name = name;
        engine.stage = stage;
        engine.vacThrust = vacThrust;
        engine.vacIsp = vacIsp;
        engine.seaLvlThrust = seaLvlThrust;
        engine.seaLvlIsp = seaLvlIsp;
        engine.minThrottle = minThrottle;
        engine.maxThrottle = maxThrottle;
        
        engine.stage.addEngine(engine);
        
        for(i=1:length(conns)) %#ok<NO4LP>
            conns(i).engine = engine;
            lv.addEngineToTankConnection(conns(i));
        end
        
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
    
    minThrottle = str2double(get(handles.minThrottleText,'String'));
    enteredStr = get(handles.minThrottleText,'String');
    numberName = 'Minimum Throttle Setting';
    lb = 0;
    ub = 100;
    isInt = false;
    errMsg = validateNumber(minThrottle, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    maxThrottle = str2double(get(handles.maxThrottleText,'String'));
    enteredStr = get(handles.maxThrottleText,'String');
    numberName = 'Maximum Throttle Setting';
    lb = 0;
    ub = 100;
    isInt = false;
    errMsg = validateNumber(maxThrottle, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        maxThrottle = str2double(get(handles.maxThrottleText,'String'));
        enteredStr = get(handles.maxThrottleText,'String');
        numberName = 'Maximum Throttle Setting';
        lb = minThrottle;
        ub = 100;
        isInt = false;
        errMsg = validateNumber(maxThrottle, numberName, lb, ub, isInt, errMsg, enteredStr);
    end
    
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



function minThrottleText_Callback(hObject, eventdata, handles)
% hObject    handle to minThrottleText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of minThrottleText as text
%        str2double(get(hObject,'String')) returns contents of minThrottleText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function minThrottleText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to minThrottleText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxThrottleText_Callback(hObject, eventdata, handles)
% hObject    handle to maxThrottleText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxThrottleText as text
%        str2double(get(hObject,'String')) returns contents of maxThrottleText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function maxThrottleText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxThrottleText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on lvd_EditEngineGUI or any of its controls.
function lvd_EditEngineGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditEngineGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            saveAndCloseButton_Callback(handles.saveAndCloseButton, [], handles);
        case 'enter'
            saveAndCloseButton_Callback(handles.saveAndCloseButton, [], handles);
        case 'escape'
            close(handles.lvd_EditEngineGUI);
    end