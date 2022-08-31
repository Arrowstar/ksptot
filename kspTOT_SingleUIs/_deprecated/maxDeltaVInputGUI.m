function varargout = maxDeltaVInputGUI(varargin)
% MAXDELTAVINPUTGUI MATLAB code for maxDeltaVInputGUI.fig
%      MAXDELTAVINPUTGUI, by itself, creates a new MAXDELTAVINPUTGUI or raises the existing
%      singleton*.
%
%      H = MAXDELTAVINPUTGUI returns the handle to a new MAXDELTAVINPUTGUI or the handle to
%      the existing singleton*.
%
%      MAXDELTAVINPUTGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MAXDELTAVINPUTGUI.M with the given input arguments.
%
%      MAXDELTAVINPUTGUI('Property','Value',...) creates a new MAXDELTAVINPUTGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before maxDeltaVInputGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to maxDeltaVInputGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help maxDeltaVInputGUI

% Last Modified by GUIDE v2.5 26-Jun-2013 19:03:07

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @maxDeltaVInputGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @maxDeltaVInputGUI_OutputFcn, ...
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


% --- Executes just before maxDeltaVInputGUI is made visible.
function maxDeltaVInputGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to maxDeltaVInputGUI (see VARARGIN)

% Choose default command line output for maxDeltaVInputGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%Possible fix for people with display issues.
checkForCharUnitsInGUI(hObject);

options = varargin{1};
deltaVStrName = deltaVTypeEnum(options.quant2opt);
dvTypeStr =  {'Delta-V To Optimize:', deltaVStrName};
set(handles.dvtypelabel, 'String', dvTypeStr);

% UIWAIT makes maxDeltaVInputGUI wait for user response (see UIRESUME)
uiwait(handles.maxDeltaVInputGUI);


% --- Outputs from this function are returned to the command line.
function [maxDV, varargout] = maxDeltaVInputGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
try
varargout{1} = handles.output;
maxDV = str2double(get(handles.maxDVText,'String'));
close(hObject);
catch
    varargout{1} = -1;
    maxDV = 0.0;
end


function maxDVText_Callback(hObject, eventdata, handles)
% hObject    handle to maxDVText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxDVText as text
%        str2double(get(hObject,'String')) returns contents of maxDVText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function maxDVText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxDVText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in okayButton.
function okayButton_Callback(hObject, eventdata, handles)
% hObject    handle to okayButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
errMsg = {};

maxDV = str2double(get(handles.maxDVText,'String'));
enteredStr = get(handles.maxDVText,'String');
numberName = 'Maximum delta-v';
lb = 0.01;
ub = 100;
isInt = false;
errMsg = validateNumber(maxDV, numberName, lb, ub, isInt, errMsg, enteredStr);

if(isempty(errMsg))
    uiresume(handles.maxDeltaVInputGUI);
else
    msgbox(errMsg,'Errors were found in maximum delta-v inputs','error');
end
