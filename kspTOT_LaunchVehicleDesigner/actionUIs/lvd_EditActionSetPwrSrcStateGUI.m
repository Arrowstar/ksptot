function varargout = lvd_EditActionSetPwrSrcStateGUI(varargin)
% LVD_EDITACTIONSETPWRSRCSTATEGUI MATLAB code for lvd_EditActionSetPwrSrcStateGUI.fig
%      LVD_EDITACTIONSETPWRSRCSTATEGUI, by itself, creates a new LVD_EDITACTIONSETPWRSRCSTATEGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITACTIONSETPWRSRCSTATEGUI returns the handle to a new LVD_EDITACTIONSETPWRSRCSTATEGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITACTIONSETPWRSRCSTATEGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITACTIONSETPWRSRCSTATEGUI.M with the given input arguments.
%
%      LVD_EDITACTIONSETPWRSRCSTATEGUI('Property','Value',...) creates a new LVD_EDITACTIONSETPWRSRCSTATEGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditActionSetPwrSrcStateGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditActionSetPwrSrcStateGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditActionSetPwrSrcStateGUI

% Last Modified by GUIDE v2.5 06-Aug-2020 15:26:37

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditActionSetPwrSrcStateGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditActionSetPwrSrcStateGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditActionSetPwrSrcStateGUI is made visible.
function lvd_EditActionSetPwrSrcStateGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditActionSetPwrSrcStateGUI (see VARARGIN)

    % Choose default command line output for lvd_EditActionSetPwrSrcStateGUI
    handles.output = hObject;

    action = varargin{1};
    setappdata(hObject,'action',action);
    
    lv = varargin{2};
    setappdata(hObject,'lv',lv);
    
    populateGUI(handles, action, lv);

    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditActionSetPwrSrcStateGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditActionSetPwrSrcStateGUI);

    
function populateGUI(handles, action, lv)
    [powerSrcListStr, powerSrcs] = lv.getPowerSrcsListBoxStr();
    set(handles.refPwrCompCombo,'String',powerSrcListStr);
    
    if(not(isempty(action.src)))
        ind = find(powerSrcs == action.src,1,'first');
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
function varargout = lvd_EditActionSetPwrSrcStateGUI_OutputFcn(hObject, eventdata, handles) 
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
        
        [~, powerSrcs] = lv.getPowerSrcsListBoxStr();
        ind = get(handles.refPwrCompCombo,'Value');
        action.src = powerSrcs(ind);
        
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
        close(handles.lvd_EditActionSetPwrSrcStateGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)   
    uiresume(handles.lvd_EditActionSetPwrSrcStateGUI);


% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditActionSetPwrSrcStateGUI);

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


% --- Executes on key press with focus on lvd_EditActionSetPwrSrcStateGUI or any of its controls.
function lvd_EditActionSetPwrSrcStateGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditActionSetPwrSrcStateGUI (see GCBO)
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
            close(handles.lvd_EditActionSetPwrSrcStateGUI);
    end
