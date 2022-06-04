function varargout = lvd_EditActionResetExtremumValueGUI(varargin)
% LVD_EDITACTIONRESETEXTREMUMVALUEGUI MATLAB code for lvd_EditActionResetExtremumValueGUI.fig
%      LVD_EDITACTIONRESETEXTREMUMVALUEGUI, by itself, creates a new LVD_EDITACTIONRESETEXTREMUMVALUEGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITACTIONRESETEXTREMUMVALUEGUI returns the handle to a new LVD_EDITACTIONRESETEXTREMUMVALUEGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITACTIONRESETEXTREMUMVALUEGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITACTIONRESETEXTREMUMVALUEGUI.M with the given input arguments.
%
%      LVD_EDITACTIONRESETEXTREMUMVALUEGUI('Property','Value',...) creates a new LVD_EDITACTIONRESETEXTREMUMVALUEGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditActionResetExtremumValueGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditActionResetExtremumValueGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditActionResetExtremumValueGUI

% Last Modified by GUIDE v2.5 23-Jan-2019 10:00:18

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditActionResetExtremumValueGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditActionResetExtremumValueGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditActionResetExtremumValueGUI is made visible.
function lvd_EditActionResetExtremumValueGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditActionResetExtremumValueGUI (see VARARGIN)

    % Choose default command line output for lvd_EditActionResetExtremumValueGUI
    handles.output = hObject;
    
    centerUIFigure(hObject);
    
    action = varargin{1};
    setappdata(hObject,'action',action);
    
    lv = varargin{2};
    setappdata(hObject,'lv',lv);
    
    populateGUI(handles, action, lv);

    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditActionResetExtremumValueGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditActionResetExtremumValueGUI);

function populateGUI(handles, action, lv)
    [exListStr, extrema] = lv.getExtremaListBoxStr();
    if(not(isempty(exListStr)))
        set(handles.refExtremumCombo,'String',exListStr);
    else
        set(handles.refExtremumCombo,'String',' ');
    end
       
    if(not(isempty(action.extremum)))
        ind = find(extrema == action.extremum,1,'first');
    else
        ind = [];
    end
    
    if(not(isempty(ind)))
        set(handles.refExtremumCombo,'Value',ind);
    end  
    

% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditActionResetExtremumValueGUI_OutputFcn(hObject, eventdata, handles) 
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
        
        [~, extrema] = lv.getExtremaListBoxStr();
        if(not(isempty(extrema)))
            ind = get(handles.refExtremumCombo,'Value');
            action.extremum = extrema(ind);
        end
        
        varargout{1} = true;
        close(handles.lvd_EditActionResetExtremumValueGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.lvd_EditActionResetExtremumValueGUI);

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditActionResetExtremumValueGUI);

% --- Executes on selection change in refExtremumCombo.
function refExtremumCombo_Callback(hObject, eventdata, handles)
% hObject    handle to refExtremumCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns refExtremumCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from refExtremumCombo


% --- Executes during object creation, after setting all properties.
function refExtremumCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to refExtremumCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on lvd_EditActionResetExtremumValueGUI or any of its controls.
function lvd_EditActionResetExtremumValueGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditActionResetExtremumValueGUI (see GCBO)
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
            close(handles.lvd_EditActionResetExtremumValueGUI);
    end
