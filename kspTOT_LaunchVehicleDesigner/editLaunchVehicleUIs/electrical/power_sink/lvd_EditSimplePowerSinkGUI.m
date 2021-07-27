function varargout = lvd_EditSimplePowerSinkGUI(varargin)
% LVD_EDITSIMPLEPOWERSINKGUI MATLAB code for lvd_EditSimplePowerSinkGUI.fig
%      LVD_EDITSIMPLEPOWERSINKGUI, by itself, creates a new LVD_EDITSIMPLEPOWERSINKGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITSIMPLEPOWERSINKGUI returns the handle to a new LVD_EDITSIMPLEPOWERSINKGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITSIMPLEPOWERSINKGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITSIMPLEPOWERSINKGUI.M with the given input arguments.
%
%      LVD_EDITSIMPLEPOWERSINKGUI('Property','Value',...) creates a new LVD_EDITSIMPLEPOWERSINKGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditSimplePowerSinkGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditSimplePowerSinkGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditSimplePowerSinkGUI

% Last Modified by GUIDE v2.5 31-Jul-2020 17:14:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditSimplePowerSinkGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditSimplePowerSinkGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditSimplePowerSinkGUI is made visible.
function lvd_EditSimplePowerSinkGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditSimplePowerSinkGUI (see VARARGIN)

    % Choose default command line output for lvd_EditSimplePowerSinkGUI
    handles.output = hObject;

    powerSink = varargin{1};
    setappdata(hObject, 'powerSink', powerSink);
    
	populateGUI(handles, powerSink);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditSimplePowerSinkGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditSimplePowerSinkGUI);

function populateGUI(handles, powerSink)
    lv = powerSink.getAttachedStage().launchVehicle;
    [stagesListboxStr, ~] = lv.getStagesListBoxStr();
    ind = lv.getIndOfStage(powerSink.stage);

    if(isempty(ind))
        ind = 1;
    end
    
    set(handles.sinkNameText,'String',powerSink.getName());
    
    set(handles.stageCombo,'String',stagesListboxStr);
    set(handles.stageCombo,'Value',ind);
    
    set(handles.dischargeRateText,'String',fullAccNum2Str(-1*powerSink.pwrRate));


% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditSimplePowerSinkGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        powerSink = getappdata(hObject, 'powerSink');
        lv = powerSink.getAttachedStage().launchVehicle;
                
%         powerSink.getAttachedStage().removePwrSink(powerSink);
        
        stage = lv.getStageForInd(handles.stageCombo.Value);
        
        name = handles.sinkNameText.String;
        dischargeRate = -1*str2double(handles.dischargeRateText.String);
        
        powerSink.name = name;
        powerSink.stage = stage;
        powerSink.pwrRate = dischargeRate;
        
%         powerSink.getAttachedStage().addPwrSink(powerSink);
                
        varargout{1} = true;
        close(handles.lvd_EditSimplePowerSinkGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_EditSimplePowerSinkGUI);
    else
        msgbox(errMsg,'Invalid Power Sink Inputs','error');
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    
    val = str2double(get(handles.dischargeRateText,'String'));
    enteredStr = get(handles.dischargeRateText,'String');
    numberName = 'Discharge Rate';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(val, numberName, lb, ub, isInt, errMsg, enteredStr);
    
% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditSimplePowerSinkGUI);


function sinkNameText_Callback(hObject, eventdata, handles)
% hObject    handle to sinkNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sinkNameText as text
%        str2double(get(hObject,'String')) returns contents of sinkNameText as a double


% --- Executes during object creation, after setting all properties.
function sinkNameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sinkNameText see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dischargeRateText_Callback(hObject, eventdata, handles)
% hObject    handle to dischargeRateText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dischargeRateText as text
%        str2double(get(hObject,'String')) returns contents of dischargeRateText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function dischargeRateText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dischargeRateText (see GCBO)
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



% --- Executes on key press with focus on lvd_EditSimplePowerSinkGUI or any of its controls.
function lvd_EditSimplePowerSinkGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditSimplePowerSinkGUI (see GCBO)
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
            close(handles.lvd_EditSimplePowerSinkGUI);
    end
