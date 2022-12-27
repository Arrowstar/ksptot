function varargout = ma_ConstraintDetailsGUI(varargin)
% MA_CONSTRAINTDETAILSGUI MATLAB code for ma_ConstraintDetailsGUI.fig
%      MA_CONSTRAINTDETAILSGUI, by itself, creates a new MA_CONSTRAINTDETAILSGUI or raises the existing
%      singleton*.
%
%      H = MA_CONSTRAINTDETAILSGUI returns the handle to a new MA_CONSTRAINTDETAILSGUI or the handle to
%      the existing singleton*.
%
%      MA_CONSTRAINTDETAILSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_CONSTRAINTDETAILSGUI.M with the given input arguments.
%
%      MA_CONSTRAINTDETAILSGUI('Property','Value',...) creates a new MA_CONSTRAINTDETAILSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_ConstraintDetailsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_ConstraintDetailsGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_ConstraintDetailsGUI

% Last Modified by GUIDE v2.5 29-Oct-2014 19:07:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_ConstraintDetailsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_ConstraintDetailsGUI_OutputFcn, ...
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


% --- Executes just before ma_ConstraintDetailsGUI is made visible.
function ma_ConstraintDetailsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_ConstraintDetailsGUI (see VARARGIN)

handles.ma_MainGUI = varargin{1};
type               = varargin{2};
unit               = varargin{3};
lbLim              = varargin{4};
ubLim              = varargin{5};
lbVal              = varargin{6};
ubVal              = varargin{7};
bodyID             = varargin{8};
eventNum           = varargin{9};
otherSCID          = varargin{10};
eventID            = varargin{11};
lbActive           = varargin{12};
ubActive           = varargin{13};

% Choose default command line output for ma_ConstraintDetailsGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

set(hObject, 'UserData', [lbLim, ubLim, eventNum, eventID]);

populateBodiesCombo(getappdata(handles.ma_MainGUI,'celBodyData'), handles.celBodyCombo, true);
populateOtherSCCombo(handles, handles.otherSCCombo);
populateEventCombo(handles.eventCombo, handles);
initGUI(handles,type,unit,lbVal,ubVal,bodyID,otherSCID,eventID,lbActive,ubActive);

% UIWAIT makes ma_ConstraintDetailsGUI wait for user response (see UIRESUME)
uiwait(handles.ma_ConstraintDetailsGUI);


function initGUI(handles,type,unit,lbVal,ubVal,bodyID,otherSCID,eventID,lbActive,ubActive)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    
    set(handles.constType,'String',type);
    set(handles.constType,'TooltipString',type);
    set(handles.lbUnit,'String',unit);
    set(handles.ubUnit,'String',unit);
    
    set(handles.lbText,'String',num2str(lbVal));
    set(handles.ubText,'String',num2str(ubVal));
        
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    if(~isempty(bodyInfo))
        value = findValueFromComboBox(bodyInfo.name, handles.celBodyCombo);
    else
        value = 1;
    end
    set(handles.celBodyCombo,'value',value);
    
    if(isfield(maData.spacecraft,'otherSC'))
        otherSC = maData.spacecraft.otherSC;
        if(~isempty(otherSC))
            enableRefSC = true;
            for(i=1:length(otherSC))
                oSC = otherSC{i};
                if(oSC.id == otherSCID)
                    value = findValueFromComboBox(oSC.name, handles.otherSCCombo);
                    set(handles.otherSCCombo,'value',value);
                    break;
                end
            end
        else
            enableRefSC = false;
        end
    end
    
    if(eventID >= 0)
        [~, eventNum] = getEventByID(eventID, maData.script);
        set(handles.eventCombo,'value',eventNum);
    else
        set(handles.eventCombo,'value',length(maData.script));
    end
    
    if(lbActive)
        set(handles.lbActiveCheckbox,'Value',1);
    else
        set(handles.lbActiveCheckbox,'Value',0);
    end
    
    if(ubActive)
        set(handles.ubActiveCheckbox,'Value',1);
    else
        set(handles.ubActiveCheckbox,'Value',0);
    end
       
    setGUIEnables(handles, enableRefSC, lbActive, ubActive);
    lbActiveCheckbox_Callback(handles.lbActiveCheckbox, [], handles);
    ubActiveCheckbox_Callback(handles.ubActiveCheckbox, [], handles);
    setGUIEnables(handles, enableRefSC, lbActive, ubActive);
    
    
function populateEventCombo(hCombo, handles)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    script = maData.script;
    
    i = 1;
    listboxStr = {};
    for(eventArr = script) %#ok<*NO4LP>
        event = eventArr{1};
        listboxStr{end+1} = ['Event ', num2str(i), ': ', event.name]; %#ok<AGROW>
        i = i+1;
    end
    
    set(hCombo,'String',listboxStr);

function setGUIEnables(handles, enableRefSC, lbActive, ubActive)
    type = get(handles.constType,'String');
    switch type
        case 'Central Body ID'
            set(handles.celBodyCombo,'Enable','on');
            set(handles.lbText,'Enable','off');
            set(handles.ubText,'Enable','off');
            set(handles.lbActiveCheckbox,'Enable','off');
            set(handles.ubActiveCheckbox,'Enable','off');
            set(handles.lbActiveCheckbox,'Value',1);
            set(handles.ubActiveCheckbox,'Value',1);
            set(handles.otherSCCombo,'Enable','off');
        case {'Distance to Ref. Spacecraft', 'Relative Vel. to Ref. Spacecraft', 'Relative Pos. of Ref. Spacecraft (In-Track)', 'Relative Pos. of Ref. Spacecraft (Cross-Track)', 'Relative Pos. of Ref. Spacecraft (Radial)', ...
              'Relative SMA of Ref. Spacecraft','Relative Eccentricity of Ref. Spacecraft','Relative Inclination of Ref. Spacecraft','Relative RAAN of Ref. Spacecraft','Relative Argument of Periapsis of Ref. Spacecraft', ...
              'Relative Pos. of Ref. Spacecraft (In-Track; Ref. SC-centered)', 'Relative Pos. of Ref. Spacecraft (Cross-Track; Ref. SC-centered)', 'Relative Pos. of Ref. Spacecraft (Radial; Ref. SC-centered)'}
            set(handles.celBodyCombo,'Enable','off');
            if(lbActive)
                set(handles.lbText,'Enable','on');
            else
                set(handles.lbText,'Enable','off');
            end
            if(ubActive)
                set(handles.ubText,'Enable','on');
            else
                set(handles.ubText,'Enable','off');
            end
            if(enableRefSC)
                set(handles.otherSCCombo,'Enable','on');
            end
        otherwise
            set(handles.celBodyCombo,'Enable','on');
            if(lbActive)
                set(handles.lbText,'Enable','on');
            else
                set(handles.lbText,'Enable','off');
            end
            if(ubActive)
                set(handles.ubText,'Enable','on');
            else
                set(handles.ubText,'Enable','off');
            end
            set(handles.otherSCCombo,'Enable','off');
    end 
    

% --- Outputs from this function are returned to the command line.
function varargout = ma_ConstraintDetailsGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if(isempty(handles))
    varargout{1} = [];
    varargout{2} = [];
    varargout{3} = [];
    varargout{4} = [];
    varargout{5} = [];
    varargout{6} = [];
    varargout{7} = [];
    varargout{8} = [];
else
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    
    lbValue = str2double(get(handles.lbText,'String'));
    ubValue = str2double(get(handles.ubText,'String'));
    
    lbValueToStore = lbValue;
    ubValueToStore = ubValue;
    
    if(get(handles.lbActiveCheckbox,'value'))
        lbActive = true;
    else
        lbActive = false;
    end
    
    if(get(handles.ubActiveCheckbox,'value'))
        ubActive = true;
    else
        ubActive = false;
    end
    
    eventNum = get(handles.eventCombo,'value');
    eventID = ma_GetEventIDByEventNum(eventNum, maData.script);
    
    contents = cellstr(get(handles.celBodyCombo,'String'));
    selected = contents{get(handles.celBodyCombo,'Value')};
    celBodyComboSelected = selected;
    if(strcmpi(selected,''))
        bodyInfo.id = -1;
    else
        bodyInfo = celBodyData.(strtrim(lower(selected)));
    end
    
    value = get(handles.otherSCCombo,'Value');
    if(value < 1 || strcmpi(get(handles.otherSCCombo,'Enable'), 'off'))
        otherSC.id = -1;
    else
        otherSC = maData.spacecraft.otherSC{value};
    end
    
    type = get(handles.constType,'String');

	const = buildConstraints(maData, celBodyData, lbValue, ubValue, eventID, celBodyComboSelected, otherSC, type, lbActive, ubActive);
    
    varargout{1} = const;
    varargout{2} = lbValueToStore;
    varargout{3} = ubValueToStore;
    varargout{4} = bodyInfo.id;
    varargout{5} = otherSC.id;
    varargout{6} = eventID;
    varargout{7} = lbActive;
    varargout{8} = ubActive;
    close(handles.ma_ConstraintDetailsGUI);
end


function errMsg = validateInputs(handles)
    pause(0.025);
    lbActive = logical(get(handles.lbActiveCheckbox,'Value'));
    ubActive = logical(get(handles.ubActiveCheckbox,'Value'));
    
    type = get(handles.constType,'String');
    bndLim = get(handles.ma_ConstraintDetailsGUI, 'UserData');
    lbLim = bndLim(1);
    ubLim = bndLim(2);
    errMsg = {};
    
    if(lbActive)
        lbValue = str2double(get(handles.lbText,'String'));
        enteredStr = get(handles.lbText,'String');
        numberName = [type, ' Lower Bound'];
        lb = lbLim;
        ub = ubLim;
        isInt = false;
        errMsg = validateNumber(lbValue, numberName, lb, ub, isInt, errMsg, enteredStr);
    end
    
    if(ubActive)
        ubValue = str2double(get(handles.ubText,'String'));
        enteredStr = get(handles.ubText,'String');
        numberName = [type, ' Upper Bound'];
        lb = lbLim;
        ub = ubLim;
        isInt = false;
        errMsg = validateNumber(ubValue, numberName, lb, ub, isInt, errMsg, enteredStr);
    end
    
    if(isempty(errMsg))
        if(lbActive && ubActive)
            lbValue = str2double(get(handles.lbText,'String'));
            enteredStr = get(handles.lbText,'String');
            numberName = [type, ' Lower Bound'];
            lb = lbLim;
            ub = ubValue;
            isInt = false;
            errMsg = validateNumber(lbValue, numberName, lb, ub, isInt, errMsg, enteredStr);
        elseif(~lbActive && ubActive)
            ubValue = str2double(get(handles.ubText,'String'));
            enteredStr = get(handles.ubText,'String');
            numberName = [type, ' Upper Bound'];
            lb = -Inf;
            ub = ubLim;
            isInt = false;
            errMsg = validateNumber(ubValue, numberName, lb, ub, isInt, errMsg, enteredStr);
        elseif(lbActive && ~ubActive)
            lbValue = str2double(get(handles.lbText,'String'));
            enteredStr = get(handles.lbText,'String');
            numberName = [type, ' Lower Bound'];
            lb = lbLim;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(lbValue, numberName, lb, ub, isInt, errMsg, enteredStr);
        end
    end


function lbText_Callback(hObject, eventdata, handles)
% hObject    handle to lbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lbText as text
%        str2double(get(hObject,'String')) returns contents of lbText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function lbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ubText_Callback(hObject, eventdata, handles)
% hObject    handle to ubText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ubText as text
%        str2double(get(hObject,'String')) returns contents of ubText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function ubText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ubText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in celBodyCombo.
function celBodyCombo_Callback(hObject, eventdata, handles)
% hObject    handle to celBodyCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns celBodyCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from celBodyCombo


% --- Executes during object creation, after setting all properties.
function celBodyCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to celBodyCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);

    if(isempty(errMsg))
        uiresume(handles.ma_ConstraintDetailsGUI);
    else
        msgbox(errMsg,'Errors were found while adding a constraint.','error');
    end 


% --- Executes on selection change in otherSCCombo.
function otherSCCombo_Callback(hObject, eventdata, handles)
% hObject    handle to otherSCCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns otherSCCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from otherSCCombo


% --- Executes during object creation, after setting all properties.
function otherSCCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to otherSCCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in eventCombo.
function eventCombo_Callback(hObject, eventdata, handles)
% hObject    handle to eventCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns eventCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from eventCombo


% --- Executes during object creation, after setting all properties.
function eventCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eventCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on ma_ConstraintDetailsGUI or any of its controls.
function ma_ConstraintDetailsGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to ma_ConstraintDetailsGUI (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
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
            close(handles.ma_ConstraintDetailsGUI);
    end

% --- Executes on button press in lbActiveCheckbox.
function lbActiveCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to lbActiveCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of lbActiveCheckbox
    if(get(hObject,'Value'))
        set(handles.lbText,'Enable','on');
    else
        set(handles.lbText,'Enable','off');
    end

% --- Executes on button press in ubActiveCheckbox.
function ubActiveCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to ubActiveCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ubActiveCheckbox
    if(get(hObject,'Value'))
        set(handles.ubText,'Enable','on');
    else
        set(handles.ubText,'Enable','off');
    end
