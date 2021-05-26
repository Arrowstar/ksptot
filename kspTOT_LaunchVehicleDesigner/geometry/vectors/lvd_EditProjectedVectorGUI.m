function varargout = lvd_EditProjectedVectorGUI(varargin)
% LVD_EDITPROJECTEDVECTORGUI MATLAB code for lvd_EditProjectedVectorGUI.fig
%      LVD_EDITPROJECTEDVECTORGUI, by itself, creates a new LVD_EDITPROJECTEDVECTORGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITPROJECTEDVECTORGUI returns the handle to a new LVD_EDITPROJECTEDVECTORGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITPROJECTEDVECTORGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITPROJECTEDVECTORGUI.M with the given input arguments.
%
%      LVD_EDITPROJECTEDVECTORGUI('Property','Value',...) creates a new LVD_EDITPROJECTEDVECTORGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditProjectedVectorGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditProjectedVectorGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditProjectedVectorGUI

% Last Modified by GUIDE v2.5 20-Jan-2021 19:53:41

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditProjectedVectorGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditProjectedVectorGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditProjectedVectorGUI is made visible.
function lvd_EditProjectedVectorGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditProjectedVectorGUI (see VARARGIN)

    % Choose default command line output for lvd_EditProjectedVectorGUI
    handles.output = hObject;

    vector = varargin{1};
    setappdata(hObject, 'vector', vector);
    
    lvdData = varargin{2};
    setappdata(hObject, 'lvdData', lvdData);
    
	populateGUI(handles, lvdData, vector);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditProjectedVectorGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditProjectedVectorGUI);

function populateGUI(handles, lvdData, vector)
    set(handles.vectorNameText,'String',vector.getName());
    
    [vectorsListBoxStr, vectors] = lvdData.geometry.vectors.getListboxStr();
    inds = [];
    for(i=1:length(vectorsListBoxStr))
        if(vectors(i) == vector)
            inds(end+1) = i; %#ok<AGROW>
        end
    end
    vectorsListBoxStr(inds) = [];
    vectors(inds) = [];
    
    setappdata(handles.lvd_EditProjectedVectorGUI, 'allVectors',vectors);
    
    handles.projectedVectorCombo.String = vectorsListBoxStr;
    handles.projectedVectorCombo.Value = find(ismember(vectors, vector.projVect),1,'first');
    
    handles.normalVectorCombo.String = vectorsListBoxStr;
    handles.normalVectorCombo.Value = find(ismember(vectors, vector.normVect),1,'first');
    
    handles.vectorLineColorCombo.String = ColorSpecEnum.getListboxStr();
    handles.vectorLineColorCombo.Value = ColorSpecEnum.getIndForName(vector.lineColor.name);

    handles.vectorLineSpecCombo.String = LineSpecEnum.getListboxStr();
    handles.vectorLineSpecCombo.Value = LineSpecEnum.getIndForName(vector.lineSpec.name);


% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditProjectedVectorGUI_OutputFcn(hObject, eventdata, handles) 
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
        
        allVectors = getappdata(hObject, 'allVectors');
        vector.projVect = allVectors(handles.projectedVectorCombo.Value);
        vector.normVect = allVectors(handles.normalVectorCombo.Value);
        
        str = handles.vectorLineColorCombo.String{handles.vectorLineColorCombo.Value};
        vector.lineColor = ColorSpecEnum.getEnumForListboxStr(str);
        
        str = handles.vectorLineSpecCombo.String{handles.vectorLineSpecCombo.Value};
        vector.lineSpec = LineSpecEnum.getEnumForListboxStr(str);
        
        varargout{1} = true;
        close(handles.lvd_EditProjectedVectorGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_EditProjectedVectorGUI);
    else
        msgbox(errMsg,'Invalid Vector Inputs','error');
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    
%     lvdData = setappdata(handles.lvd_EditProjectedVectorGUI, 'lvdData');
%     vector = getappdata(handles.lvd_EditProjectedVectorGUI, 'vector');
    
    allVectors = getappdata(handles.lvd_EditProjectedVectorGUI, 'allVectors');
    vector1 = allVectors(handles.projectedVectorCombo.Value);
    vector2 = allVectors(handles.normalVectorCombo.Value);
    
    if(vector1 == vector2)
        errMsg{end+1} = 'The projected vector and the normal vector must be different.';
    end
    
%     tf = vector.isInUse(lvdData);
    
    if(isempty(strtrim(handles.vectorNameText.String)))
        errMsg{end+1} = 'Vector name must contain more than white space and must not be empty.';
    end

    
% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditProjectedVectorGUI);


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



% --- Executes on key press with focus on lvd_EditProjectedVectorGUI or any of its controls.
function lvd_EditProjectedVectorGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditProjectedVectorGUI (see GCBO)
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
            close(handles.lvd_EditProjectedVectorGUI);
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


% --- Executes on selection change in projectedVectorCombo.
function projectedVectorCombo_Callback(hObject, eventdata, handles)
% hObject    handle to projectedVectorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns projectedVectorCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from projectedVectorCombo


% --- Executes during object creation, after setting all properties.
function projectedVectorCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to projectedVectorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in normalVectorCombo.
function normalVectorCombo_Callback(hObject, eventdata, handles)
% hObject    handle to normalVectorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns normalVectorCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from normalVectorCombo


% --- Executes during object creation, after setting all properties.
function normalVectorCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to normalVectorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
