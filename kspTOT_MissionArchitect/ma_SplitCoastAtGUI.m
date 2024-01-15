function varargout = ma_SplitCoastAtGUI(varargin)
% MA_SPLITCOASTATGUI MATLAB code for ma_SplitCoastAtGUI.fig
%      MA_SPLITCOASTATGUI, by itself, creates a new MA_SPLITCOASTATGUI or raises the existing
%      singleton*.
%
%      H = MA_SPLITCOASTATGUI returns the handle to a new MA_SPLITCOASTATGUI or the handle to
%      the existing singleton*.
%
%      MA_SPLITCOASTATGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_SPLITCOASTATGUI.M with the given input arguments.
%
%      MA_SPLITCOASTATGUI('Property','Value',...) creates a new MA_SPLITCOASTATGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_SplitCoastAtGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_SplitCoastAtGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_SplitCoastAtGUI

% Last Modified by GUIDE v2.5 22-Apr-2015 16:54:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_SplitCoastAtGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_SplitCoastAtGUI_OutputFcn, ...
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


% --- Executes just before ma_SplitCoastAtGUI is made visible.
function ma_SplitCoastAtGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_SplitCoastAtGUI (see VARARGIN)

% Choose default command line output for ma_SplitCoastAtGUI
handles.output = hObject;
handles.ma_MainGUI = varargin{1};
type = varargin{2};
minMax = varargin{3};

set(handles.splitAtText,'UserData',minMax);

% Update handles structure
guidata(hObject, handles);

setUpGUIForType(handles, type, minMax);

% UIWAIT makes ma_SplitCoastAtGUI wait for user response (see UIRESUME)
uiwait(handles.ma_SplitCoastAtGUI);

function setUpGUIForType(handles, type, minMax)
    switch type
        case 'UT'
            titleLabel = 'Split Coast at UT';
            minHeaderLabel = 'Minimum UT';
            minLabel = num2str(minMax(1));
            splitHeaderLabel = 'Split Coast At UT';
            maxHeaderLabel = 'Maximum UT';
            maxLabel = num2str(minMax(2));
            
            [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(minMax(1));
            epochStr = formDateStr(year, day, hour, minute, sec);
            minTooltipStr = epochStr;
            
            [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(minMax(2));
            epochStr = formDateStr(year, day, hour, minute, sec);
            maxTooltipStr = epochStr;
            
            set(handles.splitAtText,'String',fullAccNum2Str(minMax(1)));
            
            getUtTTS = @(a,b) getUtTextTooltip(a,b,handles.splitAtText);
            getUtTTS([],[]);
            
            hcmenu = uicontextmenu(handles.ma_SplitCoastAtGUI);
            hcb1 = @(a,b) getUtAsDateTime(a,b,handles.splitAtText);
            item1 = uimenu(hcmenu,'Label','Enter UT as Date/Time','Callback',hcb1);
            set(handles.splitAtText,'uicontextmenu',hcmenu,'Callback',getUtTTS);
            
            unit = 'sec';
        case 'Tru'
            titleLabel = 'Split Coast at True Anom.';
            minHeaderLabel = 'Minimum True Anomaly';
            minLabel = num2str(minMax(1));
            splitHeaderLabel = 'Split Coast At True Anomaly';
            maxHeaderLabel = 'Maximum True Anomaly';
            maxLabel = num2str(minMax(2));
            
            minTooltipStr = '';
            maxTooltipStr = '';
            
            unit = 'deg';
    end
    
    set(handles.titleLabel,'String',titleLabel);
    set(handles.minHeaderLabel,'String',minHeaderLabel);
    set(handles.minLabel,'String',minLabel);
    set(handles.minLabel,'TooltipString',minTooltipStr);
    
    set(handles.splitHeaderLabel,'String',splitHeaderLabel);
    set(handles.maxHeaderLabel,'String',maxHeaderLabel);
    set(handles.maxLabel,'String',maxLabel);
    set(handles.maxLabel,'TooltipString',maxTooltipStr);
    
    set(handles.minUnitLabel,'String',unit);
    set(handles.splitHeaderUnitLabel,'String',unit);
    set(handles.maxUnitLabel,'String',unit);


function getUtAsDateTime(~,~,hText)
    secUT = fullAccNum2Str(enterUTAsDateTimeGUI(str2double(get(gco, 'String'))));
    set(hText,'String',secUT);
    
    
function getUtTextTooltip(~,~,hText)
    ut = str2double(get(hText,'String'));
    [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(ut);
    [dateStr] = formDateStr(year, day, hour, minute, sec);
    set(hText,'TooltipString',dateStr);
    

% --- Outputs from this function are returned to the command line.
function varargout = ma_SplitCoastAtGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if(isempty(handles))
    varargout{1} = [];
else
    varargout{1} = str2double(get(handles.splitAtText,'String'));
    close(hObject);
end



function splitAtText_Callback(hObject, eventdata, handles)
% hObject    handle to splitAtText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of splitAtText as text
%        str2double(get(hObject,'String')) returns contents of splitAtText as a double


% --- Executes during object creation, after setting all properties.
function splitAtText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to splitAtText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);

    if(isempty(errMsg))
        uiresume(handles.ma_SplitCoastAtGUI);
    else
        msgbox(errMsg,'Errors were found while validating your split value.  Please sure value is between the given bounds.','error');
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    
    minMax = get(handles.splitAtText,'UserData');
    
    value = str2double(get(handles.splitAtText,'String'));
    enteredStr = get(handles.splitAtText,'String');
    numberName = 'Input Split Value';
    lb = minMax(1);
    ub = minMax(2);
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);


% --- Executes on key press with focus on ma_SplitCoastAtGUI and none of its controls.
function ma_SplitCoastAtGUI_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to ma_SplitCoastAtGUI (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    if(strcmpi(eventdata.Key,'return'))
        saveAndCloseButton_Callback(handles.saveAndCloseButton, [], handles);
    end


% --- Executes on key press with focus on ma_SplitCoastAtGUI or any of its controls.
function ma_SplitCoastAtGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to ma_SplitCoastAtGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'escape'
            close(handles.ma_SplitCoastAtGUI);
    end