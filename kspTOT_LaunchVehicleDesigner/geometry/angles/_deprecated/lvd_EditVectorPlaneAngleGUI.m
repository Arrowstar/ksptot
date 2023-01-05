function varargout = lvd_EditVectorPlaneAngleGUI(varargin)
% LVD_EDITVECTORPLANEANGLEGUI MATLAB code for lvd_EditVectorPlaneAngleGUI.fig
%      LVD_EDITVECTORPLANEANGLEGUI, by itself, creates a new LVD_EDITVECTORPLANEANGLEGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITVECTORPLANEANGLEGUI returns the handle to a new LVD_EDITVECTORPLANEANGLEGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITVECTORPLANEANGLEGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITVECTORPLANEANGLEGUI.M with the given input arguments.
%
%      LVD_EDITVECTORPLANEANGLEGUI('Property','Value',...) creates a new LVD_EDITVECTORPLANEANGLEGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditVectorPlaneAngleGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditVectorPlaneAngleGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditVectorPlaneAngleGUI

% Last Modified by GUIDE v2.5 23-Feb-2021 08:38:27

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditVectorPlaneAngleGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditVectorPlaneAngleGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditVectorPlaneAngleGUI is made visible.
function lvd_EditVectorPlaneAngleGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditVectorPlaneAngleGUI (see VARARGIN)

    % Choose default command line output for lvd_EditVectorPlaneAngleGUI
    handles.output = hObject;
    
    centerUIFigure(hObject);

    angle = varargin{1};
    setappdata(hObject, 'angle', angle);
    
    lvdData = varargin{2};
    setappdata(hObject, 'lvdData', lvdData);
    
	populateGUI(handles, lvdData, angle);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditVectorPlaneAngleGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditVectorPlaneAngleGUI);

function populateGUI(handles, lvdData, angle)
    set(handles.nameText,'String',angle.getName());
    
    [vectorsListBoxStr, ~] = lvdData.geometry.vectors.getListboxStr();
    [planesListBoxStr, ~] = lvdData.geometry.planes.getListboxStr();
    
    handles.vectorCombo.String = vectorsListBoxStr;
    handles.vectorCombo.Value = lvdData.geometry.vectors.getIndsForVectors(angle.vector);
    
    handles.planeCombo.String = planesListBoxStr;
    handles.planeCombo.Value = lvdData.geometry.planes.getIndsForPlanes(angle.plane);
    
    handles.lineColorCombo.String = ColorSpecEnum.getListboxStr();
    handles.lineColorCombo.Value = ColorSpecEnum.getIndForName(angle.lineColor.name);

    handles.lineSpecCombo.String = LineSpecEnum.getListboxStr();
    handles.lineSpecCombo.Value = LineSpecEnum.getIndForName(angle.lineSpec.name);


% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditVectorPlaneAngleGUI_OutputFcn(hObject, eventdata, handles) 
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
        
        angle.vector = lvdData.geometry.vectors.getVectorAtInd(handles.vectorCombo.Value);
        angle.plane = lvdData.geometry.planes.getPlaneAtInd(handles.planeCombo.Value);
        
        str = handles.lineColorCombo.String{handles.lineColorCombo.Value};
        angle.lineColor = ColorSpecEnum.getEnumForListboxStr(str);
        
        str = handles.lineSpecCombo.String{handles.lineSpecCombo.Value};
        angle.lineSpec = LineSpecEnum.getEnumForListboxStr(str);
        
        varargout{1} = true;
        close(handles.lvd_EditVectorPlaneAngleGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_EditVectorPlaneAngleGUI);
    else
        msgbox(errMsg,'Invalid Angle Inputs','error');
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    
    if(isempty(strtrim(handles.nameText.String)))
        errMsg{end+1} = 'Angle name must contain more than white space and must not be empty.';
    end

    
% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditVectorPlaneAngleGUI);


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



% --- Executes on key press with focus on lvd_EditVectorPlaneAngleGUI or any of its controls.
function lvd_EditVectorPlaneAngleGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditVectorPlaneAngleGUI (see GCBO)
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
            close(handles.lvd_EditVectorPlaneAngleGUI);
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


% --- Executes on selection change in planeCombo.
function planeCombo_Callback(hObject, eventdata, handles)
% hObject    handle to planeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns planeCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from planeCombo


% --- Executes during object creation, after setting all properties.
function planeCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to planeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
