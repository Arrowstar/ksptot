function varargout = lvd_EditGenericMAConstraintGUI(varargin)
% LVD_EDITGENERICMACONSTRAINTGUI MATLAB code for lvd_EditGenericMAConstraintGUI.fig
%      LVD_EDITGENERICMACONSTRAINTGUI, by itself, creates a new LVD_EDITGENERICMACONSTRAINTGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITGENERICMACONSTRAINTGUI returns the handle to a new LVD_EDITGENERICMACONSTRAINTGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITGENERICMACONSTRAINTGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITGENERICMACONSTRAINTGUI.M with the given input arguments.
%
%      LVD_EDITGENERICMACONSTRAINTGUI('Property','Value',...) creates a new LVD_EDITGENERICMACONSTRAINTGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditGenericMAConstraintGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditGenericMAConstraintGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditGenericMAConstraintGUI

% Last Modified by GUIDE v2.5 02-Nov-2018 17:10:22

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditGenericMAConstraintGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditGenericMAConstraintGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditGenericMAConstraintGUI is made visible.
function lvd_EditGenericMAConstraintGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditGenericMAConstraintGUI (see VARARGIN)

    % Choose default command line output for lvd_EditGenericMAConstraintGUI
    handles.output = hObject;

    constraint = varargin{1};
    setappdata(hObject, 'constraint', constraint);
    
    lvdData = varargin{2};
    setappdata(hObject,'lvdData',lvdData);
    
	populateGUI(handles, constraint, lvdData);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditGenericMAConstraintGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditGenericMAConstraintGUI);

function populateGUI(handles, constraint, lvdData)
    handles.constraintTypeLabel.String = constraint.constraintType;
    handles.constraintTypeLabel.TooltipString = constraint.constraintType;
    [unit, ~, ~, usesLbUb, usesCelBody, usesRefSc] = constraint.getConstraintStaticDetails();
    
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
    
    if(usesCelBody)
        populateBodiesCombo(lvdData.celBodyData, handles.celBodyCombo, true);
        if(not(isempty(constraint.refBodyInfo)))
            value = findValueFromComboBox(constraint.refBodyInfo.name, handles.celBodyCombo);
            handles.celBodyCombo.Value = value;
        else
            handles.celBodyCombo.Value = 1;
        end
    else
        handles.celBodyCombo.Enable = 'off';
    end
    
    if(usesRefSc)
        refOSc = constraint.refOtherSC;
        if(isempty(refOSc) || not(isfield(refOSc,'id')))
            otherSCID = [];
        else
            otherSCID = refOSc.id;
        end

        populateOtherSCCombo(handles, handles.refSpacecraftCombo);
        otherSC = {};
        if(~isempty(otherSC))
            enableRefSC = true;
            for(i=1:length(otherSC)) %#ok<*NO4LP>
                oSC = otherSC{i};
                if(oSC.id == otherSCID)
                    value = findValueFromComboBox(oSC.name, handles.refSpacecraftCombo);
                    set(handles.refSpacecraftCombo,'value',value);
                    break;
                end
            end
        else
            enableRefSC = false;
        end

        if(enableRefSC)
            handles.refSpacecraftCombo.Enable = 'on';
        else
            handles.refSpacecraftCombo.Enable = 'off';
        end
    else
        handles.refSpacecraftCombo.Enable = 'off';
    end
    
    evtNum = lvdData.script.getNumOfEvent(constraint.event);
    handles.eventCombo.String = lvdData.script.getListboxStr();
    if(not(isempty(evtNum)))
        handles.eventCombo.Value = evtNum;
    else
        handles.eventCombo.Value = 1;
    end
    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditGenericMAConstraintGUI_OutputFcn(hObject, eventdata, handles) 
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
        celBodyData = lvdData.celBodyData;
        
        constraint.lb = str2double(handles.lbText.String);
        constraint.ub = str2double(handles.ubText.String);
        
        constraint.setScaleFactor(str2double(handles.scaleFactorText.String));
        
        if(handles.celBodyCombo.Value > 1)
            bodyNameCell = handles.celBodyCombo.String(handles.celBodyCombo.Value);
            bodyName = lower(strtrim(bodyNameCell{1}));
            bodyInfo = celBodyData.(bodyName);
            constraint.refBodyInfo = bodyInfo;
        else
            constraint.refBodyInfo = KSPTOT_BodyInfo.empty(1,0);
        end
        
        otherSC = {};
        if(length(otherSC) > 1)
            selOSC = handles.refSpacecraftCombo.Value;
            constraint.refOtherSC = otherSC(selOSC);
        else
            constraint.refOtherSC = struct.empty(1,0);
        end
        
        numEvents = lvdData.script.getTotalNumOfEvents();
        if(numEvents > 0)
            eventNum = handles.eventCombo.Value;
            constraint.event = lvdData.script.getEventForInd(eventNum);
        else
            constraint.event = LaunchVehicleEvent.empty(1,0);
        end
        
        varargout{1} = true;
        close(handles.lvd_EditGenericMAConstraintGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_EditGenericMAConstraintGUI);
    else
        msgbox(errMsg,'Invalid Constraint Inputs','error');
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    
    lwrBnd = str2double(get(handles.lbText,'String'));
    enteredStr = get(handles.lbText,'String');
    numberName = 'Lower Bound';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(lwrBnd, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    uprBnd = str2double(get(handles.ubText,'String'));
    enteredStr = get(handles.ubText,'String');
    numberName = 'Upper Bound';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(uprBnd, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        uprBnd = str2double(get(handles.ubText,'String'));
        enteredStr = get(handles.ubText,'String');
        numberName = 'Upper Bound';
        lb = lwrBnd;
        ub = Inf;
        isInt = false;
        errMsg = validateNumber(uprBnd, numberName, lb, ub, isInt, errMsg, enteredStr);
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
    close(handles.lvd_EditGenericMAConstraintGUI);


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


% --- Executes on selection change in refSpacecraftCombo.
function refSpacecraftCombo_Callback(hObject, eventdata, handles)
% hObject    handle to refSpacecraftCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns refSpacecraftCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from refSpacecraftCombo


% --- Executes during object creation, after setting all properties.
function refSpacecraftCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to refSpacecraftCombo (see GCBO)
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
