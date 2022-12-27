function varargout = lvd_builtInIntegratorOptionsGUI(varargin)
% LVD_BUILTININTEGRATOROPTIONSGUI MATLAB code for lvd_builtInIntegratorOptionsGUI.fig
%      LVD_BUILTININTEGRATOROPTIONSGUI, by itself, creates a new LVD_BUILTININTEGRATOROPTIONSGUI or raises the existing
%      singleton*.
%
%      H = LVD_BUILTININTEGRATOROPTIONSGUI returns the handle to a new LVD_BUILTININTEGRATOROPTIONSGUI or the handle to
%      the existing singleton*.
%
%      LVD_BUILTININTEGRATOROPTIONSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_BUILTININTEGRATOROPTIONSGUI.M with the given input arguments.
%
%      LVD_BUILTININTEGRATOROPTIONSGUI('Property','Value',...) creates a new LVD_BUILTININTEGRATOROPTIONSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_builtInIntegratorOptionsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_builtInIntegratorOptionsGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_builtInIntegratorOptionsGUI

% Last Modified by GUIDE v2.5 15-Feb-2020 18:38:59

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_builtInIntegratorOptionsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_builtInIntegratorOptionsGUI_OutputFcn, ...
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


% --- Executes just before lvd_builtInIntegratorOptionsGUI is made visible.
function lvd_builtInIntegratorOptionsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to lvd_builtInIntegratorOptionsGUI (see VARARGIN)

    % Choose default command line output for lvd_builtInIntegratorOptionsGUI
    handles.output = hObject;
    
    centerUIFigure(hObject);

    optionsObj = varargin{1};
    setappdata(hObject,'options',optionsObj);
    
    handles = populateGUI(optionsObj, handles);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_builtInIntegratorOptionsGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_builtInIntegratorOptionsGUI);

function handles = populateGUI(options, handles)

    setOptsDoubleValueStrInGUI(handles, options, 'AbsTol', 'absTolText');
    setOptsDoubleValueStrInGUI(handles, options, 'RelTol', 'relTolText');

    handles.normControlCheckbox.Value = double(options.NormControl);
    
    setOptsDoubleValueStrInGUI(handles, options, 'integratorStepSize', 'integratorOutputStepText');
    setOptsDoubleValueStrInGUI(handles, options, 'InitialStep', 'initialStepSizeText');
    setOptsDoubleValueStrInGUI(handles, options, 'Refine', 'refineText');
    setOptsDoubleValueStrInGUI(handles, options, 'MaxStep', 'maxStepSizeText');
    

% --- Outputs from this function are returned to the command line.
function varargout = lvd_builtInIntegratorOptionsGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        options = getappdata(hObject,'options');

        setOptsDoubleValueInObject(handles, options, 'AbsTol', 'absTolText');
        setOptsDoubleValueInObject(handles, options, 'RelTol', 'relTolText');

        options.NormControl = logical(handles.normControlCheckbox.Value);
        
        setOptsDoubleValueInObject(handles, options, 'integratorStepSize', 'integratorOutputStepText');
        setOptsDoubleValueInObject(handles, options, 'InitialStep', 'initialStepSizeText');
        setOptsDoubleValueInObject(handles, options, 'Refine', 'refineText');
        setOptsDoubleValueInObject(handles, options, 'MaxStep', 'maxStepSizeText');
        
        varargout{1} = true;
        close(handles.lvd_builtInIntegratorOptionsGUI);
    end
    
function errMsg = validateInputs(handles)
    errMsg = {};

    errMsg = validateDoubleValue(handles, errMsg, 'absTolText', 'Absolute Tolerance', 1E-12, 1E-1, false);
    errMsg = validateDoubleValue(handles, errMsg, 'relTolText', 'Relative Tolerance', 1E-12, 1E-1, false);
    errMsg = validateDoubleValue(handles, errMsg, 'integratorOutputStepText', 'Integrator Output Step', -Inf, Inf, false);
    errMsg = validateDoubleValue(handles, errMsg, 'initialStepSizeText', 'Initial Step Size', 1E-12, Inf, false);
    errMsg = validateDoubleValue(handles, errMsg, 'refineText', 'Refinement Factor', 1, Inf, true);
    errMsg = validateDoubleValue(handles, errMsg, 'maxStepSizeText', 'Maximum Step Size', 1E-12, Inf, false);

% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_builtInIntegratorOptionsGUI);
    else
        msgbox(errMsg,'Invalid Integrator Options Inputs','error');
    end


function refineText_Callback(hObject, eventdata, handles)
% hObject    handle to refineText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of refineText as text
%        str2double(get(hObject,'String')) returns contents of refineText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function refineText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to refineText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function integratorOutputStepText_Callback(hObject, eventdata, handles)
% hObject    handle to integratorOutputStepText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of integratorOutputStepText as text
%        str2double(get(hObject,'String')) returns contents of integratorOutputStepText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function integratorOutputStepText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to integratorOutputStepText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function initialStepSizeText_Callback(hObject, eventdata, handles)
% hObject    handle to initialStepSizeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of initialStepSizeText as text
%        str2double(get(hObject,'String')) returns contents of initialStepSizeText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function initialStepSizeText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to initialStepSizeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function relTolText_Callback(hObject, eventdata, handles)
% hObject    handle to relTolText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of relTolText as text
%        str2double(get(hObject,'String')) returns contents of relTolText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function relTolText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to relTolText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function absTolText_Callback(hObject, eventdata, handles)
% hObject    handle to absTolText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of absTolText as text
%        str2double(get(hObject,'String')) returns contents of absTolText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function absTolText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to absTolText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in normControlCheckbox.
function normControlCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to normControlCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of normControlCheckbox



function maxStepSizeText_Callback(hObject, eventdata, handles)
% hObject    handle to maxStepSizeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxStepSizeText as text
%        str2double(get(hObject,'String')) returns contents of maxStepSizeText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function maxStepSizeText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxStepSizeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
