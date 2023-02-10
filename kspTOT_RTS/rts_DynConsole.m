function varargout = rts_DynConsole(varargin)
% RTS_DYNCONSOLE MATLAB code for rts_DynConsole.fig
%      RTS_DYNCONSOLE, by itself, creates a new RTS_DYNCONSOLE or raises the existing
%      singleton*.
%
%      H = RTS_DYNCONSOLE returns the handle to a new RTS_DYNCONSOLE or the handle to
%      the existing singleton*.
%
%      RTS_DYNCONSOLE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RTS_DYNCONSOLE.M with the given input arguments.
%
%      RTS_DYNCONSOLE('Property','Value',...) creates a new RTS_DYNCONSOLE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before rts_DynConsole_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to rts_DynConsole_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help rts_DynConsole

% Last Modified by GUIDE v2.5 13-Dec-2013 17:48:09

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @rts_DynConsole_OpeningFcn, ...
                   'gui_OutputFcn',  @rts_DynConsole_OutputFcn, ...
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

% --- Executes just before rts_DynConsole is made visible.
function rts_DynConsole_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to rts_DynConsole (see VARARGIN)

% Choose default command line output for rts_DynConsole
    handles.output = hObject;

    hRtsMainGUI = varargin{1};
    vesselGUID = varargin{2};
    handles.mainGUI = hRtsMainGUI;
    handles.vesselGUID = vesselGUID;

    rts_initRTSDynPanel(hRtsMainGUI, hObject, handles.clockLabel, handles.connStatusLabel, vesselGUID,...
                        handles.attPointingTextDispLabel, handles.attRatesTextDispLabel, handles.attCmdTextDispLabel, handles.attDispAxes,...
                        handles.actStatusTextDispLabel, handles.rwaInfoUitable, handles.attDerivedTextDispLabel);

    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes rts_DynConsole wait for user response (see UIRESUME)
    % uiwait(handles.rts_DynConsole);
end

% --- Outputs from this function are returned to the command line.
function varargout = rts_DynConsole_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end


% --- Executes when user attempts to close rts_DynConsole.
function rts_DynConsole_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to rts_DynConsole (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
    rts_pageCloseStopTimers(hObject);    
    delete(hObject);
end
