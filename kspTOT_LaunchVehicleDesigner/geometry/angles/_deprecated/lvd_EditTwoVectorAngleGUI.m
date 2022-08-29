function varargout = lvd_EditTwoVectorAngleGUI(varargin)
% LVD_EDITTWOVECTORANGLEGUI MATLAB code for lvd_EditTwoVectorAngleGUI.fig
%      LVD_EDITTWOVECTORANGLEGUI, by itself, creates a new LVD_EDITTWOVECTORANGLEGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITTWOVECTORANGLEGUI returns the handle to a new LVD_EDITTWOVECTORANGLEGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITTWOVECTORANGLEGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITTWOVECTORANGLEGUI.M with the given input arguments.
%
%      LVD_EDITTWOVECTORANGLEGUI('Property','Value',...) creates a new LVD_EDITTWOVECTORANGLEGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditTwoVectorAngleGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditTwoVectorAngleGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditTwoVectorAngleGUI

% Last Modified by GUIDE v2.5 17-Feb-2021 16:14:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditTwoVectorAngleGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditTwoVectorAngleGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditTwoVectorAngleGUI is made visible.
function lvd_EditTwoVectorAngleGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditTwoVectorAngleGUI (see VARARGIN)

    % Choose default command line output for lvd_EditTwoVectorAngleGUI
    handles.output = hObject;
    
    centerUIFigure(hObject);

    angle = varargin{1};
    setappdata(hObject, 'angle', angle);
    
    lvdData = varargin{2};
    setappdata(hObject, 'lvdData', lvdData);
    
	populateGUI(handles, lvdData, angle);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditTwoVectorAngleGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditTwoVectorAngleGUI);

function populateGUI(handles, lvdData, angle)
    set(handles.nameText,'String',angle.getName());
    
    [vectorsListBoxStr, ~] = lvdData.geometry.vectors.getListboxStr();
    
    handles.vector1Combo.String = vectorsListBoxStr;
    handles.vector1Combo.Value = lvdData.geometry.vectors.getIndsForVectors(angle.vector1);
    
    handles.vector2Combo.String = vectorsListBoxStr;
    handles.vector2Combo.Value = lvdData.geometry.vectors.getIndsForVectors(angle.vector2);
    
    handles.lineColorCombo.String = ColorSpecEnum.getListboxStr();
    handles.lineColorCombo.Value = ColorSpecEnum.getIndForName(angle.lineColor.name);

    handles.lineSpecCombo.String = LineSpecEnum.getListboxStr();
    handles.lineSpecCombo.Value = LineSpecEnum.getIndForName(angle.lineSpec.name);


% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditTwoVectorAngleGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        lvdData = getappdata(hObject, 'lvdData');
        angle = getappdata(hObject, 'angle');
        
        angle.setName(handles.nameText.String);
        
        angle.vector1 = lvdData.geometry.vectors.getVectorAtInd(handles.vector1Combo.Value);
        angle.vector2 = lvdData.geometry.vectors.getVectorAtInd(handles.vector2Combo.Value);
        
        str = handles.lineColorCombo.String{handles.lineColorCombo.Value};
        angle.lineColor = ColorSpecEnum.getEnumForListboxStr(str);
        
        str = handles.lineSpecCombo.String{handles.lineSpecCombo.Value};
        angle.lineSpec = LineSpecEnum.getEnumForListboxStr(str);
        
        varargout{1} = true;
        close(handles.lvd_EditTwoVectorAngleGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_EditTwoVectorAngleGUI);
    else
        msgbox(errMsg,'Invalid Angle Inputs','error');
    end


function errMsg = validateInputs(handles)
    errMsg = {};
%     lvdData = getappdata(handles.lvd_EditTwoVectorAngleGUI, 'lvdData');
    
%     vector1 = lvdData.geometry.vectors.getVectorAtInd(handles.vector1Combo.Value);
%     vector2 = lvdData.geometry.vectors.getVectorAtInd(handles.vector2Combo.Value);
%     
%     if(vector1 == vector2)
%         errMsg{end+1} = 'Vector 1 and Vector 2 must be different.';
%     end
    
    if(isempty(strtrim(handles.nameText.String)))
        errMsg{end+1} = 'Angle name must contain more than white space and must not be empty.';
    end

    
% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditTwoVectorAngleGUI);


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



% --- Executes on key press with focus on lvd_EditTwoVectorAngleGUI or any of its controls.
function lvd_EditTwoVectorAngleGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditTwoVectorAngleGUI (see GCBO)
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
            close(handles.lvd_EditTwoVectorAngleGUI);
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


% --- Executes on selection change in vector1Combo.
function vector1Combo_Callback(hObject, eventdata, handles)
% hObject    handle to vector1Combo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns vector1Combo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from vector1Combo


% --- Executes during object creation, after setting all properties.
function vector1Combo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vector1Combo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in vector2Combo.
function vector2Combo_Callback(hObject, eventdata, handles)
% hObject    handle to vector2Combo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns vector2Combo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from vector2Combo


% --- Executes during object creation, after setting all properties.
function vector2Combo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vector2Combo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
