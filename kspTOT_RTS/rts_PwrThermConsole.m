function varargout = rts_PwrThermConsole(varargin)
% RTS_PWRTHERMCONSOLE MATLAB code for rts_PwrThermConsole.fig
%      RTS_PWRTHERMCONSOLE, by itself, creates a new RTS_PWRTHERMCONSOLE or raises the existing
%      singleton*.
%
%      H = RTS_PWRTHERMCONSOLE returns the handle to a new RTS_PWRTHERMCONSOLE or the handle to
%      the existing singleton*.
%
%      RTS_PWRTHERMCONSOLE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RTS_PWRTHERMCONSOLE.M with the given input arguments.
%
%      RTS_PWRTHERMCONSOLE('Property','Value',...) creates a new RTS_PWRTHERMCONSOLE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before rts_PwrThermConsole_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to rts_PwrThermConsole_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help rts_PwrThermConsole

% Last Modified by GUIDE v2.5 02-Jan-2014 20:55:31

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @rts_PwrThermConsole_OpeningFcn, ...
                   'gui_OutputFcn',  @rts_PwrThermConsole_OutputFcn, ...
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

% --- Executes just before rts_PwrThermConsole is made visible.
function rts_PwrThermConsole_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to rts_PwrThermConsole (see VARARGIN)

% Choose default command line output for rts_PwrThermConsole
    handles.output = hObject;

    hRtsMainGUI = varargin{1};
    vesselGUID = varargin{2};
    handles.mainGUI = hRtsMainGUI;
    handles.vesselGUID = vesselGUID;
    
    if(ishandle(handles.elecChargeSumLabel))
        rts_initRTSPowThermPanel(hRtsMainGUI, hObject, handles.clockLabel, handles.connStatusLabel, vesselGUID, handles.elecChargeUITable, handles.elecChargeSumLabel, ...
            handles.solarPanelUITable, handles.totECGenRateLabel, handles.partTempUITable, handles.ecStoragePanel);
    end

    % Update handles structure
    guidata(hObject, handles);
end

% UIWAIT makes rts_PwrThermConsole wait for user response (see UIRESUME)
% uiwait(handles.rts_PowThmConsole);


% --- Outputs from this function are returned to the command line.
function varargout = rts_PwrThermConsole_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    varargout{1} = handles.output;
end


% --- Executes when user attempts to close rts_PowThmConsole.
function rts_PowThmConsole_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to rts_PowThmConsole (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
    rts_pageCloseStopTimers(hObject);    
    delete(hObject);
end
