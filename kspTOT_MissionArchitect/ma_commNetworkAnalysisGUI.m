function varargout = ma_commNetworkAnalysisGUI(varargin)
% MA_COMMNETWORKANALYSISGUI MATLAB code for ma_commNetworkAnalysisGUI.fig
%      MA_COMMNETWORKANALYSISGUI, by itself, creates a new MA_COMMNETWORKANALYSISGUI or raises the existing
%      singleton*.
%
%      H = MA_COMMNETWORKANALYSISGUI returns the handle to a new MA_COMMNETWORKANALYSISGUI or the handle to
%      the existing singleton*.
%
%      MA_COMMNETWORKANALYSISGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_COMMNETWORKANALYSISGUI.M with the given input arguments.
%
%      MA_COMMNETWORKANALYSISGUI('Property','Value',...) creates a new MA_COMMNETWORKANALYSISGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_commNetworkAnalysisGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_commNetworkAnalysisGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_commNetworkAnalysisGUI

% Last Modified by GUIDE v2.5 01-Jul-2015 16:22:27

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_commNetworkAnalysisGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_commNetworkAnalysisGUI_OutputFcn, ...
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


% --- Executes just before ma_commNetworkAnalysisGUI is made visible.
function ma_commNetworkAnalysisGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_commNetworkAnalysisGUI (see VARARGIN)

% Choose default command line output for ma_commNetworkAnalysisGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
handles.ma_MainGUI = varargin{1};
guidata(hObject, handles);

setUpGui(handles);

% UIWAIT makes ma_commNetworkAnalysisGUI wait for user response (see UIRESUME)
% uiwait(handles.ma_commNetworkAnalysisGUI);

function setUpGui(handles)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    stateLog = maData.stateLog;
    oSCs = maData.spacecraft.otherSC;
    stations = maData.spacecraft.stations;
    
    oScIds = [];
    if(~isempty(oSCs))
        oScStrs = {};
        for(i=1:length(oSCs)) %#ok<*NO4LP>
            oSC = oSCs{i};
            oScStrs{end+1} = getNameIdStr(oSC); %#ok<AGROW>
            oScIds(end+1) = oSC.id; %#ok<AGROW>
        end
        
        set(handles.otherSpacecraftListbox,'Enable','on')
        set(handles.otherSpacecraftListbox,'String',oScStrs);
        set(handles.otherSpacecraftListbox,'Value',1:length(oSCs));
    else
        set(handles.otherSpacecraftListbox,'Enable','off')
        set(handles.otherSpacecraftListbox,'String',noneStr());
        set(handles.otherSpacecraftListbox,'Value',1);
    end
    set(handles.otherSpacecraftListbox,'UserData',oScIds);
    
    stationIds = [];
    if(~isempty(stations))
        stationStrs = {};
        for(i=1:length(stations)) %#ok<*NO4LP>
            station = stations{i};
            stationStrs{end+1} = getNameIdStr(station); %#ok<AGROW>
            stationIds(end+1) = station.id; %#ok<AGROW>
        end
        
        set(handles.groundTargetsListbox,'Enable','on')
        set(handles.groundTargetsListbox,'String',stationStrs);
        set(handles.groundTargetsListbox,'Value',1:length(stations));
    else
        set(handles.groundTargetsListbox,'Enable','off')
        set(handles.groundTargetsListbox,'String',noneStr());
        set(handles.groundTargetsListbox,'Value',1);
    end
    set(handles.groundTargetsListbox,'UserData',stationIds);
    
    setStartEndNodeCombos(handles, true);
    
    set(handles.startTimeText,'String',fullAccNum2Str(stateLog(1,1)));
    set(handles.endTimeText,'String',fullAccNum2Str(stateLog(end,1)));
    
function str = noneStr()
    str = '--None--';
    
function str = getNameIdStr(oScStation)
    str = sprintf('%s', oScStation.name);

function avStruct = getActiveVesselPsuedoStruct()
    avStruct = struct();
    avStruct.id = 0.0;
    avStruct.name = 'Active Vessel';
    
function setStartEndNodeCombos(handles, initGui)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    useActive = get(handles.includeActiveVesselCheckbox,'Value');
    oSCs = maData.spacecraft.otherSC;
    stations = maData.spacecraft.stations;
    
    contents = cellstr(get(handles.commPathOriginCombo,'String'));
    originSel = contents{get(handles.commPathOriginCombo,'Value')};
    
    contents = cellstr(get(handles.commPathTerminusCombo,'String'));
    termSel = contents{get(handles.commPathTerminusCombo,'Value')};

    comboStrs = {};
    if(useActive)
        comboStrs{end+1} = getNameIdStr(getActiveVesselPsuedoStruct());
    end
    
    if(~isempty(oSCs))
        oScValues = get(handles.otherSpacecraftListbox,'Value');
        for(i=1:length(oScValues))
            oScValue = oScValues(i);
            comboStrs{end+1} = getNameIdStr(oSCs{oScValue}); %#ok<AGROW>
        end
    end
    
    if(~isempty(stations))
        stationValues = get(handles.groundTargetsListbox,'Value');
        for(i=1:length(stationValues))
            stationValue = stationValues(i);
            comboStrs{end+1} = getNameIdStr(stations{stationValue}); %#ok<AGROW>
        end
    end
    
    setDisabled = false;
    if(isempty(comboStrs))
        comboStrs = {noneStr()};
        setDisabled = true;
    end
    
    set(handles.commPathOriginCombo,'String',comboStrs);
    set(handles.commPathTerminusCombo,'String',comboStrs);
    
    if(setDisabled)
        set(handles.commPathOriginCombo,'Enable','off');
        set(handles.commPathTerminusCombo,'Enable','off');
    else
        set(handles.commPathOriginCombo,'Enable','on');
        set(handles.commPathTerminusCombo,'Enable','on');
    end
    
    if(initGui == false)
        if(~strcmpi(originSel,noneStr()))
            ind = find(strcmpi(comboStrs, originSel),1,'first');
            if(~isempty(ind))
                set(handles.commPathOriginCombo,'Value',ind);
            else
                set(handles.commPathOriginCombo,'Value',1);
            end
        else
            set(handles.commPathOriginCombo,'Value',1);
        end
        
        if(~strcmpi(termSel,noneStr()))
            ind = find(strcmpi(comboStrs, termSel),1,'first');
            if(~isempty(ind))
                set(handles.commPathTerminusCombo,'Value',ind);
            else
                set(handles.commPathTerminusCombo,'Value',1);
            end
        else
            set(handles.commPathTerminusCombo,'Value',1);
        end
    end
    

% --- Outputs from this function are returned to the command line.
function varargout = ma_commNetworkAnalysisGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in performNetworkAnalysisButton.
function performNetworkAnalysisButton_Callback(hObject, eventdata, handles)
% hObject    handle to performNetworkAnalysisButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(~isempty(errMsg))
        msgbox(errMsg,'Errors were found while validating your split value.  Please sure value is between the given bounds.','error');
        return;
    end
    
    matSave = getappdata(handles.ma_MainGUI,'current_save_location');
    if(not(isempty(matSave)))
        [pathstr,name,~] = fileparts(matSave);
        outputFilePath = [pathstr,'\',name,'_CommNetworkAnalysis_',datestr(now,'yyyymmdd_HHMMSS'),'.csv'];
    else
        [FileName,PathName,~] = uiputfile('*.csv','Select Output File','commAnalysis.csv');
        if(ischar(FileName))
            outputFilePath = [PathName,FileName];
        else
            outputFilePath = '';
        end
    end

	maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    stateLog = maData.stateLog;
    useActive = get(handles.includeActiveVesselCheckbox,'Value');
    oSCs = maData.spacecraft.otherSC;
    stations = maData.spacecraft.stations;

    startTime = str2double(get(handles.startTimeText,'String'));
    endTime = str2double(get(handles.endTimeText,'String'));
    rangeMulti = str2double(get(handles.rangeMultiText,'String'));
    
    contents = cellstr(get(handles.rangeModelCombo,'String'));
    rangeModelStr = contents{get(handles.rangeModelCombo,'Value')};

    if(useActive)
        indOffset = 1;
    else
        indOffset = 0;
    end

    selOsc = get(handles.otherSpacecraftListbox,'Value');
    numSelOsc = length(selOsc);
    selSta = get(handles.groundTargetsListbox,'Value');
    numselSta = length(selSta);
    
    if(numSelOsc > 0 && ~isempty(oSCs))
        oScInds = [1+indOffset : (indOffset)+numSelOsc];
    else
        oScInds = [];
    end
    
    if(numselSta > 0 && ~isempty(stations))
        if(~isempty(oScInds))
            scOffset = oScInds(end);
        else
            scOffset = indOffset;
        end
        stationInds = [1+scOffset : scOffset+numselSta];
    else
        stationInds = [];
    end
        
    originVal = get(handles.commPathOriginCombo,'Value');
    termVal = get(handles.commPathTerminusCombo,'Value');
    
    nodes = {};
    for(i=1:length(get(handles.commPathOriginCombo,'String')))
        if(ismember(i,oScInds))
            Lia = find(i==oScInds,1,'first');
            
            nType = 'osc';
            obj = oSCs{selOsc(Lia)};
        elseif(ismember(i,stationInds))
            Lia = find(i==stationInds,1,'first');
            
            nType = 'station';
            obj = stations{selSta(Lia)};
        else
            nType = 'active_vessel';
            obj = struct('name','Active Vessel');
        end

        nodes(i,:) = {i, nType, obj, []}; %#ok<AGROW>
    end
    
    hWaitBar = waitbar(0,'');
    
    bodyNames = fieldnames(celBodyData);
    bodyInfoSun = celBodyData.sun;
    timeSteps = stateLog(:,1);
    timeSteps = timeSteps(timeSteps >= startTime & timeSteps <= endTime);
    tOffset = find(timeSteps(1)==stateLog(:,1),1,'first')-1;
    resultsArr = {};
    for(i=1:length(timeSteps))
        time = timeSteps(i);
        waitbar((i-1)/length(timeSteps), hWaitBar, sprintf('Computing network path for t = %0.3f sec.\n[%u of %u]', time, i, length(timeSteps)));

        G = sparse([]);
        for(j=1:size(nodes,1))
            node = nodes(j,:);
            
            switch node{2}
                case 'active_vessel'
                    nodeBodyID = stateLog(i+tOffset,8);
                    nodeBodyInfo = getBodyInfoByNumber(nodeBodyID, celBodyData);
                    maxCommRange = maData.spacecraft.comm.maxCommRange;
                    
                    rVectNode = stateLog(i+tOffset,2:4);
                case 'osc'
                    osc = node{3};
                    nodeBodyID = osc.parentID;
                    nodeBodyInfo = getBodyInfoByNumber(nodeBodyID, celBodyData);
                    maxCommRange = osc.maxCommRange;
                    
                    tru = computeTrueAnomFromMean(deg2rad(osc.mean), osc.ecc);
                    rVectNode = getStatefromKepler(osc.sma, osc.ecc, deg2rad(osc.inc), deg2rad(osc.raan), deg2rad(osc.arg), tru, nodeBodyInfo.gm);
                case 'station'
                    sta = node{3};
                    nodeBodyID = sta.parentID;
                    nodeBodyInfo = getBodyInfoByNumber(nodeBodyID, celBodyData);
                    maxCommRange = sta.maxCommRange;
                    
                    rVectNode = getInertialVectFromLatLongAlt(time, sta.lat, sta.long, sta.alt, nodeBodyInfo, [NaN;NaN;NaN]);
            end
            rVectNode = reshape(rVectNode, 3, 1);
            
            rVect = -getAbsPositBetweenSpacecraftAndBody(time, rVectNode, nodeBodyInfo, bodyInfoSun, celBodyData);
            nodes{j,4} = reshape(rVect, 3, 1); %#ok<AGROW>
            nodes{j,5} = reshape(rVectNode, 3, 1); %#ok<AGROW>
            nodes{j,6} = nodeBodyInfo; %#ok<AGROW>
            nodes{j,7} = maxCommRange; %#ok<AGROW>
        end
        
        for(j=1:size(nodes,1))
            for(k=1:size(nodes,1))
                if(k <= j)
                    continue;
                end
                absRVect1 = nodes{j,4};
                absRVect2 = nodes{k,4};
                
                LoSArr = [];
                for(l=1:length(bodyNames))
                    eclipseBodyInfo = celBodyData.(bodyNames{l});
                    LoS = LoS2TargetComm(time, absRVect1, bodyInfoSun, absRVect2, eclipseBodyInfo, celBodyData);
                    
                    LoSArr(end+1) = LoS; %#ok<AGROW>
                    if(LoS == 0)
                        break;
                    end
                end
                
                if(all(LoSArr))
                    dist = norm(absRVect2 - absRVect1);
                    node1MaxRng = nodes{j,7};
                    node2MaxRng = nodes{k,7};
                    validBool = isValidPath(dist, node1MaxRng, node2MaxRng, rangeModelStr, rangeMulti);
                    if(validBool)
                        G(j,k) = dist; %#ok<SPRIX>
                        G(k,j) = dist; %#ok<SPRIX>
                    end
                end
            end
        end
        
        try
            [dist, path, ~] = graphshortestpath(G, originVal, termVal, 'Directed', false);
            if(isempty(path))
                solFound = false;
            else
                solFound = true;
            end
        catch ME
            dist = 0;
            path = [];
            solFound = false;
        end
        
        if(dist == Inf)
            dist = 0;
            path = [];
            solFound = false;
        end
        
        if(solFound == true)
            [pathStr, pathDist, pathDistOfMax] = getHopsStrDists(path, G, nodes, rangeModelStr, rangeMulti);
        else
            pathStr = ' ';
            pathDist = 0;
            pathDistOfMax = 0;
        end

        if(isempty(path))
            numHops = 0;
        else
            numHops = length(path)-1;
        end
        nodesInUse = NaN(size(nodes,1),1);
        for(j=1:length(path))
            nodesInUse(path(j)) = path(j);
        end
        resRow = {time, solFound, dist, pathStr, max(pathDist), 100*max(pathDistOfMax), numHops, nodesInUse};
        resultsArr(end+1,:) = resRow; %#ok<AGROW>
    end
    close(hWaitBar);
    
    times = [resultsArr{:,1}];
    nodesInUse = [resultsArr{:,8}];
    nodeNames = {};
    
    hFig = figure();
    ax = subplot(2,2,1);
    hold on;
    for(i=1:size(nodesInUse,1))
        nodeNames{end+1} = nodes{i,3}.name; %#ok<AGROW>
        plot(times, nodesInUse(i,:),'k','LineWidth',2)
    end
    xlim([timeSteps(1),timeSteps(end)]);
    ylim([0,size(nodes,1)+1]);
    ax.YTick = [nodes{:,1}];
    ax.YTickLabel = nodeNames;
    xlabel('UT Time [sec]');
    hold off;
    grid on;
    title(ax,'Comm Nodes In Use');
        
    ax = subplot(2,2,2);
    [AX,H1,H2] = plotyy(times, [resultsArr{:,3}], times, [resultsArr{:,3}]./getSpeedOfLightKmSec());
    H1.LineWidth = 2;
    H1.Color = 'k';
	H2.LineWidth = 2;
    H2.Color = 'k';
    xlabel('UT Time [sec]');
    ylabel(AX(1), 'Total Path Distance [km]','Color','k');
    ylabel(AX(2), 'One-Way Light Time [sec]','Color','k');
	grid(AX(1),'on');
	grid(AX(2),'on');
    xlim([timeSteps(1),timeSteps(end)]);
    v = axis(ax);
    if(v(3) < 0)
        ylim([0,v(4)]);
    end
    
    subplot(2,2,3);
    plot(times, [resultsArr{:,7}],'k','LineWidth',2)
    xlabel('UT Time [sec]');
    ylabel('Number of Hops');
    xlim([timeSteps(1),timeSteps(end)]);
    ylim([0, max([resultsArr{:,7}])+1])
    grid on;
    
    ax = subplot(2,2,4);
    plot(times, [resultsArr{:,6}],'k','LineWidth',2)
    xlabel('UT Time [sec]');
    ylabel('Largest Hop Distance [%Max]');
    grid on;
    v = axis(ax);
    xlim([timeSteps(1),timeSteps(end)]);
    ylim([0,v(4)]);
    
    whitebg(hFig);
       
    if(~isempty(outputFilePath))
        colNames = {'UT_sec', 'Path_Exists', 'Path_Dist_km', 'Path', 'Max_Hop_Dist_km', 'Largest_Hop_Distance_Percent_Max', 'Num_Hops'};
        T = cell2table(resultsArr(:,1:7));
        T.Properties.VariableNames = colNames;
        writetable(T,outputFilePath);
        
        msgbox(sprintf('Comm network analysis output written to file: \n%s',outputFilePath), 'Comm Analysis Output', 'help');
    end
    
function [pathStr, pathDist, pathDistOfMax] = getHopsStrDists(path, G, nodes, rangeModelStr, rangeMulti)
    if(isempty(path))
        pathStr = ' ';
        pathDist = 0;
        pathDistOfMax = 0;
        
        return;
    end

	pathDist = [];
    pathStrArr = {};
    pathDistOfMax = [];
    for(i=1:length(path)-1)
        dist = G(path(i),path(i+1));
        pathDist(end+1) = dist; %#ok<AGROW>
        pathStrArr(end+1) = {nodes{path(i),3}.name};
        
        node1MaxRng = nodes{path(i),7};
        node2MaxRng = nodes{path(i+1),7};
        
        [~,maxRange] = isValidPath(dist, node1MaxRng, node2MaxRng, rangeModelStr, rangeMulti);
        pathDistOfMax(end+1) = dist/maxRange;
    end
    pathStrArr(end+1) = {nodes{path(end),3}.name};
    
    pathStr = sprintf('[%s]',strjoin(pathStrArr,' -> '));

    
function [bool, maxRange] = isValidPath(dist, node1MaxRng, node2MaxRng, rangeModelStr, rangeMulti)
    switch strip(rangeModelStr)
        case 'Standard'    
            maxRange = min(node1MaxRng, node2MaxRng);
        case 'Additive/Root'
            maxRange = min(node1MaxRng, node2MaxRng) + sqrt(node1MaxRng * node2MaxRng);
        case 'Stock'
            maxRange = sqrt(node1MaxRng * node2MaxRng);
    end
    maxRange = rangeMulti * maxRange;
    
    bool = dist < maxRange;
    
    
function LoS = LoS2TargetComm(time, absRVect1, bodyInfoSun, absRVect2, eclipseBodyInfo, celBodyData)
    eBodyRad = eclipseBodyInfo.radius;
    rVectSC2EBody = getAbsPositBetweenSpacecraftAndBody(time, absRVect1, bodyInfoSun, eclipseBodyInfo, celBodyData);
    rVectSC2Target = absRVect2 - absRVect1;
    
    if(all(rVectSC2EBody==rVectSC2Target)) %eclipse body and target body are the same, eclipse not possible
        LoS = 1;
        return;
    end
    
    rVectDAng = dang(rVectSC2EBody,rVectSC2Target);                
    angleSizeOfEBody = atan(eBodyRad/norm(rVectSC2EBody));
    
    if(rVectDAng <= angleSizeOfEBody && norm(rVectSC2Target) > norm(rVectSC2EBody))
        LoS = 0; %we're in eclipse or we can't see the target
    else
        LoS = 1;
    end
    
    
function errMsg = validateInputs(handles)    
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    
    errMsg = {};
    
    stateLogMinUT = floor(maData.stateLog(1,1)*10000)/10000;
    stateLogMaxUT = ceil(maData.stateLog(end,1)*10000)/10000;
    
    value = str2double(get(handles.startTimeText,'String'));
    enteredStr = get(handles.startTimeText,'String');
    numberName = 'Start Time (UT)';
    lb = stateLogMinUT;
    ub = stateLogMaxUT;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    value = str2double(get(handles.endTimeText,'String'));
    enteredStr = get(handles.endTimeText,'String');
    numberName = 'End Time (UT)';
    lb = stateLogMinUT;
    ub = stateLogMaxUT;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        startUTEntered = str2double(get(handles.startTimeText,'String'));
        
        value = str2double(get(handles.endTimeText,'String'));
        enteredStr = get(handles.endTimeText,'String');
        numberName = 'End Time (UT)';
        lb = startUTEntered;
        ub = stateLogMaxUT;
        isInt = false;
        errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    end    
    
    value = str2double(get(handles.rangeMultiText,'String'));
    enteredStr = get(handles.rangeMultiText,'String');
    numberName = 'Range Multiplier';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(get(handles.commPathOriginCombo,'Value') == get(handles.commPathTerminusCombo,'Value'))
        errMsg{end+1} = 'The path origin and path terminus must be different.';
    end
    

% --- Executes on selection change in commPathOriginCombo.
function commPathOriginCombo_Callback(hObject, eventdata, handles)
% hObject    handle to commPathOriginCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns commPathOriginCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from commPathOriginCombo


% --- Executes during object creation, after setting all properties.
function commPathOriginCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to commPathOriginCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in commPathTerminusCombo.
function commPathTerminusCombo_Callback(hObject, eventdata, handles)
% hObject    handle to commPathTerminusCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns commPathTerminusCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from commPathTerminusCombo


% --- Executes during object creation, after setting all properties.
function commPathTerminusCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to commPathTerminusCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in includeActiveVesselCheckbox.
function includeActiveVesselCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to includeActiveVesselCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of includeActiveVesselCheckbox
    setStartEndNodeCombos(handles, false);

% --- Executes on selection change in otherSpacecraftListbox.
function otherSpacecraftListbox_Callback(hObject, eventdata, handles)
% hObject    handle to otherSpacecraftListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns otherSpacecraftListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from otherSpacecraftListbox
    setStartEndNodeCombos(handles, false);

% --- Executes during object creation, after setting all properties.
function otherSpacecraftListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to otherSpacecraftListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in groundTargetsListbox.
function groundTargetsListbox_Callback(hObject, eventdata, handles)
% hObject    handle to groundTargetsListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns groundTargetsListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from groundTargetsListbox
    setStartEndNodeCombos(handles, false);

% --- Executes during object creation, after setting all properties.
function groundTargetsListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to groundTargetsListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function startTimeText_Callback(hObject, eventdata, handles)
% hObject    handle to startTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of startTimeText as text
%        str2double(get(hObject,'String')) returns contents of startTimeText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function startTimeText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to startTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function endTimeText_Callback(hObject, eventdata, handles)
% hObject    handle to endTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of endTimeText as text
%        str2double(get(hObject,'String')) returns contents of endTimeText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function endTimeText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to endTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in rangeModelCombo.
function rangeModelCombo_Callback(hObject, eventdata, handles)
% hObject    handle to rangeModelCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns rangeModelCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from rangeModelCombo


% --- Executes during object creation, after setting all properties.
function rangeModelCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rangeModelCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function rangeMultiText_Callback(hObject, eventdata, handles)
% hObject    handle to rangeMultiText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of rangeMultiText as text
%        str2double(get(hObject,'String')) returns contents of rangeMultiText as a double


% --- Executes during object creation, after setting all properties.
function rangeMultiText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rangeMultiText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
