function varargout = rts_PropConsole(varargin)
% RTS_PROPCONSOLE MATLAB code for rts_PropConsole.fig
%      RTS_PROPCONSOLE, by itself, creates a new RTS_PROPCONSOLE or raises the existing
%      singleton*.
%
%      H = RTS_PROPCONSOLE returns the handle to a new RTS_PROPCONSOLE or the handle to
%      the existing singleton*.
%
%      RTS_PROPCONSOLE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RTS_PROPCONSOLE.M with the given input arguments.
%
%      RTS_PROPCONSOLE('Property','Value',...) creates a new RTS_PROPCONSOLE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before rts_PropConsole_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to rts_PropConsole_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help rts_PropConsole

% Last Modified by GUIDE v2.5 03-Jan-2014 18:04:48

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @rts_PropConsole_OpeningFcn, ...
                   'gui_OutputFcn',  @rts_PropConsole_OutputFcn, ...
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

% --- Executes just before rts_PropConsole is made visible.
function rts_PropConsole_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to rts_PropConsole (see VARARGIN)

    % Choose default command line output for rts_PropConsole
    handles.output = hObject;

    hRtsMainGUI = varargin{1};
    vesselGUID = varargin{2};
    handles.mainGUI = hRtsMainGUI;
    handles.vesselGUID = vesselGUID;
    
    if(ishandle(handles.resSumLabel1))
        rts_initRTSPropPanel(hRtsMainGUI, hObject, handles.clockLabel, handles.connStatusLabel, vesselGUID, handles.resUITable1, handles.resSumLabel1, ...
                             handles.resUITable2, handles.resSumLabel2, handles.resourceCombo1, handles.resourceCombo2, handles.mainEngineUITable,...
                             handles.rcsEngineUITable, handles.resourcePanel1, handles.resourcePanel2);
    end

    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes rts_PropConsole wait for user response (see UIRESUME)
    % uiwait(handles.rts_PropConsole);
end

% --- Outputs from this function are returned to the command line.
function varargout = rts_PropConsole_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    varargout{1} = handles.output;
end


% --- Executes on selection change in resourceCombo2.
function resourceCombo2_Callback(hObject, eventdata, handles)
% hObject    handle to resourceCombo2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns resourceCombo2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from resourceCombo2
end

% --- Executes during object creation, after setting all properties.
function resourceCombo2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to resourceCombo2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on selection change in resourceCombo1.
function resourceCombo1_Callback(hObject, eventdata, handles)
% hObject    handle to resourceCombo1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns resourceCombo1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from resourceCombo1
end

% --- Executes during object creation, after setting all properties.
function resourceCombo1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to resourceCombo1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


% --- Executes on selection change in resourceCombo2.
function popupmenu4_Callback(hObject, eventdata, handles)
% hObject    handle to resourceCombo2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns resourceCombo2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from resourceCombo2
end

% --- Executes during object creation, after setting all properties.
function popupmenu4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to resourceCombo2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


% --- Executes when user attempts to close rts_PropConsole.
function rts_PropConsole_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to rts_PropConsole (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
    rts_pageCloseStopTimers(hObject);    
    delete(hObject);
end
