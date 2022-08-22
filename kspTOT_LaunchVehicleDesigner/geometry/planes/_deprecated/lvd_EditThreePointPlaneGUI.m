function varargout = lvd_EditThreePointPlaneGUI(varargin)
% LVD_EDITTHREEPOINTPLANEGUI MATLAB code for lvd_EditThreePointPlaneGUI.fig
%      LVD_EDITTHREEPOINTPLANEGUI, by itself, creates a new LVD_EDITTHREEPOINTPLANEGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITTHREEPOINTPLANEGUI returns the handle to a new LVD_EDITTHREEPOINTPLANEGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITTHREEPOINTPLANEGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITTHREEPOINTPLANEGUI.M with the given input arguments.
%
%      LVD_EDITTHREEPOINTPLANEGUI('Property','Value',...) creates a new LVD_EDITTHREEPOINTPLANEGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditThreePointPlaneGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditThreePointPlaneGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditThreePointPlaneGUI

% Last Modified by GUIDE v2.5 17-Feb-2021 18:26:17

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditThreePointPlaneGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditThreePointPlaneGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditThreePointPlaneGUI is made visible.
function lvd_EditThreePointPlaneGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditThreePointPlaneGUI (see VARARGIN)

    % Choose default command line output for lvd_EditThreePointPlaneGUI
    handles.output = hObject;
    
    centerUIFigure(hObject);

    plane = varargin{1};
    setappdata(hObject, 'plane', plane);
    
    lvdData = varargin{2};
    setappdata(hObject, 'lvdData', lvdData);
    
	populateGUI(handles, lvdData, plane);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditThreePointPlaneGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditThreePointPlaneGUI);

function populateGUI(handles, lvdData, plane)
    set(handles.nameText,'String',plane.getName());
    
    pointsListBoxStr = lvdData.geometry.points.getListboxStr();
    
    handles.point1Combo.String = pointsListBoxStr;
    handles.point1Combo.Value = lvdData.geometry.points.getIndsForPoints(plane.point1);
    
    handles.point2Combo.String = pointsListBoxStr;
    handles.point2Combo.Value = lvdData.geometry.points.getIndsForPoints(plane.point2);
    
    handles.point3Combo.String = pointsListBoxStr;
    handles.point3Combo.Value = lvdData.geometry.points.getIndsForPoints(plane.point3);
    
    handles.lineColorCombo.String = ColorSpecEnum.getListboxStr();
    handles.lineColorCombo.Value = ColorSpecEnum.getIndForName(plane.lineColor.name);

    handles.lineSpecCombo.String = LineSpecEnum.getListboxStr();
    handles.lineSpecCombo.Value = LineSpecEnum.getIndForName(plane.lineSpec.name);

    handles.edgeLengthText.String = fullAccNum2Str(plane.edgeLength);
    handles.alphaText.String = fullAccNum2Str(plane.alpha*100);

% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditThreePointPlaneGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        lvdData = getappdata(hObject, 'lvdData');
        plane = getappdata(hObject, 'plane');
        
        plane.setName(handles.nameText.String);
        
        plane.point1 = lvdData.geometry.points.getPointAtInd(handles.point1Combo.Value);
        plane.point2 = lvdData.geometry.points.getPointAtInd(handles.point2Combo.Value);
        plane.point3 = lvdData.geometry.points.getPointAtInd(handles.point3Combo.Value);
        
        str = handles.lineColorCombo.String{handles.lineColorCombo.Value};
        plane.lineColor = ColorSpecEnum.getEnumForListboxStr(str);
        
        str = handles.lineSpecCombo.String{handles.lineSpecCombo.Value};
        plane.lineSpec = LineSpecEnum.getEnumForListboxStr(str);
        
        plane.edgeLength = str2double(handles.edgeLengthText.String);
        plane.alpha = str2double(handles.alphaText.String)/100;
        
        varargout{1} = true;
        close(handles.lvd_EditThreePointPlaneGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_EditThreePointPlaneGUI);
    else
        msgbox(errMsg,'Invalid Plane Inputs','error');
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    
    if(handles.point1Combo.Value == handles.point2Combo.Value || ...
       handles.point1Combo.Value == handles.point3Combo.Value || ...
       handles.point2Combo.Value == handles.point3Combo.Value)
        errMsg{end+1} = 'All three points on the plane must be unique.';
    end

    edgeLength = str2double(get(handles.edgeLengthText,'String'));
    enteredStr = get(handles.edgeLengthText,'String');
    numberName = 'Edge Length';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(edgeLength, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    alpha = str2double(get(handles.alphaText,'String'));
    enteredStr = get(handles.alphaText,'String');
    numberName = 'Face Transparency';
    lb = 0;
    ub = 100;
    isInt = false;
    errMsg = validateNumber(alpha, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(strtrim(handles.nameText.String)))
        errMsg{end+1} = 'Plane name must contain more than white space and must not be empty.';
    end

    
% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditThreePointPlaneGUI);


function nameText_Callback(hObject, eventdata, handles)
% hObject    handle to nameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nameText as text
%        str2double(get(hObject,'String')) returns contents of nameText as a double


% --- Executes during object creation, after setting all properties.
function nameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nameText see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on key press with focus on lvd_EditThreePointPlaneGUI or any of its controls.
function lvd_EditThreePointPlaneGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditThreePointPlaneGUI (see GCBO)
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
            close(handles.lvd_EditThreePointPlaneGUI);
    end


% --- Executes on selection change in lineSpecCombo.
function lineSpecCombo_Callback(hObject, eventdata, handles)
% hObject    handle to lineSpecCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lineSpecCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lineSpecCombo


% --- Executes during object creation, after setting all properties.
function lineSpecCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lineSpecCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in lineColorCombo.
function lineColorCombo_Callback(hObject, eventdata, handles)
% hObject    handle to lineColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lineColorCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lineColorCombo


% --- Executes during object creation, after setting all properties.
function lineColorCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lineColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in point1Combo.
function point1Combo_Callback(hObject, eventdata, handles)
% hObject    handle to point1Combo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns point1Combo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from point1Combo


% --- Executes during object creation, after setting all properties.
function point1Combo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to point1Combo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in point2Combo.
function point2Combo_Callback(hObject, eventdata, handles)
% hObject    handle to point2Combo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns point2Combo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from point2Combo


% --- Executes during object creation, after setting all properties.
function point2Combo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to point2Combo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function alphaText_Callback(hObject, eventdata, handles)
% hObject    handle to alphaText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of alphaText as text
%        str2double(get(hObject,'String')) returns contents of alphaText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function alphaText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to alphaText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edgeLengthText_Callback(hObject, eventdata, handles)
% hObject    handle to edgeLengthText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edgeLengthText as text
%        str2double(get(hObject,'String')) returns contents of edgeLengthText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function edgeLengthText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edgeLengthText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in point3Combo.
function point3Combo_Callback(hObject, eventdata, handles)
% hObject    handle to point3Combo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns point3Combo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from point3Combo


% --- Executes during object creation, after setting all properties.
function point3Combo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to point3Combo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
