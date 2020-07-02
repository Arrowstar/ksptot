function varargout = lvd_editIpoptOptionsGUI(varargin)
% LVD_EDITIPOPTOPTIONSGUI MATLAB code for lvd_editIpoptOptionsGUI.fig
%      LVD_EDITIPOPTOPTIONSGUI, by itself, creates a new LVD_EDITIPOPTOPTIONSGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITIPOPTOPTIONSGUI returns the handle to a new LVD_EDITIPOPTOPTIONSGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITIPOPTOPTIONSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITIPOPTOPTIONSGUI.M with the given input arguments.
%
%      LVD_EDITIPOPTOPTIONSGUI('Property','Value',...) creates a new LVD_EDITIPOPTOPTIONSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_editIpoptOptionsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_editIpoptOptionsGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_editIpoptOptionsGUI

% Last Modified by GUIDE v2.5 30-Jan-2020 20:01:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_editIpoptOptionsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_editIpoptOptionsGUI_OutputFcn, ...
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


% --- Executes just before lvd_editIpoptOptionsGUI is made visible.
function lvd_editIpoptOptionsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_editIpoptOptionsGUI (see VARARGIN)

    % Choose default command line output for lvd_editIpoptOptionsGUI
    handles.output = hObject;
    
    ipoptOpt = varargin{1};
    setappdata(hObject,'ipoptOpt',ipoptOpt);

    handles = populateGUI(handles, ipoptOpt);

    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_editIpoptOptionsGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_editIpoptOptionsGUI);
    
function handles = populateGUI(handles, ipoptOpt)
    options = ipoptOpt.getOptions();
    
    setDocLbl(handles);
    
    listboxStrs = IpOptAlphaForYEnum.getListBoxStr();
    handles.alphaForYCombo.String = listboxStrs;
    handles.alphaForYCombo.Value = IpOptAlphaForYEnum.getIndForName(options.alpha_for_y.name);
    
    listboxStrs = IpOptCorrectorTypeEnum.getListBoxStr();
    handles.correctorTypeCombo.String = listboxStrs;
    handles.correctorTypeCombo.Value = IpOptCorrectorTypeEnum.getIndForName(options.corrector_type.name);
    
    listboxStrs = IpOptRecalcYEnum.getListBoxStr();
    handles.recalcYCombo.String = listboxStrs;
    handles.recalcYCombo.Value = IpOptRecalcYEnum.getIndForName(options.recalc_y.name);
    
    listboxStrs = IpoptUseParallelEnum.getListBoxStr();
    handles.useParallelCombo.String = listboxStrs;
    handles.useParallelCombo.Value = IpoptUseParallelEnum.getIndForName(options.useParallel.name);
    
    setOptsDoubleValueStrInGUI(handles, options, 'dual_inf_tol', 'dualInfTolText');
	setOptsDoubleValueStrInGUI(handles, options, 'constr_viol_tol', 'constrViolTolText');
	setOptsDoubleValueStrInGUI(handles, options, 'tol', 'tolText');
	setOptsDoubleValueStrInGUI(handles, options, 'max_iter', 'maxIterText');
	setOptsDoubleValueStrInGUI(handles, options, 'max_cpu_time', 'maxCpuTime');
    
    setOptsDoubleValueStrInGUI(handles, options, 'alpha_red_factor', 'alphaRedFactorText');
    setOptsDoubleValueStrInGUI(handles, options, 'nu_inc', 'nuIncrText');
    setOptsDoubleValueStrInGUI(handles, options, 'nu_init', 'nuInitText');
    
    

function setDocLbl(handles)
    docLinkLblPos = handles.docLinkLabel.Position;
    docLinkLblParent = handles.docLinkLabel.Parent;
    handles.docLinkLabel.Visible = 'off';
    
    % Create and display the text label
    fileName = 'IPOPT_Doc.pdf';
    labelStr = ['<html><div style=''text-align: center;''>For more information, open the documentation PDF for IPOPT: <a href="">' fileName '</a></div></html>'];
    jLabel = javaObjectEDT('javax.swing.JLabel', labelStr);
    [hjLabel,~] = javacomponent(jLabel, docLinkLblPos, docLinkLblParent);

    % Modify the mouse cursor when hovering on the label
    hjLabel.setCursor(java.awt.Cursor.getPredefinedCursor(java.awt.Cursor.HAND_CURSOR));

    % Set the mouse-click callback
    set(hjLabel, 'MouseClickedCallback', @(h,e)open(['.\helper_methods\math\ipopt\',fileName]));
    

% --- Outputs from this function are returned to the command line.
function varargout = lvd_editIpoptOptionsGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        ipoptOpt = getappdata(hObject,'ipoptOpt');
        options = ipoptOpt.getOptions();
        
        listboxStrs = IpOptAlphaForYEnum.getListBoxStr();
        options.alpha_for_y = IpOptAlphaForYEnum.getEnumForListboxStr(listboxStrs{handles.alphaForYCombo.Value});
        
        listboxStrs = IpOptCorrectorTypeEnum.getListBoxStr();
        options.corrector_type = IpOptCorrectorTypeEnum.getEnumForListboxStr(listboxStrs{handles.correctorTypeCombo.Value});
        
        listboxStrs = IpOptRecalcYEnum.getListBoxStr();
        options.recalc_y = IpOptRecalcYEnum.getEnumForListboxStr(listboxStrs{handles.recalcYCombo.Value});
        
        listboxStrs = IpoptUseParallelEnum.getListBoxStr();
        options.useParallel = IpoptUseParallelEnum.getEnumForListboxStr(listboxStrs{handles.useParallelCombo.Value});
        
        setOptsDoubleValueInObject(handles, options, 'dual_inf_tol', 'dualInfTolText');
        setOptsDoubleValueInObject(handles, options, 'constr_viol_tol', 'constrViolTolText');
        setOptsDoubleValueInObject(handles, options, 'tol', 'tolText');
        setOptsDoubleValueInObject(handles, options, 'max_iter', 'maxIterText');
        setOptsDoubleValueInObject(handles, options, 'max_cpu_time', 'maxCpuTime');

        setOptsDoubleValueInObject(handles, options, 'alpha_red_factor', 'alphaRedFactorText');
        setOptsDoubleValueInObject(handles, options, 'nu_inc', 'nuIncrText');
        setOptsDoubleValueInObject(handles, options, 'nu_init', 'nuInitText');
        
        varargout{1} = true;
        close(handles.lvd_editIpoptOptionsGUI);
    end

    
function errMsg = validateInputs(handles)
    errMsg = {};

    errMsg = validateDoubleValue(handles, errMsg, 'dualInfTolText', 'Optimality Tolerance', 1E-12, Inf, false);
    errMsg = validateDoubleValue(handles, errMsg, 'constrViolTolText', 'Constraint Tolerance', 1E-12, Inf, false);
    errMsg = validateDoubleValue(handles, errMsg, 'tolText', 'Tolerance Tolerance', 1E-12, Inf, false);
    errMsg = validateDoubleValue(handles, errMsg, 'maxIterText', 'Maximum Iterations', 0, Inf, true);
    errMsg = validateDoubleValue(handles, errMsg, 'maxCpuTime', 'Max CPU Time', 0, Inf, false);
    
    errMsg = validateDoubleValue(handles, errMsg, 'alphaRedFactorText', 'Alpha Red Factor', 0, 1, false);
    errMsg = validateDoubleValue(handles, errMsg, 'nuIncrText', 'Initial Nu', 1E-12, Inf, false);
    errMsg = validateDoubleValue(handles, errMsg, 'nuInitText', 'Nu Increment', 1E-12, Inf, false);

% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_editIpoptOptionsGUI);
    else
        msgbox(errMsg,'Invalid IPOPT Options Inputs','error');
    end


% --- Executes on selection change in useParallelCombo.
function useParallelCombo_Callback(hObject, eventdata, handles)
% hObject    handle to useParallelCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns useParallelCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from useParallelCombo


% --- Executes during object creation, after setting all properties.
function useParallelCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to useParallelCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in alphaForYCombo.
function alphaForYCombo_Callback(hObject, eventdata, handles)
% hObject    handle to alphaForYCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns alphaForYCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from alphaForYCombo


% --- Executes during object creation, after setting all properties.
function alphaForYCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to alphaForYCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function alphaRedFactorText_Callback(hObject, eventdata, handles)
% hObject    handle to alphaRedFactorText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of alphaRedFactorText as text
%        str2double(get(hObject,'String')) returns contents of alphaRedFactorText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function alphaRedFactorText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to alphaRedFactorText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in correctorTypeCombo.
function correctorTypeCombo_Callback(hObject, eventdata, handles)
% hObject    handle to correctorTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns correctorTypeCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from correctorTypeCombo


% --- Executes during object creation, after setting all properties.
function correctorTypeCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to correctorTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in recalcYCombo.
function recalcYCombo_Callback(hObject, eventdata, handles)
% hObject    handle to recalcYCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns recalcYCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from recalcYCombo


% --- Executes during object creation, after setting all properties.
function recalcYCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to recalcYCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function nuInitText_Callback(hObject, eventdata, handles)
% hObject    handle to nuInitText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nuInitText as text
%        str2double(get(hObject,'String')) returns contents of nuInitText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function nuInitText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nuInitText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function nuIncrText_Callback(hObject, eventdata, handles)
% hObject    handle to nuIncrText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nuIncrText as text
%        str2double(get(hObject,'String')) returns contents of nuIncrText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function nuIncrText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nuIncrText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tolText_Callback(hObject, eventdata, handles)
% hObject    handle to tolText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tolText as text
%        str2double(get(hObject,'String')) returns contents of tolText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function tolText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tolText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function constrViolTolText_Callback(hObject, eventdata, handles)
% hObject    handle to constrViolTolText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of constrViolTolText as text
%        str2double(get(hObject,'String')) returns contents of constrViolTolText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function constrViolTolText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to constrViolTolText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dualInfTolText_Callback(hObject, eventdata, handles)
% hObject    handle to dualInfTolText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dualInfTolText as text
%        str2double(get(hObject,'String')) returns contents of dualInfTolText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function dualInfTolText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dualInfTolText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxCpuTime_Callback(hObject, eventdata, handles)
% hObject    handle to maxCpuTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxCpuTime as text
%        str2double(get(hObject,'String')) returns contents of maxCpuTime as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function maxCpuTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxCpuTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxIterText_Callback(hObject, eventdata, handles)
% hObject    handle to maxIterText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxIterText as text
%        str2double(get(hObject,'String')) returns contents of maxIterText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function maxIterText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxIterText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
