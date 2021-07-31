function varargout = lvd_EditFixedInFramePointGUI(varargin)
% LVD_EDITFIXEDINFRAMEPOINTGUI MATLAB code for lvd_EditFixedInFramePointGUI.fig
%      LVD_EDITFIXEDINFRAMEPOINTGUI, by itself, creates a new LVD_EDITFIXEDINFRAMEPOINTGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITFIXEDINFRAMEPOINTGUI returns the handle to a new LVD_EDITFIXEDINFRAMEPOINTGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITFIXEDINFRAMEPOINTGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITFIXEDINFRAMEPOINTGUI.M with the given input arguments.
%
%      LVD_EDITFIXEDINFRAMEPOINTGUI('Property','Value',...) creates a new LVD_EDITFIXEDINFRAMEPOINTGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditFixedInFramePointGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditFixedInFramePointGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditFixedInFramePointGUI

% Last Modified by GUIDE v2.5 17-Jan-2021 11:18:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditFixedInFramePointGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditFixedInFramePointGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditFixedInFramePointGUI is made visible.
function lvd_EditFixedInFramePointGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditFixedInFramePointGUI (see VARARGIN)

    % Choose default command line output for lvd_EditFixedInFramePointGUI
    handles.output = hObject;

    centerUIFigure(hObject);
    
    point = varargin{1};
    setappdata(hObject, 'point', point);
    
    lvdData = varargin{2};
    setappdata(hObject, 'lvdData', lvdData);
    
	populateGUI(handles, point);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditFixedInFramePointGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditFixedInFramePointGUI);

function populateGUI(handles, point)
    set(handles.pointNameText,'String',point.getName());
    setappdata(handles.lvd_EditFixedInFramePointGUI,'curElemSet',point.cartElem);
    
    frame = point.getFrame();
    handles.refFrameTypeCombo.String = ReferenceFrameEnum.getListBoxStr();
    handles.refFrameTypeCombo.Value = ReferenceFrameEnum.getIndForName(frame.typeEnum.name);
    handles.setFrameOptionsButton.TooltipString = sprintf('Current Frame: %s', frame.getNameStr()); 
    
    rVect = point.getRVect();
    set(handles.xCoordText,'String',fullAccNum2Str(rVect(1)));
    set(handles.yCoordText,'String',fullAccNum2Str(rVect(2)));
    set(handles.zCoordText,'String',fullAccNum2Str(rVect(3)));
    
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
function varargout = lvd_EditFixedInFramePointGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        point = getappdata(hObject, 'point');
        
        point.setName(handles.pointNameText.String);
        
        x = str2double(get(handles.xCoordText,'String'));
        y = str2double(get(handles.yCoordText,'String'));
        z = str2double(get(handles.zCoordText,'String'));
        point.setRVect([x;y;z]);
        
        str = handles.pointColorCombo.String{handles.pointColorCombo.Value};
        point.markerColor = ColorSpecEnum.getEnumForListboxStr(str);
        
        str = handles.pointMarkerShapeCombo.String{handles.pointMarkerShapeCombo.Value};
        point.markerShape = MarkerStyleEnum.getEnumForListboxStr(str);
        
        str = handles.pointLineColorCombo.String{handles.pointLineColorCombo.Value};
        point.trkLineColor = ColorSpecEnum.getEnumForListboxStr(str);
        
        str = handles.pointLineSpecCombo.String{handles.pointLineSpecCombo.Value};
        point.trkLineSpec = LineSpecEnum.getEnumForListboxStr(str);
        
        point.plotTrkLine = logical(handles.dispTrajCheckbox.Value);
        
        varargout{1} = true;
        close(handles.lvd_EditFixedInFramePointGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_EditFixedInFramePointGUI);
    else
        msgbox(errMsg,'Invalid Point Inputs','error');
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    
    val = str2double(get(handles.xCoordText,'String'));
    enteredStr = get(handles.xCoordText,'String');
    numberName = 'X Coordinate';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(val, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    val = str2double(get(handles.yCoordText,'String'));
    enteredStr = get(handles.yCoordText,'String');
    numberName = 'Y Coordinate';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(val, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    val = str2double(get(handles.zCoordText,'String'));
    enteredStr = get(handles.zCoordText,'String');
    numberName = 'Z Coordinate';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(val, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(strtrim(handles.pointNameText.String)))
        errMsg{end+1} = {'Point name must contain more than white space and must not be empty.'};
    end
    
% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditFixedInFramePointGUI);


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



function xCoordText_Callback(hObject, eventdata, handles)
% hObject    handle to xCoordText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of xCoordText as text
%        str2double(get(hObject,'String')) returns contents of xCoordText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function xCoordText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xCoordText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on lvd_EditFixedInFramePointGUI or any of its controls.
function lvd_EditFixedInFramePointGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditFixedInFramePointGUI (see GCBO)
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
            close(handles.lvd_EditFixedInFramePointGUI);
    end



function yCoordText_Callback(hObject, eventdata, handles)
% hObject    handle to yCoordText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of yCoordText as text
%        str2double(get(hObject,'String')) returns contents of yCoordText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);


% --- Executes during object creation, after setting all properties.
function yCoordText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to yCoordText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function zCoordText_Callback(hObject, eventdata, handles)
% hObject    handle to zCoordText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of zCoordText as text
%        str2double(get(hObject,'String')) returns contents of zCoordText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);


% --- Executes during object creation, after setting all properties.
function zCoordText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to zCoordText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
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


% --- Executes on selection change in refFrameTypeCombo.
function refFrameTypeCombo_Callback(hObject, eventdata, handles)
% hObject    handle to refFrameTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns refFrameTypeCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from refFrameTypeCombo
    frameUpdated(handles);

    
function frameUpdated(handles)
    lvdData = getappdata(handles.lvd_EditFixedInFramePointGUI, 'lvdData');
    
    curElemSet = getappdata(handles.lvd_EditFixedInFramePointGUI,'curElemSet');
    bodyInfo = curElemSet.frame.getOriginBody();   
    
    contents = cellstr(get(handles.refFrameTypeCombo,'String'));
    selFrameType = contents{get(handles.refFrameTypeCombo,'Value')};
    refFrameEnum = ReferenceFrameEnum.getEnumForListboxStr(selFrameType);
    
    switch refFrameEnum
        case ReferenceFrameEnum.BodyCenteredInertial
            newFrame = bodyInfo.getBodyCenteredInertialFrame();

        case ReferenceFrameEnum.BodyFixedRotating
            newFrame = bodyInfo.getBodyFixedFrame();
            
        case ReferenceFrameEnum.TwoBodyRotating       
            if(curElemSet.frame.typeEnum == ReferenceFrameEnum.TwoBodyRotating)
                newFrame = curElemSet.frame;
            else
                if(not(isempty(bodyInfo.childrenBodyInfo)))
                    primaryBody = bodyInfo;
                    secondaryBody = bodyInfo.childrenBodyInfo(1);
                else
                    primaryBody = bodyInfo.getParBodyInfo();
                    secondaryBody = bodyInfo;
                end
                
                originPt = TwoBodyRotatingFrameOriginEnum.Primary;
                
                newFrame = TwoBodyRotatingFrame(primaryBody, secondaryBody, originPt, bodyInfo.celBodyData);
            end
            
        case ReferenceFrameEnum.UserDefined
            numFrames = lvdData.geometry.refFrames.getNumRefFrames();
            if(numFrames >= 1)
                geometricFrame = lvdData.geometry.refFrames.getRefFrameAtInd(1);
                newFrame = UserDefinedGeometricFrame(geometricFrame, lvdData);
            else
                newFrame = bodyInfo.getBodyCenteredInertialFrame();
                warndlg('There are no geometric frames available.  A body-centered inertial frame will be selected instead.');
            end
            
        otherwise
            error('Unknown reference frame type: %s', string(refFrameEnum));                
    end
    
    if(not(isempty(newFrame)) && newFrame.typeEnum ~= refFrameEnum)
        refFrameEnum = newFrame.typeEnum;
        handles.refFrameTypeCombo.Value = ReferenceFrameEnum.getIndForName(refFrameEnum.name);
    end
    
    curElemSet.frame = newFrame;
    handles.setFrameOptionsButton.TooltipString = sprintf('Current Frame: %s', newFrame.getNameStr()); 
    

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
    curElemSet = getappdata(handles.lvd_EditFixedInFramePointGUI,'curElemSet');

    frame = curElemSet.frame;
    newFrame = frame.editFrameDialogUI(EditReferenceFrameContextEnum.ForGeometry);
    curElemSet.frame = newFrame;
    
    setappdata(handles.lvd_EditFixedInFramePointGUI,'curElemSet',curElemSet);
    
    frameUpdated(handles);


% --- Executes on button press in dispTrajCheckbox.
function dispTrajCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to dispTrajCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of dispTrajCheckbox
