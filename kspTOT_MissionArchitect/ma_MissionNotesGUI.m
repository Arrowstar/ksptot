function varargout = ma_MissionNotesGUI(varargin)
% MA_MISSIONNOTESGUI MATLAB code for ma_MissionNotesGUI.fig
%      MA_MISSIONNOTESGUI, by itself, creates a new MA_MISSIONNOTESGUI or raises the existing
%      singleton*.
%
%      H = MA_MISSIONNOTESGUI returns the handle to a new MA_MISSIONNOTESGUI or the handle to
%      the existing singleton*.
%
%      MA_MISSIONNOTESGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_MISSIONNOTESGUI.M with the given input arguments.
%
%      MA_MISSIONNOTESGUI('Property','Value',...) creates a new MA_MISSIONNOTESGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_MissionNotesGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_MissionNotesGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_MissionNotesGUI

% Last Modified by GUIDE v2.5 18-Jul-2015 20:44:51

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_MissionNotesGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_MissionNotesGUI_OutputFcn, ...
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


% --- Executes just before ma_MissionNotesGUI is made visible.
function ma_MissionNotesGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_MissionNotesGUI (see VARARGIN)

% Choose default command line output for ma_MissionNotesGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
handles.ma_MainGUI = varargin{1};
guidata(hObject, handles);

setupGui(handles);

% UIWAIT makes ma_MissionNotesGUI wait for user response (see UIRESUME)
% uiwait(handles.ma_MissionNotesGUI);


function setupGui(handles)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    set(handles.missionNotesText,'String',maData.notes);


% --- Outputs from this function are returned to the command line.
function varargout = ma_MissionNotesGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function missionNotesText_Callback(hObject, eventdata, handles)
% hObject    handle to missionNotesText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of missionNotesText as text
%        str2double(get(hObject,'String')) returns contents of missionNotesText as a double


% --- Executes during object creation, after setting all properties.
function missionNotesText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to missionNotesText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in saveCloseButton.
function saveCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    maData.notes = get(handles.missionNotesText,'String');
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    
    close(handles.ma_MissionNotesGUI);
