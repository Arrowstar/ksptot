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

% Last Modified by GUIDE v2.5 06-Nov-2019 20:40:27

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

populateGUI(handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes lvd_editFminconOptionsGUI wait for user response (see UIRESUME)
% uiwait(handles.lvd_editFminconOptionsGUI);

function populateGUI(handles)
    setDocLbl(handles);
    
    algoListboxStr = LvdFminconAlgorithmEnum.getListBoxStr();
    handles.algoCombo.String = algoListboxStr;
    
    finiteDiffTypeStrs = FminconFiniteDiffTypeEnum.getListBoxStr();
    handles.finiteDiffTypeCombo.String = finiteDiffTypeStrs;
    
    typicalXStrs = OptimizerTypicalXEnum.getListBoxStr();
    handles.typicalXCombo.String = typicalXStrs;
    
    hessApproxStrs = FminconHessApproxAlgEnum.getListBoxStr();
    handles.IpApproxAlgoCombo.String = hessApproxStrs;
    
    subProbStrs = FminconIpSubprobAlgEnum.getListBoxStr();
    handles.IpSubproblemAlgoCombo.String = subProbStrs;
    
    useParaStr = FminconUseParallelEnum.getListBoxStr();
    handles.useParallelCombo.String = useParaStr;
    
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
varargout{1} = handles.output;



function optTolText_Callback(hObject, eventdata, handles)
% hObject    handle to optTolText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of optTolText as text
%        str2double(get(hObject,'String')) returns contents of optTolText as a double


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



function AsTolConSqpText_Callback(hObject, eventdata, handles)
% hObject    handle to AsTolConSqpText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AsTolConSqpText as text
%        str2double(get(hObject,'String')) returns contents of AsTolConSqpText as a double


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
