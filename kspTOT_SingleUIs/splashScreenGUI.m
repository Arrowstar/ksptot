function varargout = splashScreenGUI(varargin)
% SPLASHSCREENGUI MATLAB code for splashScreenGUI.fig
%      SPLASHSCREENGUI, by itself, creates a new SPLASHSCREENGUI or raises the existing
%      singleton*.
%
%      H = SPLASHSCREENGUI returns the handle to a new SPLASHSCREENGUI or the handle to
%      the existing singleton*.
%
%      SPLASHSCREENGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SPLASHSCREENGUI.M with the given input arguments.
%
%      SPLASHSCREENGUI('Property','Value',...) creates a new SPLASHSCREENGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before splashScreenGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to splashScreenGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help splashScreenGUI

% Last Modified by GUIDE v2.5 15-Jun-2014 21:58:23

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @splashScreenGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @splashScreenGUI_OutputFcn, ...
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


% --- Executes just before splashScreenGUI is made visible.
function splashScreenGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to splashScreenGUI (see VARARGIN)

% Choose default command line output for splashScreenGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

if isunix
    rgb = imread('./images/logo500px.jpg');
else
    rgb = imread('.\images\logo500px.jpg');
end
image(rgb,'Parent',handles.logoAxes);
axis off; 
axis image;

str = sprintf('Version: %s (R%s)\n(C) 2020 Arrowstar',getKSPTOTVersionNumStr(),version('-release'));
set(handles.versionCopyrightLabel,'String',str);

set(handles.splashScreenGUI,'Name',['KSP Trajectory Optimization Tool ',getKSPTOTVersionNumStr()]);


% UIWAIT makes splashScreenGUI wait for user response (see UIRESUME)
% uiwait(handles.splashScreenGUI);


% --- Outputs from this function are returned to the command line.
function varargout = splashScreenGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
