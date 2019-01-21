function varargout = ma_InsertStateGUI(varargin)
% MA_INSERTSTATEGUI MATLAB code for ma_InsertStateGUI.fig
%      MA_INSERTSTATEGUI, by itself, creates a new MA_INSERTSTATEGUI or raises the existing
%      singleton*.
%
%      H = MA_INSERTSTATEGUI returns the handle to a new MA_INSERTSTATEGUI or the handle to
%      the existing singleton*.
%
%      MA_INSERTSTATEGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_INSERTSTATEGUI.M with the given input arguments.
%
%      MA_INSERTSTATEGUI('Property','Value',...) creates a new MA_INSERTSTATEGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_InsertStateGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_InsertStateGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_InsertStateGUI

% Last Modified by GUIDE v2.5 20-Jan-2019 16:44:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_InsertStateGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_InsertStateGUI_OutputFcn, ...
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


% --- Executes just before ma_InsertStateGUI is made visible.
function ma_InsertStateGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_InsertStateGUI (see VARARGIN)

% Choose default command line output for ma_InsertStateGUI
handles.output = hObject;
handles.ma_MainGUI = varargin{1};
handles.ksptotMainGUI = varargin{2};

% Update handles structure
guidata(hObject, handles);

%GUI setup
setResourceLabelStrings(handles);
populateBodiesCombo(getappdata(handles.ma_MainGUI,'celBodyData'), handles.bodiesCombo);
populateBodiesCombo(getappdata(handles.ma_MainGUI,'celBodyData'), handles.launchBodiesCombo);
initStateTypeBtnGrp_SelectionChangedFcn(handles.setStateRadioBtn, [], handles);

if(length(varargin) > 2) 
    if(length(varargin) > 3)
        initialState = varargin{4};
    else
        initialState = [];
    end
    setappdata(hObject,'initialState', initialState);
    
    event = varargin{3};
    if(~isempty(event))
        populateGUIWithEvent(handles, event);
    end
end

% UIWAIT makes ma_InsertStateGUI wait for user response (see UIRESUME)
uiwait(handles.ma_InsertStateGUI);

function setResourceLabelStrings(handles)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    names = maData.spacecraft.propellant.names;
    
    set(handles.resource1Label,'String',names{1});
    set(handles.resource2Label,'String',names{2});
    set(handles.resource3Label,'String',names{3});

function populateGUIWithEvent(handles, event)
    set(handles.titleLabel, 'String', 'Edit State');
    set(handles.ma_InsertStateGUI, 'Name', 'Edit State');
    set(handles.stateNameText, 'String', event.name);
    
    if(strcmpi(event.subType,'setState'))
        handles.initStateTypeBtnGrp.SelectedObject = handles.setStateRadioBtn;
    elseif(strcmpi(event.subType,'estLaunch'))
        handles.initStateTypeBtnGrp.SelectedObject = handles.estLaunchRadioBtn;
    end
    initStateTypeBtnGrp_SelectionChangedFcn(handles.initStateTypeBtnGrp.SelectedObject, [], handles);
    
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Set State Directly
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    bodyValue = findValueFromComboBox(event.centralBody.name, handles.bodiesCombo);
    set(handles.bodiesCombo, 'value', bodyValue);
    
    set(handles.epochText, 'String', fullAccNum2Str(event.epoch));
    rVect = event.rVect;
    vVect = event.vVect;
    gmu = event.centralBody.gm;
    [sma, ecc, inc, raan, arg, tru] = getKeplerFromState(rVect,vVect,gmu);
    
    set(handles.smaText, 'String', fullAccNum2Str(sma));
    set(handles.eccText, 'String', fullAccNum2Str(ecc));
    set(handles.incText, 'String', fullAccNum2Str(rad2deg(inc)));
    set(handles.raanText, 'String', fullAccNum2Str(rad2deg(raan)));
    set(handles.argText, 'String', fullAccNum2Str(rad2deg(arg)));
    set(handles.truText, 'String', fullAccNum2Str(rad2deg(tru)));
    
    set(handles.dryMassText, 'String', fullAccNum2Str(event.dryMass));
    set(handles.fuelOxMassText, 'String', fullAccNum2Str(event.fuelOxMass));
    set(handles.monopropMassText, 'String', fullAccNum2Str(event.monoMass));
    set(handles.xenonMassText, 'String', fullAccNum2Str(event.xenonMass));  
    
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Estimate Launch
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    bodyValue = findValueFromComboBox(event.centralBody.name, handles.launchBodiesCombo);
    set(handles.launchBodiesCombo, 'value', bodyValue);    
       
    if(isfield(event, 'launch') && ~isempty(event.launch))
        colorStr = getStringFromLineSpecColor(event.launch.lineColor);
        colorValue = findValueFromComboBox(colorStr, handles.launchTrajectoryColorCombo);
        set(handles.launchTrajectoryColorCombo,'value',colorValue);
        
        styleStr = getLineStyleFromString(event.launch.lineStyle);
        styleValue = findValueFromComboBox(styleStr, handles.stateLineStyleCombo);
        set(handles.stateLineStyleCombo,'Value',styleValue);
        
        contents = handles.lineWidthCombo.String;
        contentsDouble = str2double(contents);
        ind = find(contentsDouble == event.launch.lineWidth);
        set(handles.lineWidthCombo,'Value',ind);
               
        set(handles.launchEpochText, 'String', fullAccNum2Str(event.launch.launchValue(1)));
        set(handles.launchLatText, 'String', fullAccNum2Str(rad2deg(event.launch.launchValue(2))));
        set(handles.launchLongText, 'String', fullAccNum2Str(rad2deg(event.launch.launchValue(3))));
        set(handles.launchAltText, 'String', fullAccNum2Str(event.launch.launchValue(4)));
        set(handles.launchToFText, 'String', fullAccNum2Str(event.launch.launchValue(5)));
        set(handles.launchBurnoutLatText, 'String', fullAccNum2Str(rad2deg(event.launch.launchValue(6))));
        set(handles.launchBurnoutLongText, 'String', fullAccNum2Str(rad2deg(event.launch.launchValue(7))));
        set(handles.launchBurnoutAltText, 'String', fullAccNum2Str(event.launch.launchValue(8)));
        
        if(strcmpi(event.subType,'estLaunch'))
            set(handles.launchEpochLwrBndText, 'String', fullAccNum2Str(event.vars(2,1)));
            set(handles.launchLatLrwBndText, 'String', fullAccNum2Str(rad2deg(event.vars(2,2))));
            set(handles.launchLongLrwBndText, 'String', fullAccNum2Str(rad2deg(event.vars(2,3))));
            set(handles.launchAltLrwBndText, 'String', fullAccNum2Str(event.vars(2,4)));
            set(handles.launchToFLwrBndText, 'String', fullAccNum2Str(event.vars(2,5)));
            set(handles.launchBurnoutLatLwrBndText, 'String', fullAccNum2Str(rad2deg(event.vars(2,6))));
            set(handles.launchBurnoutLongLwrBndText, 'String', fullAccNum2Str(rad2deg(event.vars(2,7))));
            set(handles.launchBurnoutAltLwrBndText, 'String', fullAccNum2Str(event.vars(2,8)));

            set(handles.launchEpochUprBndText, 'String', fullAccNum2Str(event.vars(3,1)));
            set(handles.launchLatUprBndText, 'String', fullAccNum2Str(rad2deg(event.vars(3,2))));
            set(handles.launchLongUprBndText, 'String', fullAccNum2Str(rad2deg(event.vars(3,3))));
            set(handles.launchAltUprBndText, 'String', fullAccNum2Str(event.vars(3,4)));
            set(handles.launchToFUprBndText, 'String', fullAccNum2Str(event.vars(3,5)));
            set(handles.launchBurnoutLatUprBndText, 'String', fullAccNum2Str(rad2deg(event.vars(3,6))));
            set(handles.launchBurnoutLongUprBndText, 'String', fullAccNum2Str(rad2deg(event.vars(3,7))));
            set(handles.launchBurnoutAltUprBndText, 'String', fullAccNum2Str(event.vars(3,8)));

            set(handles.launchEpochOptCheckbox,'Value',event.vars(1,1));
            set(handles.launchLatOptCheckbox,'Value',event.vars(1,2));
            set(handles.launchLongOptCheckbox,'Value',event.vars(1,3));
            set(handles.launchAltCheckbox,'Value',event.vars(1,4));
            set(handles.launchToFOptCheckbox,'Value',event.vars(1,5));
            set(handles.launchBurnoutLatOptCheckbox,'Value',event.vars(1,6));
            set(handles.launchBurnoutLongOptCheckbox,'Value',event.vars(1,7));
            set(handles.launchBurnoutAltOptCheckbox,'Value',event.vars(1,8));
        elseif(strcmpi(event.subType,'setState'))
            set(handles.epochLwrBndText, 'String', fullAccNum2Str(event.vars(2,1)));
            set(handles.smaLwrBndText, 'String', fullAccNum2Str(event.vars(2,2)));
            set(handles.eccLwrBndText, 'String', fullAccNum2Str(event.vars(2,3)));
            set(handles.incLwrBndText, 'String', fullAccNum2Str(rad2deg(event.vars(2,4))));
            set(handles.raanLwrBndText, 'String', fullAccNum2Str(rad2deg(event.vars(2,5))));
            set(handles.argLwrBndText, 'String', fullAccNum2Str(rad2deg(event.vars(2,6))));
            set(handles.truLwrBndText, 'String', fullAccNum2Str(rad2deg(event.vars(2,7))));

            set(handles.epochUprBndText, 'String', fullAccNum2Str(event.vars(3,1)));
            set(handles.smaUprBndText, 'String', fullAccNum2Str(event.vars(3,2)));
            set(handles.eccUprBndText, 'String', fullAccNum2Str(event.vars(3,3)));
            set(handles.incUprBndText, 'String', fullAccNum2Str(rad2deg(event.vars(3,4))));
            set(handles.raanUprBndText, 'String', fullAccNum2Str(rad2deg(event.vars(3,5))));
            set(handles.argUprBndText, 'String', fullAccNum2Str(rad2deg(event.vars(3,6))));
            set(handles.truUprBndText, 'String', fullAccNum2Str(rad2deg(event.vars(3,7))));

            set(handles.epochOptCheckbox,'Value',event.vars(1,1));
            set(handles.smaOptCheckbox,'Value',event.vars(1,2));
            set(handles.eccOptCheckbox,'Value',event.vars(1,3));
            set(handles.incOptCheckbox,'Value',event.vars(1,4));
            set(handles.raanOptCheckbox,'Value',event.vars(1,5));
            set(handles.argOptCheckbox,'Value',event.vars(1,6));
            set(handles.truOptCheckbox,'Value',event.vars(1,7));            
        end
        if(strcmpi(event.subType,'estLaunch'))
            launchEpochOptCheckbox_Callback(handles.launchEpochOptCheckbox, [], handles);
            launchLatOptCheckbox_Callback(handles.launchLatOptCheckbox, [], handles);
            launchLongOptCheckbox_Callback(handles.launchLongOptCheckbox, [], handles);
            launchAltCheckbox_Callback(handles.launchAltCheckbox, [], handles);

            launchToFOptCheckbox_Callback(handles.launchToFOptCheckbox, [], handles);
            launchBurnoutLatOptCheckbox_Callback(handles.launchBurnoutLatOptCheckbox, [], handles);
            launchBurnoutLongOptCheckbox_Callback(handles.launchBurnoutLongOptCheckbox, [], handles);
            launchBurnoutAltOptCheckbox_Callback(handles.launchBurnoutAltOptCheckbox, [], handles);
        elseif(strcmpi(event.subType,'setState'))
            epochOptCheckbox_Callback(handles.epochOptCheckbox, [], handles);
            smaOptCheckbox_Callback(handles.smaOptCheckbox, [], handles);
            eccOptCheckbox_Callback(handles.eccOptCheckbox, [], handles);
            incOptCheckbox_Callback(handles.incOptCheckbox, [], handles);
            raanOptCheckbox_Callback(handles.raanOptCheckbox, [], handles);
            argOptCheckbox_Callback(handles.argOptCheckbox, [], handles);
            truOptCheckbox_Callback(handles.truOptCheckbox, [], handles);
        end
    end
    
    initialState = getappdata(handles.ma_InsertStateGUI,'initialState');

    if(~isempty(initialState))
        ut = initialState(1);
        rVect = initialState(2:4)';
        vVect = initialState(5:7)';
        bodyID = initialState(8);
        dryMass = initialState(9);
        fuelOxMass = initialState(10);
        monoMass = initialState(11);
        xenonMass = initialState(12);
        
        celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
        bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
        
        bodyValue = findValueFromComboBox(bodyInfo.name, handles.bodiesCombo);
        set(handles.bodiesCombo, 'value', bodyValue);
        set(handles.launchBodiesCombo, 'value', bodyValue);  
        
        [lat, long, alt, ~, ~, ~] = getLatLongAltFromInertialVect(ut, rVect, bodyInfo, vVect);
        
        set(handles.launchEpochText, 'String', fullAccNum2Str(ut));
        set(handles.launchLatText, 'String', fullAccNum2Str(rad2deg(lat)));
        set(handles.launchLongText, 'String', fullAccNum2Str(rad2deg(long)));
        set(handles.launchAltText, 'String', fullAccNum2Str(alt));
        
        set(handles.launchEpochLwrBndText, 'String', fullAccNum2Str(ut));
        set(handles.launchLatLrwBndText, 'String', fullAccNum2Str(rad2deg(lat)));
        set(handles.launchLongLrwBndText, 'String', fullAccNum2Str(rad2deg(long)));
        set(handles.launchAltLrwBndText, 'String', fullAccNum2Str(alt));

        set(handles.launchEpochUprBndText, 'String', fullAccNum2Str(ut));
        set(handles.launchLatUprBndText, 'String', fullAccNum2Str(rad2deg(lat)));
        set(handles.launchLongUprBndText, 'String', fullAccNum2Str(rad2deg(long)));
        set(handles.launchAltUprBndText, 'String', fullAccNum2Str(alt));

        set(handles.launchEpochOptCheckbox,'Value',false);
        set(handles.launchLatOptCheckbox,'Value',false);
        set(handles.launchLongOptCheckbox,'Value',false);
        set(handles.launchAltCheckbox,'Value',false);
        
        set(handles.dryMassText,'String',fullAccNum2Str(dryMass));
        set(handles.fuelOxMassText,'String',fullAccNum2Str(fuelOxMass));
        set(handles.monopropMassText,'String',fullAccNum2Str(monoMass));
        set(handles.xenonMassText,'String',fullAccNum2Str(xenonMass));
    end
    
    if(isfield(event, 'launch') && ~isempty(event.launch))
        computeAzIncRaanForLaunch(handles);
    end
    
    
% --- Outputs from this function are returned to the command line.
function varargout = ma_InsertStateGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if(isempty(handles))
    varargout{1} = [];
else
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    name = get(handles.stateNameText, 'String');
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Set State Directly
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    contents = cellstr(get(handles.bodiesCombo,'String'));
    selected = strtrim(contents{get(handles.bodiesCombo,'Value')});
    bodyInfoSetState = celBodyData.(lower(selected));
    
    epoch = str2double(get(handles.epochText,'String'));
    sma = str2double(get(handles.smaText,'String'));
    ecc = str2double(get(handles.eccText,'String'));
    inc = deg2rad(str2double(get(handles.incText,'String')));
    raan = deg2rad(str2double(get(handles.raanText,'String')));
    arg = deg2rad(str2double(get(handles.argText,'String')));
    tru = deg2rad(str2double(get(handles.truText,'String')));
    
    if(ecc >= 1)
        parentBodyInfo = getParentBodyInfo(bodyInfoSetState, celBodyData);
        rSOI = getSOIRadius(bodyInfoSetState, parentBodyInfo);
        maxTru = computeTrueAFromRadiusEcc(rSOI - 1, sma, ecc);
        
        if(tru > maxTru)
            tru = maxTru;
        elseif(tru < -maxTru)
            tru = -maxTru;
        end
    end
    
    dryMass = str2double(get(handles.dryMassText,'String'));
    fuelOxMass = str2double(get(handles.fuelOxMassText,'String'));
    monoMass = str2double(get(handles.monopropMassText,'String'));
    xenonMass = str2double(get(handles.xenonMassText,'String'));
    
    ssVars = createSetStateVars(handles);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Estimate Launch
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [launch, lVars] = createLaunchEvent(handles, name);
    contents = cellstr(get(handles.launchBodiesCombo,'String'));
    selected = strtrim(contents{get(handles.launchBodiesCombo,'Value')});
    bodyInfoEstLaunch = celBodyData.(lower(selected));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Determine Subtype
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if(strcmpi(handles.initStateTypeBtnGrp.SelectedObject.Tag, 'setStateRadioBtn'))
        subType = 'setState';
        vars = ssVars;
        bodyInfo = bodyInfoSetState;
    elseif(strcmpi(handles.initStateTypeBtnGrp.SelectedObject.Tag, 'estLaunchRadioBtn'))
        subType = 'estLaunch';
        vars = lVars;
        bodyInfo = bodyInfoEstLaunch;
    end
        
    varargout{1} = ma_createSetState(name, epoch, sma, ecc, inc, raan, arg, tru, bodyInfo, dryMass, fuelOxMass, monoMass, xenonMass, subType, launch, vars);
    close(handles.ma_InsertStateGUI);
end

function vars = createSetStateVars(handles)
    vars(1,1) = get(handles.epochOptCheckbox,'value');
    vars(1,2) = get(handles.smaOptCheckbox,'value');
    vars(1,3) = get(handles.eccOptCheckbox,'value');
    vars(1,4) = get(handles.incOptCheckbox,'value');
    vars(1,5) = get(handles.raanOptCheckbox,'value');
    vars(1,6) = get(handles.argOptCheckbox,'value');
    vars(1,7) = get(handles.truOptCheckbox,'value');
    
    vars(2,1) = str2double(get(handles.epochLwrBndText,'String'));
    vars(2,2) = str2double(get(handles.smaLwrBndText,'String'));
    vars(2,3) = str2double(get(handles.eccLwrBndText,'String'));
    vars(2,4) = deg2rad(str2double(get(handles.incLwrBndText,'String')));
    vars(2,5) = deg2rad(str2double(get(handles.raanLwrBndText,'String')));
    vars(2,6) = deg2rad(str2double(get(handles.argLwrBndText,'String')));
    vars(2,7) = deg2rad(str2double(get(handles.truLwrBndText,'String')));
    
    vars(3,1) = str2double(get(handles.epochUprBndText,'String'));
    vars(3,2) = str2double(get(handles.smaUprBndText,'String'));
    vars(3,3) = str2double(get(handles.eccUprBndText,'String'));
    vars(3,4) = deg2rad(str2double(get(handles.incUprBndText,'String')));
    vars(3,5) = deg2rad(str2double(get(handles.raanUprBndText,'String')));
    vars(3,6) = deg2rad(str2double(get(handles.argUprBndText,'String')));
    vars(3,7) = deg2rad(str2double(get(handles.truUprBndText,'String')));

function [launch, vars] = createLaunchEvent(handles, name)
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');

    contents = cellstr(get(handles.launchBodiesCombo,'String'));
    selected = strtrim(contents{get(handles.launchBodiesCombo,'Value')});
    bodyInfo = celBodyData.(lower(selected));
    
    launchEpoch = str2double(get(handles.launchEpochText,'String'));
    launchLat = deg2rad(str2double(get(handles.launchLatText,'String')));
    launchLong = deg2rad(str2double(get(handles.launchLongText,'String')));
    launchAlt = str2double(get(handles.launchAltText,'String'));
    
    launchToF = str2double(get(handles.launchToFText,'String'));
    burnoutLat = deg2rad(str2double(get(handles.launchBurnoutLatText,'String')));
    burnoutLong = deg2rad(str2double(get(handles.launchBurnoutLongText,'String')));
    burnoutAlt = str2double(get(handles.launchBurnoutAltText,'String'));
    
    vars(1,1) = get(handles.launchEpochOptCheckbox,'value');
    vars(1,2) = get(handles.launchLatOptCheckbox,'value');
    vars(1,3) = get(handles.launchLongOptCheckbox,'value');
    vars(1,4) = get(handles.launchAltCheckbox,'value');
    vars(1,5) = get(handles.launchToFOptCheckbox,'value');
    vars(1,6) = get(handles.launchBurnoutLatOptCheckbox,'value');
    vars(1,7) = get(handles.launchBurnoutLongOptCheckbox,'value');
    vars(1,8) = get(handles.launchBurnoutAltOptCheckbox,'value');
    
    vars(2,1) = str2double(get(handles.launchEpochLwrBndText,'String'));
    vars(2,2) = deg2rad(str2double(get(handles.launchLatLrwBndText,'String')));
    vars(2,3) = deg2rad(str2double(get(handles.launchLongLrwBndText,'String')));
    vars(2,4) = str2double(get(handles.launchAltLrwBndText,'String'));
    vars(2,5) = str2double(get(handles.launchToFLwrBndText,'String'));
    vars(2,6) = deg2rad(str2double(get(handles.launchBurnoutLatLwrBndText,'String')));
    vars(2,7) = deg2rad(str2double(get(handles.launchBurnoutLongLwrBndText,'String')));
    vars(2,8) = str2double(get(handles.launchBurnoutAltLwrBndText,'String'));
    
    vars(3,1) = str2double(get(handles.launchEpochUprBndText,'String'));
    vars(3,2) = deg2rad(str2double(get(handles.launchLatUprBndText,'String')));
    vars(3,3) = deg2rad(str2double(get(handles.launchLongUprBndText,'String')));
    vars(3,4) = str2double(get(handles.launchAltUprBndText,'String'));
    vars(3,5) = str2double(get(handles.launchToFUprBndText,'String'));
    vars(3,6) = deg2rad(str2double(get(handles.launchBurnoutLatUprBndText,'String')));
    vars(3,7) = deg2rad(str2double(get(handles.launchBurnoutLongUprBndText,'String')));
    vars(3,8) = str2double(get(handles.launchBurnoutAltUprBndText,'String'));
    
    contents = cellstr(get(handles.launchTrajectoryColorCombo,'String'));
	colorStr = contents{get(handles.launchTrajectoryColorCombo,'Value')};
    lineColor = getLineSpecColorFromString(colorStr);
    
    contents = cellstr(get(handles.stateLineStyleCombo,'String'));
    lineStyleStr = contents{get(handles.stateLineStyleCombo,'Value')};
    lineStyle = getLineStyleStrFromText(lineStyleStr);
    
    contents = handles.lineWidthCombo.String;
    contentsDouble = str2double(contents);
    contensInd = get(handles.lineWidthCombo,'Value');
    lineWidth = contentsDouble(contensInd);
    
    launch = ma_createLaunch(name, launchEpoch, launchLat, launchLong, launchAlt, ...
                                    launchToF, burnoutLat, burnoutLong, burnoutAlt, ...
                                    lineColor, lineStyle, lineWidth, bodyInfo.id);

                                
function [errMsg, basicLaunchCheckPassed] = validateInputs(handles)
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
       
    errMsg = {};

    basicLaunchCheckPassed = false;
    if(strcmpi(handles.initStateTypeBtnGrp.SelectedObject.Tag, 'setStateRadioBtn'))
        contents = cellstr(get(handles.bodiesCombo,'String'));
        selected = strtrim(contents{get(handles.bodiesCombo,'Value')});
        bodyInfo = celBodyData.(lower(selected));
        
        parentBodyInfo = getParentBodyInfo(bodyInfo, celBodyData);
        soiRadius = getSOIRadius(bodyInfo, parentBodyInfo);
        
        eEcc = str2double(get(handles.eccText,'String'));
        enteredStr = get(handles.eccText,'String');
        numberName = 'Orbit Eccentricity';
        lb = 0;
        ub = Inf;
        isInt = false;
        errMsg = validateNumber(eEcc, numberName, lb, ub, isInt, errMsg, enteredStr);

        if(not(isempty(errMsg))) 
            %msgbox(errMsg,'Errors were found while inserting a state.','error');
            return;
        end

        epoch = str2double(get(handles.epochText,'String'));
        enteredStr = get(handles.epochText,'String');
        numberName = 'Orbit Epoch';
        lb = 0;
        ub = Inf;
        isInt = false;
        errMsg = validateNumber(epoch, numberName, lb, ub, isInt, errMsg, enteredStr);

        eSMA = str2double(get(handles.smaText,'String'));
        enteredStr = get(handles.smaText,'String');
        if(eEcc < 1.0)
            lb = 1;
            ub = Inf;
            numberName = 'Eccentric Orbit Semi-Major Axis';
            isHyperbolic = false;            
        else
            lb = -Inf;
            ub = -1;
            numberName = 'Hyperbolic Orbit Semi-Major Axis';
            isHyperbolic = true;
        end
        isInt = false;
        errMsg = validateNumber(eSMA, numberName, lb, ub, isInt, errMsg, enteredStr);

        eInc = str2double(get(handles.incText,'String'));
        enteredStr = get(handles.incText,'String');
        numberName = 'Orbit Inclination';
        lb = 0;
        ub = 180;
        isInt = false;
        errMsg = validateNumber(eInc, numberName, lb, ub, isInt, errMsg, enteredStr);

        eRAAN = str2double(get(handles.raanText,'String'));
        enteredStr = get(handles.raanText,'String');
        numberName = 'Orbit RAAN';
        lb = -180;
        ub = 360;
        isInt = false;
        errMsg = validateNumber(eRAAN, numberName, lb, ub, isInt, errMsg, enteredStr);

        eArg = str2double(get(handles.argText,'String'));
        enteredStr = get(handles.argText,'String');
        numberName = 'Orbit Argument of Periapse';
        lb = -180;
        ub = 360;
        isInt = false;
        errMsg = validateNumber(eArg, numberName, lb, ub, isInt, errMsg, enteredStr);

        eTru = str2double(get(handles.truText,'String'));
        enteredStr = get(handles.truText,'String');
        numberName = 'Orbit True Anomaly';
        lb = -180;
        ub = 360;
        isInt = false;
        errMsg = validateNumber(eTru, numberName, lb, ub, isInt, errMsg, enteredStr);       
        
        if(isempty(errMsg))
            if(handles.epochOptCheckbox.Value == true)
                value = str2double(get(handles.epochLwrBndText,'String'));
                enteredStr = get(handles.epochLwrBndText,'String');
                numberName = 'Orbit Epoch Lower Bound';
                lb = 0;
                ub = str2double(get(handles.epochText,'String'));
                isInt = false;
                errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);

                value = str2double(get(handles.epochUprBndText,'String'));
                enteredStr = get(handles.epochUprBndText,'String');
                numberName = 'Orbit Epoch Upper Bound';
                lb = str2double(get(handles.epochText,'String'));
                ub = Inf;
                isInt = false;
                errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
%             if(handles.smaOptCheckbox.Value == true)
%                 value = str2double(get(handles.smaLwrBndText,'String'));
%                 enteredStr = get(handles.smaLwrBndText,'String');
%                 numberName = 'Orbit SMA Lower Bound';
%                 lb = -Inf;
%                 ub = str2double(get(handles.smaText,'String'));
%                 isInt = false;
%                 errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
% 
%                 value = str2double(get(handles.smaUprBndText,'String'));
%                 enteredStr = get(handles.smaUprBndText,'String');
%                 numberName = 'Orbit SMA Upper Bound';
%                 lb = str2double(get(handles.smaText,'String'));
%                 ub = Inf;
%                 isInt = false;
%                 errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
%             end
            
%             if(handles.eccOptCheckbox.Value == true)
%                 value = str2double(get(handles.eccLwrBndText,'String'));
%                 enteredStr = get(handles.eccLwrBndText,'String');
%                 numberName = 'Orbit Eccentricity Lower Bound';
%                 lb = 0;
%                 ub = str2double(get(handles.eccText,'String'));
%                 isInt = false;
%                 errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
% 
%                 value = str2double(get(handles.eccUprBndText,'String'));
%                 enteredStr = get(handles.eccUprBndText,'String');
%                 numberName = 'Orbit Eccentricity Upper Bound';
%                 lb = str2double(get(handles.eccText,'String'));
%                 ub = Inf;
%                 isInt = false;
%                 errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
%             end
            
            if(handles.incOptCheckbox.Value == true)
                value = str2double(get(handles.incLwrBndText,'String'));
                enteredStr = get(handles.incLwrBndText,'String');
                numberName = 'Orbit Inclination Lower Bound';
                lb = 0;
                ub = str2double(get(handles.incText,'String'));
                isInt = false;
                errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);

                value = str2double(get(handles.incUprBndText,'String'));
                enteredStr = get(handles.incUprBndText,'String');
                numberName = 'Orbit Inclination Upper Bound';
                lb = str2double(get(handles.incText,'String'));
                ub = 180;
                isInt = false;
                errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(handles.raanOptCheckbox.Value == true)
                value = str2double(get(handles.raanLwrBndText,'String'));
                enteredStr = get(handles.raanLwrBndText,'String');
                numberName = 'Orbit RAAN Lower Bound';
                lb = -180;
                ub = str2double(get(handles.raanText,'String'));
                isInt = false;
                errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);

                value = str2double(get(handles.raanUprBndText,'String'));
                enteredStr = get(handles.raanUprBndText,'String');
                numberName = 'Orbit RAAN Upper Bound';
                lb = str2double(get(handles.raanText,'String'));
                ub = 360;
                isInt = false;
                errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(handles.argOptCheckbox.Value == true)
                value = str2double(get(handles.argLwrBndText,'String'));
                enteredStr = get(handles.argLwrBndText,'String');
                numberName = 'Orbit Argument of Periapsis Lower Bound';
                lb = -180;
                ub = str2double(get(handles.argText,'String'));
                isInt = false;
                errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);

                value = str2double(get(handles.argUprBndText,'String'));
                enteredStr = get(handles.argUprBndText,'String');
                numberName = 'Orbit Argument of Periapsis Upper Bound';
                lb = str2double(get(handles.argText,'String'));
                ub = 360;
                isInt = false;
                errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
            end            
            
%             if(handles.truOptCheckbox.Value == true)
%                 value = str2double(get(handles.truLwrBndText,'String'));
%                 enteredStr = get(handles.truLwrBndText,'String');
%                 numberName = 'Orbit True Anomaly Lower Bound';
%                 lb = -180;
%                 ub = str2double(get(handles.truText,'String'));
%                 isInt = false;
%                 errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
% 
%                 value = str2double(get(handles.truUprBndText,'String'));
%                 enteredStr = get(handles.truUprBndText,'String');
%                 numberName = 'Orbit True Anomaly Upper Bound';
%                 lb = str2double(get(handles.truText,'String'));
%                 ub = 360;
%                 isInt = false;
%                 errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
%             end
            
            if(isHyperbolic)
                if(handles.smaOptCheckbox.Value == true)
                    value = str2double(get(handles.smaLwrBndText,'String'));
                    enteredStr = get(handles.smaLwrBndText,'String');
                    numberName = 'Orbit SMA Lower Bound';
                    lb = -Inf;
                    ub = str2double(get(handles.smaText,'String'));
                    isInt = false;
                    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);

                    value = str2double(get(handles.smaUprBndText,'String'));
                    enteredStr = get(handles.smaUprBndText,'String');
                    numberName = 'Orbit SMA Upper Bound';
                    lb = str2double(get(handles.smaText,'String'));
                    ub = -1;
                    isInt = false;
                    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
                end
                
                if(handles.eccOptCheckbox.Value == true)
                    value = str2double(get(handles.eccLwrBndText,'String'));
                    enteredStr = get(handles.eccLwrBndText,'String');
                    numberName = 'Orbit Eccentricity Lower Bound';
                    lb = 1;
                    ub = str2double(get(handles.eccText,'String'));
                    isInt = false;
                    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);

                    value = str2double(get(handles.eccUprBndText,'String'));
                    enteredStr = get(handles.eccUprBndText,'String');
                    numberName = 'Orbit Eccentricity Upper Bound';
                    lb = str2double(get(handles.eccText,'String'));
                    ub = Inf;
                    isInt = false;
                    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
                end
                
                if(handles.truOptCheckbox.Value == true)
                    maxR = soiRadius;
                    baseTru = computeTrueAFromRadiusEcc(maxR, sma, ecc);
                    minTru = -rad2deg(baseTru);
                    maxTru = rad2deg(baseTru);
                    
                    value = str2double(get(handles.truLwrBndText,'String'));
                    enteredStr = get(handles.truLwrBndText,'String');
                    numberName = 'Orbit True Anomaly Lower Bound';
                    lb = minTru;
                    ub = str2double(get(handles.truText,'String'));
                    isInt = false;
                    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);

                    value = str2double(get(handles.truUprBndText,'String'));
                    enteredStr = get(handles.truUprBndText,'String');
                    numberName = 'Orbit True Anomaly Upper Bound';
                    lb = str2double(get(handles.truText,'String'));
                    ub = maxTru;
                    isInt = false;
                    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
                end
            else
                if(handles.smaOptCheckbox.Value == true)
                    value = str2double(get(handles.smaLwrBndText,'String'));
                    enteredStr = get(handles.smaLwrBndText,'String');
                    numberName = 'Orbit SMA Lower Bound';
                    lb = 1;
                    ub = str2double(get(handles.smaText,'String'));
                    isInt = false;
                    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);

                    value = str2double(get(handles.smaUprBndText,'String'));
                    enteredStr = get(handles.smaUprBndText,'String');
                    numberName = 'Orbit SMA Upper Bound';
                    lb = str2double(get(handles.smaText,'String'));
                    ub = Inf;
                    isInt = false;
                    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
                end
                
                if(handles.eccOptCheckbox.Value == true)
                    value = str2double(get(handles.eccLwrBndText,'String'));
                    enteredStr = get(handles.eccLwrBndText,'String');
                    numberName = 'Orbit Eccentricity Lower Bound';
                    lb = 0;
                    ub = str2double(get(handles.eccText,'String'));
                    isInt = false;
                    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);

                    value = str2double(get(handles.eccUprBndText,'String'));
                    enteredStr = get(handles.eccUprBndText,'String');
                    numberName = 'Orbit Eccentricity Upper Bound';
                    lb = str2double(get(handles.eccText,'String'));
                    ub = 1;
                    isInt = false;
                    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
                end
            end
        end        
    elseif(strcmpi(handles.initStateTypeBtnGrp.SelectedObject.Tag, 'estLaunchRadioBtn'))
        contents = cellstr(get(handles.launchBodiesCombo,'String'));
        selected = strtrim(contents{get(handles.launchBodiesCombo,'Value')});
        bodyInfo = celBodyData.(lower(selected));
        
        parentBodyInfo = getParentBodyInfo(bodyInfo, celBodyData);
        soiRadius = getSOIRadius(bodyInfo, parentBodyInfo);
        
        value = str2double(get(handles.launchEpochText,'String'));
        enteredStr = get(handles.launchEpochText,'String');
        numberName = 'Launch Liftoff Epoch';
        lb = 0;
        ub = Inf;
        isInt = false;
        errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
        
        value = str2double(get(handles.launchLatText,'String'));
        enteredStr = get(handles.launchLatText,'String');
        numberName = 'Launch Site Latitude';
        lb = -90;
        ub = 90;
        isInt = false;
        errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
        
        value = str2double(get(handles.launchLongText,'String'));
        enteredStr = get(handles.launchLongText,'String');
        numberName = 'Launch Site Longitude';
        lb = -180;
        ub = 360;
        isInt = false;
        errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
        
        value = str2double(get(handles.launchAltText,'String'));
        enteredStr = get(handles.launchAltText,'String');
        numberName = 'Launch Site Altitude';
        lb = 0;
        ub = soiRadius;
        isInt = false;
        errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
        
        value = str2double(get(handles.launchToFText,'String'));
        enteredStr = get(handles.launchToFText,'String');
        numberName = 'Launch Time of Flight';
        lb = 0;
        ub = Inf;
        isInt = false;
        errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
        
        value = str2double(get(handles.launchBurnoutLatText,'String'));
        enteredStr = get(handles.launchBurnoutLatText,'String');
        numberName = 'Burnout Latitude';
        lb = -90;
        ub = 90;
        isInt = false;
        errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
        
        value = str2double(get(handles.launchBurnoutLongText,'String'));
        enteredStr = get(handles.launchBurnoutLongText,'String');
        numberName = 'Burnout Longitude';
        lb = -180;
        ub = 360;
        isInt = false;
        errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
        
        value = str2double(get(handles.launchBurnoutAltText,'String'));
        enteredStr = get(handles.launchBurnoutAltText,'String');
        numberName = 'Burnout Altitude';
        lb = 0;
        ub = soiRadius;
        isInt = false;
        errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
        
        %%%
        
        value = str2double(get(handles.launchBurnoutAltText,'String'));
        enteredStr = get(handles.launchBurnoutAltText,'String');
        numberName = 'Burnout Altitude';
        lb = str2double(get(handles.launchAltText,'String'));
        ub = soiRadius;
        isInt = false;
        errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);

        launchLat = str2double(get(handles.launchLatText,'String'));
        launchLong = str2double(get(handles.launchLongText,'String'));
        burnoutLat = str2double(get(handles.launchBurnoutLatText,'String'));
        burnoutLong = str2double(get(handles.launchBurnoutLongText,'String'));

        if(launchLat == burnoutLat && launchLong == burnoutLong)
            errMsg{end+1} = 'Launch latitude/longitude must be different than the burnout latitude/longitude.';
        end

        launchAlt = str2double(get(handles.launchAltText,'String'));
        burnoutAlt = str2double(get(handles.launchBurnoutAltText,'String'));

        if(burnoutAlt <= launchAlt)
            errMsg{end+1} = 'The burnout altitude must be greater than the launch altitude.';
        end
        
        %%%
        basicLaunchCheckPassed = false;
        if(isempty(errMsg))
            basicLaunchCheckPassed = true;
            if(handles.launchEpochOptCheckbox.Value == true)
                value = str2double(get(handles.launchEpochLwrBndText,'String'));
                enteredStr = get(handles.launchEpochLwrBndText,'String');
                numberName = 'Launch Liftoff Epoch Lower Bound';
                lb = 0;
                ub = str2double(get(handles.launchEpochText,'String'));
                isInt = false;
                errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);

                value = str2double(get(handles.launchEpochUprBndText,'String'));
                enteredStr = get(handles.launchEpochUprBndText,'String');
                numberName = 'Launch Liftoff Epoch Upper Bound';
                lb = str2double(get(handles.launchEpochText,'String'));
                ub = Inf;
                isInt = false;
                errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(handles.launchLatOptCheckbox.Value == true)
                value = str2double(get(handles.launchLatLrwBndText,'String'));
                enteredStr = get(handles.launchLatLrwBndText,'String');
                numberName = 'Launch Liftoff Latitude Lower Bound';
                lb = -90;
                ub = str2double(get(handles.launchLatText,'String'));
                isInt = false;
                errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);

                value = str2double(get(handles.launchLatUprBndText,'String'));
                enteredStr = get(handles.launchLatUprBndText,'String');
                numberName = 'Launch Liftoff Latitude Upper Bound';
                lb = str2double(get(handles.launchLatText,'String'));
                ub = 90;
                isInt = false;
                errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(handles.launchLongOptCheckbox.Value == true)
                value = str2double(get(handles.launchLongLrwBndText,'String'));
                enteredStr = get(handles.launchLongLrwBndText,'String');
                numberName = 'Launch Liftoff Longitude Lower Bound';
                lb = -180;
                ub = str2double(get(handles.launchLatText,'String'));
                isInt = false;
                errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);

                value = str2double(get(handles.launchLongUprBndText,'String'));
                enteredStr = get(handles.launchLongUprBndText,'String');
                numberName = 'Launch Liftoff Longitude Upper Bound';
                lb = str2double(get(handles.launchLatText,'String'));
                ub = 360;
                isInt = false;
                errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(handles.launchAltCheckbox.Value == true)
                value = str2double(get(handles.launchAltLrwBndText,'String'));
                enteredStr = get(handles.launchAltLrwBndText,'String');
                numberName = 'Launch Liftoff Altitude Lower Bound';
                lb = 0;
                ub = str2double(get(handles.launchAltText,'String'));
                isInt = false;
                errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);

                value = str2double(get(handles.launchAltUprBndText,'String'));
                enteredStr = get(handles.launchAltUprBndText,'String');
                numberName = 'Launch Liftoff Altitude Upper Bound';
                lb = str2double(get(handles.launchAltText,'String'));
                ub = soiRadius;
                isInt = false;
                errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(handles.launchToFOptCheckbox.Value == true)
                value = str2double(get(handles.launchToFLwrBndText,'String'));
                enteredStr = get(handles.launchToFLwrBndText,'String');
                numberName = 'Burnout Time of Flight Lower Bound';
                lb = 0;
                ub = str2double(get(handles.launchToFText,'String'));
                isInt = false;
                errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);

                value = str2double(get(handles.launchToFUprBndText,'String'));
                enteredStr = get(handles.launchToFUprBndText,'String');
                numberName = 'Burnout Time of Flight Upper Bound';
                lb = str2double(get(handles.launchToFText,'String'));
                ub = Inf;
                isInt = false;
                errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(handles.launchBurnoutLatOptCheckbox.Value == true)
                value = str2double(get(handles.launchBurnoutLatLwrBndText,'String'));
                enteredStr = get(handles.launchBurnoutLatLwrBndText,'String');
                numberName = 'Burnout Latitude Lower Bound';
                lb = -90;
                ub = str2double(get(handles.launchBurnoutLatText,'String'));
                isInt = false;
                errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);

                value = str2double(get(handles.launchBurnoutLatUprBndText,'String'));
                enteredStr = get(handles.launchBurnoutLatUprBndText,'String');
                numberName = 'Burnout Latitude Upper Bound';
                lb = str2double(get(handles.launchBurnoutLatText,'String'));
                ub = 90;
                isInt = false;
                errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(handles.launchBurnoutLongOptCheckbox.Value == true)
                value = str2double(get(handles.launchBurnoutLongLwrBndText,'String'));
                enteredStr = get(handles.launchBurnoutLongLwrBndText,'String');
                numberName = 'Burnout Longitude Lower Bound';
                lb = -180;
                ub = str2double(get(handles.launchBurnoutLongText,'String'));
                isInt = false;
                errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);

                value = str2double(get(handles.launchBurnoutLongUprBndText,'String'));
                enteredStr = get(handles.launchBurnoutLongUprBndText,'String');
                numberName = 'Burnout Longitude Upper Bound';
                lb = str2double(get(handles.launchBurnoutLongText,'String'));
                ub = 360;
                isInt = false;
                errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(handles.launchBurnoutAltOptCheckbox.Value == true)
                value = str2double(get(handles.launchBurnoutAltLwrBndText,'String'));
                enteredStr = get(handles.launchBurnoutAltLwrBndText,'String');
                numberName = 'Burnout Altitude Lower Bound';
                lb = 0;
                ub = str2double(get(handles.launchBurnoutAltText,'String'));
                isInt = false;
                errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);

                value = str2double(get(handles.launchBurnoutAltUprBndText,'String'));
                enteredStr = get(handles.launchBurnoutAltUprBndText,'String');
                numberName = 'Burnout Altitude Upper Bound';
                lb = str2double(get(handles.launchBurnoutAltText,'String'));
                ub = soiRadius;
                isInt = false;
                errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
        end
    end

    dryMass = str2double(get(handles.dryMassText,'String'));
    enteredStr = get(handles.dryMassText,'String');
    numberName = 'Dry Mass';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(dryMass, numberName, lb, ub, isInt, errMsg, enteredStr);

    fuelOxMass = str2double(get(handles.fuelOxMassText,'String'));
    enteredStr = get(handles.fuelOxMassText,'String');
    numberName = 'Fuel & Oxidizer Mass';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(fuelOxMass, numberName, lb, ub, isInt, errMsg, enteredStr);

    monopropMass = str2double(get(handles.monopropMassText,'String'));
    enteredStr = get(handles.monopropMassText,'String');
    numberName = 'Monoprop Mass';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(monopropMass, numberName, lb, ub, isInt, errMsg, enteredStr);

    xenonMass = str2double(get(handles.xenonMassText,'String'));
    enteredStr = get(handles.xenonMassText,'String');
    numberName = 'Xenon Mass';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(xenonMass, numberName, lb, ub, isInt, errMsg, enteredStr);
 

% --- Executes on button press in saveCloseButton.
function saveCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
errMsg = validateInputs(handles);

if(isempty(errMsg))
    uiresume(handles.ma_InsertStateGUI);
else
    msgbox(errMsg,'Errors were found while inserting a state.','error');
end

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.ma_InsertStateGUI);


function stateNameText_Callback(hObject, eventdata, handles)
% hObject    handle to stateNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of stateNameText as text
%        str2double(get(hObject,'String')) returns contents of stateNameText as a double


% --- Executes during object creation, after setting all properties.
function stateNameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stateNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function smaText_Callback(hObject, eventdata, handles)
% hObject    handle to smaText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of smaText as text
%        str2double(get(hObject,'String')) returns contents of smaText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function smaText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to smaText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function eccText_Callback(hObject, eventdata, handles)
% hObject    handle to eccText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eccText as text
%        str2double(get(hObject,'String')) returns contents of eccText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function eccText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eccText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function incText_Callback(hObject, eventdata, handles)
% hObject    handle to incText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of incText as text
%        str2double(get(hObject,'String')) returns contents of incText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function incText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to incText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function raanText_Callback(hObject, eventdata, handles)
% hObject    handle to raanText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of raanText as text
%        str2double(get(hObject,'String')) returns contents of raanText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function raanText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to raanText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function argText_Callback(hObject, eventdata, handles)
% hObject    handle to argText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of argText as text
%        str2double(get(hObject,'String')) returns contents of argText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function argText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to argText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in bodiesCombo.
function bodiesCombo_Callback(hObject, eventdata, handles)
% hObject    handle to bodiesCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns bodiesCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from bodiesCombo


% --- Executes during object creation, after setting all properties.
function bodiesCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bodiesCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function epochText_Callback(hObject, eventdata, handles)
% hObject    handle to epochText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of epochText as text
%        str2double(get(hObject,'String')) returns contents of epochText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function epochText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to epochText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function fuelOxMassText_Callback(hObject, eventdata, handles)
% hObject    handle to fuelOxMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fuelOxMassText as text
%        str2double(get(hObject,'String')) returns contents of fuelOxMassText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function fuelOxMassText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fuelOxMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function monopropMassText_Callback(hObject, eventdata, handles)
% hObject    handle to monopropMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of monopropMassText as text
%        str2double(get(hObject,'String')) returns contents of monopropMassText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function monopropMassText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to monopropMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function xenonMassText_Callback(hObject, eventdata, handles)
% hObject    handle to xenonMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of xenonMassText as text
%        str2double(get(hObject,'String')) returns contents of xenonMassText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function xenonMassText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xenonMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dryMassText_Callback(hObject, eventdata, handles)
% hObject    handle to dryMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dryMassText as text
%        str2double(get(hObject,'String')) returns contents of dryMassText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function dryMassText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dryMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function truText_Callback(hObject, eventdata, handles)
% hObject    handle to truText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of truText as text
%        str2double(get(hObject,'String')) returns contents of truText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function truText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to truText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function enterUTAsDateTimeContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to enterUTAsDateTimeContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
secUT = enterUTAsDateTimeGUI(str2double(get(gco, 'String')));
if(secUT >= 0)
    set(gco, 'String', fullAccNum2Str(secUT));
    epochText_Callback(handles.epochText, eventdata, handles);
end

% --------------------------------------------------------------------
function getUTFromKSPContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to getUTFromKSPContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function getOrbitFromSFSFileContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to getOrbitFromSFSFileContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    refBodyID = orbitPanelGetOrbitFromSFSContextCallBack(handles.ksptotMainGUI, handles.smaText, handles.eccText, handles.incText, handles.raanText, handles.argText, handles.truText, handles.epochText);
    tru = computeTrueAnomFromMean(deg2rad(str2double(get(handles.truText,'String'))), str2double(get(handles.eccText,'String')));
    set(handles.truText,'String',fullAccNum2Str(rad2deg(tru)));

    if(~isempty(refBodyID) && isnumeric(refBodyID))
        celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
        bodyInfo = getBodyInfoByNumber(refBodyID, celBodyData);
        value = findValueFromComboBox(bodyInfo.name, handles.bodiesCombo);
        set(handles.bodiesCombo,'Value',value);
    end


% --------------------------------------------------------------------
function getOrbitFromKSPTOTConnectContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to getOrbitFromKSPTOTConnectContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    refBodyID = orbitPanelGetOrbitFromKSPTOTConnectCallBack(handles.smaText, handles.eccText, handles.incText, handles.raanText, handles.argText, handles.truText, handles.epochText);
    tru = computeTrueAnomFromMean(deg2rad(str2double(get(handles.truText,'String'))), str2double(get(handles.eccText,'String')));
    set(handles.truText,'String',fullAccNum2Str(rad2deg(tru)));
    
    if(~isempty(refBodyID) && isnumeric(refBodyID))
        celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
        bodyInfo = getBodyInfoByNumber(refBodyID, celBodyData);
        value = findValueFromComboBox(bodyInfo.name, handles.bodiesCombo);
        set(handles.bodiesCombo,'Value',value);
    end

% --------------------------------------------------------------------
function orbitPanelContext_Callback(hObject, eventdata, handles)
% hObject    handle to orbitPanelContext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function getMassesFromKSPMenu_Callback(hObject, eventdata, handles)
% hObject    handle to getMassesFromKSPMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    m = readDoublesFromKSPTOTConnect('GetVesselMassesData','',true);
    set(handles.dryMassText,'String',num2str(m(1)));
    set(handles.fuelOxMassText,'String',num2str(m(2)));
    set(handles.monopropMassText,'String',num2str(m(3)));
    set(handles.xenonMassText,'String',num2str(m(4)));


% --- Executes on key press with focus on ma_InsertStateGUI or any of its controls.
function ma_InsertStateGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to ma_InsertStateGUI (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            saveCloseButton_Callback(handles.saveCloseButton, [], handles);
        case 'enter'
            saveCloseButton_Callback(handles.saveCloseButton, [], handles);
    end


% --------------------------------------------------------------------
function copyOrbitToClipboardMenu_Callback(hObject, eventdata, handles)
% hObject    handle to copyOrbitToClipboardMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    contents = cellstr(get(handles.bodiesCombo,'String'));
    selected = strtrim(contents{get(handles.bodiesCombo,'Value')});
    bodyInfo = celBodyData.(lower(selected));

    copyOrbitToClipboardFromText(handles.epochText, handles.smaText, handles.eccText, ...
                                 handles.incText, handles.raanText, handles.argText, ...
                                 handles.truText, true, bodyInfo.id);

% --------------------------------------------------------------------
function pasteOrbitFromClipboardMenu_Callback(hObject, eventdata, handles)
% hObject    handle to pasteOrbitFromClipboardMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');

    pasteOrbitFromClipboard(handles.epochText, handles.smaText, handles.eccText, ...
                                 handles.incText, handles.raanText, handles.argText, ...
                                 handles.truText, true, handles.bodiesCombo, celBodyData);

                             
% --- Executes on key release with focus on ma_InsertStateGUI or any of its controls.
function ma_InsertStateGUI_WindowKeyReleaseFcn(hObject, eventdata, handles)
% hObject    handle to ma_InsertStateGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was released, in lower case
%	Character: character interpretation of the key(s) that was released
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) released
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'escape'
            close(handles.ma_InsertStateGUI);
    end


% --------------------------------------------------------------------
function getOrbitFromKSPActiveVesselMenu_Callback(hObject, eventdata, handles)
% hObject    handle to getOrbitFromKSPActiveVesselMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    refBodyID = orbitPanelGetOrbitFromKSPTOTConnectActiveVesselCallBack(handles.smaText, handles.eccText, handles.incText, handles.raanText, handles.argText, handles.truText, handles.epochText);
    tru = computeTrueAnomFromMean(deg2rad(str2double(get(handles.truText,'String'))), str2double(get(handles.eccText,'String')));
    set(handles.truText,'String',fullAccNum2Str(rad2deg(tru)));
    
    if(~isempty(refBodyID) && isnumeric(refBodyID))
        celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
        bodyInfo = getBodyInfoByNumber(refBodyID, celBodyData);
        value = findValueFromComboBox(bodyInfo.name, handles.bodiesCombo);
        set(handles.bodiesCombo,'Value',value);
    end


% --- Executes when selected object is changed in initStateTypeBtnGrp.
function initStateTypeBtnGrp_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in initStateTypeBtnGrp 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if(strcmpi(hObject.Tag, 'setStateRadioBtn'))
        handles.bodiesCombo.Enable = 'on';
        handles.epochText.Enable = 'on';
        handles.smaText.Enable = 'on';
        handles.eccText.Enable = 'on';
        handles.incText.Enable = 'on';
        handles.raanText.Enable = 'on';
        handles.argText.Enable = 'on';
        handles.truText.Enable = 'on';
        
        handles.epochOptCheckbox.Enable = 'on';
        handles.epochLwrBndText.Enable = 'on';
        handles.epochUprBndText.Enable = 'on';
        handles.smaOptCheckbox.Enable = 'on';
        handles.smaLwrBndText.Enable = 'on';
        handles.smaUprBndText.Enable = 'on';
        handles.eccOptCheckbox.Enable = 'on';
        handles.eccLwrBndText.Enable = 'on';
        handles.eccUprBndText.Enable = 'on';
        handles.incOptCheckbox.Enable = 'on';
        handles.incLwrBndText.Enable = 'on';
        handles.incUprBndText.Enable = 'on';
        handles.raanOptCheckbox.Enable = 'on';
        handles.raanLwrBndText.Enable = 'on';
        handles.raanUprBndText.Enable = 'on';
        handles.argOptCheckbox.Enable = 'on';
        handles.argLwrBndText.Enable = 'on';
        handles.argUprBndText.Enable = 'on';
        handles.truOptCheckbox.Enable = 'on';
        handles.truLwrBndText.Enable = 'on';
        handles.truUprBndText.Enable = 'on';
        
        handles.launchTrajectoryColorCombo.Enable = 'off';
        handles.stateLineStyleCombo.Enable = 'off';
        handles.launchBodiesCombo.Enable = 'off';
        
        handles.launchEpochText.Enable = 'off';
        handles.launchEpochOptCheckbox.Enable = 'off';
        handles.launchEpochLwrBndText.Enable = 'off';
        handles.launchEpochUprBndText.Enable = 'off';
        handles.launchLatText.Enable = 'off';
        handles.launchLatOptCheckbox.Enable = 'off';
        handles.launchLatLrwBndText.Enable = 'off';
        handles.launchLatUprBndText.Enable = 'off';
        handles.launchLongText.Enable = 'off';
        handles.launchLongOptCheckbox.Enable = 'off';
        handles.launchLongLrwBndText.Enable = 'off';
        handles.launchLongUprBndText.Enable = 'off';
        handles.launchAltText.Enable = 'off';
        handles.launchAltCheckbox.Enable = 'off';
        handles.launchAltLrwBndText.Enable = 'off';
        handles.launchAltUprBndText.Enable = 'off';
        
        handles.launchToFText.Enable = 'off';
        handles.launchToFOptCheckbox.Enable = 'off';
        handles.launchToFLwrBndText.Enable = 'off';
        handles.launchToFUprBndText.Enable = 'off';
        
        handles.launchBurnoutLatText.Enable = 'off';
        handles.launchBurnoutLatLwrBndText.Enable = 'off';
        handles.launchBurnoutLatOptCheckbox.Enable = 'off';
        handles.launchBurnoutLatUprBndText.Enable = 'off';
        
        handles.launchBurnoutLongText.Enable = 'off';
        handles.launchBurnoutLongOptCheckbox.Enable = 'off';
        handles.launchBurnoutLongLwrBndText.Enable = 'off';
        handles.launchBurnoutLongUprBndText.Enable = 'off';
        
        handles.launchBurnoutAltText.Enable = 'off';
        handles.launchBurnoutAltOptCheckbox.Enable = 'off';
        handles.launchBurnoutAltLwrBndText.Enable = 'off';
        handles.launchBurnoutAltUprBndText.Enable = 'off';
        
        handles.lineWidthCombo.Enable = 'off';
        
        epochOptCheckbox_Callback(handles.epochOptCheckbox, [], handles);
        smaOptCheckbox_Callback(handles.smaOptCheckbox, [], handles);
        eccOptCheckbox_Callback(handles.eccOptCheckbox, [], handles);
        incOptCheckbox_Callback(handles.incOptCheckbox, [], handles);
        raanOptCheckbox_Callback(handles.raanOptCheckbox, [], handles);
        argOptCheckbox_Callback(handles.argOptCheckbox, [], handles);
        truOptCheckbox_Callback(handles.truOptCheckbox, [], handles);
        
        handles.launchResText.ForegroundColor = [0.5 0.5 0.5];
        
        handles.launchSiteNotEditableText.Visible = 'off';
    elseif(strcmpi(hObject.Tag, 'estLaunchRadioBtn'))
        handles.bodiesCombo.Enable = 'off';
        handles.epochText.Enable = 'off';
        handles.smaText.Enable = 'off';
        handles.eccText.Enable = 'off';
        handles.incText.Enable = 'off';
        handles.raanText.Enable = 'off';
        handles.argText.Enable = 'off';
        handles.truText.Enable = 'off';
        
        handles.epochOptCheckbox.Enable = 'off';
        handles.epochLwrBndText.Enable = 'off';
        handles.epochUprBndText.Enable = 'off';
        handles.smaOptCheckbox.Enable = 'off';
        handles.smaLwrBndText.Enable = 'off';
        handles.smaUprBndText.Enable = 'off';
        handles.eccOptCheckbox.Enable = 'off';
        handles.eccLwrBndText.Enable = 'off';
        handles.eccUprBndText.Enable = 'off';
        handles.incOptCheckbox.Enable = 'off';
        handles.incLwrBndText.Enable = 'off';
        handles.incUprBndText.Enable = 'off';
        handles.raanOptCheckbox.Enable = 'off';
        handles.raanLwrBndText.Enable = 'off';
        handles.raanUprBndText.Enable = 'off';
        handles.argOptCheckbox.Enable = 'off';
        handles.argLwrBndText.Enable = 'off';
        handles.argUprBndText.Enable = 'off';
        handles.truOptCheckbox.Enable = 'off';
        handles.truLwrBndText.Enable = 'off';
        handles.truUprBndText.Enable = 'off';
        
        handles.launchTrajectoryColorCombo.Enable = 'on';
        handles.stateLineStyleCombo.Enable = 'on';
        
        initialState = getappdata(handles. ma_InsertStateGUI,'initialState');
        
        if(isempty(initialState))
            handles.launchBodiesCombo.Enable = 'on';
            handles.launchEpochText.Enable = 'on';
            handles.launchEpochOptCheckbox.Enable = 'on';
            handles.launchEpochLwrBndText.Enable = 'on';
            handles.launchEpochUprBndText.Enable = 'on';
            handles.launchLatText.Enable = 'on';
            handles.launchLatOptCheckbox.Enable = 'on';
            handles.launchLatLrwBndText.Enable = 'on';
            handles.launchLatUprBndText.Enable = 'on';
            handles.launchLongText.Enable = 'on';
            handles.launchLongOptCheckbox.Enable = 'on';
            handles.launchLongLrwBndText.Enable = 'on';
            handles.launchLongUprBndText.Enable = 'on';
            handles.launchAltText.Enable = 'on';
            handles.launchAltCheckbox.Enable = 'on';
            handles.launchAltLrwBndText.Enable = 'on';
            handles.launchAltUprBndText.Enable = 'on';
            
            handles.launchSiteNotEditableText.Visible = 'off';
        else
            handles.launchBodiesCombo.Enable = 'off';
            handles.launchEpochText.Enable = 'off';
            handles.launchEpochOptCheckbox.Enable = 'off';
            handles.launchEpochLwrBndText.Enable = 'off';
            handles.launchEpochUprBndText.Enable = 'off';
            handles.launchLatText.Enable = 'off';
            handles.launchLatOptCheckbox.Enable = 'off';
            handles.launchLatLrwBndText.Enable = 'off';
            handles.launchLatUprBndText.Enable = 'off';
            handles.launchLongText.Enable = 'off';
            handles.launchLongOptCheckbox.Enable = 'off';
            handles.launchLongLrwBndText.Enable = 'off';
            handles.launchLongUprBndText.Enable = 'off';
            handles.launchAltText.Enable = 'off';
            handles.launchAltCheckbox.Enable = 'off';
            handles.launchAltLrwBndText.Enable = 'off';
            handles.launchAltUprBndText.Enable = 'off';
            
            handles.launchSiteNotEditableText.Visible = 'on';
        end
        
        handles.launchToFText.Enable = 'on';
        handles.launchToFOptCheckbox.Enable = 'on';
        handles.launchToFLwrBndText.Enable = 'on';
        handles.launchToFUprBndText.Enable = 'on';
        
        handles.launchBurnoutLatText.Enable = 'on';
        handles.launchBurnoutLatLwrBndText.Enable = 'on';
        handles.launchBurnoutLatOptCheckbox.Enable = 'on';
        handles.launchBurnoutLatUprBndText.Enable = 'on';
        
        handles.launchBurnoutLongText.Enable = 'on';
        handles.launchBurnoutLongOptCheckbox.Enable = 'on';
        handles.launchBurnoutLongLwrBndText.Enable = 'on';
        handles.launchBurnoutLongUprBndText.Enable = 'on';
        
        handles.launchBurnoutAltText.Enable = 'on';
        handles.launchBurnoutAltOptCheckbox.Enable = 'on';
        handles.launchBurnoutAltLwrBndText.Enable = 'on';
        handles.launchBurnoutAltUprBndText.Enable = 'on';
        
        handles.lineWidthCombo.Enable = 'on';
        
        launchEpochOptCheckbox_Callback(handles.launchEpochOptCheckbox, [], handles);
        launchLatOptCheckbox_Callback(handles.launchLatOptCheckbox, [], handles);
        launchLongOptCheckbox_Callback(handles.launchLongOptCheckbox, [], handles);
        launchAltCheckbox_Callback(handles.launchAltCheckbox, [], handles);

        launchToFOptCheckbox_Callback(handles.launchToFOptCheckbox, [], handles);
        launchBurnoutLatOptCheckbox_Callback(handles.launchBurnoutLatOptCheckbox, [], handles);
        launchBurnoutLongOptCheckbox_Callback(handles.launchBurnoutLongOptCheckbox, [], handles);
        launchBurnoutAltOptCheckbox_Callback(handles.launchBurnoutAltOptCheckbox, [], handles);
        
        handles.launchResText.ForegroundColor = [0 0 0];
    end


function launchEpochText_Callback(hObject, eventdata, handles)
% hObject    handle to launchEpochText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchEpochText as text
%        str2double(get(hObject,'String')) returns contents of launchEpochText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    computeAzIncRaanForLaunch(handles);

% --- Executes during object creation, after setting all properties.
function launchEpochText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchEpochText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in launchBodiesCombo.
function launchBodiesCombo_Callback(hObject, eventdata, handles)
% hObject    handle to launchBodiesCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns launchBodiesCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from launchBodiesCombo
    computeAzIncRaanForLaunch(handles);

% --- Executes during object creation, after setting all properties.
function launchBodiesCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchBodiesCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function launchLatText_Callback(hObject, eventdata, handles)
% hObject    handle to launchLatText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchLatText as text
%        str2double(get(hObject,'String')) returns contents of launchLatText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    computeAzIncRaanForLaunch(handles);

% --- Executes during object creation, after setting all properties.
function launchLatText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchLatText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function launchLongText_Callback(hObject, eventdata, handles)
% hObject    handle to launchLongText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchLongText as text
%        str2double(get(hObject,'String')) returns contents of launchLongText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    computeAzIncRaanForLaunch(handles);

% --- Executes during object creation, after setting all properties.
function launchLongText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchLongText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function launchAltText_Callback(hObject, eventdata, handles)
% hObject    handle to launchAltText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchAltText as text
%        str2double(get(hObject,'String')) returns contents of launchAltText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    computeAzIncRaanForLaunch(handles);

% --- Executes during object creation, after setting all properties.
function launchAltText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchAltText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function launchToFText_Callback(hObject, eventdata, handles)
% hObject    handle to launchToFText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchToFText as text
%        str2double(get(hObject,'String')) returns contents of launchToFText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    computeAzIncRaanForLaunch(handles);

% --- Executes during object creation, after setting all properties.
function launchToFText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchToFText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function launchBurnoutLatText_Callback(hObject, eventdata, handles)
% hObject    handle to launchBurnoutLatText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchBurnoutLatText as text
%        str2double(get(hObject,'String')) returns contents of launchBurnoutLatText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

    computeAzIncRaanForLaunch(handles);
    
% --- Executes during object creation, after setting all properties.
function launchBurnoutLatText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchBurnoutLatText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function launchBurnoutLongText_Callback(hObject, eventdata, handles)
% hObject    handle to launchBurnoutLongText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchBurnoutLongText as text
%        str2double(get(hObject,'String')) returns contents of launchBurnoutLongText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    computeAzIncRaanForLaunch(handles);

% --- Executes during object creation, after setting all properties.
function launchBurnoutLongText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchBurnoutLongText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function launchBurnoutAltText_Callback(hObject, eventdata, handles)
% hObject    handle to launchBurnoutAltText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchBurnoutAltText as text
%        str2double(get(hObject,'String')) returns contents of launchBurnoutAltText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    computeAzIncRaanForLaunch(handles);

% --- Executes during object creation, after setting all properties.
function launchBurnoutAltText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchBurnoutAltText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in launchEpochOptCheckbox.
function launchEpochOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to launchEpochOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of launchEpochOptCheckbox
    if(get(hObject,'Value'))
        handles.launchEpochLwrBndText.Enable = 'on';
        handles.launchEpochUprBndText.Enable = 'on';
    else
        handles.launchEpochLwrBndText.Enable = 'off';
        handles.launchEpochUprBndText.Enable = 'off';
    end
    
    computeAzIncRaanForLaunch(handles);


function launchEpochLwrBndText_Callback(hObject, eventdata, handles)
% hObject    handle to launchEpochLwrBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchEpochLwrBndText as text
%        str2double(get(hObject,'String')) returns contents of launchEpochLwrBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function launchEpochLwrBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchEpochLwrBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function launchEpochUprBndText_Callback(hObject, eventdata, handles)
% hObject    handle to launchEpochUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchEpochUprBndText as text
%        str2double(get(hObject,'String')) returns contents of launchEpochUprBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function launchEpochUprBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchEpochUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in launchLatOptCheckbox.
function launchLatOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to launchLatOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of launchLatOptCheckbox
    if(get(hObject,'Value'))
        handles.launchLatLrwBndText.Enable = 'on';
        handles.launchLatUprBndText.Enable = 'on';
    else
        handles.launchLatLrwBndText.Enable = 'off';
        handles.launchLatUprBndText.Enable = 'off';
    end
    
    computeAzIncRaanForLaunch(handles);

% --- Executes on button press in launchLongOptCheckbox.
function launchLongOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to launchLongOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of launchLongOptCheckbox
    if(get(hObject,'Value'))
        handles.launchLongLrwBndText.Enable = 'on';
        handles.launchLongUprBndText.Enable = 'on';
    else
        handles.launchLongLrwBndText.Enable = 'off';
        handles.launchLongUprBndText.Enable = 'off';
    end
    
    computeAzIncRaanForLaunch(handles);

% --- Executes on button press in launchAltCheckbox.
function launchAltCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to launchAltCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of launchAltCheckbox
    if(get(hObject,'Value'))
        handles.launchAltLrwBndText.Enable = 'on';
        handles.launchAltUprBndText.Enable = 'on';
    else
        handles.launchAltLrwBndText.Enable = 'off';
        handles.launchAltUprBndText.Enable = 'off';
    end

    computeAzIncRaanForLaunch(handles);

function launchLatLrwBndText_Callback(hObject, eventdata, handles)
% hObject    handle to launchLatLrwBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchLatLrwBndText as text
%        str2double(get(hObject,'String')) returns contents of launchLatLrwBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function launchLatLrwBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchLatLrwBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function launchLatUprBndText_Callback(hObject, eventdata, handles)
% hObject    handle to launchLatUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchLatUprBndText as text
%        str2double(get(hObject,'String')) returns contents of launchLatUprBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function launchLatUprBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchLatUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function launchLongLrwBndText_Callback(hObject, eventdata, handles)
% hObject    handle to launchLongLrwBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchLongLrwBndText as text
%        str2double(get(hObject,'String')) returns contents of launchLongLrwBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function launchLongLrwBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchLongLrwBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function launchLongUprBndText_Callback(hObject, eventdata, handles)
% hObject    handle to launchLongUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchLongUprBndText as text
%        str2double(get(hObject,'String')) returns contents of launchLongUprBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function launchLongUprBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchLongUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function launchAltLrwBndText_Callback(hObject, eventdata, handles)
% hObject    handle to launchAltLrwBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchAltLrwBndText as text
%        str2double(get(hObject,'String')) returns contents of launchAltLrwBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function launchAltLrwBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchAltLrwBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function launchAltUprBndText_Callback(hObject, eventdata, handles)
% hObject    handle to launchAltUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchAltUprBndText as text
%        str2double(get(hObject,'String')) returns contents of launchAltUprBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function launchAltUprBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchAltUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in launchToFOptCheckbox.
function launchToFOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to launchToFOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of launchToFOptCheckbox
    if(get(hObject,'Value'))
        handles.launchToFLwrBndText.Enable = 'on';
        handles.launchToFUprBndText.Enable = 'on';
    else
        handles.launchToFLwrBndText.Enable = 'off';
        handles.launchToFUprBndText.Enable = 'off';
    end
    
    computeAzIncRaanForLaunch(handles);


function launchToFLwrBndText_Callback(hObject, eventdata, handles)
% hObject    handle to launchToFLwrBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchToFLwrBndText as text
%        str2double(get(hObject,'String')) returns contents of launchToFLwrBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function launchToFLwrBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchToFLwrBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function launchToFUprBndText_Callback(hObject, eventdata, handles)
% hObject    handle to launchToFUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchToFUprBndText as text
%        str2double(get(hObject,'String')) returns contents of launchToFUprBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function launchToFUprBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchToFUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in launchBurnoutLatOptCheckbox.
function launchBurnoutLatOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to launchBurnoutLatOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of launchBurnoutLatOptCheckbox
    if(get(hObject,'Value'))
        handles.launchBurnoutLatLwrBndText.Enable = 'on';
        handles.launchBurnoutLatUprBndText.Enable = 'on';
    else
        handles.launchBurnoutLatLwrBndText.Enable = 'off';
        handles.launchBurnoutLatUprBndText.Enable = 'off';
    end

    computeAzIncRaanForLaunch(handles);
    
% --- Executes on button press in launchBurnoutLongOptCheckbox.
function launchBurnoutLongOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to launchBurnoutLongOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of launchBurnoutLongOptCheckbox
    if(get(hObject,'Value'))
        handles.launchBurnoutLongLwrBndText.Enable = 'on';
        handles.launchBurnoutLongUprBndText.Enable = 'on';
    else
        handles.launchBurnoutLongLwrBndText.Enable = 'off';
        handles.launchBurnoutLongUprBndText.Enable = 'off';
    end
    
    computeAzIncRaanForLaunch(handles);

% --- Executes on button press in launchBurnoutAltOptCheckbox.
function launchBurnoutAltOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to launchBurnoutAltOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of launchBurnoutAltOptCheckbox
    if(get(hObject,'Value'))
        handles.launchBurnoutAltLwrBndText.Enable = 'on';
        handles.launchBurnoutAltUprBndText.Enable = 'on';
    else
        handles.launchBurnoutAltLwrBndText.Enable = 'off';
        handles.launchBurnoutAltUprBndText.Enable = 'off';
    end
    
    computeAzIncRaanForLaunch(handles);


function launchBurnoutLatLwrBndText_Callback(hObject, eventdata, handles)
% hObject    handle to launchBurnoutLatLwrBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchBurnoutLatLwrBndText as text
%        str2double(get(hObject,'String')) returns contents of launchBurnoutLatLwrBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function launchBurnoutLatLwrBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchBurnoutLatLwrBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function launchBurnoutLongLwrBndText_Callback(hObject, eventdata, handles)
% hObject    handle to launchBurnoutLongLwrBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchBurnoutLongLwrBndText as text
%        str2double(get(hObject,'String')) returns contents of launchBurnoutLongLwrBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function launchBurnoutLongLwrBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchBurnoutLongLwrBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function launchBurnoutAltLwrBndText_Callback(hObject, eventdata, handles)
% hObject    handle to launchBurnoutAltLwrBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchBurnoutAltLwrBndText as text
%        str2double(get(hObject,'String')) returns contents of launchBurnoutAltLwrBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function launchBurnoutAltLwrBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchBurnoutAltLwrBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function launchBurnoutLatUprBndText_Callback(hObject, eventdata, handles)
% hObject    handle to launchBurnoutLatUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchBurnoutLatUprBndText as text
%        str2double(get(hObject,'String')) returns contents of launchBurnoutLatUprBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function launchBurnoutLatUprBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchBurnoutLatUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function launchBurnoutLongUprBndText_Callback(hObject, eventdata, handles)
% hObject    handle to launchBurnoutLongUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchBurnoutLongUprBndText as text
%        str2double(get(hObject,'String')) returns contents of launchBurnoutLongUprBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function launchBurnoutLongUprBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchBurnoutLongUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function launchBurnoutAltUprBndText_Callback(hObject, eventdata, handles)
% hObject    handle to launchBurnoutAltUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchBurnoutAltUprBndText as text
%        str2double(get(hObject,'String')) returns contents of launchBurnoutAltUprBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function launchBurnoutAltUprBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchBurnoutAltUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function computeAzIncRaanForLaunch(handles)
    [~, basicLaunchCheckPassed] = validateInputs(handles);
    
    if(basicLaunchCheckPassed)
        celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
        
        launch = createLaunchEvent(handles, '');
        eventLog = ma_executeLaunch([], launch, celBodyData);
        state = eventLog(end,:);
        
        bodyInfo = getBodyInfoByNumber(launch.bodyId, celBodyData);
        gmu = bodyInfo.gm;
        
        [~, ~, inc, raan, ~, ~] = getKeplerFromState(state(2:4),state(5:7),gmu, true);
        az = asin(cos(inc)/cos(launch.launchValue(2)));
        
        str = sprintf('Launch Az. = %0.3f º | Inclination = %0.3f º | RAAN = %0.3f º', rad2deg(az), rad2deg(inc), rad2deg(raan));
        handles.launchResText.String = str;
    else
        str = sprintf('Launch Az. = Err | Inclination = Err | RAAN = Err');
    end
    
    handles.launchResText.String = str;
	handles.launchResText.TooltipString = str;


% --- Executes on selection change in launchTrajectoryColorCombo.
function launchTrajectoryColorCombo_Callback(hObject, eventdata, handles)
% hObject    handle to launchTrajectoryColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns launchTrajectoryColorCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from launchTrajectoryColorCombo


% --- Executes during object creation, after setting all properties.
function launchTrajectoryColorCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchTrajectoryColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function initStateTypeBtnGrp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to initStateTypeBtnGrp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --------------------------------------------------------------------
function setLaunchSiteFromGrdTgtMenu_Callback(hObject, eventdata, handles)
% hObject    handle to setLaunchSiteFromGrdTgtMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function setLaunchSiteFromGrdTgtContext_Callback(hObject, eventdata, handles)
% hObject    handle to setLaunchSiteFromGrdTgtContext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in epochOptCheckbox.
function epochOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to epochOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of epochOptCheckbox
    if(get(hObject,'Value'))
        handles.epochLwrBndText.Enable = 'on';
        handles.epochUprBndText.Enable = 'on';
    else
        handles.epochLwrBndText.Enable = 'off';
        handles.epochUprBndText.Enable = 'off';
    end


function epochLwrBndText_Callback(hObject, eventdata, handles)
% hObject    handle to epochLwrBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of epochLwrBndText as text
%        str2double(get(hObject,'String')) returns contents of epochLwrBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function epochLwrBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to epochLwrBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function epochUprBndText_Callback(hObject, eventdata, handles)
% hObject    handle to epochUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of epochUprBndText as text
%        str2double(get(hObject,'String')) returns contents of epochUprBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function epochUprBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to epochUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in smaOptCheckbox.
function smaOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to smaOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of smaOptCheckbox
    if(get(hObject,'Value'))
        handles.smaLwrBndText.Enable = 'on';
        handles.smaUprBndText.Enable = 'on';
    else
        handles.smaLwrBndText.Enable = 'off';
        handles.smaUprBndText.Enable = 'off';
    end

% --- Executes on button press in eccOptCheckbox.
function eccOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to eccOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of eccOptCheckbox
    if(get(hObject,'Value'))
        handles.eccLwrBndText.Enable = 'on';
        handles.eccUprBndText.Enable = 'on';
    else
        handles.eccLwrBndText.Enable = 'off';
        handles.eccUprBndText.Enable = 'off';
    end

% --- Executes on button press in incOptCheckbox.
function incOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to incOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of incOptCheckbox
    if(get(hObject,'Value'))
        handles.incLwrBndText.Enable = 'on';
        handles.incUprBndText.Enable = 'on';
    else
        handles.incLwrBndText.Enable = 'off';
        handles.incUprBndText.Enable = 'off';
    end


function smaLwrBndText_Callback(hObject, eventdata, handles)
% hObject    handle to smaLwrBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of smaLwrBndText as text
%        str2double(get(hObject,'String')) returns contents of smaLwrBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function smaLwrBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to smaLwrBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function smaUprBndText_Callback(hObject, eventdata, handles)
% hObject    handle to smaUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of smaUprBndText as text
%        str2double(get(hObject,'String')) returns contents of smaUprBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function smaUprBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to smaUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function eccLwrBndText_Callback(hObject, eventdata, handles)
% hObject    handle to eccLwrBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eccLwrBndText as text
%        str2double(get(hObject,'String')) returns contents of eccLwrBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function eccLwrBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eccLwrBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function eccUprBndText_Callback(hObject, eventdata, handles)
% hObject    handle to eccUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eccUprBndText as text
%        str2double(get(hObject,'String')) returns contents of eccUprBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function eccUprBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eccUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function incLwrBndText_Callback(hObject, eventdata, handles)
% hObject    handle to incLwrBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of incLwrBndText as text
%        str2double(get(hObject,'String')) returns contents of incLwrBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function incLwrBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to incLwrBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function incUprBndText_Callback(hObject, eventdata, handles)
% hObject    handle to incUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of incUprBndText as text
%        str2double(get(hObject,'String')) returns contents of incUprBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function incUprBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to incUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function raanLwrBndText_Callback(hObject, eventdata, handles)
% hObject    handle to raanLwrBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of raanLwrBndText as text
%        str2double(get(hObject,'String')) returns contents of raanLwrBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function raanLwrBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to raanLwrBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function raanUprBndText_Callback(hObject, eventdata, handles)
% hObject    handle to raanUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of raanUprBndText as text
%        str2double(get(hObject,'String')) returns contents of raanUprBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function raanUprBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to raanUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function argLwrBndText_Callback(hObject, eventdata, handles)
% hObject    handle to argLwrBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of argLwrBndText as text
%        str2double(get(hObject,'String')) returns contents of argLwrBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function argLwrBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to argLwrBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function argUprBndText_Callback(hObject, eventdata, handles)
% hObject    handle to argUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of argUprBndText as text
%        str2double(get(hObject,'String')) returns contents of argUprBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function argUprBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to argUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function truLwrBndText_Callback(hObject, eventdata, handles)
% hObject    handle to truLwrBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of truLwrBndText as text
%        str2double(get(hObject,'String')) returns contents of truLwrBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function truLwrBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to truLwrBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function truUprBndText_Callback(hObject, eventdata, handles)
% hObject    handle to truUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of truUprBndText as text
%        str2double(get(hObject,'String')) returns contents of truUprBndText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function truUprBndText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to truUprBndText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in raanOptCheckbox.
function raanOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to raanOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of raanOptCheckbox
    if(get(hObject,'Value'))
        handles.raanLwrBndText.Enable = 'on';
        handles.raanUprBndText.Enable = 'on';
    else
        handles.raanLwrBndText.Enable = 'off';
        handles.raanUprBndText.Enable = 'off';
    end

% --- Executes on button press in argOptCheckbox.
function argOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to argOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of argOptCheckbox
    if(get(hObject,'Value'))
        handles.argLwrBndText.Enable = 'on';
        handles.argUprBndText.Enable = 'on';
    else
        handles.argLwrBndText.Enable = 'off';
        handles.argUprBndText.Enable = 'off';
    end

% --- Executes on button press in truOptCheckbox.
function truOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to truOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of truOptCheckbox
    if(get(hObject,'Value'))
        handles.truLwrBndText.Enable = 'on';
        handles.truUprBndText.Enable = 'on';
    else
        handles.truLwrBndText.Enable = 'off';
        handles.truUprBndText.Enable = 'off';
    end


% --- Executes on selection change in stateLineStyleCombo.
function stateLineStyleCombo_Callback(hObject, eventdata, handles)
% hObject    handle to stateLineStyleCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns stateLineStyleCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from stateLineStyleCombo


% --- Executes during object creation, after setting all properties.
function stateLineStyleCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stateLineStyleCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


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
