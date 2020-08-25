function varargout = lvd_editFminconOptionsGUI(varargin)
% LVD_EDITFMINCONOPTIONSGUI MATLAB code for lvd_editFminconOptionsGUI.fig
%      LVD_EDITFMINCONOPTIONSGUI, by itself, creates a new LVD_EDITFMINCONOPTIONSGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITFMINCONOPTIONSGUI returns the handle to a new LVD_EDITFMINCONOPTIONSGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITFMINCONOPTIONSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITFMINCONOPTIONSGUI.M with the given input arguments.
%
%      LVD_EDITFMINCONOPTIONSGUI('Property','Value',...) creates a new LVD_EDITFMINCONOPTIONSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_editFminconOptionsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_editFminconOptionsGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_editFminconOptionsGUI

% Last Modified by GUIDE v2.5 25-Aug-2020 10:18:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_editFminconOptionsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_editFminconOptionsGUI_OutputFcn, ...
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


% --- Executes just before lvd_editFminconOptionsGUI is made visible.
function lvd_editFminconOptionsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to lvd_editFminconOptionsGUI (see VARARGIN)

% Choose default command line output for lvd_editFminconOptionsGUI
    handles.output = hObject;

    fminconOpt = varargin{1};
    setappdata(hObject,'fminconOpt',fminconOpt);

    handles = populateGUI(handles, fminconOpt);

    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_editFminconOptionsGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_editFminconOptionsGUI);

function handles = populateGUI(handles, fminconOpt)
    options = fminconOpt.getOptions();
    
    setDocLbl(handles);
    
    algoListboxStr = LvdFminconAlgorithmEnum.getListBoxStr();
    handles.algoCombo.String = algoListboxStr;
    handles.algoCombo.Value = LvdFminconAlgorithmEnum.getIndForName(options.algorithm.name);
    
    finiteDiffTypeStrs = FminconFiniteDiffTypeEnum.getListBoxStr();
    handles.finiteDiffTypeCombo.String = finiteDiffTypeStrs;
    handles.finiteDiffTypeCombo.Value = FminconFiniteDiffTypeEnum.getIndForName(options.finDiffType.name);
    
    typicalXStrs = OptimizerTypicalXEnum.getListBoxStr();
    handles.typicalXCombo.String = typicalXStrs;
    handles.typicalXCombo.Value = OptimizerTypicalXEnum.getIndForName(options.typicalXType.name);
    
    hessApproxStrs = FminconHessApproxAlgEnum.getListBoxStr();
    handles.IpApproxAlgoCombo.String = hessApproxStrs;
    handles.IpApproxAlgoCombo.Value = FminconHessApproxAlgEnum.getIndForName(options.hessianApproxAlg.name);
    
    subProbStrs = FminconIpSubprobAlgEnum.getListBoxStr();
    handles.IpSubproblemAlgoCombo.String = subProbStrs;
    handles.IpSubproblemAlgoCombo.Value = FminconIpSubprobAlgEnum.getIndForName(options.subproblemAlgorithm.name);
    
    useParaStr = FminconUseParallelEnum.getListBoxStr();
    handles.useParallelCombo.String = useParaStr;
    handles.useParallelCombo.Value = FminconUseParallelEnum.getIndForName(options.useParallel.name);
    
    setOptsDoubleValueStrInGUI(handles, options, 'optTol', 'optTolText');
    setOptsDoubleValueStrInGUI(handles, options, 'stepTol', 'conTolText');
    setOptsDoubleValueStrInGUI(handles, options, 'tolCon', 'stepTolText');
    
    setOptsDoubleValueStrInGUI(handles, options, 'maxIter', 'maxItersText');
    setOptsDoubleValueStrInGUI(handles, options, 'maxFuncEvals', 'maxFuncEvalsText');
    
    setOptsDoubleValueStrInGUI(handles, options, 'finDiffStepSize', 'finiteDiffStepSizeText');
    
    setOptsDoubleValueStrInGUI(handles, options, 'initBarrierParam', 'IpInitBarrierParamText');
    setOptsDoubleValueStrInGUI(handles, options, 'initTrustRegionRadius', 'IpInitTrustRegionRadiusText');
    setOptsDoubleValueStrInGUI(handles, options, 'maxProjCGIter', 'IpMaxProjCGItersText');
    setOptsDoubleValueStrInGUI(handles, options, 'tolProjCG', 'IpRelProjCGTolText');
    setOptsDoubleValueStrInGUI(handles, options, 'tolProjCGAbs', 'IpAbsProjCGTolText');
    
    setOptsDoubleValueStrInGUI(handles, options, 'funcTol', 'AsFuncTolText');
    setOptsDoubleValueStrInGUI(handles, options, 'maxSQPIter', 'AsMaxSqpItersText');
    setOptsDoubleValueStrInGUI(handles, options, 'relLineSrchBnd', 'AsRelLineSrchBndText');
    setOptsDoubleValueStrInGUI(handles, options, 'relLineSrchBndDuration', 'AsLineSrchBndDurText');
    setOptsDoubleValueStrInGUI(handles, options, 'tolConSQP', 'AsTolConSqpText');
    
    setOptsDoubleValueStrInGUI(handles, options, 'numWorkers', 'numParaWorkersText');
    
function setDocLbl(handles)
    docLinkLblPos = handles.matlabDocLinkLabel.Position;
    docLinkLblParent = handles.matlabDocLinkLabel.Parent;
    handles.matlabDocLinkLabel.Visible = 'off';
    
    % Create and display the text label
    url = 'https://www.mathworks.com/help/optim/ug/fmincon.html';
    labelStr = ['<html><div style=''text-align: center;''>For more information, visit the MATLAB documentation for FMINCON: <a href="">' url '</a></div></html>'];
    jLabel = javaObjectEDT('javax.swing.JLabel', labelStr);
    [hjLabel,~] = javacomponent(jLabel, docLinkLblPos, docLinkLblParent);

    % Modify the mouse cursor when hovering on the label
    hjLabel.setCursor(java.awt.Cursor.getPredefinedCursor(java.awt.Cursor.HAND_CURSOR));

    % Set the mouse-click callback
    set(hjLabel, 'MouseClickedCallback', @(h,e)web([url], '-browser'));

% --- Outputs from this function are returned to the command line.
function varargout = lvd_editFminconOptionsGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        fminconOpt = getappdata(hObject,'fminconOpt');
        options = fminconOpt.getOptions();
        
        algoListboxStr = LvdFminconAlgorithmEnum.getListBoxStr();
        options.algorithm = LvdFminconAlgorithmEnum.getEnumForListboxStr(algoListboxStr{handles.algoCombo.Value});
        
        finiteDiffTypeStrs = FminconFiniteDiffTypeEnum.getListBoxStr();
        options.finDiffType = FminconFiniteDiffTypeEnum.getEnumForListboxStr(finiteDiffTypeStrs{handles.finiteDiffTypeCombo.Value});
        
        typicalXStrs = OptimizerTypicalXEnum.getListBoxStr();
        options.typicalXType = OptimizerTypicalXEnum.getEnumForListboxStr(typicalXStrs{handles.typicalXCombo.Value});
        
        hessApproxStrs = FminconHessApproxAlgEnum.getListBoxStr();
        options.hessianApproxAlg = FminconHessApproxAlgEnum.getEnumForListboxStr(hessApproxStrs{handles.IpApproxAlgoCombo.Value});
        
        subProbStrs = FminconIpSubprobAlgEnum.getListBoxStr();
        options.subproblemAlgorithm = FminconIpSubprobAlgEnum.getEnumForListboxStr(subProbStrs{handles.IpSubproblemAlgoCombo.Value});
        
        useParaStrs = FminconUseParallelEnum.getListBoxStr();
        options.useParallel = FminconUseParallelEnum.getEnumForListboxStr(useParaStrs{handles.useParallelCombo.Value});
        
        setOptsDoubleValueInObject(handles, options, 'optTol', 'optTolText');
        setOptsDoubleValueInObject(handles, options, 'stepTol', 'conTolText');
        setOptsDoubleValueInObject(handles, options, 'tolCon', 'stepTolText');

        setOptsDoubleValueInObject(handles, options, 'maxIter', 'maxItersText');
        setOptsDoubleValueInObject(handles, options, 'maxFuncEvals', 'maxFuncEvalsText');

        setOptsDoubleValueInObject(handles, options, 'finDiffStepSize', 'finiteDiffStepSizeText');

        setOptsDoubleValueInObject(handles, options, 'initBarrierParam', 'IpInitBarrierParamText');
        setOptsDoubleValueInObject(handles, options, 'initTrustRegionRadius', 'IpInitTrustRegionRadiusText');
        setOptsDoubleValueInObject(handles, options, 'maxProjCGIter', 'IpMaxProjCGItersText');
        setOptsDoubleValueInObject(handles, options, 'tolProjCG', 'IpRelProjCGTolText');
        setOptsDoubleValueInObject(handles, options, 'tolProjCGAbs', 'IpAbsProjCGTolText');

        setOptsDoubleValueInObject(handles, options, 'funcTol', 'AsFuncTolText');
        setOptsDoubleValueInObject(handles, options, 'maxSQPIter', 'AsMaxSqpItersText');
        setOptsDoubleValueInObject(handles, options, 'relLineSrchBnd', 'AsRelLineSrchBndText');
        setOptsDoubleValueInObject(handles, options, 'relLineSrchBndDuration', 'AsLineSrchBndDurText');
        setOptsDoubleValueInObject(handles, options, 'tolConSQP', 'AsTolConSqpText');
        
        setOptsDoubleValueInObject(handles, options, 'numWorkers', 'numParaWorkersText');
    
        varargout{1} = true;
        close(handles.lvd_editFminconOptionsGUI);
    end
   
    
function errMsg = validateInputs(handles)
    errMsg = {};

    errMsg = validateDoubleValue(handles, errMsg, 'optTolText', 'Optimality Tolerance', 0, 1, false);
    errMsg = validateDoubleValue(handles, errMsg, 'conTolText', 'Constraint Tolerance', 0, 1, false);
    errMsg = validateDoubleValue(handles, errMsg, 'stepTolText', 'Step Tolerance', 0, 1, false);
    
    errMsg = validateDoubleValue(handles, errMsg, 'maxItersText', 'Max Iterations', 0, Inf, true);
    errMsg = validateDoubleValue(handles, errMsg, 'maxFuncEvalsText', 'Max Function Evaluations', 0, Inf, true);

	errMsg = validateDoubleValue(handles, errMsg, 'finiteDiffStepSizeText', 'Finite Difference Step Size', 1E-10, 1E-2, false);
     
	errMsg = validateDoubleValue(handles, errMsg, 'IpInitBarrierParamText', 'I-P Intial Barrier Param', 1E-10, Inf, false);
    errMsg = validateDoubleValue(handles, errMsg, 'IpInitTrustRegionRadiusText', 'I-P Initial Trust Region', 1E-10, Inf, false);
    errMsg = validateDoubleValue(handles, errMsg, 'IpMaxProjCGItersText', 'I-P Max Projected C.G. Iterations', 1, Inf, true);
    errMsg = validateDoubleValue(handles, errMsg, 'IpRelProjCGTolText', 'I-P Relative Projected C.G. Tolerance', 1E-10, Inf, false);
    errMsg = validateDoubleValue(handles, errMsg, 'IpAbsProjCGTolText', 'I-P Absolute Projected C.G. Tolerance', 1E-10, Inf, false);
    
    errMsg = validateDoubleValue(handles, errMsg, 'AsFuncTolText', 'A-S Function Tolerance', 1E-10, 1, false);
    errMsg = validateDoubleValue(handles, errMsg, 'AsMaxSqpItersText', 'A-S Max SQP Iterations', 1, Inf, true);
    errMsg = validateDoubleValue(handles, errMsg, 'AsRelLineSrchBndText', 'A-S Relative Line Search Bound', 0, Inf, false);
    errMsg = validateDoubleValue(handles, errMsg, 'AsLineSrchBndDurText', 'A-S Line Search Bound Duration', 1, Inf, true);
    errMsg = validateDoubleValue(handles, errMsg, 'AsTolConSqpText', 'A-S Inner SQP Constraint Tolerance', 1E-10, Inf, false);
     
    errMsg = validateDoubleValue(handles, errMsg, 'numParaWorkersText', 'Number of Parallel Workers', 1, feature('numCores'), true);

function optTolText_Callback(hObject, eventdata, handles)
% hObject    handle to optTolText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of optTolText as text
%        str2double(get(hObject,'String')) returns contents of optTolText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function optTolText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to optTolText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function conTolText_Callback(hObject, eventdata, handles)
% hObject    handle to conTolText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of conTolText as text
%        str2double(get(hObject,'String')) returns contents of conTolText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function conTolText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to conTolText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function stepTolText_Callback(hObject, eventdata, handles)
% hObject    handle to stepTolText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of stepTolText as text
%        str2double(get(hObject,'String')) returns contents of stepTolText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function stepTolText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stepTolText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in algoCombo.
function algoCombo_Callback(hObject, eventdata, handles)
% hObject    handle to algoCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns algoCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from algoCombo


% --- Executes during object creation, after setting all properties.
function algoCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to algoCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxItersText_Callback(hObject, eventdata, handles)
% hObject    handle to maxItersText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxItersText as text
%        str2double(get(hObject,'String')) returns contents of maxItersText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function maxItersText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxItersText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxFuncEvalsText_Callback(hObject, eventdata, handles)
% hObject    handle to maxFuncEvalsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxFuncEvalsText as text
%        str2double(get(hObject,'String')) returns contents of maxFuncEvalsText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function maxFuncEvalsText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxFuncEvalsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in finiteDiffTypeCombo.
function finiteDiffTypeCombo_Callback(hObject, eventdata, handles)
% hObject    handle to finiteDiffTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns finiteDiffTypeCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from finiteDiffTypeCombo


% --- Executes during object creation, after setting all properties.
function finiteDiffTypeCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to finiteDiffTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function finiteDiffStepSizeText_Callback(hObject, eventdata, handles)
% hObject    handle to finiteDiffStepSizeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of finiteDiffStepSizeText as text
%        str2double(get(hObject,'String')) returns contents of finiteDiffStepSizeText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function finiteDiffStepSizeText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to finiteDiffStepSizeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in typicalXCombo.
function typicalXCombo_Callback(hObject, eventdata, handles)
% hObject    handle to typicalXCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns typicalXCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from typicalXCombo


% --- Executes during object creation, after setting all properties.
function typicalXCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to typicalXCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in IpApproxAlgoCombo.
function IpApproxAlgoCombo_Callback(hObject, eventdata, handles)
% hObject    handle to IpApproxAlgoCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns IpApproxAlgoCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from IpApproxAlgoCombo


% --- Executes during object creation, after setting all properties.
function IpApproxAlgoCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to IpApproxAlgoCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function IpInitBarrierParamText_Callback(hObject, eventdata, handles)
% hObject    handle to IpInitBarrierParamText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of IpInitBarrierParamText as text
%        str2double(get(hObject,'String')) returns contents of IpInitBarrierParamText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function IpInitBarrierParamText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to IpInitBarrierParamText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function IpInitTrustRegionRadiusText_Callback(hObject, eventdata, handles)
% hObject    handle to IpInitTrustRegionRadiusText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of IpInitTrustRegionRadiusText as text
%        str2double(get(hObject,'String')) returns contents of IpInitTrustRegionRadiusText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function IpInitTrustRegionRadiusText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to IpInitTrustRegionRadiusText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function IpMaxProjCGItersText_Callback(hObject, eventdata, handles)
% hObject    handle to IpMaxProjCGItersText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of IpMaxProjCGItersText as text
%        str2double(get(hObject,'String')) returns contents of IpMaxProjCGItersText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function IpMaxProjCGItersText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to IpMaxProjCGItersText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in IpSubproblemAlgoCombo.
function IpSubproblemAlgoCombo_Callback(hObject, eventdata, handles)
% hObject    handle to IpSubproblemAlgoCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns IpSubproblemAlgoCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from IpSubproblemAlgoCombo


% --- Executes during object creation, after setting all properties.
function IpSubproblemAlgoCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to IpSubproblemAlgoCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function IpRelProjCGTolText_Callback(hObject, eventdata, handles)
% hObject    handle to IpRelProjCGTolText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of IpRelProjCGTolText as text
%        str2double(get(hObject,'String')) returns contents of IpRelProjCGTolText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function IpRelProjCGTolText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to IpRelProjCGTolText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function IpAbsProjCGTolText_Callback(hObject, eventdata, handles)
% hObject    handle to IpAbsProjCGTolText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of IpAbsProjCGTolText as text
%        str2double(get(hObject,'String')) returns contents of IpAbsProjCGTolText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function IpAbsProjCGTolText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to IpAbsProjCGTolText (see GCBO)
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
        uiresume(handles.lvd_editFminconOptionsGUI);
    else
        msgbox(errMsg,'Invalid FMINCON Options Inputs','error');
    end


function AsTolConSqpText_Callback(hObject, eventdata, handles)
% hObject    handle to AsTolConSqpText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AsTolConSqpText as text
%        str2double(get(hObject,'String')) returns contents of AsTolConSqpText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function AsTolConSqpText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AsTolConSqpText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function AsLineSrchBndDurText_Callback(hObject, eventdata, handles)
% hObject    handle to AsLineSrchBndDurText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AsLineSrchBndDurText as text
%        str2double(get(hObject,'String')) returns contents of AsLineSrchBndDurText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function AsLineSrchBndDurText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AsLineSrchBndDurText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function AsRelLineSrchBndText_Callback(hObject, eventdata, handles)
% hObject    handle to AsRelLineSrchBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AsRelLineSrchBndText as text
%        str2double(get(hObject,'String')) returns contents of AsRelLineSrchBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function AsRelLineSrchBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AsRelLineSrchBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function AsMaxSqpItersText_Callback(hObject, eventdata, handles)
% hObject    handle to AsMaxSqpItersText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AsMaxSqpItersText as text
%        str2double(get(hObject,'String')) returns contents of AsMaxSqpItersText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function AsMaxSqpItersText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AsMaxSqpItersText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function AsFuncTolText_Callback(hObject, eventdata, handles)
% hObject    handle to AsFuncTolText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AsFuncTolText as text
%        str2double(get(hObject,'String')) returns contents of AsFuncTolText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function AsFuncTolText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AsFuncTolText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
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



function numParaWorkersText_Callback(hObject, eventdata, handles)
% hObject    handle to numParaWorkersText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numParaWorkersText as text
%        str2double(get(hObject,'String')) returns contents of numParaWorkersText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function numParaWorkersText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numParaWorkersText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
