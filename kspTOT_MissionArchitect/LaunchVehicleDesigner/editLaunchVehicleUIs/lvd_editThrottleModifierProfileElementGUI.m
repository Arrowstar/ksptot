function varargout = lvd_editThrottleModifierProfileElementGUI(varargin)
% LVD_EDITTHROTTLEMODIFIERPROFILEELEMENTGUI MATLAB code for lvd_editThrottleModifierProfileElementGUI.fig
%      LVD_EDITTHROTTLEMODIFIERPROFILEELEMENTGUI, by itself, creates a new LVD_EDITTHROTTLEMODIFIERPROFILEELEMENTGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITTHROTTLEMODIFIERPROFILEELEMENTGUI returns the handle to a new LVD_EDITTHROTTLEMODIFIERPROFILEELEMENTGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITTHROTTLEMODIFIERPROFILEELEMENTGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITTHROTTLEMODIFIERPROFILEELEMENTGUI.M with the given input arguments.
%
%      LVD_EDITTHROTTLEMODIFIERPROFILEELEMENTGUI('Property','Value',...) creates a new LVD_EDITTHROTTLEMODIFIERPROFILEELEMENTGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_editThrottleModifierProfileElementGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_editThrottleModifierProfileElementGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_editThrottleModifierProfileElementGUI

% Last Modified by GUIDE v2.5 07-Jan-2019 18:00:06

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_editThrottleModifierProfileElementGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_editThrottleModifierProfileElementGUI_OutputFcn, ...
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


% --- Executes just before lvd_editThrottleModifierProfileElementGUI is made visible.
function lvd_editThrottleModifierProfileElementGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to lvd_editThrottleModifierProfileElementGUI (see VARARGIN)

    % Choose default command line output for lvd_editThrottleModifierProfileElementGUI
    handles.output = hObject;

    elem = varargin{1};
    setappdata(hObject,'elem',elem);
    
    allowFuPctEdit = varargin{2};
    setappdata(hObject,'allowFuPctEdit',allowFuPctEdit);
    
    % Update handles structure
    guidata(hObject, handles);
    
    populateUI(elem, allowFuPctEdit, handles);

    % UIWAIT makes lvd_editThrottleModifierProfileElementGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_editThrottleModifierProfileElementGUI);

    
function populateUI(elem, allowFuPctEdit, handles)
    handles.fuRemainPctText.String = fullAccNum2Str(100*elem.fuelRemainPct); %percent
    handles.throtModifierText.String = fullAccNum2Str(elem.throttleModifier);
    
    if(allowFuPctEdit == false)
        handles.fuRemainPctText.Enable = 'off';
    end
    

% --- Outputs from this function are returned to the command line.
function varargout = lvd_editThrottleModifierProfileElementGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        elem = getappdata(hObject,'elem');
        elem.fuelRemainPct = str2double(handles.fuRemainPctText.String)/100;
        elem.throttleModifier = str2double(handles.throtModifierText.String);
        
        varargout{1} = true;
        close(handles.lvd_editThrottleModifierProfileElementGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_editThrottleModifierProfileElementGUI);
    else
        msgbox(errMsg,'Invalid Inputs','error');
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    
    val = str2double(get(handles.fuRemainPctText,'String'));
    enteredStr = get(handles.fuRemainPctText,'String');
    numberName = 'Fuel Remaining';
    lb = 0;
    ub = 100;
    isInt = false;
    errMsg = validateNumber(val, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        elem = getappdata(handles.lvd_editThrottleModifierProfileElementGUI,'elem');
        
        if((val == 0 || val == 100) && 100*elem.fuelRemainPct ~= val)
            errMsg = {'Cannot add points at 0% or 100%.  Edit these points from the existing list if necessary.'};
        end
    end
    
    val = str2double(get(handles.throtModifierText,'String'));
    enteredStr = get(handles.throtModifierText,'String');
    numberName = 'Throttle Modifier';
    lb = 0;
    ub = 1;
    isInt = false;
    errMsg = validateNumber(val, numberName, lb, ub, isInt, errMsg, enteredStr);

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_editThrottleModifierProfileElementGUI);


function fuRemainPctText_Callback(hObject, eventdata, handles)
% hObject    handle to fuRemainPctText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fuRemainPctText as text
%        str2double(get(hObject,'String')) returns contents of fuRemainPctText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function fuRemainPctText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fuRemainPctText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function throtModifierText_Callback(hObject, eventdata, handles)
% hObject    handle to throtModifierText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of throtModifierText as text
%        str2double(get(hObject,'String')) returns contents of throtModifierText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function throtModifierText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to throtModifierText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
