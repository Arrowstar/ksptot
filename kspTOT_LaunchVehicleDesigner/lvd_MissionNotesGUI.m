function varargout = lvd_MissionNotesGUI(varargin)
% LVD_MISSIONNOTESGUI MATLAB code for lvd_MissionNotesGUI.fig
%      LVD_MISSIONNOTESGUI, by itself, creates a new LVD_MISSIONNOTESGUI or raises the existing
%      singleton*.
%
%      H = LVD_MISSIONNOTESGUI returns the handle to a new LVD_MISSIONNOTESGUI or the handle to
%      the existing singleton*.
%
%      LVD_MISSIONNOTESGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_MISSIONNOTESGUI.M with the given input arguments.
%
%      LVD_MISSIONNOTESGUI('Property','Value',...) creates a new LVD_MISSIONNOTESGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_MissionNotesGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_MissionNotesGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_MissionNotesGUI

% Last Modified by GUIDE v2.5 31-Mar-2019 11:56:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_MissionNotesGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_MissionNotesGUI_OutputFcn, ...
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


% --- Executes just before lvd_MissionNotesGUI is made visible.
function lvd_MissionNotesGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to lvd_MissionNotesGUI (see VARARGIN)

% Choose default command line output for lvd_MissionNotesGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
setappdata(hObject, 'lvdData', varargin{1});
guidata(hObject, handles);

setupGui(handles);

% UIWAIT makes lvd_MissionNotesGUI wait for user response (see UIRESUME)
% uiwait(handles.lvd_MissionNotesGUI);


function setupGui(handles)
    lvdData = getappdata(handles.lvd_MissionNotesGUI, 'lvdData');
    set(handles.missionNotesText,'String',lvdData.notes);


% --- Outputs from this function are returned to the command line.
function varargout = lvd_MissionNotesGUI_OutputFcn(hObject, eventdata, handles) 
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
    lvdData = getappdata(handles.lvd_MissionNotesGUI, 'lvdData');
    lvdData.notes = get(handles.missionNotesText,'String');
    
    close(handles.lvd_MissionNotesGUI);
