function varargout = ma_ThrusterManagerGUI(varargin)
% MA_THRUSTERMANAGERGUI MATLAB code for ma_ThrusterManagerGUI.fig
%      MA_THRUSTERMANAGERGUI, by itself, creates a new MA_THRUSTERMANAGERGUI or raises the existing
%      singleton*.
%
%      H = MA_THRUSTERMANAGERGUI returns the handle to a new MA_THRUSTERMANAGERGUI or the handle to
%      the existing singleton*.
%
%      MA_THRUSTERMANAGERGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_THRUSTERMANAGERGUI.M with the given input arguments.
%
%      MA_THRUSTERMANAGERGUI('Property','Value',...) creates a new MA_THRUSTERMANAGERGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_ThrusterManagerGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_ThrusterManagerGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_ThrusterManagerGUI

% Last Modified by GUIDE v2.5 10-Sep-2015 20:22:16

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_ThrusterManagerGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_ThrusterManagerGUI_OutputFcn, ...
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


% --- Executes just before ma_ThrusterManagerGUI is made visible.
function ma_ThrusterManagerGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_ThrusterManagerGUI (see VARARGIN)

% Choose default command line output for ma_ThrusterManagerGUI
handles.output = hObject;
handles.ma_MainGUI = varargin{1};

% Update handles structure
guidata(hObject, handles);

%GUI Setup
populatePropellantTypesComboBox(handles);
populateThrustersListbox(handles, handles.thrusterListbox);
thrusterListbox_Callback(handles.thrusterListbox, [], handles);

% UIWAIT makes ma_ThrusterManagerGUI wait for user response (see UIRESUME)
uiwait(handles.ma_ThrusterManagerGUI);


function populatePropellantTypesComboBox(handles)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    propNames = maData.spacecraft.propellant.names;
    set(handles.propTypeCombo,'String',propNames);


function populateThrustersListbox(handles, hListbox)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    thrusters = maData.spacecraft.thrusters;
    
    listboxStr = cell(length(thrusters),1);
    for(i=1:length(thrusters)) %#ok<*NO4LP>
        listboxStr{i} = thrusters{i}.name;
    end
    
    set(hListbox, 'String', listboxStr);

% --- Outputs from this function are returned to the command line.
function varargout = ma_ThrusterManagerGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if(isempty(handles))
    varargout{1} = [];
else
    varargout{1} = handles.output;
end

% --- Executes on selection change in thrusterListbox.
function thrusterListbox_Callback(hObject, eventdata, handles)
% hObject    handle to thrusterListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns thrusterListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from thrusterListbox
maData = getappdata(handles.ma_MainGUI,'ma_data');
thrusterNum = get(hObject,'Value');
thruster = maData.spacecraft.thrusters{thrusterNum};

propNames = maData.spacecraft.propellant.names;

propType = thruster.propType;
switch propType
    case 'fuelOxMass'
        propTypeStr = propNames{1};

    case 'monoMass'
        propTypeStr = propNames{2};
         
    case 'xenonMass'
        propTypeStr = propNames{3};
        
    otherwise
        error(['Unknown propellant type: ', propType]);
end
propTypeValue = findValueFromComboBox(propTypeStr, handles.propTypeCombo);

set(handles.thrusterNameText,'String', thruster.name);
set(handles.propTypeCombo,'value',propTypeValue);
set(handles.thrusterIspText, 'String', thruster.isp);
set(handles.thrustText,'String', thruster.thrust);


% --- Executes during object creation, after setting all properties.
function thrusterListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to thrusterListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function thrusterNameText_Callback(hObject, eventdata, handles)
% hObject    handle to thrusterNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of thrusterNameText as text
%        str2double(get(hObject,'String')) returns contents of thrusterNameText as a double
    updateThrusterButton_Callback([], [], handles);

% --- Executes during object creation, after setting all properties.
function thrusterNameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to thrusterNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in propTypeCombo.
function propTypeCombo_Callback(hObject, eventdata, handles)
% hObject    handle to propTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns propTypeCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from propTypeCombo
    updateThrusterButton_Callback([], [], handles);

% --- Executes during object creation, after setting all properties.
function propTypeCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to propTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in updateThrusterButton.
function updateThrusterButton_Callback(hObject, eventdata, handles)
% hObject    handle to updateThrusterButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);

    maData = getappdata(handles.ma_MainGUI,'ma_data');
    thrusters = maData.spacecraft.thrusters;
    thrusterNum = get(handles.thrusterListbox, 'value');
    curThruster = thrusters{thrusterNum};
    
    propNames = maData.spacecraft.propellant.names;
    
    if(isempty(errMsg))
        name = get(handles.thrusterNameText,'String');
        isp = str2double(get(handles.thrusterIspText,'String'));
        thrust = str2double(get(handles.thrustText,'String'));
        
        contents = cellstr(get(handles.propTypeCombo,'String'));
        selected = contents{get(handles.propTypeCombo,'Value')};
        
        switch selected
            case propNames{1}
                propTypeStr = 'fuelOxMass';

            case propNames{2}
                propTypeStr = 'monoMass';

            case propNames{3}
                propTypeStr = 'xenonMass';

            otherwise
                error(['Unknown propellant type: ', selected]);
        end 
        
        newThruster = ma_createThruster(name, propTypeStr, isp, thrust);
        thrusters{thrusterNum} = newThruster;
        maData.spacecraft.thrusters = thrusters;
        
        script = maData.script;
        for(i=1:length(script))
            event = script{i};
            if(isfield(event,'thruster'))
                thrusterInUse = event.thruster;
                if(isfield(thrusterInUse, 'id'))
                    tId = thrusterInUse.id;
                    if(tId == curThruster.id)
                        event.thruster = newThruster;
                        script{i} = event;
                    end
                end
            end
        end
        maData.script = script;        
        
        setappdata(handles.ma_MainGUI,'ma_data',maData);
        
        populateThrustersListbox(handles, handles.thrusterListbox);
        thrusterListbox_Callback(handles.thrusterListbox, [], handles);
    else
        msgbox(errMsg,'Errors were found while adding a thruster.','error');
    end


function thrusterIspText_Callback(hObject, eventdata, handles)
% hObject    handle to thrusterIspText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of thrusterIspText as text
%        str2double(get(hObject,'String')) returns contents of thrusterIspText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

    updateThrusterButton_Callback([], [], handles);

% --- Executes during object creation, after setting all properties.
function thrusterIspText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to thrusterIspText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addThruster.
function addThruster_Callback(hObject, eventdata, handles)
% hObject    handle to addThruster (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    thrusters = maData.spacecraft.thrusters;
    
    name = 'New Thruster';
    isp = 390;
    thrust = 100;
    propTypeStr = 'fuelOxMass';

    newThruster = ma_createThruster(name, propTypeStr, isp, thrust);
    thrusters{end+1} = newThruster;
    maData.spacecraft.thrusters = thrusters;
    setappdata(handles.ma_MainGUI,'ma_data',maData);

    set(handles.thrusterListbox,'value',length(thrusters));

    populateThrustersListbox(handles, handles.thrusterListbox);
    thrusterListbox_Callback(handles.thrusterListbox, [], handles);


function errMsg = validateInputs(handles)
    errMsg = {};
    
    isp = str2double(get(handles.thrusterIspText,'String'));
    enteredStr = get(handles.thrusterIspText,'String');
    numberName = 'Thruster Isp';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(isp, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    thrust = str2double(get(handles.thrustText,'String'));
    enteredStr = get(handles.thrustText,'String');
    numberName = 'Thruster Thrust';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(thrust, numberName, lb, ub, isInt, errMsg, enteredStr);



% --- Executes on button press in delete.
function delete_Callback(hObject, eventdata, handles)
% hObject    handle to delete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    thrusters = maData.spacecraft.thrusters;
    thrusterNum = get(handles.thrusterListbox, 'value');
    thruster = thrusters{thrusterNum};
    
    if(length(get(handles.thrusterListbox,'String')) == 1)
        msgbox(['Cannot delete: Thruster ', thruster.name, ' is only remaining thruster.'],'Error Deleting Thruster','error','modal');
        return;
    end
    
    eventsInUse = [];
    script = maData.script;
    for(i=1:length(script))
        event = script{i};
        if(isfield(event,'thruster'))
            thrusterInUse = event.thruster;
            if(isfield(thrusterInUse, 'id'))
                tId = thrusterInUse.id;
                if(tId == thruster.id)
                    eventsInUse(end+1) = i; %#ok<AGROW>
                end
            end
        end
    end
       
    if(~isempty(eventsInUse))
        eventStr = '';
        for(i=1:length(eventsInUse))
            if(i < length(eventsInUse))
                eventStr = [eventStr, num2str(eventsInUse(i)), ', '];
            else
                eventStr = [eventStr, num2str(eventsInUse(i))];
            end
        end
        
        msgbox(['Cannot delete: Thruster ', thruster.name, ' is in use in events: ' eventStr],'Error Deleting Thruster','error','modal');
    else
        thrusters{thrusterNum} = [];
        reorgThrusters = {};
        for(i=1:length(thrusters))
            if(~isempty(thrusters{i}) && isstruct(thrusters{i}))
                reorgThrusters{end+1} = thrusters{i};
            end
        end
        
        maData.spacecraft.thrusters = reorgThrusters;
        setappdata(handles.ma_MainGUI,'ma_data',maData);
        
        if(length(reorgThrusters) >= thrusterNum)
            set(handles.thrusterListbox,'value',thrusterNum);
        elseif((length(reorgThrusters) < thrusterNum))
            set(handles.thrusterListbox,'value',length(reorgThrusters));
        else
            set(handles.thrusterListbox,'value',1);
        end
        populateThrustersListbox(handles, handles.thrusterListbox);
        thrusterListbox_Callback(handles.thrusterListbox, [], handles);
    end



function thrustText_Callback(hObject, eventdata, handles)
% hObject    handle to thrustText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of thrustText as text
%        str2double(get(hObject,'String')) returns contents of thrustText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

    updateThrusterButton_Callback([], [], handles);

% --- Executes during object creation, after setting all properties.
function thrustText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to thrustText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on ma_ThrusterManagerGUI or any of its controls.
function ma_ThrusterManagerGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to ma_ThrusterManagerGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'escape'
            close(handles.ma_ThrusterManagerGUI);
    end
