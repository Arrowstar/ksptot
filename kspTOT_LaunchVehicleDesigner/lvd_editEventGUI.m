function varargout = lvd_editEventGUI(varargin)
% LVD_EDITEVENTGUI MATLAB code for lvd_editEventGUI.fig
%      LVD_EDITEVENTGUI, by itself, creates a new LVD_EDITEVENTGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITEVENTGUI returns the handle to a new LVD_EDITEVENTGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITEVENTGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITEVENTGUI.M with the given input arguments.
%
%      LVD_EDITEVENTGUI('Property','Value',...) creates a new LVD_EDITEVENTGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_editEventGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_editEventGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_editEventGUI

% Last Modified by GUIDE v2.5 13-May-2021 09:08:26

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_editEventGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_editEventGUI_OutputFcn, ...
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


% --- Executes just before lvd_editEventGUI is made visible.
function lvd_editEventGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to lvd_editEventGUI (see VARARGIN)

    % Choose default command line output for lvd_editEventGUI
    handles.output = hObject;

    event = varargin{1};
    setappdata(hObject,'event',event);
    event.clearActiveOptVarsCache();
    
    isNonSeq = varargin{2};
    setappdata(hObject,'isNonSeq',isNonSeq);

    populateGUI(handles, event, isNonSeq);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_editEventGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_editEventGUI);


function populateGUI(handles, event, isNonSeq)
    set(handles.eventNameText,'String',event.name);
    
    termCond = event.termCond;
    set(handles.termCondNameLabel,'String',termCond.getName());
    set(handles.termCondNameLabel,'TooltipString',termCond.getName());
    
    set(handles.actionsListbox,'String',event.getActionsListboxStr());
    set(handles.actionsListbox,'Value',1);
    
    handles.colorSpecCombo.String = ColorSpecEnum.getListboxStr();
    [~,ind] = ColorSpecEnum.getEnumForListboxStr(event.colorLineSpec.color.name);
    handles.colorSpecCombo.Value = ind;
    
    handles.lineSpecCombo.String = LineSpecEnum.getListboxStr();
    [~,ind] = LineSpecEnum.getEnumForListboxStr(event.colorLineSpec.lineSpec.name);
    handles.lineSpecCombo.Value = ind;
    
    handles.plotMethodCombo.String = EventPlottingMethodEnum.getListBoxStr();
    ind = EventPlottingMethodEnum.getIndForName(event.plotMethod.name);
    handles.plotMethodCombo.Value = ind;
    
    handles.eventTermCondDirCombo.String = EventTermCondDirectionEnum.getListboxStr();
    [~,ind] = EventTermCondDirectionEnum.getEnumForListboxStr(event.termCondDir.name);
    handles.eventTermCondDirCombo.Value = ind;
    
    contents = handles.lineWidthCombo.String;
    contentsDouble = str2double(contents);
    ind = find(contentsDouble == event.colorLineSpec.lineWidth);
    set(handles.lineWidthCombo,'Value',ind);
    
    handles.integratorCombo.String = IntegratorEnum.getListBoxStrs();
    ind = IntegratorEnum.getIndOfListboxStr(event.integratorObj.integratorEnum.nameStr);
    handles.integratorCombo.Value = ind;
    integratorCombo_Callback(handles.integratorCombo, [], handles);
    
    handles.propagatorCombo.String = PropagatorEnum.getListBoxStr();
    ind = PropagatorEnum.getIndForName(event.propagatorObj.propagatorEnum.name);
    handles.propagatorCombo.Value = ind;
    propagatorCombo_Callback(handles.propagatorCombo, [], handles);
    
    handles.propDirCombo.String = PropagationDirectionEnum.getListBoxStr();
    handles.propDirCombo.Value = PropagationDirectionEnum.getIndForName(event.propDir.name);
    
    handles.checkSoITransCheckbox.Value = double(event.checkForSoITrans);
    
    handles.actionExecNodeCombo.String = ActionExecNodeEnum.getListBoxStr();
    handles.actionExecNodeCombo.Value = ActionExecNodeEnum.getIndForName(event.execActionsNode.name);
    
    if(isNonSeq)
        handles.colorSpecCombo.Enable = 'off';
        handles.lineSpecCombo.Enable = 'off';
        handles.lineWidthCombo.Enable = 'off';
        handles.plotMethodCombo.Enable = 'off';
        handles.propagatorCombo.Enable = 'off';
        handles.propagatorOptionsButton.Enable = 'off';
        handles.integratorCombo.Enable = 'off';
        handles.integratorOptionsButton.Enable = 'off';
        handles.propDirCombo.Enable = 'off';
        handles.checkSoITransCheckbox.Enable = 'off';
    end

% --- Outputs from this function are returned to the command line.
function varargout = lvd_editEventGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = [];
    else
        event = getappdata(handles.lvd_editEventGUI,'event');
        
        evtName = get(handles.eventNameText,'String');
        event.name = evtName;
        
        nameStr = handles.colorSpecCombo.String(handles.colorSpecCombo.Value);
        [enum,~] = ColorSpecEnum.getEnumForListboxStr(nameStr);
        event.colorLineSpec.color = enum;
    
        nameStr = handles.lineSpecCombo.String(handles.lineSpecCombo.Value);
        [enum,~] = LineSpecEnum.getEnumForListboxStr(nameStr);
    	event.colorLineSpec.lineSpec = enum;
        
        nameStr = handles.eventTermCondDirCombo.String(handles.eventTermCondDirCombo.Value);
        [enum,~] = EventTermCondDirectionEnum.getEnumForListboxStr(nameStr);
    	event.termCondDir = enum;
        
        nameStr = handles.plotMethodCombo.String(handles.plotMethodCombo.Value);
        [enum,~] = EventPlottingMethodEnum.getEnumForListboxStr(nameStr);
    	event.plotMethod = enum;
        
        contents = handles.lineWidthCombo.String;
        contentsDouble = str2double(contents);
        contensInd = get(handles.lineWidthCombo,'Value');
        lineWidth = contentsDouble(contensInd);
        event.colorLineSpec.lineWidth = lineWidth;
        
        integratorObj = getSelectedEventIntegratorObj(handles);
        event.integratorObj = integratorObj;
        
        propagatorObj = getSelectedEventPropagatorObj(handles);
        event.propagatorObj = propagatorObj;
        
        nameStr = handles.propDirCombo.String(handles.propDirCombo.Value);
        [enum,~] = PropagationDirectionEnum.getEnumForListboxStr(nameStr);
        event.propDir = enum;
        
        event.checkForSoITrans = logical(handles.checkSoITransCheckbox.Value);
        
        nameStr = handles.actionExecNodeCombo.String(handles.actionExecNodeCombo.Value);
        [enum,~] = ActionExecNodeEnum.getEnumForListboxStr(nameStr);
    	event.execActionsNode = enum;
        
        event.clearActiveOptVarsCache();
        
        close(handles.lvd_editEventGUI);
    end

% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);

    if(isempty(errMsg))
       uiresume(handles.lvd_editEventGUI);
    else
        msgbox(errMsg,'Errors were found while editing the event.','error');
    end  
    
    
function errMsg = validateInputs(handles)
    errMsg = {};


% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_editEventGUI);


function eventNameText_Callback(hObject, eventdata, handles)
% hObject    handle to eventNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eventNameText as text
%        str2double(get(hObject,'String')) returns contents of eventNameText as a double


% --- Executes during object creation, after setting all properties.
function eventNameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eventNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in actionsListbox.
function actionsListbox_Callback(hObject, eventdata, handles)
% hObject    handle to actionsListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns actionsListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from actionsListbox
    if(strcmpi(get(handles.lvd_editEventGUI,'SelectionType'),'open'))
        event = getappdata(handles.lvd_editEventGUI,'event');
        lv = event.script.lvdData.launchVehicle;
        
        if(not(isempty(event.getActionsListboxStr())))
            selActionInd = get(handles.actionsListbox,'Value');
            action = event.getActionForInd(selActionInd);

            action.event = event;
            action.openEditActionUI(action, lv);
            
            actionsListBoxStr = event.getActionsListboxStr();

            if(not(isempty(actionsListBoxStr)))
                set(handles.actionsListbox,'String',actionsListBoxStr);
            else
                set(handles.actionsListbox,'String','');
                set(handles.actionsListbox,'Value',1);
            end
        end
    end


% --- Executes during object creation, after setting all properties.
function actionsListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to actionsListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addActionButton.
function addActionButton_Callback(hObject, eventdata, handles)
% hObject    handle to addActionButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    event = getappdata(handles.lvd_editEventGUI,'event');
    lv = event.script.lvdData.launchVehicle;
    actionStrs = EventActionEnum.getActionTypeNameStrs();

    [dialogInd,tf] = listdlg('ListString',actionStrs, ...
                             'Name','Select Action', ...
                             'PromptString',{'Select the action you wish to add','to this event:'}, ...
                             'SelectionMode','single', ...
                             'ListSize',[210 300]);
    
    if(tf == 1)
        [m,~] = enumeration('EventActionEnum');
        inds = strcmpi({m.nameStr},actionStrs{dialogInd});
        
        actionEnum = m(inds);
        
        newAction = feval(actionEnum.classNameStr);
        newAction.event = event;
        addActionTf = newAction.openEditActionUI(newAction, lv);
        
        if(addActionTf)
            event.addAction(newAction);
        end
        
        set(handles.actionsListbox,'String',event.getActionsListboxStr());
        
        if(handles.actionsListbox.Value <= 0)
            handles.actionsListbox.Value = 1;
        elseif(handles.actionsListbox.Value > length(handles.actionsListbox.String))
            handles.actionsListbox.Value = length(handles.actionsListbox.String);
        end
    end
    
% --- Executes on button press in removeActionButton.
function removeActionButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeActionButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    event = getappdata(handles.lvd_editEventGUI,'event');

    selActionInd = get(handles.actionsListbox,'Value');
    event.removeActionByInd(selActionInd);
    
    set(handles.actionsListbox,'String',event.getActionsListboxStr());
    
    aListBosStr = get(handles.actionsListbox,'String');
    if(iscell(aListBosStr) && length(aListBosStr)<selActionInd)
        set(handles.actionsListbox,'Value',length(aListBosStr));
    end

% --- Executes on button press in editTermCondParamsButton.
function editTermCondParamsButton_Callback(hObject, eventdata, handles)
% hObject    handle to editTermCondParamsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    event = getappdata(handles.lvd_editEventGUI,'event');
    lvd_editEvtTermCond(event);
    
    termCond = event.termCond;
    set(handles.termCondNameLabel,'String',termCond.getName());

% --- Executes when user attempts to close lvd_editEventGUI.
function lvd_editEventGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to lvd_editEventGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
    delete(hObject);


% --- Executes on selection change in colorSpecCombo.
function colorSpecCombo_Callback(hObject, eventdata, handles)
% hObject    handle to colorSpecCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns colorSpecCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from colorSpecCombo


% --- Executes during object creation, after setting all properties.
function colorSpecCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to colorSpecCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in lineSpecCombo.
function lineSpecCombo_Callback(hObject, eventdata, handles)
% hObject    handle to lineSpecCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lineSpecCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lineSpecCombo


% --- Executes during object creation, after setting all properties.
function lineSpecCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lineSpecCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkSoITransCheckbox.
function checkSoITransCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to checkSoITransCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkSoITransCheckbox


% --- Executes on selection change in integratorCombo.
function integratorCombo_Callback(hObject, eventdata, handles)
% hObject    handle to integratorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns integratorCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from integratorCombo
    contents = cellstr(get(hObject,'String'));
    
    if(get(hObject,'Value') < 1 || get(hObject,'Value') > length(contents))
        nameStr = contents{1};
    else
        nameStr = contents{get(hObject,'Value')};
    end

    [~,m] = IntegratorEnum.getIndOfListboxStr(nameStr);
    handles.integratorDetailLabel.String = m.descStr;

% --- Executes during object creation, after setting all properties.
function integratorCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to integratorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on lvd_editEventGUI or any of its controls.
function lvd_editEventGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_editEventGUI (see GCBO)
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
            close(handles.lvd_editEventGUI);
    end

    
% --------------------------------------------------------------------
function determineFastestIntegratorMenu_Callback(hObject, eventdata, handles)
% hObject    handle to determineFastestIntegratorMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    event = getappdata(handles.lvd_editEventGUI,'event');
    lvdData = event.lvdData;
    script = lvdData.script;
    
    initStateLogEntry = lvdData.stateLog.getFirstStateLogForEvent(event);
    
    simDriver = script.simDriver;
    tStartSimTime = initStateLogEntry.time;
    isSparseOutput = false;
    
    activeNonSeqEvts = script.nonSeqEvts.getNonSeqEventsForScriptEvent(event);
    for(j=1:length(activeNonSeqEvts))
        activeNonSeqEvts(j).initEvent(initStateLogEntry);
    end
    
    oldIntegrator = event.integratorObj;
    
    hWaitBar = waitbar(0, '');
    
    try
        [m,~] = enumeration('IntegratorEnum');
        results = cell(length(m),2);
        for(i=1:length(m))
            newIntegratorEnum = m(i);
            
            if(isvalid(hWaitBar))
                waitbar(((i-1)/length(m)), hWaitBar, sprintf('Running event with integrator "%s"...',newIntegratorEnum.nameStr));
            end
            
            tStartPropTime = tic();
            
            integratorObj = IntegratorEnum.getIntegratorObjFromEnum(newIntegratorEnum);
            event.integratorObj = integratorObj;

            tt = tic;
            event.executeEvent(initStateLogEntry, simDriver, tStartPropTime, tStartSimTime, isSparseOutput, activeNonSeqEvts);
            elapsedTime = toc(tt);

            results(i,:) = {newIntegratorEnum, elapsedTime};
        end      
    catch ME
        event.integratorObj = oldIntegrator;
        throw(ME);
    end
    
    if(isvalid(hWaitBar))
        close(hWaitBar);
    end
    
    msg = {'Results of integrator speed test:', ''};
    for(i=1:size(results,1))
        integrator = results{i,1};
        time = results{i,2};
        
        msg = horzcat(msg, sprintf('%s:     %.3f sec', integrator.nameStr, time)); %#ok<AGROW>
    end
    
    [~,I] = min([results{:,2}]);
    fastestIntegratorEnum = m(I);
    
    msg = horzcat(msg,{'',sprintf('Apply fastest integrator (%s) for this event?',fastestIntegratorEnum.nameStr)});
    
    button = questdlg(msg,'Speed Test Results','Yes','No','Yes');
    
    if(strcmpi(button,'Yes'))
        fastestIntegratorObj = IntegratorEnum.getIntegratorObjFromEnum(fastestIntegratorEnum);
        event.integratorObj = fastestIntegratorObj;
        
        ind = IntegratorEnum.getIndOfListboxStr(fastestIntegratorEnum.nameStr);
        handles.integratorCombo.Value = ind;
        integratorCombo_Callback(handles.integratorCombo, [], handles);
    else
        event.integratorObj = oldIntegrator;
    end

% --------------------------------------------------------------------
function integratorContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to integratorContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- Executes on selection change in lineWidthCombo.
function lineWidthCombo_Callback(hObject, eventdata, handles)
% hObject    handle to lineWidthCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lineWidthCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lineWidthCombo


% --- Executes during object creation, after setting all properties.
function lineWidthCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lineWidthCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --------------------------------------------------------------------
function optimizeInitialStepSizeMenu_Callback(hObject, eventdata, handles)
% hObject    handle to optimizeInitialStepSizeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    event = getappdata(handles.lvd_editEventGUI,'event');
    lvdData = event.lvdData;
    script = lvdData.script;
    
    simDriver = script.simDriver;
    tStartSimTime = 0;
    isSparseOutput = false;
    
    initStateLogEntry = lvdData.stateLog.getFirstStateLogForEvent(event);
    
    activeNonSeqEvts = script.nonSeqEvts.getNonSeqEventsForScriptEvent(event);
    for(j=1:length(activeNonSeqEvts))
        activeNonSeqEvts(j).initEvent(initStateLogEntry);
    end
    
    oldInitStep = event.initialStep;
    
    fun = @(x) optInitStepSizeObjFcn(x, event, initStateLogEntry, simDriver, tStartSimTime, isSparseOutput, activeNonSeqEvts);
    x0 = oldInitStep;
    lb = 0.01;
    ub = 1E10;
%     options = optimoptions(@fmincon, 'Display','iter', 'OptimalityTolerance',1E-2, 'StepTolerance',1E-10, 'PlotFcn',{@optimplotx, @optimplotfval});
    options = optimoptions(@patternsearch, 'Display','iter', 'UseParallel',lvdData.optimizer.usesParallel(), 'PlotFcn',{@psplotbestx, @psplotbestf});
    
%     x = fmincon(fun,x0,[],[],[],[],lb,ub,[],options);
    x = patternsearch(fun,x0,[],[],[],[],lb,ub,[],options);
    msg = sprintf('Results of initial step size tuning: %0.3f sec', x);
    
    msg = horzcat(msg,{'','',sprintf('Apply optimized initial step size to this event?')});
    
    button = questdlg(msg,'Speed Test Results','Yes','No','Yes');
    
    if(strcmpi(button,'Yes'))
        handles.initialStepText.String = fullAccNum2Str(x);
        initialStepText_Callback(handles.initialStepText, [], handles);
    else
        integrator = event.integratorObj;
        propOptions = integrator.getOptions();
        propOptions.setIntegratorStepSize(oldInitStep);
    end
    
function elapsedTime = optInitStepSizeObjFcn(x, event, initStateLogEntry, simDriver, tStartSimTime, isSparseOutput, activeNonSeqEvts)
    integrator = event.integratorObj;
    propOptions = integrator.getOptions();
    propOptions.setIntegratorStepSize(x(1));
    
    tStartPropTime = tic();

    tt = tic;
    event.executeEvent(initStateLogEntry, simDriver, tStartPropTime, tStartSimTime, isSparseOutput, activeNonSeqEvts);
    elapsedTime = toc(tt);
    
    
% --------------------------------------------------------------------
function initialStepSizeContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to initialStepSizeContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in eventTermCondDirCombo.
function eventTermCondDirCombo_Callback(hObject, eventdata, handles)
% hObject    handle to eventTermCondDirCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns eventTermCondDirCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from eventTermCondDirCombo


% --- Executes during object creation, after setting all properties.
function eventTermCondDirCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eventTermCondDirCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in plotMethodCombo.
function plotMethodCombo_Callback(hObject, eventdata, handles)
% hObject    handle to plotMethodCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns plotMethodCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from plotMethodCombo


% --- Executes during object creation, after setting all properties.
function plotMethodCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to plotMethodCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in integratorOptionsButton.
function integratorOptionsButton_Callback(hObject, eventdata, handles)
% hObject    handle to integratorOptionsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    integratorObj = getSelectedEventIntegratorObj(handles);
    
    options = integratorObj.getOptions();
    options.openOptionsDialog();

function integratorObj = getSelectedEventIntegratorObj(handles)
    event = getappdata(handles.lvd_editEventGUI,'event');
    
    contents = cellstr(get(handles.integratorCombo,'String'));
    nameStr = contents{get(handles.integratorCombo,'Value')};
    [~,m] = IntegratorEnum.getIndOfListboxStr(nameStr); 

    switch m
        case IntegratorEnum.ODE113
            integratorObj = event.ode113Integrator;

        case IntegratorEnum.ODE15s
            integratorObj = event.ode15sIntegrator;

        case IntegratorEnum.ODE23
            integratorObj = event.ode23Integrator;

        case IntegratorEnum.ODE23s
            integratorObj = event.ode23sIntegrator;

        case IntegratorEnum.ODE45
            integratorObj = event.ode45Integrator;
            
        case IntegratorEnum.ODE5
            integratorObj = event.ode5Integrator;

        otherwise
            error('Unknown integrator type.');
    end
    
function propagatorObj = getSelectedEventPropagatorObj(handles)
    event = getappdata(handles.lvd_editEventGUI,'event');
    
    contents = cellstr(get(handles.propagatorCombo,'String'));
    nameStr = contents{get(handles.propagatorCombo,'Value')};
    [~,m] = PropagatorEnum.getIndForName(nameStr); 

    switch m
        case PropagatorEnum.ForceModel
            propagatorObj = event.forceModelPropagator;
            
        case PropagatorEnum.TwoBody
            propagatorObj = event.twoBodyPropagator;

        otherwise
            error('Unknown propagator type.');
    end
    
% --- Executes on selection change in propagatorCombo.
function propagatorCombo_Callback(hObject, eventdata, handles)
% hObject    handle to propagatorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns propagatorCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from propagatorCombo
    contents = cellstr(get(hObject,'String'));
    
    if(get(hObject,'Value') < 1 || get(hObject,'Value') > length(contents))
        nameStr = contents{1};
    else
        nameStr = contents{get(hObject,'Value')};
    end

    [~,m] = PropagatorEnum.getIndForName(nameStr);
    handles.propagatorDetailLabel.String = m.desc;

% --- Executes during object creation, after setting all properties.
function propagatorCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to propagatorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in propagatorOptionsButton.
function propagatorOptionsButton_Callback(hObject, eventdata, handles)
% hObject    handle to propagatorOptionsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    propagatorObj = getSelectedEventPropagatorObj(handles);

    propagatorObj.openOptionsDialog();


% --- Executes on selection change in propDirCombo.
function propDirCombo_Callback(hObject, eventdata, handles)
% hObject    handle to propDirCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns propDirCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from propDirCombo


% --- Executes during object creation, after setting all properties.
function propDirCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to propDirCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in actionExecNodeCombo.
function actionExecNodeCombo_Callback(hObject, eventdata, handles)
% hObject    handle to actionExecNodeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns actionExecNodeCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from actionExecNodeCombo


% --- Executes during object creation, after setting all properties.
function actionExecNodeCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to actionExecNodeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
