function varargout = lvd_EditCoordSysOriginRefFrameGUI(varargin)
% LVD_EDITCOORDSYSORIGINREFFRAMEGUI MATLAB code for lvd_EditCoordSysOriginRefFrameGUI.fig
%      LVD_EDITCOORDSYSORIGINREFFRAMEGUI, by itself, creates a new LVD_EDITCOORDSYSORIGINREFFRAMEGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITCOORDSYSORIGINREFFRAMEGUI returns the handle to a new LVD_EDITCOORDSYSORIGINREFFRAMEGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITCOORDSYSORIGINREFFRAMEGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITCOORDSYSORIGINREFFRAMEGUI.M with the given input arguments.
%
%      LVD_EDITCOORDSYSORIGINREFFRAMEGUI('Property','Value',...) creates a new LVD_EDITCOORDSYSORIGINREFFRAMEGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditCoordSysOriginRefFrameGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditCoordSysOriginRefFrameGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditCoordSysOriginRefFrameGUI

% Last Modified by GUIDE v2.5 12-Jan-2021 18:10:17

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditCoordSysOriginRefFrameGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditCoordSysOriginRefFrameGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditCoordSysOriginRefFrameGUI is made visible.
function lvd_EditCoordSysOriginRefFrameGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditCoordSysOriginRefFrameGUI (see VARARGIN)

    % Choose default command line output for lvd_EditCoordSysOriginRefFrameGUI
    handles.output = hObject;

    refFrame = varargin{1};
    setappdata(hObject, 'refFrame', refFrame);
    
    lvdData = varargin{2};
    setappdata(hObject, 'lvdData', lvdData);
    
	populateGUI(handles, lvdData, refFrame);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditCoordSysOriginRefFrameGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditCoordSysOriginRefFrameGUI);

function populateGUI(handles, lvdData, refFrame)
    set(handles.refFrameNameText,'String',refFrame.getName());
    
    pointsListBoxStr = lvdData.geometry.points.getListboxStr();
    handles.frameOriginCombo.String = pointsListBoxStr;
    handles.frameOriginCombo.Value = lvdData.geometry.points.getIndsForPoints(refFrame.origin);
    
    coordSysListBoxStr = lvdData.geometry.coordSyses.getListboxStr();
    handles.coordSysCombo.String = coordSysListBoxStr;
    handles.coordSysCombo.Value = lvdData.geometry.coordSyses.getIndsForCoordSyses(refFrame.coordSys);
    
    handles.xColorCombo.String = ColorSpecEnum.getListboxStr();
    handles.xColorCombo.Value = ColorSpecEnum.getIndForName(refFrame.xAxisColor.name);

    handles.yColorCombo.String = ColorSpecEnum.getListboxStr();
    handles.yColorCombo.Value = ColorSpecEnum.getIndForName(refFrame.yAxisColor.name);
    
    handles.zColorCombo.String = ColorSpecEnum.getListboxStr();
    handles.zColorCombo.Value = ColorSpecEnum.getIndForName(refFrame.zAxisColor.name);
    
    handles.xLineStyleCombo.String = LineSpecEnum.getListboxStr();
    handles.xLineStyleCombo.Value = LineSpecEnum.getIndForName(refFrame.xAxisLineSpec.name);
    
    handles.yLineStyleCombo.String = LineSpecEnum.getListboxStr();
    handles.yLineStyleCombo.Value = LineSpecEnum.getIndForName(refFrame.yAxisLineSpec.name);
    
    handles.zLineStyleCombo.String = LineSpecEnum.getListboxStr();
    handles.zLineStyleCombo.Value = LineSpecEnum.getIndForName(refFrame.zAxisLineSpec.name);
    
    handles.xLineWidthText.String = fullAccNum2Str(refFrame.xAxisLineWidth);
    handles.yLineWidthText.String = fullAccNum2Str(refFrame.yAxisLineWidth);
    handles.zLineWidthText.String = fullAccNum2Str(refFrame.zAxisLineWidth);
    
    handles.scaleFactorText.String = fullAccNum2Str(refFrame.scaleFactor);

% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditCoordSysOriginRefFrameGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        lvdData = getappdata(hObject, 'lvdData');
        refFrame = getappdata(hObject, 'refFrame');
        
        refFrame.setName(handles.refFrameNameText.String);
        
        refFrame.origin = lvdData.geometry.points.getPointsForInds(handles.frameOriginCombo.Value);
        refFrame.coordSys = lvdData.geometry.coordSyses.getCoordSysesForInds(handles.coordSysCombo.Value);
        
        str = handles.xColorCombo.String{handles.xColorCombo.Value};
        refFrame.xAxisColor = ColorSpecEnum.getEnumForListboxStr(str);
        
        str = handles.xColorCombo.String{handles.yColorCombo.Value};
        refFrame.yAxisColor = ColorSpecEnum.getEnumForListboxStr(str);
        
        str = handles.xColorCombo.String{handles.zColorCombo.Value};
        refFrame.zAxisColor = ColorSpecEnum.getEnumForListboxStr(str);
        
        str = handles.xLineStyleCombo.String{handles.xLineStyleCombo.Value};
        refFrame.xAxisLineSpec = LineSpecEnum.getEnumForListboxStr(str);
        
        str = handles.xLineStyleCombo.String{handles.yLineStyleCombo.Value};
        refFrame.yAxisLineSpec = LineSpecEnum.getEnumForListboxStr(str);
        
        str = handles.xLineStyleCombo.String{handles.zLineStyleCombo.Value};
        refFrame.zAxisLineSpec = LineSpecEnum.getEnumForListboxStr(str);
        
        refFrame.xAxisLineWidth = str2double(handles.xLineWidthText.String);
        refFrame.yAxisLineWidth = str2double(handles.yLineWidthText.String);
        refFrame.zAxisLineWidth = str2double(handles.zLineWidthText.String);
        
        refFrame.scaleFactor = str2double(handles.scaleFactorText.String);
        
        varargout{1} = true;
        close(handles.lvd_EditCoordSysOriginRefFrameGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_EditCoordSysOriginRefFrameGUI);
    else
        msgbox(errMsg,'Invalid Reference Frame Inputs','error');
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    
    if(isempty(strtrim(handles.refFrameNameText.String)))
        errMsg{end+1} = 'Reference frame name must contain more than white space and must not be empty.';
    end
    
    val = str2double(get(handles.xLineWidthText,'String'));
    enteredStr = get(handles.xLineWidthText,'String');
    numberName = 'X Axis Line Width';
    lb = 0.01;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(val, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    val = str2double(get(handles.yLineWidthText,'String'));
    enteredStr = get(handles.yLineWidthText,'String');
    numberName = 'Y Axis Line Width';
    lb = 0.01;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(val, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    val = str2double(get(handles.zLineWidthText,'String'));
    enteredStr = get(handles.zLineWidthText,'String');
    numberName = 'Z Axis Line Width';
    lb = 0.01;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(val, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    val = str2double(get(handles.scaleFactorText,'String'));
    enteredStr = get(handles.scaleFactorText,'String');
    numberName = 'Axes Scale Factor';
    lb = 0.001;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(val, numberName, lb, ub, isInt, errMsg, enteredStr);

    
% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditCoordSysOriginRefFrameGUI);


function refFrameNameText_Callback(hObject, eventdata, handles)
% hObject    handle to refFrameNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of refFrameNameText as text
%        str2double(get(hObject,'String')) returns contents of refFrameNameText as a double


% --- Executes during object creation, after setting all properties.
function refFrameNameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to refFrameNameText see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on key press with focus on lvd_EditCoordSysOriginRefFrameGUI or any of its controls.
function lvd_EditCoordSysOriginRefFrameGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditCoordSysOriginRefFrameGUI (see GCBO)
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
            close(handles.lvd_EditCoordSysOriginRefFrameGUI);
    end

% --- Executes on selection change in frameOriginCombo.
function frameOriginCombo_Callback(hObject, eventdata, handles)
% hObject    handle to frameOriginCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns frameOriginCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from frameOriginCombo


% --- Executes during object creation, after setting all properties.
function frameOriginCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to frameOriginCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in coordSysCombo.
function coordSysCombo_Callback(hObject, eventdata, handles)
% hObject    handle to coordSysCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns coordSysCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from coordSysCombo


% --- Executes during object creation, after setting all properties.
function coordSysCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to coordSysCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in xColorCombo.
function xColorCombo_Callback(hObject, eventdata, handles)
% hObject    handle to xColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns xColorCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from xColorCombo


% --- Executes during object creation, after setting all properties.
function xColorCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in xLineStyleCombo.
function xLineStyleCombo_Callback(hObject, eventdata, handles)
% hObject    handle to xLineStyleCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns xLineStyleCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from xLineStyleCombo


% --- Executes during object creation, after setting all properties.
function xLineStyleCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xLineStyleCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function xLineWidthText_Callback(hObject, eventdata, handles)
% hObject    handle to xLineWidthText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of xLineWidthText as text
%        str2double(get(hObject,'String')) returns contents of xLineWidthText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function xLineWidthText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xLineWidthText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in yColorCombo.
function yColorCombo_Callback(hObject, eventdata, handles)
% hObject    handle to yColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns yColorCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from yColorCombo


% --- Executes during object creation, after setting all properties.
function yColorCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to yColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in yLineStyleCombo.
function yLineStyleCombo_Callback(hObject, eventdata, handles)
% hObject    handle to yLineStyleCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns yLineStyleCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from yLineStyleCombo


% --- Executes during object creation, after setting all properties.
function yLineStyleCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to yLineStyleCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function yLineWidthText_Callback(hObject, eventdata, handles)
% hObject    handle to yLineWidthText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of yLineWidthText as text
%        str2double(get(hObject,'String')) returns contents of yLineWidthText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function yLineWidthText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to yLineWidthText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in zColorCombo.
function zColorCombo_Callback(hObject, eventdata, handles)
% hObject    handle to zColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns zColorCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from zColorCombo


% --- Executes during object creation, after setting all properties.
function zColorCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to zColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in zLineStyleCombo.
function zLineStyleCombo_Callback(hObject, eventdata, handles)
% hObject    handle to zLineStyleCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns zLineStyleCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from zLineStyleCombo


% --- Executes during object creation, after setting all properties.
function zLineStyleCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to zLineStyleCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function zLineWidthText_Callback(hObject, eventdata, handles)
% hObject    handle to zLineWidthText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of zLineWidthText as text
%        str2double(get(hObject,'String')) returns contents of zLineWidthText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function zLineWidthText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to zLineWidthText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
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
