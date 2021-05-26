function varargout = rts_OrbOpsConsole(varargin)
% RTS_ORBOPSCONSOLE MATLAB code for rts_OrbOpsConsole.fig
%      RTS_ORBOPSCONSOLE, by itself, creates a new RTS_ORBOPSCONSOLE or raises the existing
%      singleton*.
%
%      H = RTS_ORBOPSCONSOLE returns the handle to a new RTS_ORBOPSCONSOLE or the handle to
%      the existing singleton*.
%
%      RTS_ORBOPSCONSOLE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RTS_ORBOPSCONSOLE.M with the given input arguments.
%
%      RTS_ORBOPSCONSOLE('Property','Value',...) creates a new RTS_ORBOPSCONSOLE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before rts_OrbOpsConsole_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to rts_OrbOpsConsole_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help rts_OrbOpsConsole

% Last Modified by GUIDE v2.5 08-Dec-2013 14:01:25

% Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @rts_OrbOpsConsole_OpeningFcn, ...
                       'gui_OutputFcn',  @rts_OrbOpsConsole_OutputFcn, ...
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

% --- Executes just before rts_OrbOpsConsole is made visible.
function rts_OrbOpsConsole_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to rts_OrbOpsConsole (see VARARGIN)
    % Choose default command line output for rts_OrbOpsConsole
    handles.output = hObject;
    
    hRtsMainGUI = varargin{1};
    vesselGUID = varargin{2};
    handles.mainGUI = hRtsMainGUI;
    handles.vesselGUID = vesselGUID;

    %Initialize OrbOps panel
    rts_initRTSOrbOpsPanel(hRtsMainGUI, handles.rts_OrbOpsConsole, handles.clockLabel, handles.connStatusLabel, vesselGUID, handles.orbitTextDispLabel, ...
                            handles.orbitDispAxes, handles.targetOrbitTextDispLabel, handles.maneuversTextDispLabel, handles.rendInfoTextDispLabel);

    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes rts_OrbOpsConsole wait for user response (see UIRESUME)
    % uiwait(handles.rts_OrbOpsConsole);
end


% --- Outputs from this function are returned to the command line.
function varargout = rts_OrbOpsConsole_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    varargout{1} = handles.output;
end


% --- Executes when user attempts to close rts_OrbOpsConsole.
function rts_OrbOpsConsole_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to rts_OrbOpsConsole (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure

    rts_pageCloseStopTimers(hObject);    
    delete(hObject);
end


% --- Executes on button press in prevManButton.
function prevManButton_Callback(hObject, eventdata, handles)
% hObject    handle to prevManButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    set(handles.maneuversTextDispLabel, 'UserData', max(get(handles.maneuversTextDispLabel,'UserData')-1,0));
end

% --- Executes on button press in nextManButton.
function nextManButton_Callback(hObject, eventdata, handles)
% hObject    handle to nextManButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    set(handles.maneuversTextDispLabel, 'UserData', max(get(handles.maneuversTextDispLabel,'UserData')+1,0));
end
