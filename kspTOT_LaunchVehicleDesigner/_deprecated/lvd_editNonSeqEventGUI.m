function varargout = lvd_editNonSeqEventGUI(varargin)
% LVD_EDITNONSEQEVENTGUI MATLAB code for lvd_editNonSeqEventGUI.fig
%      LVD_EDITNONSEQEVENTGUI, by itself, creates a new LVD_EDITNONSEQEVENTGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITNONSEQEVENTGUI returns the handle to a new LVD_EDITNONSEQEVENTGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITNONSEQEVENTGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITNONSEQEVENTGUI.M with the given input arguments.
%
%      LVD_EDITNONSEQEVENTGUI('Property','Value',...) creates a new LVD_EDITNONSEQEVENTGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_editNonSeqEventGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_editNonSeqEventGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_editNonSeqEventGUI

% Last Modified by GUIDE v2.5 05-Dec-2018 14:25:39

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_editNonSeqEventGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_editNonSeqEventGUI_OutputFcn, ...
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


% --- Executes just before lvd_editNonSeqEventGUI is made visible.
function lvd_editNonSeqEventGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to lvd_editNonSeqEventGUI (see VARARGIN)

    % Choose default command line output for lvd_editNonSeqEventGUI
    handles.output = hObject;
    
    nonSeqEvt = varargin{1};
    setappdata(hObject, 'nonSeqEvt', nonSeqEvt);
    
    lvdData = varargin{2};
    setappdata(hObject, 'lvdData', lvdData);

    populateGUI(nonSeqEvt, lvdData, handles);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_editNonSeqEventGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_editNonSeqEventGUI);

    
function populateGUI(nonSeqEvt, lvdData, handles)
    handles.eventNameLabel.String = nonSeqEvt.evt.name;
    
    listBoxStr = vertcat(' ',lvdData.script.getListboxStr());
    handles.lwrBndEvtCombo.String = listBoxStr;
    
    if(not(isempty(nonSeqEvt.lwrBndEvt)))
        handles.lwrBndEvtCombo.Value = lvdData.script.getNumOfEvent(nonSeqEvt.lwrBndEvt) + 1;
    else
        handles.lwrBndEvtCombo.Value = 1;
    end
    
    listBoxStr = vertcat(' ',lvdData.script.getListboxStr());
    handles.uprBndEvtCombo.String = listBoxStr;
    
    if(not(isempty(nonSeqEvt.uprBndEvt)))
        handles.uprBndEvtCombo.Value = lvdData.script.getNumOfEvent(nonSeqEvt.uprBndEvt) + 1;
    else
        handles.uprBndEvtCombo.Value = 1;
    end
    
    handles.maxExecsText.String = num2str(nonSeqEvt.maxNumExecs);

% --- Outputs from this function are returned to the command line.
function varargout = lvd_editNonSeqEventGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = [];
    else  
        lvdData = getappdata(handles.lvd_editNonSeqEventGUI, 'lvdData');
        nonSeqEvt = getappdata(handles.lvd_editNonSeqEventGUI, 'nonSeqEvt');
        
        lwrBndValue = handles.lwrBndEvtCombo.Value;
        if(lwrBndValue == 1)
            lwrBndEvt = LaunchVehicleEvent.empty(1,0);
        else
            lwrBndEvtNum = lwrBndValue - 1;
            lwrBndEvt = lvdData.script.getEventForInd(lwrBndEvtNum);
        end
        nonSeqEvt.lwrBndEvt = lwrBndEvt;
        
        uprBndValue = handles.uprBndEvtCombo.Value;
        if(uprBndValue == 1)
            uprBndEvt = LaunchVehicleEvent.empty(1,0);
        else
            uprBndEvtNum = uprBndValue - 1;
            uprBndEvt = lvdData.script.getEventForInd(uprBndEvtNum);
        end
        nonSeqEvt.uprBndEvt = uprBndEvt;
        
        nonSeqEvt.maxNumExecs = str2double(handles.maxExecsText.String);
        nonSeqEvt.numExecsRemaining = str2double(handles.maxExecsText.String);
        
        close(handles.lvd_editNonSeqEventGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);

    if(isempty(errMsg))
       uiresume(handles.lvd_editNonSeqEventGUI);
    else
        msgbox(errMsg,'Errors were found while editing the non-sequential event.','error');
    end  
    
    
function errMsg = validateInputs(handles)
    errMsg = {};
    
    value = str2double(get(handles.maxExecsText,'String'));
    enteredStr = get(handles.maxExecsText,'String');
    numberName = 'Max. Number of Executions';
    lb = 1;
    ub = Inf;
    isInt = true;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);

% --- Executes on selection change in lwrBndEvtCombo.
function lwrBndEvtCombo_Callback(hObject, eventdata, handles)
% hObject    handle to lwrBndEvtCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lwrBndEvtCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lwrBndEvtCombo


% --- Executes during object creation, after setting all properties.
function lwrBndEvtCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lwrBndEvtCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in uprBndEvtCombo.
function uprBndEvtCombo_Callback(hObject, eventdata, handles)
% hObject    handle to uprBndEvtCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns uprBndEvtCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from uprBndEvtCombo


% --- Executes during object creation, after setting all properties.
function uprBndEvtCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uprBndEvtCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxExecsText_Callback(hObject, eventdata, handles)
% hObject    handle to maxExecsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxExecsText as text
%        str2double(get(hObject,'String')) returns contents of maxExecsText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function maxExecsText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxExecsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in editEventButton.
function editEventButton_Callback(hObject, eventdata, handles)
% hObject    handle to editEventButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    nonSeqEvt = getappdata(handles.lvd_editNonSeqEventGUI, 'nonSeqEvt');
    event = nonSeqEvt.evt;
    
%     lvd_editEventGUI(event, true);
    output = AppDesignerGUIOutput({false});
    lvd_editEventGUI_App(event, true, output);
    
    handles.eventNameLabel.String = nonSeqEvt.evt.name;
