function varargout = ma_SplitDvManeuverGUI(varargin)
% MA_SPLITDVMANEUVERGUI MATLAB code for ma_SplitDvManeuverGUI.fig
%      MA_SPLITDVMANEUVERGUI, by itself, creates a new MA_SPLITDVMANEUVERGUI or raises the existing
%      singleton*.
%
%      H = MA_SPLITDVMANEUVERGUI returns the handle to a new MA_SPLITDVMANEUVERGUI or the handle to
%      the existing singleton*.
%
%      MA_SPLITDVMANEUVERGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_SPLITDVMANEUVERGUI.M with the given input arguments.
%
%      MA_SPLITDVMANEUVERGUI('Property','Value',...) creates a new MA_SPLITDVMANEUVERGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_SplitDvManeuverGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_SplitDvManeuverGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_SplitDvManeuverGUI

% Last Modified by GUIDE v2.5 19-Aug-2016 18:11:26

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_SplitDvManeuverGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_SplitDvManeuverGUI_OutputFcn, ...
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


% --- Executes just before ma_SplitDvManeuverGUI is made visible.
function ma_SplitDvManeuverGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_SplitDvManeuverGUI (see VARARGIN)

% Choose default command line output for ma_SplitDvManeuverGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

numBurns = varargin{1};
totalDeltaV = varargin{2};
isp = varargin{3};
m0 = varargin{4};
mdot = varargin{5};

setappdata(handles.ma_SplitDvManeuverGUI,'numBurns',numBurns);
setappdata(handles.ma_SplitDvManeuverGUI,'totalDeltaV',totalDeltaV);
setappdata(handles.ma_SplitDvManeuverGUI,'isp',isp);
setappdata(handles.ma_SplitDvManeuverGUI,'m0',m0);
setappdata(handles.ma_SplitDvManeuverGUI,'mdot',mdot);

handles.splitTypeButtonGrp.SelectedObject = handles.splitByDvRadioButton;

handles = createGUIWidgets(handles, numBurns, totalDeltaV, isp, m0, mdot);
slidersCallback(-1, [], handles.splitDvPanel, numBurns, totalDeltaV, isp, m0, mdot, handles);
guidata(hObject, handles);

% UIWAIT makes ma_SplitDvManeuverGUI wait for user response (see UIRESUME)
uiwait(handles.ma_SplitDvManeuverGUI);

function handles = createGUIWidgets(handles, numBurns, totalDeltaV, isp, m0, mdot)
    deltaY = 28;
    
    position = get(handles.splitDvPanel,'Position');
    hgtAdjust = (10-numBurns)*deltaY;
    position(4) = position(4) - hgtAdjust;
    set(handles.splitDvPanel,'Position',position);
    
    position = get(handles.ma_SplitDvManeuverGUI,'Position');
    position(4) = position(4) - hgtAdjust;
    set(handles.ma_SplitDvManeuverGUI,'Position',position);
    
    position = get(handles.splitTypeButtonGrp,'Position');
    position(2) = position(2) - hgtAdjust;
    set(handles.splitTypeButtonGrp,'Position',position);
    
    for(i=1:numBurns) %#ok<*NO4LP>
        sCb = @(src,evt) slidersCallback(src, evt, handles.splitDvPanel, numBurns, totalDeltaV, isp, m0, mdot, handles);
        sH = createSlider(i, deltaY, handles.splitDvPanel, sCb, numBurns);
        handles.(get(sH,'Tag')) = sH;
        
        cH = createLockCheckbox(i, deltaY, handles.splitDvPanel);
        handles.(get(cH,'Tag')) = cH;
        
        dvCb = @(src,evt) dvTextCallback(src, evt, i, handles.splitDvPanel, totalDeltaV);
        dvH = createDvText(i, deltaY, handles.splitDvPanel, dvCb);
        handles.(get(dvH,'Tag')) = dvH;
        
        uH = createUnitText(i, deltaY, handles.splitDvPanel);
        handles.(get(uH,'Tag')) = uH;
    end
    
function sH = createSlider(burnNum, deltaY, parent, cb, numBurns)
    yAdjust = get(parent,'Position');
    yAdjust = 394 - yAdjust(4);

    sliderX = 17;
    sliderBaseY = 332 - yAdjust;
    sliderWidth = 124;
    sliderHeight = 15;

    sliderPosition = [sliderX,sliderBaseY-(burnNum-1)*deltaY,sliderWidth,sliderHeight];
    sH = uicontrol(parent,'Style','slider',...
                   'Position',sliderPosition,...
                   'Tag',['Slider',num2str(burnNum)],...
                   'Value', 1/numBurns,...
                   'Callback',cb,...
                   'UserData',1);
        
function cH = createLockCheckbox(burnNum, deltaY, parent)
    yAdjust = get(parent,'Position');
    yAdjust = 394 - yAdjust(4);

    lockCheckX = 147;
    lockCheckBaseY = 328 - yAdjust;
    lockCheckWidth = 51;
    lockCheckHeight = 23;
        
    checkboxPosition = [lockCheckX,lockCheckBaseY-(burnNum-1)*deltaY,lockCheckWidth,lockCheckHeight];
    cb = @(src,evt) lockCallback(src, evt, burnNum, parent);
    cH = uicontrol(parent,'Style','checkbox',...
                   'Position',checkboxPosition,...
                   'Tag',['lockCheckBox',num2str(burnNum)],...
                   'Value',0,...
                   'String','Lock',...
                   'Callback',cb);
               
function dvH = createDvText(burnNum, deltaY, parent, dvCb)
    yAdjust = get(parent,'Position');
    yAdjust = 394 - yAdjust(4);

    dvTextX = 191;
    dvTextBaseY = 332 - yAdjust;
    dvTextWidth = 46;
    dvTextHeight = 15;
    
    dvTextPosition = [dvTextX,dvTextBaseY-(burnNum-1)*deltaY,dvTextWidth,dvTextHeight];
    dvH = uicontrol(parent,'Style','edit',...
                   'Position',dvTextPosition,...
                   'Tag',['dvText',num2str(burnNum)],...
                   'Callback',dvCb);
               
function uH = createUnitText(burnNum, deltaY, parent)
    yAdjust = get(parent,'Position');
    yAdjust = 394 - yAdjust(4);

    unitTextX = 239;
    unitTextBaseY = 331 - yAdjust;
    unitTextWidth = 30;
    unitTextHeight = 17;
        
    unitTextPosition = [unitTextX,unitTextBaseY-(burnNum-1)*deltaY,unitTextWidth,unitTextHeight];
    uH = uicontrol(parent,'Style','text',...
                   'Position',unitTextPosition,...
                   'Tag',['unitText',num2str(burnNum)],...
                   'BackgroundColor',[0.6,1.0,0.6],...
                   'String','m/s',...
                   'HorizontalAlignment','center',...
                   'Callback',[]);
               
function slidersCallback(src, ~, parent, numBurns, totalDeltaV, isp, m0, mdot, handles)      
    totalTime = getBurnDuration(m0, mdot, isp, totalDeltaV/1000);

    sumValue = 0;
    for(i=1:numBurns)
        slider = findobj('Parent',parent,'Tag',['Slider',num2str(i)]);
        sumValue = sumValue + slider.Value;
    end
    
    totalAdjust = (1.0 - sumValue);
    adjustableSliders = [];
    for(i=1:numBurns)
        slider = findobj('Parent',parent,'Tag',['Slider',num2str(i)]);
        if(src == slider || get(slider,'UserData')==0)
            continue;
        elseif(get(slider,'UserData')==1)
            if(totalAdjust < 0 && slider.Value>0.0)
                adjustableSliders(end+1) = i;
            elseif(totalAdjust > 0 && slider.Value<1.0)
                adjustableSliders(end+1) = i;
            end
        end
    end
    
    deltaToAdjust = totalAdjust/length(adjustableSliders);
    for(i=1:length(adjustableSliders))
        sId = adjustableSliders(i);
        slider = findobj('Parent',parent,'Tag',['Slider',num2str(sId)]);
        slider.Value = max(slider.Value + deltaToAdjust, 0.0);
    end
    
    newSumValue = 0;
    for(i=1:numBurns)
        slider = findobj('Parent',parent,'Tag',['Slider',num2str(i)]);
        newSumValue = newSumValue + slider.Value;
    end
    if(abs(newSumValue - 1.0)>=10*eps)
        srcAdjust = 1.0 - newSumValue;
        src.Value = src.Value + srcAdjust;
    end
    
    for(i=1:numBurns)
        slider = findobj('Parent',parent,'Tag',['Slider',num2str(i)]);
        dvText = findobj('Parent',parent,'Tag',['dvText',num2str(i)]);
        
        switch handles.splitTypeButtonGrp.SelectedObject
            case handles.splitByDvRadioButton
                dv = strtrim(sprintf('%8.3f',slider.Value*totalDeltaV));
            case handles.splitByTimeRadioButton
                dv = strtrim(sprintf('%8.3f',slider.Value*totalTime));
        end
        
        set(dvText,'String',dv);
    end
    

function lockCallback(src, ~, burnNum, parent)
    lockCheckBox = src;
    slider = findobj('Parent',parent,'Tag',['Slider',num2str(burnNum)]);
    dvText = findobj('Parent',parent,'Tag',['dvText',num2str(burnNum)]);
    
    if(get(lockCheckBox,'value')==1)
        set(slider,'Enable','off');
        set(slider,'UserData',0);
        set(dvText,'Enable','off');
    else
        set(slider,'Enable','on');
        set(slider,'UserData',1);
        set(dvText,'Enable','on');
    end
    
    
function dvTextCallback(src, ~, burnNum, parent, totalDeltaV)
	slider = findobj('Parent',parent,'Tag',['Slider',num2str(burnNum)]);

    srcStr = get(src,'String');
    srcD = str2double(srcStr);
    if(isnan(srcD) || srcD < 0 || srcD > totalDeltaV)
        sValue = slider.Value;
        sliderDv = sValue * totalDeltaV;
        dv = strtrim(sprintf('%8.3f',sliderDv));
        set(src,'String',dv);
    else
        sliderValue = srcD/totalDeltaV;
        slider.Value = sliderValue;
        sCb = slider.Callback;
        sCb(slider,[]);
    end
        

% --- Outputs from this function are returned to the command line.
function varargout = ma_SplitDvManeuverGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = [];
        varargout{2} = [];
    else
        numBurns = getappdata(handles.ma_SplitDvManeuverGUI,'numBurns');
        
        burnValues = zeros(0,2);
        for(i=1:numBurns)
            slider = findobj('Parent',handles.splitDvPanel,'Tag',['Slider',num2str(i)]);
            burnValues(end+1,:) = [i,slider.Value]; %#ok<AGROW>
        end
        varargout{1} = burnValues;
        
        switch handles.splitTypeButtonGrp.SelectedObject
            case handles.splitByDvRadioButton
                varargout{2} = 'DV';
            case handles.splitByTimeRadioButton
                varargout{2} = 'Time';
        end
        
        close(handles.ma_SplitDvManeuverGUI);
    end


% --- Executes on button press in saveCloseButton.
function saveCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.ma_SplitDvManeuverGUI);
    

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.ma_SplitDvManeuverGUI);


% --- Executes on key press with focus on ma_SplitDvManeuverGUI or any of its controls.
function ma_SplitDvManeuverGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to ma_SplitDvManeuverGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'escape'
            close(handles.ma_SplitDvManeuverGUI);
    end


% --- Executes when selected object is changed in splitTypeButtonGrp.
function splitTypeButtonGrp_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in splitTypeButtonGrp 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    numBurns = getappdata(handles.ma_SplitDvManeuverGUI,'numBurns');
    totalDeltaV = getappdata(handles.ma_SplitDvManeuverGUI,'totalDeltaV');
    isp = getappdata(handles.ma_SplitDvManeuverGUI,'isp');
    m0 = getappdata(handles.ma_SplitDvManeuverGUI,'m0');
    mdot = getappdata(handles.ma_SplitDvManeuverGUI,'mdot');

    unitText = '';
    switch handles.splitTypeButtonGrp.SelectedObject
        case handles.splitByDvRadioButton
            dvStr = strtrim(sprintf('%8.3f',totalDeltaV));
            titleStr = sprintf('Split Delta-V Maneuver (%s m/s)',dvStr);
            
            unitText = 'm/s';
        case handles.splitByTimeRadioButton
            totalTime = getBurnDuration(m0, mdot, isp, totalDeltaV/1000);
            dvStr = strtrim(sprintf('%8.3f',totalTime));
            titleStr = sprintf('Split Delta-V Maneuver (%s s)',dvStr);
            
            unitText = 's';
    end
    
    set(handles.splitDvPanel,'Title',titleStr);
    
    for(i=1:numBurns)
        handles.(['unitText',num2str(i)]).String = unitText;
    end
    
    slidersCallback(-1, [], handles.splitDvPanel, numBurns, totalDeltaV, isp, m0, mdot, handles);
