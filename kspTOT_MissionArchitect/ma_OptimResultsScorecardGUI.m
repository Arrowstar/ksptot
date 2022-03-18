function varargout = ma_OptimResultsScorecardGUI(varargin)
% MA_OPTIMRESULTSSCORECARDGUI MATLAB code for ma_OptimResultsScorecardGUI.fig
%      MA_OPTIMRESULTSSCORECARDGUI, by itself, creates a new MA_OPTIMRESULTSSCORECARDGUI or raises the existing
%      singleton*.
%
%      H = MA_OPTIMRESULTSSCORECARDGUI returns the handle to a new MA_OPTIMRESULTSSCORECARDGUI or the handle to
%      the existing singleton*.
%
%      MA_OPTIMRESULTSSCORECARDGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_OPTIMRESULTSSCORECARDGUI.M with the given input arguments.
%
%      MA_OPTIMRESULTSSCORECARDGUI('Property','Value',...) creates a new MA_OPTIMRESULTSSCORECARDGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_OptimResultsScorecardGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_OptimResultsScorecardGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_OptimResultsScorecardGUI

% Last Modified by GUIDE v2.5 03-Jul-2016 20:39:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_OptimResultsScorecardGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_OptimResultsScorecardGUI_OutputFcn, ...
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


% --- Executes just before ma_OptimResultsScorecardGUI is made visible.
function ma_OptimResultsScorecardGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_OptimResultsScorecardGUI (see VARARGIN)

% Choose default command line output for ma_OptimResultsScorecardGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

recorder = varargin{1};
setappdata(hObject,'recorder',recorder);

setupUI(recorder, handles);

% UIWAIT makes ma_OptimResultsScorecardGUI wait for user response (see UIRESUME)
uiwait(handles.ma_OptimResultsScorecardGUI);


function setupUI(recorder, handles)
    [finalIterNum, ~, finalFVal, finalMaxCVal] = recorder.getLastIter();
    [lowFuncIterNum, ~, lowFuncFVal, lowFuncMaxCVal] = recorder.getIterWithLowestFVal();
    [lowConstrIterNum, ~, lowConstrFVal, lowConstrMaxCVal] = recorder.getIterWithLowestCVal();
    
    set(handles.finalIterNumLabel,'String',num2str(finalIterNum));
    set(handles.finalObjFuncValueLabel,'String',fullAccNum2Str(finalFVal));
    set(handles.finalMaxConstrViolLabel,'String',fullAccNum2Str(finalMaxCVal));
    
    set(handles.lowFuncIterNumLabel,'String',num2str(lowFuncIterNum));
    set(handles.lowFuncObjFuncValueLabel,'String',fullAccNum2Str(lowFuncFVal));
    set(handles.lowFuncMaxConstrViolLabel,'String',fullAccNum2Str(lowFuncMaxCVal));
    
    set(handles.lowConstrIterNumLabel,'String',num2str(lowConstrIterNum));
    set(handles.lowConstrObjFuncValueLabel,'String',fullAccNum2Str(lowConstrFVal));
    set(handles.lowConstrMaxConstrViolLabel,'String',fullAccNum2Str(lowConstrMaxCVal));
    
    [minFVal,~] = min([finalFVal, lowFuncFVal, lowConstrFVal]);
    if(finalFVal == minFVal)
        setLabelGreen(handles.finalObjFuncValueLabel)
    end
    if(lowFuncFVal == minFVal)
        setLabelGreen(handles.lowFuncObjFuncValueLabel)
    end
    if(lowConstrFVal == minFVal)
        setLabelGreen(handles.lowConstrObjFuncValueLabel)
    end
    
    [minMaxCVal,~] = min([finalMaxCVal, lowFuncMaxCVal, lowConstrMaxCVal]);
    if(finalMaxCVal == minMaxCVal)
        setLabelGreen(handles.finalMaxConstrViolLabel)
    end
    if(lowFuncMaxCVal == minMaxCVal)
        setLabelGreen(handles.lowFuncMaxConstrViolLabel)
    end
    if(lowConstrMaxCVal == minMaxCVal)
        setLabelGreen(handles.lowConstrMaxConstrViolLabel)
    end
    
function setLabelGreen(hLabel)
    set(hLabel,'BackgroundColor',[34,139,34]/255);
    set(hLabel,'ForegroundColor',[1,1,1]);
    set(hLabel,'FontWeight','bold');
    
% --- Outputs from this function are returned to the command line.
function varargout = ma_OptimResultsScorecardGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if(isempty(handles))
    varargout{1} = [];
    varargout{2} = [];
else
    recorder = getappdata(hObject,'recorder');
    selection = getappdata(handles.ma_OptimResultsScorecardGUI,'selection');
    
    switch selection
        case 'final'
            [x, xVals] = recorder.getLastIter();
        case 'lowFunc'
            [x, xVals] = recorder.getIterWithLowestFVal();
        case 'lowConstr'
            [x, xVals] = recorder.getIterWithLowestCVal();
        case 'discard'
            x = [];
            xVals = [];
    end
    
    varargout{1} = x;
    varargout{2} = xVals;
    close(hObject);
end

% --- Executes on button press in acceptFinalIterResultsButton.
function acceptFinalIterResultsButton_Callback(hObject, eventdata, handles)
% hObject    handle to acceptFinalIterResultsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    setappdata(handles.ma_OptimResultsScorecardGUI,'selection','final');
    uiresume(handles.ma_OptimResultsScorecardGUI);

% --- Executes on button press in acceptLowestConstrViolIterationButton.
function acceptLowestConstrViolIterationButton_Callback(hObject, eventdata, handles)
% hObject    handle to acceptLowestConstrViolIterationButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    setappdata(handles.ma_OptimResultsScorecardGUI,'selection','lowConstr');
    uiresume(handles.ma_OptimResultsScorecardGUI);

% --- Executes on button press in acceptLowestFuncValueIterButton.
function acceptLowestFuncValueIterButton_Callback(hObject, eventdata, handles)
% hObject    handle to acceptLowestFuncValueIterButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    setappdata(handles.ma_OptimResultsScorecardGUI,'selection','lowFunc');
    uiresume(handles.ma_OptimResultsScorecardGUI);

% --- Executes on button press in discardOptimResultsButton.
function discardOptimResultsButton_Callback(hObject, eventdata, handles)
% hObject    handle to discardOptimResultsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    setappdata(handles.ma_OptimResultsScorecardGUI,'selection','discard');
    uiresume(handles.ma_OptimResultsScorecardGUI);
