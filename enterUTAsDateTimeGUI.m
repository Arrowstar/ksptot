function varargout = enterUTAsDateTimeGUI(varargin)
% ENTERUTASDATETIMEGUI MATLAB code for enterUTAsDateTimeGUI.fig
%      ENTERUTASDATETIMEGUI, by itself, creates a new ENTERUTASDATETIMEGUI or raises the existing
%      singleton*.
%
%      H = ENTERUTASDATETIMEGUI returns the handle to a new ENTERUTASDATETIMEGUI or the handle to
%      the existing singleton*.
%
%      ENTERUTASDATETIMEGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ENTERUTASDATETIMEGUI.M with the given input arguments.
%
%      ENTERUTASDATETIMEGUI('Property','Value',...) creates a new ENTERUTASDATETIMEGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before enterUTAsDateTimeGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to enterUTAsDateTimeGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help enterUTAsDateTimeGUI

% Last Modified by GUIDE v2.5 22-May-2014 20:37:46

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @enterUTAsDateTimeGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @enterUTAsDateTimeGUI_OutputFcn, ...
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


% --- Executes just before enterUTAsDateTimeGUI is made visible.
function enterUTAsDateTimeGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to enterUTAsDateTimeGUI (see VARARGIN)
global options_UseEarthTimeSystem;
% Choose default command line output for enterUTAsDateTimeGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%Possible fix for people with display issues.
checkForCharUnitsInGUI(hObject);

utTime = varargin{1};
[year, day, hour, minute, second] = convertSec2YearDayHrMnSec(utTime);
set(handles.year, 'String', num2str(year));
set(handles.day, 'String', num2str(day));
set(handles.hour, 'String', num2str(hour));
set(handles.minute, 'String', num2str(minute));
set(handles.second, 'String', num2str(second));

if(options_UseEarthTimeSystem)
    timeWarnStr = 'All times are in Earth units!  (1 year = 365 days, 1 day = 24 hours)';
else
    timeWarnStr = 'All times are in Kerbin units!  (1 year = 426 days, 1 day = 6 hours)';
end
set(handles.timeWarnStr,'String',timeWarnStr);

% UIWAIT makes enterUTAsDateTimeGUI wait for user response (see UIRESUME)
uiwait(handles.enterUTAsDateTimeGUI);


% --- Outputs from this function are returned to the command line.
function [secUT] = enterUTAsDateTimeGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
try 
    year = str2double(get(handles.year,'String'));
    day = str2double(get(handles.day,'String'));
    hour = str2double(get(handles.hour,'String'));
    min = str2double(get(handles.minute,'String'));
    sec = str2double(get(handles.second,'String'));

    secUT = convertYearDayHrMnSec2Sec(year, day, hour, min, sec);
    close(handles.enterUTAsDateTimeGUI);
catch err
    secUT = -1;
end


function year_Callback(hObject, eventdata, handles)
% hObject    handle to year (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of year as text
%        str2double(get(hObject,'String')) returns contents of year as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function year_CreateFcn(hObject, eventdata, handles)
% hObject    handle to year (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function day_Callback(hObject, eventdata, handles)
% hObject    handle to day (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of day as text
%        str2double(get(hObject,'String')) returns contents of day as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function day_CreateFcn(hObject, eventdata, handles)
% hObject    handle to day (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function hour_Callback(hObject, eventdata, handles)
% hObject    handle to hour (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hour as text
%        str2double(get(hObject,'String')) returns contents of hour as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function hour_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hour (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function minute_Callback(hObject, eventdata, handles)
% hObject    handle to minute (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of minute as text
%        str2double(get(hObject,'String')) returns contents of minute as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function minute_CreateFcn(hObject, eventdata, handles)
% hObject    handle to minute (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function second_Callback(hObject, eventdata, handles)
% hObject    handle to second (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of second as text
%        str2double(get(hObject,'String')) returns contents of second as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function second_CreateFcn(hObject, eventdata, handles)
% hObject    handle to second (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in okayButton.
function okayButton_Callback(hObject, eventdata, handles)
% hObject    handle to okayButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
errMsg = {};

year = str2double(get(handles.year,'String'));
enteredStr = get(handles.year,'String');
numberName = 'Year';
lb = 1;
ub = Inf;
isInt = false;
errMsg = validateNumber(year, numberName, lb, ub, isInt, errMsg, enteredStr);

day = str2double(get(handles.day,'String'));
enteredStr = get(handles.day,'String');
numberName = 'Day';
lb = 1;
ub = Inf;
isInt = false;
errMsg = validateNumber(day, numberName, lb, ub, isInt, errMsg, enteredStr);

hour = str2double(get(handles.hour,'String'));
enteredStr = get(handles.hour,'String');
numberName = 'Hour';
lb = 0;
ub = Inf;
isInt = false;
errMsg = validateNumber(hour, numberName, lb, ub, isInt, errMsg, enteredStr);

min = str2double(get(handles.minute,'String'));
enteredStr = get(handles.minute,'String');
numberName = 'Minute';
lb = 0;
ub = Inf;
isInt = false;
errMsg = validateNumber(min, numberName, lb, ub, isInt, errMsg, enteredStr);

sec = str2double(get(handles.second,'String'));
enteredStr = get(handles.second,'String');
numberName = 'Second';
lb = 0;
ub = Inf;
isInt = false;
errMsg = validateNumber(sec, numberName, lb, ub, isInt, errMsg, enteredStr);

if(isempty(errMsg))
    try
        uiresume(handles.enterUTAsDateTimeGUI);
    catch ME
        msgbox(ME.message);
    end 
else
    msgbox(errMsg,'Errors were found in date/time inputs','error');
end


% --- Executes on key press with focus on enterUTAsDateTimeGUI or any of its controls.
function enterUTAsDateTimeGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to enterUTAsDateTimeGUI (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            okayButton_Callback(handles.okayButton, [], handles);
        case 'enter'
            okayButton_Callback(handles.okayButton, [], handles);
    end
