function varargout = lvd_EditGeometricAngleConstraintGUI(varargin)
% LVD_EDITGEOMETRICANGLECONSTRAINTGUI MATLAB code for lvd_EditGeometricAngleConstraintGUI.fig
%      LVD_EDITGEOMETRICANGLECONSTRAINTGUI, by itself, creates a new LVD_EDITGEOMETRICANGLECONSTRAINTGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITGEOMETRICANGLECONSTRAINTGUI returns the handle to a new LVD_EDITGEOMETRICANGLECONSTRAINTGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITGEOMETRICANGLECONSTRAINTGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITGEOMETRICANGLECONSTRAINTGUI.M with the given input arguments.
%
%      LVD_EDITGEOMETRICANGLECONSTRAINTGUI('Property','Value',...) creates a new LVD_EDITGEOMETRICANGLECONSTRAINTGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditGeometricAngleConstraintGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditGeometricAngleConstraintGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditGeometricAngleConstraintGUI

% Last Modified by GUIDE v2.5 27-Feb-2021 15:21:27

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditGeometricAngleConstraintGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditGeometricAngleConstraintGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditGeometricAngleConstraintGUI is made visible.
function lvd_EditGeometricAngleConstraintGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditGeometricAngleConstraintGUI (see VARARGIN)

    % Choose default command line output for lvd_EditGeometricAngleConstraintGUI
    handles.output = hObject;

    constraint = varargin{1};
    setappdata(hObject, 'constraint', constraint);
    
    lvdData = varargin{2};
    setappdata(hObject,'lvdData',lvdData);
    
	populateGUI(handles, constraint, lvdData);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditGeometricAngleConstraintGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditGeometricAngleConstraintGUI);

function populateGUI(handles, constraint, lvdData)
    handles.constraintTypeLabel.String = constraint.getConstraintType();
    handles.constraintTypeLabel.TooltipString = constraint.getConstraintType();
    [unit, ~, ~, usesLbUb, ~, ~] = constraint.getConstraintStaticDetails();
    
    if(usesLbUb)
        [lb, ub] = constraint.getBounds();
        handles.ubText.String = fullAccNum2Str(ub);
        handles.lbText.String = fullAccNum2Str(lb);
    else
        handles.ubText.String = fullAccNum2Str(0);
        handles.lbText.String = fullAccNum2Str(0);
        handles.lbText.Enable = 'off';
        handles.ubText.Enable = 'off';
    end
    
    handles.scaleFactorText.String = fullAccNum2Str(constraint.getScaleFactor());
    
    handles.ubUnitLabel.String = unit;
    handles.lbUnitLabel.String = unit;
    
    evtNum = lvdData.script.getNumOfEvent(constraint.event);
    handles.eventCombo.String = lvdData.script.getListboxStr();
    if(not(isempty(evtNum)))
        handles.eventCombo.Value = evtNum;
    else
        handles.eventCombo.Value = 1;
    end
    
    handles.angleCombo.String = lvdData.geometry.angles.getListboxStr();
    
    if(isempty(constraint.angle))
        angleInd = 1;
    else
        angleInd = lvdData.geometry.angles.getIndsForAngles(constraint.angle);
    end
    handles.angleCombo.Value = angleInd;
    
    handles.useAbsValueCheckbox.Value = double(constraint.useAbsValue);
    handles.constActiveCheckbox.Value = constraint.active;
    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditGeometricAngleConstraintGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        constraint = getappdata(hObject, 'constraint');
        lvdData = getappdata(hObject,'lvdData');
        
        constraint.lb = str2double(handles.lbText.String);
        constraint.ub = str2double(handles.ubText.String);
        
        constraint.setScaleFactor(str2double(handles.scaleFactorText.String));
        
        constraint.angle = lvdData.geometry.angles.getAngleAtInd(handles.angleCombo.Value);
        
        numEvents = lvdData.script.getTotalNumOfEvents();
        if(numEvents > 0)
            eventNum = handles.eventCombo.Value;
            constraint.event = lvdData.script.getEventForInd(eventNum);
        else
            constraint.event = LaunchVehicleEvent.empty(1,0);
        end
        
        constraint.active = logical(handles.constActiveCheckbox.Value);
        constraint.useAbsValue = logical(handles.useAbsValueCheckbox.Value);
        
        varargout{1} = true;
        close(handles.lvd_EditGeometricAngleConstraintGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_EditGeometricAngleConstraintGUI);
    else
        msgbox(errMsg,'Invalid Constraint Inputs','error');
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    
    constraint = getappdata(handles.lvd_EditGeometricAngleConstraintGUI, 'constraint');
    [~, lbLim, ubLim, usesLbUb, ~, ~] = constraint.getConstraintStaticDetails();
    
    if(usesLbUb)
        lwrBnd = str2double(get(handles.lbText,'String'));
        enteredStr = get(handles.lbText,'String');
        numberName = 'Lower Bound';
        lb = lbLim;
        ub = Inf;
        isInt = false;
        errMsg = validateNumber(lwrBnd, numberName, lb, ub, isInt, errMsg, enteredStr);

        uprBnd = str2double(get(handles.ubText,'String'));
        enteredStr = get(handles.ubText,'String');
        numberName = 'Upper Bound';
        lb = -Inf;
        ub = ubLim;
        isInt = false;
        errMsg = validateNumber(uprBnd, numberName, lb, ub, isInt, errMsg, enteredStr);

        if(isempty(errMsg))
            uprBnd = str2double(get(handles.ubText,'String'));
            enteredStr = get(handles.ubText,'String');
            numberName = 'Upper Bound';
            lb = lwrBnd;
            ub = ubLim;
            isInt = false;
            errMsg = validateNumber(uprBnd, numberName, lb, ub, isInt, errMsg, enteredStr);
        end
    end
    
    sf = str2double(get(handles.scaleFactorText,'String'));
    enteredStr = get(handles.scaleFactorText,'String');
    numberName = 'Scale Factor';
    lb = 1E-12;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(sf, numberName, lb, ub, isInt, errMsg, enteredStr);

    
% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditGeometricAngleConstraintGUI);


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


% --- Executes during object creation, after setting all properties.
function constraintTypeLabel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to constraintTypeLabel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called



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


% --- Executes on selection change in angleCombo.
function angleCombo_Callback(hObject, eventdata, handles)
% hObject    handle to angleCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns angleCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from angleCombo


% --- Executes during object creation, after setting all properties.
function angleCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angleCombo (see GCBO)
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



function scaleFactorText_Callback(hObject, eventdata, handles)
% hObject    handle to scaleFactorText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of scaleFactorText as text
%        str2double(get(hObject,'String')) returns contents of scaleFactorText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function scaleFactorText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scaleFactorText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on lvd_EditGeometricAngleConstraintGUI or any of its controls.
function lvd_EditGeometricAngleConstraintGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditGeometricAngleConstraintGUI (see GCBO)
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
            close(handles.lvd_EditGeometricAngleConstraintGUI);
    end


% --- Executes on button press in constActiveCheckbox.
function constActiveCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to constActiveCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of constActiveCheckbox


% --- Executes on button press in useAbsValueCheckbox.
function useAbsValueCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to useAbsValueCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of useAbsValueCheckbox
