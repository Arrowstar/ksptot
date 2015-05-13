function varargout = ma_StateLogGUI(varargin)
% MA_STATELOGGUI MATLAB code for ma_StateLogGUI.fig
%      MA_STATELOGGUI, by itself, creates a new MA_STATELOGGUI or raises the existing
%      singleton*.
%
%      H = MA_STATELOGGUI returns the handle to a new MA_STATELOGGUI or the handle to
%      the existing singleton*.
%
%      MA_STATELOGGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_STATELOGGUI.M with the given input arguments.
%
%      MA_STATELOGGUI('Property','Value',...) creates a new MA_STATELOGGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_StateLogGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_StateLogGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_StateLogGUI

% Last Modified by GUIDE v2.5 22-Apr-2015 16:56:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_StateLogGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_StateLogGUI_OutputFcn, ...
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


% --- Executes just before ma_StateLogGUI is made visible.
function ma_StateLogGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_StateLogGUI (see VARARGIN)

% Choose default command line output for ma_StateLogGUI
handles.output = hObject;
handles.ma_MainGUI = varargin{1};

% Update handles structure
guidata(hObject, handles);

initializeGUI(handles);

% UIWAIT makes ma_StateLogGUI wait for user response (see UIRESUME)
% uiwait(handles.ma_StateLogGUI);

function initializeGUI(handles) 
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    stateLog = maData.stateLog;
    firstLog = stateLog(1,:);
    lastLog  = stateLog(end,:);
    numLogEntries = size(stateLog,1);
    
%     if(firstLog(1) == lastLog(1))
%         lastLog(1) = firstLog(1) + 1;
%     end
    
    if(numLogEntries==1)
        arr = [1, 1];
        min = 1;
        max = 2;
    else
        arr = [1/(numLogEntries-1), 10/numLogEntries];
        min = 1;
        max = numLogEntries;
    end
    
    set(handles.leftSlider, 'Min', min);
    set(handles.leftSlider, 'Max', max);
    set(handles.leftSlider, 'Value', 1);
    set(handles.leftSlider, 'SliderStep', arr);
    set(handles.leftUTSelectText,'String', num2str(firstLog(1)));
    set(handles.leftMinLabel,'String',num2str(firstLog(1)));
    set(handles.leftMaxLabel,'String',num2str(lastLog(1)));
    
    set(handles.rightSlider, 'Min', min);
    set(handles.rightSlider, 'Max', max);
    set(handles.rightSlider, 'Value', numLogEntries);
    set(handles.rightSlider, 'SliderStep', arr);
    set(handles.rightUTSelectText,'String', num2str(firstLog(1)));
    set(handles.rightMinLabel,'String',num2str(firstLog(1)));
    set(handles.rightMaxLabel,'String',num2str(lastLog(1)));
    
    rightUTSelectText_Callback(handles.rightUTSelectText, [], handles);
    leftUTSelectText_Callback(handles.leftUTSelectText, [], handles);
    

% --- Outputs from this function are returned to the command line.
function varargout = ma_StateLogGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function leftSlider_Callback(hObject, eventdata, handles)
% hObject    handle to leftSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    utInd = round(get(hObject,'Value'));
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    stateLog = maData.stateLog;
    if(size(stateLog,1)==1)
        ut = stateLog(1,1);
    else
        ut = stateLog(utInd,1);
    end
    sliderUTTextUpdtFunction(ut, handles.leftStateLabel, handles.leftSlider, handles.leftUTSelectText, handles);

% --- Executes during object creation, after setting all properties.
function leftSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to leftSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function sliderUTTextUpdtFunction(ut, hStateLabel, hSlider, hUTSelectText, handles) 
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');

    stateLog = maData.stateLog;
    stateLogLatest = stateLog(stateLog(:,1) <= ut, :);
    stateLogLatest = stateLogLatest(end, :);

    utInd = round(get(hSlider,'Value'));
    if(size(stateLog,1)==1)
        utSlider = stateLog(1,1);
    else
        utSlider = stateLog(utInd,1);
    end

    if(utSlider ~= ut)
        utInd = find(stateLog(:,1) >= ut,1,'first');
    end
    
    set(hUTSelectText, 'String', num2str(ut));
	set(hSlider, 'Value', utInd);
  
	ma_UpdateStateReadout(hStateLabel, 'initial', stateLogLatest, celBodyData);
    
    
function errMsg = validateInputs(hUTSelectText, minUT, maxUT)
    errMsg = {};
    
    value = str2double(get(hUTSelectText,'String'));
    enteredStr = get(hUTSelectText,'String');
    numberName = 'Universal Time';
    lb = minUT;
    ub = maxUT;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);


% --- Executes on slider movement.
function rightSlider_Callback(hObject, eventdata, handles)
% hObject    handle to rightSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    utInd = round(get(hObject,'Value'));
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    stateLog = maData.stateLog;
    if(size(stateLog,1)==1)
        ut = stateLog(1,1);
    else
        ut = stateLog(utInd,1);
    end
    sliderUTTextUpdtFunction(ut, handles.rightStateLabel, handles.rightSlider, handles.rightUTSelectText, handles);

% --- Executes during object creation, after setting all properties.
function rightSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rightSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function leftUTSelectText_Callback(hObject, eventdata, handles)
% hObject    handle to leftUTSelectText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of leftUTSelectText as text
%        str2double(get(hObject,'String')) returns contents of leftUTSelectText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    minUTInd = get(handles.leftSlider,'Min');
    maxUTInd = get(handles.leftSlider,'Max');
    
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    minUT = maData.stateLog(minUTInd,1);
    if(size(maData.stateLog,1) == 1)
        maxUT = maData.stateLog(1,1);
    else
        maxUT = maData.stateLog(maxUTInd,1);
    end
    
    errMsg = validateInputs(hObject, minUT, maxUT);
    ut = str2double(get(hObject,'String'));
    
    if(isempty(errMsg))
        sliderUTTextUpdtFunction(ut, handles.leftStateLabel, handles.leftSlider, handles.leftUTSelectText, handles);
    else
        msgbox(errMsg,'Errors were found while setting the state UT to display','error');
    end  

% --- Executes during object creation, after setting all properties.
function leftUTSelectText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to leftUTSelectText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function rightUTSelectText_Callback(hObject, eventdata, handles)
% hObject    handle to rightUTSelectText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of rightUTSelectText as text
%        str2double(get(hObject,'String')) returns contents of rightUTSelectText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

    minUTInd = get(handles.rightSlider,'Min');
    maxUTInd = get(handles.rightSlider,'Max');
    
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    minUT = maData.stateLog(minUTInd,1);
    if(size(maData.stateLog,1) == 1)
        maxUT = maData.stateLog(1,1);
    else
        maxUT = maData.stateLog(maxUTInd,1);
    end
    
    errMsg = validateInputs(hObject, minUT, maxUT);
    ut = str2double(get(hObject,'String'));
    
    if(isempty(errMsg))
        sliderUTTextUpdtFunction(ut, handles.rightStateLabel, handles.rightSlider, handles.rightUTSelectText, handles);
    else
        msgbox(errMsg,'Errors were found while setting the state UT to display','error');
    end 

% --- Executes during object creation, after setting all properties.
function rightUTSelectText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rightUTSelectText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on ma_StateLogGUI or any of its controls.
function ma_StateLogGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to ma_StateLogGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'escape'
            close(handles.ma_StateLogGUI);
    end