function varargout = lvd_EditActionSetClampStateGUI(varargin)
% LVD_EDITACTIONSETCLAMPSTATEGUI MATLAB code for lvd_EditActionSetClampStateGUI.fig
%      LVD_EDITACTIONSETCLAMPSTATEGUI, by itself, creates a new LVD_EDITACTIONSETCLAMPSTATEGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITACTIONSETCLAMPSTATEGUI returns the handle to a new LVD_EDITACTIONSETCLAMPSTATEGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITACTIONSETCLAMPSTATEGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITACTIONSETCLAMPSTATEGUI.M with the given input arguments.
%
%      LVD_EDITACTIONSETCLAMPSTATEGUI('Property','Value',...) creates a new LVD_EDITACTIONSETCLAMPSTATEGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditActionSetClampStateGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditActionSetClampStateGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditActionSetClampStateGUI

% Last Modified by GUIDE v2.5 11-Oct-2018 18:13:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditActionSetClampStateGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditActionSetClampStateGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditActionSetClampStateGUI is made visible.
function lvd_EditActionSetClampStateGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditActionSetClampStateGUI (see VARARGIN)

    % Choose default command line output for lvd_EditActionSetClampStateGUI
    handles.output = hObject;
    
    action = varargin{1};
    setappdata(hObject,'action',action);
    
    populateGUI(handles, action);

    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditActionSetClampStateGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditActionSetClampStateGUI);

function populateGUI(handles, action)
        
    if(action.activeStateToSet)
        set(handles.stateCombo,'Value',1);
    else
        set(handles.stateCombo,'Value',2);
    end
    

% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditActionSetClampStateGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else  
        action = getappdata(hObject,'action');
               
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
        
        action.activeStateToSet = state; %TODO Create this field
        
        varargout{1} = true;
        close(handles.lvd_EditActionSetClampStateGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.lvd_EditActionSetClampStateGUI);

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditActionSetClampStateGUI);


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
