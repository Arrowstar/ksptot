function varargout = lvd_fixedStepSizeIntegratorOptionsGUI(varargin)
% LVD_FIXEDSTEPSIZEINTEGRATOROPTIONSGUI MATLAB code for lvd_fixedStepSizeIntegratorOptionsGUI.fig
%      LVD_FIXEDSTEPSIZEINTEGRATOROPTIONSGUI, by itself, creates a new LVD_FIXEDSTEPSIZEINTEGRATOROPTIONSGUI or raises the existing
%      singleton*.
%
%      H = LVD_FIXEDSTEPSIZEINTEGRATOROPTIONSGUI returns the handle to a new LVD_FIXEDSTEPSIZEINTEGRATOROPTIONSGUI or the handle to
%      the existing singleton*.
%
%      LVD_FIXEDSTEPSIZEINTEGRATOROPTIONSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_FIXEDSTEPSIZEINTEGRATOROPTIONSGUI.M with the given input arguments.
%
%      LVD_FIXEDSTEPSIZEINTEGRATOROPTIONSGUI('Property','Value',...) creates a new LVD_FIXEDSTEPSIZEINTEGRATOROPTIONSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_fixedStepSizeIntegratorOptionsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_fixedStepSizeIntegratorOptionsGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_fixedStepSizeIntegratorOptionsGUI

% Last Modified by GUIDE v2.5 06-Mar-2020 17:08:32

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_fixedStepSizeIntegratorOptionsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_fixedStepSizeIntegratorOptionsGUI_OutputFcn, ...
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


% --- Executes just before lvd_fixedStepSizeIntegratorOptionsGUI is made visible.
function lvd_fixedStepSizeIntegratorOptionsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to lvd_fixedStepSizeIntegratorOptionsGUI (see VARARGIN)

    % Choose default command line output for lvd_fixedStepSizeIntegratorOptionsGUI
    handles.output = hObject;

    optionsObj = varargin{1};
    setappdata(hObject,'options',optionsObj);
    
    handles = populateGUI(optionsObj, handles);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_fixedStepSizeIntegratorOptionsGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_builtInIntegratorOptionsGUI);

function handles = populateGUI(options, handles)   
    setOptsDoubleValueStrInGUI(handles, options, 'integratorStepSize', 'integratorOutputStepText');
    

% --- Outputs from this function are returned to the command line.
function varargout = lvd_fixedStepSizeIntegratorOptionsGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        options = getappdata(hObject,'options');
        
        setOptsDoubleValueInObject(handles, options, 'integratorStepSize', 'integratorOutputStepText');
        
        varargout{1} = true;
        close(handles.lvd_builtInIntegratorOptionsGUI);
    end
    
function errMsg = validateInputs(handles)
    errMsg = {};

    errMsg = validateDoubleValue(handles, errMsg, 'integratorOutputStepText', 'Integrator Output Step', 1E-6, Inf, false);


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
