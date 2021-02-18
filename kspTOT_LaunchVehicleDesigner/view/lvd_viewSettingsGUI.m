function varargout = lvd_viewSettingsGUI(varargin)
    % LVD_VIEWSETTINGSGUI MATLAB code for lvd_viewSettingsGUI.fig
    %      LVD_VIEWSETTINGSGUI, by itself, creates a new LVD_VIEWSETTINGSGUI or raises the existing
    %      singleton*.
    %
    %      H = LVD_VIEWSETTINGSGUI returns the handle to a new LVD_VIEWSETTINGSGUI or the handle to
    %      the existing singleton*.
    %
    %      LVD_VIEWSETTINGSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in LVD_VIEWSETTINGSGUI.M with the given input arguments.
    %
    %      LVD_VIEWSETTINGSGUI('Property','Value',...) creates a new LVD_VIEWSETTINGSGUI or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before lvd_viewSettingsGUI_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to lvd_viewSettingsGUI_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES
    
    % Edit the above text to modify the response to help lvd_viewSettingsGUI
    
    % Last Modified by GUIDE v2.5 18-Feb-2021 10:06:40
    
    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
        'gui_Singleton',  gui_Singleton, ...
        'gui_OpeningFcn', @lvd_viewSettingsGUI_OpeningFcn, ...
        'gui_OutputFcn',  @lvd_viewSettingsGUI_OutputFcn, ...
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
    
    
    % --- Executes just before lvd_viewSettingsGUI is made visible.
function lvd_viewSettingsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_viewSettingsGUI (see VARARGIN)
    
    % Choose default command line output for lvd_viewSettingsGUI
    handles.output = hObject;
    
    viewSettings = varargin{1};
    setappdata(hObject,'viewSettings',viewSettings);
    
    handles = populateGUI(viewSettings, handles);
    
    % Update handles structure
    guidata(hObject, handles);
    
    % UIWAIT makes lvd_viewSettingsGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_viewSettingsGUI);
    
function handles = populateGUI(viewSettings, handles)
    handles.viewProfilesListbox.String = viewSettings.getListboxStr();
    handles.viewProfilesListbox.Value = viewSettings.getIndOfSelectedProfile();
    
    celBodyData = viewSettings.lvdData.celBodyData;
    populateBodiesCombo(celBodyData, handles.bodiesToPlotListbox);
    
    grdObjSet = viewSettings.lvdData.groundObjs;
    handles.grdObjsListbox.String = grdObjSet.getListboxStr();
    
    geometry = viewSettings.lvdData.geometry;
	[~, plotPointsListBoxStr] = geometry.points.getPlottablePoints();
    handles.pointsToPlotListbox.String = plotPointsListBoxStr;
    handles.vectorsToPlotListbox.String = geometry.vectors.getListboxStr();
    handles.refFramessToPlotListbox.String = geometry.refFrames.getListboxStr();
    handles.anglesToPlotListbox.String = geometry.angles.getListboxStr();
    handles.planesToPlotListbox.String = geometry.planes.getListboxStr();
    
    profile = getSelectedProfile(handles);
    updateGuiForProfile(profile, handles);
    setDeleteButtonEnable(handles);
    
function updateGuiForProfile(profile, handles)
    viewSettings = getappdata(handles.lvd_viewSettingsGUI,'viewSettings');
    celBodyData = viewSettings.lvdData.celBodyData;
    
    handles.nameText.String = profile.name;
    handles.profileDesc.String = profile.desc;
    handles.setAsActiveProfileCheckbox.Value = viewSettings.isProfileActive(profile);
    
    handles.showSoICheckbox.Value = profile.showSoIRadius;
    handles.showFixedFrameGridCheckbox.Value = profile.showLongLatAnnotations;
    
    handles.axesBackgroundColorCombo.String = ColorSpecEnum.getListboxStr();
    handles.axesBackgroundColorCombo.Value = ColorSpecEnum.getIndForName(profile.backgroundColor.name);
    
    handles.majorGridLinesColorCombo.String = ColorSpecEnum.getListboxStr();
    handles.majorGridLinesColorCombo.Value = ColorSpecEnum.getIndForName(profile.majorGridColor.name);
    
    handles.gridTypeCombo.String = ViewGridTypeEnum.getListBoxStr();
    handles.gridTypeCombo.Value = ViewGridTypeEnum.getIndForName(profile.gridType.name);
    
    handles.minorGridLinesColorCombo.String = ColorSpecEnum.getListboxStr();
    handles.minorGridLinesColorCombo.Value = ColorSpecEnum.getIndForName(profile.minorGridColor.name);
    
    handles.gridAlphaText.String = fullAccNum2Str(100*profile.gridTransparency);
    
    handles.evtsPlottingStyleCombo.String = ViewEventsTypeEnum.getListBoxStr();
    handles.evtsPlottingStyleCombo.Value = ViewEventsTypeEnum.getIndForName(profile.trajEvtsViewType.name);
    
    handles.trajViewFrameCombo.String = ReferenceFrameEnum.getListBoxStr();
    handles.trajViewFrameCombo.Value = ReferenceFrameEnum.getIndForName(profile.frame.typeEnum.name);
    handles.setFrameOptionsButton.TooltipString = sprintf('Current Frame: %s', profile.frame.getNameStr());
    
    [~, sortedBodyInfo] = ma_getSortedBodyNames(celBodyData);
    
    indsToSel = [];
    for(i=1:length(profile.bodiesToPlot))
        tf = cellfun(@(c) c == profile.bodiesToPlot(i), sortedBodyInfo);
        indsToSel(end+1) = find(tf,1,'first'); %#ok<AGROW>
    end
    handles.bodiesToPlotListbox.Value = indsToSel;
    
    handles.bodyPlottingStyleCombo.String = ViewProfileBodyPlottingStyle.getListBoxStr();
    handles.bodyPlottingStyleCombo.Value = ViewProfileBodyPlottingStyle.getIndForName(profile.bodyPlotStyle.name);
    
    handles.displayXAxisCheckbox.Value = double(profile.dispXAxis);
    handles.displayYAxisCheckbox.Value = double(profile.dispYAxis);
    handles.displayZAxisCheckbox.Value = double(profile.dispZAxis);
    
    handles.showThrustVectorsCheckbox.Value = double(profile.showThrustVectors);
    
    handles.thrustVectColorCombo.String = ColorSpecEnum.getListboxStr();
    handles.thrustVectColorCombo.Value = ColorSpecEnum.getIndForName(profile.thrustVectColor.name);
    
    handles.thrustVectLineStyleCombo.String = LineSpecEnum.getListboxStr();
    handles.thrustVectLineStyleCombo.Value = LineSpecEnum.getIndForName(profile.thrustVectLineType.name);
    
    handles.thrustVectScaleText.String = fullAccNum2Str(profile.thrustVectScale);
    handles.thrustVectIncrText.String = fullAccNum2Str(profile.thrustVectEntryIncr);
    
    handles.showSunLightingCheckbox.Value = double(profile.showLighting);
    handles.showSunVectorCheckbox.Value = double(profile.showSunVect);
    
    handles.showScBodyAxesCheckbox.Value = double(profile.showScBodyAxes);
    handles.scBodyAxesScaleText.String = fullAccNum2Str(profile.scBodyAxesScale);
    
    grdObjSet = viewSettings.lvdData.groundObjs;
    handles.grdObjsListbox.Value = grdObjSet.getIndsForGroundObjs(profile.groundObjsToPlot);
    handles.showGrdObjTrksCheckbox.Value = double(profile.showGndTracks);
    handles.showLoSToScCheckbox.Value = double(profile.showGrdObjLoS);

    handles.rendererCombo.String = FigureRendererEnum.getListboxStr();
    handles.rendererCombo.Value = FigureRendererEnum.getIndForName(profile.renderer.name);
    
    handles.meshEdgeAlphaText.String = fullAccNum2Str(100*profile.meshEdgeAlpha);
    
    handles.updateViewAxesCheckbox.Value = double(profile.updateViewAxesLimits);
    
    handles.showCbAtmo.Value = double(profile.showAtmosphere);
    
    geometry = viewSettings.lvdData.geometry;
    [plotPoints, ~] = geometry.points.getPlottablePoints();
    handles.pointsToPlotListbox.Value = find(ismember(plotPoints, profile.pointsToPlot));
    handles.vectorsToPlotListbox.Value = geometry.vectors.getIndsForVectors(profile.vectorsToPlot);
    handles.refFramessToPlotListbox.Value = geometry.refFrames.getIndsForRefFrames(profile.refFramesToPlot);
    handles.anglesToPlotListbox.Value = geometry.angles.getIndsForAngles(profile.anglesToPlot);
    handles.planesToPlotListbox.Value = geometry.planes.getIndsForPlanes(profile.planesToPlot);
    
    setDeleteButtonEnable(handles);


function profile = getSelectedProfile(handles)
    viewSettings = getappdata(handles.lvd_viewSettingsGUI,'viewSettings');
    
    ind = handles.viewProfilesListbox.Value;
    profile = viewSettings.getProfileAtInd(ind);
    
function setDeleteButtonEnable(handles)
    viewSettings = getappdata(handles.lvd_viewSettingsGUI,'viewSettings');
    numProfiles = viewSettings.getNumProfiles();
    
    if(numProfiles > 1)
        handles.removeViewProfileButton.Enable = 'on';
    else
        handles.removeViewProfileButton.Enable = 'off';
    end
    
    
    % --- Outputs from this function are returned to the command line.
function varargout = lvd_viewSettingsGUI_OutputFcn(hObject, eventdata, handles)
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        varargout{1} = true;
        close(handles.lvd_viewSettingsGUI);
    end
    
    
    % --- Executes on selection change in viewProfilesListbox.
function viewProfilesListbox_Callback(hObject, eventdata, handles)
    % hObject    handle to viewProfilesListbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns viewProfilesListbox contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from viewProfilesListbox
    profile = getSelectedProfile(handles);
    updateGuiForProfile(profile, handles);
    
    % --- Executes during object creation, after setting all properties.
function viewProfilesListbox_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to viewProfilesListbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: listbox controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on button press in addViewProfileButton.
function addViewProfileButton_Callback(hObject, eventdata, handles)
    % hObject    handle to addViewProfileButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    viewSettings = getappdata(handles.lvd_viewSettingsGUI,'viewSettings');
    newProfile = LaunchVehicleViewProfile();
%     newProfile.frame = BodyCenteredInertialFrame(viewSettings.lvdData.initialState.centralBody, viewSettings.lvdData.celBodyData);
    newProfile.frame = viewSettings.lvdData.initialState.centralBody.getBodyCenteredInertialFrame();
    viewSettings.addViewProfile(newProfile);
    
    handles.viewProfilesListbox.String = viewSettings.getListboxStr();
    
    handles.viewProfilesListbox.Value = viewSettings.getNumProfiles();
    updateGuiForProfile(newProfile, handles);
    setDeleteButtonEnable(handles);
    
    % --- Executes on button press in removeViewProfileButton.
function removeViewProfileButton_Callback(hObject, eventdata, handles)
    % hObject    handle to removeViewProfileButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    viewSettings = getappdata(handles.lvd_viewSettingsGUI,'viewSettings');
    
    profile = getSelectedProfile(handles);
    isActiveProfile = viewSettings.isProfileActive(profile);
    viewSettings.removeViewProfile(profile);
    numProfiles = viewSettings.getNumProfiles();
    
    handles.viewProfilesListbox.String = viewSettings.getListboxStr();
    
    if(handles.viewProfilesListbox.Value > numProfiles)
        handles.viewProfilesListbox.Value = numProfiles;
    end
    
    profile = getSelectedProfile(handles);
    if(isActiveProfile)
        viewSettings.setProfileAsActive(profile);
        handles.viewProfilesListbox.String = viewSettings.getListboxStr();
    end
    
    updateGuiForProfile(profile, handles);
    setDeleteButtonEnable(handles);
    
    % --- Executes on button press in moveViewProfileDownButton.
function moveViewProfileDownButton_Callback(hObject, eventdata, handles)
    % hObject    handle to moveViewProfileDownButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    viewSettings = getappdata(handles.lvd_viewSettingsGUI,'viewSettings');
    
    profileNum = get(handles.viewProfilesListbox,'Value');
    viewSettings.moveProfileAtIndexDown(profileNum);
    
    if(profileNum < viewSettings.getNumProfiles())
        set(handles.viewProfilesListbox,'Value',profileNum+1);
    end
    
    handles.viewProfilesListbox.String = viewSettings.getListboxStr();
    
    % --- Executes on button press in moveViewProfileUpButton.
function moveViewProfileUpButton_Callback(hObject, eventdata, handles)
    % hObject    handle to moveViewProfileUpButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    viewSettings = getappdata(handles.lvd_viewSettingsGUI,'viewSettings');
    
    profileNum = get(handles.viewProfilesListbox,'Value');
    viewSettings.moveProfileAtIndexUp(profileNum);
    
    if(profileNum > 1)
        set(handles.viewProfilesListbox,'Value',profileNum-1);
    end
    
    handles.viewProfilesListbox.String = viewSettings.getListboxStr();
    
    
function nameText_Callback(hObject, eventdata, handles)
    % hObject    handle to nameText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of nameText as text
    %        str2double(get(hObject,'String')) returns contents of nameText as a double
    profile = getSelectedProfile(handles);
    profile.name = get(hObject,'String');
    
    viewSettings = getappdata(handles.lvd_viewSettingsGUI,'viewSettings');
    handles.viewProfilesListbox.String = viewSettings.getListboxStr();
    
    % --- Executes during object creation, after setting all properties.
function nameText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to nameText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    
function profileDesc_Callback(hObject, eventdata, handles)
    % hObject    handle to profileDesc (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of profileDesc as text
    %        str2double(get(hObject,'String')) returns contents of profileDesc as a double
    profile = getSelectedProfile(handles);
    profile.desc = get(hObject,'String');
    
    % --- Executes during object creation, after setting all properties.
function profileDesc_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to profileDesc (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on selection change in axesBackgroundColorCombo.
function axesBackgroundColorCombo_Callback(hObject, eventdata, handles)
    % hObject    handle to axesBackgroundColorCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns axesBackgroundColorCombo contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from axesBackgroundColorCombo
    profile = getSelectedProfile(handles);
    
    contents = cellstr(get(hObject,'String'));
    str = contents{get(hObject,'Value')};
    
    profile.backgroundColor = ColorSpecEnum.getEnumForListboxStr(str);
    
    % --- Executes during object creation, after setting all properties.
function axesBackgroundColorCombo_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to axesBackgroundColorCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on selection change in majorGridLinesColorCombo.
function majorGridLinesColorCombo_Callback(hObject, eventdata, handles)
    % hObject    handle to majorGridLinesColorCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns majorGridLinesColorCombo contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from majorGridLinesColorCombo
    profile = getSelectedProfile(handles);
    
    contents = cellstr(get(hObject,'String'));
    str = contents{get(hObject,'Value')};
    
    profile.majorGridColor = ColorSpecEnum.getEnumForListboxStr(str);
    
    % --- Executes during object creation, after setting all properties.
function majorGridLinesColorCombo_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to majorGridLinesColorCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on selection change in minorGridLinesColorCombo.
function minorGridLinesColorCombo_Callback(hObject, eventdata, handles)
    % hObject    handle to minorGridLinesColorCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns minorGridLinesColorCombo contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from minorGridLinesColorCombo
    profile = getSelectedProfile(handles);
    
    contents = cellstr(get(hObject,'String'));
    str = contents{get(hObject,'Value')};
    
    profile.minorGridColor = ColorSpecEnum.getEnumForListboxStr(str);
    
    % --- Executes during object creation, after setting all properties.
function minorGridLinesColorCombo_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to minorGridLinesColorCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on selection change in gridTypeCombo.
function gridTypeCombo_Callback(hObject, eventdata, handles)
    % hObject    handle to gridTypeCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns gridTypeCombo contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from gridTypeCombo
    profile = getSelectedProfile(handles);
    
    contents = cellstr(get(hObject,'String'));
    str = contents{get(hObject,'Value')};
    
    profile.gridType = ViewGridTypeEnum.getEnumForListboxStr(str);
    
    % --- Executes during object creation, after setting all properties.
function gridTypeCombo_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to gridTypeCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    
function gridAlphaText_Callback(hObject, eventdata, handles)
    % hObject    handle to gridAlphaText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of gridAlphaText as text
    %        str2double(get(hObject,'String')) returns contents of gridAlphaText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    profile = getSelectedProfile(handles);
    
    errMsg = {};
    
    alpha = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Grid Transparency';
    lb = 0;
    ub = 100;
    isInt = false;
    errMsg = validateNumber(alpha, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        profile.gridTransparency = alpha/100;
    else
        hObject.String = fullAccNum2Str(profile.gridTransparency);
        
        msgbox(errMsg,'Invalid Grid Transparency Value','error');
    end
    
    
    
    % --- Executes during object creation, after setting all properties.
function gridAlphaText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to gridAlphaText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on selection change in evtsPlottingStyleCombo.
function evtsPlottingStyleCombo_Callback(hObject, eventdata, handles)
    % hObject    handle to evtsPlottingStyleCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns evtsPlottingStyleCombo contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from evtsPlottingStyleCombo
    profile = getSelectedProfile(handles);
    
    contents = cellstr(get(hObject,'String'));
    str = contents{get(hObject,'Value')};
    
    profile.trajEvtsViewType = ViewEventsTypeEnum.getEnumForListboxStr(str);
    
    % --- Executes during object creation, after setting all properties.
function evtsPlottingStyleCombo_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to evtsPlottingStyleCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on selection change in trajViewFrameCombo.
function trajViewFrameCombo_Callback(hObject, eventdata, handles)
    % hObject    handle to trajViewFrameCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns trajViewFrameCombo contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from trajViewFrameCombo
    viewSettings = getappdata(handles.lvd_viewSettingsGUI,'viewSettings');
    lvdData = viewSettings.lvdData;
    celBodyData = lvdData.celBodyData;
    
    profile = getSelectedProfile(handles);
    bodyInfo = profile.frame.getOriginBody();
    
    contents = cellstr(get(handles.trajViewFrameCombo,'String'));
    selFrameType = contents{get(handles.trajViewFrameCombo,'Value')};
    refFrameEnum = ReferenceFrameEnum.getEnumForListboxStr(selFrameType);
    
    switch refFrameEnum
        case ReferenceFrameEnum.BodyCenteredInertial
            newFrame = bodyInfo.getBodyCenteredInertialFrame();
            
        case ReferenceFrameEnum.BodyFixedRotating
            newFrame = bodyInfo.getBodyFixedFrame();
            
        case ReferenceFrameEnum.TwoBodyRotating
            if(not(isempty(bodyInfo.childrenBodyInfo)))
                primaryBody = bodyInfo;
                secondaryBody = bodyInfo.childrenBodyInfo(1);
            else
                primaryBody = bodyInfo.getParBodyInfo();
                secondaryBody = bodyInfo;
            end
            
            originPt = TwoBodyRotatingFrameOriginEnum.Primary;
            
            newFrame = TwoBodyRotatingFrame(primaryBody, secondaryBody, originPt, celBodyData);
            
        case ReferenceFrameEnum.UserDefined
            numFrames = lvdData.geometry.refFrames.getNumRefFrames();
            if(numFrames >= 1)
                geometricFrame = AbstractGeometricRefFrame.empty(1,0);
                for(i=1:numFrames)
                    frame = lvdData.geometry.refFrames.getRefFrameAtInd(i);
                    if(frame.isVehDependent() == false)
                        geometricFrame = frame;
                        break;
                    end
                end

                if(not(isempty(geometricFrame)))
                    newFrame = UserDefinedGeometricFrame(geometricFrame, lvdData);
                else
                    newFrame = bodyInfo.getBodyCenteredInertialFrame();

                    warndlg('There are no geometric frames available which are not dependent on vehicle properties.  A body-centered inertial frame will be selected instead.');
                end
            else
                bodyInfo = getSelectedBodyInfo(handles);
                newFrame = bodyInfo.getBodyCenteredInertialFrame();

                warndlg('There are no geometric frames available which are not dependent on vehicle properties.  A body-centered inertial frame will be selected instead.');
            end
            
        otherwise
            error('Unknown reference frame type: %s', string(refFrameEnum));
    end
    
    if(not(isempty(newFrame)) && newFrame.typeEnum ~= refFrameEnum)
        refFrameEnum = newFrame.typeEnum;
        handles.trajViewFrameCombo.Value = ReferenceFrameEnum.getIndForName(refFrameEnum.name);
    end
    
    profile.frame = newFrame;
    handles.setFrameOptionsButton.TooltipString = sprintf('Current Frame: %s', profile.frame.getNameStr()); 
    
    
    % --- Executes during object creation, after setting all properties.
function trajViewFrameCombo_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to trajViewFrameCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on button press in showSoICheckbox.
function showSoICheckbox_Callback(hObject, eventdata, handles)
    % hObject    handle to showSoICheckbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hint: get(hObject,'Value') returns toggle state of showSoICheckbox
    profile = getSelectedProfile(handles);
    profile.showSoIRadius = logical(get(hObject,'Value'));
        
    % --- Executes on button press in showFixedFrameGridCheckbox.
function showFixedFrameGridCheckbox_Callback(hObject, eventdata, handles)
    % hObject    handle to showFixedFrameGridCheckbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hint: get(hObject,'Value') returns toggle state of showFixedFrameGridCheckbox
    profile = getSelectedProfile(handles);
    profile.showLongLatAnnotations = logical(get(hObject,'Value'));
  
    
    % --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
    % hObject    handle to saveAndCloseButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    errMsg = {};
    if(isempty(errMsg))
        uiresume(handles.lvd_viewSettingsGUI);
    else
        msgbox(errMsg,'Errors were found while editing plugins.','error');
    end
    
    
    % --- Executes on button press in setAsActiveProfileCheckbox.
function setAsActiveProfileCheckbox_Callback(hObject, eventdata, handles)
    % hObject    handle to setAsActiveProfileCheckbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hint: get(hObject,'Value') returns toggle state of setAsActiveProfileCheckbox
    viewSettings = getappdata(handles.lvd_viewSettingsGUI,'viewSettings');
    profile = getSelectedProfile(handles);
    
    viewSettings.setProfileAsActive(profile);
    
    updateGuiForProfile(profile, handles);
    
    viewSettings = getappdata(handles.lvd_viewSettingsGUI,'viewSettings');
    handles.viewProfilesListbox.String = viewSettings.getListboxStr();
    
    
    % --- Executes on selection change in bodiesToPlotListbox.
function bodiesToPlotListbox_Callback(hObject, eventdata, handles)
    % hObject    handle to bodiesToPlotListbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns bodiesToPlotListbox contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from bodiesToPlotListbox
    viewSettings = getappdata(handles.lvd_viewSettingsGUI,'viewSettings');
    celBodyData = viewSettings.lvdData.celBodyData;
    [~, sortedBodyInfo] = ma_getSortedBodyNames(celBodyData);
    
    profile = getSelectedProfile(handles);
    
    inds = hObject.Value;
    if(not(isempty(inds)))
        profile.bodiesToPlot = [sortedBodyInfo{inds}];
    else
        profile.bodiesToPlot = KSPTOT_BodyInfo.empty(1,0);
    end
    
    % --- Executes during object creation, after setting all properties.
function bodiesToPlotListbox_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to bodiesToPlotListbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: listbox controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on button press in setFrameOptionsButton.
function setFrameOptionsButton_Callback(hObject, eventdata, handles)
    % hObject    handle to setFrameOptionsButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    profile = getSelectedProfile(handles);
    newFrame = profile.frame.editFrameDialogUI(EditReferenceFrameContextEnum.ForView);
    
    profile.frame = newFrame;
    handles.setFrameOptionsButton.TooltipString = sprintf('Current Frame: %s', profile.frame.getNameStr());


% --- Executes on selection change in bodyPlottingStyleCombo.
function bodyPlottingStyleCombo_Callback(hObject, eventdata, handles)
% hObject    handle to bodyPlottingStyleCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns bodyPlottingStyleCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from bodyPlottingStyleCombo
    profile = getSelectedProfile(handles);
    
    contents = cellstr(get(hObject,'String'));
    str = contents{get(hObject,'Value')};
    
    profile.bodyPlotStyle = ViewProfileBodyPlottingStyle.getEnumForListboxStr(str);

% --- Executes during object creation, after setting all properties.
function bodyPlottingStyleCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bodyPlottingStyleCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in displayXAxisCheckbox.
function displayXAxisCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to displayXAxisCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of displayXAxisCheckbox
    profile = getSelectedProfile(handles);
    profile.dispXAxis = logical(get(hObject,'Value'));

% --- Executes on button press in displayYAxisCheckbox.
function displayYAxisCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to displayYAxisCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of displayYAxisCheckbox
    profile = getSelectedProfile(handles);
    profile.dispYAxis = logical(get(hObject,'Value'));

% --- Executes on button press in displayZAxisCheckbox.
function displayZAxisCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to displayZAxisCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of displayZAxisCheckbox
    profile = getSelectedProfile(handles);
    profile.dispZAxis = logical(get(hObject,'Value'));


% --- Executes on button press in showThrustVectorsCheckbox.
function showThrustVectorsCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to showThrustVectorsCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showThrustVectorsCheckbox
    profile = getSelectedProfile(handles);
    profile.showThrustVectors = logical(get(hObject,'Value'));

% --- Executes on selection change in thrustVectColorCombo.
function thrustVectColorCombo_Callback(hObject, eventdata, handles)
% hObject    handle to thrustVectColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns thrustVectColorCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from thrustVectColorCombo
    profile = getSelectedProfile(handles);
    
    contents = cellstr(get(hObject,'String'));
    str = contents{get(hObject,'Value')};
    
    profile.thrustVectColor = ColorSpecEnum.getEnumForListboxStr(str);

% --- Executes during object creation, after setting all properties.
function thrustVectColorCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to thrustVectColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in thrustVectLineStyleCombo.
function thrustVectLineStyleCombo_Callback(hObject, eventdata, handles)
% hObject    handle to thrustVectLineStyleCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns thrustVectLineStyleCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from thrustVectLineStyleCombo
    profile = getSelectedProfile(handles);
    
    contents = cellstr(get(hObject,'String'));
    str = contents{get(hObject,'Value')};
    
    profile.thrustVectLineType = LineSpecEnum.getEnumForListboxStr(str);

% --- Executes during object creation, after setting all properties.
function thrustVectLineStyleCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to thrustVectLineStyleCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function thrustVectIncrText_Callback(hObject, eventdata, handles)
% hObject    handle to thrustVectIncrText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of thrustVectIncrText as text
%        str2double(get(hObject,'String')) returns contents of thrustVectIncrText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    profile = getSelectedProfile(handles);
    
    errMsg = {};
    
    incr = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Thrust Vector Data Point Incrememnt';
    lb = 1;
    ub = Inf;
    isInt = true;
    errMsg = validateNumber(incr, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        profile.thrustVectEntryIncr = incr;
    else
        hObject.String = fullAccNum2Str(profile.thrustVectEntryIncr);
        
        msgbox(errMsg,'Invalid Thrust Vector Data Point Incrememnt','error');
    end

% --- Executes during object creation, after setting all properties.
function thrustVectIncrText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to thrustVectIncrText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function thrustVectScaleText_Callback(hObject, eventdata, handles)
% hObject    handle to thrustVectScaleText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of thrustVectScaleText as text
%        str2double(get(hObject,'String')) returns contents of thrustVectScaleText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    profile = getSelectedProfile(handles);
    
    errMsg = {};
    
    scale = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Thrust Vector Scale Factor';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(scale, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        profile.thrustVectScale = scale;
    else
        hObject.String = fullAccNum2Str(profile.thrustVectScale);
        
        msgbox(errMsg,'Invalid Thrust Vector Scale Factor Value','error');
    end

% --- Executes during object creation, after setting all properties.
function thrustVectScaleText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to thrustVectScaleText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on lvd_viewSettingsGUI or any of its controls.
function lvd_viewSettingsGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_viewSettingsGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            saveAndCloseButton_Callback(handles.lvd_viewSettingsGUI, [], handles);
        case 'enter'
            saveAndCloseButton_Callback(handles.lvd_viewSettingsGUI, [], handles);
        case 'escape'
            close(handles.lvd_viewSettingsGUI);
    end


% --- Executes on button press in showSunVectorCheckbox.
function showSunVectorCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to showSunVectorCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showSunVectorCheckbox
    profile = getSelectedProfile(handles);
    profile.showSunVect = logical(get(hObject,'Value'));

% --- Executes on button press in showSunLightingCheckbox.
function showSunLightingCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to showSunLightingCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showSunLightingCheckbox
    profile = getSelectedProfile(handles);
    profile.showLighting = logical(get(hObject,'Value'));


% --- Executes on button press in showScBodyAxesCheckbox.
function showScBodyAxesCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to showScBodyAxesCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showScBodyAxesCheckbox
    profile = getSelectedProfile(handles);
    profile.showScBodyAxes = logical(get(hObject,'Value'));


function scBodyAxesScaleText_Callback(hObject, eventdata, handles)
% hObject    handle to scBodyAxesScaleText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of scBodyAxesScaleText as text
%        str2double(get(hObject,'String')) returns contents of scBodyAxesScaleText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    profile = getSelectedProfile(handles);
    
    errMsg = {};
    
    scale = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'S/C Body Axes Scale';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(scale, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        profile.scBodyAxesScale = scale;
    else
        hObject.String = fullAccNum2Str(profile.scBodyAxesScale);
        
        msgbox(errMsg,'Invalid S/C Body Axes Scale Value','error');
    end

% --- Executes during object creation, after setting all properties.
function scBodyAxesScaleText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scBodyAxesScaleText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in grdObjsListbox.
function grdObjsListbox_Callback(hObject, eventdata, handles)
% hObject    handle to grdObjsListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns grdObjsListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from grdObjsListbox
    viewSettings = getappdata(handles.lvd_viewSettingsGUI,'viewSettings');
    grdObjs = viewSettings.lvdData.groundObjs;

    profile = getSelectedProfile(handles);
    
    inds = hObject.Value;
    if(not(isempty(inds)))
        profile.groundObjsToPlot = grdObjs.getGroundObjsForInds(inds);
    else
        profile.groundObjsToPlot = LaunchVehicleGroundObject.empty(1,0);
    end

% --- Executes during object creation, after setting all properties.
function grdObjsListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to grdObjsListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in showGrdObjTrksCheckbox.
function showGrdObjTrksCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to showGrdObjTrksCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showGrdObjTrksCheckbox
    profile = getSelectedProfile(handles);
    profile.showGndTracks = logical(get(hObject,'Value'));


% --- Executes on button press in showLoSToScCheckbox.
function showLoSToScCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to showLoSToScCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showLoSToScCheckbox
    profile = getSelectedProfile(handles);
    profile.showGrdObjLoS = logical(get(hObject,'Value'));


% --- Executes on selection change in rendererCombo.
function rendererCombo_Callback(hObject, eventdata, handles)
% hObject    handle to rendererCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns rendererCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from rendererCombo
    profile = getSelectedProfile(handles);
    
    contents = cellstr(get(hObject,'String'));
    str = contents{get(hObject,'Value')};
    
    profile.renderer = FigureRendererEnum.getEnumForListboxStr(str);

% --- Executes during object creation, after setting all properties.
function rendererCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rendererCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function meshEdgeAlphaText_Callback(hObject, eventdata, handles)
% hObject    handle to meshEdgeAlphaText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of meshEdgeAlphaText as text
%        str2double(get(hObject,'String')) returns contents of meshEdgeAlphaText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    profile = getSelectedProfile(handles);
    
    errMsg = {};
    
    alpha = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Mesh Edge Transparency';
    lb = 0;
    ub = 100;
    isInt = false;
    errMsg = validateNumber(alpha, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        profile.meshEdgeAlpha = alpha/100;
    else
        hObject.String = fullAccNum2Str(profile.meshEdgeAlpha);
        
        msgbox(errMsg,'Invalid Mesh Edge Transparency Value','error');
    end

% --- Executes during object creation, after setting all properties.
function meshEdgeAlphaText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to meshEdgeAlphaText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in updateViewAxesCheckbox.
function updateViewAxesCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to updateViewAxesCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of updateViewAxesCheckbox
    profile = getSelectedProfile(handles);
    
    profile.updateViewAxesLimits = logical(get(hObject,'Value'));


% --- Executes on button press in showCbAtmo.
function showCbAtmo_Callback(hObject, eventdata, handles)
% hObject    handle to showCbAtmo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showCbAtmo
    profile = getSelectedProfile(handles);
    profile.showAtmosphere = logical(get(hObject,'Value'));


% --- Executes on selection change in pointsToPlotListbox.
function pointsToPlotListbox_Callback(hObject, eventdata, handles)
% hObject    handle to pointsToPlotListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pointsToPlotListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pointsToPlotListbox
    viewSettings = getappdata(handles.lvd_viewSettingsGUI,'viewSettings');
    pointSet = viewSettings.lvdData.geometry.points;

    profile = getSelectedProfile(handles);
    
    inds = hObject.Value;
    if(not(isempty(inds)))
        [plotPoints, ~] = pointSet.getPlottablePoints();
        profile.pointsToPlot = plotPoints(inds);
    else
        profile.pointsToPlot = AbstractGeometricPoint.empty(1,0);
    end


% --- Executes during object creation, after setting all properties.
function pointsToPlotListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pointsToPlotListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in vectorsToPlotListbox.
function vectorsToPlotListbox_Callback(hObject, eventdata, handles)
% hObject    handle to vectorsToPlotListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns vectorsToPlotListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from vectorsToPlotListbox
    viewSettings = getappdata(handles.lvd_viewSettingsGUI,'viewSettings');
    vectorSet = viewSettings.lvdData.geometry.vectors;

    profile = getSelectedProfile(handles);
    
    inds = hObject.Value;
    if(not(isempty(inds)))
        profile.vectorsToPlot = vectorSet.getVectorsForInds(inds);
    else
        profile.vectorsToPlot = AbstractGeometricVector.empty(1,0);
    end

% --- Executes during object creation, after setting all properties.
function vectorsToPlotListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vectorsToPlotListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in refFramessToPlotListbox.
function refFramessToPlotListbox_Callback(hObject, eventdata, handles)
% hObject    handle to refFramessToPlotListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns refFramessToPlotListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from refFramessToPlotListbox
    viewSettings = getappdata(handles.lvd_viewSettingsGUI,'viewSettings');
    refFrameSet = viewSettings.lvdData.geometry.refFrames;

    profile = getSelectedProfile(handles);
    
    inds = hObject.Value;
    if(not(isempty(inds)))
        profile.refFramesToPlot = refFrameSet.getRefFramesForInds(inds);
    else
        profile.refFramesToPlot = AbstractGeometricRefFrame.empty(1,0);
    end

% --- Executes during object creation, after setting all properties.
function refFramessToPlotListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to refFramessToPlotListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in anglesToPlotListbox.
function anglesToPlotListbox_Callback(hObject, eventdata, handles)
% hObject    handle to anglesToPlotListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns anglesToPlotListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from anglesToPlotListbox
    viewSettings = getappdata(handles.lvd_viewSettingsGUI,'viewSettings');
    angleSet = viewSettings.lvdData.geometry.angles;

    profile = getSelectedProfile(handles);
    
    inds = hObject.Value;
    if(not(isempty(inds)))
        profile.anglesToPlot = angleSet.getAnglesForInds(inds);
    else
        profile.anglesToPlot = AbstractGeometricAngle.empty(1,0);
    end

% --- Executes during object creation, after setting all properties.
function anglesToPlotListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to anglesToPlotListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in planesToPlotListbox.
function planesToPlotListbox_Callback(hObject, eventdata, handles)
% hObject    handle to planesToPlotListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns planesToPlotListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from planesToPlotListbox
    viewSettings = getappdata(handles.lvd_viewSettingsGUI,'viewSettings');
    planeSet = viewSettings.lvdData.geometry.planes;

    profile = getSelectedProfile(handles);
    
    inds = hObject.Value;
    if(not(isempty(inds)))
        profile.planesToPlot = planeSet.getPlanesForInds(inds);
    else
        profile.planesToPlot = AbstractGeometricPlane.empty(1,0);
    end

% --- Executes during object creation, after setting all properties.
function planesToPlotListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to planesToPlotListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
