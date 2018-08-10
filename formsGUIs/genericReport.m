function varargout = genericReport(varargin)
% GENERICREPORT MATLAB code for genericReport.fig
%      GENERICREPORT, by itself, creates a new GENERICREPORT or raises the existing
%      singleton*.
%
%      H = GENERICREPORT returns the handle to a new GENERICREPORT or the handle to
%      the existing singleton*.
%
%      GENERICREPORT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GENERICREPORT.M with the given input arguments.
%
%      GENERICREPORT('Property','Value',...) creates a new GENERICREPORT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before genericReport_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to genericReport_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help genericReport

% Last Modified by GUIDE v2.5 23-Aug-2013 23:52:56

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @genericReport_OpeningFcn, ...
                   'gui_OutputFcn',  @genericReport_OutputFcn, ...
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


% --- Executes just before genericReport is made visible.
function genericReport_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to genericReport (see VARARGIN)

% Choose default command line output for genericReport
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

axis(handles.leftAxis, 'off');
axis(handles.rightAxis, 'off');

fp = fillPage(gcf, 'margins', [0 0 0 0], 'papersize', [8.5 11]);

load('genericReportPrintSetup.mat');
genericReportPrintSetup.ResolutionMode = 'manual';
genericReportPrintSetup.DPI = 1000;
genericReportPrintSetup.PrintDriver = '-dwinc';
setprinttemplate(hObject, genericReportPrintSetup);

manType = varargin{2};
generatedOn = datestr(now(), 'yyyy-mm-dd HH:MM:SS.FFF');
generatedBy = ['KSP TOT v', getKSPTOTVersionNumStr(), ' -- ', varargin{3}];
[scName, reportDesc] = basicReportInfoGUI();
headerTextBoxStr = {};
headerTextBoxStr{end+1} = manType;
headerTextBoxStr{end+1} = generatedOn;
headerTextBoxStr{end+1} = generatedBy;
headerTextBoxStr{end+1} = scName;
headerTextBoxStr{end+1} = reportDesc;
set(handles.headerTextBox, 'String', headerTextBoxStr);

% assignin('base','hFig',hObject);

% UIWAIT makes genericReport wait for user response (see UIRESUME)
% uiwait(handles.genericReportGUI);


% --- Outputs from this function are returned to the command line.
function varargout = genericReport_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
varargout{2} = handles;



function userEnteredNotesText_Callback(hObject, eventdata, handles)
% hObject    handle to userEnteredNotesText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of userEnteredNotesText as text
%        str2double(get(hObject,'String')) returns contents of userEnteredNotesText as a double


% --- Executes during object creation, after setting all properties.
function userEnteredNotesText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to userEnteredNotesText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function uipushtool1_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uipushtool1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% 
[FileName,PathName,FilterIndex] = uiputfile('*.png','Select Location To Save Report To');
% export_fig([PathName,FileName],'-png', '-r200', '-a4');
print([PathName,FileName], '-r600', '-dpng');
% printpreview();
