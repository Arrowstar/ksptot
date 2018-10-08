function varargout = ma_MissionOptimizerGUI(varargin)
% MA_MISSIONOPTIMIZERGUI MATLAB code for ma_missionoptimizergui.fig
%      MA_MISSIONOPTIMIZERGUI, by itself, creates a new MA_MISSIONOPTIMIZERGUI or raises the existing
%      singleton*.
%
%      H = MA_MISSIONOPTIMIZERGUI returns the handle to a new MA_MISSIONOPTIMIZERGUI or the handle to
%      the existing singleton*.
%
%      MA_MISSIONOPTIMIZERGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_MISSIONOPTIMIZERGUI.M with the given input arguments.
%
%      MA_MISSIONOPTIMIZERGUI('Property','Value',...) creates a new MA_MISSIONOPTIMIZERGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_MissionOptimizerGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_MissionOptimizerGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_missionoptimizergui

% Last Modified by GUIDE v2.5 20-May-2016 22:12:18

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_MissionOptimizerGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_MissionOptimizerGUI_OutputFcn, ...
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


% --- Executes just before ma_missionoptimizergui is made visible.
function ma_MissionOptimizerGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_missionoptimizergui (see VARARGIN)

% Choose default command line output for ma_missionoptimizergui
    handles.output = hObject;
    handles.exists = true;

    % Update handles structure
    handles.ma_MainGUI = varargin{1};
    guidata(hObject, handles);

    maData = getappdata(handles.ma_MainGUI,'ma_data');

    excludeList = {'Distance Traveled','Distance to Ref. Station','Dry Mass','Eclipse','Elevation Angle w.r.t. Ref. Station', ...
                   'Line of Sight to Ref. Spacecraft','Line of Sight to Ref. Station'};
    taskList = ma_getGraphAnalysisTaskList(excludeList);
    set(handles.availConstListbox, 'String', taskList);

    initUserData(handles, maData);

    setOptVarListbox(handles.optVarListbox, maData);
    optVarListbox_Callback(handles.optVarListbox, [], handles);

    setOptVarListbox(handles.eventObjFuncCombo, maData);
    populateBodiesCombo(getappdata(handles.ma_MainGUI,'celBodyData'), handles.bodyObjFuncCombo);
    bodyObjFuncCombo_Callback(handles.objFuncCombo, [], handles);

    populateGUIFromOptSettings(handles, maData);
    objFuncCombo_Callback(handles.objFuncCombo, [], handles);

    % UIWAIT makes ma_missionoptimizergui wait for user response (see UIRESUME)
    uiwait(handles.ma_MissionOptimizerGUI);


function initUserData(handles, maData)
    set(handles.optVarListbox,'UserData',zeros(length(maData.script),5));
    set(handles.actConstsListbox,'UserData',{});


function setOptVarListbox(hListbox, maData)
    script = maData.script;
    
    i = 1;
    listboxStr = {};
    for(eventArr = script)
        event = eventArr{1};
        listboxStr{end+1} = ['Event ', num2str(i), ': ', event.name]; %#ok<AGROW>
        i = i+1;
    end
    
    set(hListbox,'String',listboxStr);
    
    
function populateGUIFromOptSettings(handles, maData)
    script = maData.script;
    
    if(isfield(maData.optimizer,'objective') && ~isempty(maData.optimizer.objective))
        value = findValueFromComboBox(maData.optimizer.objective{1}, handles.objFuncCombo);
        if(value <= length(get(handles.objFuncCombo,'String')))
            set(handles.objFuncCombo,'value',value);
        else
            set(handles.objFuncCombo,'value',length(get(handles.objFuncCombo,'String')));
        end
        
        eventID = maData.optimizer.objective{5};
        [~, eventNum] = getEventByID(eventID, script);
        if(eventNum <= length(get(handles.eventObjFuncCombo,'String')))
            [~, eventNum] = getEventByID(eventID, script);
            if(eventNum >= 1)
                set(handles.eventObjFuncCombo,'value',eventNum);
            else
                set(handles.eventObjFuncCombo,'value',length(get(handles.eventObjFuncCombo,'String')));
            end
        else
            set(handles.eventObjFuncCombo,'value',length(get(handles.eventObjFuncCombo,'String')));
        end
        
        if(maData.optimizer.objective{4} <= length(get(handles.bodyObjFuncCombo,'String')))
            set(handles.bodyObjFuncCombo,'value',maData.optimizer.objective{4});
        else
            set(handles.bodyObjFuncCombo,'value',length(get(handles.bodyObjFuncCombo,'String')));
        end
    end
    
    if(~isempty(maData.optimizer.constraints))
        constDetails = maData.optimizer.constraints{1};
        constDetailsToDelete = [];
        for(i=1:size(constDetails,1))
            try
                row = constDetails(i,:);
                details = row{5};

                eventID = details(7);
                [event, eventNum] = getEventByID(eventID, script);
                row{1} = ma_getConstraintStr(row{3}, eventNum);
                constDetails(i,:) = row;
                if(isempty(event) || eventNum<1 || ~isstruct(event) || ~isfield(event,'id') || event.id ~= eventID)
                    constDetailsToDelete(end+1) = i; %constraint no longer applicable, delete
                end

                otherSCID = details(8);
                oSCInfo = getOtherSCInfoByID(maData, otherSCID);
                if(isempty(oSCInfo) && otherSCID >= 0)
                    constDetailsToDelete(end+1) = i;
                end
            catch
                constDetailsToDelete(end+1) = i;
                continue;
            end
        end
        
        for(i=length(constDetailsToDelete):-1:1)
            idToDelete = constDetailsToDelete(i);
            constDetails(idToDelete,:) = [];
        end
        
        preSize = size(constDetails);
        constDetails(all(cellfun(@isempty,constDetails),2),:) = [];
        postSize = size(constDetails);
        
        if(~all(preSize==postSize))
            set(handles.actConstsListbox,'UserData',constDetails);
            updateActConstListBox(handles);
        end
        
        set(handles.actConstsListbox,'UserData',constDetails);
        updateActConstListBox(handles);
    end
    
    
% --- Outputs from this function are returned to the command line.
function varargout = ma_MissionOptimizerGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
% varargout{1} = handles.output;


% --- Executes on selection change in objFuncCombo.
function objFuncCombo_Callback(hObject, eventdata, handles)
% hObject    handle to objFuncCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns objFuncCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from objFuncCombo
    contents = cellstr(get(hObject,'String'));
    selected = deblank(contents{get(hObject,'Value')});
    
    switch selected
        case 'Minimize Distance to Body'
            set(handles.eventObjFuncCombo,'Enable','on');
            set(handles.bodyObjFuncCombo,'Enable','on');
            
        case 'Maximize Spacecraft Mass'
            set(handles.eventObjFuncCombo,'Enable','on');
            set(handles.bodyObjFuncCombo,'Enable','off');
            
        case 'Minimize Inclination'
            set(handles.eventObjFuncCombo,'Enable','on');
            set(handles.bodyObjFuncCombo,'Enable','off');
            
        case 'Minimize Eccentricity'
            set(handles.eventObjFuncCombo,'Enable','on');
            set(handles.bodyObjFuncCombo,'Enable','off');
            
        case 'Maximize Inclination'
            set(handles.eventObjFuncCombo,'Enable','on');
            set(handles.bodyObjFuncCombo,'Enable','off');
            
        case 'Maximize Eccentricity'
            set(handles.eventObjFuncCombo,'Enable','on');
            set(handles.bodyObjFuncCombo,'Enable','off');
            
        case 'Minimize Mission Duration'
            set(handles.eventObjFuncCombo,'Enable','off');
            set(handles.bodyObjFuncCombo,'Enable','off');
            
        case 'No Optimization (Satisfy Constraints Only)'
            set(handles.eventObjFuncCombo,'Enable','off');
            set(handles.bodyObjFuncCombo,'Enable','off');
    end
    

% --- Executes during object creation, after setting all properties.
function objFuncCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to objFuncCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in eventObjFuncCombo.
function eventObjFuncCombo_Callback(hObject, eventdata, handles)
% hObject    handle to eventObjFuncCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns eventObjFuncCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from eventObjFuncCombo


% --- Executes during object creation, after setting all properties.
function eventObjFuncCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eventObjFuncCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in optVarListbox.
function optVarListbox_Callback(hObject, eventdata, handles)
% hObject    handle to optVarListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns optVarListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from optVarListbox
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    
    eventNum = get(hObject,'Value');
    event = maData.script{eventNum};
    
    updateEventInfo(handles.varEventInfoLabel, event, celBodyData);
%     setOptFlagLbUb(handles, eventNum);
    
    
function setOptFlagLbUb(handles, eventNum)
    maData = getappdata(handles.ma_MainGUI,'ma_data');

    userData = get(handles.optVarListbox,'UserData');
    if(eventNum > size(userData,1))
        userData = [userData; zeros(eventNum-size(userData,1),5)];
    end
    eventID = ma_GetEventIDByEventNum(eventNum, maData.script);
    event = getEventByID(eventID, maData.script);
    
    blacklist = false;
    if(strcmpi(event.type,'Mass_Dump'))
        blacklist = true;
    elseif(strcmpi(event.type,'Set_State'))
        blacklist = true;
    elseif(strcmpi(event.type,'Coast'))
        bool1 = strcmpi(event.coastType,'goto_ut');
        bool2 = strcmpi(event.coastType,'goto_dt');
        bool3 = strcmpi(event.coastType,'goto_tru');
        if(~(bool1 || bool2 || bool3))
            blacklist = true;
        end
    elseif(strcmpi(event.type,'DV_Maneuver'))
        bool1 = strcmpi(event.maneuverType,'dv_inertial');
        bool2 = strcmpi(event.maneuverType,'dv_orbit');
        if(~(bool1 || bool2))
            blacklist = true;
        end
    end
    
    if(blacklist)
        set(handles.varOptEventCheckbox,'Enable','off', 'value',0);
        set(handles.lbVarText,'Enable','off');
        set(handles.ubVarText,'Enable','off');
    else
        set(handles.lbVarText,'Enable','on');
        set(handles.ubVarText,'Enable','on');        
        set(handles.varOptEventCheckbox,'Enable','on'); 
        
        row = userData(eventNum,:);
        set(handles.varOptEventCheckbox, 'value', row(1));
        set(handles.lbVarText, 'String', num2str(row(2)));
        set(handles.ubVarText, 'String', num2str(row(3)));
    end
    
    
function updateEventInfo(hVarEventInfoLabel, event, celBodyData)
    name = event.name;
    type = event.type;
    
    optStr = {};
    if(isfield(event,'vars'))
        vars = event.vars;
        for(i=1:size(vars,2))
            if(vars(1,i) == 1)
                optStr{i} = '(Opt)';
            else
                optStr{i} = '';
            end
        end
    end
    
    if(length(name)>13)
        name = [name(1:10),'...'];
    end
    if(length(type)>13)
        type = [type(1:10),'...'];
    end
    
    eventInfoStr = {};
    eventInfoStr{end+1} = ['Name    = ', name];
    eventInfoStr{end+1} = ['Type    = ', type];
    
    subtype = [];
    param1Str = 'No Parameters';
    param2Str = '';
    param3Str = '';
    switch event.type
        case 'Set_State'
            subtype = 'None';
            
        case 'Coast'
            subtype = event.coastType;
            
            switch subtype
                case 'goto_ut'
                    param1Str = ['UT = ', num2str(event.coastToValue),' sec ', optStr{1}];
                    
                    param2Str = ['Num. of Revs = ', num2str(event.revs)];
                    
                    if(~isempty(event.refBody))
                        bodyInfo = getBodyInfoByNumber(event.refBody.id, celBodyData);
                        param3Str = ['RefBody = ', bodyInfo.name];
                    else
                        param3Str = ['RefBody = None'];
                    end
                    
                case 'goto_dt'
                    param1Str = ['dT = ', num2str(event.coastToValue),' sec ', optStr{1}];
                    
                    param2Str = ['Num. of Revs = ', num2str(event.revs)];
                    
                    bodyInfo = event.refBody;
                    if(~isempty(bodyInfo))
                        param3Str = ['RefBody = ', bodyInfo.name];
                    else
                        param3Str = ['RefBody = None'];
                    end
                    
                case 'goto_tru'
                    param1Str = ['Tru Anom = ', num2str(rad2deg(event.coastToValue)),' deg ', optStr{1}];
                    
                    param2Str = ['Num. of Revs = ', num2str(event.revs)];
                    
                    bodyInfo = event.refBody;
                    if(~isempty(bodyInfo))
                        param3Str = ['RefBody = ', bodyInfo.name];
                    else
                        param3Str = ['RefBody = None'];
                    end
                    
                otherwise
                    param1Str = ['Num. of Revs = ', num2str(event.revs)];
                    
                    bodyInfo = event.refBody;
                    if(~isempty(bodyInfo))
                        param2Str = ['RefBody = ', bodyInfo.name];
                    else
                        param2Str = ['RefBody = None'];
                    end
            end
            
        case 'DV_Maneuver'
            subtype = event.maneuverType;
            
            switch event.maneuverType
                case 'dv_inertial'
                    param1Str = ['dVx = ', num2str(event.maneuverValue(1)*1000), ' m/s ', optStr{1}];
                    param2Str = ['dVy = ', num2str(event.maneuverValue(2)*1000), ' m/s ', optStr{2}];
                    param3Str = ['dVz = ', num2str(event.maneuverValue(3)*1000), ' m/s ', optStr{3}];
                case 'dv_orbit'
                    param1Str = ['dVp = ', num2str(event.maneuverValue(1)*1000), ' m/s ', optStr{1}];
                    param2Str = ['dVn = ', num2str(event.maneuverValue(2)*1000), ' m/s ', optStr{2}];
                    param3Str = ['dVr = ', num2str(event.maneuverValue(3)*1000), ' m/s ', optStr{3}];
                case 'finite_inertial'
                    param1Str = ['dVx = ', num2str(event.maneuverValue(1)*1000), ' m/s ', optStr{1}];
                    param2Str = ['dVy = ', num2str(event.maneuverValue(2)*1000), ' m/s ', optStr{2}];
                    param3Str = ['dVz = ', num2str(event.maneuverValue(3)*1000), ' m/s ', optStr{3}];
                case 'finite_steered'
                    param1Str = ['dVp = ', num2str(event.maneuverValue(1)*1000), ' m/s ', optStr{1}];
                    param2Str = ['dVn = ', num2str(event.maneuverValue(2)*1000), ' m/s ', optStr{2}];
                    param3Str = ['dVr = ', num2str(event.maneuverValue(3)*1000), ' m/s ', optStr{3}];
                case 'dv_inertial_spherical'
                    param1Str = ['Az. = ', num2str(rad2deg(event.maneuverValue(1))), ' deg ', optStr{1}];
                    param2Str = ['El. = ', num2str(rad2deg(event.maneuverValue(2))), ' deg ', optStr{2}];
                    param3Str = ['Mag. = ', num2str(event.maneuverValue(3)*1000), ' m/s ', optStr{3}];
                case 'dv_orbit_spherical'
                    param1Str = ['Az. = ', num2str(rad2deg(event.maneuverValue(1))), ' deg ', optStr{1}];
                    param2Str = ['El. = ', num2str(rad2deg(event.maneuverValue(2))), ' deg ', optStr{2}];
                    param3Str = ['Mag. = ', num2str(event.maneuverValue(3)*1000), ' m/s ', optStr{3}];
                case 'finite_inertial_spherical'
                    param1Str = ['Az. = ', num2str(rad2deg(event.maneuverValue(1))), ' deg ', optStr{1}];
                    param2Str = ['El. = ', num2str(rad2deg(event.maneuverValue(2))), ' deg ', optStr{2}];
                    param3Str = ['Mag. = ', num2str(event.maneuverValue(3)*1000), ' m/s ', optStr{3}];
                case 'finite_steered_spherical'
                    param1Str = ['Az. = ', num2str(rad2deg(event.maneuverValue(1))), ' deg ', optStr{1}];
                    param2Str = ['El. = ', num2str(rad2deg(event.maneuverValue(2))), ' deg ', optStr{2}];
                    param3Str = ['Mag. = ', num2str(event.maneuverValue(3)*1000), ' m/s ', optStr{3}];
            end
            
        case 'Mass_Dump'
            subtype = event.subType;
    end
    
    if(length(subtype)>13)
        subtype = [subtype(1:10),'...'];
    end
    eventInfoStr{end+1} = ['Subtype = ', subtype];
    eventInfoStr{end+1} = [' '];
    eventInfoStr{end+1} = param1Str;
    eventInfoStr{end+1} = param2Str;
    eventInfoStr{end+1} = param3Str;
    
    set(hVarEventInfoLabel, 'String',eventInfoStr);


% --- Executes during object creation, after setting all properties.
function optVarListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to optVarListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in varOptEventCheckbox.
function varOptEventCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to varOptEventCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of varOptEventCheckbox
    updateVarListbox(handles);
    

function updateVarListbox(handles)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    varUserData = get(handles.optVarListbox,'UserData');
    eventNum = get(handles.optVarListbox,'Value');
    
    lb = str2double(get(handles.lbVarText,'String'));
    if(isnan(lb))
        lb = 0;
    end
    ub = str2double(get(handles.ubVarText,'String'));
    if(isnan(ub))
        ub = 0;
    end
    
    eventID = ma_GetEventIDByEventNum(eventNum, maData.script);
    varUserData(eventNum, :) = [get(handles.varOptEventCheckbox,'Value'), lb, ub, eventNum, eventID];
    set(handles.optVarListbox,'UserData',varUserData);
        
    
% --- Executes on button press in optimizeMissionButton.
function optimizeMissionButton_Callback(hObject, eventdata, handles)
% hObject    handle to optimizeMissionButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');

    contents = cellstr(get(handles.objFuncCombo,'String'));
    selectedObjFunc = deblank(contents{get(handles.objFuncCombo,'Value')});
    
    contents = cellstr(get(handles.bodyObjFuncCombo,'String'));
    selectedCelBody = contents{get(handles.bodyObjFuncCombo,'Value')};
    selectedCelBodyValue = get(handles.bodyObjFuncCombo,'Value');
    if(~isempty(selectedCelBody))
        bodyID = celBodyData.(strtrim(lower(selectedCelBody))).id;
    else
        bodyID = -1;
    end
    
    objEventNum = get(handles.eventObjFuncCombo,'value');
    objEventID = ma_GetEventIDByEventNum(objEventNum, maData.script);
    
    optVarData = get(handles.optVarListbox,'UserData');
    actConsts = get(handles.actConstsListbox,'UserData');
    
    hWaitbar = waitbar(0,'Please wait while the optimizer initializes...');
    
    [maData, problem] = ma_setupOptimProblem(maData, celBodyData, hWaitbar, selectedObjFunc, bodyID, selectedCelBodyValue, objEventNum, objEventID, optVarData, actConsts);
    if(isempty(problem))
        return;
    end
    
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    
    %%%%%%%
    % Run optimizer!
    %%%%%%%   
    set(handles.ma_MissionOptimizerGUI,'Visible','off');
    drawnow;
    waitbar(1,hWaitbar);
    close(hWaitbar);
    
    ma_ObserveOptimGUI(celBodyData, problem, false, [], handles.ma_MainGUI);

    uiresume(handles.ma_MissionOptimizerGUI);
    close(handles.ma_MissionOptimizerGUI); 

    
% --- Executes on selection change in availConstListbox.
function availConstListbox_Callback(hObject, eventdata, handles)
% hObject    handle to availConstListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns availConstListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from availConstListbox
    if(strcmpi(get(handles.ma_MissionOptimizerGUI,'SelectionType'),'open'))  
        addConstraintButton_Callback(handles.addConstraintButton, [], handles);
    end

% --- Executes during object creation, after setting all properties.
function availConstListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to availConstListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in actConstsListbox.
function actConstsListbox_Callback(hObject, eventdata, handles)
% hObject    handle to actConstsListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns actConstsListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from actConstsListbox
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    actConsts = get(handles.actConstsListbox,'UserData');
    value = get(handles.actConstsListbox,'value');

    if(strcmpi(get(handles.ma_MissionOptimizerGUI,'SelectionType'),'open'))       
        preSize = size(actConsts);
        actConsts(all(cellfun(@isempty,actConsts),2),:) = [];
        postSize = size(actConsts);
        
        if(~all(preSize==postSize))
            set(handles.actConstsListbox,'UserData',actConsts);
            updateActConstListBox(handles);
            return;
        end
        
        try
            const = actConsts(value,:);
            type = const{end,3};
            unit = const{end,4};
            numericConstInputs = const{end,5};
            lbLim = numericConstInputs(1);
            ubLim = numericConstInputs(2);
            lbVal = numericConstInputs(3);
            ubVal = numericConstInputs(4);
            body = numericConstInputs(5);
%             eventNum = numericConstInputs(6);
            otherSC = numericConstInputs(8);
            eventID = numericConstInputs(7);
            
            if(length(numericConstInputs) == 8)
                lbActive = true;
                ubActive = true;
            else
                lbActive = numericConstInputs(9);
                ubActive = numericConstInputs(10);
            end
        catch
            try
                actConsts(value,:) = [];
                set(handles.actConstsListbox,'UserData',actConsts);
                updateActConstListBox(handles);
                return;
            catch
                return;
            end
        end
        
        [~, eventNum] = getEventByID(eventID, maData.script);
        [constFunc, lbVal, ubVal, body, otherSC, eventID, lbActive, ubActive] = ma_ConstraintDetailsGUI(handles.ma_MainGUI, type, unit, lbLim, ubLim, lbVal, ubVal, body, eventNum, otherSC, eventID, lbActive, ubActive);
        if(~isempty(constFunc))
            [~, eventNum] = getEventByID(eventID, maData.script);
            constStr = ma_getConstraintStr(type, eventNum);
            
            actConsts = get(handles.actConstsListbox,'UserData');
            actConsts{value,1} = constStr;
            actConsts{value,2} = [];
            actConsts{value,3} = type;
            actConsts{value,4} = unit;
            actConsts{value,5} = [lbLim, ubLim, lbVal, ubVal, body, eventNum, eventID, otherSC, lbActive, ubActive];
            set(handles.actConstsListbox,'UserData',actConsts);

            updateActConstListBox(handles);
        end
    end
    

% --- Executes during object creation, after setting all properties.
function actConstsListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to actConstsListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addConstraintButton.
function addConstraintButton_Callback(hObject, eventdata, handles)
% hObject    handle to addConstraintButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    contents = cellstr(get(handles.availConstListbox,'String'));
    type = deblank(contents{get(handles.availConstListbox,'Value')});

    eventNum = -1;
    eventID = -1;

    [unit, lbLim, ubLim, lbVal, ubVal, body, othersc] = ma_getConstraintStaticDetails(type);
    lbActive = true;
    ubActive = true;
    
    [constFunc, lbVal, ubVal, body, othersc, eventID, lbActive, ubActive] = ma_ConstraintDetailsGUI(handles.ma_MainGUI, type, unit, lbLim, ubLim, lbVal, ubVal, body, eventNum, othersc, eventID, lbActive, ubActive);
    if(~isempty(constFunc))
        [~, eventNum] = getEventByID(eventID, maData.script);
        constStr = ma_getConstraintStr(type, eventNum);

        actConsts = get(handles.actConstsListbox,'UserData');
        actConsts = ma_getConstCellArr(actConsts, constStr, constFunc, type, unit, lbLim, ubLim, lbVal, ubVal, body, eventNum, eventID, othersc, lbActive, ubActive);
        set(handles.actConstsListbox,'UserData',actConsts);

        updateActConstListBox(handles);
    end
    
    
function updateActConstListBox(handles)
    actConsts = get(handles.actConstsListbox,'UserData');
    value = get(handles.actConstsListbox,'value');
    
    listboxStr = cell(size(actConsts,1),1);
    for(i=1:size(actConsts,1))
        listboxStr{i} = actConsts{i,1};
    end
    
    if(length(listboxStr)==1)
        set(handles.actConstsListbox,'String',listboxStr);
        set(handles.actConstsListbox,'value',1);
    elseif(length(listboxStr) < value)
        set(handles.actConstsListbox,'value',length(listboxStr));
        set(handles.actConstsListbox,'String',listboxStr);
    else
        set(handles.actConstsListbox,'String',listboxStr);
%         set(handles.actConstsListbox,'value',length(listboxStr));
    end
    
    setActConstListboxTooltip(handles);
    
    
function setActConstListboxTooltip(handles)
    actConsts = get(handles.actConstsListbox,'UserData');
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    
    tooltipStr = 'Active Constraints:\n \n';
    for(i=1:size(actConsts,1)) %#ok<*NO4LP>
        try
            constType = actConsts{i,3};
            constUnit = actConsts{i,4};
            constLB = actConsts{i,5}(3);
            constUB = actConsts{i,5}(4);
            constEventID = actConsts{i,5}(7);
            [~, constEventNum] = getEventByID(constEventID, maData.script);
            constBodyID = actConsts{i,5}(5);
        catch
            continue;
        end
        
        try
            otherSCID = actConsts{i,5}(8);
        catch
            otherSCID = -1;
        end
        
        if(length(actConsts{i,5}) == 8)
            lbActive = true;
            ubActive = true;
        else
            lbActive = actConsts{i,5}(9);
            ubActive = actConsts{i,5}(10);
        end
        
        if(constBodyID == -1)
            constBodyStrFull = '';
        else
            bodyInfo = getBodyInfoByNumber(constBodyID, celBodyData);
            constBodyStr = bodyInfo.name;
            constBodyStrFull = ['Body: ', constBodyStr,'\n'];
        end
        
        if(otherSCID == -1)
            constOSCStrFull = '';
        else
            otherSCInfo = getOtherSCInfoByID(maData, otherSCID);
            if(~isempty(otherSCInfo) && isfield(otherSCInfo,'name'))
                constOSCStr = otherSCInfo.name;
                constOSCStrFull = ['Spacecraft: ',constOSCStr,'\n'];
            else
                constOSCStrFull = '';
            end
        end
        
        lbActiveStr = '';
        if(lbActive == false)
            lbActiveStr = ' (Inactive)';
        end
        
        ubActiveStr = '';
        if(ubActive == false)
            ubActiveStr = ' (Inactive)';
        end
        
        lbStr = ['Lower Bnd: ', num2str(constLB), ' ', constUnit, lbActiveStr, '\n'];
        ubStr = ['Upper Bnd: ', num2str(constUB), ' ', constUnit, ubActiveStr, '\n'];
        
        if(constLB == 0 && constUB == 0 && isempty(constUnit) && ~strcmpi(constType, 'Eccentricity'))
            lbStr = '';
            ubStr = '';
        end
        
        tooltipStr = [tooltipStr,...
                      '--',constType,' Constraint--','\n'...
                      'Event: ', num2str(constEventNum),'\n',...
                      lbStr,...
                      ubStr,...
                      constBodyStrFull,...
                      constOSCStrFull,' \n']; %#ok<AGROW>
    end
    set(handles.actConstsListbox, 'TooltipString', sprintf(tooltipStr));
    
    
    
% --- Executes on button press in removeConstraintButton.
function removeConstraintButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeConstraintButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    value = get(handles.actConstsListbox,'value');
    actConsts = get(handles.actConstsListbox,'UserData');
    if(value > 0)
        actConsts(value,:) = [];

        set(handles.actConstsListbox,'UserData',actConsts);

        updateActConstListBox(handles);
    end


% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.ma_MissionOptimizerGUI);


function lbVarText_Callback(hObject, eventdata, handles)
% hObject    handle to lbVarText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lbVarText as text
%        str2double(get(hObject,'String')) returns contents of lbVarText as a double
    updateVarListbox(handles);

% --- Executes during object creation, after setting all properties.
function lbVarText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lbVarText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ubVarText_Callback(hObject, eventdata, handles)
% hObject    handle to ubVarText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ubVarText as text
%        str2double(get(hObject,'String')) returns contents of ubVarText as a double
    updateVarListbox(handles);

% --- Executes during object creation, after setting all properties.
function ubVarText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ubVarText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in bodyObjFuncCombo.
function bodyObjFuncCombo_Callback(hObject, eventdata, handles)
% hObject    handle to bodyObjFuncCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns bodyObjFuncCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from bodyObjFuncCombo



% --- Executes during object creation, after setting all properties.
function bodyObjFuncCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bodyObjFuncCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on ma_MissionOptimizerGUI or any of its controls.
function ma_MissionOptimizerGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to ma_MissionOptimizerGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'escape'
            close(handles.ma_MissionOptimizerGUI);
    end


% --------------------------------------------------------------------
function enableAllConstMenu_Callback(hObject, eventdata, handles)
% hObject    handle to enableAllConstMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    actConsts = get(handles.actConstsListbox,'UserData');
    for(i=1:size(actConsts,1))
        actConsts{i,5}(9) = 1;
        actConsts{i,5}(10) = 1;
    end
    set(handles.actConstsListbox,'UserData',actConsts);

% --------------------------------------------------------------------
function disableAllConstMenu_Callback(hObject, eventdata, handles)
% hObject    handle to disableAllConstMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    actConsts = get(handles.actConstsListbox,'UserData');
    for(i=1:size(actConsts,1))
        actConsts{i,5}(9) = 0;
        actConsts{i,5}(10) = 0;
    end
    set(handles.actConstsListbox,'UserData',actConsts);
