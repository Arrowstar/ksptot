function varargout = lvd_EditTwoBodyPointGUI(varargin)
% LVD_EDITTWOBODYPOINTGUI MATLAB code for lvd_EditTwoBodyPointGUI.fig
%      LVD_EDITTWOBODYPOINTGUI, by itself, creates a new LVD_EDITTWOBODYPOINTGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITTWOBODYPOINTGUI returns the handle to a new LVD_EDITTWOBODYPOINTGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITTWOBODYPOINTGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITTWOBODYPOINTGUI.M with the given input arguments.
%
%      LVD_EDITTWOBODYPOINTGUI('Property','Value',...) creates a new LVD_EDITTWOBODYPOINTGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditTwoBodyPointGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditTwoBodyPointGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditTwoBodyPointGUI

% Last Modified by GUIDE v2.5 17-Jan-2021 11:22:18

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditTwoBodyPointGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditTwoBodyPointGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditTwoBodyPointGUI is made visible.
function lvd_EditTwoBodyPointGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditTwoBodyPointGUI (see VARARGIN)

    % Choose default command line output for lvd_EditTwoBodyPointGUI
    handles.output = hObject;

    point = varargin{1};
    setappdata(hObject, 'point', point);
    
    lvdData = varargin{2};
    setappdata(hObject, 'lvdData', lvdData);
    
    handles.ksptotMainGUI = varargin{3};
    
	populateGUI(handles, point);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditTwoBodyPointGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditTwoBodyPointGUI);

function populateGUI(handles, point)
    set(handles.pointNameText,'String',point.getName());
    elemSet = point.elemSet;
    setappdata(handles.lvd_EditTwoBodyPointGUI,'curElemSet',elemSet);
    
    handles.refFrameTypeCombo.String = ReferenceFrameEnum.getListBoxStr();
    handles.refFrameTypeCombo.Value = ReferenceFrameEnum.getIndForName(elemSet.frame.typeEnum.name);
    handles.setFrameOptionsButton.TooltipString = sprintf('Current Frame: %s', elemSet.frame.getNameStr());   
    
    handles.elementSetCombo.String = ElementSetEnum.getListBoxStr();
    value = ElementSetEnum.getIndForName(elemSet.typeEnum.name);
    handles.elementSetCombo.Value = value;
    elementSetCombo_Callback(handles.elementSetCombo, [], handles);
    
    handles.utText.String = fullAccNum2Str(elemSet.time);
    
    elemVector = elemSet.getElementVector();
    handles.orbit1Text.String = fullAccNum2Str(elemVector(1));
    handles.orbit2Text.String = fullAccNum2Str(elemVector(2));
    handles.orbit3Text.String = fullAccNum2Str(elemVector(3));
    handles.orbit4Text.String = fullAccNum2Str(elemVector(4));
    handles.orbit5Text.String = fullAccNum2Str(elemVector(5));
    handles.orbit6Text.String = fullAccNum2Str(elemVector(6));
    
    handles.pointColorCombo.String = ColorSpecEnum.getListboxStr();
    handles.pointColorCombo.Value = ColorSpecEnum.getIndForName(point.markerColor.name);

    handles.pointMarkerShapeCombo.String = MarkerStyleEnum.getListboxStr();
    handles.pointMarkerShapeCombo.Value = MarkerStyleEnum.getIndForName(point.markerShape.name);

    handles.pointLineColorCombo.String = ColorSpecEnum.getListboxStr();
    handles.pointLineColorCombo.Value = ColorSpecEnum.getIndForName(point.trkLineColor.name);

    handles.pointLineSpecCombo.String = LineSpecEnum.getListboxStr();
    handles.pointLineSpecCombo.Value = LineSpecEnum.getIndForName(point.trkLineSpec.name);

    handles.dispTrajCheckbox.Value = double(point.plotTrkLine);

% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditTwoBodyPointGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        lvdData = getappdata(hObject,'lvdData');
        point = getappdata(hObject, 'point');
        
        point.setName(handles.pointNameText.String);
                
        [elemSet, ~] = getCurrentElemSetFromExistingValues(handles);
        point.elemSet = elemSet;
        
        str = handles.pointColorCombo.String{handles.pointColorCombo.Value};
        point.markerColor = ColorSpecEnum.getEnumForListboxStr(str);
        
        str = handles.pointMarkerShapeCombo.String{handles.pointMarkerShapeCombo.Value};
        point.markerShape = MarkerStyleEnum.getEnumForListboxStr(str);
        
        str = handles.pointLineColorCombo.String{handles.pointLineColorCombo.Value};
        point.trkLineColor = ColorSpecEnum.getEnumForListboxStr(str);
        
        str = handles.pointLineSpecCombo.String{handles.pointLineSpecCombo.Value};
        point.trkLineSpec = LineSpecEnum.getEnumForListboxStr(str);
        
         point.plotTrkLine = logical(handles.dispTrajCheckbox.Value);
        
        maStateLog = lvdData.stateLog.getMAFormattedStateLogMatrix(false);
        
        stateLogMinTime = min(maStateLog(:,1));
        if(stateLogMinTime > 0)
            minTime = 0;
        else
            minTime = stateLogMinTime;
        end
        
        simMaxDur = lvdData.settings.simMaxDur;
        stateLogMaxTime = max(maStateLog(:,1));
        if(stateLogMinTime + simMaxDur > stateLogMaxTime)
            maxTime = stateLogMinTime + simMaxDur;
        else
            maxTime = stateLogMaxTime;
        end
        
        hHelpDlg = helpdlg('The two body point is (re-)generating its internal state cache.  Please wait.','Creating Cache');
        point.refeshTrajCache(minTime, maxTime);
        if(isvalid(hHelpDlg))
            close(hHelpDlg);
        end
        
        varargout{1} = true;
        close(handles.lvd_EditTwoBodyPointGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_EditTwoBodyPointGUI);
    else
        msgbox(errMsg,'Invalid Point Inputs','error');
    end


function errMsg = validateInputs(handles)
    errMsg = {};
        
    if(isempty(strtrim(handles.pointNameText.String)))
        errMsg{end+1} = {'Point name must contain more than white space and must not be empty.'};
    end
    
% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditTwoBodyPointGUI);


function pointNameText_Callback(hObject, eventdata, handles)
% hObject    handle to pointNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pointNameText as text
%        str2double(get(hObject,'String')) returns contents of pointNameText as a double


% --- Executes during object creation, after setting all properties.
function pointNameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pointNameText see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on lvd_EditTwoBodyPointGUI or any of its controls.
function lvd_EditTwoBodyPointGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditTwoBodyPointGUI (see GCBO)
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
            close(handles.lvd_EditTwoBodyPointGUI);
    end



% --- Executes on selection change in pointColorCombo.
function pointColorCombo_Callback(hObject, eventdata, handles)
% hObject    handle to pointColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pointColorCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pointColorCombo


% --- Executes during object creation, after setting all properties.
function pointColorCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pointColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pointLineSpecCombo.
function pointLineSpecCombo_Callback(hObject, eventdata, handles)
% hObject    handle to pointLineSpecCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pointLineSpecCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pointLineSpecCombo


% --- Executes during object creation, after setting all properties.
function pointLineSpecCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pointLineSpecCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pointLineColorCombo.
function pointLineColorCombo_Callback(hObject, eventdata, handles)
% hObject    handle to pointLineColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pointLineColorCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pointLineColorCombo


% --- Executes during object creation, after setting all properties.
function pointLineColorCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pointLineColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pointMarkerShapeCombo.
function pointMarkerShapeCombo_Callback(hObject, eventdata, handles)
% hObject    handle to pointMarkerShapeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pointMarkerShapeCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pointMarkerShapeCombo


% --- Executes during object creation, after setting all properties.
function pointMarkerShapeCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pointMarkerShapeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function utText_Callback(hObject, eventdata, handles)
% hObject    handle to utText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of utText as text
%        str2double(get(hObject,'String')) returns contents of utText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    updateValuesInState(handles);

% --- Executes during object creation, after setting all properties.
function utText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to utText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function orbit1Text_Callback(hObject, eventdata, handles)
% hObject    handle to orbit1Text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of orbit1Text as text
%        str2double(get(hObject,'String')) returns contents of orbit1Text as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    updateValuesInState(handles);


% --- Executes during object creation, after setting all properties.
function orbit1Text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to orbit1Text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function orbit2Text_Callback(hObject, eventdata, handles)
% hObject    handle to orbit2Text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of orbit2Text as text
%        str2double(get(hObject,'String')) returns contents of orbit2Text as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    updateValuesInState(handles);


% --- Executes during object creation, after setting all properties.
function orbit2Text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to orbit2Text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function orbit3Text_Callback(hObject, eventdata, handles)
% hObject    handle to orbit3Text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of orbit3Text as text
%        str2double(get(hObject,'String')) returns contents of orbit3Text as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    updateValuesInState(handles);


% --- Executes during object creation, after setting all properties.
function orbit3Text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to orbit3Text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function orbit4Text_Callback(hObject, eventdata, handles)
% hObject    handle to orbit4Text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of orbit4Text as text
%        str2double(get(hObject,'String')) returns contents of orbit4Text as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    updateValuesInState(handles);


% --- Executes during object creation, after setting all properties.
function orbit4Text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to orbit4Text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function orbit5Text_Callback(hObject, eventdata, handles)
% hObject    handle to orbit5Text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of orbit5Text as text
%        str2double(get(hObject,'String')) returns contents of orbit5Text as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    updateValuesInState(handles);


% --- Executes during object creation, after setting all properties.
function orbit5Text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to orbit5Text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function orbit6Text_Callback(hObject, eventdata, handles)
% hObject    handle to orbit6Text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of orbit6Text as text
%        str2double(get(hObject,'String')) returns contents of orbit6Text as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    updateValuesInState(handles);


% --- Executes during object creation, after setting all properties.
function orbit6Text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to orbit6Text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function updateStateDueToFrameChange(handles, newFrame)
    lvdData = getappdata(handles.lvd_EditTwoBodyPointGUI,'lvdData');
    celBodyData = lvdData.celBodyData;

    curElemSet = getappdata(handles.lvd_EditTwoBodyPointGUI,'curElemSet');
       
    contents = cellstr(get(handles.refFrameTypeCombo,'String'));
    selFrameType = contents{get(handles.refFrameTypeCombo,'Value')};
    refFrameEnum = ReferenceFrameEnum.getEnumForListboxStr(selFrameType);
    
    if(not(isempty(newFrame)) && newFrame.typeEnum ~= refFrameEnum)
        refFrameEnum = newFrame.typeEnum;
        handles.refFrameTypeCombo.Value = ReferenceFrameEnum.getIndForName(refFrameEnum.name);
    end
    
    switch refFrameEnum
        case ReferenceFrameEnum.BodyCenteredInertial
            if(isempty(newFrame))
                bodyInfo = getSelectedBodyInfo(handles);
            else
                bodyInfo = newFrame.getOriginBody();
            end            
            
            newFrame = bodyInfo.getBodyCenteredInertialFrame();

        case ReferenceFrameEnum.BodyFixedRotating
            if(isempty(newFrame))
                bodyInfo = getSelectedBodyInfo(handles);
            else
                bodyInfo = newFrame.getOriginBody();
            end
            
            newFrame = bodyInfo.getBodyFixedFrame();
            
        case ReferenceFrameEnum.TwoBodyRotating            
            if(isempty(newFrame))
                bodyInfo = getSelectedBodyInfo(handles);
                if(not(isempty(bodyInfo.childrenBodyInfo)))
                    primaryBody = bodyInfo;
                    secondaryBody = bodyInfo.childrenBodyInfo(1);
                else
                    primaryBody = bodyInfo.getParBodyInfo();
                    secondaryBody = bodyInfo;
                end
                
                originPt = TwoBodyRotatingFrameOriginEnum.Primary;
                
                newFrame = TwoBodyRotatingFrame(primaryBody, secondaryBody, originPt, celBodyData);
            else
                newFrame = TwoBodyRotatingFrame(newFrame.primaryBodyInfo, newFrame.secondaryBodyInfo, newFrame.originPt, celBodyData);
            end
            
        case ReferenceFrameEnum.UserDefined
            if(isempty(newFrame))
                numFrames = lvdData.geometry.refFrames.getNumRefFrames();
                if(numFrames >= 1)
                    geometricFrame = AbstractGeometricRefFrame.empty(1,0);
                    for(i=1:numFrames)
                        frame = lvdData.geometry.refFrames.getRefFrameAtInd(i);
                        if(frame.isVehDependent() == false)
                            geometricFrame = frame;
                            break;
                        end
                    end

                    if(not(isempty(geometricFrame)))
                        newFrame = UserDefinedGeometricFrame(geometricFrame, lvdData);
                    else
                        bodyInfo = getSelectedBodyInfo(handles);
                        newFrame = bodyInfo.getBodyCenteredInertialFrame();
                        
                        warndlg('There are no geometric frames available which are not dependent on vehicle properties.  A body-centered inertial frame will be selected instead.');
                    end
                else
                    bodyInfo = getSelectedBodyInfo(handles);
                    newFrame = bodyInfo.getBodyCenteredInertialFrame();
                    
                    warndlg('There are no geometric frames available which are not dependent on vehicle properties.  A body-centered inertial frame will be selected instead.');
                end
                
            else
                newFrame = UserDefinedGeometricFrame(newFrame.geometricFrame, lvdData);
            end

        otherwise
            error('Unknown reference frame type: %s', string(refFrameEnum));                
    end
    
    if(not(isempty(newFrame)) && newFrame.typeEnum ~= refFrameEnum)
        refFrameEnum = newFrame.typeEnum;
        handles.refFrameTypeCombo.Value = ReferenceFrameEnum.getIndForName(refFrameEnum.name);
    end
    
    try
        newElemSet = curElemSet.convertToFrame(newFrame);

        elemVect = newElemSet.getElementVector();
        
        if(any(isnan(elemVect)) || any(not(isfinite(elemVect))))
            error('State conversion resulted in NaN');
        end
        
        handles.orbit1Text.String = fullAccNum2Str(elemVect(1));
        handles.orbit2Text.String = fullAccNum2Str(elemVect(2));
        handles.orbit3Text.String = fullAccNum2Str(elemVect(3));
        handles.orbit4Text.String = fullAccNum2Str(elemVect(4));
        handles.orbit5Text.String = fullAccNum2Str(elemVect(5));
        handles.orbit6Text.String = fullAccNum2Str(elemVect(6));

        setappdata(handles.lvd_EditTwoBodyPointGUI,'curElemSet', newElemSet);
    catch ME
        updateValuesInState(handles);
        msgbox('Error converting state to new frame.','Conversion Error','error');
    end
    
    handles.setFrameOptionsButton.TooltipString = sprintf('Current Frame: %s', newFrame.getNameStr()); 


function updateValuesInState(handles)
    curElemSet = getappdata(handles.lvd_EditTwoBodyPointGUI,'curElemSet');
    newElemSet = curElemSet;
    
    time = str2double(handles.utText.String);
    orbit1Elem = str2double(handles.orbit1Text.String);
    orbit2Elem = str2double(handles.orbit2Text.String);
    orbit3Elem = str2double(handles.orbit3Text.String);
    orbit4Elem = str2double(handles.orbit4Text.String);
    orbit5Elem = str2double(handles.orbit5Text.String);
    orbit6Elem = str2double(handles.orbit6Text.String);
    
    frame = newElemSet.frame;
	switch newElemSet.typeEnum
        case ElementSetEnum.CartesianElements
            newElemSet = CartesianElementSet(time, [orbit1Elem; orbit2Elem; orbit3Elem], [orbit4Elem; orbit5Elem; orbit6Elem], frame);

        case ElementSetEnum.KeplerianElements
            newElemSet = KeplerianElementSet(time, orbit1Elem, orbit2Elem, deg2rad(orbit3Elem), deg2rad(orbit4Elem), deg2rad(orbit5Elem), deg2rad(orbit6Elem), frame);

        case ElementSetEnum.GeographicElements
            newElemSet = GeographicElementSet(time, deg2rad(orbit1Elem), deg2rad(orbit2Elem), orbit3Elem, deg2rad(orbit4Elem), deg2rad(orbit5Elem), orbit6Elem, frame);
                
        case ElementSetEnum.UniversalElements
            newElemSet = UniversalElementSet(time, orbit1Elem, orbit2Elem, deg2rad(orbit3Elem), deg2rad(orbit4Elem), deg2rad(orbit5Elem), orbit6Elem, frame);
        
        otherwise
            error('Unknown element set type: %s', string(elemSetEnum));
	end
    
    setappdata(handles.lvd_EditTwoBodyPointGUI,'curElemSet', newElemSet);

    
function bodyInfo = getSelectedBodyInfo(handles)
    curElemSet = getappdata(handles.lvd_EditTwoBodyPointGUI,'curElemSet');
    bodyInfo = curElemSet.frame.getOriginBody();
    
    
function [orbitModel, elemSetEnum] = getCurrentElemSetFromExistingValues(handles)
        contents = cellstr(get(handles.elementSetCombo,'String'));
        selElemSet = contents{get(handles.elementSetCombo,'Value')};
        elemSetEnum = ElementSetEnum.getEnumForListboxStr(selElemSet);
                
        time = str2double(handles.utText.String);
        
        orbit1Elem = str2double(handles.orbit1Text.String);
        orbit2Elem = str2double(handles.orbit2Text.String);
        orbit3Elem = str2double(handles.orbit3Text.String);
        orbit4Elem = str2double(handles.orbit4Text.String);
        orbit5Elem = str2double(handles.orbit5Text.String);
        orbit6Elem = str2double(handles.orbit6Text.String);
        
        curElemSet = getappdata(handles.lvd_EditTwoBodyPointGUI,'curElemSet');
        frame = curElemSet.frame;
        
        switch elemSetEnum
            case ElementSetEnum.CartesianElements
                orbitModel = CartesianElementSet(time, [orbit1Elem; orbit2Elem; orbit3Elem], [orbit4Elem; orbit5Elem; orbit6Elem], frame);
                
            case ElementSetEnum.KeplerianElements
                orbitModel = KeplerianElementSet(time, orbit1Elem, orbit2Elem, deg2rad(orbit3Elem), deg2rad(orbit4Elem), deg2rad(orbit5Elem), deg2rad(orbit6Elem), frame);
                
            case ElementSetEnum.GeographicElements
                orbitModel = GeographicElementSet(time, deg2rad(orbit1Elem), deg2rad(orbit2Elem), orbit3Elem, deg2rad(orbit4Elem), deg2rad(orbit5Elem), orbit6Elem, frame);
                
            case ElementSetEnum.UniversalElements
                orbitModel = UniversalElementSet(time, orbit1Elem, orbit2Elem, deg2rad(orbit3Elem), deg2rad(orbit4Elem), deg2rad(orbit5Elem), orbit6Elem, frame);
                
            otherwise
                error('Unknown element set type: %s', class(elemSetEnum));
        end
    

% --- Executes on selection change in elementSetCombo.
function elementSetCombo_Callback(hObject, eventdata, handles)
% hObject    handle to elementSetCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns elementSetCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from elementSetCombo
    contents = cellstr(get(hObject,'String'));
    sel = contents{get(hObject,'Value')};
    [~, elemSetEnum] = ElementSetEnum.getIndForName(sel);
    
    elemNames = elemSetEnum.elemNames;
    unitNames = elemSetEnum.unitNames;
    
    handles.orbit1Label.String = elemNames{1};
    handles.orbit2Label.String = elemNames{2};
    handles.orbit3Label.String = elemNames{3};
    handles.orbit4Label.String = elemNames{4};
    handles.orbit5Label.String = elemNames{5};
    handles.orbit6Label.String = elemNames{6};
    
    handles.orbit1UnitLabel.String = unitNames{1};
    handles.orbit2UnitLabel.String = unitNames{2};
    handles.orbit3UnitLabel.String = unitNames{3};
    handles.orbit4UnitLabel.String = unitNames{4};
    handles.orbit5UnitLabel.String = unitNames{5};
    handles.orbit6UnitLabel.String = unitNames{6};
    
    curElemSet = getappdata(handles.lvd_EditTwoBodyPointGUI,'curElemSet');
    
    try
        switch elemSetEnum
            case ElementSetEnum.CartesianElements
                newElemSet = curElemSet.convertToCartesianElementSet();

            case ElementSetEnum.KeplerianElements
                newElemSet = curElemSet.convertToKeplerianElementSet();

            case ElementSetEnum.GeographicElements
                newElemSet = curElemSet.convertToGeographicElementSet();
                
            case ElementSetEnum.UniversalElements
                newElemSet = curElemSet.convertToUniversalElementSet();

            otherwise
                error('Unknown element set type: %s', class(elemSetEnum));
        end
        
        elemVect = newElemSet.getElementVector();
        
        if(any(isnan(elemVect)) || any(not(isfinite(elemVect))))
            error('State conversion resulted in NaN or Inf');
        end        
        
        handles.orbit1Text.String = fullAccNum2Str(elemVect(1));
        handles.orbit2Text.String = fullAccNum2Str(elemVect(2));
        handles.orbit3Text.String = fullAccNum2Str(elemVect(3));
        handles.orbit4Text.String = fullAccNum2Str(elemVect(4));
        handles.orbit5Text.String = fullAccNum2Str(elemVect(5));
        handles.orbit6Text.String = fullAccNum2Str(elemVect(6));

        setappdata(handles.lvd_EditTwoBodyPointGUI,'curElemSet', newElemSet);
        
    catch ME
        updateValuesInState(handles);
        msgbox('Error converting state to new element set.','Conversion Error','error');
    end

% --- Executes during object creation, after setting all properties.
function elementSetCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to elementSetCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in refFrameTypeCombo.
function refFrameTypeCombo_Callback(hObject, eventdata, handles)
% hObject    handle to refFrameTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns refFrameTypeCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from refFrameTypeCombo
    updateStateDueToFrameChange(handles, AbstractReferenceFrame.empty(1,0));

% --- Executes during object creation, after setting all properties.
function refFrameTypeCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to refFrameTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in setFrameOptionsButton.
function setFrameOptionsButton_Callback(hObject, eventdata, handles)
% hObject    handle to setFrameOptionsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    curElemSet = getappdata(handles.lvd_EditTwoBodyPointGUI,'curElemSet');
    frame = curElemSet.frame;
    newFrame = frame.editFrameDialogUI(EditReferenceFrameContextEnum.ForState);
    
    updateStateDueToFrameChange(handles, newFrame);


% --------------------------------------------------------------------
function getOrbitFromSFSFileContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to getOrbitFromSFSFileContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
	contents = cellstr(get(handles.refFrameTypeCombo,'String'));
    selFrameType = contents{get(handles.refFrameTypeCombo,'Value')};
    enum = ReferenceFrameEnum.getEnumForListboxStr(selFrameType);
    if(not(enum == ReferenceFrameEnum.BodyCenteredInertial))
        enum = ReferenceFrameEnum.BodyCenteredInertial;
        ind = ReferenceFrameEnum.getIndForName(enum.name);
        handles.refFrameTypeCombo.Value = ind;
        refFrameTypeCombo_Callback(handles.refFrameTypeCombo, [], handles);
    end  

    contents = cellstr(get(handles.elementSetCombo,'String'));
    selOrbitType = contents{get(handles.elementSetCombo,'Value')};
    [~,enum] = ElementSetEnum.getIndForName(selOrbitType);
    if(not(enum == ElementSetEnum.KeplerianElements))
        enum = ElementSetEnum.KeplerianElements;
        ind = ElementSetEnum.getIndForName(enum.name);
        handles.elementSetCombo.Value = ind;
        elementSetCombo_Callback(handles.elementSetCombo, [], handles);
    end

    refBodyID = orbitPanelGetOrbitFromSFSContextCallBack(handles.ksptotMainGUI, handles.orbit1Text, handles.orbit2Text, handles.orbit3Text, handles.orbit4Text, handles.orbit5Text, handles.orbit6Text, handles.utText);
    tru = computeTrueAnomFromMean(deg2rad(str2double(get(handles.orbit6Text,'String'))), str2double(get(handles.orbit2Text,'String')));
    set(handles.orbit6Text,'String',fullAccNum2Str(rad2deg(tru)));

    if(~isempty(refBodyID) && isnumeric(refBodyID))
        lvdData = getappdata(handles.lvd_EditTwoBodyPointGUI,'lvdData');
        celBodyData = lvdData.celBodyData;
        bodyInfo = getBodyInfoByNumber(refBodyID, celBodyData);
        
        curElemSet = getCurrentElemSetFromExistingValues(handles);
        setappdata(handles.lvd_EditTwoBodyPointGUI,'curElemSet',curElemSet);
        
        curElemSet.frame.setOriginBody(bodyInfo);
        updateStateDueToFrameChange(handles, AbstractReferenceFrame.empty(1,0));
    end

% --------------------------------------------------------------------
function getOrbitFromKSPTOTConnectContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to getOrbitFromKSPTOTConnectContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
	contents = cellstr(get(handles.refFrameTypeCombo,'String'));
    selFrameType = contents{get(handles.refFrameTypeCombo,'Value')};
    enum = ReferenceFrameEnum.getEnumForListboxStr(selFrameType);
    if(not(enum == ReferenceFrameEnum.BodyCenteredInertial))
        enum = ReferenceFrameEnum.BodyCenteredInertial;
        ind = ReferenceFrameEnum.getIndForName(enum.name);
        handles.refFrameTypeCombo.Value = ind;
        refFrameTypeCombo_Callback(handles.refFrameTypeCombo, [], handles);
    end  

    contents = cellstr(get(handles.elementSetCombo,'String'));
    selOrbitType = contents{get(handles.elementSetCombo,'Value')};
    [~,enum] = ElementSetEnum.getIndForName(selOrbitType);
    if(not(enum == ElementSetEnum.KeplerianElements))
        enum = ElementSetEnum.KeplerianElements;
        ind = ElementSetEnum.getIndForName(enum.name);
        handles.elementSetCombo.Value = ind;
        elementSetCombo_Callback(handles.elementSetCombo, [], handles);
    end
    
    refBodyID = orbitPanelGetOrbitFromKSPTOTConnectCallBack(handles.orbit1Text, handles.orbit2Text, handles.orbit3Text, handles.orbit4Text, handles.orbit5Text, handles.orbit6Text, handles.utText);
    tru = computeTrueAnomFromMean(deg2rad(str2double(get(handles.orbit6Text,'String'))), str2double(get(handles.orbit2Text,'String')));
    set(handles.orbit6Text,'String',fullAccNum2Str(rad2deg(tru)));
    
    if(~isempty(refBodyID) && isnumeric(refBodyID))
        lvdData = getappdata(handles.lvd_EditTwoBodyPointGUI,'lvdData');
        celBodyData = lvdData.celBodyData;
        bodyInfo = getBodyInfoByNumber(refBodyID, celBodyData);
        
        curElemSet = getCurrentElemSetFromExistingValues(handles);
        setappdata(handles.lvd_EditTwoBodyPointGUI,'curElemSet',curElemSet);
        
        curElemSet.frame.setOriginBody(bodyInfo);
        updateStateDueToFrameChange(handles, AbstractReferenceFrame.empty(1,0));
    end

% --------------------------------------------------------------------
function getOrbitFromKSPActiveVesselMenu_Callback(hObject, eventdata, handles)
% hObject    handle to getOrbitFromKSPActiveVesselMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
	contents = cellstr(get(handles.refFrameTypeCombo,'String'));
    selFrameType = contents{get(handles.refFrameTypeCombo,'Value')};
    enum = ReferenceFrameEnum.getEnumForListboxStr(selFrameType);
    if(not(enum == ReferenceFrameEnum.BodyCenteredInertial))
        enum = ReferenceFrameEnum.BodyCenteredInertial;
        ind = ReferenceFrameEnum.getIndForName(enum.name);
        handles.refFrameTypeCombo.Value = ind;
        refFrameTypeCombo_Callback(handles.refFrameTypeCombo, [], handles);
    end  

    contents = cellstr(get(handles.elementSetCombo,'String'));
    selOrbitType = contents{get(handles.elementSetCombo,'Value')};
    [~,enum] = ElementSetEnum.getIndForName(selOrbitType);
    if(not(enum == ElementSetEnum.KeplerianElements))
        enum = ElementSetEnum.KeplerianElements;
        ind = ElementSetEnum.getIndForName(enum.name);
        handles.elementSetCombo.Value = ind;
        elementSetCombo_Callback(handles.elementSetCombo, [], handles);
    end

    refBodyID = orbitPanelGetOrbitFromKSPTOTConnectActiveVesselCallBack(handles.orbit1Text, handles.orbit2Text, handles.orbit3Text, handles.orbit4Text, handles.orbit5Text, handles.orbit6Text, handles.utText);
    tru = computeTrueAnomFromMean(deg2rad(str2double(get(handles.orbit6Text,'String'))), str2double(get(handles.orbit2Text,'String')));
    set(handles.orbit6Text,'String',fullAccNum2Str(rad2deg(tru)));
    
    if(~isempty(refBodyID) && isnumeric(refBodyID))
        lvdData = getappdata(handles.lvd_EditTwoBodyPointGUI,'lvdData');
        celBodyData = lvdData.celBodyData;
        bodyInfo = getBodyInfoByNumber(refBodyID, celBodyData);
        
        curElemSet = getCurrentElemSetFromExistingValues(handles);
        setappdata(handles.lvd_EditTwoBodyPointGUI,'curElemSet',curElemSet);
        
        curElemSet.frame.setOriginBody(bodyInfo);
        updateStateDueToFrameChange(handles, AbstractReferenceFrame.empty(1,0));
    end

% --------------------------------------------------------------------
function copyOrbitToClipboardMenu_Callback(hObject, eventdata, handles)
% hObject    handle to copyOrbitToClipboardMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    bodyInfo = getSelectedBodyInfo(handles);

    o1V = handles.orbit1Text.String;
    o2V = handles.orbit2Text.String;
    o3V = handles.orbit3Text.String;
    o4V = handles.orbit4Text.String;
    o5V = handles.orbit5Text.String;
    o6V = handles.orbit6Text.String;
       
	contents = cellstr(get(handles.refFrameTypeCombo,'String'));
    selFrameType = contents{get(handles.refFrameTypeCombo,'Value')};
    enum = ReferenceFrameEnum.getEnumForListboxStr(selFrameType);
    framEnumOrig = enum;
    if(not(enum == ReferenceFrameEnum.BodyCenteredInertial))
        enum = ReferenceFrameEnum.BodyCenteredInertial;
        ind = ReferenceFrameEnum.getIndForName(enum.name);
        handles.refFrameTypeCombo.Value = ind;
        refFrameTypeCombo_Callback(handles.refFrameTypeCombo, [], handles);
    end  

    contents = cellstr(get(handles.elementSetCombo,'String'));
    selOrbitType = contents{get(handles.elementSetCombo,'Value')};
    [~,enum] = ElementSetEnum.getIndForName(selOrbitType);
    elemSetEnumOrig = enum;
    if(not(enum == ElementSetEnum.KeplerianElements))
        enum = ElementSetEnum.KeplerianElements;
        ind = ElementSetEnum.getIndForName(enum.name);
        handles.elementSetCombo.Value = ind;
        elementSetCombo_Callback(handles.elementSetCombo, [], handles);
    end 

    copyOrbitToClipboardFromText(handles.utText, handles.orbit1Text, handles.orbit2Text, ...
                                 handles.orbit3Text, handles.orbit4Text, handles.orbit5Text, ...
                                 handles.orbit6Text, true, bodyInfo.id);
                                
    ind = ElementSetEnum.getIndForName(elemSetEnumOrig.name);
    handles.elementSetCombo.Value = ind;
    elementSetCombo_Callback(handles.elementSetCombo, [], handles);
    
    ind = ReferenceFrameEnum.getIndForName(framEnumOrig.name);
    handles.refFrameTypeCombo.Value = ind;
    refFrameTypeCombo_Callback(handles.refFrameTypeCombo, [], handles);
    
    handles.orbit1Text.String = o1V;
    handles.orbit2Text.String = o2V;
    handles.orbit3Text.String = o3V;
    handles.orbit4Text.String = o4V;
    handles.orbit5Text.String = o5V;
    handles.orbit6Text.String = o6V;

% --------------------------------------------------------------------
function pasteOrbitFromClipboardMenu_Callback(hObject, eventdata, handles)
% hObject    handle to pasteOrbitFromClipboardMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
	contents = cellstr(get(handles.refFrameTypeCombo,'String'));
    selFrameType = contents{get(handles.refFrameTypeCombo,'Value')};
    enum = ReferenceFrameEnum.getEnumForListboxStr(selFrameType);
    if(not(enum == ReferenceFrameEnum.BodyCenteredInertial))
        enum = ReferenceFrameEnum.BodyCenteredInertial;
        ind = ReferenceFrameEnum.getIndForName(enum.name);
        handles.refFrameTypeCombo.Value = ind;
        refFrameTypeCombo_Callback(handles.refFrameTypeCombo, [], handles);
    end  

    contents = cellstr(get(handles.elementSetCombo,'String'));
    selOrbitType = contents{get(handles.elementSetCombo,'Value')};
    [~,enum] = ElementSetEnum.getIndForName(selOrbitType);
    if(not(enum == ElementSetEnum.KeplerianElements))
        enum = ElementSetEnum.KeplerianElements;
        ind = ElementSetEnum.getIndForName(enum.name);
        handles.elementSetCombo.Value = ind;
        elementSetCombo_Callback(handles.elementSetCombo, [], handles);
    end

	lvdData = getappdata(handles.lvd_EditTwoBodyPointGUI,'lvdData');
    celBodyData = lvdData.celBodyData;

    bodyInfo = pasteOrbitFromClipboard(handles.utText, handles.orbit1Text, handles.orbit2Text, ...
                                       handles.orbit3Text, handles.orbit4Text, handles.orbit5Text, ...
                                       handles.orbit6Text, true, [], celBodyData);
          
	if(not(isempty(bodyInfo)))
        curElemSet = getappdata(handles.lvd_EditTwoBodyPointGUI,'curElemSet');
        curElemSet.frame.setOriginBody(bodyInfo);
        updateStateDueToFrameChange(handles, AbstractReferenceFrame.empty(1,0));
	end

% --------------------------------------------------------------------
function enterUTAsDateTimeContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to enterUTAsDateTimeContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    secUT = enterUTAsDateTimeGUI(str2double(get(gco, 'String')));
    if(secUT >= 0)
        set(gco, 'String', fullAccNum2Str(secUT));
        utText_Callback(handles.utText, eventdata, handles);
    end

% --------------------------------------------------------------------
function epochContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to epochContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function orbitPanelContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to orbitPanelContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in dispTrajCheckbox.
function dispTrajCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to dispTrajCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of dispTrajCheckbox
