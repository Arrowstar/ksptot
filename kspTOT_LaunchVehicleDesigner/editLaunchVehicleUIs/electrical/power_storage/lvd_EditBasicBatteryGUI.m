function varargout = lvd_EditBasicBatteryGUI(varargin)
% LVD_EDITBASICBATTERYGUI MATLAB code for lvd_EditBasicBatteryGUI.fig
%      LVD_EDITBASICBATTERYGUI, by itself, creates a new LVD_EDITBASICBATTERYGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITBASICBATTERYGUI returns the handle to a new LVD_EDITBASICBATTERYGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITBASICBATTERYGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITBASICBATTERYGUI.M with the given input arguments.
%
%      LVD_EDITBASICBATTERYGUI('Property','Value',...) creates a new LVD_EDITBASICBATTERYGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditBasicBatteryGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditBasicBatteryGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditBasicBatteryGUI

% Last Modified by GUIDE v2.5 02-Aug-2020 16:04:06

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditBasicBatteryGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditBasicBatteryGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditBasicBatteryGUI is made visible.
function lvd_EditBasicBatteryGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditBasicBatteryGUI (see VARARGIN)

    % Choose default command line output for lvd_EditBasicBatteryGUI
    handles.output = hObject;

    powerStorage = varargin{1};
    setappdata(hObject, 'powerStorage', powerStorage);
    
	populateGUI(handles, powerStorage);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditBasicBatteryGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditBasicBatteryGUI);

function populateGUI(handles, powerStorage)
    lv = powerStorage.getAttachedStage().launchVehicle;
    [stagesListboxStr, ~] = lv.getStagesListBoxStr();
    ind = lv.getIndOfStage(powerStorage.stage);

    if(isempty(ind))
        ind = 1;
    end
    
    set(handles.batteryNameText,'String',powerStorage.getName());
    
    set(handles.stageCombo,'String',stagesListboxStr);
    set(handles.stageCombo,'Value',ind);
    
    set(handles.maxCapacityText,'String',fullAccNum2Str(powerStorage.maxCapacity));
    set(handles.initStateOfChargeText,'String',fullAccNum2Str(powerStorage.initialStateOfCharge));


% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditBasicBatteryGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        powerStorage = getappdata(hObject, 'powerStorage');
        lv = powerStorage.getAttachedStage().launchVehicle;
                
%         powerStorage.getAttachedStage().removePwrStorage(powerStorage);
        
        stage = lv.getStageForInd(handles.stageCombo.Value);
        
        name = handles.batteryNameText.String;
        maxCapacity = str2double(handles.maxCapacityText.String);
        initSoc = str2double(handles.initStateOfChargeText.String);
        
        powerStorage.name = name;
        powerStorage.stage = stage;
        powerStorage.maxCapacity = maxCapacity;
        powerStorage.initialStateOfCharge = initSoc;
        
%         powerStorage.getAttachedStage().addPwrStorage(powerStorage);
                
        varargout{1} = true;
        close(handles.lvd_EditBasicBatteryGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_EditBasicBatteryGUI);
    else
        msgbox(errMsg,'Invalid Power Storage Inputs','error');
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    
    maxCapacity = str2double(get(handles.maxCapacityText,'String'));
    enteredStr = get(handles.maxCapacityText,'String');
    numberName = 'Maximum Capacity';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(maxCapacity, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        initSoC = str2double(get(handles.initStateOfChargeText,'String'));
        enteredStr = get(handles.initStateOfChargeText,'String');
        numberName = 'Initial State of Charge';
        lb = 0;
        ub = maxCapacity;
        isInt = false;
        errMsg = validateNumber(initSoC, numberName, lb, ub, isInt, errMsg, enteredStr);
    end
    
% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditBasicBatteryGUI);


function batteryNameText_Callback(hObject, eventdata, handles)
% hObject    handle to batteryNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of batteryNameText as text
%        str2double(get(hObject,'String')) returns contents of batteryNameText as a double


% --- Executes during object creation, after setting all properties.
function batteryNameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to batteryNameText see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxCapacityText_Callback(hObject, eventdata, handles)
% hObject    handle to maxCapacityText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxCapacityText as text
%        str2double(get(hObject,'String')) returns contents of maxCapacityText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function maxCapacityText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxCapacityText (see GCBO)
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



% --- Executes on key press with focus on lvd_EditBasicBatteryGUI or any of its controls.
function lvd_EditBasicBatteryGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditBasicBatteryGUI (see GCBO)
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
            close(handles.lvd_EditBasicBatteryGUI);
    end


function initStateOfChargeText_Callback(hObject, eventdata, handles)
% hObject    handle to initStateOfChargeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of initStateOfChargeText as text
%        str2double(get(hObject,'String')) returns contents of initStateOfChargeText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    

% --- Executes during object creation, after setting all properties.
function initStateOfChargeText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to initStateOfChargeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
