function varargout = lvd_EditStopwatchesGUI(varargin)
% LVD_EDITSTOPWATCHESGUI MATLAB code for lvd_EditStopwatchesGUI.fig
%      LVD_EDITSTOPWATCHESGUI, by itself, creates a new LVD_EDITSTOPWATCHESGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITSTOPWATCHESGUI returns the handle to a new LVD_EDITSTOPWATCHESGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITSTOPWATCHESGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITSTOPWATCHESGUI.M with the given input arguments.
%
%      LVD_EDITSTOPWATCHESGUI('Property','Value',...) creates a new LVD_EDITSTOPWATCHESGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditStopwatchesGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditStopwatchesGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditStopwatchesGUI

% Last Modified by GUIDE v2.5 15-Dec-2018 18:20:47

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditStopwatchesGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditStopwatchesGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditStopwatchesGUI is made visible.
function lvd_EditStopwatchesGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditStopwatchesGUI (see VARARGIN)

    % Choose default command line output for lvd_EditStopwatchesGUI
    handles.output = hObject;

    lvdData = varargin{1};
    setappdata(hObject,'lvdData',lvdData);
    
    populateGUI(handles, lvdData);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditStopwatchesGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditStopwatchesGUI);

function populateGUI(handles, lvdData)
    set(handles.stopwatchesListBox,'String',lvdData.launchVehicle.getStopwatchesListBoxStr());
    
    numStopwatches = length(get(handles.stopwatchesListBox,'String'));
    if(numStopwatches <= 0)
        handles.removeStopwatchButton.Enable = 'off';
    end

    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditStopwatchesGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = [];
    else
        close(handles.lvd_EditStopwatchesGUI);
    end


% --- Executes on button press in closeButton.
function closeButton_Callback(hObject, eventdata, handles)
% hObject    handle to closeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.lvd_EditStopwatchesGUI);

% --- Executes on selection change in stopwatchesListBox.
function stopwatchesListBox_Callback(hObject, eventdata, handles)
% hObject    handle to stopwatchesListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns stopwatchesListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from stopwatchesListBox
    if(strcmpi(get(handles.lvd_EditStopwatchesGUI,'SelectionType'),'open'))
        lvdData = getappdata(handles.lvd_EditStopwatchesGUI,'lvdData');
        lv = lvdData.launchVehicle;

        selSW = get(handles.stopwatchesListBox,'Value');
        stopwatch = lv.getStopwatchForInd(selSW);
        
        lvd_EditStopwatchGUI(stopwatch);
        
        set(handles.stopwatchesListBox,'String',lvdData.launchVehicle.getStopwatchesListBoxStr());
    end
    

% --- Executes during object creation, after setting all properties.
function stopwatchesListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stopwatchesListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addStopwatchButton.
function addStopwatchButton_Callback(hObject, eventdata, handles)
% hObject    handle to addStopwatchButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditStopwatchesGUI,'lvdData');
    
    stopwatch = LaunchVehicleStopwatch(lvdData);
    useStopwatch = lvd_EditStopwatchGUI(stopwatch);
    
    if(useStopwatch)        
        lvdData.launchVehicle.addStopwatch(stopwatch);
        
        set(handles.stopwatchesListBox,'String',lvdData.launchVehicle.getStopwatchesListBoxStr());
        
        if(handles.stopwatchesListBox.Value <= 0)
            handles.stopwatchesListBox.Value = 1;
        end
        
        handles.removeStopwatchButton.Enable = 'on';
    end
    
% --- Executes on button press in removeStopwatchButton.
function removeStopwatchButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeStopwatchButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditStopwatchesGUI,'lvdData');
    lv = lvdData.launchVehicle;
    
    selSw = get(handles.stopwatchesListBox,'Value');
    stopwatch = lv.getStopwatchForInd(selSw);
    
    tf = stopwatch.isInUse();
    
    if(tf == false)
        lv.removeStopwatch(stopwatch);
        
        set(handles.stopwatchesListBox,'String',lvdData.launchVehicle.getStopwatchesListBoxStr());
        
        numSws = length(handles.stopwatchesListBox.String);
        if(selSw > numSws)
            set(handles.stopwatchesListBox,'Value',numSws);
        end
        
        if(numSws <= 0)
            handles.removeStopwatchButton.Enable = 'off';
        end
    else
        warndlg(sprintf('Could not delete the stopwatch "%s" because it is in use as part of an event termination condition, event action, objective function, or constraint.  Remove the engine dependencies before attempting to delete the engine.', stopwatch.name),'Cannot Delete Engine','modal');
    end


% --- Executes on key press with focus on lvd_EditStopwatchesGUI or any of its controls.
function lvd_EditStopwatchesGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditStopwatchesGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            uiresume(handles.lvd_EditStopwatchesGUI);
        case 'enter'
            uiresume(handles.lvd_EditStopwatchesGUI);
        case 'escape'
            uiresume(handles.lvd_EditStopwatchesGUI);
    end
