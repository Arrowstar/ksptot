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

% Last Modified by GUIDE v2.5 24-Sep-2018 17:46:50

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

    maData = varargin{1};
    setappdata(hObject,'maData',maData);

    celBodyData = varargin{2};
    setappdata(hObject,'celBodyData',celBodyData);
    
    setappdata(hObject,'hMaMainGUI',varargin{3});

    if(~isfield(maData,'lvdData') || isempty(maData.lvdData))
        lvdData = LvdData.getDefaultLvdData(celBodyData);
        maData.lvdData = lvdData;
        setappdata(handles.ma_LvdMainGUI,'maData',maData);
    end

    output_text_max_line_length = length(getMA_HR());
    setappdata(hObject,'output_text_max_line_length',output_text_max_line_length);
    writeOutput = @(str,type) writeToMAOutput(handles.outputText, str, type, output_text_max_line_length);
    setappdata(hObject,'write_to_output_func',writeOutput);

    initializeOutputWindowText(handles, handles.outputText);
    view(handles.dispAxes,3);
    
    lvdData.script.executeScript();
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
    
    t = tic;
    lvdData.script.executeScript();
    execTime = toc(t);
    
    handles.scriptWorkingLbl.Visible = 'off';
    
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


% --- Executes on selection change in scriptListbox.
function scriptListbox_Callback(hObject, eventdata, handles)
% hObject    handle to scriptListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns scriptListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from scriptListbox
    if(strcmpi(get(handles.ma_LvdMainGUI,'SelectionType'),'open'))
        eventNum = get(hObject,'Value');
        maData = getappdata(handles.ma_LvdMainGUI,'maData');
        lvdData = maData.lvdData;
        
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
    maData = getappdata(handles.ma_LvdMainGUI,'maData');
    lvdData = maData.lvdData;

    selEvtNum = get(handles.scriptListbox,'Value');
    event = LaunchVehicleEvent.getDefaultEvent(lvdData.script);
    lvdData.script.addEventAtInd(event,selEvtNum);
    lvd_editEventGUI(event);
    
    runScript(handles, lvdData);
    lvd_processData(handles);

% --- Executes on button press in moveEventDown.
function moveEventDown_Callback(hObject, eventdata, handles)
% hObject    handle to moveEventDown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_LvdMainGUI,'maData');
    
    lvdData = maData.lvdData;
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
    maData = getappdata(handles.ma_LvdMainGUI,'maData');
    
    lvdData = maData.lvdData;
    eventNum = get(handles.scriptListbox,'Value');
    lvdData.script.removeEventFromIndex(eventNum);
    
    if(eventNum > length(lvdData.script.evts))
        set(handles.scriptListbox,'Value',length(lvdData.script.evts));
    end
    
    runScript(handles, lvdData);
    lvd_processData(handles);

% --- Executes on button press in moveEventUp.
function moveEventUp_Callback(hObject, eventdata, handles)
% hObject    handle to moveEventUp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_LvdMainGUI,'maData');
    
    lvdData = maData.lvdData;
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
    maData = getappdata(handles.ma_LvdMainGUI,'maData');
    hMaMainGUI = getappdata(handles.ma_LvdMainGUI,'hMaMainGUI');
    writeOutput = getappdata(handles.ma_LvdMainGUI,'write_to_output_func');
    
    lvdData = maData.lvdData;
    lvdData.optimizer.optimize(hMaMainGUI, writeOutput);
    
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
    maData = getappdata(handles.ma_LvdMainGUI,'maData');
    lvdData = maData.lvdData;
    
    lvd_editLaunchVehicle(lvdData);
    
%     runScript(handles, lvdData);
%     lvd_processData(handles);


% --------------------------------------------------------------------
function editObjFunctionMenu_Callback(hObject, eventdata, handles)
% hObject    handle to editObjFunctionMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_LvdMainGUI,'maData');
    lvdData = maData.lvdData;
    lvd_EditObjectiveFunctionGUI(lvdData);

% --------------------------------------------------------------------
function editConstraintsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to editConstraintsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_LvdMainGUI,'maData');
    lvdData = maData.lvdData;
    hMaMainGUI = getappdata(handles.ma_LvdMainGUI,'hMaMainGUI');
    lvd_EditConstraintsGUI(maData, lvdData, hMaMainGUI);
    
% --------------------------------------------------------------------
function editInitialStateMenu_Callback(hObject, eventdata, handles)
% hObject    handle to editInitialStateMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_LvdMainGUI,'maData');
    lvdData = maData.lvdData;
    hMaMainGUI = getappdata(handles.ma_LvdMainGUI,'hMaMainGUI');
    lvd_EditInitialStateGUI(maData, lvdData, hMaMainGUI);
    
%     runScript(handles, lvdData);
%     lvd_processData(handles);

% --------------------------------------------------------------------
function viewStateAfterSelectedEventMenu_Callback(hObject, eventdata, handles)
% hObject    handle to viewStateAfterSelectedEventMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    hMaMainGUI = getappdata(handles.ma_LvdMainGUI,'hMaMainGUI');
    maData = getappdata(handles.ma_LvdMainGUI,'maData');
    lvdData = maData.lvdData;
    
    eventNum = handles.scriptListbox.Value;
    stateLog = lvdData.stateLog.getMAFormattedStateLogMatrix();
    
    state = stateLog(stateLog(:,13)==eventNum,:);
    state = state(end,:);

    viewSpacecraftStatePopupGUI(hMaMainGUI, state, eventNum);

% --------------------------------------------------------------------
function copyUtAtStartOfSelEventMenu_Callback(hObject, eventdata, handles)
% hObject    handle to copyUtAtStartOfSelEventMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_LvdMainGUI,'maData');
    lvdData = maData.lvdData;
    
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
    maData = getappdata(handles.ma_LvdMainGUI,'maData');
    lvdData = maData.lvdData;
    
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
    maData = getappdata(handles.ma_LvdMainGUI,'maData');
    lvdData = maData.lvdData;
    
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
    maData = getappdata(handles.ma_LvdMainGUI,'maData');
    celBodyData = getappdata(handles.ma_LvdMainGUI,'celBodyData');
    lvdData = maData.lvdData;
    
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
