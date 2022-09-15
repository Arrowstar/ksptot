function varargout = lvd_editSurrogateOptOptionsGUI(varargin)
% LVD_EDITSURROGATEOPTOPTIONSGUI MATLAB code for lvd_editSurrogateOptOptionsGUI.fig
%      LVD_EDITSURROGATEOPTOPTIONSGUI, by itself, creates a new LVD_EDITSURROGATEOPTOPTIONSGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITSURROGATEOPTOPTIONSGUI returns the handle to a new LVD_EDITSURROGATEOPTOPTIONSGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITSURROGATEOPTOPTIONSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITSURROGATEOPTOPTIONSGUI.M with the given input arguments.
%
%      LVD_EDITSURROGATEOPTOPTIONSGUI('Property','Value',...) creates a new LVD_EDITSURROGATEOPTOPTIONSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_editSurrogateOptOptionsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_editSurrogateOptOptionsGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_editSurrogateOptOptionsGUI

% Last Modified by GUIDE v2.5 18-Mar-2021 20:44:53

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_editSurrogateOptOptionsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_editSurrogateOptOptionsGUI_OutputFcn, ...
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


% --- Executes just before lvd_editSurrogateOptOptionsGUI is made visible.
function lvd_editSurrogateOptOptionsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to lvd_editSurrogateOptOptionsGUI (see VARARGIN)

% Choose default command line output for lvd_editSurrogateOptOptionsGUI
    handles.output = hObject;
    
    centerUIFigure(hObject);

    surrogateOpt = varargin{1};
    setappdata(hObject,'surrogateOpt',surrogateOpt);

    handles = populateGUI(handles, surrogateOpt);

    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_editSurrogateOptOptionsGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_editSurrogateOptOptionsGUI);

function handles = populateGUI(handles, surrogateOpt)
    options = surrogateOpt.getOptions();
    
    setDocLbl(handles);
       
    useParaStr = SurrogateOptUseParallelEnum.getListBoxStr();
    handles.useParallelCombo.String = useParaStr;
    handles.useParallelCombo.Value = SurrogateOptUseParallelEnum.getIndForName(options.useParallel.name);
    
    setOptsDoubleValueStrInGUI(handles, options, 'tolCon', 'conTolText');
    
    setOptsDoubleValueStrInGUI(handles, options, 'maxFuncEvals', 'maxFuncEvalsText');
    
    setOptsDoubleValueStrInGUI(handles, options, 'batchUpdateInterval', 'batchUpdateIntervalText');
    setOptsDoubleValueStrInGUI(handles, options, 'minSampleDistance', 'minSampleDistanceText');
    setOptsDoubleValueStrInGUI(handles, options, 'minSurrogatePoints', 'minSurrogatePointsText');
       
    setOptsDoubleValueStrInGUI(handles, options, 'numWorkers', 'numParaWorkersText');

    
function setDocLbl(handles)
    docLinkLblPos = handles.matlabDocLinkLabel.Position;
    docLinkLblParent = handles.matlabDocLinkLabel.Parent;
    handles.matlabDocLinkLabel.Visible = 'off';
    
    % Create and display the text label
    url = 'https://www.mathworks.com/help/gads/surrogate-optimization.html';
    labelStr = ['<html><div style=''text-align: center;''>For more information, visit the MATLAB documentation for Surrogate Optimizer: <a href="">' url '</a></div></html>'];
    jLabel = javaObjectEDT('javax.swing.JLabel', labelStr);
    [hjLabel,~] = javacomponent(jLabel, docLinkLblPos, docLinkLblParent);

    % Modify the mouse cursor when hovering on the label
    hjLabel.setCursor(java.awt.Cursor.getPredefinedCursor(java.awt.Cursor.HAND_CURSOR));

    % Set the mouse-click callback
    set(hjLabel, 'MouseClickedCallback', @(h,e)web([url], '-browser'));

% --- Outputs from this function are returned to the command line.
function varargout = lvd_editSurrogateOptOptionsGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        surrogateOpt = getappdata(hObject,'surrogateOpt');
        options = surrogateOpt.getOptions();
        
        useParaStrs = SurrogateOptUseParallelEnum.getListBoxStr();
        options.useParallel = SurrogateOptUseParallelEnum.getEnumForListboxStr(useParaStrs{handles.useParallelCombo.Value});
        
        setOptsDoubleValueInObject(handles, options, 'tolCon', 'conTolText');

        setOptsDoubleValueInObject(handles, options, 'maxFuncEvals', 'maxFuncEvalsText');

        setOptsDoubleValueInObject(handles, options, 'batchUpdateInterval', 'batchUpdateIntervalText');
        setOptsDoubleValueInObject(handles, options, 'minSampleDistance', 'minSampleDistanceText');
        setOptsDoubleValueInObject(handles, options, 'minSurrogatePoints', 'minSurrogatePointsText');
        
        setOptsDoubleValueInObject(handles, options, 'numWorkers', 'numParaWorkersText');
        
        varargout{1} = true;
        close(handles.lvd_editSurrogateOptOptionsGUI);
    end
   
    
function errMsg = validateInputs(handles)
    errMsg = {};

    errMsg = validateDoubleValue(handles, errMsg, 'conTolText', 'Constraint Tolerance', 0, 1, false);
    
    errMsg = validateDoubleValue(handles, errMsg, 'maxFuncEvalsText', 'Max Function Evaluations', 0, Inf, true);

	errMsg = validateDoubleValue(handles, errMsg, 'batchUpdateIntervalText', 'Batch Update Interval', 1, Inf, true);
    errMsg = validateDoubleValue(handles, errMsg, 'minSampleDistanceText', 'Minimum Sample Distance', 1E-10, Inf, false);
    errMsg = validateDoubleValue(handles, errMsg, 'minSurrogatePointsText', 'Minimum Number of Surrogate Points', 1, Inf, true);
     
    errMsg = validateDoubleValue(handles, errMsg, 'numParaWorkersText', 'Number of Parallel Workers', 1, feature('numCores'), true);


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


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_editSurrogateOptOptionsGUI);
    else
        msgbox(errMsg,'Invalid FMINCON Options Inputs','error');
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


function minSurrogatePointsText_Callback(hObject, eventdata, handles)
% hObject    handle to minSurrogatePointsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of minSurrogatePointsText as text
%        str2double(get(hObject,'String')) returns contents of minSurrogatePointsText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function minSurrogatePointsText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to minSurrogatePointsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function minSampleDistanceText_Callback(hObject, eventdata, handles)
% hObject    handle to minSampleDistanceText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of minSampleDistanceText as text
%        str2double(get(hObject,'String')) returns contents of minSampleDistanceText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function minSampleDistanceText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to minSampleDistanceText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function batchUpdateIntervalText_Callback(hObject, eventdata, handles)
% hObject    handle to batchUpdateIntervalText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of batchUpdateIntervalText as text
%        str2double(get(hObject,'String')) returns contents of batchUpdateIntervalText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function batchUpdateIntervalText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to batchUpdateIntervalText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
