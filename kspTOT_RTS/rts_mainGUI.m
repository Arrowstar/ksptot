function varargout = rts_mainGUI(varargin)
% RTS_MAINGUI MATLAB code for rts_mainGUI.fig
%      RTS_MAINGUI, by itself, creates a new RTS_MAINGUI or raises the existing
%      singleton*.
%
%      H = RTS_MAINGUI returns the handle to a new RTS_MAINGUI or the handle to
%      the existing singleton*.
%
%      RTS_MAINGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RTS_MAINGUI.M with the given input arguments.
%
%      RTS_MAINGUI('Property','Value',...) creates a new RTS_MAINGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before rts_mainGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to rts_mainGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help rts_mainGUI

% Last Modified by GUIDE v2.5 09-Sep-2014 18:16:51

% Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @rts_mainGUI_OpeningFcn, ...
                       'gui_OutputFcn',  @rts_mainGUI_OutputFcn, ...
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

% --- Executes just before rts_mainGUI is made visible.
function rts_mainGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to rts_mainGUI (see VARARGIN)

% Choose default command line output for rts_mainGUI
handles.output = hObject;

%%% REPLACE THIS WITH A CALL TO GET CEL BODY DATA FROM MAIN KSPTOT GUI %%%
% [celBodyDataFromINI,~,~] = inifile('bodies.ini','readall');
% celBodyData = processINIBodyInfo(celBodyDataFromINI);
celBodyData = varargin{1};
setappdata(handles.rtsMainGUI,'CelBodyData',celBodyData);
setappdata(handles.rtsMainGUI,'ChildGUIs',{});

rtsOpts = struct();
rtsOpts.tmTransRate = '1';
rtsOpts.procExecMode = 'fixedRate';
rtsOpts.processFreq = '0.5';
setappdata(handles.rtsMainGUI,'RTSOptions',rtsOpts);

% Initialize RTS Main Panel
initRTSMainPanel(handles.rtsMainGUI);

% Update handles structure
if(ishandle(hObject))
    guidata(hObject, handles);
end

% UIWAIT makes rts_mainGUI wait for user response (see UIRESUME)
% uiwait(handles.rtsMainGUI);
end

function initRTSMainPanel(hRtsMainGUI) 
    rts_StartTMStream(hRtsMainGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = rts_mainGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = [];
end

% --- Executes on button press in rts_FlightPageButton.
function rts_FlightPageButton_Callback(hObject, eventdata, handles)
% hObject    handle to rts_FlightPageButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

% --- Executes on button press in rts_OrbOpsPageButton.
function rts_OrbOpsPageButton_Callback(hObject, eventdata, handles)
% hObject    handle to rts_OrbOpsPageButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA).
    vesselGUID = getappdata(handles.rtsMainGUI,'VesselGUID');
    h = rts_OrbOpsConsole(handles.rtsMainGUI, vesselGUID);
    ChildGUIs = getappdata(handles.rtsMainGUI,'ChildGUIs');
    ChildGUIs{end+1} = h;
    setappdata(handles.rtsMainGUI,'ChildGUIs',ChildGUIs);
end

% --- Executes on button press in rts_SCDynPageButton.
function rts_SCDynPageButton_Callback(hObject, eventdata, handles)
% hObject    handle to rts_SCDynPageButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    vesselGUID = getappdata(handles.rtsMainGUI,'VesselGUID');
    h = rts_DynConsole(handles.rtsMainGUI, vesselGUID);
    ChildGUIs = getappdata(handles.rtsMainGUI,'ChildGUIs');
    ChildGUIs{end+1} = h;
    setappdata(handles.rtsMainGUI,'ChildGUIs',ChildGUIs);
end

% --- Executes on button press in rts_PwrThrmlPageButton.
function rts_PwrThrmlPageButton_Callback(hObject, eventdata, handles)
% hObject    handle to rts_PwrThrmlPageButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    vesselGUID = getappdata(handles.rtsMainGUI,'VesselGUID');
    h = rts_PwrThermConsole(handles.rtsMainGUI, vesselGUID);
    ChildGUIs = getappdata(handles.rtsMainGUI,'ChildGUIs');
    ChildGUIs{end+1} = h;
    setappdata(handles.rtsMainGUI,'ChildGUIs',ChildGUIs);
end

% --- Executes on button press in rts_PropPageButton.
function rts_PropPageButton_Callback(hObject, eventdata, handles)
% hObject    handle to rts_PropPageButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    vesselGUID = getappdata(handles.rtsMainGUI,'VesselGUID');
    h = rts_PropConsole(handles.rtsMainGUI, vesselGUID);
    ChildGUIs = getappdata(handles.rtsMainGUI,'ChildGUIs');
    ChildGUIs{end+1} = h;
    setappdata(handles.rtsMainGUI,'ChildGUIs',ChildGUIs);
end

% --- Executes on button press in rts_ClockUtilButton.
function rts_ClockUtilButton_Callback(hObject, eventdata, handles)
% hObject    handle to rts_ClockUtilButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


% --- Executes when user attempts to close rtsMainGUI.
function rtsMainGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to rtsMainGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
    rts_EndTMStream(handles.rtsMainGUI, true, false, false);
    ChildGUIs = getappdata(handles.rtsMainGUI,'ChildGUIs');
    for(i=1:length(ChildGUIs))
        if(ishandle(ChildGUIs{i}))
            delete(ChildGUIs{i});
        end
    end
    delete(hObject);
end


% --------------------------------------------------------------------
function connect2KSPTOTConnect_Callback(hObject, eventdata, handles)
% hObject    handle to connect2KSPTOTConnect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    rts_StartTMStream(handles.rtsMainGUI);
end


% --------------------------------------------------------------------
function disconnectFromKSPTOTConnect_Callback(hObject, eventdata, handles)
% hObject    handle to disconnectFromKSPTOTConnect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    rts_EndTMStream(handles.rtsMainGUI, false, false, false);
end


% --- Executes on button press in rts_TMMonUtilButton.
function rts_TMMonUtilButton_Callback(hObject, eventdata, handles)
% hObject    handle to rts_TMMonUtilButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    vesselGUID = getappdata(handles.rtsMainGUI,'VesselGUID');
    h = rts_TmMonitorConsole(handles.rtsMainGUI, vesselGUID);
    ChildGUIs = getappdata(handles.rtsMainGUI,'ChildGUIs');
    ChildGUIs{end+1} = h;
    setappdata(handles.rtsMainGUI,'ChildGUIs',ChildGUIs);
end

% --------------------------------------------------------------------
function exitGUI_Callback(hObject, eventdata, handles)
% hObject    handle to exitGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    ChildGUIs = getappdata(handles.rtsMainGUI,'ChildGUIs');
    for(i=1:length(ChildGUIs))
        if(ishandle(ChildGUIs{i}))
            close(ChildGUIs{i});
        end
    end
    close(handles.rtsMainGUI);
end


% --------------------------------------------------------------------
function connectionMenu_Callback(hObject, eventdata, handles)
% hObject    handle to connectionMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

% --------------------------------------------------------------------
function connect2NewVessel_Callback(hObject, eventdata, handles)
% hObject    handle to connect2NewVessel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    rts_EndTMStream(handles.rtsMainGUI, true, false, true);
    rts_StartTMStream(handles.rtsMainGUI);
end


% --------------------------------------------------------------------
function rtsOptions_Callback(hObject, eventdata, handles)
% hObject    handle to rtsOptions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    rts_kspTotConnectOptions(handles.rtsMainGUI);
end


% --------------------------------------------------------------------
function terminateTMStream_Callback(hObject, eventdata, handles)
% hObject    handle to terminateTMStream (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    rts_EndTMStream(handles.rtsMainGUI, true, false, true);
end
