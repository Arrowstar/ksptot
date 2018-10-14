function varargout = ma_LvdMainGUI(varargin)
% MA_LVDMAINGUI MATLAB code for ma_LvdMainGUI.fig
%      MA_LVDMAINGUI, by itself, creates a new MA_LVDMAINGUI or raises the existing
%      singleton*.
%
%      H = MA_LVDMAINGUI returns the handle to a new MA_LVDMAINGUI or the handle to
%      the existing singleton*.
%
%      MA_LVDMAINGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_LVDMAINGUI.M with the given input arguments.
%
%      MA_LVDMAINGUI('Property','Value',...) creates a new MA_LVDMAINGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_LvdMainGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_LvdMainGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_LvdMainGUI

% Last Modified by GUIDE v2.5 14-Oct-2018 15:17:09

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_LvdMainGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_LvdMainGUI_OutputFcn, ...
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


% --- Executes just before ma_LvdMainGUI is made visible.
function ma_LvdMainGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_LvdMainGUI (see VARARGIN)

    % Choose default command line output for ma_LvdMainGUI
    handles.output = hObject;

    celBodyData = varargin{1};
    setappdata(hObject,'celBodyData',celBodyData);
    
    setappdata(hObject,'ksptotMainGUI',varargin{2});

    setappdata(hObject,'current_save_location','');
    setappdata(hObject,'application_title','KSP TOT Launch Vehicle Designer');
    setappdata(hObject,'undoRedo',LVD_UndoRedoStateSet());
    
    lvdData = LvdData.getDefaultLvdData(celBodyData);
	setappdata(handles.ma_LvdMainGUI,'lvdData',lvdData);

    output_text_max_line_length = length(getMA_HR());
    setappdata(hObject,'output_text_max_line_length',output_text_max_line_length);
    writeOutput = @(str,type) writeToMAOutput(handles.outputText, str, type, output_text_max_line_length);
    setappdata(hObject,'write_to_output_func',writeOutput);
    
    initializeOutputWindowText(handles, handles.outputText);
    view(handles.dispAxes,3);
    
    runScript(handles, lvdData);
    lvd_processData(handles);

    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes ma_LvdMainGUI wait for user response (see UIRESUME)
    % uiwait(handles.ma_LvdMainGUI);
  
function initializeOutputWindowText(handles, hOutputText) 
    write_to_output_func = getappdata(handles.ma_LvdMainGUI,'write_to_output_func');

    set(hOutputText,'String',' ');
    statusBoxMsg = {['KSP TOT Launch Vehicle Designer v', getKSPTOTVersionNumStr(), sprintf(' (R%s)', version('-release'))], 'Written By Arrowstar (C) 2018', ...
                    getMA_HR()};
	for(i=1:size(statusBoxMsg,2)) %#ok<ALIGN,*NO4LP>
        if(i==1)
            write_to_output_func(statusBoxMsg{i},'overwrite');
        else
            write_to_output_func(statusBoxMsg{i},'appendNoDate');
        end
    end

    
function runScript(handles, lvdData)
    writeOutput = getappdata(handles.ma_LvdMainGUI,'write_to_output_func');
    
    handles.scriptWorkingLbl.Visible = 'on';
    drawnow;
    
%     profile('on','-detail','builtin', '-remove_overhead','on');
    
    t = tic;
    lvdData.script.executeScript();
    execTime = toc(t);
    
%     profile viewer;
    
    handles.scriptWorkingLbl.Visible = 'off';
    handles.warnAlertsSlider.Value = 0;    
    
    lvdData.validation.validate();
    updateWarnErrorLabels(handles, true);
    
    writeOutput(sprintf('Executed mission script in %.3f seconds.',execTime),'append');
    drawnow;

% --- Outputs from this function are returned to the command line.
function varargout = ma_LvdMainGUI_OutputFcn(hObject, eventdata, handles) 
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Get default command line output from handles structure
    varargout{1} = handles.output;

    
function addUndoState(handles,actionName)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    undoRedo = getappdata(handles.ma_LvdMainGUI,'undoRedo');
    
    undoRedo.addState(handles.ma_LvdMainGUI, lvdData, actionName)

% --- Executes on selection change in scriptListbox.
function scriptListbox_Callback(hObject, eventdata, handles)
% hObject    handle to scriptListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns scriptListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from scriptListbox
    if(strcmpi(get(handles.ma_LvdMainGUI,'SelectionType'),'open'))
        addUndoState(handles,'Edit Event');
        
        eventNum = get(hObject,'Value');
        lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
        
        event = lvdData.script.getEventForInd(eventNum);
        lvd_editEventGUI(event);
        
        runScript(handles, lvdData);
        
        lvd_processData(handles);
    end

% --- Executes during object creation, after setting all properties.
function scriptListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scriptListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in insertEventButton.
function insertEventButton_Callback(hObject, eventdata, handles)
% hObject    handle to insertEventButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');

    addUndoState(handles,'Insert Event');
    
    selEvtNum = get(handles.scriptListbox,'Value');
    event = LaunchVehicleEvent.getDefaultEvent(lvdData.script);
    lvdData.script.addEventAtInd(event,selEvtNum);
    lvd_editEventGUI(event);
    
	handles.deleteEvent.Enable = 'on';

    runScript(handles, lvdData);
    lvd_processData(handles);

% --- Executes on button press in moveEventDown.
function moveEventDown_Callback(hObject, eventdata, handles)
% hObject    handle to moveEventDown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');

    addUndoState(handles,'Move Event Down');
    
    eventNum = get(handles.scriptListbox,'Value');
    lvdData.script.moveEvtAtIndexDown(eventNum);
    
    if(eventNum < length(lvdData.script.evts))
        set(handles.scriptListbox,'Value',eventNum+1);
    end
    
    runScript(handles, lvdData);
    lvd_processData(handles);
    
% --- Executes on button press in deleteEvent.
function deleteEvent_Callback(hObject, eventdata, handles)
% hObject    handle to deleteEvent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
    addUndoState(handles,'Delete Event');
    
    eventNum = get(handles.scriptListbox,'Value');
    evt = lvdData.script.getEventForInd(eventNum);
    
    lvdData.optimizer.constraints.removeConstraintsThatUseEvent(evt);
    
    if(lvdData.optimizer.objFcn.usesEvent(evt))
        lvdData.optimizer.objFcn = NoOptimizationObjectiveFcn(lvdData.optimizer, lvdData);
        
        warndlg(sprintf('The existing objective function referenced the deleted event.  The objective function has been replaced with a "%s" objective function.',ObjectiveFunctionEnum.NoObjectiveFunction.name),'Objective Function Reset','modal');
    end
    
    lvdData.script.removeEventFromIndex(eventNum);
    
    if(eventNum > length(lvdData.script.evts))
        set(handles.scriptListbox,'Value',length(lvdData.script.evts));
    end
    
    numEventsRemaining = lvdData.script.getTotalNumOfEvents();
    if(numEventsRemaining <= 1)
        handles.deleteEvent.Enable = 'off';
    end
    
    runScript(handles, lvdData);
    lvd_processData(handles);

% --- Executes on button press in moveEventUp.
function moveEventUp_Callback(hObject, eventdata, handles)
% hObject    handle to moveEventUp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
    addUndoState(handles,'Move Event Up');
    
    eventNum = get(handles.scriptListbox,'Value');
    lvdData.script.moveEvtAtIndexUp(eventNum);
    
    if(eventNum > 1)
        set(handles.scriptListbox,'Value',eventNum-1);
    end
    
    runScript(handles, lvdData);
    lvd_processData(handles);


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


% --- Executes on button press in decrOrbitToPlotNum.
function decrOrbitToPlotNum_Callback(hObject, eventdata, handles)
% hObject    handle to decrOrbitToPlotNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in incrOrbitToPlotNum.
function incrOrbitToPlotNum_Callback(hObject, eventdata, handles)
% hObject    handle to incrOrbitToPlotNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on slider movement.
function warnAlertsSlider_Callback(hObject, eventdata, handles)
% hObject    handle to warnAlertsSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    updateWarnErrorLabels(handles, false);

function updateWarnErrorLabels(handles, updateSlider)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');    

    hLabels = [handles.warning1Lbl, handles.warning2Lbl, handles.warning3Lbl, ...
              handles.warning4Lbl, handles.warning5Lbl, handles.warning6Lbl];
    
    lvdData.validation.writeOutputsToUI(handles.warnAlertsSlider, hLabels, updateSlider);
    
    
% --- Executes during object creation, after setting all properties.
function warnAlertsSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to warnAlertsSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --------------------------------------------------------------------
function optimizationMenu_Callback(hObject, eventdata, handles)
% hObject    handle to optimizationMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function optimizeMissionMenu_Callback(hObject, eventdata, handles)
% hObject    handle to optimizeMissionMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    writeOutput = getappdata(handles.ma_LvdMainGUI,'write_to_output_func');
    
    addUndoState(handles,'Optimize Mission');
    
    lvdData.optimizer.optimize(writeOutput);
    
    runScript(handles, lvdData);
    lvd_processData(handles);

% --------------------------------------------------------------------
function launchVehicleMenu_Callback(hObject, eventdata, handles)
% hObject    handle to launchVehicleMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function editLaunchVehicleMenu_Callback(hObject, eventdata, handles)
% hObject    handle to editLaunchVehicleMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
    addUndoState(handles,'Edit Launch Vehicle');
    
    lvd_editLaunchVehicle(lvdData);
    
    runScript(handles, lvdData);
    lvd_processData(handles);


% --------------------------------------------------------------------
function editObjFunctionMenu_Callback(hObject, eventdata, handles)
% hObject    handle to editObjFunctionMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    lvd_EditObjectiveFunctionGUI(lvdData);

% --------------------------------------------------------------------
function editConstraintsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to editConstraintsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
    addUndoState(handles,'Edit Constraints');
    
    lvd_EditConstraintsGUI(lvdData);
    
    runScript(handles, lvdData);
    lvd_processData(handles);
    
% --------------------------------------------------------------------
function editInitialStateMenu_Callback(hObject, eventdata, handles)
% hObject    handle to editInitialStateMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    hKsptotMainGUI = getappdata(handles.ma_LvdMainGUI,'ksptotMainGUI');
    
    addUndoState(handles,'Edit Initial State');
    
    lvd_EditInitialStateGUI(lvdData, hKsptotMainGUI);
    
    runScript(handles, lvdData);
    lvd_processData(handles);

% --------------------------------------------------------------------
function viewStateAfterSelectedEventMenu_Callback(hObject, eventdata, handles)
% hObject    handle to viewStateAfterSelectedEventMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
    eventNum = handles.scriptListbox.Value;
    stateLog = lvdData.stateLog.getMAFormattedStateLogMatrix();
    
    state = stateLog(stateLog(:,13)==eventNum,:);
    state = state(end,:);

    propNames = {'Fuel/Ox', 'Monoprop', 'Xenon'};
    viewSpacecraftStatePopupGUI(propNames, state, eventNum, lvdData.celBodyData);

% --------------------------------------------------------------------
function copyUtAtStartOfSelEventMenu_Callback(hObject, eventdata, handles)
% hObject    handle to copyUtAtStartOfSelEventMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
    eventNum = handles.scriptListbox.Value;
    stateLog = lvdData.stateLog.getMAFormattedStateLogMatrix();
    
    state = stateLog(stateLog(:,13)==eventNum,:);
    state = state(1,:);
    
    clipboard('copy', fullAccNum2Str(state(1,1)));

% --------------------------------------------------------------------
function copyUtAtEndOfSelEventMenu_Callback(hObject, eventdata, handles)
% hObject    handle to copyUtAtEndOfSelEventMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
    eventNum = handles.scriptListbox.Value;
    stateLog = lvdData.stateLog.getMAFormattedStateLogMatrix();
    
    state = stateLog(stateLog(:,13)==eventNum,:);
    state = state(end,:);
    
    clipboard('copy', fullAccNum2Str(state(1,1)));

% --------------------------------------------------------------------
function copyDurationOfSelEventMenu_Callback(hObject, eventdata, handles)
% hObject    handle to copyDurationOfSelEventMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
    eventNum = handles.scriptListbox.Value;
    stateLog = lvdData.stateLog.getMAFormattedStateLogMatrix();
    
    eventLog = stateLog(stateLog(:,13)==eventNum,:);
    duration = max(eventLog(:,1)) - min(eventLog(:,1));
    
    clipboard('copy', fullAccNum2Str(duration));

% --------------------------------------------------------------------
function copyOrbitAfterSelectedEventMenu_Callback(hObject, eventdata, handles)
% hObject    handle to copyOrbitAfterSelectedEventMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    celBodyData = getappdata(handles.ma_LvdMainGUI,'celBodyData');
    
    eventNum = handles.scriptListbox.Value;
    stateLog = lvdData.stateLog.getMAFormattedStateLogMatrix();    
    
    state = stateLog(stateLog(:,13)==eventNum,:);
    state = state(end,:);
    
    bodyID = state(8);
    
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    gmu = bodyInfo.gm;
    utSec = state(1);
    rVect = state(2:4)';
    vVect = state(5:7)';
 
    [sma, ecc, inc, raan, arg, tru] = getKeplerFromState(rVect,vVect,gmu);
    clipboardData = [utSec, sma, ecc, inc, raan, arg, tru, bodyID];
    set(handles.copyOrbitAfterSelectedEventMenu,'UserData',clipboardData);
    copyOrbitToClipboardFromStateLog([],[],handles.copyOrbitAfterSelectedEventMenu);


% --------------------------------------------------------------------
function clearOutputMenu_Callback(hObject, eventdata, handles)
% hObject    handle to clearOutputMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    initializeOutputWindowText(handles, handles.outputText);

% --------------------------------------------------------------------
function outputContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to outputContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function fileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to fileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


function saved = isMissionPlanSaved(handles)
    application_title = get(handles.ma_LvdMainGUI,'Name');
    if(application_title(end) == '*')
        saved = false;
    else
        saved = true;
    end

% --------------------------------------------------------------------
function newMissionPlanMenu_Callback(hObject, eventdata, handles, varargin)
% hObject    handle to newMissionPlanMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if(~isempty(varargin))
        askToClear = varargin{1};
    else
        if(isMissionPlanSaved(handles))
            askToClear = false;
        else
            askToClear = true;
        end
    end
    if(askToClear)
        response = questdlg(['All unsaved work will be lost.  Continue?'],'Create new mission plan?','Yes','No','No');
    else
        response = 'Yes';
    end
    
    if(~strcmpi(response,'Yes'))
        return;
    end
    
    setappdata(handles.ma_LvdMainGUI,'undoRedo',LVD_UndoRedoStateSet());

    celBodyData = getappdata(handles.ma_LvdMainGUI,'celBodyData');
    write_to_output_func = getappdata(handles.ma_LvdMainGUI,'write_to_output_func');
    application_title = getappdata(handles.ma_LvdMainGUI,'application_title');
    if(askToClear)
        write_to_output_func('Creating new mission plan... ','append');
    end
    
    lvdData = LvdData.getDefaultLvdData(celBodyData);
    setappdata(handles.ma_LvdMainGUI,'lvdData',lvdData);
    setappdata(handles.ma_LvdMainGUI,'current_save_location','');
    
    runScript(handles, lvdData);
    lvd_processData(handles);
    
    set(handles.ma_LvdMainGUI,'Name', application_title);
    
    if(askToClear)
        write_to_output_func(['Done.'],'appendSameLine'); %#ok<*NBRAK>
    end
    
    set(handles.newMissionPlanToolbar,'Enable','on');
    set(handles.openMissionPlanToolbar,'Enable','on');
    set(handles.saveMissionPlanToolbar,'Enable','on');

% --------------------------------------------------------------------
function openMissionPlanMenu_Callback(hObject, eventdata, handles)
% hObject    handle to openMissionPlanMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if(isMissionPlanSaved(handles))
        askToClear = false;
    else
        askToClear = true;
    end
    
    if(askToClear)
        response = questdlg(['All unsaved work will be lost.  Continue?'],'Open mission plan?','Yes','No','No');
    else
        response = 'Yes';
    end
    
    if(~strcmpi(response,'Yes'))
        return;
    end
    
    celBodyData = getappdata(handles.ma_LvdMainGUI,'celBodyData');
    write_to_output_func = getappdata(handles.ma_LvdMainGUI,'write_to_output_func');
    application_title = getappdata(handles.ma_LvdMainGUI,'application_title');
    
    [FileName,PathName] = uigetfile({'*.mat','KSP TOT Launch Vehicle Designer Case File (*.mat)'},...
                                                'Open Launch Vehicle Designer Case',...
                                                'mission.mat');
	filePath = [PathName,FileName];
    
    if(ischar(filePath))
        write_to_output_func(['Loading mission case from "', filePath,'"... '],'append');
        
        load(filePath);
        if(exist('lvdData','var'))
            setappdata(handles.ma_LvdMainGUI,'undoRedo',LVD_UndoRedoStateSet());

            if(isfield(lvdData,'celBodyData') && ...
               length(fields(celBodyData.sun)) == length(fields(lvdData.celBodyData.sun))) %#ok<NODEF>
                celBodyData = lvdData.celBodyData;
                setappdata(handles.ma_LvdMainGUI,'celBodyData',celBodyData);
            else
                lvdData.celBodyData = celBodyData;
            end
            
            set(handles.ma_LvdMainGUI,'Name',[application_title, ' - ', filePath]);
            write_to_output_func(['Done.'],'appendSameLine');
            
            setappdata(handles.ma_LvdMainGUI,'lvdData',lvdData);
            setappdata(handles.ma_LvdMainGUI,'current_save_location',filePath);
            
            runScript(handles, lvdData);
            lvd_processData(handles);
            
%             if(~strcmpi(maData.settings.gravParamType,options_gravParamType))
%                 warndlg(sprintf(['Warning!  It appears this mission plan file was created with a different Gravitational Paramter mode than is currently in use in KSPTOT.  This may cause your misson to fail to propagate properly.\n\n', ...
%                                  'The expected GM type is "%s". \n\n', ...
%                                  'The GM type actually in use now is "%s".\n\n', ...
%                                  'Switch your GM type back to "%s" on the main KSPTOT UI if needed (Edit -> Gravitational Parameter).'], ...
%                                  maData.settings.gravParamType, ...
%                                  options_gravParamType, ...
%                                  maData.settings.gravParamType),'GM Type Warning','modal');
%             end
        else
            write_to_output_func(['There was a problem loading the case file from disk: ',filePath,'.  Case not loaded.'],'append');           
        end
    end
    
    set(handles.newMissionPlanToolbar,'Enable','on');
    set(handles.openMissionPlanToolbar,'Enable','on');
    set(handles.saveMissionPlanToolbar,'Enable','on');

% --------------------------------------------------------------------
function saveMissionPlanMenu_Callback(hObject, eventdata, handles)
% hObject    handle to saveMissionPlanMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    current_save_location = getappdata(handles.ma_LvdMainGUI,'current_save_location');
    if(isempty(current_save_location))
        saveMissionAs(handles);
    else
        saveMission(handles,current_save_location);
    end
    
    set(handles.newMissionPlanToolbar,'Enable','on');
    set(handles.openMissionPlanToolbar,'Enable','on');
    set(handles.saveMissionPlanToolbar,'Enable','on');

% --------------------------------------------------------------------
function saveAsMissionPlanMenu_Callback(hObject, eventdata, handles)
% hObject    handle to saveAsMissionPlanMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    saveMissionAs(handles);

    set(handles.newMissionPlanToolbar,'Enable','on');
    set(handles.openMissionPlanToolbar,'Enable','on');
    set(handles.saveMissionPlanToolbar,'Enable','on');
    
function saveMission(handles, varargin)
    if(length(varargin) == 1)
        filePath = varargin{1};
    else
        [FileName,PathName] = uiputfile({'*.mat','KSP TOT Launch Vehicle Designer Case File (*.mat)'},...
                                                    'Save Launch Vehicle Designer Case',...
                                                    'mission.mat');
        if(ischar(FileName) && ischar(PathName))
            filePath = [PathName,FileName];
        else
            return;
        end
    end
    
    write_to_output_func = getappdata(handles.ma_LvdMainGUI,'write_to_output_func');
    write_to_output_func(['Saving mission case as "', filePath,'"... '],'append');
    
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    lvdData.ksptotVer = getKSPTOTVersionNumStr();
    
    save(filePath,'lvdData');
    application_title = getappdata(handles.ma_LvdMainGUI,'application_title');
    
    set(handles.ma_LvdMainGUI,'Name',[application_title, ' - ', filePath]);
    setappdata(handles.ma_LvdMainGUI,'current_save_location',filePath);
    
    write_to_output_func(['Done.'],'appendSameLine');
    
function saveMissionAs(handles)
    [FileName,PathName] = uiputfile({'*.mat','KSP TOT Launch Vehicle Designer Case File (*.mat)'},...
                                                'Save Launch Vehicle Designer Case',...
                                                'mission.mat');
    if(ischar(FileName) && ischar(PathName))
        saveMission(handles, [PathName,FileName]);
    end

% --------------------------------------------------------------------
function exitMenu_Callback(hObject, eventdata, handles)
% hObject    handle to exitMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.ma_LvdMainGUI);


% --------------------------------------------------------------------
function newMissionPlanToolbar_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to newMissionPlanToolbar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    set(hObject,'Enable','off');
    drawnow;
    newMissionPlanMenu_Callback(handles.newMissionPlanMenu, [], handles);
    
    set(handles.newMissionPlanToolbar,'Enable','on');
    set(handles.openMissionPlanToolbar,'Enable','on');
    set(handles.saveMissionPlanToolbar,'Enable','on');

% --------------------------------------------------------------------
function openMissionPlanToolbar_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to openMissionPlanToolbar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    set(hObject,'Enable','off');
    drawnow;
    openMissionPlanMenu_Callback(handles.openMissionPlanMenu, [], handles);
    
    set(handles.newMissionPlanToolbar,'Enable','on');
    set(handles.openMissionPlanToolbar,'Enable','on');
    set(handles.saveMissionPlanToolbar,'Enable','on');

% --------------------------------------------------------------------
function saveMissionPlanToolbar_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to saveMissionPlanToolbar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    set(hObject,'Enable','off');
    drawnow;
    saveMissionPlanMenu_Callback(handles.saveMissionPlanMenu, [], handles);
    
    set(handles.newMissionPlanToolbar,'Enable','on');
    set(handles.openMissionPlanToolbar,'Enable','on');
    set(handles.saveMissionPlanToolbar,'Enable','on');


% --------------------------------------------------------------------
function editMenu_Callback(hObject, eventdata, handles)
% hObject    handle to editMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    undoRedo = getappdata(handles.ma_LvdMainGUI,'undoRedo');
    [undoTf, undoActionName] = undoRedo.shouldUndoMenuBeEnabled();
    [redoTf, redoActionName] = undoRedo.shouldRedoMenuBeEnabled();
    
    if(undoTf)
        set(handles.undoMenu,'Enable','on');
    else
        set(handles.undoMenu,'Enable','off');
    end
    set(handles.undoMenu,'Label',['Undo ',undoActionName]);
    
    if(redoTf)
        set(handles.redoMenu,'Enable','on');
    else
        set(handles.redoMenu,'Enable','off');
    end
    set(handles.redoMenu,'Label',['Redo ',redoActionName]);

% --------------------------------------------------------------------
function undoMenu_Callback(hObject, eventdata, handles)
% hObject    handle to undoMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    undoRedo = getappdata(handles.ma_LvdMainGUI,'undoRedo');
    lvdData = undoRedo.undo(lvdData);
    
    setappdata(handles.ma_LvdMainGUI,'lvdData',lvdData);
    
    runScript(handles, lvdData);
    lvd_processData(handles);
    
    curName = get(handles.ma_LvdMainGUI,'Name');
    if(~strcmpi(curName(end),'*'))
        set(handles.ma_MainGUI,'Name',[curName,'*']);
    end
    
    editMenu_Callback([], [], handles);
    
% --------------------------------------------------------------------
function redoMenu_Callback(hObject, eventdata, handles)
% hObject    handle to redoMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    undoRedo = getappdata(handles.ma_LvdMainGUI,'undoRedo');
    lvdData = undoRedo.redo();
    
    if(not(isempty(lvdData)))
        setappdata(handles.ma_LvdMainGUI,'lvdData',lvdData);

        runScript(handles, lvdData);
        lvd_processData(handles);
    end
    
    curName = get(handles.ma_LvdMainGUI,'Name');
    if(~strcmpi(curName(end),'*'))
        set(handles.ma_MainGUI,'Name',[curName,'*']);
    end
    
    editMenu_Callback([], [], handles);


% --- Executes when user attempts to close ma_LvdMainGUI.
function ma_LvdMainGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to ma_LvdMainGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
    if(strcmpi(handles.scriptWorkingLbl.Visible,'on') || ...
       strcmpi(handles.plotWorkingLbl.Visible,'on'))
        askToQuit = true;
    else
        askToQuit = false;
    end
    
    yesStr = 'Yes';
    if(askToQuit)
        response = questdlg(['KSPTOT is still processing.  Any in-work data will be lost upon closing.  Continue?'],'Close Launch Vehicle Designer?',yesStr,'No','No');
    else
        response = yesStr;
    end
    
    if(~strcmpi(response,yesStr))
        return;
    else
        if(isMissionPlanSaved(handles))
            askToClear = false;
        else
            askToClear = true;
        end

        if(askToClear)
            response = questdlg(['All unsaved work will be lost.  Continue?'],'Close Launch Vehicle Designer?',yesStr,'No','No');
        else
            response = yesStr;
        end

        if(~strcmpi(response,yesStr))
            return;
        end

        delete(hObject);
    end


% --------------------------------------------------------------------
function settingsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to settingsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function integrationSettingsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to integrationSettingsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function optimSettingsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to optimSettingsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');

    parallelOptim = lvdData.settings.optUsePara;
    if(parallelOptim==true)
        set(handles.optUseParaMenu, 'Checked', 'on');
    else
        set(handles.optUseParaMenu, 'Checked', 'off');
    end

% --------------------------------------------------------------------
function optAlgorithmMenu_Callback(hObject, eventdata, handles)
% hObject    handle to optAlgorithmMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');

    optAlgo = lvdData.settings.optAlgo;
    switch optAlgo
        case LvdOptimAlgorithmEnum.InteriorPoint
            set(handles.optInteriorPointAlgoMenu, 'Checked', 'on');
            set(handles.optSqpAlgoMenu, 'Checked', 'off');
            set(handles.optActiveSetAlgoMenu, 'Checked', 'off');
        case LvdOptimAlgorithmEnum.SQP
            set(handles.optInteriorPointAlgoMenu, 'Checked', 'off');
            set(handles.optSqpAlgoMenu, 'Checked', 'on');
            set(handles.optActiveSetAlgoMenu, 'Checked', 'off');
        case LvdOptimAlgorithmEnum.ActiveSet
            set(handles.optInteriorPointAlgoMenu, 'Checked', 'off');
            set(handles.optSqpAlgoMenu, 'Checked', 'off');
            set(handles.optActiveSetAlgoMenu, 'Checked', 'on');
        otherwise
            error('Unknown optimization algorithm when setting menu checkmark.');
    end

% --------------------------------------------------------------------
function optUseParaMenu_Callback(hObject, eventdata, handles)
% hObject    handle to optUseParaMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    writeOutput = getappdata(handles.ma_LvdMainGUI,'write_to_output_func');
    
    if strcmp(get(gcbo, 'Checked'),'on')
        set(gcbo, 'Checked', 'off');
        lvdData.settings.optUsePara = false;
        writeOutput('Parallel optimization mode disabled.','append');
    else
        set(gcbo, 'Checked', 'on');
        lvdData.settings.optUsePara = true;
        
        drawnow;
        p = gcp('nocreate');
        if(isempty(p))
            try
                h = msgbox('Attempting to start parallel computing workers.  Please wait...');
                pp=parpool('local',feature('numCores'));
                pp.IdleTimeout = 99999; %we don't want the pool to shutdown
                if(isvalid(h))
                    close(h);
                end
                writeOutput('Parallel optimization mode enabled.','append');
            catch ME %#ok<NASGU>
                if(ishandle(h))
                    close(h);
                end
                msgbox('Parallel mode start failed.  Optimization will run in serial.');
            end
        else
            writeOutput('Parallel optimization mode enabled.','append');
        end
    end

% --------------------------------------------------------------------
function integrationAbsTolMenu_Callback(hObject, eventdata, handles)
% hObject    handle to integrationAbsTolMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    writeOutput = getappdata(handles.ma_LvdMainGUI,'write_to_output_func');
    
    input_str = sprintf(['Enter the desired integration absolute error tolerance:\n',...
                         '(Minimum = 1E-14, Maximum = 1E-2)\n',...
                         '(This will influence script execution speed.)']);
    str = inputdlg(input_str, 'Absolute Error Tolerance', [1 75], {num2str(lvdData.settings.intAbsTol,'%6.6E')});
    if(isempty(str))
        return;
    end
    
    str = str{1};
    
    if(checkStrIsNumeric(str) && str2double(str) >= 1E-14 && str2double(str) <= 1E-2)
        writeOutput(sprintf('Setting integration absolute error tolerance to %s.', str),'append');
        
        lvdData.settings.intAbsTol = str2double(str);       
        
        runScript(handles, lvdData);
        lvd_processData(handles);
    else
        writeOutput(sprintf('Could not set the desired integration absolute error tolerance.  "%s" is an invalid entry.', str),'append');
        beep;
    end

% --------------------------------------------------------------------
function integrationRelTolMenu_Callback(hObject, eventdata, handles)
% hObject    handle to integrationRelTolMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    writeOutput = getappdata(handles.ma_LvdMainGUI,'write_to_output_func');
    
    input_str = sprintf(['Enter the desired integration relative error tolerance:\n',...
                         '(Minimum = 1E-14, Maximum = 1E-2)\n',...
                         '(This will influence script execution speed.)']);
    str = inputdlg(input_str, 'Relative Error Tolerance', [1 75], {num2str(lvdData.settings.intRelTol,'%6.6E')});
    if(isempty(str))
        return;
    end
    
    str = str{1};
    
    if(checkStrIsNumeric(str) && str2double(str) >= 1E-14 && str2double(str) <= 1E-2)
        writeOutput(sprintf('Setting integration relative error tolerance to %s.', str),'append');
        
        lvdData.settings.intRelTol = str2double(str);       
        
        runScript(handles, lvdData);
        lvd_processData(handles);
    else
        writeOutput(sprintf('Could not set the desired integration relative error tolerance.  "%s" is an invalid entry.', str),'append');
        beep;
    end

% --------------------------------------------------------------------
function intMinAltitudeMenu_Callback(hObject, eventdata, handles)
% hObject    handle to intMinAltitudeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    writeOutput = getappdata(handles.ma_LvdMainGUI,'write_to_output_func');
    
    input_str = sprintf(['Enter the desired minimum integration altitude (km):\n',...
                         '(Minimum = -Inf km, Maximum = 0 km)\n', ...
                         '(Script execution stops if the vehicle reaches this altitude.)']);
    str = inputdlg(input_str, 'Minimum Integration Altitude', [1 75], {fullAccNum2Str(lvdData.settings.minAltitude)});
    if(isempty(str))
        return;
    end
    
    str = str{1};
    
    if(checkStrIsNumeric(str) && str2double(str) >= -Inf && str2double(str) <= 0.0)
        writeOutput(sprintf('Setting minimum integration altitude to %s km.', str),'append');
        
        lvdData.settings.minAltitude = str2double(str);       
        
        runScript(handles, lvdData);
        lvd_processData(handles);
    else
        writeOutput(sprintf('Could not set the desired minimum integration altitude.  "%s" is an invalid entry.', str),'append');
        beep;
    end

% --------------------------------------------------------------------
function intMaxSimTimeMenu_Callback(hObject, eventdata, handles)
% hObject    handle to intMaxSimTimeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    writeOutput = getappdata(handles.ma_LvdMainGUI,'write_to_output_func');
    
    input_str = sprintf(['Enter the desired maximum simulation time (sec):\n',...
                         '(Minimum = 0.0 sec, Maximum = Inf sec)\n', ...
                         '(Script execution stops if the duration of the mission exceeds this value.)']);
    str = inputdlg(input_str, 'Maximum Simulation Time', [1 75], {fullAccNum2Str(lvdData.settings.simMaxDur)});
    if(isempty(str))
        return;
    end
    
    str = str{1};
    
    if(checkStrIsNumeric(str) && str2double(str) >= 0 && str2double(str) <= Inf)
        writeOutput(sprintf('Setting maximum simulation time to %s sec.', str),'append');
        
        lvdData.settings.simMaxDur = str2double(str);       
        
        runScript(handles, lvdData);
        lvd_processData(handles);
    else
        writeOutput(sprintf('Could not set the desired maximum simulation time.  "%s" is an invalid entry.', str),'append');
        beep;
    end

% --------------------------------------------------------------------
function optInteriorPointAlgoMenu_Callback(hObject, eventdata, handles)
% hObject    handle to optInteriorPointAlgoMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    writeOutput = getappdata(handles.ma_LvdMainGUI,'write_to_output_func');
    
    lvdData.settings.optAlgo = LvdOptimAlgorithmEnum.InteriorPoint;
    writeOutput('Optimization algorithm changed to interior point.','append');

% --------------------------------------------------------------------
function optSqpAlgoMenu_Callback(hObject, eventdata, handles)
% hObject    handle to optSqpAlgoMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    writeOutput = getappdata(handles.ma_LvdMainGUI,'write_to_output_func');
    
    lvdData.settings.optAlgo = LvdOptimAlgorithmEnum.SQP;
    writeOutput('Optimization algorithm changed to SQP.','append');

% --------------------------------------------------------------------
function optActiveSetAlgoMenu_Callback(hObject, eventdata, handles)
% hObject    handle to optActiveSetAlgoMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    writeOutput = getappdata(handles.ma_LvdMainGUI,'write_to_output_func');
    
    lvdData.settings.optAlgo = LvdOptimAlgorithmEnum.ActiveSet;
    writeOutput('Optimization algorithm changed to active set.','append');