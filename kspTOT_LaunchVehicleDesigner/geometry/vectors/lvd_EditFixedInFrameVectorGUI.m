function varargout = lvd_EditFixedInFrameVectorGUI(varargin)
% LVD_EDITFIXEDINFRAMEVECTORGUI MATLAB code for lvd_EditFixedInFrameVectorGUI.fig
%      LVD_EDITFIXEDINFRAMEVECTORGUI, by itself, creates a new LVD_EDITFIXEDINFRAMEVECTORGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITFIXEDINFRAMEVECTORGUI returns the handle to a new LVD_EDITFIXEDINFRAMEVECTORGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITFIXEDINFRAMEVECTORGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITFIXEDINFRAMEVECTORGUI.M with the given input arguments.
%
%      LVD_EDITFIXEDINFRAMEVECTORGUI('Property','Value',...) creates a new LVD_EDITFIXEDINFRAMEVECTORGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditFixedInFrameVectorGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditFixedInFrameVectorGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditFixedInFrameVectorGUI

% Last Modified by GUIDE v2.5 11-Jan-2021 08:46:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditFixedInFrameVectorGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditFixedInFrameVectorGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditFixedInFrameVectorGUI is made visible.
function lvd_EditFixedInFrameVectorGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditFixedInFrameVectorGUI (see VARARGIN)

    % Choose default command line output for lvd_EditFixedInFrameVectorGUI
    handles.output = hObject;

    vector = varargin{1};
    setappdata(hObject, 'vector', vector);
    
	populateGUI(handles, vector);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditFixedInFrameVectorGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditFixedInFramePointGUI);

function populateGUI(handles, vector)
    set(handles.vectorNameText,'String',vector.getName());
    setappdata(handles.lvd_EditFixedInFramePointGUI,'curElemSet',vector.cartElem);
    
    frame = vector.getFrame();
    handles.refFrameTypeCombo.String = ReferenceFrameEnum.getListBoxStr();
    handles.refFrameTypeCombo.Value = ReferenceFrameEnum.getIndForName(frame.typeEnum.name);
    handles.setFrameOptionsButton.TooltipString = sprintf('Current Frame: %s', frame.getNameStr()); 
    
    rVect = vector.getRVect();
    set(handles.xCoordText,'String',fullAccNum2Str(rVect(1)));
    set(handles.yCoordText,'String',fullAccNum2Str(rVect(2)));
    set(handles.zCoordText,'String',fullAccNum2Str(rVect(3)));

    handles.vectorLineColorCombo.String = ColorSpecEnum.getListboxStr();
    handles.vectorLineColorCombo.Value = ColorSpecEnum.getIndForName(vector.lineColor.name);

    handles.vectorLineSpecCombo.String = LineSpecEnum.getListboxStr();
    handles.vectorLineSpecCombo.Value = LineSpecEnum.getIndForName(vector.lineSpec.name);


% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditFixedInFrameVectorGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        vector = getappdata(hObject, 'vector');
        
        vector.setName(handles.vectorNameText.String);
        
        x = str2double(get(handles.xCoordText,'String'));
        y = str2double(get(handles.yCoordText,'String'));
        z = str2double(get(handles.zCoordText,'String'));
        vector.setRVect([x;y;z]);
                
        str = handles.vectorLineColorCombo.String{handles.vectorLineColorCombo.Value};
        vector.lineColor = ColorSpecEnum.getEnumForListboxStr(str);
        
        str = handles.vectorLineSpecCombo.String{handles.vectorLineSpecCombo.Value};
        vector.lineSpec = LineSpecEnum.getEnumForListboxStr(str);
        
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
    
    xval = str2double(get(handles.xCoordText,'String'));
    enteredStr = get(handles.xCoordText,'String');
    numberName = 'X Coordinate';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(xval, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    yval = str2double(get(handles.yCoordText,'String'));
    enteredStr = get(handles.yCoordText,'String');
    numberName = 'Y Coordinate';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(yval, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    zval = str2double(get(handles.zCoordText,'String'));
    enteredStr = get(handles.zCoordText,'String');
    numberName = 'Z Coordinate';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(zval, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(normVector([xval, yval, zval]) == 0)
        errMsg{end+1} = 'The magnitude of the vector must be greater than 0.';
    end
    
    if(isempty(strtrim(handles.vectorNameText.String)))
        errMsg{end+1} = 'Vector name must contain more than white space and must not be empty.';
    end
    
% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditFixedInFramePointGUI);


function vectorNameText_Callback(hObject, eventdata, handles)
% hObject    handle to vectorNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of vectorNameText as text
%        str2double(get(hObject,'String')) returns contents of vectorNameText as a double


% --- Executes during object creation, after setting all properties.
function vectorNameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vectorNameText see GCBO)
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


% --- Executes on key press with focus on lvd_EditFixedInFrameVectorGUI or any of its controls.
function lvd_EditFixedInFramePointGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditFixedInFrameVectorGUI (see GCBO)
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


% --- Executes on selection change in vectorLineSpecCombo.
function vectorLineSpecCombo_Callback(hObject, eventdata, handles)
% hObject    handle to vectorLineSpecCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns vectorLineSpecCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from vectorLineSpecCombo


% --- Executes during object creation, after setting all properties.
function vectorLineSpecCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vectorLineSpecCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in vectorLineColorCombo.
function vectorLineColorCombo_Callback(hObject, eventdata, handles)
% hObject    handle to vectorLineColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns vectorLineColorCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from vectorLineColorCombo


% --- Executes during object creation, after setting all properties.
function vectorLineColorCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vectorLineColorCombo (see GCBO)
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
        otherwise
            error('Unknown reference frame type: %s', class(refFrameEnum));                
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
    newFrame = frame.editFrameDialogUI();
    curElemSet.frame = newFrame;
    
    setappdata(handles.lvd_EditFixedInFramePointGUI,'curElemSet',curElemSet);
    
    frameUpdated(handles);
