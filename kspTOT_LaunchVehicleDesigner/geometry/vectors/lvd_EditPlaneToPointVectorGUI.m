function varargout = lvd_EditPlaneToPointVectorGUI(varargin)
% LVD_EDITPLANETOPOINTVECTORGUI MATLAB code for lvd_EditPlaneToPointVectorGUI.fig
%      LVD_EDITPLANETOPOINTVECTORGUI, by itself, creates a new LVD_EDITPLANETOPOINTVECTORGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITPLANETOPOINTVECTORGUI returns the handle to a new LVD_EDITPLANETOPOINTVECTORGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITPLANETOPOINTVECTORGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITPLANETOPOINTVECTORGUI.M with the given input arguments.
%
%      LVD_EDITPLANETOPOINTVECTORGUI('Property','Value',...) creates a new LVD_EDITPLANETOPOINTVECTORGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditPlaneToPointVectorGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditPlaneToPointVectorGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditPlaneToPointVectorGUI

% Last Modified by GUIDE v2.5 22-Feb-2021 18:55:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditPlaneToPointVectorGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditPlaneToPointVectorGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditPlaneToPointVectorGUI is made visible.
function lvd_EditPlaneToPointVectorGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditPlaneToPointVectorGUI (see VARARGIN)

    % Choose default command line output for lvd_EditPlaneToPointVectorGUI
    handles.output = hObject;

    vector = varargin{1};
    setappdata(hObject, 'vector', vector);
    
    lvdData = varargin{2};
    setappdata(hObject, 'lvdData', lvdData);
    
	populateGUI(handles, lvdData, vector);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditPlaneToPointVectorGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditPlaneToPointVectorGUI);

function populateGUI(handles, lvdData, vector)
    set(handles.vectorNameText,'String',vector.getName());
    
    pointsListBoxStr = lvdData.geometry.points.getListboxStr();
    planesListBoxStr = lvdData.geometry.planes.getListboxStr();
    
    handles.originPlaneCombo.String = planesListBoxStr;
    handles.originPlaneCombo.Value = lvdData.geometry.planes.getIndsForPlanes(vector.plane);
    
    handles.terminusPointCombo.String = pointsListBoxStr;
    handles.terminusPointCombo.Value = lvdData.geometry.points.getIndsForPoints(vector.point);
    
    handles.vectorLineColorCombo.String = ColorSpecEnum.getListboxStr();
    handles.vectorLineColorCombo.Value = ColorSpecEnum.getIndForName(vector.lineColor.name);

    handles.vectorLineSpecCombo.String = LineSpecEnum.getListboxStr();
    handles.vectorLineSpecCombo.Value = LineSpecEnum.getIndForName(vector.lineSpec.name);


% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditPlaneToPointVectorGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        lvdData = getappdata(hObject, 'lvdData');
        vector = getappdata(hObject, 'vector');
        
        vector.setName(handles.vectorNameText.String);
        
        vector.plane = lvdData.geometry.planes.getPlanesForInds(handles.originPlaneCombo.Value);
        vector.point = lvdData.geometry.points.getPointsForInds(handles.terminusPointCombo.Value);
        
        str = handles.vectorLineColorCombo.String{handles.vectorLineColorCombo.Value};
        vector.lineColor = ColorSpecEnum.getEnumForListboxStr(str);
        
        str = handles.vectorLineSpecCombo.String{handles.vectorLineSpecCombo.Value};
        vector.lineSpec = LineSpecEnum.getEnumForListboxStr(str);
        
        varargout{1} = true;
        close(handles.lvd_EditPlaneToPointVectorGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_EditPlaneToPointVectorGUI);
    else
        msgbox(errMsg,'Invalid Vector Inputs','error');
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    
    if(isempty(strtrim(handles.vectorNameText.String)))
        errMsg{end+1} = 'Vector name must contain more than white space and must not be empty.';
    end

    
% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditPlaneToPointVectorGUI);


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



% --- Executes on key press with focus on lvd_EditPlaneToPointVectorGUI or any of its controls.
function lvd_EditPlaneToPointVectorGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditPlaneToPointVectorGUI (see GCBO)
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
            close(handles.lvd_EditPlaneToPointVectorGUI);
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


% --- Executes on selection change in originPlaneCombo.
function originPlaneCombo_Callback(hObject, eventdata, handles)
% hObject    handle to originPlaneCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns originPlaneCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from originPlaneCombo


% --- Executes during object creation, after setting all properties.
function originPlaneCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to originPlaneCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in terminusPointCombo.
function terminusPointCombo_Callback(hObject, eventdata, handles)
% hObject    handle to terminusPointCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns terminusPointCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from terminusPointCombo


% --- Executes during object creation, after setting all properties.
function terminusPointCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to terminusPointCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
