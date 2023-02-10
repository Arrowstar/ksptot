function varargout = lvd_EditPointVectorPlaneGUI(varargin)
% LVD_EDITPOINTVECTORPLANEGUI MATLAB code for lvd_EditPointVectorPlaneGUI.fig
%      LVD_EDITPOINTVECTORPLANEGUI, by itself, creates a new LVD_EDITPOINTVECTORPLANEGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITPOINTVECTORPLANEGUI returns the handle to a new LVD_EDITPOINTVECTORPLANEGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITPOINTVECTORPLANEGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITPOINTVECTORPLANEGUI.M with the given input arguments.
%
%      LVD_EDITPOINTVECTORPLANEGUI('Property','Value',...) creates a new LVD_EDITPOINTVECTORPLANEGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditPointVectorPlaneGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditPointVectorPlaneGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditPointVectorPlaneGUI

% Last Modified by GUIDE v2.5 17-Feb-2021 17:59:42

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditPointVectorPlaneGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditPointVectorPlaneGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditPointVectorPlaneGUI is made visible.
function lvd_EditPointVectorPlaneGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditPointVectorPlaneGUI (see VARARGIN)

    % Choose default command line output for lvd_EditPointVectorPlaneGUI
    handles.output = hObject;
    
    centerUIFigure(hObject);

    plane = varargin{1};
    setappdata(hObject, 'plane', plane);
    
    lvdData = varargin{2};
    setappdata(hObject, 'lvdData', lvdData);
    
	populateGUI(handles, lvdData, plane);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditPointVectorPlaneGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditPointVectorPlaneGUI);

function populateGUI(handles, lvdData, plane)
    set(handles.nameText,'String',plane.getName());
    
    pointsListBoxStr = lvdData.geometry.points.getListboxStr();
    vectorsListBoxStr = lvdData.geometry.vectors.getListboxStr();
    
    handles.pointCombo.String = pointsListBoxStr;
    handles.pointCombo.Value = lvdData.geometry.points.getIndsForPoints(plane.point);
    
    handles.vectorCombo.String = vectorsListBoxStr;
    handles.vectorCombo.Value = lvdData.geometry.vectors.getIndsForVectors(plane.vector);
    
    handles.lineColorCombo.String = ColorSpecEnum.getListboxStr();
    handles.lineColorCombo.Value = ColorSpecEnum.getIndForName(plane.lineColor.name);

    handles.lineSpecCombo.String = LineSpecEnum.getListboxStr();
    handles.lineSpecCombo.Value = LineSpecEnum.getIndForName(plane.lineSpec.name);

    handles.edgeLengthText.String = fullAccNum2Str(plane.edgeLength);
    handles.alphaText.String = fullAccNum2Str(plane.alpha*100);

% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditPointVectorPlaneGUI_OutputFcn(hObject, eventdata, handles) 
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
        
        plane.point = lvdData.geometry.points.getPointAtInd(handles.pointCombo.Value);
        plane.vector = lvdData.geometry.vectors.getVectorAtInd(handles.vectorCombo.Value);
        
        str = handles.lineColorCombo.String{handles.lineColorCombo.Value};
        plane.lineColor = ColorSpecEnum.getEnumForListboxStr(str);
        
        str = handles.lineSpecCombo.String{handles.lineSpecCombo.Value};
        plane.lineSpec = LineSpecEnum.getEnumForListboxStr(str);
        
        plane.edgeLength = str2double(handles.edgeLengthText.String);
        plane.alpha = str2double(handles.alphaText.String)/100;
        
        varargout{1} = true;
        close(handles.lvd_EditPointVectorPlaneGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_EditPointVectorPlaneGUI);
    else
        msgbox(errMsg,'Invalid Plane Inputs','error');
    end


function errMsg = validateInputs(handles)
    errMsg = {};

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
    close(handles.lvd_EditPointVectorPlaneGUI);


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



% --- Executes on key press with focus on lvd_EditPointVectorPlaneGUI or any of its controls.
function lvd_EditPointVectorPlaneGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditPointVectorPlaneGUI (see GCBO)
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
            close(handles.lvd_EditPointVectorPlaneGUI);
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


% --- Executes on selection change in pointCombo.
function pointCombo_Callback(hObject, eventdata, handles)
% hObject    handle to pointCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pointCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pointCombo


% --- Executes during object creation, after setting all properties.
function pointCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pointCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in vectorCombo.
function vectorCombo_Callback(hObject, eventdata, handles)
% hObject    handle to vectorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns vectorCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from vectorCombo


% --- Executes during object creation, after setting all properties.
function vectorCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vectorCombo (see GCBO)
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
