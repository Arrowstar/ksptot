function varargout = vs_mainGUI(varargin)
% VS_MAINGUI MATLAB code for vs_mainGUI.fig
%      VS_MAINGUI, by itself, creates a new VS_MAINGUI or raises the existing
%      singleton*.
%
%      H = VS_MAINGUI returns the handle to a new VS_MAINGUI or the handle to
%      the existing singleton*.
%
%      VS_MAINGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VS_MAINGUI.M with the given input arguments.
%
%      VS_MAINGUI('Property','Value',...) creates a new VS_MAINGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before vs_mainGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to vs_mainGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help vs_mainGUI

% Last Modified by GUIDE v2.5 05-Apr-2019 23:17:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @vs_mainGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @vs_mainGUI_OutputFcn, ...
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


% --- Executes just before vs_mainGUI is made visible.
function vs_mainGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to vs_mainGUI (see VARARGIN)

    % Choose default command line output for vs_mainGUI
    handles.output = hObject;

    celBodyData = varargin{1};
    setappdata(hObject,'celBodyData',celBodyData);
    
    vsProb = VS_Problem.getDefaultVsProblem(celBodyData);
    setappdata(hObject,'vsProb',vsProb);
    
    populateBodiesCombo(celBodyData, handles.bodyCombo);
    
    populateGUI(vsProb, handles);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes vs_mainGUI wait for user response (see UIRESUME)
    % uiwait(handles.vs_mainGUI);
    
function populateGUI(vsProb, handles)
    set(handles.movePhaseUpButton,'String','<html>&uarr;');
    set(handles.movePhaseDownButton,'String','<html>&darr;');
    set(handles.moveStageUpButton,'String','<html>&uarr;');
    set(handles.moveStageDownButton,'String','<html>&darr;');
    
    jScrollPane = findjobj(handles.outputText);

    % Modify the scroll-pane's scrollbar policies
    set(jScrollPane,'VerticalScrollBarPolicy',20);  % or: jScrollPane.VERTICAL_SCROLLBAR_AS_NEEDED
    
    jViewPort = jScrollPane.getViewport;
    jEditbox = jViewPort.getComponent(0);
    jEditbox.setWrapping(false);  % do *NOT* use set(...)!!!
    jEditbox.setEditable(false);   
    set(jScrollPane,'HorizontalScrollBarPolicy',30);
    
    handles.phasesListbox.String = vsProb.getPhasesListboxStr();
    handles.phasesListbox.Value = 1;
    
    phasesListbox_Callback(handles.phasesListbox, [], handles);


% --- Outputs from this function are returned to the command line.
function varargout = vs_mainGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    varargout{1} = handles.output;


% --- Executes on selection change in stagesListbox.
function stagesListbox_Callback(hObject, eventdata, handles)
% hObject    handle to stagesListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns stagesListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from stagesListbox
    selStage = getSelectedStage(handles);
    
    handles.stageNameText.String = selStage.name;
    handles.stageIspText.String = fullAccNum2Str(selStage.isp);
    handles.dryMassFractionText.String = fullAccNum2Str(selStage.dryMassFrac);
    handles.desiredT2WText.String = fullAccNum2Str(selStage.desiredT2W);
    
    value = findValueFromComboBox(selStage.bodyInfo.name, handles.bodyCombo);
    if(not(isempty(value)))
        handles.bodyCombo.Value = value;
    end
    
    handles.isPayloadCheckbox.Value = double(selStage.isPayload);
    if(selStage.isPayload)
        handles.payloadMassText.Enable = 'on';
    else
        handles.payloadMassText.Enable = 'off';
    end
    
    handles.payloadMassText.String = fullAccNum2Str(selStage.dryMass/1000);
    
    
% --- Executes during object creation, after setting all properties.
function stagesListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stagesListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in phasesListbox.
function phasesListbox_Callback(hObject, eventdata, handles)
% hObject    handle to phasesListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns phasesListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from phasesListbox
    selPhase = getSelectedPhase(handles);
    
    handles.phaseNameText.String = selPhase.name;
    handles.phaseDvText.String = fullAccNum2Str(selPhase.phaseDv);
    
    handles.stagesListbox.String = selPhase.getStagesListboxStr();
    if(handles.stagesListbox.Value > length(selPhase.stages))
        handles.stagesListbox.Value = length(selPhase.stages);
    end
    
    handles.stagesPanel.Title = sprintf('Stages (Phase = %s)',selPhase.name);
    
    stagesListbox_Callback(handles.stagesListbox, [], handles);
    
    if(length(selPhase.stages) <= 1)
        handles.deleteStageButton.Enable = 'off';
    else
        handles.deleteStageButton.Enable = 'on';
    end
    
% --- Executes during object creation, after setting all properties.
function phasesListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to phasesListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function updatePhase(handles)
    vsProb = getappdata(handles.vs_mainGUI,'vsProb');
    selPhase = getSelectedPhase(handles);
    
    selPhase.name = handles.phaseNameText.String;
    handles.stagesPanel.Title = sprintf('Stages (Phase = %s)',selPhase.name);
    handles.phasesListbox.String = vsProb.getPhasesListboxStr();
    
    selPhase.phaseDv = str2double(handles.phaseDvText.String);
    
    phasesListbox_Callback(handles.phasesListbox, [], handles);
    
    
function updateStage(handles)
    celBodyData = getappdata(handles.vs_mainGUI,'celBodyData');
    
    selPhase = getSelectedPhase(handles);
    selStage = getSelectedStage(handles);
    
    selStage.name = handles.stageNameText.String;
    selStage.isp = str2double(handles.stageIspText.String);
    selStage.dryMassFrac = str2double(handles.dryMassFractionText.String);
    selStage.desiredT2W = str2double(handles.desiredT2WText.String);
    
    selBodyInd = handles.bodyCombo.Value;
    selBodyStr = lower(strtrim(handles.bodyCombo.String{selBodyInd}));
    selStage.bodyInfo = celBodyData.(selBodyStr);
    
    selStage.isPayload = logical(handles.isPayloadCheckbox.Value);
    if(selStage.isPayload)
        handles.payloadMassText.Enable = 'on';
    else
        handles.payloadMassText.Enable = 'off';
    end
    
    selStage.dryMass = str2double(handles.payloadMassText.String)*1000; %mT -> kg
    
    handles.stagesListbox.String = selPhase.getStagesListboxStr();
    if(handles.stagesListbox.Value > length(selPhase.stages))
        handles.stagesListbox.Value = length(selPhase.stages);
    end
    
    stagesListbox_Callback(handles.stagesListbox, [], handles);
    
    
function selPhase = getSelectedPhase(handles)
    vsProb = getappdata(handles.vs_mainGUI,'vsProb');
    
    selInd = get(handles.phasesListbox,'Value');
    selPhase = vsProb.getPhaseForInd(selInd);
    
function selStage = getSelectedStage(handles)
    selPhase = getSelectedPhase(handles);
    
    selInd = get(handles.stagesListbox,'Value');
    selStage = selPhase.getStageForInd(selInd);

function phaseNameText_Callback(hObject, eventdata, handles)
% hObject    handle to phaseNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of phaseNameText as text
%        str2double(get(hObject,'String')) returns contents of phaseNameText as a double
    updatePhase(handles);

% --- Executes during object creation, after setting all properties.
function phaseNameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to phaseNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function stageNameText_Callback(hObject, eventdata, handles)
% hObject    handle to stageNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of stageNameText as text
%        str2double(get(hObject,'String')) returns contents of stageNameText as a double
    updateStage(handles);

% --- Executes during object creation, after setting all properties.
function stageNameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stageNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function stageIspText_Callback(hObject, eventdata, handles)
% hObject    handle to stageIspLabel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of stageIspLabel as text
%        str2double(get(hObject,'String')) returns contents of stageIspLabel as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    errMsg = {};
    
    rawDouble = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Stage Engine Specific Impulse (Isp)';
    lb = 1;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(rawDouble, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(not(isempty(errMsg)))
        selStage = getSelectedStage(handles);
        hObject.String = fullAccNum2Str(selStage.isp);
        
        msgbox(errMsg,'Vehicle Sizing Tool Input Error','error');
    else
        updateStage(handles);
    end



function dryMassFractionText_Callback(hObject, eventdata, handles)
% hObject    handle to dryMassFractionText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dryMassFractionText as text
%        str2double(get(hObject,'String')) returns contents of dryMassFractionText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    errMsg = {};
    
    rawDouble = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Stage Dry Mass Fraction';
    lb = 0;
    ub = 1;
    isInt = false;
    errMsg = validateNumber(rawDouble, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(not(isempty(errMsg)))
        selStage = getSelectedStage(handles);
        hObject.String = fullAccNum2Str(selStage.dryMassFrac);
        
        msgbox(errMsg,'Vehicle Sizing Tool Input Error','error');
    else
        updateStage(handles);
    end


% --- Executes during object creation, after setting all properties.
function dryMassFractionText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dryMassFractionText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function desiredT2WText_Callback(hObject, eventdata, handles)
% hObject    handle to desiredT2WText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of desiredT2WText as text
%        str2double(get(hObject,'String')) returns contents of desiredT2WText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    errMsg = {};
    
    rawDouble = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Stage Desired Thrust to Weight Ratio';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(rawDouble, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(not(isempty(errMsg)))
        selStage = getSelectedStage(handles);
        hObject.String = fullAccNum2Str(selStage.desiredT2W);
        
        msgbox(errMsg,'Vehicle Sizing Tool Input Error','error');
    else
        updateStage(handles);
    end


% --- Executes during object creation, after setting all properties.
function desiredT2WText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to desiredT2WText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function phaseDvText_Callback(hObject, eventdata, handles)
% hObject    handle to phaseDvText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of phaseDvText as text
%        str2double(get(hObject,'String')) returns contents of phaseDvText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    errMsg = {};
    
    rawDouble = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Phase Delta-V';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(rawDouble, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(not(isempty(errMsg)))
        selPhase = getSelectedPhase(handles);
        hObject.String = fullAccNum2Str(selPhase.phaseDv);
        
        msgbox(errMsg,'Vehicle Sizing Tool Input Error','error');
    else
        updatePhase(handles);
    end

% --- Executes during object creation, after setting all properties.
function phaseDvText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to phaseDvText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in bodyCombo.
function bodyCombo_Callback(hObject, eventdata, handles)
% hObject    handle to bodyCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns bodyCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from bodyCombo
	updateStage(handles);

% --- Executes during object creation, after setting all properties.
function bodyCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bodyCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in isPayloadCheckbox.
function isPayloadCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to isPayloadCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of isPayloadCheckbox
    updateStage(handles);


function outputText_Callback(hObject, eventdata, handles)
% hObject    handle to outputText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of outputText as text
%        str2double(get(hObject,'String')) returns contents of outputText as a double


% --- Executes during object creation, after setting all properties.
function outputText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to outputText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function stageIspLabel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stageIspLabel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function isPayloadCheckbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to isPayloadCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in runSizingButton.
function runSizingButton_Callback(hObject, eventdata, handles)
% hObject    handle to runSizingButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    vsProb = getappdata(handles.vs_mainGUI,'vsProb');
    initStage = vsProb.getProblemState();
    
    try
%         handles.runSizingButton.Enable = 'off';
        drawnow;
        
        hWaitbar = waitbar(0,'Running Vehicle Sizing Analysis...');
        
        [~,~,exitflag,output] = vsProb.sizeVehicle();
        
        waitbar(1,hWaitbar,'Analysis Complete!');
        pause(0.1);
        
        if(isvalid(hWaitbar))
            close(hWaitbar);
        end
        
        handles.runSizingButton.Enable = 'on';
        handles.outputText.String = vsProb.getProblemOutputStr(exitflag,output);
        
        jhEdit = findjobj(handles.outputText);
        jEdit = jhEdit.getComponent(0).getComponent(0);
        jEdit.setCaretPosition(0);
    catch ME
        vsProb.updateStagesWithVars(initStage);
        
        handles.runSizingButton.Enable = 'on';
        
        if(isvalid(hWaitbar))
            close(hWaitbar);
        end
        
        errorText = sprintf('An error was encountered during the vehicle sizing analysis.  Please verify your inputs (especially Isp values) and try again.  Error text:\n\n%s',ME.message);
        errordlg(errorText,'Vehicle Sizing Tool','modal');
    end
    
    
    

% --- Executes during object creation, after setting all properties.
function stageIspText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stageIspText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addPhaseButton.
function addPhaseButton_Callback(hObject, eventdata, handles)
% hObject    handle to addPhaseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    celBodyData = getappdata(handles.vs_mainGUI,'celBodyData');
    vsProb = getappdata(handles.vs_mainGUI,'vsProb');
    
    bodyNames = fields(celBodyData);
    bodyInfo = celBodyData.(bodyNames{1});

    newPhase = VS_Phase(vsProb);
    vsProb.addPhase(newPhase);
    
    newStage = VS_Stage(newPhase);
    newStage.bodyInfo = bodyInfo;
    newPhase.addStage(newStage);
    
    handles.phasesListbox.String = vsProb.getPhasesListboxStr();
    handles.phasesListbox.Value = length(vsProb.phases);
    phasesListbox_Callback(handles.phasesListbox, [], handles);

    handles.deletePhaseButton.Enable = 'on';
    
    
% --- Executes on button press in deletePhaseButton.
function deletePhaseButton_Callback(hObject, eventdata, handles)
% hObject    handle to deletePhaseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    vsProb = getappdata(handles.vs_mainGUI,'vsProb');
    
    selPhase = getSelectedPhase(handles);
    vsProb.removePhase(selPhase);
    
    if(handles.phasesListbox.Value > length(vsProb.phases))
        handles.phasesListbox.Value = length(vsProb.phases);
    end
    
    handles.phasesListbox.String = vsProb.getPhasesListboxStr();
    phasesListbox_Callback(handles.phasesListbox, [], handles);
    
    if(length(vsProb.phases) <= 1)
        handles.deletePhaseButton.Enable = 'off';
    else
        handles.deletePhaseButton.Enable = 'on';
    end
    
% --- Executes on button press in addStageButton.
function addStageButton_Callback(hObject, eventdata, handles)
% hObject    handle to addStageButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    celBodyData = getappdata(handles.vs_mainGUI,'celBodyData');
    selPhase = getSelectedPhase(handles);
    
    bodyNames = fields(celBodyData);
    bodyInfo = celBodyData.(bodyNames{1});
    
    newStage = VS_Stage(selPhase);
    newStage.bodyInfo = bodyInfo;
    selPhase.addStage(newStage);
    
    phasesListbox_Callback(handles.phasesListbox, [], handles);

    handles.deleteStageButton.Enable = 'on';
    
    
% --- Executes on button press in deleteStageButton.
function deleteStageButton_Callback(hObject, eventdata, handles)
% hObject    handle to deleteStageButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    selPhase = getSelectedPhase(handles);
    selStage = getSelectedStage(handles);
    
    selPhase.removeStage(selStage);
    phasesListbox_Callback(handles.phasesListbox, eventdata, handles);
    
    if(length(selPhase.stages) <= 1)
        handles.deleteStageButton.Enable = 'off';
    else
        handles.deleteStageButton.Enable = 'on';
    end



function payloadMassText_Callback(hObject, eventdata, handles)
% hObject    handle to payloadMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of payloadMassText as text
%        str2double(get(hObject,'String')) returns contents of payloadMassText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    errMsg = {};
    
    rawDouble = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Stage Payload Mass';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(rawDouble, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(not(isempty(errMsg)))
        selStage = getSelectedStage(handles);
        hObject.String = fullAccNum2Str(selStage.dryMass/1000);
        
        msgbox(errMsg,'Vehicle Sizing Tool Input Error','error');
    else
        updateStage(handles);
    end

% --- Executes during object creation, after setting all properties.
function payloadMassText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to payloadMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function fileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to fileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function loadVstCaseMenu_Callback(hObject, eventdata, handles)
% hObject    handle to loadVstCaseMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    [FileName,PathName] = uigetfile({'*.mat','KSP TOT Vehicle Sizing Tool Case File (*.mat)'},...
                                                'Open Vehicle Sizing Tool Case',...
                                                'vstCase.mat');
    if(ischar(FileName) && ischar(PathName))
        filePath = [PathName,FileName];
    else
        return;
    end
    
    if(ischar(filePath))
        load(filePath); %#ok<LOAD>
        
        if(exist('vsProb','var'))
            setappdata(handles.vs_mainGUI,'vsProb',vsProb);
            
            populateGUI(vsProb, handles);
        end
    end

% --------------------------------------------------------------------
function saveVstCaseMenu_Callback(hObject, eventdata, handles)
% hObject    handle to saveVstCaseMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    [FileName,PathName] = uiputfile({'*.mat','KSP TOT Vehicle Sizing Tool Case File (*.mat)'},...
                                                'Open Vehicle Sizing Tool Case',...
                                                'vstCase.mat');
    if(ischar(FileName) && ischar(PathName))
        filePath = [PathName,FileName];
    else
        return;
    end
                                            
    if(ischar(FileName) && ischar(PathName))
    	vsProb = getappdata(handles.vs_mainGUI,'vsProb');
        save(filePath,'vsProb');
    end


% --- Executes on button press in moveStageUpButton.
function moveStageUpButton_Callback(hObject, eventdata, handles)
% hObject    handle to moveStageUpButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    selPhase = getSelectedPhase(handles);
    selStage = getSelectedStage(handles);
    
    stageInd = selPhase.getIndOfStage(selStage);
    selPhase.moveStageUp(selStage);
    
    if(stageInd>1)
        set(handles.stagesListbox,'Value',stageInd-1);
    end
    
    set(handles.stagesListbox,'String',selPhase.getStagesListboxStr());

% --- Executes on button press in moveStageDownButton.
function moveStageDownButton_Callback(hObject, eventdata, handles)
% hObject    handle to moveStageDownButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    selPhase = getSelectedPhase(handles);
    selStage = getSelectedStage(handles);
    
    stageInd = selPhase.getIndOfStage(selStage);
    selPhase.moveStageDown(selStage);
    
    numStages = length(selPhase.stages);
    if(stageInd<numStages)
        set(handles.stagesListbox,'Value',stageInd+1);
    end
    
    set(handles.stagesListbox,'String',selPhase.getStagesListboxStr());

% --- Executes on button press in movePhaseUpButton.
function movePhaseUpButton_Callback(hObject, eventdata, handles)
% hObject    handle to movePhaseUpButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    vsProb = getappdata(handles.vs_mainGUI,'vsProb');
    selPhase = getSelectedPhase(handles);
    
    phaseInd = vsProb.getIndOfPhase(selPhase);
    vsProb.movePhaseUp(selPhase);
    
    if(phaseInd>1)
        set(handles.phasesListbox,'Value',phaseInd-1);
    end
    
    set(handles.phasesListbox,'String',vsProb.getPhasesListboxStr());
    
% --- Executes on button press in movePhaseDownButton.
function movePhaseDownButton_Callback(hObject, eventdata, handles)
% hObject    handle to movePhaseDownButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    vsProb = getappdata(handles.vs_mainGUI,'vsProb');
    selPhase = getSelectedPhase(handles);
    
    phaseInd = vsProb.getIndOfPhase(selPhase);
    vsProb.movePhaseDown(selPhase);
    
    numPhases = length(vsProb.phases);
    if(phaseInd<numPhases)
        set(handles.phasesListbox,'Value',phaseInd+1);
    end
    
    set(handles.phasesListbox,'String',vsProb.getPhasesListboxStr());