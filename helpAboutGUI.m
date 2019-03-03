function varargout = helpAboutGUI(varargin)
% HELPABOUTGUI MATLAB code for helpAboutGUI.fig
%      HELPABOUTGUI, by itself, creates a new HELPABOUTGUI or raises the existing
%      singleton*.
%
%      H = HELPABOUTGUI returns the handle to a new HELPABOUTGUI or the handle to
%      the existing singleton*.
%
%      HELPABOUTGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in HELPABOUTGUI.M with the given input arguments.
%
%      HELPABOUTGUI('Property','Value',...) creates a new HELPABOUTGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before helpAboutGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to helpAboutGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help helpAboutGUI

% Last Modified by GUIDE v2.5 15-Jun-2014 12:57:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @helpAboutGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @helpAboutGUI_OutputFcn, ...
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


% --- Executes just before helpAboutGUI is made visible.
function helpAboutGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to helpAboutGUI (see VARARGIN)

% Choose default command line output for helpAboutGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% str = sprintf(['KSP\nTrajectory Optimization Tool ',getKSPTOTVersionNumStr()]);
% set(handles.titleLabel,'String',str);

handles.versionLabel.String = ['v',getKSPTOTVersionNumStr()];

if(ispc)
    rgb = imread('images\testlogo.png');
else
    rgb = imread('images/testlogo.png');
end
image(rgb,'Parent',handles.logoAxes);
axis off; 
axis image;




% UIWAIT makes helpAboutGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = helpAboutGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
