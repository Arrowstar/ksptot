function varargout = departDisplayGUI(varargin)
% DEPARTDISPLAYGUI MATLAB code for departDisplayGUI.fig
%      DEPARTDISPLAYGUI, by itself, creates a new DEPARTDISPLAYGUI or raises the existing
%      singleton*.
%
%      H = DEPARTDISPLAYGUI returns the handle to a new DEPARTDISPLAYGUI or the handle to
%      the existing singleton*.
%
%      DEPARTDISPLAYGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DEPARTDISPLAYGUI.M with the given input arguments.
%
%      DEPARTDISPLAYGUI('Property','Value',...) creates a new DEPARTDISPLAYGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before departDisplayGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to departDisplayGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help departDisplayGUI

% Last Modified by GUIDE v2.5 02-Dec-2013 19:58:32

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @departDisplayGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @departDisplayGUI_OutputFcn, ...
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


% --- Executes just before departDisplayGUI is made visible.
function departDisplayGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to departDisplayGUI (see VARARGIN)

% Choose default command line output for departDisplayGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%Possible fix for people with display issues.
% checkForCharUnitsInGUI(hObject);

% UIWAIT makes departDisplayGUI wait for user response (see UIRESUME)
% uiwait(handles.departDispGUI);


% --- Outputs from this function are returned to the command line.
function [dummy, varargout] = departDisplayGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

dummy{1} = handles.departAxis;
dummy{2} = handles.hyperOrbitText;
dummy{3} = handles.mainOrbitText;
dummy{4} = handles.burnInfoText;
dummy{5} = handles.departDispGUI;
dummy{6} = handles.hyperOrbitLabel;
dummy{7} = handles.transOrbitLabel;
dummy{8} = handles.departureOrbitRadio;

function hyperOrbitText_Callback(hObject, eventdata, handles)
% hObject    handle to hyperOrbitText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hyperOrbitText as text
%        str2double(get(hObject,'String')) returns contents of hyperOrbitText as a double


% --- Executes during object creation, after setting all properties.
function hyperOrbitText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hyperOrbitText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function burnInfoText_Callback(hObject, eventdata, handles)
% hObject    handle to burnInfoText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of burnInfoText as text
%        str2double(get(hObject,'String')) returns contents of burnInfoText as a double


% --- Executes during object creation, after setting all properties.
function burnInfoText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to burnInfoText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function mainOrbitText_Callback(hObject, eventdata, handles)
% hObject    handle to mainOrbitText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of mainOrbitText as text
%        str2double(get(hObject,'String')) returns contents of mainOrbitText as a double


% --- Executes during object creation, after setting all properties.
function mainOrbitText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mainOrbitText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when selected object is changed in plotDisplayPanel.
function plotDisplayPanel_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in plotDisplayPanel 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
hPlotBtnGrp = findobj(handles.departDispGUI,'Tag','plotDisplayPanel');
hTypeBtn = get(hPlotBtnGrp,'SelectedObject');
plotType = get(hTypeBtn, 'Tag');

departAxis = handles.departAxis;
axisUserData = get(departAxis,'UserData');
reset(departAxis);
set(departAxis,'UserData',axisUserData);
hLegend = findobj(handles.departDispGUI,'Type','axes','Tag','legend');
delete(hLegend);

switch plotType
    case 'departureOrbitRadio'
        plotBodyDepartOrbit(departAxis)
    case 'transferOrbitRadio'
        plotTransferOrbit(departAxis)
end


% --------------------------------------------------------------------
function generateReport_Callback(hObject, eventdata, handles)
% hObject    handle to generateReport (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[hReport, handlesR] = genericReport(1, 'SINGLE DELTA-V MANEUVER', 'BALLISTIC TRANSFER APPLICATION');

    set(handlesR.rightTextBoxLabel,'String', 'Transfer Orbit Details');

    results = get(handles.departDispGUI,'UserData');
    results = results{1};

    paddLen = 29;
    form = '%9.5f';
    burnInfoTextstr = {};
    burnInfoTextstr{end+1} = [paddStr('Total Delta-V = ',paddLen), num2str(norm(results.burnVect), form), ' km/s'];
    burnInfoTextstr{end+1} = [paddStr('Prograde Delta-V = ',paddLen), num2str(1000*results.burnVect(1), form), ' m/s'];
    burnInfoTextstr{end+1} = [paddStr('Radial Delta-V = ',paddLen), num2str(1000*results.burnVect(3), form), ' m/s'];
    burnInfoTextstr{end+1} = [paddStr('Orbit Normal Delta-V = ',paddLen), num2str(1000*results.burnVect(2), form), ' m/s'];
    burnInfoTextstr{end+1} = '---------------------';
    burnInfoTextstr{end+1} = [paddStr('Departure True Anomaly = ',paddLen), num2str(rad2deg(results.burnTA), form), ' deg'];
    
    if(isfield(results,'burnTimeBeforePeri'))
        burnInfoTextstr{end+1} = [paddStr('Burn Time Before Peri. = ',paddLen), num2str(results.burnTimeBeforePeri, form), ' sec'];
    end
    
    if(isfield(results,'burnTimePastPeri'))
        burnInfoTextstr{end+1} = [paddStr('Burn Time Past Peri. = ',paddLen), num2str(results.burnTimeBeforePeri, form), ' sec'];
    end
    
    if(isfield(results,'iniOrbitPeriod'))
        burnInfoTextstr{end+1} = [paddStr('Ini. Orbit Period = ',paddLen), num2str(results.iniOrbitPeriod, form), ' sec'];
    end
    set(handlesR.leftTextBox, 'String', burnInfoTextstr);
    
    paddLen = 30;
    xferOrbitText = {};
    xferOrbitText{end+1} = ['Transfer Orbit about ', cap1stLetter(results.xferOrbitCBName)];
    xferOrbitText{end+1} = '-----------------------------------------------';
    xferOrbitText{end+1} = [paddStr('Semi-major Axis = ',paddLen), num2str(results.xferOrbit(1), form), ' km'];
    xferOrbitText{end+1} = [paddStr('Eccentricity = ', paddLen), num2str(results.xferOrbit(2))];
    xferOrbitText{end+1} = [paddStr('Inclination = ',paddLen), num2str(rad2deg(AngleZero2Pi(results.xferOrbit(3))), form), ' deg'];
    xferOrbitText{end+1} = [paddStr('Right Ascension of AN = ',paddLen), num2str(rad2deg(AngleZero2Pi(results.xferOrbit(4))), form), ' deg'];
    xferOrbitText{end+1} = [paddStr('Argument of Periapse = ',paddLen), num2str(rad2deg(AngleZero2Pi(results.xferOrbit(5))), form), ' deg'];
    xferOrbitText{end+1} = [paddStr([cap1stLetter(results.departBodyName), ' Depart True Anomaly = '],paddLen), num2str(rad2deg(AngleZero2Pi(results.xferOrbit(6))), form), ' deg'];
    xferOrbitText{end+1} = [paddStr([cap1stLetter(results.arrivalBodyName), ' Arrive True Anomaly = '],paddLen), num2str(rad2deg(AngleZero2Pi(results.xferOrbit(7))), form), ' deg'];
    
    set(handlesR.rightTextBox, 'String', xferOrbitText);
    
    set(handlesR.leftAxis,'UserData',results.axisUserData);
    set(handlesR.rightAxis,'UserData',results.axisUserData);
    
    plotBodyDepartOrbit(handlesR.leftAxis);
    plotTransferOrbit(handlesR.rightAxis, false);
    


% --------------------------------------------------------------------
function uploadManeuver_Callback(hObject, eventdata, handles)
% hObject    handle to uploadManeuver (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
guiData = get(handles.burnInfoText,'UserData');
uploadManeuverToKSP(guiData);
