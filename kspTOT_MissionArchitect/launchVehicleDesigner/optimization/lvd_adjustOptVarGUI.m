function varargout = lvd_adjustOptVarGUI(varargin)
% LVD_ADJUSTOPTVARGUI MATLAB code for lvd_adjustOptVarGUI.fig
%      LVD_ADJUSTOPTVARGUI, by itself, creates a new LVD_ADJUSTOPTVARGUI or raises the existing
%      singleton*.
%
%      H = LVD_ADJUSTOPTVARGUI returns the handle to a new LVD_ADJUSTOPTVARGUI or the handle to
%      the existing singleton*.
%
%      LVD_ADJUSTOPTVARGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_ADJUSTOPTVARGUI.M with the given input arguments.
%
%      LVD_ADJUSTOPTVARGUI('Property','Value',...) creates a new LVD_ADJUSTOPTVARGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_adjustOptVarGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_adjustOptVarGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_adjustOptVarGUI

% Last Modified by GUIDE v2.5 23-Jan-2020 20:18:05

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_adjustOptVarGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_adjustOptVarGUI_OutputFcn, ...
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


% --- Executes just before lvd_adjustOptVarGUI is made visible.
function lvd_adjustOptVarGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to lvd_adjustOptVarGUI (see VARARGIN)

    % Choose default command line output for lvd_adjustOptVarGUI
    handles.output = hObject;
    
    lvdData = varargin{1};
    setappdata(hObject,'lvdData',lvdData);
    
    propScriptFcn = varargin{2};
    setappdata(hObject,'propScriptFcn',propScriptFcn);
    
    procDataFcn = varargin{3};
    setappdata(hObject,'procDataFcn',procDataFcn);
    
    lvdOpt = lvdData.optimizer;
    varSet = lvdOpt.vars;
    [xVectScaled, ~, ~, ~] = varSet.getTotalScaledXVector();
    setappdata(hObject,'origScaledXVect',xVectScaled);

    populateGUI(handles, lvdData, 1); %just close and throw an error if no variables enabled in LVD GUI
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_adjustOptVarGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_adjustOptVarGUI);
    
function populateGUI(handles, lvdData, value)
    lvdOpt = lvdData.optimizer;
    varSet = lvdOpt.vars;
    [~, ~, varNameStrs, xUnscaled] = varSet.getTotalScaledXVector();
    [~, ~, lwrBndsUnscaled, uprBndsUnscaled] = varSet.getTotalScaledBndsVector();
    
    handles.variablesCombo.String = varNameStrs;
    handles.variablesCombo.Value = value;
    handles.varValueText.String = fullAccNum2Str(xUnscaled(value));
    handles.varLowerBndLabel.String = fullAccNum2Str(lwrBndsUnscaled(value));
    handles.varUpperBndLabel.String = fullAccNum2Str(uprBndsUnscaled(value));
    handles.varValueSlider.Value = scaleXToNeg1And1(xUnscaled(value), lwrBndsUnscaled(value), uprBndsUnscaled(value));
    
function xScaled = scaleXToNeg1And1(xi, lbi, ubi)
    bndDiff = ubi - lbi;
    bndCenter = (lbi + ubi)/2;
    xScaled = (xi - bndCenter)/(bndDiff/2);
    

function xUnscaled = unscaleXFromNeg1And(xSi, lbi, ubi)
    bndDiff = ubi - lbi;
    bndCenter = (lbi + ubi)/2;

    if(bndDiff > 1E-10)
        xUnscaled = xSi * (bndDiff/2) + bndCenter;
    end
    
    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_adjustOptVarGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else 
        varargout{1} = true;
        close(handles.lvd_adjustOptVarGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.lvd_adjustOptVarGUI);

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_adjustOptVarGUI,'lvdData');
    lvdOpt = lvdData.optimizer;
    varSet = lvdOpt.vars;
    
    origScaledXVect = getappdata(handles.lvd_adjustOptVarGUI,'origScaledXVect');
    varSet.updateObjsWithScaledVarValues(origScaledXVect);
    
    close(handles.lvd_adjustOptVarGUI);
    
% --- Executes on selection change in variablesCombo.
function variablesCombo_Callback(hObject, eventdata, handles)
% hObject    handle to variablesCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns variablesCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from variablesCombo
    lvdData = getappdata(handles.lvd_adjustOptVarGUI,'lvdData');
    value = handles.variablesCombo.Value;
    populateGUI(handles, lvdData, value);

% --- Executes during object creation, after setting all properties.
function variablesCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to variablesCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function varValueSlider_Callback(hObject, eventdata, handles)
% hObject    handle to varValueSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    processUserChangeToVar(handles);
    
function processUserChangeToVar(handles)
    propScriptFcn = getappdata(handles.lvd_adjustOptVarGUI,'propScriptFcn');
    procDataFcn = getappdata(handles.lvd_adjustOptVarGUI,'procDataFcn');
    lvdData = getappdata(handles.lvd_adjustOptVarGUI,'lvdData');
    lvdOpt = lvdData.optimizer;
    varSet = lvdOpt.vars;
    [xVectScaled, ~, ~, ~] = varSet.getTotalScaledXVector();
    [~, ~, lwrBndsUnscaled, uprBndsUnscaled] = varSet.getTotalScaledBndsVector();
    
    value = handles.variablesCombo.Value;
    xScaled = handles.varValueSlider.Value;
    xUnscaled = unscaleXFromNeg1And(xScaled, lwrBndsUnscaled(value), uprBndsUnscaled(value));
    
    xVectScaledUpdated = xVectScaled;
    xVectScaledUpdated(value) = xScaled;
    
    handles.varValueText.String = fullAccNum2Str(xUnscaled);
    
    varSet.updateObjsWithScaledVarValues(xVectScaledUpdated);
    propScriptFcn();
    procDataFcn();
    
% --- Executes during object creation, after setting all properties.
function varValueSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to varValueSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on key press with focus on lvd_adjustOptVarGUI or any of its controls.
function lvd_adjustOptVarGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_adjustOptVarGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            saveAndCloseButton_Callback(handles.saveAndCloseButton, [], handles);
        case 'enter'
            saveAndCloseButton_Callback(handles.saveAndCloseButton, [], handles);
        case 'escape'
            cancelButton_Callback(handles.cancelButton, [], handles);
    end



function varValueText_Callback(hObject, eventdata, handles)
% hObject    handle to varValueText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of varValueText as text
%        str2double(get(hObject,'String')) returns contents of varValueText as a double
    lvdData = getappdata(handles.lvd_adjustOptVarGUI,'lvdData');
    lvdOpt = lvdData.optimizer;
    varSet = lvdOpt.vars;
    [~, ~, ~, xUnscaled] = varSet.getTotalScaledXVector();
    [~, ~, lwrBndsUnscaled, uprBndsUnscaled] = varSet.getTotalScaledBndsVector();
    
    varInd = handles.variablesCombo.Value;

    errMsg = {};
    value = str2double(get(handles.varValueText,'String'));
    enteredStr = get(handles.varValueText,'String');
    numberName = 'Epoch (UT)';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);

    if(isempty(errMsg))
        lb = lwrBndsUnscaled(varInd);
        ub = uprBndsUnscaled(varInd);
        
        if(value < lb)
            handles.varValueText.String = fullAccNum2Str(lb);
            handles.varValueSlider.Value = -1;
            
        elseif(value > ub)
            handles.varValueText.String = fullAccNum2Str(ub);
            handles.varValueSlider.Value = 1;
            
        end
        
        processUserChangeToVar(handles);
    else
        handles.varValueText.String = fullAccNum2Str(xUnscaled(varInd));
    end
