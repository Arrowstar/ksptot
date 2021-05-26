function varargout = lvd_editNomadOptionsGUI(varargin)
% LVD_EDITNOMADOPTIONSGUI MATLAB code for lvd_editNomadOptionsGUI.fig
%      LVD_EDITNOMADOPTIONSGUI, by itself, creates a new LVD_EDITNOMADOPTIONSGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITNOMADOPTIONSGUI returns the handle to a new LVD_EDITNOMADOPTIONSGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITNOMADOPTIONSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITNOMADOPTIONSGUI.M with the given input arguments.
%
%      LVD_EDITNOMADOPTIONSGUI('Property','Value',...) creates a new LVD_EDITNOMADOPTIONSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_editNomadOptionsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_editNomadOptionsGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_editNomadOptionsGUI

% Last Modified by GUIDE v2.5 25-Aug-2020 10:31:16

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_editNomadOptionsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_editNomadOptionsGUI_OutputFcn, ...
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


% --- Executes just before lvd_editNomadOptionsGUI is made visible.
function lvd_editNomadOptionsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to lvd_editNomadOptionsGUI (see VARARGIN)

    % Choose default command line output for lvd_editNomadOptionsGUI
    handles.output = hObject;

    nomadOpt = varargin{1};
    handles = populateGUI(handles, nomadOpt);
    setappdata(hObject,'nomadOpt',nomadOpt);

    % Update handles structure
    guidata(hObject, handles);

% UIWAIT makes lvd_editNomadOptionsGUI wait for user response (see UIRESUME)
uiwait(handles.lvd_editNomadOptionsGUI);

function handles = populateGUI(handles, nomadOpt)
    options = nomadOpt.getOptions();
    
    setDocLbl(handles);
    
    dirTypeStrs = NomadDirectionTypeEnum.getListBoxStr();
    handles.directionTypeCombo.String = dirTypeStrs;
    handles.directionTypeCombo.Value = NomadDirectionTypeEnum.getIndForName(options.direction_type.name);
    
    stopIfFeasibleStrs = NomadStopIfFeasibleEnum.getListBoxStr();
    handles.stopIfFeasibleCombo.String = stopIfFeasibleStrs;
    handles.stopIfFeasibleCombo.Value = NomadStopIfFeasibleEnum.getIndForName(options.stop_if_feasible.name);
    
    constrTypeStrs = NomadConstraintType.getListBoxStr();
    handles.constrTypeCombo.String = constrTypeStrs;
    handles.constrTypeCombo.Value = NomadConstraintType.getIndForName(options.constrType.name);
    
    hNormStrs = NomadHNormTypeEnum.getListBoxStr();
    handles.hNormCombo.String = hNormStrs;
    handles.hNormCombo.Value = NomadHNormTypeEnum.getIndForName(options.h_norm.name);
    
    useParallelStrs = PatternSearchUseParallelEnum.getListBoxStr();
    handles.useParallelCombo.String = useParallelStrs;
    handles.useParallelCombo.Value = PatternSearchUseParallelEnum.getIndForName(options.useParallel.name);
    
    setOptsDoubleValueStrInGUI(handles, options, 'initial_mesh_size', 'initialMeshSizeText');
    
    setOptsDoubleValueStrInGUI(handles, options, 'max_bb_eval', 'maxBbEvalsText');
    setOptsDoubleValueStrInGUI(handles, options, 'max_time', 'maxTimeText');
    setOptsDoubleValueStrInGUI(handles, options, 'max_cache_memory', 'maxCacheMemoryText');
    setOptsDoubleValueStrInGUI(handles, options, 'max_iterations', 'maxIterationsText');
    
    setOptsDoubleValueStrInGUI(handles, options, 'h_max_0', 'hMax0Text');
    setOptsDoubleValueStrInGUI(handles, options, 'h_min', 'hMinText');
    
    setOptsDoubleValueStrInGUI(handles, options, 'vns_trigger', 'vnsTriggerText');
    
    setOptsDoubleValueStrInGUI(handles, options, 'vns_trigger', 'vnsTriggerText');
    
    setOptsDoubleValueStrInGUI(handles, options, 'numWorkers', 'numParaWorkersText');
    
function setDocLbl(handles)
    docLinkLblPos = handles.docLinkLabel.Position;
    docLinkLblParent = handles.docLinkLabel.Parent;
    handles.docLinkLabel.Visible = 'off';
    
    % Create and display the text label
    fileName = 'NOMAD_Users_Guide.pdf';
    labelStr = ['<html><div style=''text-align: center;''>For more information, open the documentation PDF for NOMAD: <a href="">' fileName '</a></div></html>'];
    jLabel = javaObjectEDT('javax.swing.JLabel', labelStr);
    [hjLabel,~] = javacomponent(jLabel, docLinkLblPos, docLinkLblParent);

    % Modify the mouse cursor when hovering on the label
    hjLabel.setCursor(java.awt.Cursor.getPredefinedCursor(java.awt.Cursor.HAND_CURSOR));

    % Set the mouse-click callback
    set(hjLabel, 'MouseClickedCallback', @(h,e)open(['.\helper_methods\math\nomad\',fileName]));

% --- Outputs from this function are returned to the command line.
function varargout = lvd_editNomadOptionsGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        nomadOpt = getappdata(hObject,'nomadOpt');
        options = nomadOpt.getOptions();
        
        dirTypeStrs = NomadDirectionTypeEnum.getListBoxStr();
        options.direction_type = NomadDirectionTypeEnum.getEnumForListboxStr(dirTypeStrs{handles.directionTypeCombo.Value});
        
        stopIfFeasibleStrs = NomadStopIfFeasibleEnum.getListBoxStr();
        options.stop_if_feasible = NomadStopIfFeasibleEnum.getEnumForListboxStr(stopIfFeasibleStrs{handles.stopIfFeasibleCombo.Value});

        constrTypeStrs = NomadConstraintType.getListBoxStr();
        options.constrType = NomadConstraintType.getEnumForListboxStr(constrTypeStrs{handles.constrTypeCombo.Value});

        hNormStrs = NomadHNormTypeEnum.getListBoxStr();
        options.h_norm = NomadHNormTypeEnum.getEnumForListboxStr(hNormStrs{handles.hNormCombo.Value});
    
        useParallelStrs = PatternSearchUseParallelEnum.getListBoxStr();
        options.useParallel = PatternSearchUseParallelEnum.getEnumForListboxStr(useParallelStrs{handles.useParallelCombo.Value});
        
        setOptsDoubleValueInObject(handles, options, 'initial_mesh_size', 'initialMeshSizeText');

        setOptsDoubleValueInObject(handles, options, 'max_bb_eval', 'maxBbEvalsText');
        setOptsDoubleValueInObject(handles, options, 'max_time', 'maxTimeText');
        setOptsDoubleValueInObject(handles, options, 'max_cache_memory', 'maxCacheMemoryText');
        setOptsDoubleValueInObject(handles, options, 'max_iterations', 'maxIterationsText');

        setOptsDoubleValueInObject(handles, options, 'h_max_0', 'hMax0Text');
        setOptsDoubleValueInObject(handles, options, 'h_min', 'hMinText');

        setOptsDoubleValueInObject(handles, options, 'vns_trigger', 'vnsTriggerText');
        
        setOptsDoubleValueInObject(handles, options, 'numWorkers', 'numParaWorkersText');
        
        varargout{1} = true;
        close(handles.lvd_editNomadOptionsGUI);
    end


% --- Executes on selection change in directionTypeCombo.
function directionTypeCombo_Callback(hObject, eventdata, handles)
% hObject    handle to directionTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns directionTypeCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from directionTypeCombo


% --- Executes during object creation, after setting all properties.
function directionTypeCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to directionTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function initialMeshSizeText_Callback(hObject, eventdata, handles)
% hObject    handle to initialMeshSizeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of initialMeshSizeText as text
%        str2double(get(hObject,'String')) returns contents of initialMeshSizeText as a double


% --- Executes during object creation, after setting all properties.
function initialMeshSizeText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to initialMeshSizeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in constrTypeCombo.
function constrTypeCombo_Callback(hObject, eventdata, handles)
% hObject    handle to constrTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns constrTypeCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from constrTypeCombo


% --- Executes during object creation, after setting all properties.
function constrTypeCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to constrTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function hMax0Text_Callback(hObject, eventdata, handles)
% hObject    handle to hMax0Text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hMax0Text as text
%        str2double(get(hObject,'String')) returns contents of hMax0Text as a double


% --- Executes during object creation, after setting all properties.
function hMax0Text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hMax0Text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function hMinText_Callback(hObject, eventdata, handles)
% hObject    handle to hMinText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hMinText as text
%        str2double(get(hObject,'String')) returns contents of hMinText as a double


% --- Executes during object creation, after setting all properties.
function hMinText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hMinText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit9_Callback(hObject, eventdata, handles)
% hObject    handle to edit9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit9 as text
%        str2double(get(hObject,'String')) returns contents of edit9 as a double


% --- Executes during object creation, after setting all properties.
function edit9_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in hNormCombo.
function hNormCombo_Callback(hObject, eventdata, handles)
% hObject    handle to hNormCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns hNormCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from hNormCombo


% --- Executes during object creation, after setting all properties.
function hNormCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hNormCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxBbEvalsText_Callback(hObject, eventdata, handles)
% hObject    handle to maxBbEvalsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxBbEvalsText as text
%        str2double(get(hObject,'String')) returns contents of maxBbEvalsText as a double


% --- Executes during object creation, after setting all properties.
function maxBbEvalsText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxBbEvalsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxTimeText_Callback(hObject, eventdata, handles)
% hObject    handle to maxTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxTimeText as text
%        str2double(get(hObject,'String')) returns contents of maxTimeText as a double


% --- Executes during object creation, after setting all properties.
function maxTimeText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxCacheMemoryText_Callback(hObject, eventdata, handles)
% hObject    handle to maxCacheMemoryText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxCacheMemoryText as text
%        str2double(get(hObject,'String')) returns contents of maxCacheMemoryText as a double


% --- Executes during object creation, after setting all properties.
function maxCacheMemoryText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxCacheMemoryText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxIterationsText_Callback(hObject, eventdata, handles)
% hObject    handle to maxIterationsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxIterationsText as text
%        str2double(get(hObject,'String')) returns contents of maxIterationsText as a double


% --- Executes during object creation, after setting all properties.
function maxIterationsText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxIterationsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in stopIfFeasibleCombo.
function stopIfFeasibleCombo_Callback(hObject, eventdata, handles)
% hObject    handle to stopIfFeasibleCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns stopIfFeasibleCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from stopIfFeasibleCombo


% --- Executes during object creation, after setting all properties.
function stopIfFeasibleCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stopIfFeasibleCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function vnsTriggerText_Callback(hObject, eventdata, handles)
% hObject    handle to vnsTriggerText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of vnsTriggerText as text
%        str2double(get(hObject,'String')) returns contents of vnsTriggerText as a double


% --- Executes during object creation, after setting all properties.
function vnsTriggerText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vnsTriggerText (see GCBO)
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


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_editNomadOptionsGUI);
    else
        msgbox(errMsg,'Invalid NOMAD Options Inputs','error');
    end
    
function errMsg = validateInputs(handles)
    errMsg = {};
    
    errMsg = validateDoubleValue(handles, errMsg, 'initialMeshSizeText', 'Cache Tolerance', 1E-12, Inf, false);
    
    errMsg = validateDoubleValue(handles, errMsg, 'maxBbEvalsText', 'Max Function Evals', 1, Inf, true);
    errMsg = validateDoubleValue(handles, errMsg, 'maxTimeText', 'Max Time (s)', 1, Inf, false);
    errMsg = validateDoubleValue(handles, errMsg, 'maxCacheMemoryText', 'Max Cache Memory (MB)', 1, Inf, true);
    errMsg = validateDoubleValue(handles, errMsg, 'maxIterationsText', 'Max Iterations', 1, Inf, true);
    
    errMsg = validateDoubleValue(handles, errMsg, 'hMax0Text', 'Initial Hmax Factor', 1, Inf, false);
    errMsg = validateDoubleValue(handles, errMsg, 'hMinText', 'Constraint Tolerance', 1E-12, Inf, false);
    
    errMsg = validateDoubleValue(handles, errMsg, 'vnsTriggerText', 'VNS Trigger', 0, 1, false);

    errMsg = validateDoubleValue(handles, errMsg, 'vnsTriggerText', 'VNS Trigger', 0, 1, false);
    
    errMsg = validateDoubleValue(handles, errMsg, 'numParaWorkersText', 'Number of Parallel Workers', 1, feature('numCores'), true);

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
