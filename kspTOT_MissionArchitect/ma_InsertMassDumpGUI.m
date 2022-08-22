function varargout = ma_InsertMassDumpGUI(varargin)
% MA_INSERTMASSDUMPGUI MATLAB code for ma_InsertMassDumpGUI.fig
%      MA_INSERTMASSDUMPGUI, by itself, creates a new MA_INSERTMASSDUMPGUI or raises the existing
%      singleton*.
%
%      H = MA_INSERTMASSDUMPGUI returns the handle to a new MA_INSERTMASSDUMPGUI or the handle to
%      the existing singleton*.
%
%      MA_INSERTMASSDUMPGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_INSERTMASSDUMPGUI.M with the given input arguments.
%
%      MA_INSERTMASSDUMPGUI('Property','Value',...) creates a new MA_INSERTMASSDUMPGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_InsertMassDumpGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_InsertMassDumpGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_InsertMassDumpGUI

% Last Modified by GUIDE v2.5 19-Jun-2014 19:45:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_InsertMassDumpGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_InsertMassDumpGUI_OutputFcn, ...
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


% --- Executes just before ma_InsertMassDumpGUI is made visible.
function ma_InsertMassDumpGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_InsertMassDumpGUI (see VARARGIN)

% Choose default command line output for ma_InsertMassDumpGUI
handles.output = hObject;
handles.ma_MainGUI = varargin{1};

% Update handles structure
guidata(hObject, handles);

if(length(varargin)>1)
    event = varargin{2};
    populateGUIWithEvent(handles, event);
end

% GUI Setup
setPropellantNameLabels(handles);
populateThrusterCombo(handles, handles.thrustersCombo);
massDumpTypeCombo_Callback(handles.massDumpTypeCombo, [], handles);
thrustersCombo_Callback(handles.thrustersCombo, [], handles);

% UIWAIT makes ma_InsertMassDumpGUI wait for user response (see UIRESUME)
uiwait(handles.ma_InsertMassDumpGUI);

function setPropellantNameLabels(handles)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    propNames = maData.spacecraft.propellant.names;
    
    set(handles.propName1Text,'String', propNames{1}, 'TooltipString', propNames{1});
    set(handles.propName2Text,'String', propNames{2}, 'TooltipString', propNames{2});
    set(handles.propName3Text,'String', propNames{3}, 'TooltipString', propNames{3});

function populateThrusterCombo(handles, hThrustersCombo)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    thrusters = maData.spacecraft.thrusters;
    
    thrusterComboStr = cell(length(thrusters),1);
    for(i=1:length(thrusters))
        thrusterComboStr{i} = thrusters{i}.name;
    end
    
    set(hThrustersCombo,'String',thrusterComboStr);
    
function populateGUIWithEvent(handles, event)
    maData = getappdata(handles.ma_MainGUI,'ma_data');

    set(handles.titleLabel, 'String', 'Edit Mass Dump');
    set(handles.ma_InsertMassDumpGUI, 'Name', 'Edit Mass Dump');
    set(handles.nameText, 'String', event.name);
    
    type = event.subType;
    switch type
        case 'basic'
            value = findValueFromComboBox('Mass Dump', handles.massDumpTypeCombo);
            set(handles.massDumpTypeCombo,'value',value);
            
            dmasses = event.dumpValue;
            
            set(handles.dryMassText,'String', fullAccNum2Str(dmasses(1)));
            set(handles.fuelOxMassText,'String', fullAccNum2Str(dmasses(2)));
            set(handles.monopropMassText,'String', fullAccNum2Str(dmasses(3)));
            set(handles.xenonMassText,'String', fullAccNum2Str(dmasses(4)));
        case 'delta-v'
            value = findValueFromComboBox('Delta-V Dump', handles.massDumpTypeCombo);
            set(handles.massDumpTypeCombo,'value',value);
            
            deltav = event.dumpValue;
            set(handles.deltavText,'String',fullAccNum2Str(deltav));
            
            thrusters = maData.spacecraft.thrusters;
            thrusterVal = 1;
            for(i=1:length(thrusters)) %#ok<*NO4LP>
                thrusterFromArr = thrusters{i};
                if(thrusterFromArr.id == event.thruster.id)
                    thrusterVal = i;
                    break;
                end
            end
            
            set(handles.thrustersCombo,'value',thrusterVal);
    end
    
% --- Outputs from this function are returned to the command line.
function varargout = ma_InsertMassDumpGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if(isempty(handles))
    varargout{1} = [];
else
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    
    name = get(handles.nameText, 'String');
               
    contents = cellstr(get(handles.massDumpTypeCombo,'String'));
    selected = contents{get(handles.massDumpTypeCombo,'Value')};
    
    switch selected
        case 'Mass Dump'
            subType = 'basic';
            
            dryMass = str2double(get(handles.dryMassText,'String'));
            fuelOxMass = str2double(get(handles.fuelOxMassText,'String'));
            monopropMass = str2double(get(handles.monopropMassText,'String'));
            xenonMass = str2double(get(handles.xenonMassText,'String'));
            
            massDumpValue = [dryMass fuelOxMass monopropMass xenonMass];
            
            thruster = [];
        case 'Delta-V Dump'
            subType = 'delta-v';
            
            deltav = str2double(get(handles.deltavText,'String'));
            
            massDumpValue = [deltav];
            
            thrusterNum = get(handles.thrustersCombo,'value');
            thruster = maData.spacecraft.thrusters{thrusterNum};
    end
    
    varargout{1} = ma_createMassDump(name, subType, massDumpValue, thruster);
    close(handles.ma_InsertMassDumpGUI);
end


% --- Executes on button press in saveCloseButton.
function saveCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);

    if(isempty(errMsg))
        uiresume(handles.ma_InsertMassDumpGUI);
    else
        msgbox(errMsg,'Errors were found while inserting a mass dump.','error');
    end


function errMsg = validateInputs(handles)
    contents = cellstr(get(handles.massDumpTypeCombo,'String'));
    selected = contents{get(handles.massDumpTypeCombo,'Value')};
    
    errMsg = {};
    
    switch selected
        case 'Mass Dump'
            dryMass = str2double(get(handles.dryMassText,'String'));
            enteredStr = get(handles.dryMassText,'String');
            numberName = 'Dry Mass to Dump';
            lb = 0;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(dryMass, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            fuelOxMass = str2double(get(handles.fuelOxMassText,'String'));
            enteredStr = get(handles.fuelOxMassText,'String');
            numberName = 'Fuel/Ox Mass to Dump';
            lb = 0;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(fuelOxMass, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            monopropMass = str2double(get(handles.monopropMassText,'String'));
            enteredStr = get(handles.monopropMassText,'String');
            numberName = 'Monoprop Mass to Dump';
            lb = 0;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(monopropMass, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            xenonMass = str2double(get(handles.xenonMassText,'String'));
            enteredStr = get(handles.xenonMassText,'String');
            numberName = 'Xenon Mass to Dump';
            lb = 0;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(xenonMass, numberName, lb, ub, isInt, errMsg, enteredStr);

        case 'Delta-V Dump'
            deltav = str2double(get(handles.deltavText,'String'));
            enteredStr = get(handles.deltavText,'String');
            numberName = 'Delta-V to Dump';
            lb = 0;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(deltav, numberName, lb, ub, isInt, errMsg, enteredStr);
    end


% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.ma_InsertMassDumpGUI);


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


% --- Executes on selection change in massDumpTypeCombo.
function massDumpTypeCombo_Callback(hObject, eventdata, handles)
% hObject    handle to massDumpTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns massDumpTypeCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from massDumpTypeCombo
    contents = cellstr(get(hObject,'String'));
    selected = contents{get(hObject,'Value')};
    
    switch selected
        case 'Mass Dump'
            set(handles.dryMassText,'Enable','on');
            set(handles.fuelOxMassText,'Enable','on');
            set(handles.monopropMassText,'Enable','on');
            set(handles.xenonMassText,'Enable','on');
            set(handles.deltavText,'Enable','off');
            set(handles.thrustersCombo,'Enable','off');
        case 'Delta-V Dump'
            set(handles.dryMassText,'Enable','off');
            set(handles.fuelOxMassText,'Enable','off');
            set(handles.monopropMassText,'Enable','off');
            set(handles.xenonMassText,'Enable','off');
            set(handles.deltavText,'Enable','on');
            set(handles.thrustersCombo,'Enable','on');
    end

% --- Executes during object creation, after setting all properties.
function massDumpTypeCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to massDumpTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
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



function deltavText_Callback(hObject, eventdata, handles)
% hObject    handle to deltavText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of deltavText as text
%        str2double(get(hObject,'String')) returns contents of deltavText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function deltavText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to deltavText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in thrustersCombo.
function thrustersCombo_Callback(hObject, eventdata, handles)
% hObject    handle to thrustersCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns thrustersCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from thrustersCombo
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    propNames = maData.spacecraft.propellant.names;
    thrusters = maData.spacecraft.thrusters;
    
    thruster = thrusters{get(handles.thrustersCombo,'Value')};
    propTypeIndex = ma_getPropTypeIndexFromInternalPropName(thruster.propType);
    set(handles.fuelTypeBeingDumpedLabel,'String',propNames{propTypeIndex});

% --- Executes during object creation, after setting all properties.
function thrustersCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to thrustersCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on ma_InsertMassDumpGUI or any of its controls.
function ma_InsertMassDumpGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to ma_InsertMassDumpGUI (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
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
            close(handles.ma_InsertMassDumpGUI);
    end
