function varargout = lvd_editEventGUI(varargin)
% LVD_EDITEVENTGUI MATLAB code for lvd_editEventGUI.fig
%      LVD_EDITEVENTGUI, by itself, creates a new LVD_EDITEVENTGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITEVENTGUI returns the handle to a new LVD_EDITEVENTGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITEVENTGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITEVENTGUI.M with the given input arguments.
%
%      LVD_EDITEVENTGUI('Property','Value',...) creates a new LVD_EDITEVENTGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_editEventGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_editEventGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_editEventGUI

% Last Modified by GUIDE v2.5 15-Sep-2018 19:46:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_editEventGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_editEventGUI_OutputFcn, ...
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


% --- Executes just before lvd_editEventGUI is made visible.
function lvd_editEventGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to lvd_editEventGUI (see VARARGIN)

    % Choose default command line output for lvd_editEventGUI
    handles.output = hObject;

    event = varargin{1};
    setappdata(hObject,'event',event);

    populateGUI(handles, event);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_editEventGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_editEventGUI);


function populateGUI(handles, event)
    set(handles.eventNameText,'String',event.name);
    
    termCond = event.termCond;
    set(handles.termCondNameLabel,'String',termCond.getName());
    
    set(handles.actionsListbox,'String',event.getActionsListboxStr());
    set(handles.actionsListbox,'Value',1);

% --- Outputs from this function are returned to the command line.
function varargout = lvd_editEventGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = [];
    else
        event = getappdata(handles.lvd_editEventGUI,'event');
        
        evtName = get(handles.eventNameText,'String');
        event.name = evtName;
        
        close(handles.lvd_editEventGUI);
    end

% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.lvd_editEventGUI);

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_editEventGUI);


function eventNameText_Callback(hObject, eventdata, handles)
% hObject    handle to eventNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eventNameText as text
%        str2double(get(hObject,'String')) returns contents of eventNameText as a double


% --- Executes during object creation, after setting all properties.
function eventNameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eventNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in actionsListbox.
function actionsListbox_Callback(hObject, eventdata, handles)
% hObject    handle to actionsListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns actionsListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from actionsListbox
    if(strcmpi(get(handles.lvd_editEventGUI,'SelectionType'),'open'))
        event = getappdata(handles.lvd_editEventGUI,'event');
        lv = event.script.lvdData.launchVehicle;
        
        selActionInd = get(handles.actionsListbox,'Value');
        action = event.getActionForInd(selActionInd);
        
        action.openEditActionUI(action, lv);
        
        set(handles.actionsListbox,'String',event.getActionsListboxStr());
    end


% --- Executes during object creation, after setting all properties.
function actionsListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to actionsListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addActionButton.
function addActionButton_Callback(hObject, eventdata, handles)
% hObject    handle to addActionButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    event = getappdata(handles.lvd_editEventGUI,'event');
    lv = event.script.lvdData.launchVehicle;
    actionStrs = EventActionEnum.getActionTypeNameStrs();

    [dialogInd,tf] = listdlg('ListString',actionStrs, ...
                             'Name','Select Action', ...
                             'PromptString',{'Select the action you wish to add','to this event:'}, ...
                             'SelectionMode','single', ...
                             'ListSize',[210 300]);
    
    if(tf == 1)
        [m,~] = enumeration('EventActionEnum');
        inds = strcmpi({m.nameStr},actionStrs{dialogInd});
        
        actionEnum = m(inds);
        
        newAction = feval(actionEnum.classNameStr);
        addActionTf = newAction.openEditActionUI(newAction, lv);
        
        if(addActionTf)
            event.addAction(newAction);
        end
        
        set(handles.actionsListbox,'String',event.getActionsListboxStr());
    end
    
% --- Executes on button press in removeActionButton.
function removeActionButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeActionButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    event = getappdata(handles.lvd_editEventGUI,'event');

    selActionInd = get(handles.actionsListbox,'Value');
    event.removeActionByInd(selActionInd);
    
    set(handles.actionsListbox,'String',event.getActionsListboxStr());
    
    aListBosStr = get(handles.actionsListbox,'String');
    if(iscell(aListBosStr) && length(aListBosStr)<selActionInd)
        set(handles.actionsListbox,'Value',length(aListBosStr));
    end

% --- Executes on button press in editTermCondParamsButton.
function editTermCondParamsButton_Callback(hObject, eventdata, handles)
% hObject    handle to editTermCondParamsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    event = getappdata(handles.lvd_editEventGUI,'event');
    lvd_editEvtTermCond(event);
    
    termCond = event.termCond;
    set(handles.termCondNameLabel,'String',termCond.getName());

% --- Executes when user attempts to close lvd_editEventGUI.
function lvd_editEventGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to lvd_editEventGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
    delete(hObject);
