function varargout = ma_LaunchTrajectoryGUI(varargin)
% MA_LAUNCHTRAJECTORYGUI MATLAB code for ma_LaunchTrajectoryGUI.fig
%      MA_LAUNCHTRAJECTORYGUI, by itself, creates a new MA_LAUNCHTRAJECTORYGUI or raises the existing
%      singleton*.
%
%      H = MA_LAUNCHTRAJECTORYGUI returns the handle to a new MA_LAUNCHTRAJECTORYGUI or the handle to
%      the existing singleton*.
%
%      MA_LAUNCHTRAJECTORYGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_LAUNCHTRAJECTORYGUI.M with the given input arguments.
%
%      MA_LAUNCHTRAJECTORYGUI('Property','Value',...) creates a new MA_LAUNCHTRAJECTORYGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_LaunchTrajectoryGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_LaunchTrajectoryGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_LaunchTrajectoryGUI

% Last Modified by GUIDE v2.5 11-Jul-2015 17:04:06

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_LaunchTrajectoryGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_LaunchTrajectoryGUI_OutputFcn, ...
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


% --- Executes just before ma_LaunchTrajectoryGUI is made visible.
function ma_LaunchTrajectoryGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_LaunchTrajectoryGUI (see VARARGIN)

% Choose default command line output for ma_LaunchTrajectoryGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
handles.ma_MainGUI = varargin{1};
guidata(hObject, handles);

setupGUI(handles);

% UIWAIT makes ma_LaunchTrajectoryGUI wait for user response (see UIRESUME)
% uiwait(handles.ma_LaunchTrajectoryGUI);


function setupGUI(handles)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    populateStationsCombo(handles, handles.stationCombo);
    
    launchTraj = maData.launch;
    
    set(handles.lvDefTable,'Data',launchTraj.lvDef);
    set(handles.maxCoastDurText,'String',num2str(launchTraj.maxCoast));
    
    stations = maData.spacecraft.stations;
    if(isempty(stations))
        set(handles.stationCombo,'Enable','off');
        set(handles.stationCombo,'String','--None--');
        set(handles.stationCombo,'Value',1);
    else
        set(handles.stationCombo,'Enable','on');
        for(i=1:length(stations))  %#ok<*NO4LP>
            station = stations{i};
            if(station.id == launchTraj.station)
                set(handles.stationCombo,'Value',i);
                break;
            end
        end
    end
    
    set(handles.smaText,'String',num2str(launchTraj.orbit.sma));
    set(handles.eccText,'String',num2str(launchTraj.orbit.ecc));
    set(handles.incText,'String',num2str(rad2deg(launchTraj.orbit.inc)));
    set(handles.raanText,'String',num2str(rad2deg(launchTraj.orbit.raan)));
    set(handles.argText,'String',num2str(rad2deg(launchTraj.orbit.arg)));
    
    set(handles.liftoffUtText,'String',num2str(launchTraj.liftoffUT));
    set(handles.launchHeadingText,'String',num2str(launchTraj.launchHeading));
    set(handles.ascentDurText,'String',num2str(launchTraj.ascentDuration));
    
    set(handles.pitchProfileTable,'Data',launchTraj.pitchProfile);
    set(handles.pitchInterpCombo,'Value',findValueFromComboBox(launchTraj.pitchInterp, handles.pitchInterpCombo));
    
    postInputUpdate(handles);
    
function updateLvDefLabels(handles)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    lvDef = maData.launch.lvDef;
    
    [bodyInfo, station] = getBodyInfoForLaunchSite(maData, celBodyData);
    g0 = 1000 * bodyInfo.gm / (bodyInfo.radius + station.alt)^2; %1000 * km^3/s^2 / km^2 = 1000 * km/s^2 = m/s^2
    
    initThrust = lvDef{1,4};
    totMass = sum([lvDef{:,2}]) + sum([lvDef{:,3}]);
    initTw = initThrust / (totMass * g0); % kN / (ton * m/s/s) = 1000N / (1000kg * m/s/s) = N/(kg * m/s/s) = 1
    set(handles.initTwRatioLabel,'String',num2str(initTw,'%0.5f'));
    if(initTw <= 1.0)
        set(handles.initTwRatioLabel,'ForegroundColor','r');
    else
        set(handles.initTwRatioLabel,'ForegroundColor','k');
    end

    cumData = getStageData(lvDef);
    maxBurnTime = sum(cumData(:,1));
    set(handles.maxBurnTimeLabel,'String',sprintf('%0.3f sec',maxBurnTime));
    
    maxCoast = maData.launch.maxCoast;
    maxAscentTime = maxBurnTime + size(lvDef,1)*maxCoast;
    set(handles.maxAscentTimeLabel,'String',sprintf('%0.3f sec',maxAscentTime));
    
    totDV = 0;
    liftoffUt = maData.launch.liftoffUT;
    lvPerfTable = getLVPerfTable(lvDef, liftoffUt);
    for(i=1:size(lvDef,1))
        row = lvDef(i,:);
        totDV = totDV + getG0Ms()*row{5} * log(lvPerfTable(i,5)/lvPerfTable(i,6));
    end
    totDV = totDV/1000;
    set(handles.totalDvLabel,'String',sprintf('%0.3f km/s',totDV));
       
function updateLaunchSiteLabels(handles)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
        
    [bodyInfo, station] = getBodyInfoForLaunchSite(maData, celBodyData);
       
    if(~isempty(station))
        set(handles.launchSiteLatLabel,'String',sprintf('%0.5f degN', rad2deg(station.lat)));
        set(handles.launchSiteLongLabel,'String',sprintf('%0.5f degE', rad2deg(station.long)));
        set(handles.launchSiteAltLabel,'String',sprintf('%0.5f km', station.alt));

        rotRate = 2*pi/bodyInfo.rotperiod; %rad/s
        radius = bodyInfo.radius; %km
        orbAssist = cos(station.lat) * (rotRate * radius); %km/s
        
        set(handles.orbitSpeedAtSiteLabel,'String',sprintf('%0.4f km/s', orbAssist));
    end
    
function [bodyInfo, station] = getBodyInfoForLaunchSite(maData, celBodyData)
    stationId = maData.launch.station;
        
    stations = maData.spacecraft.stations;
    station = [];
    for(i=1:length(stations)) 
        selStation = stations{i};
        if(selStation.id == stationId)
            station = selStation;
            break;
        end
    end
    
    if(~isempty(station))
        bodyInfo = getBodyInfoByNumber(station.parentID, celBodyData);
    else
        bodyInfo = [];
    end
    
function plotLowerAxes(handles)
    axToPlot = handles.dataPlotAxes;
    cla(axToPlot,'reset');
    
    selObj = handles.dataPlotButtonGrp.SelectedObject;
    switch selObj.String
        case 'Pitch Profile'
            plotPitchProfile(handles, axToPlot);
        case 'State vs Time'
            plotStateVsTime(handles, axToPlot);
        case 'Vertical Speed'
            plotVerticalSpeed(handles, axToPlot);
        case 'Ground Track'
            plotGroundTrack(handles, axToPlot);
    end
    
function plotPitchProfile(handles, axToPlot)
	maData = getappdata(handles.ma_MainGUI,'ma_data');
    pitchProfile = maData.launch.pitchProfile;
    pitchInterp = maData.launch.pitchInterp;
    ascentDur = maData.launch.ascentDuration;
    
    xPts = [pitchProfile{:,1}]';
    yPts = [pitchProfile{:,2}]';
    cfit = fit(xPts,yPts,pitchInterp);
    
    cFitTArr = linspace(0, ascentDur, 100);
    cFitCurve = cfit(cFitTArr);
    
    axes(axToPlot);
    hold on;
    plot([min(cFitTArr), pitchProfile{:,1}, max(cFitTArr)],[pitchProfile{1,3}, pitchProfile{:,3}, pitchProfile{end,3}],'o-c','MarkerFaceColor','c','MarkerEdgeColor','k');
    plot([min(cFitTArr), pitchProfile{:,1}, max(cFitTArr)],[pitchProfile{1,4}, pitchProfile{:,4}, pitchProfile{end,4}],'o-b','MarkerFaceColor','b','MarkerEdgeColor','k');
    plot(cFitTArr,cFitCurve,'r');
    plot(xPts,yPts,'o','MarkerFaceColor','r','MarkerEdgeColor','k');
    xlim([min(cFitTArr), max(cFitTArr)]);
    
    hold off;
    xlabel('Time [sec]');
    ylabel('Pitch [deg]');
    grid on;
    
function plotStateVsTime(handles, axToPlot)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    T = maData.launch.results.T;
    Y = maData.launch.results.Y;
    
    [bodyInfo, ~] = getBodyInfoForLaunchSite(maData, celBodyData);
    
    alt = sqrt(sum(Y(:,1:3).^2,2)) - bodyInfo.radius;
    speed = sqrt(sum(Y(:,4:6).^2,2));
    
    axes(axToPlot);
    hold on
    [AX,~,~] = plotyy(T, alt, T, speed);
    xlabel('Time [sec]');
    ylabel(AX(1), 'Altitude [km]');
    ylabel(AX(2), 'Speed [km/s]');
    grid on;
    hold off;
    
function plotVerticalSpeed(handles, axToPlot)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    T = maData.launch.results.T;
    Y = maData.launch.results.Y;
    
    rVects = Y(:,1:3)';
    vVects = Y(:,4:6)';
    vSpeed = zeros(1,size(rVects,2));
	for(i=1:size(rVects,2))
        vVect = vVects(:,i);
        rVect = rVects(:,i);
        c = dotARH(vVect,rVect)/norm(rVect)^2*rVect;
        vSpeed(i) = norm(c);
        
        if(dotARH(vVect,rVect) < 0)
            vSpeed(i) = -vSpeed(i);
        end
	end
    
    axes(axToPlot);
    hold on
    plot(T, vSpeed);
    xlabel('Time [sec]');
    ylabel('Vertical Speed [km/s]');
    grid on;
    hold off;
    
function plotGroundTrack(handles, axToPlot)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    T = maData.launch.results.T;
    Y = maData.launch.results.Y;
    
    [bodyInfo, ~] = getBodyInfoForLaunchSite(maData, celBodyData);
    
    rVects = Y(:,1:3)';
    
    lats = zeros(size(T));
    lons = zeros(size(T));
    for(i=1:length(T))
        ut = T(i);
        rVectECI = rVects(:,i);
        [lat, long, ~] = getLatLongAltFromInertialVect(ut, rVectECI, bodyInfo);
        
        lats(i) = rad2deg(lat);
        lons(i) = rad2deg(long) - 180;
    end
    
    axes(axToPlot);
    plot(axToPlot, lons, lats,'r','LineWidth',1.5);
    xlim([-180 180]);
    ylim([-90 90]);
    xlabel('Longitude [degE]');
    ylabel('Latitude [degN]');
    axToPlot.XTick = [-180:30:180];
    axToPlot.YTick = [-90:15:90];
    grid on;
    

function optimizeTrajectory(handles)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    liftoffUt = maData.launch.liftoffUT;
    
    tArr = liftoffUt + [maData.launch.pitchProfile{:,1}]';
    pitch = deg2rad([maData.launch.pitchProfile{:,2}]);
    pitchLB = deg2rad([maData.launch.pitchProfile{:,3}]);
    pitchUB = deg2rad([maData.launch.pitchProfile{:,4}]);
    
    launchHdg = deg2rad(maData.launch.launchHeading);
    launchHdgLB = launchHdg - deg2rad(5);
    launchHdgUB = launchHdg + deg2rad(5);
    
    lvDef = maData.launch.lvDef;
    cumData = getStageData(lvDef);
    maxCoast = maData.launch.maxCoast;
    maxBurnTime = sum(cumData(:,1));
    maxAscentTime = maxBurnTime + size(lvDef,1)*maxCoast;
    
    durScaleFact = 100;
    ascentDur = maData.launch.ascentDuration/durScaleFact;
    ascntDurLB = ascentDur/100/durScaleFact;
    ascntDurUB = maxAscentTime/durScaleFact;
    
    coast = [lvDef{:,6}]/durScaleFact;
    coastLB = 0 * ones(size(coast))/durScaleFact;
    coastUB = maData.launch.maxCoast * ones(size(coast))/durScaleFact;
    
    x0 = horzcat(pitch, launchHdg, ascentDur, coast);
    lb = horzcat(pitchLB, launchHdgLB, ascntDurLB, coastLB);
    ub = horzcat(pitchUB, launchHdgUB, ascntDurUB, coastUB);
    
    inds = [1, length(pitch);
            length(pitch)+1, length(pitch)+1;
            length(pitch)+2, length(pitch)+2;
            length(pitch)+2+1, length(pitch)+2+length(coast)];
    
    [bodyInfo, station] = getBodyInfoForLaunchSite(maData, celBodyData);
    rVect0 = getInertialVectFromLatLongAlt(liftoffUt, station.lat, station.long, station.alt, bodyInfo, [NaN;NaN;NaN]);
    
    rotRate = 2*pi/bodyInfo.rotperiod;
    radius = bodyInfo.radius + station.alt;
    speed0 = cos(station.lat) * (rotRate * radius);
    vVect0 = cross([0,0,1],rVect0);
    vVect0 = speed0 * vVect0'/norm(vVect0);
    
    pitchInterp = maData.launch.pitchInterp;
    gmu = bodyInfo.gm;
    
    smaD = maData.launch.orbit.sma;
    eccD = maData.launch.orbit.ecc;
	incD = maData.launch.orbit.inc;
    raanD = maData.launch.orbit.raan;
    argD = maData.launch.orbit.arg;
    bodyRadius = bodyInfo.radius;
    atmoHgt = bodyInfo.atmohgt;
    
    A = zeros(1,length(x0));
    b = [];
    for(i=1:length(pitch)-1)
        A(i,i) = -1;
        A(i,i+1) = 1;
        b(i) = 0; %#ok<AGROW>
    end
    
    hWaitBar = waitbar(0,'Starting parallel processing job, please wait...');
    numCores = feature('numCores');
    parpool('local',numCores-1);
    close(hWaitBar);
    
    oFun = @(x) launchAscentObjFunc(x, rVect0, vVect0, lvDef, tArr, liftoffUt, pitchInterp, gmu, bodyInfo, inds, durScaleFact);
    nonlcon = @(x) launchAscentCons(x, oFun, smaD, eccD, incD, raanD, argD, bodyRadius, atmoHgt);
    options = optimoptions('fmincon','Display','iter','UseParallel',true,'TolX',1E-10,'TolCon',1E-6,'TolFun',1E-6,'ScaleProblem','obj-and-constr','PlotFcns',{@optimplotx, @optimplotfval, @optimplotconstrviolation});
    x = fmincon(oFun,x0,A,b,[],[],lb,ub,nonlcon,options);
    delete(gcp);
    
    for(i=inds(1,1):inds(1,2))
        maData.launch.pitchProfile{i,2} = rad2deg(x(i));
    end
    maData.launch.launchHeading = rad2deg(x(inds(2,1)));
    maData.launch.ascentDuration = durScaleFact * x(inds(3,1));
    j=1;
    for(i=inds(4,1):inds(4,2))
        maData.launch.lvDef{j,6} = durScaleFact*x(i);
        j=j+1;
    end
    
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    
    set(handles.launchHeadingText,'String',num2str(maData.launch.launchHeading));    
    set(handles.ascentDurText,'String',num2str(maData.launch.ascentDuration));
    set(handles.pitchProfileTable,'Data',maData.launch.pitchProfile);
    set(handles.lvDefTable,'Data',maData.launch.lvDef);
    
    postInputUpdate(handles);
    
    
function [f, sma, ecc, inc, raan, arg, tru, T, Y, pitchFit, heading, bodyInfo] = execOneTraj(handles)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    liftoffUt = maData.launch.liftoffUT;
    
    lvDef = maData.launch.lvDef;
    
    durScaleFact = 100;
    ascentDur = maData.launch.ascentDuration/durScaleFact;
    tArr = liftoffUt + [maData.launch.pitchProfile{:,1}]';
    pitch = deg2rad([maData.launch.pitchProfile{:,2}]);    
    launchHdg = deg2rad(maData.launch.launchHeading);
    coast = [lvDef{:,6}]/durScaleFact;
    x0 = horzcat(pitch, launchHdg, ascentDur, coast);
    
    inds = [1, length(pitch);
            length(pitch)+1, length(pitch)+1;
            length(pitch)+2, length(pitch)+2;
            length(pitch)+2+1, length(pitch)+2+length(coast)];
    
    [bodyInfo, station] = getBodyInfoForLaunchSite(maData, celBodyData);
    rVect0 = getInertialVectFromLatLongAlt(liftoffUt, station.lat, station.long, station.alt, bodyInfo, [NaN;NaN;NaN]);
    
    rotRate = 2*pi/bodyInfo.rotperiod;
    radius = bodyInfo.radius + station.alt;
    speed0 = cos(station.lat) * (rotRate * radius);
    vVect0 = cross([0,0,1],rVect0);
    vVect0 = speed0 * vVect0'/norm(vVect0);
    
    pitchInterp = maData.launch.pitchInterp;
    gmu = bodyInfo.gm;
    
    [f, sma, ecc, inc, raan, arg, tru, T, Y, pitchFit, heading] = launchAscentObjFunc(x0, rVect0, vVect0, lvDef, tArr, liftoffUt, pitchInterp, gmu, bodyInfo, inds, durScaleFact);
    a = 1;
       
function plot3DLaunchVehicleTraj(handles, hAxes, bodyInfo)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    Y = maData.launch.results.Y;

    rVect = Y(end,1:3)';
    vVect = Y(end,4:6)';
    [sma, ecc, inc, raan, arg, ~] = getKeplerFromState(rVect,vVect,bodyInfo.gm);
    
    [vAz,vEl] = view(hAxes);

    cla(hAxes,'reset');
    axes(hAxes);
    ma_initOrbPlot([], hAxes, bodyInfo);
    
    hold on;
    plot3(Y(:,1),Y(:,2),Y(:,3),'Color','r','LineWidth',3);
	plotOrbit([0,0,0], maData.launch.orbit.sma, maData.launch.orbit.ecc, maData.launch.orbit.inc, ...
                       maData.launch.orbit.raan, maData.launch.orbit.arg, 0, 2*pi, bodyInfo.gm, hAxes, [], [], '--');
	plotOrbit([1,0,0], sma, ecc, inc, raan, arg, 0, 2*pi, bodyInfo.gm, hAxes, [], [], '--');
    axis equal;
    grid on;
    hold off;
    
    view(hAxes,[vAz,vEl]);
    
function updateFinalStateLabel(handles, bodyInfo)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    T = maData.launch.results.T;
    Y = maData.launch.results.Y;

    lvDef = maData.launch.lvDef;
    liftoffUt = maData.launch.liftoffUT;
    lvPerfTable = getLVPerfTable(lvDef, liftoffUt);

    ut = T(end);
    perfRow = lvPerfTable(lvPerfTable(:,1) <= ut & ut < lvPerfTable(:,2),:);
    dryMass = perfRow(7);
    fuelMass = Y(end,7);
    
    stateLog = [ut, Y(end,1:3), Y(end,4:6), bodyInfo.id, dryMass, fuelMass, 0.0, 0.0, 1];

    ma_UpdateStateReadout(handles.finalStateLabel, 'final', maData, stateLog, celBodyData);
    
function postInputUpdate(handles)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    
    [f, sma, ecc, inc, raan, arg, tru, T, Y, pitchFit, heading, bodyInfo] = execOneTraj(handles);
    maData.launch.results.T = T;
    maData.launch.results.Y = Y;
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    
    updateLvDefLabels(handles);
    updateLaunchSiteLabels(handles);
    plotLowerAxes(handles);
    plot3DLaunchVehicleTraj(handles, handles.trajPlotAxes, bodyInfo);
    updateFinalStateLabel(handles, bodyInfo);    



% --- Outputs from this function are returned to the command line.
function varargout = ma_LaunchTrajectoryGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in addPitchPtButton.
function addPitchPtButton_Callback(hObject, eventdata, handles)
% hObject    handle to addPitchPtButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    pitchProfile = maData.launch.pitchProfile;
        
    pitchProfile(end+1,:) = {pitchProfile{end,1}+1,0, 0, 90};
    maData.launch.pitchProfile = pitchProfile;
    set(handles.pitchProfileTable,'Data',pitchProfile);

    if(size(pitchProfile,1) <= 1)
        set(handles.delPitchPtButton,'Enable','off');
    else
        set(handles.delPitchPtButton,'Enable','on');
    end
    
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    postInputUpdate(handles);

% --- Executes on button press in delPitchPtButton.
function delPitchPtButton_Callback(hObject, eventdata, handles)
% hObject    handle to delPitchPtButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    pitchProfile = maData.launch.pitchProfile;
    
    selInd = get(handles.pitchProfileTable,'UserData');
    if(~isempty(selInd) && size(pitchProfile,1) >= selInd(1))
        pitchProfile(selInd(1),:) = [];

        maData.launch.pitchProfile = pitchProfile;
        set(handles.pitchProfileTable,'Data',pitchProfile);

        if(size(pitchProfile,1) <= 1)
            set(handles.delPitchPtButton,'Enable','off');
        else
            set(handles.delPitchPtButton,'Enable','on');
        end

        setappdata(handles.ma_MainGUI,'ma_data',maData);
        postInputUpdate(handles);
    end

% --- Executes on button press in addStageButton.
function addStageButton_Callback(hObject, eventdata, handles)
% hObject    handle to addStageButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    lvDef = maData.launch.lvDef;
    
    newStageNum = size(lvDef,1)+1; 
    
    lvDef(end+1,:) = {newStageNum, 5, 30, 650, 450, 184, 1};
    maData.launch.lvDef = lvDef;
    set(handles.lvDefTable,'Data',lvDef);

    if(size(lvDef,1) <= 1)
        set(handles.delStageButton,'Enable','off');
    else
        set(handles.delStageButton,'Enable','on');
    end
    
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    postInputUpdate(handles);

% --- Executes on button press in delStageButton.
function delStageButton_Callback(hObject, eventdata, handles)
% hObject    handle to delStageButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    lvDef = maData.launch.lvDef;
    
    selInd = get(handles.lvDefTable,'UserData');
    if(~isempty(selInd) && size(lvDef,1) >= selInd(1))
        lvDef(selInd(1),:) = [];

        for(i=1:size(lvDef,1))
            lvDef{i,1} = i;
        end

        maData.launch.lvDef = lvDef;
        set(handles.lvDefTable,'Data',lvDef);

        if(size(lvDef,1) <= 1)
            set(handles.delStageButton,'Enable','off');
        else
            set(handles.delStageButton,'Enable','on');
        end

        setappdata(handles.ma_MainGUI,'ma_data',maData);
        postInputUpdate(handles);
    end
    

function smaText_Callback(hObject, eventdata, handles)
% hObject    handle to smaText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of smaText as text
%        str2double(get(hObject,'String')) returns contents of smaText as a double
    maData = getappdata(handles.ma_MainGUI,'ma_data');

    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

    errMsg = {};
    
    value = str2double(get(handles.smaText,'String'));
    enteredStr = get(handles.smaText,'String');
    numberName = 'Target SMA';
    lb = 1;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
        
    if(~isempty(errMsg))
        msgbox(errMsg,'Error Found in Entry','error');
        set(handles.smaText, 'String', num2str(maData.launch.orbit.sma));
        return;
    end
    
    maData.launch.orbit.sma = value;
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    
    postInputUpdate(handles);
    

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
    maData = getappdata(handles.ma_MainGUI,'ma_data');

    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

    errMsg = {};
    
    value = str2double(get(handles.eccText,'String'));
    enteredStr = get(handles.eccText,'String');
    numberName = 'Target Eccentricity';
    lb = 0;
    ub = 0.999999999;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
        
    if(~isempty(errMsg))
        msgbox(errMsg,'Error Found in Entry','error');
        set(handles.eccText, 'String', num2str(maData.launch.orbit.ecc));
        return;
    end
    
    maData.launch.orbit.ecc = value;
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    
    postInputUpdate(handles);

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
    maData = getappdata(handles.ma_MainGUI,'ma_data');

    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

    errMsg = {};
    
    value = str2double(get(handles.incText,'String'));
    enteredStr = get(handles.incText,'String');
    numberName = 'Target Inclination';
    lb = 0;
    ub = 180;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
        
    if(~isempty(errMsg))
        msgbox(errMsg,'Error Found in Entry','error');
        set(handles.incText, 'String', num2str(rad2deg(maData.launch.orbit.inc)));
        return;
    end
    
    maData.launch.orbit.inc = deg2rad(value);
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    
    postInputUpdate(handles);

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
    maData = getappdata(handles.ma_MainGUI,'ma_data');

    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

    errMsg = {};
    
    value = str2double(get(handles.raanText,'String'));
    enteredStr = get(handles.raanText,'String');
    numberName = 'Target RAAN';
    lb = 0;
    ub = 360;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
        
    if(~isempty(errMsg))
        msgbox(errMsg,'Error Found in Entry','error');
        set(handles.raanText, 'String', num2str(rad2deg(maData.launch.orbit.raan)));
        return;
    end
    
    maData.launch.orbit.raan = deg2rad(value);
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    
    postInputUpdate(handles);

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
    maData = getappdata(handles.ma_MainGUI,'ma_data');

    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

    errMsg = {};
    
    value = str2double(get(handles.argText,'String'));
    enteredStr = get(handles.argText,'String');
    numberName = 'Target RAAN';
    lb = 0;
    ub = 360;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
        
    if(~isempty(errMsg))
        msgbox(errMsg,'Error Found in Entry','error');
        set(handles.argText, 'String', num2str(rad2deg(maData.launch.orbit.arg)));
        return;
    end
    
    maData.launch.orbit.arg = deg2rad(value);
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    
    postInputUpdate(handles);

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


% --- Executes on selection change in stationCombo.
function stationCombo_Callback(hObject, eventdata, handles)
% hObject    handle to stationCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns stationCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from stationCombo
    maData = getappdata(handles.ma_MainGUI,'ma_data');

    staVal = get(hObject,'Value');
    stations = maData.spacecraft.stations;

    maData.launch.station = stations{staVal}.id;
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    
    postInputUpdate(handles);
    
% --- Executes during object creation, after setting all properties.
function stationCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stationCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in importOrbitFromInitStateButton.
function importOrbitFromInitStateButton_Callback(hObject, eventdata, handles)
% hObject    handle to importOrbitFromInitStateButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    stateLog = maData.stateLog;
    
    bodyInfo = getBodyInfoByNumber(stateLog(1,8), celBodyData);
    
    rVect = stateLog(1,2:4);
    vVect = stateLog(1,5:7);
    gmu = bodyInfo.gm;
    
    [sma, ecc, inc, raan, arg, ~] = getKeplerFromState(rVect,vVect,gmu);
    
    maData.launch.orbit.sma = sma;
    maData.launch.orbit.ecc = ecc;
    maData.launch.orbit.inc = inc;
    maData.launch.orbit.raan = raan;
    maData.launch.orbit.arg = arg;
    
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    
    set(handles.smaText,'String',num2str(sma));
    set(handles.eccText,'String',num2str(ecc));
    set(handles.incText,'String',num2str(rad2deg(inc)));
    set(handles.raanText,'String',num2str(rad2deg(raan)));
    set(handles.argText,'String',num2str(rad2deg(arg)));
    
    postInputUpdate(handles);

% --- Executes on selection change in pitchInterpCombo.
function pitchInterpCombo_Callback(hObject, eventdata, handles)
% hObject    handle to pitchInterpCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pitchInterpCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pitchInterpCombo
    maData = getappdata(handles.ma_MainGUI,'ma_data');

    oldInterp = maData.launch.pitchInterp;
    
    contents = cellstr(get(hObject,'String'));
    maData.launch.pitchInterp = contents{get(hObject,'Value')};
    setappdata(handles.ma_MainGUI,'ma_data',maData);

    try
        postInputUpdate(handles);
    catch ME
        maData.launch.pitchInterp = oldInterp;
        setappdata(handles.ma_MainGUI,'ma_data',maData);
        set(handles.pitchInterpCombo,'Value',findValueFromComboBox(oldInterp, handles.pitchInterpCombo));
    end


% --- Executes during object creation, after setting all properties.
function pitchInterpCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pitchInterpCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when entered data in editable cell(s) in pitchProfileTable.
function pitchProfileTable_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to pitchProfileTable (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    set(hObject,'UserData',eventdata.Indices);
    
    newData = eventdata.NewData;
    if(~isempty(newData))
        maData.launch.pitchProfile = get(handles.pitchProfileTable,'Data');
        maData.launch.pitchProfile = sortrows(maData.launch.pitchProfile,1);
        set(handles.pitchProfileTable,'Data',maData.launch.pitchProfile);
    end
    setappdata(handles.ma_MainGUI,'ma_data',maData);

    postInputUpdate(handles);



function liftoffUtText_Callback(hObject, eventdata, handles)
% hObject    handle to liftoffUtText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of liftoffUtText as text
%        str2double(get(hObject,'String')) returns contents of liftoffUtText as a double
    maData = getappdata(handles.ma_MainGUI,'ma_data');

    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

    errMsg = {};
    
    value = str2double(get(handles.liftoffUtText,'String'));
    enteredStr = get(handles.liftoffUtText,'String');
    numberName = 'Liftoff Time (UT)';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
        
    if(~isempty(errMsg))
        msgbox(errMsg,'Error Found in Entry','error');
        set(handles.liftoffUtText, 'String', num2str(maData.launch.liftoffUT));
        return;
    end
    
    maData.launch.liftoffUT = value;
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    
    postInputUpdate(handles);

% --- Executes during object creation, after setting all properties.
function liftoffUtText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to liftoffUtText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function launchHeadingText_Callback(hObject, eventdata, handles)
% hObject    handle to launchHeadingText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchHeadingText as text
%        str2double(get(hObject,'String')) returns contents of launchHeadingText as a double
    maData = getappdata(handles.ma_MainGUI,'ma_data');

    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

    errMsg = {};
    
    value = str2double(get(handles.launchHeadingText,'String'));
    enteredStr = get(handles.launchHeadingText,'String');
    numberName = 'Launch Heading';
    lb = 0;
    ub = 360;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
        
    if(~isempty(errMsg))
        msgbox(errMsg,'Error Found in Entry','error');
        set(handles.launchHeadingText, 'String', num2str(maData.launch.launchHeading));
        return;
    end
    
    maData.launch.launchHeading = value;
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    
    postInputUpdate(handles);

% --- Executes during object creation, after setting all properties.
function launchHeadingText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchHeadingText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ascentDurText_Callback(hObject, eventdata, handles)
% hObject    handle to ascentDurText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ascentDurText as text
%        str2double(get(hObject,'String')) returns contents of ascentDurText as a double
    maData = getappdata(handles.ma_MainGUI,'ma_data');

    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

    errMsg = {};
    
    value = str2double(get(handles.ascentDurText,'String'));
    enteredStr = get(handles.ascentDurText,'String');
    numberName = 'Launch Heading';
    lb = 0.1;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
        
    if(~isempty(errMsg))
        msgbox(errMsg,'Error Found in Entry','error');
        set(handles.ascentDurText, 'String', num2str(maData.launch.ascentDuration));
        return;
    end
    
    maData.launch.ascentDuration = value;
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    
    postInputUpdate(handles);


% --- Executes during object creation, after setting all properties.
function ascentDurText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ascentDurText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when entered data in editable cell(s) in lvDefTable.
function lvDefTable_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to lvDefTable (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    set(hObject,'UserData',eventdata.Indices);

    inds = eventdata.Indices;
    newData = eventdata.NewData;
    oldData = eventdata.PreviousData;
    if(~isempty(newData))
        maData.launch.lvDef = get(handles.lvDefTable,'Data');
    end
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    
    postInputUpdate(handles);


% --- Executes when selected cell(s) is changed in pitchProfileTable.
function pitchProfileTable_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to pitchProfileTable (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
    set(hObject,'UserData',eventdata.Indices);

% --- Executes when selected cell(s) is changed in lvDefTable.
function lvDefTable_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to lvDefTable (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
    set(hObject,'UserData',eventdata.Indices);


% --- Executes during object creation, after setting all properties.
function dataPlotButtonGrp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dataPlotButtonGrp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes when selected object is changed in dataPlotButtonGrp.
function dataPlotButtonGrp_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in dataPlotButtonGrp 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    plotLowerAxes(handles);


% --- Executes on button press in optimizeTrajButton.
function optimizeTrajButton_Callback(hObject, eventdata, handles)
% hObject    handle to optimizeTrajButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    optimizeTrajectory(handles);



function maxCoastDurText_Callback(hObject, eventdata, handles)
% hObject    handle to maxCoastDurText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxCoastDurText as text
%        str2double(get(hObject,'String')) returns contents of maxCoastDurText as a double
    maData = getappdata(handles.ma_MainGUI,'ma_data');

    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

    errMsg = {};
    
    value = str2double(get(handles.maxCoastDurText,'String'));
    enteredStr = get(handles.maxCoastDurText,'String');
    numberName = 'Max Coast Duration';
    lb = 0.1;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
        
    if(~isempty(errMsg))
        msgbox(errMsg,'Error Found in Entry','error');
        set(handles.maxCoastDurText, 'String', num2str(maData.launch.maxCoast));
        return;
    end
    
    maData.launch.maxCoast = value;
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    
    postInputUpdate(handles);
    

% --- Executes during object creation, after setting all properties.
function maxCoastDurText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxCoastDurText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
