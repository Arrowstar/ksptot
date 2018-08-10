function varargout = flyByPorkchopPlotterGUI(varargin)
% FLYBYPORKCHOPPLOTTERGUI MATLAB code for flyByPorkchopPlotterGUI.fig
%      FLYBYPORKCHOPPLOTTERGUI, by itself, creates a new FLYBYPORKCHOPPLOTTERGUI or raises the existing
%      singleton*.
%
%      H = FLYBYPORKCHOPPLOTTERGUI returns the handle to a new FLYBYPORKCHOPPLOTTERGUI or the handle to
%      the existing singleton*.
%
%      FLYBYPORKCHOPPLOTTERGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FLYBYPORKCHOPPLOTTERGUI.M with the given input arguments.
%
%      FLYBYPORKCHOPPLOTTERGUI('Property','Value',...) creates a new FLYBYPORKCHOPPLOTTERGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before flyByPorkchopPlotterGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to flyByPorkchopPlotterGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help flyByPorkchopPlotterGUI

% Last Modified by GUIDE v2.5 27-May-2017 22:31:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @flyByPorkchopPlotterGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @flyByPorkchopPlotterGUI_OutputFcn, ...
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


% --- Executes just before flyByPorkchopPlotterGUI is made visible.
function flyByPorkchopPlotterGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to flyByPorkchopPlotterGUI (see VARARGIN)

% Choose default command line output for flyByPorkchopPlotterGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%Possible fix for people with display issues.
checkForCharUnitsInGUI(hObject);

mainGUIHandle = varargin{1};
mainGUIUserData = get(mainGUIHandle,'UserData');
celBodyData = mainGUIUserData{1,1};
setappdata(hObject,'celBodyData',celBodyData);

setCentralBodyCombo(celBodyData, handles.centralBodyCombo);
initWayPtTable(celBodyData, handles.waypointTable, handles.centralBodyCombo);
initDispAxes(handles.displayAxes);
initFlightTimeBounds(handles, celBodyData);

eventdataWpT.Indices = [1 1];
waypointTable_CellSelectionCallback(handles.waypointTable, eventdataWpT, handles);

launchWindowOpenText_Callback(handles.launchWindowOpenText, [], handles);
launchWindowCloseText_Callback(handles.launchWindowCloseText, [], handles);
numContourLvlsText_Callback(handles.numContourLvlsText, [], handles);

hZoom = zoom(handles.flyByPorkchopPlotterGUI);
set(hZoom,'ActionPostCallback',@postZoomCallback);

hPan = pan(handles.flyByPorkchopPlotterGUI);
set(hPan,'ActionPostCallback',@postZoomCallback);

% UIWAIT makes flyByPorkchopPlotterGUI wait for user response (see UIRESUME)
% uiwait(handles.flyByPorkchopPlotterGUI);

function postZoomCallback(obj,evd)
    handles = guidata(obj);
    if(get(handles.recomputePlotOnZoomCheckbox,'Value')==1)
        newXLim = get(evd.Axes,'XLim');
        newYLim = get(evd.Axes,'YLim');
        
        if(newXLim(1)<0)
            newXLim(1)=0;
        end
        if(newYLim(1)<0)
            newYLim(1)=0;
        end
        set(evd.Axes,'XLim',newXLim);
        set(evd.Axes,'YLim',newYLim);
        
        elem2 = get(handles.dispAxesSelectSlider,'Value');
        
        bnds = get(handles.flightTimeBndsPanel,'UserData');
        [~, ~, secInDay, ~] = getSecondsInVariousTimeUnits();
        bnds(elem2-1,:) = newYLim*secInDay;
        set(handles.flightTimeBndsPanel,'UserData',bnds);
        
        [~, ~, secInDay, ~] = getSecondsInVariousTimeUnits();
        set(handles.launchWindowOpenText,'String',num2str(newXLim(1)*secInDay));
        set(handles.launchWindowCloseText,'String',num2str(newXLim(2)*secInDay));
        
        launchWindowOpenText_Callback(handles.launchWindowOpenText,[],handles);
        launchWindowCloseText_Callback(handles.launchWindowCloseText,[],handles);
        eventdataWpT.Indices = [elem2-1 1];
        waypointTable_CellSelectionCallback(handles.waypointTable, eventdataWpT, handles);
        drawnow;
        
        computeFlybyPorkchopPlotButton_Callback(handles.computeFlybyPorkchopPlotButton, [], handles);
    end

    
function setCentralBodyCombo(celBodyData, hCentralBodyCombo)
    celBodyFields = fieldnames(celBodyData);
    validBodies = {};
    for(i=1:length(celBodyFields)) %#ok<*NO4LP>
        bodyInfo = celBodyData.(celBodyFields{i});
        [children, ~] = getChildrenOfParentInfo(celBodyData, bodyInfo.name);
        if(bodyInfo.canbecentral==1 && length(children)>=3)
            validBodies{end+1} = bodyInfo.name; %#ok<AGROW>
        end
    end
    
    set(hCentralBodyCombo, 'String', char(validBodies));


function initWayPtTable(celBodyData, hWayPtTable, hCentralBodyCombo)
    childrenNames = getValidWayPtsFromParent(celBodyData, hCentralBodyCombo);
    childrenNames = childrenNames';
    
    [mem,Inds] = ismember({'Kerbin','Eve','Duna'},childrenNames);
    if(all(mem))
        initData = childrenNames(Inds);
    else
        if(length(childrenNames)>=3)
            initData = childrenNames(1:3);
        else
            initData = childrenNames(1:end);
        end
    end
    
    set(hWayPtTable,'Data',initData);
    set(hWayPtTable,'ColumnFormat',{childrenNames'});
    set(hWayPtTable,'ColumnName',{'Waypoint'});
    set(hWayPtTable,'ColumnWidth',{135});
    set(hWayPtTable,'ColumnEditable',[true]);
    
    set(hWayPtTable,'UserData',size(initData));

    
function initDispAxes(hDispAxesMFMS)
    hAxis = hDispAxesMFMS;
    axes(hAxis);
    cla(hAxis, 'reset');
    grid on;
    colorbar;
    
    
function childrenNames = getValidWayPtsFromParent(celBodyData, hCentralBodyCombo)
    contents = cellstr(get(hCentralBodyCombo,'String'));
	cbName = contents{get(hCentralBodyCombo,'Value')};
    [~, childrenNames] = getChildrenOfParentInfo(celBodyData, cbName);
    
    
function initFlightTimeBounds(handles, celBodyData)
    wayPtBodies = {};
    waypts = get(handles.waypointTable,'Data');
    for(i=1:length(waypts))
        wayPtBodies{end+1} = celBodyData.(lower(waypts{i})); %#ok<AGROW>
    end
    
    [lb, ub] = getMultiFlybyLBUB(0, 1, wayPtBodies, celBodyData);
    numLegs = length(wayPtBodies)-1;
    
    lb = lb(2:1+numLegs);
    ub = ub(2:1+numLegs);
    maxRevs = zeros(1,numLegs);
    bnds = [lb',ub', maxRevs'];
    set(handles.flightTimeBndsPanel,'UserData',bnds);



% --- Outputs from this function are returned to the command line.
function varargout = flyByPorkchopPlotterGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function numPtsPerAxisText_Callback(hObject, eventdata, handles)
% hObject    handle to numPtsPerAxisText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numPtsPerAxisText as text
%        str2double(get(hObject,'String')) returns contents of numPtsPerAxisText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function numPtsPerAxisText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numPtsPerAxisText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addWayPointRowButton.
function addWayPointRowButton_Callback(hObject, eventdata, handles)
% hObject    handle to addWayPointRowButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    celBodyData = getappdata(handles.flyByPorkchopPlotterGUI,'celBodyData');

    wayPtData = get(handles.waypointTable,'Data');    
    validChildren = get(handles.waypointTable,'ColumnFormat');
    wayPtData{end+1,1} = validChildren{1}{1};
    set(handles.waypointTable,'Data',wayPtData);
    
    wayPtBodies = {};
    for(i=1:length(wayPtData))
        wayPtBodies{end+1} = celBodyData.(lower(wayPtData{i})); %#ok<AGROW>
    end
    
    bnds = get(handles.flightTimeBndsPanel,'UserData');
    [lb, ub] = getMultiFlybyLBUB(0, 1, wayPtBodies, celBodyData);
    numLegs = length(wayPtBodies)-1;
    bnds(end+1,1) = lb(numLegs+1);
    bnds(end,2) = ub(numLegs+1);
    bnds(end,3) = 0;
    set(handles.flightTimeBndsPanel,'UserData',bnds);

    
% --- Executes on button press in deleteWayPointRowButton.
function deleteWayPointRowButton_Callback(hObject, eventdata, handles)
% hObject    handle to deleteWayPointRowButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    celBodyData = getappdata(handles.flyByPorkchopPlotterGUI,'celBodyData');

    wayPtData = get(handles.waypointTable,'Data');
    numPreDeleteWayPts = length(wayPtData);
    if(size(wayPtData,1) > 2)
        selected = get(handles.waypointTable,'UserData');
        if(isempty(selected))
            selected = size(wayPtData);
        end
        if(selected<=length(wayPtData))
            row = selected(1,1);
            wayPtData(row,:) = [];

            bnds = get(handles.flightTimeBndsPanel,'UserData');

            if(row==1)
                bnds(1,:) = [];
            elseif(row == numPreDeleteWayPts)
                bnds(row-1,:) = [];
            else
                preBnds = bnds(1:row-2,:);
                pstBnds = bnds(row+1:end,:);
                
                wayPtBodies = {};
                for(i=1:length(wayPtData))
                    wayPtBodies{end+1} = celBodyData.(lower(wayPtData{i})); %#ok<AGROW>
                end
                [lb, ub] = getMultiFlybyLBUB(0, 1, wayPtBodies, celBodyData);
                
                newBnds(1) = lb(row);
                newBnds(2) = ub(row);
                newBnds(3) = 0;
                
                bnds = [preBnds; newBnds; pstBnds];
            end

            set(handles.flightTimeBndsPanel,'UserData',bnds);
            set(handles.waypointTable,'Data',wayPtData);
        end
    end

% --- Executes on selection change in centralBodyCombo.
function centralBodyCombo_Callback(hObject, eventdata, handles)
% hObject    handle to centralBodyCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns centralBodyCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from centralBodyCombo
    celBodyData = getappdata(handles.flyByPorkchopPlotterGUI,'celBodyData');
    initWayPtTable(celBodyData, handles.waypointTable, handles.centralBodyCombo);

    initFlightTimeBounds(handles, celBodyData);

    eventdataWpT.Indices = [1 1];
    waypointTable_CellSelectionCallback(handles.waypointTable, eventdataWpT, handles);
    
% --- Executes during object creation, after setting all properties.
function centralBodyCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to centralBodyCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function launchWindowOpenText_Callback(hObject, eventdata, handles)
% hObject    handle to launchWindowOpenText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchWindowOpenText as text
%        str2double(get(hObject,'String')) returns contents of launchWindowOpenText as a double
    newInput = get(hObject,'String');

    newInput = attemptStrEval(newInput);

    inputSec = str2double(newInput);
    if(checkStrIsNumeric(newInput) && inputSec>=0.0)
        [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(inputSec);
        dateStr = formDateStr(year, day, hour, minute, sec);
        set(handles.launchWinOpenLabel, 'String', dateStr);
        set(hObject,'String', num2str(inputSec));
    else

    end

% --- Executes during object creation, after setting all properties.
function launchWindowOpenText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchWindowOpenText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function launchWindowCloseText_Callback(hObject, eventdata, handles)
% hObject    handle to launchWindowCloseText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of launchWindowCloseText as text
%        str2double(get(hObject,'String')) returns contents of launchWindowCloseText as a double
    newInput = get(hObject,'String');

    newInput = attemptStrEval(newInput);

    inputSec = str2double(newInput);
    if(checkStrIsNumeric(newInput) && inputSec>=0.0)
        [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(inputSec);
        dateStr = formDateStr(year, day, hour, minute, sec);
        set(handles.launchWinCloseLabel, 'String', dateStr);
        set(hObject,'String', num2str(inputSec));
    else

    end

% --- Executes during object creation, after setting all properties.
function launchWindowCloseText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to launchWindowCloseText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in computeFlybyPorkchopPlotButton.
function computeFlybyPorkchopPlotButton_Callback(hObject, eventdata, handles)
% hObject    handle to computeFlybyPorkchopPlotButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    celBodyData = getappdata(handles.flyByPorkchopPlotterGUI,'celBodyData');

    errMsg = {};
    
    lWindOpen = str2double(get(handles.launchWindowOpenText,'String'));
    enteredStr = get(handles.launchWindowOpenText,'String');
    numberName = 'Launch window open time';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(lWindOpen, numberName, lb, ub, isInt, errMsg, enteredStr);

    lWindClse = str2double(get(handles.launchWindowCloseText,'String'));
    enteredStr = get(handles.launchWindowCloseText,'String');
    numberName = 'Launch window close time';
    lb = lWindOpen+1;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(lWindClse, numberName, lb, ub, isInt, errMsg, enteredStr);
      
    wayPtBodies = {};
    waypts = get(handles.waypointTable,'Data');
    for(i=1:length(waypts))
        wayPtBodies{end+1} = celBodyData.(lower(waypts{i})); %#ok<AGROW>
    end
    
    if(length(wayPtBodies)<2)
        errMsg = {'At least three way points are required.'};
    end
    
    for(i=1:length(wayPtBodies)-1)
        errMsg = checkIfInputBodiesAreSame(wayPtBodies{i}.name, wayPtBodies{i+1}.name, errMsg, ['Waypoint ', num2str(i)], ['Waypoint ', num2str(i+1)]);
    end
    
    numVarsPerAxis = str2double(get(handles.numPtsPerAxisText,'String'));
    enteredStr = get(handles.numPtsPerAxisText,'String');
    numberName = 'Number of Points per Axis';
    lb = 5;
    ub = Inf;
    isInt = true;
    errMsg = validateNumber(numVarsPerAxis, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(get(handles.includeDepartureVInfCheckbox,'Value')==1)
        considerDVINf = true;
        set(handles.includeDepartureVInfCheckbox,'UserData',1);
    else
        considerDVINf = false;
        set(handles.includeDepartureVInfCheckbox,'UserData',0);
    end
    
    if(get(handles.includeArrivalVInfCheckbox,'Value')==1)
        considerAVINf = true;
        set(handles.includeArrivalVInfCheckbox,'UserData',1);
    else
        considerAVINf = false;
        set(handles.includeArrivalVInfCheckbox,'UserData',0);
    end
    
    if(isempty(errMsg))
        hWaitBar = waitbar(0,'Generating Flyby Porkchop Plot.  Please wait...','WindowStyle','modal');
        
%         try
            bnds = get(handles.flightTimeBndsPanel,'UserData');        
            [lb, ub] = getMultiFlybyLBUB(lWindOpen, lWindClse-lWindOpen, wayPtBodies, celBodyData);
            lb(2:1+length(bnds(:,1))) = [bnds(:,1)];
            ub(2:1+length(bnds(:,2))) = [bnds(:,2)];
            maxRevs = bnds(:,3);

            for(i=1:length(maxRevs))
                tmpNumRevsArrCell = [-maxRevs(i), maxRevs(i)];

                if(wayPtBodies{i}.id == wayPtBodies{i+1}.id)
                    tmpNumRevsArrCell(tmpNumRevsArrCell==0) = [];

                    if(isempty(tmpNumRevsArrCell))
                        tmpNumRevsArrCell = [-1,1];
                    end
                end

                numRevsArr{i} = tmpNumRevsArrCell; %#ok<AGROW>
                lb(end+1) = 1; %#ok<AGROW>
                ub(end+1) = length(tmpNumRevsArrCell); %#ok<AGROW>
            end

            C = {};
            cMat = [];
            for(i=1:length(lb))
                if(abs(ub(i)-lb(i))>1)
                    C{i} = linspace(lb(i),ub(i),numVarsPerAxis)';
                    cMat(:,i) = C{i};
                elseif(abs(ub(i)-lb(i))==1)
                    C{i} = linspace(lb(i),ub(i),2)';
                elseif(abs(ub(i)-lb(i))==0)
                    C{i} = lb(i);
                else
                    error('error');
                end
            end

            waitbar(0.25,hWaitBar,'Generating plot grid...');
            xsol = cartesianProduct(C);
            pause(0.25);

            drawnow;
            waitbar(0.50,hWaitBar,'Computing delta-v...');
            fitnessfcn = @(x) multiFlybyObjFunc(x, numRevsArr,wayPtBodies,celBodyData);
            [~, ~, ~, ~, ~, ~, vInfDepart, vInfArrive, totDV] =  fitnessfcn(xsol);

            dvToPlot = totDV;

            if(considerDVINf)
                dvToPlot = dvToPlot + sqrt(sum(abs(vInfDepart).^2,1))';
            end

            if(considerAVINf)
                dvToPlot = dvToPlot + sqrt(sum(abs(vInfArrive).^2,1))';
            end

            elem1 = 1;
            elem2 = get(handles.dispAxesSelectSlider,'Value');

            resultsToSave = {xsol, numVarsPerAxis, dvToPlot, wayPtBodies, cMat};
            set(handles.dispAxesSelectSlider,'Value',elem2,'Min',2,'Max',length(wayPtBodies)+0.01);
            if(length(wayPtBodies)>2)
                set(handles.dispAxesSelectSlider,'SliderStep',ones(1,2)*(1/(length(wayPtBodies)-2)));
                set(handles.dispAxesSelectSlider,'Visible','on');
            else
                set(handles.dispAxesSelectSlider,'Visible','off');
            end


            waitbar(0.75,hWaitBar,'Plotting delta-v contour map across solution space...');
            clearMarkerLinesFromPlot(handles);
            clearMarkerLinesFromMem(handles);
            generatePorkChopPlot(elem1, elem2, xsol, numVarsPerAxis, dvToPlot, wayPtBodies, cMat, handles, considerDVINf, considerAVINf);
            set(handles.dispAxesSelectSlider,'UserData',resultsToSave);
            set(handles.recomputePlotOnZoomCheckbox,'Enable','on');

            if(ishandle(hWaitBar))
                close(hWaitBar);
            end
%         catch ME
%             if(ishandle(hWaitBar))
%                 close(hWaitBar);
%             end
%             if(strcmp(ME.identifier,'MATLAB:nomem'))
%                 errordlg(sprintf('It looks like the application ran out of available memory.\nTrying lowering the number of points per axis or removing waypoints.'),'Out of Memory');
%             else
%                 errordlg(['Error: ',ME.message],'Error');
%             end
%         end
    else
        msgbox(errMsg,'Errors were found in multi-flyby manuever sequencer inputs','error');
    end
    
    
function generatePorkChopPlot(elem1, elem2, xsol, numVarsPerAxis, dvToPlot, wayPtBodies, cMat, handles, inclDepartDV, inclArriveDV)
    elem1Solns = unique(xsol(:,elem1));
    elem2Solns = unique(xsol(:,elem2));
    DVs = zeros([numVarsPerAxis,numVarsPerAxis]);
    for(i=1:length(elem1Solns))
        for(j=1:length(elem2Solns))
            elem1Soln = elem1Solns(i);
            elem2Soln = elem2Solns(j);

            Inds = find(xsol(:,elem1) == elem1Soln & xsol(:,elem2) == elem2Soln);
            if(~isempty(Inds))
                DVs(i,j) = min(dvToPlot(Inds));
            end
        end
    end
    DVs = DVs';

    wayptFirst = cap1stLetter(wayPtBodies{1}.name);
    waypt1 = cap1stLetter(wayPtBodies{elem2-1}.name);
    waypt2 = cap1stLetter(wayPtBodies{elem2}.name);
    
    contents = cellstr(get(handles.maxDvToDisplayCombo,'String'));
    percentMax = str2double(strrep(contents{get(handles.maxDvToDisplayCombo,'Value')},'%',''))/100;
    maxDV = max(max(DVs))*percentMax;
    minDV = min(min(DVs));
    
    numContourLvls = get(handles.numContourLvlsText,'UserData');
    
    [~, ~, secInDay, ~] = getSecondsInVariousTimeUnits();
    [~,hConf] = contourf(handles.displayAxes,cMat(:,elem1)/secInDay,cMat(:,elem2)/secInDay,DVs,linspace(minDV,maxDV,numContourLvls));
    set(hConf,'UIContextMenu',get(handles.displayAxes,'UIContextMenu'));   
    
    clearMarkerLinesFromPlot(handles);
    
    t = colorbar('peer',handles.displayAxes);
    set(handles.flyByPorkchopPlotterGUI,'Colormap',getFlybyPorkchopPlotCData());
    xlabel(handles.displayAxes,[wayptFirst, ' Departure UT [days]'],'FontWeight','bold');
    ylabel(handles.displayAxes,[waypt1,' -> ',waypt2,' Flight Time [days]'],'FontWeight','bold');
    title(handles.displayAxes,'Multi-Flyby Sequence Delta-V','FontWeight','bold');
    
    dvTypeIncl = '(Includes: Powered Flyby Delta-V';
    if(inclDepartDV)
        dvTypeIncl = [dvTypeIncl,', Departure V_Inf'];
    end
    if(inclArriveDV)
        dvTypeIncl = [dvTypeIncl, ', Arrival V_Inf'];
    end
    dvTypeIncl = [dvTypeIncl,')'];
    set(get(t,'ylabel'),'interpreter','none');
    set(get(t,'ylabel'),'String', sprintf(['Total Mission Delta-V [km/s]\n',dvTypeIncl]),'FontWeight','bold');
    
    axes(handles.displayAxes);
    plotMarkerLines(handles);
    
    CLim = get(gca,'CLim');
    CLim(2) = maxDV;
    caxis(CLim);
    set(gca,'CLim',CLim);
    
    dcm_obj = datacursormode(handles.flyByPorkchopPlotterGUI);
    porkchopUpdate = @(empty, event_obj) flybyPorkchopUpdateFcn(empty, event_obj, cMat(:,elem1), cMat(:,elem2), DVs, inclDepartDV, inclArriveDV);
    set(dcm_obj, 'UpdateFcn', porkchopUpdate, 'DisplayStyle','datatip');


% --- Executes on slider movement.
function dispAxesSelectSlider_Callback(hObject, eventdata, handles)
% hObject    handle to dispAxesSelectSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    value = get(hObject,'Value');
    value = round(value);
    set(hObject,'Value',value); drawnow;

    elem1 = 1;
    elem2 = get(hObject,'Value');

    pause(0.1);
    hWaitBar = waitbar(0,'Generating Flyby Porkchop Plot.  Please wait...','WindowStyle','modal');
    
    if(get(handles.includeDepartureVInfCheckbox,'UserData')==1)
        considerDVINf = true;
    else
        considerDVINf = false;
    end
    
    if(get(handles.includeArrivalVInfCheckbox,'UserData')==1)
        considerAVINf = true;
    else
        considerAVINf = false;
    end
    
    try
    resultsToSave = get(handles.dispAxesSelectSlider,'UserData');
        if(~isempty(resultsToSave))
            xsol = resultsToSave{1};
            numVarsPerAxis = resultsToSave{2};
            dvToPlot = resultsToSave{3};
            wayPtBodies = resultsToSave{4};
            cMat = resultsToSave{5};

            generatePorkChopPlot(elem1, elem2, xsol, numVarsPerAxis, dvToPlot, wayPtBodies, cMat, handles, considerDVINf, considerAVINf);
            
            if(ishandle(hWaitBar))
                close(hWaitBar);
            end
        else
            if(ishandle(hWaitBar))
                close(hWaitBar);
            end
        end
    catch
        if(ishandle(hWaitBar))
            close(hWaitBar);
        end
    end

% --- Executes during object creation, after setting all properties.
function dispAxesSelectSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dispAxesSelectSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in recomputePlotOnZoomCheckbox.
function recomputePlotOnZoomCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to recomputePlotOnZoomCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of recomputePlotOnZoomCheckbox


% --- Executes when entered data in editable cell(s) in waypointTable.
function waypointTable_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to waypointTable (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
    waypointTable_CellSelectionCallback(handles.waypointTable, eventdata, handles);



% --- Executes when selected cell(s) is changed in waypointTable.
function waypointTable_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to waypointTable (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
    set(handles.waypointTable,'UserData',eventdata.Indices);
    
    celBodyData = getappdata(handles.flyByPorkchopPlotterGUI,'celBodyData');
    
    wayPtBodies = {};
    waypts = get(handles.waypointTable,'Data');
    for(i=1:length(waypts))
        wayPtBodies{end+1} = celBodyData.(lower(waypts{i})); %#ok<AGROW>
    end
    
    selected = eventdata.Indices;
    if(isempty(selected))
        selected = size(wayPtBodies);
    end
    selected = selected(1);
    
    if(selected==length(wayPtBodies))
        set(handles.minFlightTimeText,'String','N/A');
        set(handles.maxFlightTimeText,'String','N/A');
        set(handles.maxNumRevsText,'String','N/A');
        
        set(handles.minFlightTimeText,'Enable','off');
        set(handles.maxFlightTimeText,'Enable','off');
        set(handles.maxNumRevsText,'Enable','off');
    else
        set(handles.minFlightTimeText,'Enable','on');
        set(handles.maxFlightTimeText,'Enable','on');
        set(handles.maxNumRevsText,'Enable','on');
        
        waypt1 = cap1stLetter(wayPtBodies{selected}.name);
        waypt2 = cap1stLetter(wayPtBodies{selected+1}.name);
        set(handles.flightTimeBndsPanel,'Title',[waypt1,' -> ',waypt2,' Flight Time Bounds']);
        
        bnds = get(handles.flightTimeBndsPanel,'UserData');
        [~, ~, secInDay, ~] = getSecondsInVariousTimeUnits();
        set(handles.minFlightTimeText,'String',num2str(bnds(selected,1)/secInDay));
        set(handles.maxFlightTimeText,'String',num2str(bnds(selected,2)/secInDay));
        set(handles.maxNumRevsText,'String',num2str(bnds(selected,3)));
    end
    


% --- Executes on button press in includeDepartureVInfCheckbox.
function includeDepartureVInfCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to includeDepartureVInfCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of includeDepartureVInfCheckbox


% --- Executes on button press in includeArrivalVInfCheckbox.
function includeArrivalVInfCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to includeArrivalVInfCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of includeArrivalVInfCheckbox



function minFlightTimeText_Callback(hObject, eventdata, handles)
% hObject    handle to minFlightTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of minFlightTimeText as text
%        str2double(get(hObject,'String')) returns contents of minFlightTimeText as a double
    selected = get(handles.waypointTable,'UserData');
    selected = selected(1);
    bnds = get(handles.flightTimeBndsPanel,'UserData');
    
    celBodyData = getappdata(handles.flyByPorkchopPlotterGUI,'celBodyData');
    
    wayPtBodies = {};
    waypts = get(handles.waypointTable,'Data');
    for(i=1:length(waypts))
        wayPtBodies{end+1} = celBodyData.(lower(waypts{i})); %#ok<AGROW>
    end
    
    if(selected~=length(wayPtBodies))
        newInput = get(hObject,'String');
        newInput = attemptStrEval(newInput);
        set(hObject,'String', newInput);
        
        newInputD = str2double(newInput);
        [~, ~, secInDay, ~] = getSecondsInVariousTimeUnits();
        if(checkStrIsNumeric(newInput) && newInputD>=0.0 && newInputD < bnds(selected,2)/secInDay)
            bnds(selected,1) = newInputD * secInDay;
            set(handles.flightTimeBndsPanel,'UserData',bnds);
        else
            set(hObject,'String', num2str(bnds(selected,1)/secInDay));
            errordlg(['Invalid minimum flight time entered.  Make sure what you entered is a number and that it is less than the maximum shown.'],'Invalid Minimum Flight Time');
        end
    end
    

% --- Executes during object creation, after setting all properties.
function minFlightTimeText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to minFlightTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxFlightTimeText_Callback(hObject, eventdata, handles)
% hObject    handle to maxFlightTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxFlightTimeText as text
%        str2double(get(hObject,'String')) returns contents of maxFlightTimeText as a double
    selected = get(handles.waypointTable,'UserData');
    selected = selected(1);
    bnds = get(handles.flightTimeBndsPanel,'UserData');
    
    celBodyData = getappdata(handles.flyByPorkchopPlotterGUI,'celBodyData');
    
    wayPtBodies = {};
    waypts = get(handles.waypointTable,'Data');
    for(i=1:length(waypts))
        wayPtBodies{end+1} = celBodyData.(lower(waypts{i})); %#ok<AGROW>
    end
    
    if(selected~=length(wayPtBodies))
        newInput = get(hObject,'String');
        newInput = attemptStrEval(newInput);
        set(hObject,'String', newInput);
        
        newInputD = str2double(newInput);
        [~, ~, secInDay, ~] = getSecondsInVariousTimeUnits();
        if(checkStrIsNumeric(newInput) && newInputD>=0.0 && newInputD > bnds(selected,1)/secInDay)
            bnds(selected,2) = newInputD * secInDay;
            set(handles.flightTimeBndsPanel,'UserData',bnds);
        else
            set(hObject,'String', num2str(bnds(selected,2)/secInDay));
            errordlg(['Invalid maximum flight time entered.  Make sure what you entered is a number and that it is greater than the minimum shown.'],'Invalid Maximum Flight Time');
        end
    end

% --- Executes during object creation, after setting all properties.
function maxFlightTimeText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxFlightTimeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in maxDvToDisplayCombo.
function maxDvToDisplayCombo_Callback(hObject, eventdata, handles)
% hObject    handle to maxDvToDisplayCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns maxDvToDisplayCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from maxDvToDisplayCombo
    elem1 = 1;
    elem2 = get(handles.dispAxesSelectSlider,'Value');

    hWaitBar = waitbar(0,'Generating Flyby Porkchop Plot.  Please wait...','WindowStyle','modal');
    
    if(get(handles.includeDepartureVInfCheckbox,'UserData')==1)
        considerDVINf = true;
    else
        considerDVINf = false;
    end
    
    if(get(handles.includeArrivalVInfCheckbox,'UserData')==1)
        considerAVINf = true;
    else
        considerAVINf = false;
    end
    
    try
    resultsToSave = get(handles.dispAxesSelectSlider,'UserData');
        if(~isempty(resultsToSave))
            xsol = resultsToSave{1};
            numVarsPerAxis = resultsToSave{2};
            dvToPlot = resultsToSave{3};
            wayPtBodies = resultsToSave{4};
            cMat = resultsToSave{5};

            generatePorkChopPlot(elem1, elem2, xsol, numVarsPerAxis, dvToPlot, wayPtBodies, cMat, handles, considerDVINf, considerAVINf);
            waitbar(1,hWaitBar,'Done!'); pause(0.25);
            
            if(ishandle(hWaitBar))
                close(hWaitBar);
            end
        else
            if(ishandle(hWaitBar))
                close(hWaitBar);
            end
        end
    catch
        if(ishandle(hWaitBar))
            close(hWaitBar);
        end
    end


% --- Executes during object creation, after setting all properties.
function maxDvToDisplayCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxDvToDisplayCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
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
    launchWindowOpenText_Callback(handles.launchWindowOpenText, eventdata, handles);
    launchWindowCloseText_Callback(handles.launchWindowCloseText, eventdata, handles);
end


% --------------------------------------------------------------------
function placeMarkerLineAtDepartureUTContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to placeMarkerLineAtDepartureUTContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    [x,~] = ginput(1);
    
    markers = get(handles.placeMarkerLineAtDepartureUTContextMenu,'UserData');
    markers(end+1,1) = x;
    markers(end,2) = -1; 
    set(handles.placeMarkerLineAtDepartureUTContextMenu,'UserData',markers);
    
    plotMarkerLines(handles);
    
function plotMarkerLines(handles)
    markers = get(handles.placeMarkerLineAtDepartureUTContextMenu,'UserData');
    
    ylim = get(handles.displayAxes,'YLim');
%     axes(handles.displayAxes);
    for(i=1:size(markers,1))
        markerX = markers(i,1);
        if(~ishandle(markers(i,2)))
            hold(handles.displayAxes,'on');
            h = plot(handles.displayAxes,[markerX markerX],ylim,'w-','LineWidth',3);
            markers(i,2) = h;
        end
        hold(handles.displayAxes,'off');
    end
    set(handles.placeMarkerLineAtDepartureUTContextMenu,'UserData',markers);
    

function clearMarkerLinesFromMem(handles)
      set(handles.placeMarkerLineAtDepartureUTContextMenu,'UserData',[]);  
        
function clearMarkerLinesFromPlot(handles)
    markers = get(handles.placeMarkerLineAtDepartureUTContextMenu,'UserData');
    
    for(i=1:size(markers,1))
        if(ishandle(markers(i,2)))
            delete(markers(i,2));
        end
    end
    drawnow;
    
        

% --------------------------------------------------------------------
function dispAxesContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to dispAxesContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function clearMarkerLinesFromPlotContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to clearMarkerLinesFromPlotContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    clearMarkerLinesFromPlot(handles);
    clearMarkerLinesFromMem(handles);



function numContourLvlsText_Callback(hObject, eventdata, handles)
% hObject    handle to numContourLvlsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numContourLvlsText as text
%        str2double(get(hObject,'String')) returns contents of numContourLvlsText as a double
    errMsg = {};
    
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

    numContourLvls = str2double(get(handles.numContourLvlsText,'String'));
    enteredStr = get(handles.numContourLvlsText,'String');
    numberName = 'Number of Contour Levels';
    lb = 5;
    ub = 100;
    isInt = true;
    errMsg = validateNumber(numContourLvls, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        set(handles.numContourLvlsText,'UserData',numContourLvls);
    else
        numContourLvls = get(handles.numContourLvlsText,'UserData');
        if(isempty(numContourLvls))
            numContourLvls = 20;
        end
        set(handles.numContourLvlsText,'String',num2str(numContourLvls));
        
        msgbox(errMsg,'Num. Contour Level Error','error');
    end


% --- Executes during object creation, after setting all properties.
function numContourLvlsText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numContourLvlsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxNumRevsText_Callback(hObject, eventdata, handles)
% hObject    handle to maxNumRevsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxNumRevsText as text
%        str2double(get(hObject,'String')) returns contents of maxNumRevsText as a double
    selected = get(handles.waypointTable,'UserData');
    selected = selected(1);
    bnds = get(handles.flightTimeBndsPanel,'UserData');
    
    celBodyData = getappdata(handles.flyByPorkchopPlotterGUI,'celBodyData');
    
    wayPtBodies = {};
    waypts = get(handles.waypointTable,'Data');
    for(i=1:length(waypts))
        wayPtBodies{end+1} = celBodyData.(lower(waypts{i})); %#ok<AGROW>
    end
    
    if(selected~=length(wayPtBodies))
        newInput = get(hObject,'String');
        newInput = attemptStrEval(newInput);
        set(hObject,'String', newInput);
        
        newInputD = str2double(newInput);
        err = validateNumber(newInputD, '', 0, Inf, true, {}, newInput);
        
        if(checkStrIsNumeric(newInput) && newInputD>=0.0 && isempty(err))
            bnds(selected,3) = newInputD;
            set(handles.flightTimeBndsPanel,'UserData',bnds);
        else
            set(hObject,'String', num2str(bnds(selected,3)));
            errordlg(['Invalid maximum number of revolutions entered.  Make sure what you entered is a positive integer.'],'Invalid Maximum Revolutions');
        end
    end

% --- Executes during object creation, after setting all properties.
function maxNumRevsText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxNumRevsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
