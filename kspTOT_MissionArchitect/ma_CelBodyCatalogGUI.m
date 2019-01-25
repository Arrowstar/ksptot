function varargout = ma_CelBodyCatalogGUI(varargin)
% MA_CELBODYCATALOGGUI MATLAB code for ma_CelBodyCatalogGUI.fig
%      MA_CELBODYCATALOGGUI, by itself, creates a new MA_CELBODYCATALOGGUI or raises the existing
%      singleton*.
%
%      H = MA_CELBODYCATALOGGUI returns the handle to a new MA_CELBODYCATALOGGUI or the handle to
%      the existing singleton*.
%
%      MA_CELBODYCATALOGGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_CELBODYCATALOGGUI.M with the given input arguments.
%
%      MA_CELBODYCATALOGGUI('Property','Value',...) creates a new MA_CELBODYCATALOGGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_CelBodyCatalogGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_CelBodyCatalogGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_CelBodyCatalogGUI

% Last Modified by GUIDE v2.5 28-Jun-2015 14:21:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_CelBodyCatalogGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_CelBodyCatalogGUI_OutputFcn, ...
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


% --- Executes just before ma_CelBodyCatalogGUI is made visible.
function ma_CelBodyCatalogGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_CelBodyCatalogGUI (see VARARGIN)

% Choose default command line output for ma_CelBodyCatalogGUI
handles.output = hObject;
handles.ma_MainGUI = varargin{1};
% celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
celBodyData = varargin{1};
setappdata(hObject,'celBodyData',celBodyData);

pos = get(handles.dispAxes,'Position');
set(handles.displayAtmoRadio,'UserData',pos);

setupCelBodyListbox(handles, celBodyData);
catalogListbox_Callback(handles.catalogListbox, [], handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ma_CelBodyCatalogGUI wait for user response (see UIRESUME)
% uiwait(handles.ma_CelBodyCatalogGUI);

function setupCelBodyListbox(handles, celBodyData)
%     bodies = fields(celBodyData);
    bodiesStr = ma_getSortedBodyNames(celBodyData);
    
%     bodiesStr = cell(length(bodies),1);
%     for(i = 1:length(bodies)) %#ok<*NO4LP>
%         body = bodies{i};
%         bodiesStr{i} = celBodyData.(strtrim(lower(body))).name;
%     end
    
    set(handles.catalogListbox, 'String', bodiesStr);
    if(length(bodiesStr) >= 1)
        set(handles.catalogListbox, 'value', 1);
    elseif(length(bodiesStr) >= 1)
        set(handles.catalogListbox, 'value', 1);
    end



% --- Outputs from this function are returned to the command line.
function varargout = ma_CelBodyCatalogGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in catalogListbox.
function catalogListbox_Callback(hObject, eventdata, handles)
% hObject    handle to catalogListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns catalogListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from catalogListbox
    contents = cellstr(get(hObject,'String'));
    selected = contents{get(hObject,'Value')};
    
    celBodyData = getappdata(handles.ma_CelBodyCatalogGUI,'celBodyData');
    bodyInfo = celBodyData.(strtrim(lower(selected)));
    parentBodyInfo = bodyInfo.getParBodyInfo(celBodyData);
    bodyInfoStr = generateBodyInfoStr(bodyInfo, celBodyData);
    set(handles.infoLabel,'String',bodyInfoStr);
    
    dispBodyValue = get(handles.displayBodyRadio, 'Value');
    dispOrbValue = get(handles.displayOrbitRadio, 'Value');
    dispAtmoValue = get(handles.displayAtmoRadio, 'Value');
    
    if(bodyInfo.atmohgt == 0)
        set(handles.displayAtmoRadio, 'Enable', 'off');
        if(dispAtmoValue==1)
            set(handles.displayAtmoRadio, 'Value', 0);
            set(handles.displayBodyRadio, 'Value', 1);
            
            dispBodyValue = get(handles.displayBodyRadio, 'Value');
            dispAtmoValue = get(handles.displayAtmoRadio, 'Value');
        end
    else
        set(handles.displayAtmoRadio, 'Enable', 'on');
    end
    
    cla(handles.dispAxes);
    xlabel('');
    ylabel('');
    if(dispBodyValue==1)
        plotBody(handles.ma_CelBodyCatalogGUI,handles.dispAxes,bodyInfo);
        set(handles.dispAxes,'Position',get(handles.displayAtmoRadio,'UserData'));
    elseif(dispOrbValue==1)
        if(~isempty(parentBodyInfo))
            plotBodyOrbit(bodyInfo, 'r', getParentGM(bodyInfo, celBodyData));
            plotBody(handles.ma_CelBodyCatalogGUI,handles.dispAxes,parentBodyInfo);
        else
            plotBody(handles.ma_CelBodyCatalogGUI,handles.dispAxes,bodyInfo);
        end
        set(handles.dispAxes,'Position',get(handles.displayAtmoRadio,'UserData'));
    elseif(dispAtmoValue==1)
        plotAtmoCurve(handles.dispAxes, bodyInfo);
        set(handles.dispAxes,'OuterPosition',get(handles.displayAtmoRadio,'UserData'));
    end
    
function plotAtmoCurve(orbitDispAxes, bodyInfo)
    atmoHgt = bodyInfo.atmohgt;
    
    if(atmoHgt > 0)
        hArr = linspace(0,atmoHgt,100);
        density = zeros(size(hArr));
        for(i=1:length(hArr))
            density(i) = getAtmoDensityAtAltitude(bodyInfo, hArr(i), deg2rad(45));
        end

        plot(orbitDispAxes,hArr,density,'r-','LineWidth',2);
        v = ylim(orbitDispAxes);
        grid on;
        xlim(orbitDispAxes, [min(hArr), max(hArr)]);
        ylim(orbitDispAxes, [0, v(2)]);
        xlabel('Altitude [km]');
        ylabel('Density [kg/m^3]');
    end
    
    
function plotBody(hFig,orbitDispAxes, bodyInfo)
    dRad = bodyInfo.radius;
    [X,Y,Z] = sphere(10);
    hold(orbitDispAxes,'on');
    surf(orbitDispAxes, dRad*X,dRad*Y,dRad*Z);
    ma_initOrbPlot(hFig, orbitDispAxes, bodyInfo);


function bodyInfoStr = generateBodyInfoStr(bodyInfo, celBodyData)
    hrule = '-----------------------------------';
    
    [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(bodyInfo.epoch);
    [dateStr] = formDateStr(year, day, hour, minute, sec);

    parentBodyInfo = bodyInfo.getParBodyInfo(celBodyData);
    if(bodyInfo.sma > 0 && ~isempty(parentBodyInfo))
        [~, ~, secInDay, ~] = getSecondsInVariousTimeUnits();
        period = computePeriod(bodyInfo.sma, getParentGM(bodyInfo, celBodyData));
        periodStr = [num2str(period/secInDay), ' days'];
        
        [rAp, rPe] = computeApogeePerigee(bodyInfo.sma, bodyInfo.ecc);
        rApStr = [num2str(rAp), ' km'];
        rPeStr = [num2str(rPe), ' km'];
    else
        periodStr = 'N/A';
        
        [~, rPe] = computeApogeePerigee(bodyInfo.sma, bodyInfo.ecc);
        rApStr = 'N/A';
        rPeStr = [num2str(rPe), ' km'];
    end
    
    if(bodyInfo.sma == 0)
        rPeStr = 'N/A';
    end
    
    if(isempty(bodyInfo.parent))
        parentStr = 'N/A';
        rSOIStr = 'N/A';
        rSOI = Inf;
    else
        parentStr = bodyInfo.parent;
        
        rSOI = getSOIRadius(bodyInfo, parentBodyInfo);
        rSOIStr = [num2str(rSOI), ' km'];
    end
    
    sPhr = floor(bodyInfo.rotperiod/3600);
    sPmin = floor((bodyInfo.rotperiod - 3600*sPhr)/60);
    sPsec = bodyInfo.rotperiod - 3600*sPhr - 60*sPmin;
    sPStr = sprintf('%02.0f:%02.0f:%07.4f',sPhr,sPmin,sPsec);
    
    syncSMA = computeSMAFromPeriod(bodyInfo.rotperiod, bodyInfo.gm);
    if(syncSMA > rSOI)
        syncNotPoss = '*';
    else
        syncNotPoss = '';
    end
    
    bodyInfoStr{1} = ['Name: ', bodyInfo.name];
    bodyInfoStr{end+1} = ['ID: ', num2str(bodyInfo.id)];
    bodyInfoStr{end+1} = ['Parent: ', parentStr];
    bodyInfoStr{end+1} = hrule;
    
    bodyInfoStr{end+1} = 'Orbit';
    bodyInfoStr{end+1} = [' Epoch = ', dateStr];
    bodyInfoStr{end+1} = [' SMA = ', num2str(bodyInfo.sma), ' km'];
    bodyInfoStr{end+1} = [' Ecc = ', num2str(bodyInfo.ecc)];
    bodyInfoStr{end+1} = [' Inc = ', num2str(bodyInfo.inc), ' deg'];
    bodyInfoStr{end+1} = [' RAAN = ', num2str(bodyInfo.raan), ' deg'];
    bodyInfoStr{end+1} = [' Arg = ', num2str(bodyInfo.arg), ' deg'];
    bodyInfoStr{end+1} = [' Mean = ', num2str(bodyInfo.mean), ' deg'];
    bodyInfoStr{end+1} = hrule;
    
    bodyInfoStr{end+1} = 'Physical Properties';
    bodyInfoStr{end+1} = [' GM = ', num2str(bodyInfo.gm), ' km^3/s^2'];
    bodyInfoStr{end+1} = [' Radius = ', num2str(bodyInfo.radius), ' km'];
    bodyInfoStr{end+1} = [' Atmo Height = ', num2str(bodyInfo.atmohgt), ' km'];
    bodyInfoStr{end+1} = [' Atmo SL Press = ', num2str(getPressureAtAltitude(bodyInfo, 0)), ' kPa'];
    bodyInfoStr{end+1} = [' Sidereal Day = ', num2str(bodyInfo.rotperiod), ' sec'];
    bodyInfoStr{end+1} = ['              = ', sPStr];
    bodyInfoStr{end+1} = hrule;
    
    bodyInfoStr{end+1} = 'Derived';
    bodyInfoStr{end+1} = [' Orbit Period = ', periodStr];
    bodyInfoStr{end+1} = [' Orbit RPe = ', rPeStr];
    bodyInfoStr{end+1} = [' Orbit RAp = ', rApStr];
    bodyInfoStr{end+1} = [' SoI Radius = ', rSOIStr];
    bodyInfoStr{end+1} = [' Sync. SMA = ', num2str(syncSMA), ' km',syncNotPoss];

% --- Executes during object creation, after setting all properties.
function catalogListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to catalogListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when selected object is changed in dispAxesButtonGrp.
function dispAxesButtonGrp_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in dispAxesButtonGrp 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
    catalogListbox_Callback(handles.catalogListbox, [], handles);


% --- Executes on key press with focus on ma_CelBodyCatalogGUI or any of its controls.
function ma_CelBodyCatalogGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to ma_CelBodyCatalogGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'escape'
            close(handles.ma_CelBodyCatalogGUI);
    end
