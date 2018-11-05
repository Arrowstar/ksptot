function varargout = lvd_editEvtTermCond(varargin)
% LVD_EDITEVTTERMCOND MATLAB code for lvd_editEvtTermCond.fig
%      LVD_EDITEVTTERMCOND, by itself, creates a new LVD_EDITEVTTERMCOND or raises the existing
%      singleton*.
%
%      H = LVD_EDITEVTTERMCOND returns the handle to a new LVD_EDITEVTTERMCOND or the handle to
%      the existing singleton*.
%
%      LVD_EDITEVTTERMCOND('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITEVTTERMCOND.M with the given input arguments.
%
%      LVD_EDITEVTTERMCOND('Property','Value',...) creates a new LVD_EDITEVTTERMCOND or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_editEvtTermCond_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_editEvtTermCond_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_editEvtTermCond

% Last Modified by GUIDE v2.5 17-Sep-2018 17:18:24

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_editEvtTermCond_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_editEvtTermCond_OutputFcn, ...
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


% --- Executes just before lvd_editEvtTermCond is made visible.
function lvd_editEvtTermCond_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_editEvtTermCond (see VARARGIN)

    % Choose default command line output for lvd_editEvtTermCond
    handles.output = hObject;

    event = varargin{1};
    setappdata(hObject,'event',event);
    
    populateGUI(handles, event);

    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_editEvtTermCond wait for user response (see UIRESUME)
    uiwait(handles.lvd_editEvtTermCond);


function populateGUI(handles, event)
    termCondStrs = TerminationConditionEnum.getTermCondTypeNameStrs();
    set(handles.termCondTypeCombo,'String',termCondStrs);
    
    termCond = event.termCond;
    ind = TerminationConditionEnum.getIndOfListboxStrsForTermCond(termCond);
    set(handles.termCondTypeCombo,'Value',ind);
    
    params = termCond.getTermCondUiStruct();
    
    value = params.value;
    if(isempty(value))
        value = 0.0;
    end
    
    set(handles.numParamText,'String',fullAccNum2Str(value));
    
    lv = event.script.lvdData.launchVehicle;
    
    stagesListStr = lv.getStagesListBoxStr();
    set(handles.refStageCombo,'String',stagesListStr);

    tanksListStr = lv.getTanksListBoxStr();
    set(handles.refTankCombo,'String',tanksListStr);
    
    enginesListStr = lv.getEnginesListBoxStr();
    set(handles.refEngineCombo,'String',enginesListStr);
    
    set(handles.numParamLabel,'String',params.paramName);
    set(handles.numParamUnitLabel,'String',params.paramUnit);
    
    set(handles.numParamText,'Enable',params.useParam);
    set(handles.optParamCheckbox,'Enable',params.useParam);
    set(handles.paramLbText,'Enable',params.useParam);
    set(handles.paramUbText,'Enable',params.useParam);
    
    set(handles.refStageCombo,'Enable',params.useStages);
    set(handles.refTankCombo,'Enable',params.useTanks);
    set(handles.refEngineCombo,'Enable',params.useEngines);
    
    if(not(isempty(params.refStage)))
        set(handles.refStageCombo,'Value',lv.getListBoxIndForStage(params.refStage));
    end
    
    if(not(isempty(params.refTank)))
        set(handles.refTankCombo,'Value',lv.getListBoxIndForTank(params.refTank));
    end
    
    if(not(isempty(params.refEngine)))
        set(handles.refEngineCombo,'Value',lv.getListBoxIndForEngine(params.refEngine));
    end
    
    optVar = termCond.getExistingOptVar();
    if(isempty(optVar))
        useTf = false([1,1]);
        lb = zeros(size(useTf));
        ub = zeros(size(useTf));
    else
        useTf = optVar.getUseTfForVariable();
        optVar.setUseTfForVariable(true(size(useTf)));
        [lb, ub] = optVar.getBndsForVariable();
        optVar.setUseTfForVariable(useTf);
    end
    
    if(strcmpi(params.paramUnit,'deg'))
        lb = rad2deg(lb);
        ub = rad2deg(ub);
    elseif(strcmpi(params.paramUnit,'%'))
        lb = lb*100;
        ub = ub*100;
    end
    
    lbStr = fullAccNum2Str(lb);
    ubStr = fullAccNum2Str(ub);
    
    set(handles.optParamCheckbox,'Value',useTf);
    set(handles.paramLbText,'String',lbStr);
    set(handles.paramUbText,'String',ubStr);
    
    optParamCheckbox_Callback(handles.optParamCheckbox,[],handles);
    
    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_editEvtTermCond_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = [];
    else        
        event = getappdata(hObject,'event');
        lv = event.script.lvdData.launchVehicle;
        
        paramValue = str2double(get(handles.numParamText,'String'));
        
        termCond = event.termCond;
        params = getParamsForSelectedTermCondType(handles);
       
        optVar = termCond.getExistingOptVar();
        if(not(isempty(optVar)))
            lv.lvdData.optimizer.vars.removeVariable(optVar);%need to remove existing var if it exists
        end
        
        if(strcmpi(params.paramUnit,'deg'))
            paramValue = deg2rad(paramValue);
        elseif(strcmpi(params.paramUnit,'%'))
            paramValue = paramValue/100;
        end
        
        [~,stages] = lv.getStagesListBoxStr();
        [~,tanks] = lv.getTanksListBoxStr();
        [~,engines] = lv.getEnginesListBoxStr();
        
        if(not(isempty(stages)))
            stage = stages(get(handles.refStageCombo,'Value'));
        else
            stage = stages;
        end
        
        if(not(isempty(tanks)))
            tank = tanks(get(handles.refTankCombo,'Value'));
        else
            tank = tanks;
        end
        
        if(not(isempty(engines)))
            engine = engines(get(handles.refEngineCombo,'Value'));
        else
            engine = engines;
        end
        
        [m,~] = enumeration('TerminationConditionEnum');
        contents = cellstr(get(handles.termCondTypeCombo,'String'));
        termCondType = contents{get(handles.termCondTypeCombo,'Value')};
        ind = strcmpi({m.nameStr},termCondType);
        termCond = feval(sprintf('%s.getTermCondForParams',m(ind).classNameStr), paramValue, stage, tank, engine);
                
        lb = str2double(get(handles.paramLbText,'String'));
        ub = str2double(get(handles.paramUbText,'String'));
        
        if(strcmpi(params.paramUnit,'deg'))
            lb = deg2rad(lb);
            ub = deg2rad(ub);
        elseif(strcmpi(params.paramUnit,'%'))
            lb = lb/100;
            ub = ub/100;
        end
        
        optVar = termCond.getNewOptVar();
        
        if(not(isempty(optVar)))
            optVar.setUseTfForVariable(true); 
            optVar.setBndsForVariable(lb, ub);

            useTf = logical(get(handles.optParamCheckbox,'Value'));
            optVar.setUseTfForVariable(useTf);       

            lv.lvdData.optimizer.vars.addVariable(optVar);
            termCond.optVar = optVar;
            optVar.varObj = termCond;
        end
        
        event.termCond = termCond;
        
        close(handles.lvd_editEvtTermCond);
    end

    
function errMsg = validateInputs(handles)
    errMsg = {};
    
    value = str2double(get(handles.numParamText,'String'));
    enteredStr = get(handles.numParamText,'String');
    numberName = get(handles.numParamLabel,'String');
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    lwrBndValue = str2double(get(handles.paramLbText,'String'));
    enteredStr = get(handles.paramLbText,'String');
    numberName = [get(handles.numParamLabel,'String'), ' Lower Bound'];
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(lwrBndValue, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    uprBndValue = str2double(get(handles.paramUbText,'String'));
    enteredStr = get(handles.paramUbText,'String');
    numberName = [get(handles.numParamLabel,'String'), ' Upper Bound'];
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(uprBndValue, numberName, lb, ub, isInt, errMsg, enteredStr);

    if(isempty(errMsg))
        uprBndValue = str2double(get(handles.paramUbText,'String'));
        enteredStr = get(handles.paramUbText,'String');
        numberName = [get(handles.numParamLabel,'String'), ' Upper Bound'];
        lb = lwrBndValue;
        ub = Inf;
        isInt = false;
        errMsg = validateNumber(uprBndValue, numberName, lb, ub, isInt, errMsg, enteredStr);
    end
    
    
% --- Executes on selection change in termCondTypeCombo.
function termCondTypeCombo_Callback(hObject, eventdata, handles)
% hObject    handle to termCondTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns termCondTypeCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from termCondTypeCombo
    params = getParamsForSelectedTermCondType(handles);
    
    set(handles.numParamLabel,'String',params.paramName);
    set(handles.numParamUnitLabel,'String',params.paramUnit);
    
    set(handles.numParamText,'Enable',params.useParam);
    set(handles.optParamCheckbox,'Enable',params.useParam);
    set(handles.paramLbText,'Enable',params.useParam);
    set(handles.paramUbText,'Enable',params.useParam);
    
    if(params.useParam == false)
        set(handles.optParamCheckbox,'Value',0);
    end
    
    set(handles.refStageCombo,'Enable',params.useStages);
    set(handles.refTankCombo,'Enable',params.useTanks);
    set(handles.refEngineCombo,'Enable',params.useEngines);

    
function params = getParamsForSelectedTermCondType(handles)
	event = getappdata(handles.lvd_editEvtTermCond,'event');
    lv = event.script.lvdData.launchVehicle;
        
    [~,stages] = lv.getStagesListBoxStr();
    [~,tanks] = lv.getTanksListBoxStr();
    [~,engines] = lv.getEnginesListBoxStr();

    stage = stages(1);
    tank = tanks(1);
    engine = engines(1);

    [m,~] = enumeration('TerminationConditionEnum');
    contents = cellstr(get(handles.termCondTypeCombo,'String'));
    termCondType = contents{get(handles.termCondTypeCombo,'Value')};
    ind = strcmpi({m.nameStr},termCondType);
    termCond = feval(sprintf('%s.getTermCondForParams',m(ind).classNameStr), 0, stage, tank, engine);
    
    params = termCond.getTermCondUiStruct();
    
% --- Executes during object creation, after setting all properties.
function termCondTypeCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to termCondTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function numParamText_Callback(hObject, eventdata, handles)
% hObject    handle to numParamText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numParamText as text
%        str2double(get(hObject,'String')) returns contents of numParamText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function numParamText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numParamText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in refStageCombo.
function refStageCombo_Callback(hObject, eventdata, handles)
% hObject    handle to refStageCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns refStageCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from refStageCombo


% --- Executes during object creation, after setting all properties.
function refStageCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to refStageCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in refTankCombo.
function refTankCombo_Callback(hObject, eventdata, handles)
% hObject    handle to refTankCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns refTankCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from refTankCombo


% --- Executes during object creation, after setting all properties.
function refTankCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to refTankCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in refEngineCombo.
function refEngineCombo_Callback(hObject, eventdata, handles)
% hObject    handle to refEngineCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns refEngineCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from refEngineCombo


% --- Executes during object creation, after setting all properties.
function refEngineCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to refEngineCombo (see GCBO)
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
       uiresume(handles.lvd_editEvtTermCond);
    else
        msgbox(errMsg,'Errors were found while editing the termination conditions.','error');
    end  

    

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_editEvtTermCond);


% --- Executes on button press in optParamCheckbox.
function optParamCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to optParamCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of optParamCheckbox
    if(get(hObject,'Value') == 1)
        set(handles.paramLbText,'Enable','on');
        set(handles.paramUbText,'Enable','on');
    else
        set(handles.paramLbText,'Enable','off');
        set(handles.paramUbText,'Enable','off');        
    end


function paramLbText_Callback(hObject, eventdata, handles)
% hObject    handle to paramLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of paramLbText as text
%        str2double(get(hObject,'String')) returns contents of paramLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function paramLbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to paramLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function paramUbText_Callback(hObject, eventdata, handles)
% hObject    handle to paramUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of paramUbText as text
%        str2double(get(hObject,'String')) returns contents of paramUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function paramUbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to paramUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
