function varargout = ma_ObserveOptimGUI(varargin)
% MA_OBSERVEOPTIMGUI MATLAB code for ma_ObserveOptimGUI.fig
%      MA_OBSERVEOPTIMGUI, by itself, creates a new MA_OBSERVEOPTIMGUI or raises the existing
%      singleton*.
%
%      H = MA_OBSERVEOPTIMGUI returns the handle to a new MA_OBSERVEOPTIMGUI or the handle to
%      the existing singleton*.
%
%      MA_OBSERVEOPTIMGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_OBSERVEOPTIMGUI.M with the given input arguments.
%
%      MA_OBSERVEOPTIMGUI('Property','Value',...) creates a new MA_OBSERVEOPTIMGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_ObserveOptimGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_ObserveOptimGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_ObserveOptimGUI

% Last Modified by GUIDE v2.5 02-Jan-2019 21:49:18

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_ObserveOptimGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_ObserveOptimGUI_OutputFcn, ...
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


% --- Executes just before ma_ObserveOptimGUI is made visible.
function ma_ObserveOptimGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_ObserveOptimGUI (see VARARGIN)

% Choose default command line output for ma_ObserveOptimGUI
handles.output = hObject;

celBodyData = varargin{1};
problem = varargin{2};

if(length(varargin) >= 3)
    isLVD = varargin{3};
else
    isLVD = true;
end

if(length(varargin) >= 4)
    writeOutput = varargin{4};    
end

propNames = {'Liquid Fuel/Ox','Monopropellant','Xenon'};
if(length(varargin) >= 5)
    handles.ma_MainGUI = varargin{5};  
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    propNames = maData.spacecraft.propellant.names;
end

% Update handles structure
guidata(hObject, handles);

set(hObject, 'Visible','on');
set(handles.cancelButton,'UserData',false);
drawnow;

set(handles.dispAxes,'XTickLabel',[]);
set(handles.dispAxes,'YTickLabel',[]);
set(handles.dispAxes,'ZTickLabel',[]);
set(handles.dispAxes,'Visible','off');
drawnow;

% celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
recorder = ma_OptimRecorder();
outputFnc = @(x, optimValues, state) ma_OptimOutputFunc(x, optimValues, state, handles, problem, celBodyData, recorder, propNames, writeOutput);
problem.options.OutputFcn = outputFnc;

if(not(isLVD))
    executeOptimProblem(handles, problem, recorder);
else
    lvd_executeOptimProblem(celBodyData, writeOutput, problem, recorder);
end

close(handles.ma_ObserveOptimGUI);

% UIWAIT makes ma_ObserveOptimGUI wait for user response (see UIRESUME)
% uiwait(handles.ma_ObserveOptimGUI);


        

% --- Outputs from this function are returned to the command line.
function varargout = ma_ObserveOptimGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = [];


% --- Executes on button press in pauseButton.
function pauseButton_Callback(hObject, eventdata, handles)
% hObject    handle to pauseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    h = msgbox('Optimization has been paused.  Push OK to continue.','Paused','help','modal');
    uiwait(h);

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    set(handles.cancelButton,'UserData',true);


% --- Executes on mouse motion over figure - except title and menu.
function ma_ObserveOptimGUI_WindowButtonMotionFcn(hObject, eventdata, handles)
% hObject    handle to ma_ObserveOptimGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
