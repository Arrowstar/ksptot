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

% Last Modified by GUIDE v2.5 11-Jan-2021 18:33:05

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
