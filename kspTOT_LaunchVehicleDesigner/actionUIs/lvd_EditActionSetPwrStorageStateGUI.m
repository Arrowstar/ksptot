function varargout = lvd_EditActionSetPwrStorageStateGUI(varargin)
% LVD_EDITACTIONSETPWRSTORAGESTATEGUI MATLAB code for lvd_EditActionSetPwrStorageStateGUI.fig
%      LVD_EDITACTIONSETPWRSTORAGESTATEGUI, by itself, creates a new LVD_EDITACTIONSETPWRSTORAGESTATEGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITACTIONSETPWRSTORAGESTATEGUI returns the handle to a new LVD_EDITACTIONSETPWRSTORAGESTATEGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITACTIONSETPWRSTORAGESTATEGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITACTIONSETPWRSTORAGESTATEGUI.M with the given input arguments.
%
%      LVD_EDITACTIONSETPWRSTORAGESTATEGUI('Property','Value',...) creates a new LVD_EDITACTIONSETPWRSTORAGESTATEGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditActionSetPwrStorageStateGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditActionSetPwrStorageStateGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditActionSetPwrStorageStateGUI

% Last Modified by GUIDE v2.5 06-Aug-2020 15:29:58

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditActionSetPwrStorageStateGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditActionSetPwrStorageStateGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditActionSetPwrStorageStateGUI is made visible.
function lvd_EditActionSetPwrStorageStateGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditActionSetPwrStorageStateGUI (see VARARGIN)

    % Choose default command line output for lvd_EditActionSetPwrStorageStateGUI
    handles.output = hObject;
    
    centerUIFigure(hObject);

    action = varargin{1};
    setappdata(hObject,'action',action);
    
    lv = varargin{2};
    setappdata(hObject,'lv',lv);
    
    populateGUI(handles, action, lv);

    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditActionSetPwrStorageStateGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditActionSetPwrStorageStateGUI);

    
function populateGUI(handles, action, lv)
    [powerStoragesListStr, powerStorages] = lv.getPowerStoragesListBoxStr();
    set(handles.refPwrCompCombo,'String',powerStoragesListStr);
    
    if(not(isempty(action.storage)))
        ind = find(powerStorages == action.storage,1,'first');
    else
        ind = [];
    end
    
    if(not(isempty(ind)))
        set(handles.refPwrCompCombo,'Value',ind);
    end
    
    if(action.activeStateToSet)
        set(handles.stateCombo,'Value',1);
    else
        set(handles.stateCombo,'Value',2);
    end

% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditActionSetPwrStorageStateGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else  
        action = getappdata(hObject,'action');
        lv = getappdata(hObject,'lv');
        
        [~, powerStorages] = lv.getPowerStoragesListBoxStr();
        ind = get(handles.refPwrCompCombo,'Value');
        action.storage = powerStorages(ind);
        
        contents = cellstr(get(handles.stateCombo,'String'));
        stateStr = contents{get(handles.stateCombo,'Value')};
        
        switch stateStr
            case 'Active'
                state = true;
            case 'Inactive'
                state = false;
            otherwise 
                error('Invalid state string: %s', stateStr);
        end
        
        action.activeStateToSet = state;
        
        varargout{1} = true;
        close(handles.lvd_EditActionSetPwrStorageStateGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)   
    uiresume(handles.lvd_EditActionSetPwrStorageStateGUI);


% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditActionSetPwrStorageStateGUI);

% --- Executes on selection change in refPwrCompCombo.
function refPwrCompCombo_Callback(hObject, eventdata, handles)
% hObject    handle to refPwrCompCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns refPwrCompCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from refPwrCompCombo


% --- Executes during object creation, after setting all properties.
function refPwrCompCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to refPwrCompCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in stateCombo.
function stateCombo_Callback(hObject, eventdata, handles)
% hObject    handle to stateCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns stateCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from stateCombo


% --- Executes during object creation, after setting all properties.
function stateCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stateCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on lvd_EditActionSetPwrStorageStateGUI or any of its controls.
function lvd_EditActionSetPwrStorageStateGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditActionSetPwrStorageStateGUI (see GCBO)
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
            close(handles.lvd_EditActionSetPwrStorageStateGUI);
    end
