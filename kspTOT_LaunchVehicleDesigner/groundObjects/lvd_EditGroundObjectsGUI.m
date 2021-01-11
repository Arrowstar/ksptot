function varargout = lvd_EditGroundObjectsGUI(varargin)
    % LVD_EDITGROUNDOBJECTSGUI MATLAB code for lvd_EditGroundObjectsGUI.fig
    %      LVD_EDITGROUNDOBJECTSGUI, by itself, creates a new LVD_EDITGROUNDOBJECTSGUI or raises the existing
    %      singleton*.
    %
    %      H = LVD_EDITGROUNDOBJECTSGUI returns the handle to a new LVD_EDITGROUNDOBJECTSGUI or the handle to
    %      the existing singleton*.
    %
    %      LVD_EDITGROUNDOBJECTSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in LVD_EDITGROUNDOBJECTSGUI.M with the given input arguments.
    %
    %      LVD_EDITGROUNDOBJECTSGUI('Property','Value',...) creates a new LVD_EDITGROUNDOBJECTSGUI or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before lvd_EditGroundObjectsGUI_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to lvd_EditGroundObjectsGUI_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES
    
    % Edit the above text to modify the response to help lvd_EditGroundObjectsGUI
    
    % Last Modified by GUIDE v2.5 19-Jul-2020 08:59:13
    
    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
        'gui_Singleton',  gui_Singleton, ...
        'gui_OpeningFcn', @lvd_EditGroundObjectsGUI_OpeningFcn, ...
        'gui_OutputFcn',  @lvd_EditGroundObjectsGUI_OutputFcn, ...
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
    
    
    % --- Executes just before lvd_EditGroundObjectsGUI is made visible.
function lvd_EditGroundObjectsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditGroundObjectsGUI (see VARARGIN)
    
    % Choose default command line output for lvd_EditGroundObjectsGUI
    handles.output = hObject;
    
    grndObjs = varargin{1};
    setappdata(hObject,'grndObjs',grndObjs);
    
    handles = populateGUI(grndObjs, handles);
    
    % Update handles structure
    guidata(hObject, handles);
    
    % UIWAIT makes lvd_EditGroundObjectsGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditGroundObjectsGUI);
    
function handles = populateGUI(grndObjs, handles)
    listboxStr = grndObjs.getListboxStr();
    handles.groundObjListbox.String = listboxStr;
    
    if(length(listboxStr) >= 1)
        handles.groundObjListbox.Value = 1;
    end
    
    celBodyData = grndObjs.lvdData.celBodyData;
    populateBodiesCombo(celBodyData, handles.celestialBodyCombo);
    
    grndObj = getSelectedGroundObj(handles);
    updateGuiForGroundObj(grndObj, handles);
    
function updateGuiForGroundObj(grndObj, handles)
    if(not(isempty(grndObj)))
        grndObjs = getappdata(handles.lvd_EditGroundObjectsGUI,'grndObjs');
        celBodyData = grndObjs.lvdData.celBodyData;
        
        handles.groundObjectNameText.String = grndObj.name;
        handles.groundObjDescText.String = grndObj.desc;
        
        [~, sortedBodyInfo] = ma_getSortedBodyNames(celBodyData);
        sortedBodyInfo = [sortedBodyInfo{:}];
        
        ind = find(grndObj.centralBodyInfo == sortedBodyInfo,1,'first');
        handles.celestialBodyCombo.Value = ind;
        
        handles.groundObjColorCombo.String = ColorSpecEnum.getListboxStr();
        handles.groundObjColorCombo.Value = ColorSpecEnum.getIndForName(grndObj.markerColor.name);
        
        handles.groundObjMarkerShapeCombo.String = MarkerStyleEnum.getListboxStr();
        handles.groundObjMarkerShapeCombo.Value = MarkerStyleEnum.getIndForName(grndObj.markerShape.name);
        
        handles.groundObjLineColorCombo.String = ColorSpecEnum.getListboxStr();
        handles.groundObjLineColorCombo.Value = ColorSpecEnum.getIndForName(grndObj.grdTrkLineColor.name);
        
        handles.groundObjLineSpecCombo.String = LineSpecEnum.getListboxStr();
        handles.groundObjLineSpecCombo.Value = LineSpecEnum.getIndForName(grndObj.grdTrkLineSpec.name);
        
        handles.initialTimeText.String = fullAccNum2Str(grndObj.initialTime);
        handles.extrapolateTimesCheckbox.Value = double(grndObj.extrapolateTimes);
        handles.loopGroundObjTrackCheckbox.Value = double(grndObj.loopWayPts);
        
        handles.waypointsListbox.String = grndObj.getWayListboxStr();
        
        wayPt = getSelectedWayPt(handles);
        updateGuiForWayPt(wayPt, grndObj, handles);
        
        toggleEnableForGuiElements('on', handles);
    else
        handles.groundObjectNameText.String = '';
        handles.groundObjDescText.String = '';
        handles.initialTimeText.String = '';
        
        updateGuiForWayPt(LaunchVehicleGroundObjectWayPt.empty(1,0), grndObj, handles);
        toggleEnableForGuiElements('off', handles);
    end
    
    setWayPtDeleteButtonEnable(handles);
    setGrndObjDeleteButtonEnable(handles);
    
function updateGuiForWayPt(wayPt, grndObj, handles)
    if(not(isempty(wayPt)))
        handles.waypointLatText.String = fullAccNum2Str(rad2deg(wayPt.getLatitude()));
        handles.waypointLongText.String = fullAccNum2Str(rad2deg(wayPt.getLongitude()));
        handles.waypointAltText.String = fullAccNum2Str(wayPt.getAltitude());
        handles.timeToNextWaypointText.String = fullAccNum2Str(wayPt.getTimesToNextWaypt());
        
        updateDistanceLabel(handles);
    else
        handles.waypointLatText.String = '';
        handles.waypointLongText.String = '';
        handles.waypointAltText.String = '';
        handles.timeToNextWaypointText.String = '';
        handles.distToNextWaypointLabel.String = '';
        
        handles.waypointsListbox.String = {};
    end
    
    setWayPtDeleteButtonEnable(handles);
    
function updateDistanceLabel(handles)
    grndObj = getSelectedGroundObj(handles);
    wayPt = getSelectedWayPt(handles);
    
    wayPt2 = grndObj.getNextWaypt(wayPt);
    if(not(isempty(wayPt2)))
        wayPtDistStr = fullAccNum2Str(grndObj.getDistanceBetweenWayPts(wayPt, wayPt2));
    else
        wayPtDistStr = '--';
    end
    
    handles.distToNextWaypointLabel.String = wayPtDistStr;
    
function wayPt = getSelectedWayPt(handles)
    grndObj = getSelectedGroundObj(handles);
    
    ind = handles.waypointsListbox.Value;
    wayPt = grndObj.getWayPointAtInd(ind);
    
function grndObj = getSelectedGroundObj(handles)
    grndObjs = getappdata(handles.lvd_EditGroundObjectsGUI,'grndObjs');
    
    ind = handles.groundObjListbox.Value;
    grndObj = grndObjs.getGroundObjAtInd(ind);
    
    
function toggleEnableForGuiElements(enableStr, handles)
    handles.groundObjListbox.Enable = enableStr;
    handles.removeGroundObjButton.Enable = enableStr;
    
    handles.groundObjectNameText.Enable = enableStr;
    handles.groundObjDescText.Enable = enableStr;
    
    handles.celestialBodyCombo.Enable = enableStr;
    
    handles.groundObjColorCombo.Enable = enableStr;
    handles.groundObjMarkerShapeCombo.Enable = enableStr;
    handles.groundObjLineColorCombo.Enable = enableStr;
    handles.groundObjLineSpecCombo.Enable = enableStr;
    
    handles.initialTimeText.Enable = enableStr;
    handles.extrapolateTimesCheckbox.Enable = enableStr;
    handles.loopGroundObjTrackCheckbox.Enable = enableStr;
    
    handles.waypointsListbox.Enable = enableStr;
    handles.moveWaypointDownButton.Enable = enableStr;
    handles.moveWaypointUpButton.Enable = enableStr;
    handles.addWaypointButton.Enable = enableStr;
    handles.removeWaypointButton.Enable = enableStr;
    
    handles.waypointLatText.Enable = enableStr;
    handles.waypointLongText.Enable = enableStr;
    handles.waypointAltText.Enable = enableStr;
    handles.timeToNextWaypointText.Enable = enableStr;
    handles.distToNextWaypointLabel.Enable = enableStr;
    
function setGrndObjDeleteButtonEnable(handles)
    grndObjs = getappdata(handles.lvd_EditGroundObjectsGUI,'grndObjs');
    numGrndObjs = grndObjs.getNumGroundObj();
    
    if(numGrndObjs > 0)
        handles.removeGroundObjButton.Enable = 'on';
    else
        handles.removeGroundObjButton.Enable = 'off';
    end
    
function setWayPtDeleteButtonEnable(handles)
    grndObj = getSelectedGroundObj(handles);
    
    if(not(isempty(grndObj)))
        numWayPts = grndObj.getNumWayPts();
        
        if(numWayPts > 1)
            handles.removeWaypointButton.Enable = 'on';
        else
            handles.removeWaypointButton.Enable = 'off';
        end
    else
        handles.removeWaypointButton.Enable = 'off';
    end
    
    % --- Outputs from this function are returned to the command line.
function varargout = lvd_EditGroundObjectsGUI_OutputFcn(hObject, eventdata, handles)
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        varargout{1} = true;
        close(handles.lvd_EditGroundObjectsGUI);
    end
    
    
    % --- Executes on selection change in groundObjListbox.
function groundObjListbox_Callback(hObject, eventdata, handles)
    % hObject    handle to groundObjListbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns groundObjListbox contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from groundObjListbox
    grndObj = getSelectedGroundObj(handles);
    updateGuiForGroundObj(grndObj, handles);
    
    % --- Executes during object creation, after setting all properties.
function groundObjListbox_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to groundObjListbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: listbox controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on button press in addGroundObjButton.
function addGroundObjButton_Callback(hObject, eventdata, handles)
    % hObject    handle to addGroundObjButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    grndObjs = getappdata(handles.lvd_EditGroundObjectsGUI,'grndObjs');
    celBodyData = grndObjs.lvdData.celBodyData;
    
    grndObj = LaunchVehicleGroundObject.getDefaultObj(celBodyData);
    grndObjs.addGroundObj(grndObj);
    
    handles.groundObjListbox.String = grndObjs.getListboxStr();
    handles.groundObjListbox.Value = grndObjs.getNumGroundObj();
    updateGuiForGroundObj(grndObj, handles);
    
    setGrndObjDeleteButtonEnable(handles);
    
    % --- Executes on button press in removeGroundObjButton.
function removeGroundObjButton_Callback(hObject, eventdata, handles)
    % hObject    handle to removeGroundObjButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    grndObjs = getappdata(handles.lvd_EditGroundObjectsGUI,'grndObjs');
    
    grndObj = getSelectedGroundObj(handles);
    
    tf = grndObj.isInUse();
    if(tf == false)
        grndObjs.removeGroundObj(grndObj);
        numGrndObjs = grndObjs.getNumGroundObj();

        grndObjs.lvdData.viewSettings.removeGrdObjFromViewProfiles(grndObj);

        handles.groundObjListbox.String = grndObjs.getListboxStr();

        if(handles.groundObjListbox.Value > numGrndObjs)
            handles.groundObjListbox.Value = numGrndObjs;
        end

        grndObj = getSelectedGroundObj(handles);
        updateGuiForGroundObj(grndObj, handles);
        setGrndObjDeleteButtonEnable(handles);
    else
        errordlg('The selected ground object could not be deleted.  It is in use as a geometric point.  Remove ground object dependecies first.','Could Not Delete Ground Object');
    end
    
    
function groundObjectNameText_Callback(hObject, eventdata, handles)
    % hObject    handle to groundObjectNameText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of groundObjectNameText as text
    %        str2double(get(hObject,'String')) returns contents of groundObjectNameText as a double
    grndObj = getSelectedGroundObj(handles);
    grndObj.name = get(hObject,'String');
    
    grndObjs = getappdata(handles.lvd_EditGroundObjectsGUI,'grndObjs');
    handles.groundObjListbox.String = grndObjs.getListboxStr();
    
    % --- Executes during object creation, after setting all properties.
function groundObjectNameText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to groundObjectNameText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    
function groundObjDescText_Callback(hObject, eventdata, handles)
    % hObject    handle to groundObjDescText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of groundObjDescText as text
    %        str2double(get(hObject,'String')) returns contents of groundObjDescText as a double
    grndObj = getSelectedGroundObj(handles);
    grndObj.desc = get(hObject,'String');
    
    % --- Executes during object creation, after setting all properties.
function groundObjDescText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to groundObjDescText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on selection change in groundObjColorCombo.
function groundObjColorCombo_Callback(hObject, eventdata, handles)
    % hObject    handle to groundObjColorCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns groundObjColorCombo contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from groundObjColorCombo
    grndObj = getSelectedGroundObj(handles);
    
    contents = cellstr(get(hObject,'String'));
    str = contents{get(hObject,'Value')};
    
    grndObj.markerColor = ColorSpecEnum.getEnumForListboxStr(str);
    
    % --- Executes during object creation, after setting all properties.
function groundObjColorCombo_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to groundObjColorCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on selection change in groundObjLineSpecCombo.
function groundObjLineSpecCombo_Callback(hObject, eventdata, handles)
    % hObject    handle to groundObjLineSpecCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns groundObjLineSpecCombo contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from groundObjLineSpecCombo
    grndObj = getSelectedGroundObj(handles);
    
    contents = cellstr(get(hObject,'String'));
    str = contents{get(hObject,'Value')};
    
    grndObj.grdTrkLineSpec = LineSpecEnum.getEnumForListboxStr(str);
    
    % --- Executes during object creation, after setting all properties.
function groundObjLineSpecCombo_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to groundObjLineSpecCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on selection change in waypointsListbox.
function waypointsListbox_Callback(hObject, eventdata, handles)
    % hObject    handle to waypointsListbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns waypointsListbox contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from waypointsListbox
    grndObj = getSelectedGroundObj(handles);
    wayPt = getSelectedWayPt(handles);
    updateGuiForWayPt(wayPt, grndObj, handles);
    
    % --- Executes during object creation, after setting all properties.
function waypointsListbox_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to waypointsListbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: listbox controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on button press in addWaypointButton.
function addWaypointButton_Callback(hObject, eventdata, handles)
    % hObject    handle to addWaypointButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    grndObj = getSelectedGroundObj(handles);
    
    initialTime = grndObj.initialTime;
    frameToUse = grndObj.centralBodyInfo.getBodyFixedFrame();
    wayPt = LaunchVehicleGroundObjectWayPt.getDefaultWayPt(initialTime, frameToUse);
    grndObj.addWaypoint(wayPt);
    
    handles.waypointsListbox.String = grndObj.getWayListboxStr();
    handles.waypointsListbox.Value = grndObj.getNumWayPts();
    updateGuiForWayPt(wayPt, grndObj, handles);
    
    setWayPtDeleteButtonEnable(handles);
    
    % --- Executes on button press in removeWaypointButton.
function removeWaypointButton_Callback(hObject, eventdata, handles)
    % hObject    handle to removeWaypointButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    grndObj = getSelectedGroundObj(handles);
    
    wayPt = getSelectedWayPt(handles);
    grndObj.removeWaypoint(wayPt);
    numWayPts = grndObj.getNumWayPts();
    
    handles.waypointsListbox.String = grndObj.getWayListboxStr();
    
    if(handles.waypointsListbox.Value > numWayPts)
        handles.waypointsListbox.Value = numWayPts;
    end
    
    wayPt = getSelectedWayPt(handles);
    updateGuiForWayPt(wayPt, grndObj, handles);
    setWayPtDeleteButtonEnable(handles);
    
    
    % --- Executes on button press in extrapolateTimesCheckbox.
function extrapolateTimesCheckbox_Callback(hObject, eventdata, handles)
    % hObject    handle to extrapolateTimesCheckbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hint: get(hObject,'Value') returns toggle state of extrapolateTimesCheckbox
    grndObj = getSelectedGroundObj(handles);
    grndObj.extrapolateTimes = logical(get(hObject,'Value'));
    
    % --- Executes on button press in loopGroundObjTrackCheckbox.
function loopGroundObjTrackCheckbox_Callback(hObject, eventdata, handles)
    % hObject    handle to loopGroundObjTrackCheckbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hint: get(hObject,'Value') returns toggle state of loopGroundObjTrackCheckbox
    grndObj = getSelectedGroundObj(handles);
    grndObj.loopWayPts = logical(get(hObject,'Value'));
    
    wayPt = getSelectedWayPt(handles);
    updateGuiForWayPt(wayPt, grndObj, handles);
    
    
function initialTimeText_Callback(hObject, eventdata, handles)
    % hObject    handle to initialTimeText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of initialTimeText as text
    %        str2double(get(hObject,'String')) returns contents of initialTimeText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    grndObj = getSelectedGroundObj(handles);
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Initial Time';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        grndObj.initialTime = value;
    else
        hObject.String = fullAccNum2Str(grndObj.initialTime);
        
        msgbox(errMsg,'Invalid Initial Time Value','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function initialTimeText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to initialTimeText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on button press in moveWaypointDownButton.
function moveWaypointDownButton_Callback(hObject, eventdata, handles)
    % hObject    handle to moveWaypointDownButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    grndObj = getSelectedGroundObj(handles);
    
    wayPtNum = get(handles.waypointsListbox,'Value');
    grndObj.moveWayPtAtIndexDown(wayPtNum);
    
    if(wayPtNum < grndObj.getNumWayPts())
        set(handles.waypointsListbox,'Value',wayPtNum+1);
    end
    
    handles.waypointsListbox.String = grndObj.getWayListboxStr();
    
    % --- Executes on button press in moveWaypointUpButton.
function moveWaypointUpButton_Callback(hObject, eventdata, handles)
    % hObject    handle to moveWaypointUpButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    grndObj = getSelectedGroundObj(handles);
    
    wayPtNum = get(handles.waypointsListbox,'Value');
    grndObj.moveWayPtAtIndexUp(wayPtNum);
    
    if(wayPtNum > 1)
        set(handles.waypointsListbox,'Value',wayPtNum-1);
    end
    
    handles.waypointsListbox.String = grndObj.getWayListboxStr();
    
    
function waypointLatText_Callback(hObject, eventdata, handles)
    % hObject    handle to waypointLatText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of waypointLatText as text
    %        str2double(get(hObject,'String')) returns contents of waypointLatText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    wayPt = getSelectedWayPt(handles);
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Waypoint Latitude';
    lb = -90;
    ub = 90;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        wayPt.setLatitude(deg2rad(value));
        
        grndObj = getSelectedGroundObj(handles);
        handles.waypointsListbox.String = grndObj.getWayListboxStr();
        updateDistanceLabel(handles);
    else
        hObject.String = fullAccNum2Str(rad2deg(wayPt.getLatitude()));
        
        msgbox(errMsg,'Invalid Waypoint Latitude Value','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function waypointLatText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to waypointLatText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    
function waypointLongText_Callback(hObject, eventdata, handles)
    % hObject    handle to waypointLongText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of waypointLongText as text
    %        str2double(get(hObject,'String')) returns contents of waypointLongText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    wayPt = getSelectedWayPt(handles);
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Waypoint Longitude';
    lb = -360;
    ub = 360;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        wayPt.setLongitude(deg2rad(value));
        
        grndObj = getSelectedGroundObj(handles);
        handles.waypointsListbox.String = grndObj.getWayListboxStr();
        updateDistanceLabel(handles);
    else
        hObject.String = fullAccNum2Str(rad2deg(wayPt.getLongitude()));
        
        msgbox(errMsg,'Invalid Waypoint Longitude Value','error');
    end
    
    
    % --- Executes during object creation, after setting all properties.
function waypointLongText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to waypointLongText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    
function waypointAltText_Callback(hObject, eventdata, handles)
    % hObject    handle to waypointAltText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of waypointAltText as text
    %        str2double(get(hObject,'String')) returns contents of waypointAltText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    wayPt = getSelectedWayPt(handles);
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Waypoint Altitude';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        wayPt.setAltitude(value);
        
        grndObj = getSelectedGroundObj(handles);
        handles.waypointsListbox.String = grndObj.getWayListboxStr();
        updateDistanceLabel(handles);
    else
        hObject.String = fullAccNum2Str(wayPt.getAltitude());
        
        msgbox(errMsg,'Invalid Waypoint Altitude Value','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function waypointAltText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to waypointAltText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    
function timeToNextWaypointText_Callback(hObject, eventdata, handles)
    % hObject    handle to timeToNextWaypointText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of timeToNextWaypointText as text
    %        str2double(get(hObject,'String')) returns contents of timeToNextWaypointText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    wayPt = getSelectedWayPt(handles);
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Time to Next Waypoint';
    lb = 0.001;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        wayPt.timeToNextWayPt = value;
        
        grndObj = getSelectedGroundObj(handles);
        handles.waypointsListbox.String = grndObj.getWayListboxStr();
        updateDistanceLabel(handles);
    else
        hObject.String = fullAccNum2Str(wayPt.timeToNextWayPt);
        
        msgbox(errMsg,'Invalid Time to Next Waypoint Value','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function timeToNextWaypointText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to timeToNextWaypointText (see GCBO)
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
    errMsg = {};
    if(isempty(errMsg))
        uiresume(handles.lvd_EditGroundObjectsGUI);
    else
        msgbox(errMsg,'Errors were found while editing ground objects.','error');
    end
    
    % --- Executes on selection change in celestialBodyCombo.
function celestialBodyCombo_Callback(hObject, eventdata, handles)
    % hObject    handle to celestialBodyCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns celestialBodyCombo contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from celestialBodyCombo
    grndObjs = getappdata(handles.lvd_EditGroundObjectsGUI,'grndObjs');
    celBodyData = grndObjs.lvdData.celBodyData;
    [~, sortedBodyInfo] = ma_getSortedBodyNames(celBodyData);
    
    grndObj = getSelectedGroundObj(handles);
    
    ind = hObject.Value;
    grndObj.centralBodyInfo = sortedBodyInfo{ind};
    
    % --- Executes during object creation, after setting all properties.
function celestialBodyCombo_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to celestialBodyCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes during object creation, after setting all properties.
function distToNextWaypointLabel_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to distToNextWaypointLabel (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    
    % --- Executes on selection change in groundObjLineColorCombo.
function groundObjLineColorCombo_Callback(hObject, eventdata, handles)
    % hObject    handle to groundObjLineColorCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns groundObjLineColorCombo contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from groundObjLineColorCombo
    grndObj = getSelectedGroundObj(handles);
    
    contents = cellstr(get(hObject,'String'));
    str = contents{get(hObject,'Value')};
    
    grndObj.grdTrkLineColor = ColorSpecEnum.getEnumForListboxStr(str);
    
    % --- Executes during object creation, after setting all properties.
function groundObjLineColorCombo_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to groundObjLineColorCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on selection change in groundObjMarkerShapeCombo.
function groundObjMarkerShapeCombo_Callback(hObject, eventdata, handles)
    % hObject    handle to groundObjMarkerShapeCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns groundObjMarkerShapeCombo contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from groundObjMarkerShapeCombo
    grndObj = getSelectedGroundObj(handles);
    
    contents = cellstr(get(hObject,'String'));
    str = contents{get(hObject,'Value')};
    
    grndObj.markerShape = MarkerStyleEnum.getEnumForListboxStr(str);
    
    % --- Executes during object creation, after setting all properties.
function groundObjMarkerShapeCombo_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to groundObjMarkerShapeCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --------------------------------------------------------------------
function enterUTAsDateTimeMenu_Callback(hObject, eventdata, handles)
    % hObject    handle to enterUTAsDateTimeMenu (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    secUT = enterUTAsDateTimeGUI(str2double(get(gco, 'String')));
    if(secUT >= 0)
        set(gco, 'String', fullAccNum2Str(secUT));
        initialTimeText_Callback(handles.initialTimeText, [], handles);
    end
    
    % --------------------------------------------------------------------
function getUTFromKSPMenu_Callback(hObject, eventdata, handles)
    % hObject    handle to getUTFromKSPMenu (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    secUT = readDoublesFromKSPTOTConnect('GetUT', '', true);
    if(secUT >= 0)
        set(gco, 'String', fullAccNum2Str(secUT));
        initialTimeText_Callback(handles.initialTimeText, [], handles);
    end
    
    % --------------------------------------------------------------------
function initialTimeContextMenu_Callback(hObject, eventdata, handles)
    % hObject    handle to initialTimeContextMenu (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
