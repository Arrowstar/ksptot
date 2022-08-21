function varargout = ma_DeltaVBudgetGUI(varargin)
% MA_DELTAVBUDGETGUI MATLAB code for ma_DeltaVBudgetGUI.fig
%      MA_DELTAVBUDGETGUI, by itself, creates a new MA_DELTAVBUDGETGUI or raises the existing
%      singleton*.
%
%      H = MA_DELTAVBUDGETGUI returns the handle to a new MA_DELTAVBUDGETGUI or the handle to
%      the existing singleton*.
%
%      MA_DELTAVBUDGETGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_DELTAVBUDGETGUI.M with the given input arguments.
%
%      MA_DELTAVBUDGETGUI('Property','Value',...) creates a new MA_DELTAVBUDGETGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_DeltaVBudgetGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_DeltaVBudgetGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_DeltaVBudgetGUI

% Last Modified by GUIDE v2.5 22-Apr-2015 16:45:33

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_DeltaVBudgetGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_DeltaVBudgetGUI_OutputFcn, ...
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


% --- Executes just before ma_DeltaVBudgetGUI is made visible.
function ma_DeltaVBudgetGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_DeltaVBudgetGUI (see VARARGIN)

% Choose default command line output for ma_DeltaVBudgetGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

dvBudgetText = varargin{1};
set(handles.deltaVBudgetText,'String', dvBudgetText);

% UIWAIT makes ma_DeltaVBudgetGUI wait for user response (see UIRESUME)
% uiwait(handles.ma_DeltaVBudgetGUI);


% --- Outputs from this function are returned to the command line.
function varargout = ma_DeltaVBudgetGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function deltaVBudgetText_Callback(hObject, eventdata, handles)
% hObject    handle to deltaVBudgetText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of deltaVBudgetText as text
%        str2double(get(hObject,'String')) returns contents of deltaVBudgetText as a double


% --- Executes during object creation, after setting all properties.
function deltaVBudgetText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to deltaVBudgetText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on ma_DeltaVBudgetGUI or any of its controls.
function ma_DeltaVBudgetGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to ma_DeltaVBudgetGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'escape'
            close(handles.ma_DeltaVBudgetGUI);
    end