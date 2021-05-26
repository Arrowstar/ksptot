function varargout = lvd_EditTwoPointVectorGUI(varargin)
% LVD_EDITTWOPOINTVECTORGUI MATLAB code for lvd_EditTwoPointVectorGUI.fig
%      LVD_EDITTWOPOINTVECTORGUI, by itself, creates a new LVD_EDITTWOPOINTVECTORGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITTWOPOINTVECTORGUI returns the handle to a new LVD_EDITTWOPOINTVECTORGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITTWOPOINTVECTORGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITTWOPOINTVECTORGUI.M with the given input arguments.
%
%      LVD_EDITTWOPOINTVECTORGUI('Property','Value',...) creates a new LVD_EDITTWOPOINTVECTORGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditTwoPointVectorGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditTwoPointVectorGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditTwoPointVectorGUI

% Last Modified by GUIDE v2.5 10-Jan-2021 21:04:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditTwoPointVectorGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditTwoPointVectorGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditTwoPointVectorGUI is made visible.
function lvd_EditTwoPointVectorGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditTwoPointVectorGUI (see VARARGIN)

    % Choose default command line output for lvd_EditTwoPointVectorGUI
    handles.output = hObject;

    vector = varargin{1};
    setappdata(hObject, 'vector', vector);
    
    lvdData = varargin{2};
    setappdata(hObject, 'lvdData', lvdData);
    
	populateGUI(handles, lvdData, vector);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditTwoPointVectorGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditTwoPointVectorGUI);

function populateGUI(handles, lvdData, vector)
    set(handles.vectorNameText,'String',vector.getName());
    
    pointsListBoxStr = lvdData.geometry.points.getListboxStr();
    
    handles.vectorOriginCombo.String = pointsListBoxStr;
    handles.vectorOriginCombo.Value = lvdData.geometry.points.getIndsForPoints(vector.point1);
    
    handles.vectorTerminusCombo.String = pointsListBoxStr;
    handles.vectorTerminusCombo.Value = lvdData.geometry.points.getIndsForPoints(vector.point2);
    
    handles.vectorLineColorCombo.String = ColorSpecEnum.getListboxStr();
    handles.vectorLineColorCombo.Value = ColorSpecEnum.getIndForName(vector.lineColor.name);

    handles.vectorLineSpecCombo.String = LineSpecEnum.getListboxStr();
    handles.vectorLineSpecCombo.Value = LineSpecEnum.getIndForName(vector.lineSpec.name);


% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditTwoPointVectorGUI_OutputFcn(hObject, eventdata, handles) 
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
        
        vector.point1 = lvdData.geometry.points.getPointsForInds(handles.vectorOriginCombo.Value);
        vector.point2 = lvdData.geometry.points.getPointsForInds(handles.vectorTerminusCombo.Value);
        
        str = handles.vectorLineColorCombo.String{handles.vectorLineColorCombo.Value};
        vector.lineColor = ColorSpecEnum.getEnumForListboxStr(str);
        
        str = handles.vectorLineSpecCombo.String{handles.vectorLineSpecCombo.Value};
        vector.lineSpec = LineSpecEnum.getEnumForListboxStr(str);
        
        varargout{1} = true;
        close(handles.lvd_EditTwoPointVectorGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_EditTwoPointVectorGUI);
    else
        msgbox(errMsg,'Invalid Vector Inputs','error');
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    
    if(handles.vectorOriginCombo.Value == handles.vectorTerminusCombo.Value)
        errMsg{end+1} = 'The origin and terminus points must be different.';
    end
    
    if(isempty(strtrim(handles.vectorNameText.String)))
        errMsg{end+1} = 'Vector name must contain more than white space and must not be empty.';
    end

    
% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditTwoPointVectorGUI);


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



% --- Executes on key press with focus on lvd_EditTwoPointVectorGUI or any of its controls.
function lvd_EditTwoPointVectorGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditTwoPointVectorGUI (see GCBO)
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
            close(handles.lvd_EditTwoPointVectorGUI);
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


% --- Executes on selection change in vectorOriginCombo.
function vectorOriginCombo_Callback(hObject, eventdata, handles)
% hObject    handle to vectorOriginCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns vectorOriginCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from vectorOriginCombo


% --- Executes during object creation, after setting all properties.
function vectorOriginCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vectorOriginCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in vectorTerminusCombo.
function vectorTerminusCombo_Callback(hObject, eventdata, handles)
% hObject    handle to vectorTerminusCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns vectorTerminusCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from vectorTerminusCombo


% --- Executes during object creation, after setting all properties.
function vectorTerminusCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vectorTerminusCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
