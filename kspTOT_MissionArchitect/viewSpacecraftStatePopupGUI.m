function varargout = viewSpacecraftStatePopupGUI(varargin)
% VIEWSPACECRAFTSTATEPOPUPGUI MATLAB code for viewSpacecraftStatePopupGUI.fig
%      VIEWSPACECRAFTSTATEPOPUPGUI, by itself, creates a new VIEWSPACECRAFTSTATEPOPUPGUI or raises the existing
%      singleton*.
%
%      H = VIEWSPACECRAFTSTATEPOPUPGUI returns the handle to a new VIEWSPACECRAFTSTATEPOPUPGUI or the handle to
%      the existing singleton*.
%
%      VIEWSPACECRAFTSTATEPOPUPGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VIEWSPACECRAFTSTATEPOPUPGUI.M with the given input arguments.
%
%      VIEWSPACECRAFTSTATEPOPUPGUI('Property','Value',...) creates a new VIEWSPACECRAFTSTATEPOPUPGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before viewSpacecraftStatePopupGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to viewSpacecraftStatePopupGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help viewSpacecraftStatePopupGUI

% Last Modified by GUIDE v2.5 22-Apr-2015 16:57:20

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @viewSpacecraftStatePopupGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @viewSpacecraftStatePopupGUI_OutputFcn, ...
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


% --- Executes just before viewSpacecraftStatePopupGUI is made visible.
function viewSpacecraftStatePopupGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to viewSpacecraftStatePopupGUI (see VARARGIN)

% Choose default command line output for viewSpacecraftStatePopupGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

handles.ma_MainGUI = varargin{1};
stateLog = varargin{2};
eventNum = varargin{3};
celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
set(hObject, 'Name', ['Spacecraft State After Event ', num2str(eventNum)]);
ma_UpdateStateReadout(handles.stateLabel, 'initial', stateLog, celBodyData);

% UIWAIT makes viewSpacecraftStatePopupGUI wait for user response (see UIRESUME)
% uiwait(handles.viewSpacecraftStatePopupGUI);


% --- Outputs from this function are returned to the command line.
function varargout = viewSpacecraftStatePopupGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = [];


% --- Executes on key press with focus on viewSpacecraftStatePopupGUI or any of its controls.
function viewSpacecraftStatePopupGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to viewSpacecraftStatePopupGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'escape'
            close(handles.viewSpacecraftStatePopupGUI);
    end