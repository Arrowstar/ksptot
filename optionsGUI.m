function varargout = optionsGUI(varargin)
% OPTIONSGUI MATLAB code for optionsGUI.fig
%      OPTIONSGUI, by itself, creates a new OPTIONSGUI or raises the existing
%      singleton*.
%
%      H = OPTIONSGUI returns the handle to a new OPTIONSGUI or the handle to
%      the existing singleton*.
%
%      OPTIONSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in OPTIONSGUI.M with the given input arguments.
%
%      OPTIONSGUI('Property','Value',...) creates a new OPTIONSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before optionsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to optionsGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help optionsGUI

% Last Modified by GUIDE v2.5 22-Jun-2013 13:43:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @optionsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @optionsGUI_OutputFcn, ...
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


% --- Executes just before optionsGUI is made visible.
function optionsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to optionsGUI (see VARARGIN)

% Choose default command line output for optionsGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%Possible fix for people with display issues.
checkForCharUnitsInGUI(hObject);

userData = varargin{1};
set(hObject, 'UserData', userData);

options = userData{1,9};
set(handles.porkchopPtsAxesText,'String', num2str(options.porkchopPtsAxes));
set(handles.porkchopMaxDeltaV,'String', num2str(options.plotMaxDeltaV));
set(handles.porkchopNumSynPeriods,'String', num2str(options.porkchopNumSynPeriods));
set(handles.departPlotNumOptIters,'String', num2str(options.departPlotNumOptIters));
set(handles.optimizerQuantityBtnGroup,'SelectedObject', findobj(handles.optimizerQuantityBtnGroup, 'tag', options.quant2Opt));

% UIWAIT makes optionsGUI wait for user response (see UIRESUME)
uiwait(handles.optionsGUI);


% --- Outputs from this function are returned to the command line.
function [userData, varargout] = optionsGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
try
    varargout{1} = handles.output;

    userData = get(hObject, 'UserData');
    options = userData{1,9};

    options.porkchopPtsAxes = str2double(get(handles.porkchopPtsAxesText,'String'));
    options.plotMaxDeltaV = str2double(get(handles.porkchopMaxDeltaV,'String'));
    options.porkchopNumSynPeriods = str2double(get(handles.porkchopNumSynPeriods,'String'));
    options.departPlotNumOptIters = str2double(get(handles.departPlotNumOptIters,'String'));
    options.quant2Opt = get(get(handles.optimizerQuantityBtnGroup,'SelectedObject'),'tag');
    userData{1,9} = options;
    close(hObject);
catch
    varargout{1} = -1;
    userData = {};
end

function porkchopPtsAxesText_Callback(hObject, eventdata, handles)
% hObject    handle to porkchopPtsAxesText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of porkchopPtsAxesText as text
%        str2double(get(hObject,'String')) returns contents of porkchopPtsAxesText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function porkchopPtsAxesText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to porkchopPtsAxesText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function porkchopNumSynPeriods_Callback(hObject, eventdata, handles)
% hObject    handle to porkchopNumSynPeriods (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of porkchopNumSynPeriods as text
%        str2double(get(hObject,'String')) returns contents of porkchopNumSynPeriods as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function porkchopNumSynPeriods_CreateFcn(hObject, eventdata, handles)
% hObject    handle to porkchopNumSynPeriods (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function departPlotNumOptIters_Callback(hObject, eventdata, handles)
% hObject    handle to departPlotNumOptIters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of departPlotNumOptIters as text
%        str2double(get(hObject,'String')) returns contents of departPlotNumOptIters as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function departPlotNumOptIters_CreateFcn(hObject, eventdata, handles)
% hObject    handle to departPlotNumOptIters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit4_Callback(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit4 as text
%        str2double(get(hObject,'String')) returns contents of edit4 as a double


% --- Executes during object creation, after setting all properties.
function edit4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function porkchopMaxDeltaV_Callback(hObject, eventdata, handles)
% hObject    handle to porkchopMaxDeltaV (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of porkchopMaxDeltaV as text
%        str2double(get(hObject,'String')) returns contents of porkchopMaxDeltaV as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);

% --- Executes during object creation, after setting all properties.
function porkchopMaxDeltaV_CreateFcn(hObject, eventdata, handles)
% hObject    handle to porkchopMaxDeltaV (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in okButton.
function okButton_Callback(hObject, eventdata, handles)
% hObject    handle to okButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
errMsg = {};

porkchopPtsAxes = str2double(get(handles.porkchopPtsAxesText,'String'));
enteredStr = get(handles.porkchopPtsAxesText,'String');
numberName = 'Number of points per porkchop plot axis';
lb = 10;
ub = 10000;
isInt = true;
errMsg = validateNumber(porkchopPtsAxes, numberName, lb, ub, isInt, errMsg, enteredStr);

plotMaxDeltaV = str2double(get(handles.porkchopMaxDeltaV,'String'));
enteredStr = get(handles.porkchopMaxDeltaV,'String');
numberName = 'Porkchop plot maximum delta-v';
lb = 0.1;
ub = Inf;
isInt = false;
errMsg = validateNumber(plotMaxDeltaV, numberName, lb, ub, isInt, errMsg, enteredStr);

porkchopNumSynPeriods = str2double(get(handles.porkchopNumSynPeriods,'String'));
enteredStr = get(handles.porkchopNumSynPeriods,'String');
numberName = 'Number of porkchop plot synodic periods';
lb = 0.1;
ub = Inf;
isInt = false;
errMsg = validateNumber(porkchopNumSynPeriods, numberName, lb, ub, isInt, errMsg, enteredStr);

departPlotNumOptIters = str2double(get(handles.departPlotNumOptIters,'String'));
enteredStr = get(handles.departPlotNumOptIters,'String');
numberName = 'Number of departure computation search iterations';
lb = 10;
ub = 1000;
isInt = true;
errMsg = validateNumber(departPlotNumOptIters, numberName, lb, ub, isInt, errMsg, enteredStr);

if(isempty(errMsg))
    uiresume(handles.optionsGUI);
else
    msgbox(errMsg,'Errors were found in application options inputs','error');
end
