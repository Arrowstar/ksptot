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

% Last Modified by GUIDE v2.5 17-Feb-2021 13:44:22

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
    try
        handles.output = hObject;
        hObject.Visible = 'off';

        hManager = uigetmodemanager(hObject);
        [hManager.WindowListenerHandles.Enabled] = deal(false); 

        celBodyData = varargin{1};
        celBodyData = CelestialBodyData(celBodyData);
        setappdata(hObject,'celBodyData',celBodyData);

        hKsptotMainGUI = varargin{2};
        setappdata(hObject,'ksptotMainGUI',hKsptotMainGUI);

        setappdata(hObject,'current_save_location','');
        setappdata(hObject,'application_title','KSP TOT Launch Vehicle Designer');
        setappdata(hObject,'undoRedo',LVD_UndoRedoStateSet());

        lvdData = LvdData.getDefaultLvdData(celBodyData);
        setappdata(handles.ma_LvdMainGUI,'lvdData',lvdData);
        
        output_text_max_line_length = length(getLVD_HR(handles.outputText));
        setappdata(hObject,'output_text_max_line_length',output_text_max_line_length);
        writeOutput = @(str,type) writeToMAOutput(handles.outputText, str, type, output_text_max_line_length);
        setappdata(hObject,'write_to_output_func',writeOutput);

        jDispAxesTimeSlider = javaObjectEDT('javax.swing.JSlider');
        jDispAxesTimeSlider.setSnapToTicks(false);
        jDispAxesTimeSlider.setMinimum(0);
        jDispAxesTimeSlider.setMaximum(1);
        jDispAxesTimeSlider.setValue(0);
        sliderPnlPos = handles.timeSliderPanel.Position;
        [~,hDispAxesTimeSliderJavaWrapper] = javacomponent(jDispAxesTimeSlider,[1, 1, sliderPnlPos(3), sliderPnlPos(4)], handles.timeSliderPanel);
        handles.jDispAxesTimeSlider = jDispAxesTimeSlider;
        jDispAxesTimeSlider.setToolTipText('Adjust slider to view the location of vehicles and selected celestial bodies at a given time.');

        hDispAxesTimeSlider = handle(jDispAxesTimeSlider, 'CallbackProperties');
        handles.hDispAxesTimeSlider = hDispAxesTimeSlider;
        handles.hDispAxesTimeSliderJavaWrapper = hDispAxesTimeSliderJavaWrapper;
        timeSliderCb = @(src,evt) timeSliderStateChanged(src,evt, lvdData, handles);
        set(hDispAxesTimeSlider, 'StateChangedCallback', timeSliderCb); 

        setappdata(handles.hDispAxesTimeSlider,'lastTime',NaN);
        
        initializeOutputWindowText(handles, handles.outputText);
        view(handles.dispAxes,3);

        hRot3D = rotate3d(handles.ma_LvdMainGUI);
        hRot3D.ActionPostCallback = @(src,evt) recordFinalAxesViewAfterRotation(src,evt, handles); 

        hZoom = zoom(handles.ma_LvdMainGUI);
        hZoom.ActionPostCallback = @(src,evt) recordFinalAxesPanZoomAfterRotation(src,evt, handles);

        hPan = pan(handles.ma_LvdMainGUI);
        hPan.ActionPostCallback = @(src,evt) recordFinalAxesPanZoomAfterRotation(src,evt, handles);

        addlistener(handles.dispAxes,'CameraPosition','PostSet', @(src,evt) recordFinalAxesPanZoomAfterRotation(src,evt, handles));
        addlistener(handles.dispAxes,'CameraTarget','PostSet', @(src,evt) recordFinalAxesPanZoomAfterRotation(src,evt, handles));
        addlistener(handles.dispAxes,'CameraUpVector','PostSet', @(src,evt) recordFinalAxesPanZoomAfterRotation(src,evt, handles));
        addlistener(handles.dispAxes,'CameraViewAngle','PostSet', @(src,evt) recordFinalAxesPanZoomAfterRotation(src,evt, handles));
        
        setDeleteButtonEnable(lvdData, handles);
        setNonSeqDeleteButtonEnable(lvdData, handles);

        gravSystemUpdateCbFh = @(src,evt) gravSystemUpdateCallback(src,evt, handles);
        appOptions = getappdata(hKsptotMainGUI,'appOptions');
        addlistener(appOptions.ksptot,'GravParamTypeUpdated',gravSystemUpdateCbFh);

        rotate3d(handles.dispAxes,'on');

        enableDisableArrowButtons(lvdData, handles);
        
        setResizeData(hObject, handles);
                
        runScript(handles, lvdData, 1);
        lvd_processData(handles);

        % Update handles structure
        guidata(hObject, handles);
        hObject.Visible = 'on';
        drawnow;           

        % UIWAIT makes ma_LvdMainGUI wait for user response (see UIRESUME)
        % uiwait(handles.ma_LvdMainGUI);
    catch ME
        beep;
        errordlg('An error occured while opening Launch Vehicle Designer.  Please see the ksptot.log for more details.','Error');
        disp(ME.message);
        close(handles.ma_LvdMainGUI);
    end
    
function setResizeData(hObject, handles)
    pos = hObject.Position;
    origWidth = pos(3);
    origHgt = pos(4);
    setappdata(hObject,'OriginalWidth',origWidth);
    setappdata(hObject,'OriginalHeight',origHgt);
    
    %title label
    titlePos = handles.titleText.Position;
    titleOffsetFromTop = origHgt - (titlePos(2) + titlePos(4));
    setappdata(hObject,'titleOffsetFromTop',titleOffsetFromTop);
    
    %initial state panel
    initScStatePanelPos = handles.initScStatePanel.Position;
    initScStatePanelOffsetFromTop = origHgt - (initScStatePanelPos(2) + initScStatePanelPos(4));
    setappdata(hObject,'initScStatePanelOffsetFromTop',initScStatePanelOffsetFromTop);
    
    %final state panel
    finalScStatePanelPos = handles.finalScStatePanel.Position;
    finalScStatePanelOffsetFromTop = origHgt - (finalScStatePanelPos(2) + finalScStatePanelPos(4));
    setappdata(hObject,'finalScStatePanelOffsetFromTop',finalScStatePanelOffsetFromTop);
    
    %display axes label
    dispAxisTitleLabelPos = handles.dispAxisTitleLabel.Position;
    dispAxisTitleLabelOffsetFromTop = origHgt - (dispAxisTitleLabelPos(2) + dispAxisTitleLabelPos(4));
    setappdata(hObject,'dispAxisTitleLabelOffsetFromTop',dispAxisTitleLabelOffsetFromTop);
    
    %display axes
%     dispAxesPos = handles.dispAxes.Position;
%     dispAxesOffsetFromTop = origHgt - (dispAxesPos(2) + dispAxesPos(4));
%     setappdata(hObject,'dispAxesOffsetFromTop',dispAxesOffsetFromTop);
    
    %display axes panel
    dispAxesPanelPos = handles.dispAxesPanel.Position;
    dispAxesPanelOffsetFromTop = origHgt - (dispAxesPanelPos(2) + dispAxesPanelPos(4));
    setappdata(hObject,'dispAxesPanelOffsetFromTop',dispAxesPanelOffsetFromTop);    
    
    %insert seq event button
    insertEventButtonPos = handles.insertEventButton.Position;
    insertEventButtonOffsetFromTop = origHgt - (insertEventButtonPos(2) + insertEventButtonPos(4));
    setappdata(hObject,'insertEventButtonOffsetFromTop',insertEventButtonOffsetFromTop);
    
    %script listbox
    scriptListboxPos = handles.scriptListbox.Position;
    scriptListboxOffsetFromTop = origHgt - (scriptListboxPos(2) + scriptListboxPos(4));
    setappdata(hObject,'scriptListboxOffsetFromTop',scriptListboxOffsetFromTop);
  
    %incrOrbitToPlotNum Button
    incrOrbitToPlotNumPos = handles.incrOrbitToPlotNum.Position;
    incrOrbitToPlotNumOffsetFromRight = origWidth - (incrOrbitToPlotNumPos(1) + incrOrbitToPlotNumPos(3));
    setappdata(hObject,'incrOrbitToPlotNumOffsetFromRight',incrOrbitToPlotNumOffsetFromRight);
    
    %timeSliderValueLabel
    timeSliderValueLabelPos = handles.timeSliderValueLabel.Position;
    timeSliderValueLabelOffsetFromRight = origWidth - (timeSliderValueLabelPos(1) + timeSliderValueLabelPos(3));
    setappdata(hObject,'timeSliderValueLabelOffsetFromRight',timeSliderValueLabelOffsetFromRight);
    
    %timeSliderPanel
    timeSliderPanelPos = handles.timeSliderPanel.Position;
    timeSliderPanelOffsetFromRight = origWidth - (timeSliderPanelPos(1) + timeSliderPanelPos(3));
    setappdata(hObject,'timeSliderPanelOffsetFromRight',timeSliderPanelOffsetFromRight);
    
    %warningAlertPanel
    warningAlertPanelPos = handles.warningAlertPanel.Position;
    warningAlertPanelOffsetFromRight = origWidth - (warningAlertPanelPos(1) + warningAlertPanelPos(3));
    setappdata(hObject,'warningAlertPanelOffsetFromRight',warningAlertPanelOffsetFromRight);
    
    %warnAlertsSlider
    warnAlertsSliderPos = handles.warnAlertsSlider.Position;
    warnAlertsSliderOffsetFromRight = warningAlertPanelPos(3) - (warnAlertsSliderPos(1) + warnAlertsSliderPos(3));
    setappdata(handles.warningAlertPanel,'warnAlertsSliderOffsetFromRight',warnAlertsSliderOffsetFromRight);
    
    %warning1Lbl (and others
    warningLblPos = handles.warning1Lbl.Position;
    warningLblOffsetFromRight = warningAlertPanelPos(3) - (warningLblPos(1) + warningLblPos(3));
    setappdata(handles.warningAlertPanel,'warningLblOffsetFromRight',warningLblOffsetFromRight);

function initializeOutputWindowText(handles, hOutputText) 
    write_to_output_func = getappdata(handles.ma_LvdMainGUI,'write_to_output_func');

    set(hOutputText,'String',' ');
    statusBoxMsg = {['KSP TOT Launch Vehicle Designer v', getKSPTOTVersionNumStr(), sprintf(' (R%s)', version('-release'))], 'Written By Arrowstar (C) 2021', ...
                    getLVD_HR(hOutputText)};
	for(i=1:size(statusBoxMsg,2)) %#ok<ALIGN,*NO4LP>
        if(i==1)
            write_to_output_func(statusBoxMsg{i},'overwrite');
        else
            write_to_output_func(statusBoxMsg{i},'appendNoDate');
        end
    end
   
function runScript(handles, lvdData, evtStartNum)
    if(lvdData.settings.autoPropScript)
        propagateScript(handles, lvdData, evtStartNum);
    else
        handles.scriptResultsOutOfDateLbl.Visible = 'on';
    end
    setappdata(handles.hDispAxesTimeSlider,'lastTime',NaN);
    
function propagateScript(handles, lvdData, evtStartNum)
    writeOutput = getappdata(handles.ma_LvdMainGUI,'write_to_output_func');
    
    handles.scriptResultsOutOfDateLbl.Visible = 'off';
    handles.scriptWorkingLbl.Visible = 'on';
    drawnow;
    
    if(not(isdeployed))
%         profile off; profile('on','-detail','builtin', '-remove_overhead','on');
    end
    
    lvdData.validation.clearOutputs();
    
    isSparseOutput = lvdData.settings.isSparseOutput;
    dispEvtPropTimes = lvdData.settings.disEvtPropTimes;
    
    evt = lvdData.script.getEventForInd(evtStartNum);
    
    t = tic;
    lvdData.script.executeScript(isSparseOutput, evt, true, false, dispEvtPropTimes);
    execTime = toc(t);
    
    if(not(isdeployed))
%         profile viewer;
    end
    
    handles.scriptWorkingLbl.Visible = 'off';
    handles.warnAlertsSlider.Value = 0;    
    
    lvdData.validation.validate();
    updateWarnErrorLabels(handles, true);
    
    setappdata(handles.hDispAxesTimeSlider,'lastTime',NaN);
    
    writeOutput(sprintf('Executed mission script in %.3f seconds.',execTime),'append');
    drawnow;
    
function celBodyData = getCelBodyDataFromMainGui(handles)
    hKsptotMainGUI = getappdata(handles.ma_LvdMainGUI,'ksptotMainGUI');
    
    mainGUIUserData = get(hKsptotMainGUI, 'UserData');
    celBodyData = mainGUIUserData{1,1};
   
    
function recordFinalAxesViewAfterRotation(obj,event_obj, handles)  
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    lvdData.viewSettings.selViewProfile.viewZoomAxLims = [handles.dispAxes.XLim;
                                                          handles.dispAxes.YLim;
                                                          handles.dispAxes.ZLim];
    
    [az,el] = view(handles.dispAxes);
    lvdData.viewSettings.selViewProfile.viewAzEl = [az,el];
    
function recordFinalAxesPanZoomAfterRotation(obj,event_obj, handles)  
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    lvdData.viewSettings.selViewProfile.viewZoomAxLims = [handles.dispAxes.XLim;
                                                          handles.dispAxes.YLim;
                                                          handles.dispAxes.ZLim];
                                                      
    [az,el] = view(handles.dispAxes);
    lvdData.viewSettings.selViewProfile.viewAzEl = [az,el];
    
    lvdData.viewSettings.selViewProfile.viewCameraPosition = handles.dispAxes.CameraPosition;
	lvdData.viewSettings.selViewProfile.viewCameraTarget = handles.dispAxes.CameraTarget;
	lvdData.viewSettings.selViewProfile.viewCameraUpVector = handles.dispAxes.CameraUpVector;
	lvdData.viewSettings.selViewProfile.viewCameraViewAngle = handles.dispAxes.CameraViewAngle;
    
    
function gravSystemUpdateCallback(src,evt, handles)
    if(isvalid(handles.ma_LvdMainGUI))
        lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
        lvdData.celBodyData.resetAllParentNeedsUpdateFlags();
    end
    
function timeSliderKeyPressCallback(src,evt, handles)
    if(javaMethodEDT('getKeyCode',evt) == java.awt.event.KeyEvent.VK_RIGHT || ...
       javaMethodEDT('getKeyCode',evt) == java.awt.event.KeyEvent.VK_LEFT || ...
       javaMethodEDT('getKeyCode',evt) == java.awt.event.KeyEvent.VK_KP_RIGHT || ... 
       javaMethodEDT('getKeyCode',evt) == java.awt.event.KeyEvent.VK_KP_LEFT)
   
        src.StateChangedCallback(src,[]);
    end

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
    
    undoRedo.addState(handles.ma_LvdMainGUI, lvdData, actionName);
 

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
        lvd_editEventGUI(event, false);   

        runScript(handles, lvdData, 1);
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
    lvd_editEventGUI(event, false);
    
	setDeleteButtonEnable(lvdData, handles);

    runScript(handles, lvdData, 1);
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
    
    runScript(handles, lvdData, 1);
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
    
    tfEvt = evt.usesEvent(evt);
    tfObj = lvdData.optimizer.objFcn.usesEvent(evt);
    if(tfEvt || tfObj)
        warndlg(sprintf('Could not delete the event "%s" because it is in use as part of an event action or objective function.  Remove the event dependencies before attempting to delete the event.', evt.getListboxStr()),'Cannot Delete Event','modal');
    else
        lvdData.optimizer.vars.removeVariablesThatUseEvent(evt, lvdData);
        lvdData.optimizer.constraints.removeConstraintsThatUseEvent(evt);

        lvdData.script.removeEventFromIndex(eventNum);

        if(eventNum > length(lvdData.script.evts))
            set(handles.scriptListbox,'Value',length(lvdData.script.evts));
        end

        setDeleteButtonEnable(lvdData, handles);

        runScript(handles, lvdData, 1);
        lvd_processData(handles);
    end
   
    
function setDeleteButtonEnable(lvdData, handles)
    numEvents = lvdData.script.getTotalNumOfEvents();
    if(numEvents <= 1)
        handles.deleteEvent.Enable = 'off';
    else
        handles.deleteEvent.Enable = 'on';
    end
    
    
function setNonSeqDeleteButtonEnable(lvdData, handles)
    numEvents = lvdData.script.nonSeqEvts.getTotalNumOfEvents();
    if(numEvents <= 0)
        handles.deleteNonSeqEventButton.Enable = 'off';
    else
        handles.deleteNonSeqEventButton.Enable = 'on';
    end

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
    
    runScript(handles, lvdData, 1);
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
%     orbitNumToPlot = get(handles.dispAxes,'UserData');
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    orbitNumToPlot = lvdData.viewSettings.selViewProfile.orbitNumToPlot;
    
    if(orbitNumToPlot > 1)
        orbitNumToPlot = orbitNumToPlot - 1;

    elseif(orbitNumToPlot == 1)
        maStateLog = lvdData.stateLog.getMAFormattedStateLogMatrix(false);
        chunkedStateLog = breakStateLogIntoSoIChunks(maStateLog);
        orbitNumToPlot = size(chunkedStateLog,1);
    end
    
    lvdData.viewSettings.selViewProfile.orbitNumToPlot = orbitNumToPlot;
    set(handles.dispAxes,'UserData',orbitNumToPlot);
    lvd_processData(handles);
    
    

% --- Executes on button press in incrOrbitToPlotNum.
function incrOrbitToPlotNum_Callback(hObject, eventdata, handles)
% hObject    handle to incrOrbitToPlotNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%     orbitNumToPlot = get(handles.dispAxes,'UserData');
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    maStateLog = lvdData.stateLog.getMAFormattedStateLogMatrix(false);
    chunkedStateLog = breakStateLogIntoSoIChunks(maStateLog);
    orbitNumToPlot = lvdData.viewSettings.selViewProfile.orbitNumToPlot;
    
    if(orbitNumToPlot < size(chunkedStateLog,1))
        orbitNumToPlot = orbitNumToPlot + 1;

    elseif(orbitNumToPlot == size(chunkedStateLog,1))
        orbitNumToPlot = 1;
        
    end
    
    lvdData.viewSettings.selViewProfile.orbitNumToPlot = orbitNumToPlot;
	set(handles.dispAxes,'UserData',orbitNumToPlot);
    lvd_processData(handles);

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
    
    lvdData.optimizer.optimize(writeOutput, true);
    
    runScript(handles, lvdData, 1);
    lvd_processData(handles);

% --------------------------------------------------------------------
function scenarioMenu_Callback(hObject, eventdata, handles)
% hObject    handle to scenarioMenu (see GCBO)
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
    
    runScript(handles, lvdData, 1);
    lvd_processData(handles);


% --------------------------------------------------------------------
function editObjFunctionMenu_Callback(hObject, eventdata, handles)
% hObject    handle to editObjFunctionMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
    addUndoState(handles,'Edit Objective Function');
    
%     lvd_EditObjectiveFunctionGUI(lvdData);
    lvd_EditCompositeObjectiveFunctionGUI(lvdData);

% --------------------------------------------------------------------
function editConstraintsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to editConstraintsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
    addUndoState(handles,'Edit Constraints');
    
    lvd_EditConstraintsGUI(lvdData);
    
    runScript(handles, lvdData, 1);
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
    
    runScript(handles, lvdData, 1);
    lvd_processData(handles);

% --------------------------------------------------------------------
function viewStateAfterSelectedEventMenu_Callback(hObject, eventdata, handles)
% hObject    handle to viewStateAfterSelectedEventMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
    eventNum = handles.scriptListbox.Value;
    stateLog = lvdData.stateLog.getMAFormattedStateLogMatrix(true);
    
    state = stateLog(stateLog(:,13)==eventNum,:);
    state = state(end,:);

%     propNames = {'Liquid Fuel/Ox','Monopropellant','Xenon'};
    propNames = lvdData.launchVehicle.tankTypes.getFirstThreeTypesCellArr();
    viewSpacecraftStatePopupGUI(propNames, state, eventNum, lvdData.celBodyData);

% --------------------------------------------------------------------
function copyUtAtStartOfSelEventMenu_Callback(hObject, eventdata, handles)
% hObject    handle to copyUtAtStartOfSelEventMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
    eventNum = handles.scriptListbox.Value;
    stateLog = lvdData.stateLog.getMAFormattedStateLogMatrix(false);
    
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
    stateLog = lvdData.stateLog.getMAFormattedStateLogMatrix(false);
    
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
    stateLog = lvdData.stateLog.getMAFormattedStateLogMatrix(false);
    
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
    stateLog = lvdData.stateLog.getMAFormattedStateLogMatrix(false);    
    
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

    celBodyData = getCelBodyDataFromMainGui(handles);
    setappdata(handles.ma_LvdMainGUI,'celBodyData', celBodyData);
    
%     celBodyData = getappdata(handles.ma_LvdMainGUI,'celBodyData');
    write_to_output_func = getappdata(handles.ma_LvdMainGUI,'write_to_output_func');
    application_title = getappdata(handles.ma_LvdMainGUI,'application_title');
    if(askToClear)
        write_to_output_func('Creating new mission plan... ','append');
    end
    
    lvdData = LvdData.getDefaultLvdData(celBodyData);
    setappdata(handles.ma_LvdMainGUI,'lvdData',lvdData);
    setappdata(handles.ma_LvdMainGUI,'current_save_location','');
    
    setDeleteButtonEnable(lvdData, handles);
    setNonSeqDeleteButtonEnable(lvdData, handles);

    setappdata(handles.hDispAxesTimeSlider,'lastTime',NaN);
    timeSliderCb = @(src,evt) timeSliderStateChanged(src,evt, lvdData, handles);
    set(handles.hDispAxesTimeSlider, 'StateChangedCallback', timeSliderCb);
    
    enableDisableArrowButtons(lvdData, handles);
    
    runScript(handles, lvdData, 1);
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
    current_save_location = getappdata(handles.ma_LvdMainGUI,'current_save_location');
    
    if(isempty(current_save_location))
        fileNameToDefaultTo = 'mission.mat';
    else
        [current_save_location_path,~,~] = fileparts(current_save_location);
        fileNameToDefaultTo = [current_save_location_path,filesep,'mission.mat'];
    end
    
    [FileName,PathName] = uigetfile({'*.mat','KSP TOT Launch Vehicle Designer Case File (*.mat)'},...
                                                'Open Launch Vehicle Designer Case',...
                                                fileNameToDefaultTo);
	filePath = [PathName,FileName];
    
    if(ischar(filePath))
        write_to_output_func(['Loading mission case from "', filePath,'"... '],'append');
        
        hMsg = helpdlg('Loading LVD Case File.  Please wait...','Launch Vehicle Designer');
        
        try
            load(filePath); %#ok<LOAD>
        catch ME
            write_to_output_func(['There was a problem loading the case file from disk: ',filePath,'.  Case not loaded.'],'append'); 
            
            if(isvalid(hMsg))
                close(hMsg);
            end
            
            return;
        end
        
        if(isvalid(hMsg))
            close(hMsg);
        end
        
        if(exist('lvdData','var'))
            setappdata(handles.ma_LvdMainGUI,'undoRedo',LVD_UndoRedoStateSet());
           
            topLevelBodyInfo = getTopLevelCentralBody(celBodyData);
            ldvDataTopLevelBodyInfo = getTopLevelCentralBody(lvdData.celBodyData);
            if(isprop(lvdData,'celBodyData') && ...
               length(fields(topLevelBodyInfo)) == length(fields(ldvDataTopLevelBodyInfo)))
                celBodyData = lvdData.celBodyData;
                setappdata(handles.ma_LvdMainGUI,'celBodyData',celBodyData);
            else
                lvdData.celBodyData = celBodyData;
            end
            
            if(isprop(lvdData,'celBodyData'))
                lvdData.celBodyData = CelestialBodyData(lvdData.celBodyData);
                
                names = fieldnames(lvdData.celBodyData);
                for(i=1:length(names))
                    name = names{i};
                    lvdData.celBodyData.(name).celBodyData = celBodyData;
                    lvdData.celBodyData.(name).getParBodyInfo(lvdData.celBodyData);
                end
            end
            
            set(handles.ma_LvdMainGUI,'Name',[application_title, ' - ', FileName]);
            write_to_output_func(['Done.'],'appendSameLine');
            
            setappdata(handles.ma_LvdMainGUI,'lvdData',lvdData);
            setappdata(handles.ma_LvdMainGUI,'current_save_location',filePath);
            
            setDeleteButtonEnable(lvdData, handles);
            setNonSeqDeleteButtonEnable(lvdData, handles)
            
            setappdata(handles.hDispAxesTimeSlider,'lastTime',NaN);
            timeSliderCb = @(src,evt) timeSliderStateChanged(src,evt, lvdData, handles);
            set(handles.hDispAxesTimeSlider, 'StateChangedCallback', timeSliderCb);
            
            enableDisableArrowButtons(lvdData, handles);
            
            if(lvdData.optimizer.usesParallel())
                numWorkers = lvdData.optimizer.getSelectedOptimizer().getNumParaWorkers();
                startParallelPool(write_to_output_func, numWorkers);
            end
            
            propagateScript(handles, lvdData, 1);
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
        [~,name,ext] = fileparts(filePath);
        FileName = [name,ext];
    else
        current_save_location = getappdata(handles.ma_LvdMainGUI,'current_save_location');

        if(isempty(current_save_location))
            fileNameToDefaultTo = 'mission.mat';
        else
            [current_save_location_path,~,~] = fileparts(current_save_location);
            fileNameToDefaultTo = [current_save_location_path,filesep,'mission.mat'];
        end
        
        [FileName,PathName] = uiputfile({'*.mat','KSP TOT Launch Vehicle Designer Case File (*.mat)'},...
                                                    'Save Launch Vehicle Designer Case',...
                                                    fileNameToDefaultTo);
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
    
    set(handles.ma_LvdMainGUI,'Name',[application_title, ' - ', FileName]);
    setappdata(handles.ma_LvdMainGUI,'current_save_location',filePath);
    
    write_to_output_func(['Done.'],'appendSameLine');
    
function saveMissionAs(handles)
    current_save_location = getappdata(handles.ma_LvdMainGUI,'current_save_location');

    if(isempty(current_save_location))
        fileNameToDefaultTo = 'mission.mat';
    else
        [current_save_location_path,~,~] = fileparts(current_save_location);
        fileNameToDefaultTo = [current_save_location_path,filesep,'mission.mat'];
    end
    
    [FileName,PathName] = uiputfile({'*.mat','KSP TOT Launch Vehicle Designer Case File (*.mat)'},...
                                                'Save Launch Vehicle Designer Case',...
                                                current_save_location);
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
    writeOutput = getappdata(handles.ma_LvdMainGUI,'write_to_output_func');
    
    [~, undoActionName] = undoRedo.shouldUndoMenuBeEnabled();
    
    writeOutput(sprintf('Undoing %s...',undoActionName),'append');
    lvdData = undoRedo.undo(lvdData);
    
    setappdata(handles.ma_LvdMainGUI,'lvdData',lvdData);
    
    runScript(handles, lvdData, 1);
    lvd_processData(handles);
    
    curName = get(handles.ma_LvdMainGUI,'Name');
    if(~strcmpi(curName(end),'*'))
        set(handles.ma_LvdMainGUI,'Name',[curName,'*']);
    end
    
    editMenu_Callback([], [], handles);
    
% --------------------------------------------------------------------
function redoMenu_Callback(hObject, eventdata, handles)
% hObject    handle to redoMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    undoRedo = getappdata(handles.ma_LvdMainGUI,'undoRedo');
    writeOutput = getappdata(handles.ma_LvdMainGUI,'write_to_output_func');
    
    [~, undoActionName] = undoRedo.shouldRedoMenuBeEnabled();
    
    writeOutput(sprintf('Redoing %s...',undoActionName),'append');    
    lvdData = undoRedo.redo();
    
    if(not(isempty(lvdData)))
        setappdata(handles.ma_LvdMainGUI,'lvdData',lvdData);

        runScript(handles, lvdData, 1);
        lvd_processData(handles);
    end
    
    curName = get(handles.ma_LvdMainGUI,'Name');
    if(~strcmpi(curName(end),'*'))
        set(handles.ma_LvdMainGUI,'Name',[curName,'*']);
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
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
	isAutoProp = lvdData.settings.autoPropScript;
    if(isAutoProp)
        set(handles.autopropagateMenu, 'Checked', 'on');
    else
        set(handles.autopropagateMenu, 'Checked', 'off');
    end
    
	disEvtPropTimes = lvdData.settings.disEvtPropTimes;
    if(disEvtPropTimes)
        set(handles.displayEvtPropTimesInLogFileMenu, 'Checked', 'on');
    else
        set(handles.displayEvtPropTimesInLogFileMenu, 'Checked', 'off');
    end

% --------------------------------------------------------------------
function integrationSettingsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to integrationSettingsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
	isSparseOutput = lvdData.settings.isSparseOutput;
    if(isSparseOutput==true)
        set(handles.sparseIntegratorOutputMenu, 'Checked', 'on');
    else
        set(handles.sparseIntegratorOutputMenu, 'Checked', 'off');
    end

% --------------------------------------------------------------------
function optimSettingsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to optimSettingsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


function startParallelPool(writeOutput, numWorkers)
    p = gcp('nocreate');
    if(isempty(p) || p.NumWorkers ~= numWorkers)       
        try
            beep off;
            h = msgbox('Attempting to start parallel computing workers.  Please wait...','modal');
            
            if(not(isempty(p)))
                delete(p);
            end
            
            pp=parpool('local',numWorkers);
            pp.IdleTimeout = 99999; %we don't want the pool to shutdown
            if(isvalid(h))
                close(h);
            end
            writeOutput('Parallel optimization mode enabled.','append');
            beep on;
        catch ME 
            if(ishandle(h))
                close(h);
            end
            msgbox(sprintf('Parallel mode start failed.  Optimization will run in serial.  Message:\n\n%s',ME.message));
            disp(ME.message);
            beep on;
        end
    else
        writeOutput('Parallel optimization mode enabled.','append');
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
        addUndoState(handles,'Edit Integrator Abs Tol');  
        
        writeOutput(sprintf('Setting integration absolute error tolerance to %s.', str),'append');
        
        lvdData.settings.intAbsTol = str2double(str);       
        
        runScript(handles, lvdData, 1);
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
        addUndoState(handles,'Edit Integrator Rel Tol');  
        
        writeOutput(sprintf('Setting integration relative error tolerance to %s.', str),'append');
        
        lvdData.settings.intRelTol = str2double(str);       
        
        runScript(handles, lvdData, 1);
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
        addUndoState(handles,'Edit Minimum Altitude');        

        writeOutput(sprintf('Setting minimum integration altitude to %s km.', str),'append');
        
        lvdData.settings.minAltitude = str2double(str);       
        
        runScript(handles, lvdData, 1);
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
        addUndoState(handles,'Set Max Simulation Time');
        
        writeOutput(sprintf('Setting maximum simulation time to %s sec.', str),'append');
        
        lvdData.settings.simMaxDur = str2double(str);       
        
        runScript(handles, lvdData, 1);
        lvd_processData(handles);
    else
        writeOutput(sprintf('Could not set the desired maximum simulation time.  "%s" is an invalid entry.', str),'append');
        beep;
    end


% --------------------------------------------------------------------
function toolsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to toolsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function graphicalAnalysisMenu_Callback(hObject, eventdata, handles)
% hObject    handle to graphicalAnalysisMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
%     lvd_GraphicalAnalysisGUI(lvdData, handles.ma_LvdMainGUI);
    
    hFig = msgbox('Starting Graphical Analysis, please wait...', 'Graphical Analysis', 'help');
    lvd_GraphicalAnalysisGUI_App(lvdData, handles.ma_LvdMainGUI);
    close(hFig);


% --------------------------------------------------------------------
function perturbOptVarsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to perturbOptVarsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    writeOutput = getappdata(handles.ma_LvdMainGUI,'write_to_output_func');
    
    %questdlg
    input_str = sprintf(['Enter the percentage amount to perturb the current solution by:\n',...
                         '(Minimum = 0%%, Maximum = 100%%)\n',...
                         '(Values greater than 5%%-10%% will likely cause the solution to become hard to recover with the optimizer.)']);
    str = inputdlg(input_str, 'Perturb Optimization Variables', [1 75], {num2str(0.01,'%4.2f')});
    if(isempty(str))
        return;
    end
    
    str = str{1};
    
    if(checkStrIsNumeric(str) && str2double(str) >= 0 && str2double(str) <= 100)
        addUndoState(handles,'Perturb Optim Vars');
        
        writeOutput(sprintf('Perturbing optimization variables by %s%%.', str),'append');
        pPct = str2double(str);

        lvdData.optimizer.vars.perturbVarsAndUpdate(pPct);
        
        runScript(handles, lvdData, 1);
        lvd_processData(handles);        
    else
        writeOutput(sprintf('Could not perturb optimization variables.  "%s" is an invalid entry.', str),'append');
        beep;
    end


% --------------------------------------------------------------------
function celBodyCatalogMenu_Callback(hObject, eventdata, handles)
% hObject    handle to celBodyCatalogMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    ma_CelBodyCatalogGUI(lvdData.celBodyData);


% --------------------------------------------------------------------
function astroCalculatorsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to astroCalculatorsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    ma_AstroCalculatorsGUI(lvdData.celBodyData);


% --------------------------------------------------------------------
function maxScriptPropTimeMenu_Callback(hObject, eventdata, handles)
% hObject    handle to maxScriptPropTimeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    writeOutput = getappdata(handles.ma_LvdMainGUI,'write_to_output_func');
    
    input_str = sprintf(['Enter the desired maximum script propagation time (sec):\n',...
                         '(Minimum = 0.001 sec, Maximum = 3600 sec)\n', ...
                         '(Script execution stops if the amount of time required to propagate the script exceeds this.)']);
    str = inputdlg(input_str, 'Maximum Script Execution Time', [1 75], {fullAccNum2Str(lvdData.settings.maxScriptPropTime)});
    if(isempty(str))
        return;
    end
    
    str = str{1};
    
    if(checkStrIsNumeric(str) && str2double(str) >= 0.001 && str2double(str) <= 3600)
        addUndoState(handles,'Edit Max Script Propagation Time');
        
        writeOutput(sprintf('Setting maximum script execution time to %s sec.', str),'append');
        
        lvdData.settings.maxScriptPropTime = str2double(str);       
        
        runScript(handles, lvdData, 1);
        lvd_processData(handles);
    else
        writeOutput(sprintf('Could not set the desired maximum script execution time.  "%s" is an invalid entry.', str),'append');
        beep;
    end


% --------------------------------------------------------------------
function sparseIntegratorOutputMenu_Callback(hObject, eventdata, handles)
% hObject    handle to sparseIntegratorOutputMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    writeOutput = getappdata(handles.ma_LvdMainGUI,'write_to_output_func');
    
    addUndoState(handles,'Toggle Sparse Output');
    
    if strcmp(get(gcbo, 'Checked'),'on')
        set(gcbo, 'Checked', 'off');
        lvdData.settings.isSparseOutput = false;
        writeOutput('Sparse output mode disabled.  Full integrator output will be provided and plotted.','append');
    else
        set(gcbo, 'Checked', 'on');
        lvdData.settings.isSparseOutput = true;
        writeOutput('Sparse output mode enabled.  Only first and last states from each event will be provided and plotted.','append');
    end
    
    runScript(handles, lvdData, 1);
    lvd_processData(handles);


% --- Executes on key press with focus on ma_LvdMainGUI or any of its controls.
function ma_LvdMainGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to ma_LvdMainGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    key = eventdata.Key;
    mod = eventdata.Modifier;

    if(hObject == handles.scriptListbox && ...
       strcmpi(key,'f') && ...
       length(mod) == 1 && ...
       strcmpi(mod{1},'control'))
        
        toggleOptimForSelEventMenu_Callback(handles.scriptListbox, [], handles);
    end

% --- Executes on selection change in nonSeqEventsListbox.
function nonSeqEventsListbox_Callback(hObject, eventdata, handles)
% hObject    handle to nonSeqEventsListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns nonSeqEventsListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from nonSeqEventsListbox
    if(strcmpi(get(handles.ma_LvdMainGUI,'SelectionType'),'open'))
        addUndoState(handles,'Edit Non-Sequential Event');
        
        eventNum = get(hObject,'Value');
        lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
        
        nonSeqEvt = lvdData.script.nonSeqEvts.getEventForInd(eventNum);
        lvd_editNonSeqEventGUI(nonSeqEvt, lvdData);
        
        runScript(handles, lvdData, 1);
        lvd_processData(handles);
    end

% --- Executes during object creation, after setting all properties.
function nonSeqEventsListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nonSeqEventsListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in insertNonSeqEventButton.
function insertNonSeqEventButton_Callback(hObject, eventdata, handles)
% hObject    handle to insertNonSeqEventButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');

    addUndoState(handles,'Insert Non-Sequential Event');
    
    selEvtNum = get(handles.nonSeqEventsListbox,'Value');
    event = LaunchVehicleEvent.getDefaultEvent(lvdData.script);
    nonSeqEvt = LaunchVehicleNonSeqEvent(event);
    lvdData.script.nonSeqEvts.addEventAtInd(nonSeqEvt,selEvtNum);
    lvd_editNonSeqEventGUI(nonSeqEvt, lvdData);
    
	setNonSeqDeleteButtonEnable(lvdData, handles)

    runScript(handles, lvdData, 1);
    lvd_processData(handles);

% --- Executes on button press in deleteNonSeqEventButton.
function deleteNonSeqEventButton_Callback(hObject, eventdata, handles)
% hObject    handle to deleteNonSeqEventButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
    addUndoState(handles,'Delete Non-Sequential Event');
    
    eventNum = get(handles.nonSeqEventsListbox,'Value');
%     evt = lvdData.script.nonSeqEvts.getEventForInd(eventNum);
    
%     lvdData.optimizer.constraints.removeConstraintsThatUseEvent(evt);
%     
%     if(lvdData.optimizer.objFcn.usesEvent(evt))
%         lvdData.optimizer.objFcn = NoOptimizationObjectiveFcn(lvdData.optimizer, lvdData);
%         
%         warndlg(sprintf('The existing objective function referenced the deleted event.  The objective function has been replaced with a "%s" objective function.',ObjectiveFunctionEnum.NoObjectiveFunction.name),'Objective Function Reset','modal');
%     end
    
    lvdData.script.nonSeqEvts.removeEventFromIndex(eventNum);
    
    totNumNonSeqEvents = lvdData.script.nonSeqEvts.getTotalNumOfEvents();
    if(eventNum > totNumNonSeqEvents)
        set(handles.scriptListbox,'Value',totNumNonSeqEvents);
    end
    
    setNonSeqDeleteButtonEnable(lvdData, handles)
    
    runScript(handles, lvdData, 1);
    lvd_processData(handles);


% --------------------------------------------------------------------
function editStopwatchesMenu_Callback(hObject, eventdata, handles)
% hObject    handle to editStopwatchesMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
    addUndoState(handles,'Edit Stopwatches');
    
    lvd_EditStopwatchesGUI(lvdData);
    
    runScript(handles, lvdData, 1);
    lvd_processData(handles);


% --------------------------------------------------------------------
function toggleOptimForSelEventMenu_Callback(hObject, eventdata, handles)
% hObject    handle to toggleOptimForSelEventMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    eventNum = get(handles.scriptListbox,'Value');        
    event = lvdData.script.getEventForInd(eventNum);

    if(not(isempty(event)))
        addUndoState(handles,sprintf('Toggle Optimization on Event %u', eventNum));
        event.toggleOptimDisable(lvdData);
        
        lvd_processData(handles);
    end


% --------------------------------------------------------------------
function simulationMenu_Callback(hObject, eventdata, handles)
% hObject    handle to simulationMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function runScriptMenu_Callback(hObject, eventdata, handles)
% hObject    handle to runScriptMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
    if(not(isdeployed))
%         profile off; profile on;
    end
    
    propagateScript(handles, lvdData, 1);
    
    if(not(isdeployed))
%         profile viewer;
    end
    
    lvd_processData(handles);
    
    
    
% --------------------------------------------------------------------
function editExtremaMenu_Callback(hObject, eventdata, handles)
% hObject    handle to editExtremaMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');

    addUndoState(handles,'Edit Extrema');
    lvd_EditExtremasGUI(lvdData);
    
    runScript(handles, lvdData, 1);
    lvd_processData(handles); 


% --- Executes on button press in showSoICheckBox.
function showSoICheckBox_Callback(hObject, eventdata, handles)
% hObject    handle to showSoICheckBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showSoICheckBox
    lvd_processData(handles); 

% --- Executes on button press in showChildrenCheckBox.
function showChildrenCheckBox_Callback(hObject, eventdata, handles)
% hObject    handle to showChildrenCheckBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showChildrenCheckBox
    lvd_processData(handles); 

% --- Executes on button press in showChildBodyMarker.
function showChildBodyMarker_Callback(hObject, eventdata, handles)
% hObject    handle to showChildBodyMarker (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showChildBodyMarker
    lvd_processData(handles); 


% --------------------------------------------------------------------
function viewMenu_Callback(hObject, eventdata, handles)
% hObject    handle to viewMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    viewProfiles = lvdData.viewSettings.getProfilesArray();
    
    oldMenus = handles.setActiveViewProfileMenu.Children;
    for(i=1:length(oldMenus))
        delete(oldMenus(i));
    end
    
    for(i=1:length(viewProfiles))
        profile = viewProfiles(i);
        
        if(lvdData.viewSettings.isProfileActive(profile))
            checkedTxt = 'on';
        else
            checkedTxt = 'off';
        end
        
        cbFh = @(src,evt) viewProfileMenuSelectedCallback(src,evt, profile, lvdData.viewSettings, handles);
        
        menus(i) = uimenu(handles.setActiveViewProfileMenu, 'Text',profile.name, ...
                                                            'Checked',checkedTxt, ...
                                                            'MenuSelectedFcn',cbFh); %#ok<NASGU>
    end


function viewProfileMenuSelectedCallback(src,~, profile, viewSettings, handles)
    viewSettings.setProfileAsActive(profile);
    
    menus = src.Parent.Children;
    for(i=1:length(menus))
        delete(menus(i));
    end
    
    setappdata(handles.hDispAxesTimeSlider,'lastTime',NaN);
    lvd_processData(handles);
    
% --------------------------------------------------------------------
function editMissionNotesMenu_Callback(hObject, eventdata, handles)
% hObject    handle to editMissionNotesMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
    addUndoState(handles,'Edit Mission Notes');
    
    lvd_MissionNotesGUI(lvdData);


% --------------------------------------------------------------------
function autopropagateMenu_Callback(hObject, eventdata, handles)
% hObject    handle to autopropagateMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    writeOutput = getappdata(handles.ma_LvdMainGUI,'write_to_output_func');

    addUndoState(handles,'Edit Script Auto-Propagation');
    
    if(strcmp(get(gcbo, 'Checked'),'on'))
        lvdData.settings.autoPropScript = false;
        
        writeOutput('Script auto-propagation is off.  Run script manually with ctrl-p.','append');
    else
        lvdData.settings.autoPropScript = true;
        
        writeOutput('Script auto-propagation is on.','append');
    end


% --------------------------------------------------------------------
function showConstrJacobianHeatMapMenu_Callback(hObject, eventdata, handles)
% hObject    handle to showConstrJacobianHeatMapMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
    constrLbls = lvdData.optimizer.constraints.getListboxStr();
    [x0All, ~, varLbls] = lvdData.optimizer.vars.getTotalScaledXVector();
    
    if(~isempty(constrLbls) && ~isempty(varLbls))
        hHlpDlg = helpdlg('Computing constraint Jacobian with current trajectory.  Please wait...','Computing Jacobian');
        
        try
            evtToStartScriptExecAt = lvdData.script.getEventForInd(1);
            nonlcon = @(x) lvdData.optimizer.constraints.evalConstraints(x, true, evtToStartScriptExecAt, false);
            jacNonlcon = @(x) computeJacNonlconFunc(x, nonlcon);

%             jac = abs(mklJac(jacNonlcon, x0All));

            cAtX0 = jacNonlcon(x0All);

            if(not(isempty(gcp('nocreate'))))
                useParallel = true;
            else
                useParallel = false;
            end
%             useParallel = false;
            
            finiteDiffMeth = CustomFiniteDiffsCalculationMethod();
            jac = abs(finiteDiffMeth.computeJacobian(jacNonlcon, x0All, cAtX0, useParallel));

            zeroColInds = find(all(jac < eps));
            totalColInds = 1:1:size(jac,2);
            nonZeroColInds = setdiff(totalColInds,zeroColInds);

            filteredJac = jac(:,nonZeroColInds);
            filteredVarLbls = varLbls(nonZeroColInds);

            [c, ceq, ~, ~, ~, ~, ~, ~, ~, ~] = nonlcon(x0All);
            heatMapConstrLbls = {};
            totNumIneqConstr = length(c)/2;
            totNumConstr = totNumIneqConstr + length(ceq);
            for(i=1:totNumIneqConstr)
                heatMapConstrLbls{end+1} = sprintf('%s (Lwr Bnd)', constrLbls{i}); %#ok<AGROW>
                heatMapConstrLbls{end+1} = sprintf('%s (Upr Bnd)', constrLbls{i}); %#ok<AGROW>
            end

            heatMapConstrLbls = horzcat(heatMapConstrLbls, constrLbls(totNumIneqConstr+1:totNumConstr));

            hFig = figure();
            hHeatMap = heatmap(hFig, filteredVarLbls,heatMapConstrLbls,filteredJac);
            
            hHeatMap.Title = {'Increase the scale factor of','any constraint with values >> 1'};
            hHeatMap.XLabel = 'Variables';
            hHeatMap.YLabel = 'Constraints';
        catch ME
            errordlg(sprintf('The following error was encountered while trying to compute the Jacobian:\n\n %s',ME.message));
        end
        
        if(ishandle(hHlpDlg) && isvalid(hHlpDlg))
            close(hHlpDlg);
        end
    end
    
function [c] = computeJacNonlconFunc(x, nonlcon)
    [cML, ceqML] = nonlcon(x);
    
    c = [cML(:)', ceqML(:)'];

    


% --------------------------------------------------------------------
function selectOptimizationAlgosMenu_Callback(hObject, eventdata, handles)
% hObject    handle to selectOptimizationAlgosMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    writeOutput = getappdata(handles.ma_LvdMainGUI,'write_to_output_func');
    
    addUndoState(handles,'Edit Optimizer Algorithm');
    
    lvd_OptimizerSelectionGUI(lvdData);
    
    if(lvdData.optimizer.getSelectedOptimizer().usesParallel())
        numWorkers = lvdData.optimizer.getSelectedOptimizer().getNumParaWorkers();
        startParallelPool(writeOutput, numWorkers);
    end
    
    
    % --------------------------------------------------------------------
function adjustVariablesMenu_Callback(hObject, eventdata, handles)
% hObject    handle to adjustVariablesMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    lvdOpt = lvdData.optimizer;
    varSet = lvdOpt.vars;
    varSet.sortVarsByEvtNum();
    [x, ~, ~, ~] = varSet.getTotalScaledXVector();
    
    if(~isempty(x))
        addUndoState(handles,'Adjust Optimization Variables');
        
        propScriptFcn = @() propagateScript(handles, lvdData, 1);
        procDataFcn = @() lvd_processData(handles);
        
        lvd_adjustOptVarGUI(lvdData, propScriptFcn, procDataFcn);
        
        runScript(handles, lvdData, 1);
        lvd_processData(handles);
    else
        warndlg('Cannot display adjustment dialog: no optimization variables are enabled on this script.');
    end


% --------------------------------------------------------------------
function pluginsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to pluginsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function managePluginsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to managePluginsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
    addUndoState(handles,'Manage Plugins');
    
    result = ldv_editPluginGUI(lvdData);
    
    if(result == false)
        undoMenu_Callback(handles.undoMenu, [], handles);
    else
        runScript(handles, lvdData, 1);
    end
    
    lvd_processData(handles);


% --------------------------------------------------------------------
function editViewSettingsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to editViewSettingsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
    addUndoState(handles,'Edit View Settings');
    
%     lvd_viewSettingsGUI(lvdData.viewSettings);
    lvd_viewSettingsGUI_App(lvdData.viewSettings);
    
    setappdata(handles.hDispAxesTimeSlider,'lastTime',NaN);
       
    enableDisableArrowButtons(lvdData, handles);
    lvd_processData(handles);

    
function enableDisableArrowButtons(lvdData, handles)
    type = lvdData.viewSettings.selViewProfile.trajEvtsViewType;
    switch type
        case ViewEventsTypeEnum.All
            handles.decrOrbitToPlotNum.Enable = 'off';
            handles.incrOrbitToPlotNum.Enable = 'off';
            
        case ViewEventsTypeEnum.SoIChunk
            handles.decrOrbitToPlotNum.Enable = 'on';
            handles.incrOrbitToPlotNum.Enable = 'on';
            
        otherwise
            error('Unknown event view type: %s', type.name);
    end

% --------------------------------------------------------------------
function popOutOrbitDisplayMenu_Callback(hObject, eventdata, handles)
% hObject    handle to popOutOrbitDisplayMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    hFig = figure('Visible','off');
    hAx = axes(hFig);
    inlineDispAxes = handles.dispAxes;
    handles.dispAxes = hAx;
    set(hAx,'UserData',get(handles.dispAxes,'UserData'));

    hFig.DeleteFcn = @(src,evt) popOutOrbitDispDelFcn(src,evt, inlineDispAxes, handles);
    
    wb = waitbar(0,'Popping out orbit display...');
    wbch = allchild(wb);
    jp = wbch(1).JavaPeer;
    jp.setIndeterminate(1);
    
    try
        lvd_processData(handles);
    catch ME
        %nothing
    end

    title(hAx, handles.dispAxisTitleLabel.String);
    
    delete(wb);
    hFig.Visible = 'on';
    
    tf = cameratoolbar(handles.ma_LvdMainGUI, 'GetVisible');
    if(tf)
        cameratoolbar(hFig, 'Show');
    end
    
    
function popOutOrbitDispDelFcn(~,~, inlineDispAxes, handles)
    handles.dispAxes = inlineDispAxes;
    
    lvd_processData(handles); 


% --------------------------------------------------------------------
function setActiveViewProfileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to setActiveViewProfileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function editGroundObjsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to editGroundObjsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
    addUndoState(handles,'Edit Ground Objects');
    
    result = lvd_EditGroundObjectsGUI(lvdData.groundObjs);
    
%     if(result == false)
%         undoMenu_Callback(handles.undoMenu, [], handles);
%     else
%         runScript(handles, lvdData, 1);
%     end
    
    lvd_processData(handles);


% --------------------------------------------------------------------
function editCalculusObjectsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to editCalculusObjectsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');

    addUndoState(handles,'Edit Calculus Calculations');
    lvd_EditCalculusObjsGUI(lvdData);
    
    runScript(handles, lvdData, 1);
    lvd_processData(handles); 


% --------------------------------------------------------------------
function createContConstraintsWithSelEvtMenu_Callback(hObject, eventdata, handles)
% hObject    handle to createContConstraintsWithSelEvtMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');

    totNumEvts = lvdData.script.getTotalNumOfEvents();
    eventNum = get(handles.scriptListbox,'Value');
    evt = lvdData.script.getEventForInd(eventNum);
    
    prevEvts = LaunchVehicleEvent.empty(1,0);
    prevEvtsNames = {};
    for(i=1:totNumEvts)
        if(i == eventNum)
            continue;
        end
        
        prevEvt = lvdData.script.getEventForInd(i);
        prevEvts(end+1) = prevEvt; %#ok<AGROW>
        prevEvtsNames{end+1} = prevEvt.getListboxStr(); %#ok<AGROW>
    end
    
    if(not(isempty(prevEvts)))
        [Selection,ok] = listdlgARH('ListString',prevEvtsNames, ...
                                    'SelectionMode','single', ...
                                    'ListSize', [300 300], ...
                                    'Name','Select Constraint Event', ...
                                    'PromptString', 'Select event to create continuity constraints with:');
                                
        if(ok == 1)
            selEvt = prevEvts(Selection);
            selEvtNum = selEvt.getEventNum();
            
            if(eventNum > selEvtNum)
                refEvt = evt;
                constrEvt = selEvt;
            else
                refEvt = selEvt;
                constrEvt = evt;
            end
            
            c = AbstractConstraint.empty(1,0);
            
            %position
            c(end+1) = PositionContinuityConstraintX(refEvt, constrEvt);
            c(end+1) = PositionContinuityConstraintY(refEvt, constrEvt);
            c(end+1) = PositionContinuityConstraintZ(refEvt, constrEvt);
            
            %velocity
            c(end+1) = VelocityContinuityConstraintX(refEvt, constrEvt);
            c(end+1) = VelocityContinuityConstraintY(refEvt, constrEvt);
            c(end+1) = VelocityContinuityConstraintZ(refEvt, constrEvt);
            
            %time
            c(end+1) = TimeContinuityConstraint(refEvt, constrEvt);
            
            for(i=1:length(c))
                lvdData.optimizer.constraints.addConstraint(c(i));
            end
            
            msgbox('Position, velocity, and time continuity constraints added successfully.');
        else
            return;
        end
    else
        warndlg('There must be at least one other event in the missions script to create continuity constraints with.');
    end
    


% --------------------------------------------------------------------
function setIntegrationStepSizeForAllEventsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to setIntegrationStepSizeForAllEventsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    writeOutput = getappdata(handles.ma_LvdMainGUI,'write_to_output_func');
    
    input_str = sprintf(['Enter the desired integration step size for all events:\n',...
                         '(Minimum = 1E-6, Maximum = Inf)\n',...
                         '(This will influence script execution speed.)']);
    str = inputdlg(input_str, 'Global Integrator Step Size', [1 75], {'1.0'});
    if(isempty(str))
        return;
    end
    
    str = str{1};
    
    if(checkStrIsNumeric(str) && str2double(str) >= 1E-6 && str2double(str) <= Inf)
        addUndoState(handles,'Set Global Integrator Step Size');  
        
        writeOutput(sprintf('Setting integrator step size on all events to %s.', str),'append');
        
        stepSize = str2double(str);
        totNumEvts = lvdData.script.getTotalNumOfEvents();
        for(i=1:totNumEvts)
            evt = lvdData.script.getEventForInd(i);

            evt.integratorObj.getOptions().setIntegratorStepSize(stepSize);
        end
        
        runScript(handles, lvdData, 1);
        lvd_processData(handles);
    else
        writeOutput(sprintf('Could not set the desired integration step size on all events.  "%s" is an invalid entry.', str),'append');
        beep;
    end


% --------------------------------------------------------------------
function displayEvtPropTimesInLogFileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to displayEvtPropTimesInLogFileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    writeOutput = getappdata(handles.ma_LvdMainGUI,'write_to_output_func');

    addUndoState(handles,'Edit Display Event Prop Times');
    
    if(strcmp(get(gcbo, 'Checked'),'on'))
        lvdData.settings.disEvtPropTimes = false;
        
        writeOutput('Display of event propagation times in KSPTOT log file is off.','append');
    else
        lvdData.settings.disEvtPropTimes = true;
        
        writeOutput('Event propagation times will be displayed in the ksptot.log file.','append');
    end


% --- Executes when ma_LvdMainGUI is resized.
function ma_LvdMainGUI_SizeChangedFcn(hObject, eventdata, handles)
% hObject    handle to ma_LvdMainGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    origWidth = getappdata(hObject,'OriginalWidth');
    origHeight = getappdata(hObject,'OriginalHeight');
    
    newPos = hObject.Position;
    newWidth = newPos(3);
    newHeight = newPos(4);
    
    if(newWidth <= origWidth && newHeight <= origHeight)
        try
            LimitFigSize(hObject, 'min', [origWidth, origHeight]);
        catch
            %do nothing
        end
    end
    
%     %update figure to not get smaller than original size
    updatedFigPos = newPos;
%     updatedFigPos(3) = max([origWidth,newWidth]);
%     updatedFigPos(4) = max([origHeight,newHeight]);
%     hObject.Position = updatedFigPos;
%     drawnow;
    
    %resize title text banner
    titleOffsetFromTop = getappdata(hObject,'titleOffsetFromTop');
    titlePos = handles.titleText.Position;
    titlePos(3) = updatedFigPos(3);
    titlePos(2) = updatedFigPos(4) - (titlePos(4) + titleOffsetFromTop);
    handles.titleText.Position = titlePos;
    
    %initial state panel
    initScStatePanelOffsetFromTop = getappdata(hObject,'initScStatePanelOffsetFromTop');
    initScStatePanelPos = handles.initScStatePanel.Position;
    initScStatePanelPos(2) = updatedFigPos(4) - (initScStatePanelPos(4) + initScStatePanelOffsetFromTop);
    handles.initScStatePanel.Position = initScStatePanelPos;
    
    %final state panel
    finalScStatePanelOffsetFromTop = getappdata(hObject,'finalScStatePanelOffsetFromTop');
    finalScStatePanelPos = handles.finalScStatePanel.Position;
    finalScStatePanelPos(2) = updatedFigPos(4) - (finalScStatePanelPos(4) + finalScStatePanelOffsetFromTop);
    handles.finalScStatePanel.Position = finalScStatePanelPos;
    
    %display axes title label
    dispAxisTitleLabelOffsetFromTop = getappdata(hObject,'dispAxisTitleLabelOffsetFromTop');
    dispAxisTitleLabelPos = handles.dispAxisTitleLabel.Position;
    dispAxisTitleLabelPos(2) = updatedFigPos(4) - (dispAxisTitleLabelPos(4) + dispAxisTitleLabelOffsetFromTop);
    dispAxisTitleLabelPos(3) = updatedFigPos(3) - dispAxisTitleLabelPos(1);
    handles.dispAxisTitleLabel.Position = dispAxisTitleLabelPos;
    
    %display axes    
    dispAxesPanelOffsetFromTop = getappdata(hObject,'dispAxesPanelOffsetFromTop');
    dispAxesPanelPos = handles.dispAxesPanel.Position;
    dispAxesPanelPos(3) = updatedFigPos(3) - dispAxesPanelPos(1);
    dispAxesPanelPos(4) = newHeight - (dispAxesPanelPos(2) + dispAxesPanelOffsetFromTop);
    handles.dispAxesPanel.Position = dispAxesPanelPos;    
       
    %insert seq event button
    insertEventButtonOffsetFromTop = getappdata(hObject,'insertEventButtonOffsetFromTop');
    insertEventButtonPos = handles.insertEventButton.Position;
    insertEventButtonPos(2) = updatedFigPos(4) - (insertEventButtonPos(4) + insertEventButtonOffsetFromTop);
    handles.insertEventButton.Position = insertEventButtonPos;
    
    %timeSliderValueLabel
    timeSliderValueLabelOffsetFromRight = getappdata(hObject,'timeSliderValueLabelOffsetFromRight');
    timeSliderValueLabelPos = handles.timeSliderValueLabel.Position;
    timeSliderValueLabelPos(3) = (updatedFigPos(3) - timeSliderValueLabelOffsetFromRight) - timeSliderValueLabelPos(1);
    handles.timeSliderValueLabel.Position = timeSliderValueLabelPos;
    
    %script listbox
    scriptListboxOffsetFromTop = getappdata(hObject,'scriptListboxOffsetFromTop');
    scriptListboxPos = handles.scriptListbox.Position;
    scriptListboxPos(4) = newHeight - (scriptListboxPos(2) + scriptListboxOffsetFromTop);
    handles.scriptListbox.Position = scriptListboxPos;
    
    %incrOrbitToPlotNum Button
    incrOrbitToPlotNumOffsetFromRight = getappdata(hObject,'incrOrbitToPlotNumOffsetFromRight');
    incrOrbitToPlotNumPos = handles.incrOrbitToPlotNum.Position;
    incrOrbitToPlotNumPos(1) = newWidth - incrOrbitToPlotNumOffsetFromRight - incrOrbitToPlotNumPos(3);
    handles.incrOrbitToPlotNum.Position = incrOrbitToPlotNumPos;
    
    %timeSliderPanel
    timeSliderPanelOffsetFromRight = getappdata(hObject,'timeSliderPanelOffsetFromRight');
    timeSliderPanelPos = handles.timeSliderPanel.Position;
    timeSliderPanelPos(3) = newWidth - (timeSliderPanelPos(1) + timeSliderPanelOffsetFromRight);
    handles.timeSliderPanel.Position = timeSliderPanelPos;
    
    %warningAlertPanel
    warningAlertPanelOffsetFromRight = getappdata(hObject,'warningAlertPanelOffsetFromRight');
    warningAlertPanelPos = handles.warningAlertPanel.Position;
    warningAlertPanelPos(3) = newWidth - (warningAlertPanelPos(1) + warningAlertPanelOffsetFromRight);
    handles.warningAlertPanel.Position = warningAlertPanelPos;
    
    drawnow limitrate nocallbacks;
    
% --- Executes when timeSliderPanel is resized.
function timeSliderPanel_SizeChangedFcn(hObject, eventdata, handles)
% hObject    handle to timeSliderPanel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if(not(isempty(handles)))
        panelPos = hObject.Position;
        hDispAxesTimeSliderJavaWrapperPos = handles.hDispAxesTimeSliderJavaWrapper.Position;
        hDispAxesTimeSliderJavaWrapperPos(3:4) = panelPos(3:4);
        handles.hDispAxesTimeSliderJavaWrapper.Position = hDispAxesTimeSliderJavaWrapperPos;
    end


% --- Executes when warningAlertPanel is resized.
function warningAlertPanel_SizeChangedFcn(hObject, eventdata, handles)
% hObject    handle to warningAlertPanel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if(not(isempty(handles)))
        panelPos = hObject.Position;
        
        warnAlertsSliderOffsetFromRight = getappdata(hObject,'warnAlertsSliderOffsetFromRight');
        warnAlertsSliderPos = handles.warnAlertsSlider.Position;
        warnAlertsSliderPos(1) = panelPos(3) - warnAlertsSliderPos(3) - warnAlertsSliderOffsetFromRight;
        handles.warnAlertsSlider.Position = warnAlertsSliderPos;
        
        warningLblOffsetFromRight = getappdata(hObject,'warningLblOffsetFromRight');
        warningLblPos = handles.warning1Lbl.Position;
        newWarnLblWidth = panelPos(3) - warningLblPos(1) - warningLblOffsetFromRight;
        warningLblPos(3) = newWarnLblWidth;
        handles.warning1Lbl.Position = warningLblPos;
        handles.warning1Lbl.String = strWrapForLabel(handles.warning1Lbl,  handles.warning1Lbl.TooltipString);
        
        warningLblPos = handles.warning2Lbl.Position;
        warningLblPos(3) = newWarnLblWidth;
        handles.warning2Lbl.Position = warningLblPos;
        handles.warning2Lbl.String = strWrapForLabel(handles.warning2Lbl,  handles.warning2Lbl.TooltipString);
        
        warningLblPos = handles.warning3Lbl.Position;
        warningLblPos(3) = newWarnLblWidth;
        handles.warning3Lbl.Position = warningLblPos;
        handles.warning3Lbl.String = strWrapForLabel(handles.warning3Lbl,  handles.warning3Lbl.TooltipString);
        
        warningLblPos = handles.warning4Lbl.Position;
        warningLblPos(3) = newWarnLblWidth;
        handles.warning4Lbl.Position = warningLblPos;
        handles.warning4Lbl.String = strWrapForLabel(handles.warning4Lbl,  handles.warning4Lbl.TooltipString);
        
        warningLblPos = handles.warning5Lbl.Position;
        warningLblPos(3) = newWarnLblWidth;
        handles.warning5Lbl.Position = warningLblPos;
        handles.warning5Lbl.String = strWrapForLabel(handles.warning5Lbl,  handles.warning5Lbl.TooltipString);
        
        warningLblPos = handles.warning6Lbl.Position;
        warningLblPos(3) = newWarnLblWidth;
        handles.warning6Lbl.Position = warningLblPos;
        handles.warning6Lbl.String = strWrapForLabel(handles.warning6Lbl,  handles.warning6Lbl.TooltipString);
    end


% --- Executes when dispAxesPanel is resized.
function dispAxesPanel_SizeChangedFcn(hObject, eventdata, handles)
% hObject    handle to dispAxesPanel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if(not(isempty(handles)))
        dispAxesPanelPos = hObject.Position;
        
        %disp axes
        dispAxesPos = [10, 5, dispAxesPanelPos(3)-10, dispAxesPanelPos(4)-10];
        handles.dispAxes.Position = dispAxesPos;
        
        %axes working label
        plotWorkingLblPos = handles.plotWorkingLbl.Position;
        plotWorkingLblPos(1:2) = [1 1];
        handles.plotWorkingLbl.Position = plotWorkingLblPos;

        %disp axes results out of date label
        plotOutOfDataLblPos = handles.scriptResultsOutOfDateLbl.Position;
        plotOutOfDataLblPos(1:2) = [1 1];
        plotOutOfDataLblPos(3) = dispAxesPanelPos(3);
        handles.scriptResultsOutOfDateLbl.Position = plotOutOfDataLblPos;
    end


% --------------------------------------------------------------------
function toggleCameraToolbar_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to toggleCameraToolbar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    cameratoolbar(handles.ma_LvdMainGUI, 'Toggle');


% --------------------------------------------------------------------
function uploadImpDvActionToKspMenu_Callback(hObject, eventdata, handles)
% hObject    handle to uploadImpDvActionToKspMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
    eventNum = handles.scriptListbox.Value;
    event = lvdData.script.getEventForInd(eventNum);
    actions = event.actions;
    
    bool = arrayfun(@(x) isa(x,'AddDeltaVAction'), actions);
    if(any(bool)) %there's at least one delta-v action
        if(sum(bool) == 1) %there's one delta-v action
            deltaVAction = actions(bool);
        else               %there's more than one delta-v action
            actionsListBoxStr = event.getActionsListboxStr();
            actionsListBoxStr = actionsListBoxStr(bool);
            dvActions = actions(bool);
            
            [Selection,ok] = listdlgARH('ListString',actionsListBoxStr, ...
                                        'SelectionMode', 'single', ...
                                        'ListSize', [300 300], ...
                                        'Name', 'Select Delta-V Action', ...
                                        'PromptString', 'Select Delta-V Action to Upload:');
            if(ok)
                deltaVAction = dvActions(Selection);
            else
                return;
            end            
        end
        
    else
        errordlg('Error: Selected event does not have an impulsive delta-v action.','Upload Failed!');
        return;
    end
    
    subStateLog = lvdData.stateLog.getAllStateLogEntriesForEvent(event);
    preActionsStateLogEntry = subStateLog(end-1);
    
    data = deltaVAction.getUploadDvToKspData(preActionsStateLogEntry);
    uploadManeuverToKSP(data);
    


% --------------------------------------------------------------------
function advanceScriptToSelectedEventMenu_Callback(hObject, eventdata, handles)
% hObject    handle to advanceScriptToSelectedEventMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
    eventNum = handles.scriptListbox.Value;
    event = lvdData.script.getEventForInd(eventNum);
    eventNum = event.getEventNum();
    eventFirstStateLogEntry = lvdData.stateLog.getFirstStateLogForEvent(event);
    
    tf = false;
    badEvtStrs = [];
    for(i=eventNum+1:lvdData.script.getTotalNumOfEvents())
        evt = lvdData.script.getEventForInd(i);
        
        for(j=1:eventNum)
            evtToBeDel = lvdData.script.getEventForInd(j);
            
            tf = tf || evt.usesEvent(evtToBeDel);
            
            if(evt.usesEvent(evtToBeDel))
                badEvtStrs{end+1} = sprintf('Event %u uses Event %u in an action or event termination condition.', evt.getEventNum(), evtToBeDel.getEventNum());
            end
        end
    end
    
    if(tf == false)
        addUndoState(handles,'Advance Script to Event');

        oldAutoPropSetting = lvdData.settings.autoPropScript;
        if(oldAutoPropSetting == false)
%             lvdData.settings.autoPropScript = true;

            propagateScript(handles, lvdData, 1);
%             runScript(handles, lvdData, 1);
    %         lvd_processData(handles);
        end

        lvdData.initStateModel.setInitialStateFromStateLogEntry(eventFirstStateLogEntry);

        for(i=eventNum-1:-1:1)
            evt = lvdData.script.getEventForInd(i);
            lvdData.optimizer.constraints.removeConstraintsThatUseEvent(evt);
            lvdData.optimizer.objFcn.removeObjFcnsThatUseEvent(evt);
            lvdData.script.removeEvent(evt);
        end

        handles.scriptListbox.Value = 1;
        runScript(handles, lvdData, 1);
        lvd_processData(handles);
%         lvdData.settings.autoPropScript = oldAutoPropSetting;
    else
        badEvtStrJoin = strjoin(badEvtStrs,'\n');
        msgStr = sprintf('Cannot advance to event because one or more of the events that would be deleted are in use elsewhere:\n\n%s', badEvtStrJoin);
        errordlg(msgStr,'Cannot Advance to Event');
    end


% --------------------------------------------------------------------
function createkOSExecCodeMenu_Callback(hObject, eventdata, handles)
% hObject    handle to createkOSExecCodeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
    [FileName,PathName,FilterIndex] = uiputfile({'*.csv','CSV Files'},'Save LVD Data to CSV.');
    
    if(FilterIndex == 0)
        return;
    else
        csvFilePath = fullfile(PathName,FileName);
    end
    
    eventsListboxStr = lvdData.script.getListboxStr();
    evtInds = 1:length(eventsListboxStr);
    [Selection,ok] = listdlgARH('ListString', eventsListboxStr, ...
                                 'ListSize', [300, 300], ...
                                 'InitialValue', evtInds, ...
                                 'Name', 'Select Events for Export', ...
                                 'PromptString', 'Select the events to export for kOS:');
                             
     if(ok == 0 || isempty(Selection))
         return;
     end
        
    oldAutoPropSetting = lvdData.settings.autoPropScript;
    if(oldAutoPropSetting == false)
        propagateScript(handles, lvdData, 1);
    end
    
    stateLog = lvdData.stateLog;
    stateLogEntries = LaunchVehicleStateLogEntry.empty(1,0);
	for(i=1:length(Selection))
        evt = lvdData.script.getEventForInd(Selection(i));
        stateLogEntries = [stateLogEntries, stateLog.getAllStateLogEntriesForEvent(evt)]; %#ok<AGROW>
	end

%     stateLogEntries = stateLog.getAllEntries();
    
    %sort state log entries by time ascending so that they show up in the
    %right order.
    stateLogTimes = [stateLogEntries.time];
    [~,I] = sort(stateLogTimes);
    stateLogEntries = stateLogEntries(I);
    
    numEntries = length(stateLogEntries);
    
    time = NaN(1,numEntries);
    yaw = NaN(1,numEntries);
    pitch = NaN(1,numEntries);
    roll = NaN(1,numEntries);
    throttle = NaN(1,numEntries);
    timeToNextEvt = NaN(1,numEntries);
    evtNames = cell(1,numEntries);
    nextEvtNames = cell(1,numEntries);
    
    hWaitbar = waitbar(0,'Parsing State Log Data, Please Wait...');
    numStateLogEntries = length(stateLogEntries);
    for(i=1:numStateLogEntries)
        stateLogEntry = stateLogEntries(i);
        
        time(i) = stateLogEntry.time;
        yaw(i) = lvd_SteeringAngleTask(stateLogEntry, 'yaw');
        pitch(i) = lvd_SteeringAngleTask(stateLogEntry, 'pitch');
        roll(i) = lvd_SteeringAngleTask(stateLogEntry, 'roll');
        throttle(i) = stateLogEntry.throttle;
        
        evt = stateLogEntry.event;
        evtNames{i} = evt.name;
        
        nextEvt = LaunchVehicleEvent.empty(0,1);
        nextEvtStartTime = [];
        for(j=i:numStateLogEntries)
            testEntry = stateLogEntries(j);
            if(evt ~= testEntry.event)
                nextEvt = testEntry.event;
                nextEvtStartTime = testEntry.time;
                break;
            end
        end

        if(not(isempty(nextEvt)))
            timeToNextEvt(i) = nextEvtStartTime - stateLogEntry.time;
            nextEvtNames{i} = nextEvt.name;
        else
            timeToNextEvt(i) = 0;
            nextEvtNames{i} = '';
        end
        
        waitbar(i/numStateLogEntries, hWaitbar);
    end
    
    if(isvalid(hWaitbar))
        close(hWaitbar);
    end

    M = [time(:)'; ...
         yaw(:)'; ...
         pitch(:)'; ...
         roll(:)'; ...
         throttle(:)'; ...
         timeToNextEvt(:)'];
    dlmwrite(csvFilePath,M,'precision','%0.13f');
    
    fid = fopen(csvFilePath,'a');
    fprintf(fid, '%s\n', strjoin(evtNames,','));
    fprintf(fid, '%s', strjoin(nextEvtNames,','));
    fclose(fid);


% --------------------------------------------------------------------
function geometryMenu_Callback(hObject, eventdata, handles)
% hObject    handle to geometryMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function editPointsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to editPointsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    hKsptotMainGUI = getappdata(hObject,'ksptotMainGUI');
    
    addUndoState(handles,'Edit Points');
    lvd_EditGeometricPointsGUI(lvdData, hKsptotMainGUI);
    
    runScript(handles, lvdData, 1);
    lvd_processData(handles);

% --------------------------------------------------------------------
function editVectorsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to editVectorsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
    addUndoState(handles,'Edit Vectors');
    lvd_EditGeometricVectorsGUI(lvdData);
    
    runScript(handles, lvdData, 1);
    lvd_processData(handles);

% --------------------------------------------------------------------
function editCoordSysMenu_Callback(hObject, eventdata, handles)
% hObject    handle to editCoordSysMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
    addUndoState(handles,'Edit Coordinate Systems');
    lvd_EditGeometricCoordSysGUI(lvdData);
    
    runScript(handles, lvdData, 1);
    lvd_processData(handles);

% --------------------------------------------------------------------
function editRefRamesMenu_Callback(hObject, eventdata, handles)
% hObject    handle to editRefRamesMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
    addUndoState(handles,'Edit Reference Frames');
    lvd_EditGeometricRefFramesGUI(lvdData);
    
    runScript(handles, lvdData, 1);
    lvd_processData(handles);


% --------------------------------------------------------------------
function editAnglesMenu_Callback(hObject, eventdata, handles)
% hObject    handle to editAnglesMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
    addUndoState(handles,'Edit Angles');
    lvd_EditGeometricAnglesGUI(lvdData);
    
    runScript(handles, lvdData, 1);
    lvd_processData(handles);

% --------------------------------------------------------------------
function editPlanesMenu_Callback(hObject, eventdata, handles)
% hObject    handle to editPlanesMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    
    addUndoState(handles,'Edit Planes');
    lvd_EditGeometricPlanesGUI(lvdData);
    
    runScript(handles, lvdData, 1);
    lvd_processData(handles);