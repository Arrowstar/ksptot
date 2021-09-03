function varargout = basicReportInfoGUI(varargin)
% BASICREPORTINFOGUI MATLAB code for basicReportInfoGUI.fig
%      BASICREPORTINFOGUI, by itself, creates a new BASICREPORTINFOGUI or raises the existing
%      singleton*.
%
%      H = BASICREPORTINFOGUI returns the handle to a new BASICREPORTINFOGUI or the handle to
%      the existing singleton*.
%
%      BASICREPORTINFOGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BASICREPORTINFOGUI.M with the given input arguments.
%
%      BASICREPORTINFOGUI('Property','Value',...) creates a new BASICREPORTINFOGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before basicReportInfoGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to basicReportInfoGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help basicReportInfoGUI

% Last Modified by GUIDE v2.5 23-Aug-2013 18:41:16

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @basicReportInfoGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @basicReportInfoGUI_OutputFcn, ...
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


% --- Executes just before basicReportInfoGUI is made visible.
function basicReportInfoGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to basicReportInfoGUI (see VARARGIN)

% Choose default command line output for basicReportInfoGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes basicReportInfoGUI wait for user response (see UIRESUME)
uiwait(handles.reportInfoGUI);


% --- Outputs from this function are returned to the command line.
function varargout = basicReportInfoGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
try
    varargout{1} = get(handles.spacecraftNameText, 'String');
    varargout{2} = get(handles.reportDescText, 'String');
    close(hObject);
catch ME
    varargout{1} = [];
    varargout{2} = [];
end



function spacecraftNameText_Callback(hObject, eventdata, handles)
% hObject    handle to spacecraftNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of spacecraftNameText as text
%        str2double(get(hObject,'String')) returns contents of spacecraftNameText as a double


% --- Executes during object creation, after setting all properties.
function spacecraftNameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to spacecraftNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function reportDescText_Callback(hObject, eventdata, handles)
% hObject    handle to reportDescText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of reportDescText as text
%        str2double(get(hObject,'String')) returns contents of reportDescText as a double


% --- Executes during object creation, after setting all properties.
function reportDescText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to reportDescText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in saveButton.
function saveButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(handles.reportInfoGUI);

% --- Executes on button press in resetFormButton.
function resetFormButton_Callback(hObject, eventdata, handles)
% hObject    handle to resetFormButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.spacecraftNameText, 'String', '');
set(handles.reportDescText, 'String', '');