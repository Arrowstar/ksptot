function varargout = lvd_GraphicalAnalysisGUI(varargin)
% LVD_GRAPHICALANALYSISGUI MATLAB code for lvd_GraphicalAnalysisGUI.fig
%      LVD_GRAPHICALANALYSISGUI, by itself, creates a new LVD_GRAPHICALANALYSISGUI or raises the existing
%      singleton*.
%
%      H = LVD_GRAPHICALANALYSISGUI returns the handle to a new LVD_GRAPHICALANALYSISGUI or the handle to
%      the existing singleton*.
%
%      LVD_GRAPHICALANALYSISGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_GRAPHICALANALYSISGUI.M with the given input arguments.
%
%      LVD_GRAPHICALANALYSISGUI('Property','Value',...) creates a new LVD_GRAPHICALANALYSISGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_GraphicalAnalysisGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_GraphicalAnalysisGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_GraphicalAnalysisGUI

% Last Modified by GUIDE v2.5 09-Aug-2020 18:29:26

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_GraphicalAnalysisGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_GraphicalAnalysisGUI_OutputFcn, ...
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


% --- Executes just before lvd_GraphicalAnalysisGUI is made visible.
function lvd_GraphicalAnalysisGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to lvd_GraphicalAnalysisGUI (see VARARGIN)

    % Choose default command line output for lvd_GraphicalAnalysisGUI
    handles.output = hObject;

    % Set up GUI
    lvdData = varargin{1};
    setappdata(hObject,'lvdData',lvdData);
    
    handles.ma_LvdMainGUI = varargin{2};

    exclude = getLvdGAExcludeList();

    taskList = lvd_getGraphAnalysisTaskList(lvdData, exclude);
    set(handles.depVarListbox,'String',taskList);

    maStateLog = lvdData.stateLog.getMAFormattedStateLogMatrix();

%     propNames = {'Liquid Fuel/Ox','Monopropellant','Xenon'};
    propNames = lvdData.launchVehicle.tankTypes.getFirstThreeTypesCellArr();
    substituteDefaultPropNamesWithCustomNamesInDepVarListbox(handles.depVarListbox, propNames);
    useSubplotCheckbox_Callback(handles.useSubplotCheckbox, [], handles);
    set(handles.startTimeText,'String',fullAccNum2Str(min(maStateLog(:,1))));
    set(handles.endTimeText,'String',fullAccNum2Str(max(maStateLog(:,1))));
    populateBodiesCombo(lvdData.celBodyData, handles.refBodyCombo);
    % populateOtherSCCombo(handles, handles.refSpacecraftCombo);
    % populateStationsCombo(handles, handles.refStationCombo);
    indepVarCombo_Callback(handles.indepVarCombo, [], handles);

    setappdata(hObject,'xLineValue',[]);
    setappdata(hObject,'yLineValue',[]);

    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_GraphicalAnalysisGUI wait for user response (see UIRESUME)
    % uiwait(handles.lvd_GraphicalAnalysisGUI);


    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_GraphicalAnalysisGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    varargout{1} = handles.output;


% --- Executes on selection change in indepVarCombo.
function indepVarCombo_Callback(hObject, eventdata, handles)
% hObject    handle to indepVarCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns indepVarCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from indepVarCombo
    contents = cellstr(get(hObject,'String'));
    selected = deblank(contents{get(hObject,'Value')});
    
    if(strcmpi(selected,'Time') || strcmpi(selected,'Mission Elapsed Time'))
        set(handles.showEventTerminationCheckbox,'Enable','on');
%         set(handles.showSoITransCheckbox,'Enable','on');
        set(handles.showPeriCheckbox,'Enable','on');
        set(handles.showApoCheckbox,'Enable','on');
    else
        set(handles.showEventTerminationCheckbox,'Enable','off');
%         set(handles.showSoITransCheckbox,'Enable','off');
        set(handles.showPeriCheckbox,'Enable','off');
        set(handles.showApoCheckbox,'Enable','off');
    end
    

% --- Executes during object creation, after setting all properties.
function indepVarCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to indepVarCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in useSubplotCheckbox.
function useSubplotCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to useSubplotCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of useSubplotCheckbox
    if(get(hObject,'Value'))
        set(handles.subPlotSizeXText,'Enable','on');
        set(handles.subPlotSizeYText,'Enable','on');
    else
        set(handles.subPlotSizeXText,'Enable','off');
        set(handles.subPlotSizeYText,'Enable','off');
    end


function subPlotSizeXText_Callback(hObject, eventdata, handles)
% hObject    handle to subPlotSizeXText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of subPlotSizeXText as text
%        str2double(get(hObject,'String')) returns contents of subPlotSizeXText as a double


% --- Executes during object creation, after setting all properties.
function subPlotSizeXText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to subPlotSizeXText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function subPlotSizeYText_Callback(hObject, eventdata, handles)
% hObject    handle to subPlotSizeYText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of subPlotSizeYText as text
%        str2double(get(hObject,'String')) returns contents of subPlotSizeYText as a double


% --- Executes during object creation, after setting all properties.
function subPlotSizeYText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to subPlotSizeYText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function lineWidthText_Callback(hObject, eventdata, handles)
% hObject    handle to lineWidthText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lineWidthText as text
%        str2double(get(hObject,'String')) returns contents of lineWidthText as a double


% --- Executes during object creation, after setting all properties.
function lineWidthText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lineWidthText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in lineColorCombo.
function lineColorCombo_Callback(hObject, eventdata, handles)
% hObject    handle to lineColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lineColorCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lineColorCombo


% --- Executes during object creation, after setting all properties.
function lineColorCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lineColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in backgndColorCombo.
function backgndColorCombo_Callback(hObject, eventdata, handles)
% hObject    handle to backgndColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns backgndColorCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from backgndColorCombo


% --- Executes during object creation, after setting all properties.
function backgndColorCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to backgndColorCombo (see GCBO)
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


% --- Executes on button press in genPlotsButton.
function genPlotsButton_Callback(hObject, eventdata, handles)
% hObject    handle to genPlotsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(~isempty(errMsg))
        msgbox(errMsg,'Errors were found while validating your split value.  Please sure value is between the given bounds.','error');
        return;
    end

    lvdData = getappdata(handles.lvd_GraphicalAnalysisGUI,'lvdData');
    celBodyData = lvdData.celBodyData;
    maStateLog = lvdData.stateLog.getMAFormattedStateLogMatrix();

    taskInds = get(handles.depVarListbox,'Value');
    if(isempty(taskInds))
        errordlg('Error: No valid dependent variables selected.');
        return;
    end
    
    startTimeUT = str2double(get(handles.startTimeText,'String'));
    endTimeUT = str2double(get(handles.endTimeText,'String'));
    
    lineWidth = str2double(get(handles.lineWidthText,'String'));
    
    contents = cellstr(get(handles.lineColorCombo,'String'));
    lineColorStr = contents{get(handles.lineColorCombo,'Value')};
    lineColor = getLineSpecColorFromString(lineColorStr);
    
    contents = cellstr(get(handles.backgndColorCombo,'String'));
    bgColorStr = contents{get(handles.backgndColorCombo,'Value')};
    bgColor = getLineSpecColorFromString(bgColorStr);
    
    contents = cellstr(get(handles.lineSpecCombo,'String'));
    lineTypeStr = contents{get(handles.lineSpecCombo,'Value')};
    switch lineTypeStr
        case 'Solid Line'
            lineType = '-';
        case 'Dashed Line'
            lineType = '--';
        case 'Dotted Line'
            lineType = ':';
        case 'Dash-dot Line'
            lineType = '-.';
        otherwise
            lineType = '-';
    end
    
    propNames = lvdData.launchVehicle.tankTypes.getFirstThreeTypesCellArr();
    
    lvdSubLog = lvdData.stateLog.getStateLogEntriesBetweenTimes(startTimeUT, endTimeUT);
    maSubLog = maStateLog(maStateLog(:,1) >= startTimeUT & maStateLog(:,1) <= endTimeUT,:);
    
    contentsIndep = cellstr(get(handles.indepVarCombo,'String'));
    indepVarValues = zeros(size(maSubLog,1), 2);
    indepVarStr = deblank(contentsIndep{get(handles.indepVarCombo,'Value')});
    
    contentsIndepUnit = cellstr(get(handles.indepVarTimeUnit,'String'));
    indepVarUnitStr = deblank(contentsIndepUnit{get(handles.indepVarTimeUnit,'Value')});
    
    [secInMin, secInHr, secInDay, secInYear] = getSecondsInVariousTimeUnits();
    switch indepVarUnitStr
        case 'Seconds'
            indepTimeUnit = 'sec';
            indepTimeUnitMult = 1;
        case 'Minutes'
            indepTimeUnit = 'min';
            indepTimeUnitMult = 1/secInMin;
        case 'Hours'
            indepTimeUnit = 'hr';
            indepTimeUnitMult = 1/secInHr;
        case 'Days'
            indepTimeUnit = 'day';
            indepTimeUnitMult = 1/secInDay;
        case 'Years'
            indepTimeUnit = 'year';
            indepTimeUnitMult = 1/secInYear;
    end
    
    switch indepVarStr
        case 'Time'
            indepVarValues = indepTimeUnitMult*[maSubLog(:,1), maSubLog(:,1)];
            indepVarUnits = indepTimeUnit;
            
        case 'Mission Elapsed Time'
            indepVarValues = indepTimeUnitMult*[maSubLog(:,1) - maStateLog(1,1), maSubLog(:,1)];
            indepVarUnits = indepTimeUnit;
            
        case 'True Anomaly'
            for(i=1:size(maSubLog,1))
                indepVarValues(i,:) = [ma_GAKeplerElementsTask(maSubLog(i,:), 'tru', celBodyData), maSubLog(i,1)];
            end
            indepVarUnits = 'deg';
            
        case 'Longitude'
            for(i=1:size(maSubLog,1))
                indepVarValues(i,:) = [ma_GALongLatAltTasks(maSubLog(i,:), 'long', celBodyData), maSubLog(i,1)];
            end
            indepVarUnits = 'degE';
            
        case 'Altitude'
            for(i=1:size(maSubLog,1))
                indepVarValues(i,:) = [ma_GALongLatAltTasks(maSubLog(i,:), 'alt', celBodyData), maSubLog(i,1)];
            end
            indepVarUnits = 'km';
    end
    
    hWaitBar = waitbar(0,'Computing Dependent Variables...','WindowStyle','modal');
    depVarValues = zeros(size(maSubLog,1), length(taskInds));
    depVarUnits = cell(1,length(taskInds));
    contentsDep = strtrim(cellstr(get(handles.depVarListbox,'String')));
    prevDistTraveled = 0;
    
    hRefBodyCombo = handles.refBodyCombo;
    contents = cellstr(get(hRefBodyCombo,'String'));
    refBodyStr = contents{get(hRefBodyCombo,'Value')};
    refBodyInfo = celBodyData.(strtrim(lower(refBodyStr)));
    refBodyId = refBodyInfo.id;
    
    hRefSCCombo = handles.refSpacecraftCombo;
    if(strcmpi(get(hRefSCCombo,'Enable'),'off'))
        otherSCId = [];
    else
        try
            refSCInd = get(hRefSCCombo,'Value');
            otherSCs = maData.spacecraft.otherSC;
            otherSCId = otherSCs{refSCInd}.id;
        catch
            otherSCId = [];
        end
    end
    
%     hRefStnCombo = handles.refStationCombo;
%     if(strcmpi(get(hRefStnCombo,'Enable'),'off'))
%         stationID = [];
%     else
%         try
%             refSCInd = get(hRefStnCombo,'Value');
%             stations = maData.spacecraft.stations;
%             stationID = stations{refSCInd}.id;
%         catch
%             
%         end
%     end
    
    stationID = [];

    dataEvtNums = [];
    maTaskList = ma_getGraphAnalysisTaskList({});
    for(i=1:size(maSubLog,1))
        for(j=1:length(taskInds))
            taskInd = taskInds(j);
            taskStr = contentsDep{taskInd};
            
            if(isvalid(hWaitBar))
                waitbar(i/size(maSubLog,1), hWaitBar, sprintf('Computing Dependent Variables...\n[%u of %u]', i, size(maSubLog,1)));
            end

            if(ismember(taskStr,maTaskList))
                [depVarValues(i,j), depVarUnits{j}, prevDistTraveled] = ma_getDepVarValueUnit(i, maSubLog, taskStr, prevDistTraveled, refBodyId, otherSCId, stationID, propNames, [], celBodyData, false);
            else
                [depVarValues(i,j), depVarUnits{j}] = lvd_getDepVarValueUnit(i, lvdSubLog, taskStr, refBodyId, celBodyData, false);
            end
        end
        
        dataEvtNums(i) = maSubLog(i,13);
    end
    close(hWaitBar);
    
    plotMethods = [lvdData.script.evts.plotMethod];
    if(any(plotMethods == EventPlottingMethodEnum.SkipFirstState))
        evtIndsToInsertNaNBetween = find(plotMethods == EventPlottingMethodEnum.SkipFirstState);
        
        stateInds = [];
        for(i=1:length(evtIndsToInsertNaNBetween))
            evtInd = evtIndsToInsertNaNBetween(i);
            stateInd = find(maSubLog(:,13) == evtInd,1,'first');
            if(stateInd > 1)
                stateInds(end+1) = stateInd;
            end
        end
        
        numIndepVars = size(indepVarValues,2);
        numDepVars = size(depVarValues,2);
        for(i=1:length(stateInds))
            indepVarValues = [indepVarValues(1:stateInds(i)-1,:); NaN(1,numIndepVars); indepVarValues(stateInds(i)+1:end,:)];
            depVarValues = [depVarValues(1:stateInds(i)-1,:); NaN(1,numDepVars); depVarValues(stateInds(i)+1:end,:)];
            
%             if(i < length(stateInds))
%                 stateInds(i+1:end) = stateInds(i+1:end)+1;  %accounts for the fact that we're inserting data
%             end
        end
    end
    
    useEvtLineColor = logical(handles.useEvtLineColorsCheckbox.Value);
    evts = [lvdData.script.evts];
    
    figNum = 100;
    if(get(handles.useSubplotCheckbox,'Value'))
        subPlotMaxX = str2double(get(handles.subPlotSizeXText,'String'));
        subPlotMaxY = str2double(get(handles.subPlotSizeYText,'String'));
        
        hFig = figure(figNum);
        whitebg(hFig, bgColor);
        plotNum = 0;
        for(i = 1:size(depVarValues,2))
            plotNum = plotNum  +1;
            if(plotNum > subPlotMaxX*subPlotMaxY)
                figNum = figNum + 1;
                hFig = figure(figNum);
                plotNum = 1;
            end
            
            data = depVarValues(:,i);

            taskInd = taskInds(i);
            taskStr = contentsDep{taskInd};

            subplot(subPlotMaxX,subPlotMaxY,plotNum);
            plotData(hFig, indepVarValues, data, lineColor, useEvtLineColor, evts, dataEvtNums, lineType, lineWidth, indepVarStr, taskStr, bgColor, indepVarUnits, indepTimeUnitMult, depVarUnits{i}, maStateLog, startTimeUT, endTimeUT, celBodyData, handles.lvd_GraphicalAnalysisGUI);
        end
    else
        for(i = 1:size(depVarValues,2)) %#ok<*NO4LP>
            data = depVarValues(:,i);

            taskInd = taskInds(i);
            taskStr = contentsDep{taskInd};

            hFig = figure(figNum+i);
            whitebg(hFig, bgColor);
            plotData(hFig, indepVarValues, data, lineColor, useEvtLineColor, evts, dataEvtNums, lineType, lineWidth, indepVarStr, taskStr, bgColor, indepVarUnits, indepTimeUnitMult, depVarUnits{i}, maStateLog, startTimeUT, endTimeUT, celBodyData, handles.lvd_GraphicalAnalysisGUI);
        end
    end
    
    if(get(handles.generateTextOutputCheckbox,'Value'))
        matSave = getappdata(handles.ma_LvdMainGUI,'current_save_location');
        [pathstr,name,~] = fileparts(matSave);
        if(isempty(pathstr))
            pathstr = uigetdir(pwd,'Select folder to save tabular text output');
            name = 'UntitledMission';
        end
        csvFilename = [pathstr,'\',name,'_GraphicalAnalysis_',datestr(now,'yyyymmdd_HHMMSS'),'.csv'];
               
        indepVarUnitStr = indepVarUnits;
        if(~isempty(indepVarUnitStr))
            indepVarUnitStr = [' [',indepVarUnitStr,']'];
        else
            indepVarUnitStr = '';
        end
        
        taskStrs = [indepVarStr,indepVarUnitStr,','];
        for(i = 1:length(taskInds)) %#ok<*NO4LP>
            taskInd = taskInds(i);
            taskStr = contentsDep{taskInd};
            
                depVarUnitStr = depVarUnits{i};
                if(~isempty(depVarUnitStr))
                    depVarUnitStr = [' [',depVarUnitStr,']']; %#ok<*AGROW>
                else
                    depVarUnitStr = '';
                end
                
                taskStr = [taskStr,depVarUnitStr];
            
            taskStrs = [taskStrs,taskStr,','];
        end
        taskStrs = [taskStrs,'\n'];
        if(pathstr ~= 0)
            fid = fopen(csvFilename,'wt+');
            fprintf(fid,taskStrs);
            fclose(fid);

            M = [indepVarValues(:,1),depVarValues];
            dlmwrite(csvFilename, M, '-append','precision', 15);

            msgbox(sprintf('Tabular output written to file: \n%s',csvFilename), 'Tabular Output', 'help');
        end
    end
    
function plotData(hFig, indepVarValues, data, lineColor, useEvtLineColor, evts, dataEvtNums, lineType, lineWidth, indepVarStr, taskStr, bgColor, indepVarUnitStr, indepTimeUnitMult, depVarUnitStr, maStateLog, startTimeUT, endTimeUT, celBodyData, hGAFig)
    xLineValue = getappdata(hGAFig,'xLineValue');
    yLineValue = getappdata(hGAFig,'yLineValue');

    hold on;
    
    if(useEvtLineColor)
        for(i=1:length(evts))
            evt = evts(i);
            eventNum = evt.getEventNum();
            
            bool = dataEvtNums == eventNum;
            
            subIndVal = indepVarValues(bool,1);
            subData = data(bool);
            lineColor = evt.colorLineSpec.color.color;
            
            plot(subIndVal, subData, 'Color',lineColor, 'LineStyle',lineType, 'LineWidth',lineWidth);
        end
    else
        plot(indepVarValues(:,1), data, 'Color',lineColor, 'LineStyle',lineType, 'LineWidth',lineWidth);
    end
    
    minData = min(data);
    maxData = max(data);
    if(minData == maxData)
        minData = minData - 0.75;
        maxData = maxData + 0.75;
    end
    onePercData = (maxData-minData)/100;
    
    if(~isempty(xLineValue))
        if(xLineValue >= min(indepVarValues(:,1)) && xLineValue <= max(indepVarValues(:,1)))
            if(strcmpi(bgColor,'c'))
                markerLineColor = 'w';
            else
                markerLineColor = 'c';
            end
            plot([xLineValue xLineValue], [minData maxData],markerLineColor,'LineWidth',0.25);
        end
    end
    
    if(~isempty(yLineValue))
        if(yLineValue >= min(data) && yLineValue <= max(data))
            if(strcmpi(bgColor,'c'))
                markerLineColor = 'w';
            else
                markerLineColor = 'c';
            end
            plot([min(indepVarValues(:,1)) max(indepVarValues(:,1))], [yLineValue yLineValue],markerLineColor,'LineWidth',0.25);
        end
    end
    
    subLog = maStateLog(maStateLog(:,1) >= startTimeUT & maStateLog(:,1) <= endTimeUT,:);
    
    hShowMan = findobj('Tag','showEventTerminationCheckbox');
    if(get(hShowMan,'Value') && strcmpi(get(hShowMan,'Enable'), 'on'))
        if(strcmpi(bgColor,'r'))
            evtEndLineColor = 'w';
        else
            evtEndLineColor = 'r';
        end
        
        allEventNums = subLog(:,13);
        x = diff(allEventNums)~=0;
        inds = find(x);

        minData = min(data);
        maxData = max(data);
        if(minData == maxData)
            minData = minData - 0.75;
            maxData = maxData + 0.75;
        end
        
        for(i=1:length(inds))
            ind = inds(i);
            
            eventTime = subLog(ind,1)*indepTimeUnitMult;
            indepVarEventLoc = indepVarValues(indepVarValues(:,2)==eventTime,1);
            indepVarEventLoc = indepVarEventLoc(1);
            
            plot([indepVarEventLoc indepVarEventLoc], [minData, maxData],evtEndLineColor,'LineWidth',0.25);
            text(indepVarEventLoc,maxData-8*onePercData,sprintf(' Event %u End ',i),'Color',evtEndLineColor);
        
        end
    end
    
    hShowSoI = findobj('Tag','showSoITransCheckbox');
    if(get(hShowSoI,'Value') && strcmpi(get(hShowSoI,'Enable'), 'on'))
        if(strcmpi(bgColor,'m'))
            soiLineColor = 'w';
        else
            soiLineColor = 'm';
        end
        
        allBodyIDs = subLog(:,8);
        x = diff(allBodyIDs)~=0;
        inds = find(x);
        for(i=1:length(inds))
            ind = inds(i)+1;
            
            bodyLog = subLog(ind,:);
            bodyID = bodyLog(1,8);
            bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);

            if(bodyLog(1,1) == startTimeUT)
                continue;
            end
            eventTime = bodyLog(1,1)*indepTimeUnitMult;
            indepVarEventLoc = indepVarValues(indepVarValues(:,2)==eventTime,1);
            indepVarEventLoc = indepVarEventLoc(1);

            minData = min(data);
            maxData = max(data);
            if(minData == maxData)
                minData = minData - 0.75;
                maxData = maxData + 0.75;
            end

            plot([indepVarEventLoc indepVarEventLoc], [minData, maxData],soiLineColor,'LineWidth',0.25);
            text(indepVarEventLoc,maxData-2*onePercData,[' To ',bodyInfo.name],'Color',soiLineColor);
        end
    end
    
    hShowPeri = findobj('Tag','showPeriCheckbox');
    if(get(hShowPeri,'Value') && strcmpi(get(hShowPeri,'Enable'), 'on'))
        if(strcmpi(bgColor,'g'))
            periLineColor = 'w';
        else
            periLineColor = 'g';
        end
        
        periCnt = 1;
        allBodyIDs = subLog(:,8);
        x = diff(allBodyIDs)~=0;
        inds = find(x)+1;
        inds = [1 inds' length(allBodyIDs)+1];
        for(i=1:length(inds)-1)
            ind = inds(i);
            nextInd = inds(i+1)-1;
            
            bodyLog = subLog(ind:nextInd,:);
            bodyID = bodyLog(1,8);
            bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
            
            [~, ~, ~, ~, ~, tru] = vect_getKeplerFromState(bodyLog(:,2:4)',bodyLog(:,5:7)',bodyInfo.gm);
            tru = angleNegPiToPi(tru);
            
            for(j=2:length(tru))
                tru1 = tru(j-1);
                tru2 = tru(j);
                
%                 if(((tru1 > tru2 && abs(tru1-tru2)>pi) || (tru1 < 0 && tru2 >= 0)) && bodyLog(j-1,8)==bodyLog(j,8))  
                if(((tru1 < 0 && tru2 >= 0)) && bodyLog(j-1,8)==bodyLog(j,8)) 
                    eventTime = bodyLog(j,1)*indepTimeUnitMult;
                    indepVarEventLoc = indepVarValues(indepVarValues(:,2)==eventTime,1);
                    indepVarEventLoc = indepVarEventLoc(1);

                    minData = min(data);
                    maxData = max(data);
                    if(minData == maxData)
                        minData = minData - 0.75;
                        maxData = maxData + 0.75;
                    end

                    plot([indepVarEventLoc indepVarEventLoc], [minData, maxData],periLineColor,'LineWidth',0.25);
                    text(indepVarEventLoc,maxData-4*onePercData,[' P',num2str(periCnt)],'Color',periLineColor);
                    periCnt = periCnt + 1;
                end
            end
        end
    end
    
	hShowApo = findobj('Tag','showApoCheckbox');
    if(get(hShowApo,'Value') && strcmpi(get(hShowApo,'Enable'), 'on'))
        if(strcmpi(bgColor,'b'))
            apoLineColor = 'w';
        else
            apoLineColor = 'b';
        end
        
        apoCnt = 1;
        allBodyIDs = subLog(:,8);
        x = diff(allBodyIDs)~=0;
        inds = find(x)+1;
        inds = [1 inds' length(allBodyIDs)+1];
        for(i=1:length(inds)-1)
            ind = inds(i);
            nextInd = inds(i+1)-1;
            
            bodyLog = subLog(ind:nextInd,:);
            bodyID = bodyLog(1,8);
            bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
            
            [~, ~, ~, ~, ~, tru] = vect_getKeplerFromState(bodyLog(:,2:4)',bodyLog(:,5:7)',bodyInfo.gm);
            
            for(j=2:length(tru))
                tru1 = tru(j-1);
                tru2 = tru(j);
                               
                if(tru1 < pi && tru2 >= pi && bodyLog(j-1,8)==bodyLog(j,8))                   
                    eventTime = bodyLog(j,1)*indepTimeUnitMult;
                    indepVarEventLoc = indepVarValues(indepVarValues(:,2)==eventTime,1);
                    indepVarEventLoc = indepVarEventLoc(1);
                    
                    minData = min(data);
                    maxData = max(data);
                    if(minData == maxData)
                        minData = minData - 0.75;
                        maxData = maxData + 0.75;
                    end

                    plot([indepVarEventLoc indepVarEventLoc], [minData, maxData],apoLineColor,'LineWidth',0.25);
                    text(indepVarEventLoc,maxData-6*onePercData,[' A',num2str(apoCnt)],'Color',apoLineColor);
                    apoCnt = apoCnt + 1;
                end
            end
        end
    end
    
    hGridOn = findobj('Tag','showGridCheckboxGA');
    if(get(hGridOn,'Value'))
        grid on;
    else
        grid off;
    end
    
    if(~isempty(indepVarUnitStr))
        indepVarUnitStr = [' [',indepVarUnitStr,']'];
    else
        indepVarUnitStr = '';
    end
    
    if(~isempty(depVarUnitStr))
        depVarUnitStr = [' [',depVarUnitStr,']'];
    else
        depVarUnitStr = '';
    end
    
    xlabel([indepVarStr,indepVarUnitStr]);
    ylabel([taskStr,depVarUnitStr]);
    
    hold off;
    
    dcmObj = datacursormode;
    set(dcmObj,'UpdateFcn',@dataTipFormatFunc,'Enable','on');
        
    
function errMsg = validateInputs(handles)    
%     maData = getappdata(handles.ma_MainGUI,'ma_data');
%     celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    lvdData = getappdata(handles.lvd_GraphicalAnalysisGUI,'lvdData');
    celBodyData = lvdData.celBodyData;
    stateLog = lvdData.stateLog.getMAFormattedStateLogMatrix();
    
    errMsg = {};
    
    stateLogMinUT = floor(min(stateLog(:,1))*10000)/10000;
    stateLogMaxUT = ceil(max(stateLog(:,1))*10000)/10000;
    
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
    
    if(get(handles.useSubplotCheckbox,'Value'))
        value = str2double(get(handles.subPlotSizeXText,'String'));
        enteredStr = get(handles.subPlotSizeXText,'String');
        numberName = 'Sub Plot X Size';
        lb = 1;
        ub = 10;
        isInt = true;
        errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
        
        value = str2double(get(handles.subPlotSizeYText,'String'));
        enteredStr = get(handles.subPlotSizeYText,'String');
        numberName = 'Sub Plot Y Size';
        lb = 1;
        ub = 10;
        isInt = true;
        errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    end
    
    value = str2double(get(handles.lineWidthText,'String'));
    enteredStr = get(handles.lineWidthText,'String');
    numberName = 'Line Width';
    lb = 0.25;
    ub = 5;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    
        

% --- Executes on selection change in depVarListbox.
function depVarListbox_Callback(hObject, eventdata, handles)
% hObject    handle to depVarListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns depVarListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from depVarListbox


% --- Executes during object creation, after setting all properties.
function depVarListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to depVarListbox (see GCBO)
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


% --------------------------------------------------------------------
function enterUTAsDateTime_Callback(hObject, eventdata, handles)
% hObject    handle to enterUTAsDateTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    secUT = enterUTAsDateTimeGUI(str2double(get(gco, 'String')));
    if(secUT >= 0)
        set(gco, 'String', num2str(secUT));
    end


% --- Executes on selection change in refBodyCombo.
function refBodyCombo_Callback(hObject, eventdata, handles)
% hObject    handle to refBodyCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns refBodyCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from refBodyCombo


% --- Executes during object creation, after setting all properties.
function refBodyCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to refBodyCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in refSpacecraftCombo.
function refSpacecraftCombo_Callback(hObject, eventdata, handles)
% hObject    handle to refSpacecraftCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns refSpacecraftCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from refSpacecraftCombo


% --- Executes during object creation, after setting all properties.
function refSpacecraftCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to refSpacecraftCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in generateTextOutputCheckbox.
function generateTextOutputCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to generateTextOutputCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of generateTextOutputCheckbox


% --- Executes on button press in showGridCheckboxGA.
function showGridCheckboxGA_Callback(hObject, eventdata, handles)
% hObject    handle to showGridCheckboxGA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showGridCheckboxGA


% --- Executes on button press in showEventTerminationCheckbox.
function showEventTerminationCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to showEventTerminationCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showEventTerminationCheckbox


% --- Executes on button press in showSoITransCheckbox.
function showSoITransCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to showSoITransCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showSoITransCheckbox


% --- Executes on button press in showPeriCheckbox.
function showPeriCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to showPeriCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showPeriCheckbox


% --- Executes on button press in showApoCheckbox.
function showApoCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to showApoCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showApoCheckbox


% --- Executes on selection change in refStationCombo.
function refStationCombo_Callback(hObject, eventdata, handles)
% hObject    handle to refStationCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns refStationCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from refStationCombo


% --- Executes during object creation, after setting all properties.
function refStationCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to refStationCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function output_txt = dataTipFormatFunc(obj,event_obj)
% Display the position of the data cursor
% obj          Currently not used (empty)
% event_obj    Handle to event object
% output_txt   Data cursor text string (string or cell array of strings).
    pos = get(event_obj,'Position');
    output_txt = {['X: ',num2str(pos(1),'%12.5f')],...
        ['Y: ',num2str(pos(2),'%12.5f')]};

    % If there is a Z-coordinate in the position, display it as well
    if length(pos) > 2
        output_txt{end+1} = ['Z: ',num2str(pos(3),'%12.5f')];
    end


% --- Executes on button press in markerLinesButton.
function markerLinesButton_Callback(hObject, eventdata, handles)
% hObject    handle to markerLinesButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    xLineValue = getappdata(handles.lvd_GraphicalAnalysisGUI,'xLineValue');
    yLineValue = getappdata(handles.lvd_GraphicalAnalysisGUI,'yLineValue');

    defAns = cell(1,2);
    if(~isempty(xLineValue))
        defAns{1} = num2str(xLineValue);
    else
        defAns{1} = '';
    end
    if(~isempty(yLineValue))
        defAns{2} = num2str(yLineValue);
    else
        defAns{2} = '';
    end
    
    answer = inputdlg({'Draw a vertical line at X=? (Blank to clear)';
                       'Draw a horizontal line at Y=? (Blank to clear)'},...
                       'Marker Lines',...
                        1,...
                        defAns);
	answer = strtrim(answer);
    if(isempty(answer))
        return;
    end
    
    newX = str2double(answer{1});
    if(isnan(newX))
        newXStr = [];
    else
        newXStr = newX;
    end
    
    newY = str2double(answer{2});
    if(isnan(newY))
        newYStr = [];
    else
        newYStr = newY;
    end
    
    setappdata(handles.lvd_GraphicalAnalysisGUI,'xLineValue',newXStr);
    setappdata(handles.lvd_GraphicalAnalysisGUI,'yLineValue',newYStr);


% --- Executes on key press with focus on lvd_GraphicalAnalysisGUI or any of its controls.
function lvd_GraphicalAnalysisGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_GraphicalAnalysisGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'escape'
            close(handles.lvd_GraphicalAnalysisGUI);
    end


% --- Executes on selection change in indepVarTimeUnit.
function indepVarTimeUnit_Callback(hObject, eventdata, handles)
% hObject    handle to indepVarTimeUnit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns indepVarTimeUnit contents as cell array
%        contents{get(hObject,'Value')} returns selected item from indepVarTimeUnit


% --- Executes during object creation, after setting all properties.
function indepVarTimeUnit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to indepVarTimeUnit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function setTimeFromScriptMenu_Callback(hObject, eventdata, handles)
% hObject    handle to setTimeFromScriptMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_GraphicalAnalysisGUI,'lvdData');
    stateLog = lvdData.stateLog.getMAFormattedStateLogMatrix();
    
    h = gco;
    if(strcmpi(h.Tag,'startTimeText'))
        set(gco,'String', num2str(min(stateLog(:,1)), '%1.15f'));
    elseif(strcmpi(h.Tag,'endTimeText'))
        set(gco,'String', num2str(max(stateLog(:,1)), '%1.15f'));
    else
        return;
    end


% --- Executes on button press in useEvtLineColorsCheckbox.
function useEvtLineColorsCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to useEvtLineColorsCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of useEvtLineColorsCheckbox
    if(hObject.Value)
        handles.lineColorCombo.Enable = 'off';
    else
        handles.lineColorCombo.Enable = 'on';
    end
