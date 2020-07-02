function varargout = rts_kspTotConnectOptions(varargin)
% RTS_KSPTOTCONNECTOPTIONS MATLAB code for rts_kspTotConnectOptions.fig
%      RTS_KSPTOTCONNECTOPTIONS, by itself, creates a new RTS_KSPTOTCONNECTOPTIONS or raises the existing
%      singleton*.
%
%      H = RTS_KSPTOTCONNECTOPTIONS returns the handle to a new RTS_KSPTOTCONNECTOPTIONS or the handle to
%      the existing singleton*.
%
%      RTS_KSPTOTCONNECTOPTIONS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RTS_KSPTOTCONNECTOPTIONS.M with the given input arguments.
%
%      RTS_KSPTOTCONNECTOPTIONS('Property','Value',...) creates a new RTS_KSPTOTCONNECTOPTIONS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before rts_kspTotConnectOptions_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to rts_kspTotConnectOptions_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help rts_kspTotConnectOptions

% Last Modified by GUIDE v2.5 13-Dec-2013 22:29:31

% Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @rts_kspTotConnectOptions_OpeningFcn, ...
                       'gui_OutputFcn',  @rts_kspTotConnectOptions_OutputFcn, ...
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
end

% --- Executes just before rts_kspTotConnectOptions is made visible.
function rts_kspTotConnectOptions_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to rts_kspTotConnectOptions (see VARARGIN)

    % Choose default command line output for rts_kspTotConnectOptions
    handles.output = hObject;
    
    hRtsMainGUI = varargin{1};
    handles.mainGUI = hRtsMainGUI;
    rtsOpts = getappdata(hRtsMainGUI,'RTSOptions');
    processInputOptions(handles, rtsOpts);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes rts_kspTotConnectOptions wait for user response (see UIRESUME)
    uiwait(handles.rts_kspTotConnectOptions);
end

function processInputOptions(handles, rtsOpts)   
    findAndSetInComboBox(handles.tmTransRateComboBox, rtsOpts.tmTransRate);
    findAndSetInComboBox(handles.processExecModeComboBox, rtsOpts.procExecMode);
    findAndSetInComboBox(handles.processFreqComboBox, rtsOpts.processFreq);
    
end

function findAndSetInComboBox(hComboBox, strToFindSet)
    contents = cellstr(get(hComboBox,'String'));
    for(i=1:length(contents))
        content = contents{i};
        if(strcmpi(content,strToFindSet))
            set(hComboBox,'Value',i);
        end
    end
end

% --- Outputs from this function are returned to the command line.
function varargout = rts_kspTotConnectOptions_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    processSaveSelections(handles);
    varargout{1} = handles.output;
    close(hObject);
end

function processSaveSelections(handles)
    hRtsMainGUI = handles.mainGUI;
    
    rtsOpts = struct();
    rtsOpts = getSelectionFromComboBox(handles.tmTransRateComboBox, rtsOpts, 'tmTransRate');
    rtsOpts = getSelectionFromComboBox(handles.processExecModeComboBox, rtsOpts, 'procExecMode');
    rtsOpts = getSelectionFromComboBox(handles.processFreqComboBox, rtsOpts, 'processFreq');
    
    setappdata(hRtsMainGUI,'RTSOptions', rtsOpts);
    restartTimersWOptions(handles, rtsOpts);
    updateTMRate(rtsOpts);
end

function rtsOpts = getSelectionFromComboBox(hComboBox, rtsOpts, optsStructFieldName)
    contents = cellstr(get(hComboBox,'String'));
    optStr = contents{get(hComboBox,'Value')};
    
    rtsOpts.(optsStructFieldName) = optStr;
end

function updateTMRate(rtsOpts) 
    tmPeriod = 1/str2double(rtsOpts.tmTransRate);
    writeDataToKSPTOTConnect('ChangeTMStreamTransmissionRate', num2str(tmPeriod), 't');
end

function restartTimersWOptions(handles, rtsOpts)
    hRtsMainGUI = handles.mainGUI;
    
    procExecPeriod = 1/str2double(rtsOpts.processFreq);
    procExecMode = rtsOpts.procExecMode;
    
    timers = getappdata(hRtsMainGUI,'timers');
    for(i=1:length(timers))
        timer = timers(i);
        if(isvalid(timer))
            data = get(timer,'UserData');
            allowEdit = data{1,1};
            
            if(allowEdit)           
                if(strcmpi(get(timer,'Running'), 'on'))
                    turnBackOn = true;
                    stop(timer);
                else
                    turnBackOn = false;
                end

                set(timer,'Period',procExecPeriod);
                set(timer,'ExecutionMode',procExecMode);

                if(turnBackOn)
                    start(timer);
                end
            end
        end
    end
end

% --- Executes on selection change in tmTransRateComboBox.
function tmTransRateComboBox_Callback(hObject, eventdata, handles)
% hObject    handle to tmTransRateComboBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns tmTransRateComboBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from tmTransRateComboBox
end

% --- Executes during object creation, after setting all properties.
function tmTransRateComboBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tmTransRateComboBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% --- Executes on selection change in processExecModeComboBox.
function processExecModeComboBox_Callback(hObject, eventdata, handles)
% hObject    handle to processExecModeComboBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns processExecModeComboBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from processExecModeComboBox
end

% --- Executes during object creation, after setting all properties.
function processExecModeComboBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to processExecModeComboBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% --- Executes on selection change in processFreqComboBox.
function processFreqComboBox_Callback(hObject, eventdata, handles)
% hObject    handle to processFreqComboBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns processFreqComboBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from processFreqComboBox
end

% --- Executes during object creation, after setting all properties.
function processFreqComboBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to processFreqComboBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% --- Executes on button press in saveCloseButton.
function saveCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.rts_kspTotConnectOptions);
end
