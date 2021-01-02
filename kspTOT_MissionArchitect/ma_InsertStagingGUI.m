function varargout = ma_InsertStagingGUI(varargin)
% MA_INSERTSTAGINGGUI MATLAB code for ma_InsertStagingGUI.fig
%      MA_INSERTSTAGINGGUI, by itself, creates a new MA_INSERTSTAGINGGUI or raises the existing
%      singleton*.
%
%      H = MA_INSERTSTAGINGGUI returns the handle to a new MA_INSERTSTAGINGGUI or the handle to
%      the existing singleton*.
%
%      MA_INSERTSTAGINGGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_INSERTSTAGINGGUI.M with the given input arguments.
%
%      MA_INSERTSTAGINGGUI('Property','Value',...) creates a new MA_INSERTSTAGINGGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_InsertStagingGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_InsertStagingGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_InsertStagingGUI

% Last Modified by GUIDE v2.5 18-Jul-2015 21:18:23

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_InsertStagingGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_InsertStagingGUI_OutputFcn, ...
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


% --- Executes just before ma_InsertStagingGUI is made visible.
function ma_InsertStagingGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_InsertStagingGUI (see VARARGIN)

% Choose default command line output for ma_InsertStagingGUI
handles.output = hObject;
handles.ma_MainGUI = varargin{1};

setResourceLabelStrings(handles);
if(length(varargin)>1)
    event = varargin{2};
    populateGUIWithEvent(handles, event);
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ma_InsertStagingGUI wait for user response (see UIRESUME)
uiwait(handles.ma_InsertStagingGUI);

function setResourceLabelStrings(handles)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    names = maData.spacecraft.propellant.names;
    
    set(handles.resource1Label,'String',names{1});
    set(handles.resource2Label,'String',names{2});
    set(handles.resource3Label,'String',names{3});

function populateGUIWithEvent(handles, event)
    set(handles.titleLabel, 'String', 'Edit Staging');
    set(handles.ma_InsertStagingGUI, 'Name', 'Edit Staging');
    set(handles.nameText, 'String', event.name);
            
    newMasses = event.stagingValue;

    set(handles.dryMassText,'String', fullAccNum2Str(newMasses(1)));
    set(handles.fuelOxMassText,'String', fullAccNum2Str(newMasses(2)));
    set(handles.monopropMassText,'String', fullAccNum2Str(newMasses(3)));
    set(handles.xenonMassText,'String', fullAccNum2Str(newMasses(4)));


% --- Outputs from this function are returned to the command line.
function varargout = ma_InsertStagingGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if(isempty(handles))
    varargout{1} = [];
else
    name = get(handles.nameText, 'String');
    
    dryMass = str2double(get(handles.dryMassText,'String'));
    fuelOxMass = str2double(get(handles.fuelOxMassText,'String'));
    monopropMass = str2double(get(handles.monopropMassText,'String'));
    xenonMass = str2double(get(handles.xenonMassText,'String'));
    
    stagingValue = [dryMass fuelOxMass monopropMass xenonMass];
    
    varargout{1} = ma_createStaging(name, stagingValue);
    close(handles.ma_InsertStagingGUI);
end


% --- Executes on button press in saveCloseButton.
function saveCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);

    if(isempty(errMsg))
        uiresume(handles.ma_InsertStagingGUI);
    else
        msgbox(errMsg,'Errors were found while inserting a mass dump.','error');
    end
    
function errMsg = validateInputs(handles)    
    errMsg = {};

    dryMass = str2double(get(handles.dryMassText,'String'));
    enteredStr = get(handles.dryMassText,'String');
    numberName = 'Post Staging New Dry Mass';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(dryMass, numberName, lb, ub, isInt, errMsg, enteredStr);

    fuelOxMass = str2double(get(handles.fuelOxMassText,'String'));
    enteredStr = get(handles.fuelOxMassText,'String');
    numberName = 'Post Staging New Fuel/Ox Mass';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(fuelOxMass, numberName, lb, ub, isInt, errMsg, enteredStr);

    monopropMass = str2double(get(handles.monopropMassText,'String'));
    enteredStr = get(handles.monopropMassText,'String');
    numberName = 'Post Staging New Monoprop Mass';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(monopropMass, numberName, lb, ub, isInt, errMsg, enteredStr);

    xenonMass = str2double(get(handles.xenonMassText,'String'));
    enteredStr = get(handles.xenonMassText,'String');
    numberName = 'Post Staging New Xenon Mass';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(xenonMass, numberName, lb, ub, isInt, errMsg, enteredStr);    
    

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.ma_InsertStagingGUI);


function nameText_Callback(hObject, eventdata, handles)
% hObject    handle to nameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nameText as text
%        str2double(get(hObject,'String')) returns contents of nameText as a double


% --- Executes during object creation, after setting all properties.
function nameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dryMassText_Callback(hObject, eventdata, handles)
% hObject    handle to dryMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dryMassText as text
%        str2double(get(hObject,'String')) returns contents of dryMassText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function dryMassText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dryMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function fuelOxMassText_Callback(hObject, eventdata, handles)
% hObject    handle to fuelOxMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fuelOxMassText as text
%        str2double(get(hObject,'String')) returns contents of fuelOxMassText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function fuelOxMassText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fuelOxMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function monopropMassText_Callback(hObject, eventdata, handles)
% hObject    handle to monopropMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of monopropMassText as text
%        str2double(get(hObject,'String')) returns contents of monopropMassText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function monopropMassText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to monopropMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function xenonMassText_Callback(hObject, eventdata, handles)
% hObject    handle to xenonMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of xenonMassText as text
%        str2double(get(hObject,'String')) returns contents of xenonMassText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function xenonMassText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xenonMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on ma_InsertStagingGUI or any of its controls.
function ma_InsertStagingGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to ma_InsertStagingGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            saveCloseButton_Callback(handles.saveCloseButton, [], handles);
        case 'enter'
            saveCloseButton_Callback(handles.saveCloseButton, [], handles);
        case 'escape'
            close(handles.ma_InsertStagingGUI);
    end
