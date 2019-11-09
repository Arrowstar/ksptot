function varargout = lvd_editPatternSearchOptionsGUI(varargin)
% LVD_EDITPATTERNSEARCHOPTIONSGUI MATLAB code for lvd_editPatternSearchOptionsGUI.fig
%      LVD_EDITPATTERNSEARCHOPTIONSGUI, by itself, creates a new LVD_EDITPATTERNSEARCHOPTIONSGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITPATTERNSEARCHOPTIONSGUI returns the handle to a new LVD_EDITPATTERNSEARCHOPTIONSGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITPATTERNSEARCHOPTIONSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITPATTERNSEARCHOPTIONSGUI.M with the given input arguments.
%
%      LVD_EDITPATTERNSEARCHOPTIONSGUI('Property','Value',...) creates a new LVD_EDITPATTERNSEARCHOPTIONSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_editPatternSearchOptionsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_editPatternSearchOptionsGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_editPatternSearchOptionsGUI

% Last Modified by GUIDE v2.5 08-Nov-2019 18:46:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_editPatternSearchOptionsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_editPatternSearchOptionsGUI_OutputFcn, ...
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


% --- Executes just before lvd_editPatternSearchOptionsGUI is made visible.
function lvd_editPatternSearchOptionsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to lvd_editPatternSearchOptionsGUI (see VARARGIN)

    % Choose default command line output for lvd_editPatternSearchOptionsGUI
    handles.output = hObject;

    patternSearchOpt = [];
    handles = populateGUI(handles, patternSearchOpt);

    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_editPatternSearchOptionsGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_editPatternSearchOptionsGUI);


function handles = populateGUI(handles, patternSearchOpt)
%     options = patternSearchOpt.getOptions();
    
    setDocLbl(handles);


function setDocLbl(handles)
    docLinkLblPos = handles.matlabDocLinkLabel.Position;
    docLinkLblParent = handles.matlabDocLinkLabel.Parent;
    handles.matlabDocLinkLabel.Visible = 'off';
    
    % Create and display the text label
    url = 'https://www.mathworks.com/help/gads/patternsearch.html';
    labelStr = ['<html><div style=''text-align: center;''>For more information, visit the MATLAB documentation for Pattern Search: <a href="">' url '</a></div></html>'];
    jLabel = javaObjectEDT('javax.swing.JLabel', labelStr);
    [hjLabel,~] = javacomponent(jLabel, docLinkLblPos, docLinkLblParent);

    % Modify the mouse cursor when hovering on the label
    hjLabel.setCursor(java.awt.Cursor.getPredefinedCursor(java.awt.Cursor.HAND_CURSOR));

    % Set the mouse-click callback
    set(hjLabel, 'MouseClickedCallback', @(h,e)web([url], '-browser'));


% --- Outputs from this function are returned to the command line.
function varargout = lvd_editPatternSearchOptionsGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function funcTolText_Callback(hObject, eventdata, handles)
% hObject    handle to funcTolText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of funcTolText as text
%        str2double(get(hObject,'String')) returns contents of funcTolText as a double


% --- Executes during object creation, after setting all properties.
function funcTolText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to funcTolText (see GCBO)
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



function cacheTolText_Callback(hObject, eventdata, handles)
% hObject    handle to cacheTolText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cacheTolText as text
%        str2double(get(hObject,'String')) returns contents of cacheTolText as a double


% --- Executes during object creation, after setting all properties.
function cacheTolText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cacheTolText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function meshTolText_Callback(hObject, eventdata, handles)
% hObject    handle to meshTolText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of meshTolText as text
%        str2double(get(hObject,'String')) returns contents of meshTolText as a double


% --- Executes during object creation, after setting all properties.
function meshTolText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to meshTolText (see GCBO)
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


% --- Executes on selection change in useCacheCombo.
function useCacheCombo_Callback(hObject, eventdata, handles)
% hObject    handle to useCacheCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns useCacheCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from useCacheCombo


% --- Executes during object creation, after setting all properties.
function useCacheCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to useCacheCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function cacheSizeText_Callback(hObject, eventdata, handles)
% hObject    handle to cacheSizeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cacheSizeText as text
%        str2double(get(hObject,'String')) returns contents of cacheSizeText as a double


% --- Executes during object creation, after setting all properties.
function cacheSizeText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cacheSizeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function meshExpFactorText_Callback(hObject, eventdata, handles)
% hObject    handle to meshExpFactorText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of meshExpFactorText as text
%        str2double(get(hObject,'String')) returns contents of meshExpFactorText as a double


% --- Executes during object creation, after setting all properties.
function meshExpFactorText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to meshExpFactorText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function meshContrFactorText_Callback(hObject, eventdata, handles)
% hObject    handle to meshContrFactorText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of meshContrFactorText as text
%        str2double(get(hObject,'String')) returns contents of meshContrFactorText as a double


% --- Executes during object creation, after setting all properties.
function meshContrFactorText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to meshContrFactorText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function initMeshSizeText_Callback(hObject, eventdata, handles)
% hObject    handle to initMeshSizeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of initMeshSizeText as text
%        str2double(get(hObject,'String')) returns contents of initMeshSizeText as a double


% --- Executes during object creation, after setting all properties.
function initMeshSizeText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to initMeshSizeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in accelMeshCombo.
function accelMeshCombo_Callback(hObject, eventdata, handles)
% hObject    handle to accelMeshCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns accelMeshCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from accelMeshCombo


% --- Executes during object creation, after setting all properties.
function accelMeshCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to accelMeshCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in useMeshRotateCombo.
function useMeshRotateCombo_Callback(hObject, eventdata, handles)
% hObject    handle to useMeshRotateCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns useMeshRotateCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from useMeshRotateCombo


% --- Executes during object creation, after setting all properties.
function useMeshRotateCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to useMeshRotateCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxFunEvalsText_Callback(hObject, eventdata, handles)
% hObject    handle to maxFunEvalsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxFunEvalsText as text
%        str2double(get(hObject,'String')) returns contents of maxFunEvalsText as a double


% --- Executes during object creation, after setting all properties.
function maxFunEvalsText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxFunEvalsText (see GCBO)
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



function penaltyFactText_Callback(hObject, eventdata, handles)
% hObject    handle to penaltyFactText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of penaltyFactText as text
%        str2double(get(hObject,'String')) returns contents of penaltyFactText as a double


% --- Executes during object creation, after setting all properties.
function penaltyFactText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to penaltyFactText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function initPenaltyText_Callback(hObject, eventdata, handles)
% hObject    handle to initPenaltyText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of initPenaltyText as text
%        str2double(get(hObject,'String')) returns contents of initPenaltyText as a double


% --- Executes during object creation, after setting all properties.
function initPenaltyText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to initPenaltyText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in searchFuncCombo.
function searchFuncCombo_Callback(hObject, eventdata, handles)
% hObject    handle to searchFuncCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns searchFuncCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from searchFuncCombo


% --- Executes during object creation, after setting all properties.
function searchFuncCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to searchFuncCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in scaleMeshCombo.
function scaleMeshCombo_Callback(hObject, eventdata, handles)
% hObject    handle to scaleMeshCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns scaleMeshCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from scaleMeshCombo


% --- Executes during object creation, after setting all properties.
function scaleMeshCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scaleMeshCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in useCompleteSearchCombo.
function useCompleteSearchCombo_Callback(hObject, eventdata, handles)
% hObject    handle to useCompleteSearchCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns useCompleteSearchCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from useCompleteSearchCombo


% --- Executes during object creation, after setting all properties.
function useCompleteSearchCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to useCompleteSearchCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pollMethodCombo.
function pollMethodCombo_Callback(hObject, eventdata, handles)
% hObject    handle to pollMethodCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pollMethodCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pollMethodCombo


% --- Executes during object creation, after setting all properties.
function pollMethodCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pollMethodCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pollOrderCombo.
function pollOrderCombo_Callback(hObject, eventdata, handles)
% hObject    handle to pollOrderCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pollOrderCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pollOrderCombo


% --- Executes during object creation, after setting all properties.
function pollOrderCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pollOrderCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in useCompletePollCombo.
function useCompletePollCombo_Callback(hObject, eventdata, handles)
% hObject    handle to useCompletePollCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns useCompletePollCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from useCompletePollCombo


% --- Executes during object creation, after setting all properties.
function useCompletePollCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to useCompletePollCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu10.
function popupmenu10_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu10 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu10


% --- Executes during object creation, after setting all properties.
function popupmenu10_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu10 (see GCBO)
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
