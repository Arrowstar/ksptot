function varargout = lvd_finiteDiffOptionsGUI(varargin)
% LVD_FINITEDIFFOPTIONSGUI MATLAB code for lvd_finiteDiffOptionsGUI.fig
%      LVD_FINITEDIFFOPTIONSGUI, by itself, creates a new LVD_FINITEDIFFOPTIONSGUI or raises the existing
%      singleton*.
%
%      H = LVD_FINITEDIFFOPTIONSGUI returns the handle to a new LVD_FINITEDIFFOPTIONSGUI or the handle to
%      the existing singleton*.
%
%      LVD_FINITEDIFFOPTIONSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_FINITEDIFFOPTIONSGUI.M with the given input arguments.
%
%      LVD_FINITEDIFFOPTIONSGUI('Property','Value',...) creates a new LVD_FINITEDIFFOPTIONSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_finiteDiffOptionsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_finiteDiffOptionsGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_finiteDiffOptionsGUI

% Last Modified by GUIDE v2.5 08-Feb-2020 12:12:32

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_finiteDiffOptionsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_finiteDiffOptionsGUI_OutputFcn, ...
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


% --- Executes just before lvd_finiteDiffOptionsGUI is made visible.
function lvd_finiteDiffOptionsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_finiteDiffOptionsGUI (see VARARGIN)

    % Choose default command line output for lvd_finiteDiffOptionsGUI
    handles.output = hObject;
    
    finDiffObj = varargin{1};
    setappdata(hObject,'finDiffObj',finDiffObj);

    populateGUI(handles, finDiffObj);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_finiteDiffOptionsGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_finiteDiffOptionsGUI);
    
function handles = populateGUI(handles, finDiffObj)
    handles.pertStepHText.String = fullAccNum2Str(finDiffObj.h);
    handles.numPointsText.String = fullAccNum2Str(double(finDiffObj.numPts));

    typeListboxStr = FiniteDiffTypeEnum.getListBoxStr();
    handles.finDiffTypeCombo.String = typeListboxStr;
    handles.finDiffTypeCombo.Value = FiniteDiffTypeEnum.getIndForName(finDiffObj.diffType.name);
    
    if(finDiffObj.shouldComputeSparsity())
        handles.computeSparsityCheckbox.Value = 1;
    else
        handles.computeSparsityCheckbox.Value = 0;
    end

% --- Outputs from this function are returned to the command line.
function varargout = lvd_finiteDiffOptionsGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        finDiffObj = getappdata(handles.lvd_finiteDiffOptionsGUI,'finDiffObj');
        
        finDiffObj.h = str2double(handles.pertStepHText.String);
        finDiffObj.numPts = str2double(handles.numPointsText.String);
        
        typeListboxStr = FiniteDiffTypeEnum.getListBoxStr();
        finDiffObj.diffType = FiniteDiffTypeEnum.getEnumForListboxStr(typeListboxStr{handles.finDiffTypeCombo.Value});
        
        computeSparsity = logical(handles.computeSparsityCheckbox.Value);
        finDiffObj.computeSparsity = computeSparsity;
        
        close(handles.lvd_finiteDiffOptionsGUI);
        varargout{1} = true;
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    
    errMsg = validateDoubleValue(handles, errMsg, 'pertStepHText', 'Normalized Perturbation Step', 1E-10, 1E-1, false);
    errMsg = validateDoubleValue(handles, errMsg, 'numPointsText', 'Number of Points', 2, Inf, true);

% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_finiteDiffOptionsGUI);
    else
        msgbox(errMsg,'Invalid Finite Differences Options Inputs','error');
    end


function pertStepHText_Callback(hObject, eventdata, handles)
% hObject    handle to pertStepHText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pertStepHText as text
%        str2double(get(hObject,'String')) returns contents of pertStepHText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function pertStepHText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pertStepHText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in finDiffTypeCombo.
function finDiffTypeCombo_Callback(hObject, eventdata, handles)
% hObject    handle to finDiffTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns finDiffTypeCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from finDiffTypeCombo


% --- Executes during object creation, after setting all properties.
function finDiffTypeCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to finDiffTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function numPointsText_Callback(hObject, eventdata, handles)
% hObject    handle to numPointsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numPointsText as text
%        str2double(get(hObject,'String')) returns contents of numPointsText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function numPointsText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numPointsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in computeSparsityCheckbox.
function computeSparsityCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to computeSparsityCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of computeSparsityCheckbox
