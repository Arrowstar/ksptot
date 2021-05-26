function varargout = lvd_EditAlignedConstrainedCoordSysGUI(varargin)
% LVD_EDITALIGNEDCONSTRAINEDCOORDSYSGUI MATLAB code for lvd_EditAlignedConstrainedCoordSysGUI.fig
%      LVD_EDITALIGNEDCONSTRAINEDCOORDSYSGUI, by itself, creates a new LVD_EDITALIGNEDCONSTRAINEDCOORDSYSGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITALIGNEDCONSTRAINEDCOORDSYSGUI returns the handle to a new LVD_EDITALIGNEDCONSTRAINEDCOORDSYSGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITALIGNEDCONSTRAINEDCOORDSYSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITALIGNEDCONSTRAINEDCOORDSYSGUI.M with the given input arguments.
%
%      LVD_EDITALIGNEDCONSTRAINEDCOORDSYSGUI('Property','Value',...) creates a new LVD_EDITALIGNEDCONSTRAINEDCOORDSYSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditAlignedConstrainedCoordSysGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditAlignedConstrainedCoordSysGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditAlignedConstrainedCoordSysGUI

% Last Modified by GUIDE v2.5 11-Jan-2021 15:22:06

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditAlignedConstrainedCoordSysGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditAlignedConstrainedCoordSysGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditAlignedConstrainedCoordSysGUI is made visible.
function lvd_EditAlignedConstrainedCoordSysGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditAlignedConstrainedCoordSysGUI (see VARARGIN)

    % Choose default command line output for lvd_EditAlignedConstrainedCoordSysGUI
    handles.output = hObject;

    coordsys = varargin{1};
    setappdata(hObject, 'coordsys', coordsys);
    
    lvdData = varargin{2};
    setappdata(hObject, 'lvdData', lvdData);
    
	populateGUI(handles, lvdData, coordsys);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditAlignedConstrainedCoordSysGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditAlignedConstrainedCoordSysGUI);

function populateGUI(handles, lvdData, coordsys)
    set(handles.coordSysNameText,'String',coordsys.getName());
    
    vectorsListBoxStr = lvdData.geometry.vectors.getListboxStr();
    
    handles.aVectorCombo.String = vectorsListBoxStr;
    handles.aVectorCombo.Value = lvdData.geometry.vectors.getIndsForVectors(coordsys.aVector);
    
    handles.cVectorCombo.String = vectorsListBoxStr;
    handles.cVectorCombo.Value = lvdData.geometry.vectors.getIndsForVectors(coordsys.cVector);
    
    axesListBoxStr = AlignedConstrainedCoordSysAxesEnum.getListBoxStr();
    
    handles.alignedVectAxisCombo.String = axesListBoxStr;
    handles.alignedVectAxisCombo.Value = AlignedConstrainedCoordSysAxesEnum.getIndForName(coordsys.aVectorAxis.name);
    
    handles.constrainedVectAxisCombo.String = axesListBoxStr;
    handles.constrainedVectAxisCombo.Value = AlignedConstrainedCoordSysAxesEnum.getIndForName(coordsys.cVectorAxis.name);


% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditAlignedConstrainedCoordSysGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        lvdData = getappdata(hObject, 'lvdData');
        coordsys = getappdata(hObject, 'coordsys');
        
        coordsys.setName(handles.coordSysNameText.String);

        coordsys.aVector = lvdData.geometry.vectors.getVectorAtInd(handles.aVectorCombo.Value);
        coordsys.cVector = lvdData.geometry.vectors.getVectorAtInd(handles.cVectorCombo.Value);
        
        str = handles.alignedVectAxisCombo.String{handles.alignedVectAxisCombo.Value};
        coordsys.aVectorAxis = AlignedConstrainedCoordSysAxesEnum.getEnumForListboxStr(str);
        
        str = handles.constrainedVectAxisCombo.String{handles.constrainedVectAxisCombo.Value};
        coordsys.cVectorAxis = AlignedConstrainedCoordSysAxesEnum.getEnumForListboxStr(str);
        
        varargout{1} = true;
        close(handles.lvd_EditAlignedConstrainedCoordSysGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_EditAlignedConstrainedCoordSysGUI);
    else
        msgbox(errMsg,'Invalid Vector Inputs','error');
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    lvdData = getappdata(handles.lvd_EditAlignedConstrainedCoordSysGUI, 'lvdData');    
    
    aVector = lvdData.geometry.vectors.getVectorAtInd(handles.aVectorCombo.Value);
    cVector = lvdData.geometry.vectors.getVectorAtInd(handles.cVectorCombo.Value);
    if(aVector == cVector)
        errMsg{end+1} = 'The aligned vector and constrained vector must be different.';
    end
    
    str = handles.alignedVectAxisCombo.String{handles.alignedVectAxisCombo.Value};
    aVectorAxis = AlignedConstrainedCoordSysAxesEnum.getEnumForListboxStr(str);

    str = handles.constrainedVectAxisCombo.String{handles.constrainedVectAxisCombo.Value};
    cVectorAxis = AlignedConstrainedCoordSysAxesEnum.getEnumForListboxStr(str);
    if(aVectorAxis == cVectorAxis || ...
       strcmpi(aVectorAxis.baseAxis, cVectorAxis.baseAxis))
        errMsg{end+1} = 'The aligned vector axis and constrained vector axis must be different and not opposite.';
    end
    
    if(isempty(strtrim(handles.coordSysNameText.String)))
        errMsg{end+1} = 'Coordinate system name must contain more than white space and must not be empty.';
    end

    
% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditAlignedConstrainedCoordSysGUI);


function coordSysNameText_Callback(hObject, eventdata, handles)
% hObject    handle to coordSysNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of coordSysNameText as text
%        str2double(get(hObject,'String')) returns contents of coordSysNameText as a double


% --- Executes during object creation, after setting all properties.
function coordSysNameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to coordSysNameText see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on key press with focus on lvd_EditAlignedConstrainedCoordSysGUI or any of its controls.
function lvd_EditAlignedConstrainedCoordSysGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditAlignedConstrainedCoordSysGUI (see GCBO)
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
            close(handles.lvd_EditAlignedConstrainedCoordSysGUI);
    end


% --- Executes on selection change in aVectorCombo.
function aVectorCombo_Callback(hObject, eventdata, handles)
% hObject    handle to aVectorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns aVectorCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from aVectorCombo


% --- Executes during object creation, after setting all properties.
function aVectorCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to aVectorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in cVectorCombo.
function cVectorCombo_Callback(hObject, eventdata, handles)
% hObject    handle to cVectorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns cVectorCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from cVectorCombo


% --- Executes during object creation, after setting all properties.
function cVectorCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cVectorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in alignedVectAxisCombo.
function alignedVectAxisCombo_Callback(hObject, eventdata, handles)
% hObject    handle to alignedVectAxisCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns alignedVectAxisCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from alignedVectAxisCombo


% --- Executes during object creation, after setting all properties.
function alignedVectAxisCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to alignedVectAxisCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in constrainedVectAxisCombo.
function constrainedVectAxisCombo_Callback(hObject, eventdata, handles)
% hObject    handle to constrainedVectAxisCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns constrainedVectAxisCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from constrainedVectAxisCombo


% --- Executes during object creation, after setting all properties.
function constrainedVectAxisCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to constrainedVectAxisCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
