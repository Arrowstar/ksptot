function varargout = lvd_EditStopwatchGUI(varargin)
% LVD_EDITSTOPWATCHGUI MATLAB code for lvd_EditStopwatchGUI.fig
%      LVD_EDITSTOPWATCHGUI, by itself, creates a new LVD_EDITSTOPWATCHGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITSTOPWATCHGUI returns the handle to a new LVD_EDITSTOPWATCHGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITSTOPWATCHGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITSTOPWATCHGUI.M with the given input arguments.
%
%      LVD_EDITSTOPWATCHGUI('Property','Value',...) creates a new LVD_EDITSTOPWATCHGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditStopwatchGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditStopwatchGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditStopwatchGUI

% Last Modified by GUIDE v2.5 15-Dec-2018 18:36:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditStopwatchGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditStopwatchGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditStopwatchGUI is made visible.
function lvd_EditStopwatchGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditStopwatchGUI (see VARARGIN)

    % Choose default command line output for lvd_EditStopwatchGUI
    handles.output = hObject;
    
    centerUIFigure(hObject);

    stopwatch = varargin{1};
    setappdata(hObject, 'stopwatch', stopwatch);
    
	populateGUI(handles, stopwatch);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditStopwatchGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditStopwatchGUI);

function populateGUI(handles, stopwatch)
    runningStateStrs = StopwatchRunningEnum.getNameStrs();
    set(handles.startRunningCombo,'String',runningStateStrs);
    
    ind = StopwatchRunningEnum.getIndOfListboxStrs(stopwatch.startOn);
    set(handles.startRunningCombo,'Value',ind);
    
    set(handles.stopwatchNameText,'String',stopwatch.name);
    set(handles.initialValueText,'String',fullAccNum2Str(stopwatch.startValue));

% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditStopwatchGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        stopwatch = getappdata(hObject, 'stopwatch');
                
        name = handles.stopwatchNameText.String;
        initialValue = str2double(handles.initialValueText.String);

        [~, m] = StopwatchRunningEnum.getNameStrs();
        startOn = m(get(handles.startRunningCombo,'Value'));
        
        stopwatch.name = name;
        stopwatch.startValue = initialValue;
        stopwatch.startOn = startOn;
        
        varargout{1} = true;
        close(handles.lvd_EditStopwatchGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_EditStopwatchGUI);
    else
        msgbox(errMsg,'Invalid Stopwatch Inputs','error');
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    
    val = str2double(get(handles.initialValueText,'String'));
    enteredStr = get(handles.initialValueText,'String');
    numberName = 'Initial Value';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(val, numberName, lb, ub, isInt, errMsg, enteredStr);

    
% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditStopwatchGUI);


function stopwatchNameText_Callback(hObject, eventdata, handles)
% hObject    handle to stopwatchNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of stopwatchNameText as text
%        str2double(get(hObject,'String')) returns contents of stopwatchNameText as a double


% --- Executes during object creation, after setting all properties.
function stopwatchNameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stopwatchNameText see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function initialValueText_Callback(hObject, eventdata, handles)
% hObject    handle to initialValueText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of initialValueText as text
%        str2double(get(hObject,'String')) returns contents of initialValueText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function initialValueText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to initialValueText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on key press with focus on lvd_EditStopwatchGUI or any of its controls.
function lvd_EditStopwatchGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditStopwatchGUI (see GCBO)
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
            close(handles.lvd_EditStopwatchGUI);
    end


% --- Executes on selection change in startRunningCombo.
function startRunningCombo_Callback(hObject, eventdata, handles)
% hObject    handle to startRunningCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns startRunningCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from startRunningCombo


% --- Executes during object creation, after setting all properties.
function startRunningCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to startRunningCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
