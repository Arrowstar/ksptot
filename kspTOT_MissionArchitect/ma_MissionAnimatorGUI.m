function varargout = ma_MissionAnimatorGUI(varargin)
% MA_MISSIONANIMATORGUI MATLAB code for ma_MissionAnimatorGUI.fig
%      MA_MISSIONANIMATORGUI, by itself, creates a new MA_MISSIONANIMATORGUI or raises the existing
%      singleton*.
%
%      H = MA_MISSIONANIMATORGUI returns the handle to a new MA_MISSIONANIMATORGUI or the handle to
%      the existing singleton*.
%
%      MA_MISSIONANIMATORGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_MISSIONANIMATORGUI.M with the given input arguments.
%
%      MA_MISSIONANIMATORGUI('Property','Value',...) creates a new MA_MISSIONANIMATORGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_MissionAnimatorGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_MissionAnimatorGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_MissionAnimatorGUI

% Last Modified by GUIDE v2.5 01-May-2015 16:05:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_MissionAnimatorGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_MissionAnimatorGUI_OutputFcn, ...
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


% --- Executes just before ma_MissionAnimatorGUI is made visible.
function ma_MissionAnimatorGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_MissionAnimatorGUI (see VARARGIN)

% Choose default command line output for ma_MissionAnimatorGUI
global GLOBAL_VideoWriter GLOBAL_isRecording;

handles.output = hObject;

% Update handles structure
handles.ma_MainGUI = varargin{1};
guidata(hObject, handles);

handles = initGUI(handles);
guidata(hObject, handles);

GLOBAL_VideoWriter = [];
GLOBAL_isRecording = false;

% UIWAIT makes ma_MissionAnimatorGUI wait for user response (see UIRESUME)
% uiwait(handles.ma_MissionAnimatorGUI);

function handles = initGUI(handles)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    stateLog = maData.stateLog;      

    set(handles.playButton,'String','<html>&#9658'); %&#9553; pause symbol OR &#9616;&#9616;'
    set(handles.rewindButton,'String','<html>&laquo;');
    set(handles.fastForwardButton,'String','<html>&raquo;');
    if(size(stateLog,1) > 1)
        lowerStep = 1/(size(stateLog,1)-1);
        set(handles.movieFrameSlider,'Min',stateLog(1,1),'Max',stateLog(end,1),'Value',stateLog(1,1));
        set(handles.movieFrameSlider,'SliderStep',[lowerStep,0.1]);
    else
        set(handles.movieFrameSlider,'Min',stateLog(1,1),'Max',stateLog(1,1)+1,'Value',stateLog(1,1));
    end
    
    setCamSrcTgtComboBoxes(handles);
    
    frameRateCombo_Callback(handles.frameRateCombo, [], handles);
    warpRateCombo_Callback(handles.warpRateCombo, [], handles);
    spacecraftMarkerCombo_Callback(handles.spacecraftMarkerCombo, [], handles);
    spacecraftMarkerColorCombo_Callback(handles.spacecraftMarkerColorCombo, [], handles);
    scMarkerSizeCombo_Callback(handles.scMarkerSizeCombo, [], handles);
    
    showChildBodiesCheckbox_Callback(handles.showChildBodiesCheckbox, [], handles);
    showChildBodyOrbitsCheckbox_Callback(handles.showChildBodyOrbitsCheckbox,[],handles);
    showGroundStationsCheckbox_Callback(handles.showGroundStationsCheckbox, [], handles);
    showOtherScCheckbox_Callback(handles.showOtherScCheckbox, [], handles);
    showGridCheckbox_Callback(handles.showGridCheckbox, [], handles);
    
    annoteShowUTCheckbox_Callback(handles.annoteShowUTCheckbox, [], handles);
	annoteShowOrbitCheckbox_Callback(handles.annoteShowOrbitCheckbox, [], handles);
    annoteShowLatLongCheckbox_Callback(handles.annoteShowLatLongCheckbox, [], handles);
    annoteShowMassCheckbox_Callback(handles.annoteShowMassCheckbox, [], handles);
    showFpsCheckbox_Callback(handles.showFpsCheckbox, [], handles);
    
    backgroundColorCombo_Callback(handles.backgroundColorCombo, [], handles);
    
    cameraTypeCombo_Callback(handles.cameraTypeCombo, [], handles);
    axesScaleFactorText_Callback(handles.axesScaleFactorText, [], handles);
    fieldOfViewText_Callback(handles.fieldOfViewText,[],handles);
    azOffsetText_Callback(handles.azOffsetText, [], handles);
    elOffsetText_Callback(handles.elOffsetText, [], handles);
    rngOffsetText_Callback(handles.rngOffsetText, [], handles);
       
    cameraSrcCombo_Callback(handles.cameraSrcCombo,[],handles);
    cameraTgtCombo_Callback(handles.cameraTgtCombo, [], handles);
    
	sliderUTText_Callback(handles.sliderUTText, [], handles);
    
    set(handles.ma_MissionAnimatorGUI,'Visible','on');
    
    plotOneFrame(handles);
    

function plotOneFrame(handles)
    if(strcmpi(get(handles.ma_MissionAnimatorGUI,'Visible'),'on'))
        maData = getappdata(handles.ma_MainGUI,'ma_data');
        stateLog = maData.stateLog;  
        celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');

        time = get(handles.movieFrameSlider,'Value');
        orbitToPlot = ma_getOrbitToPlot(stateLog, time);
        
        hFig = handles.ma_MissionAnimatorGUI;
        mAxes = handles.movieAxes;

        ma_plotFrame(hFig, mAxes, maData, stateLog, time, NaN, orbitToPlot, celBodyData, handles);
    end
    

% --- Outputs from this function are returned to the command line.
function varargout = ma_MissionAnimatorGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function movieFrameSlider_Callback(hObject, eventdata, handles)
% hObject    handle to movieFrameSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    set(handles.sliderUTText, 'String', fullAccNum2Str(get(handles.movieFrameSlider,'Value')));
    plotOneFrame(handles);

% --- Executes during object creation, after setting all properties.
function movieFrameSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to movieFrameSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in rewindButton.
function rewindButton_Callback(hObject, eventdata, handles)
% hObject    handle to rewindButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    stateLog = maData.stateLog;
    
    currentUT = get(handles.movieFrameSlider,'Value');
    
    bodyChangeInd = find(diff(stateLog(:,13)) ~= 0 | diff(stateLog(:,8)) ~= 0);
    bodyChangeUTs = stateLog(bodyChangeInd,1);
    jumpToUT = -1;
    for(i=length(bodyChangeInd):-1:1)
        if(currentUT > bodyChangeUTs(i))
            jumpToUT = bodyChangeUTs(i);
            break;
        end
    end
    
    if(jumpToUT == -1)
        jumpToUT = stateLog(1,1);
    end
    
    set(handles.movieFrameSlider,'Value',jumpToUT);
    movieFrameSlider_Callback(handles.movieFrameSlider, [], handles);

% --- Executes on button press in fastForwardButton.
function fastForwardButton_Callback(hObject, eventdata, handles)
% hObject    handle to fastForwardButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    stateLog = maData.stateLog;
    
    currentUT = get(handles.movieFrameSlider,'Value');
    
    bodyChangeInd = find(diff(stateLog(:,13)) ~= 0 | diff(stateLog(:,8)) ~= 0);
    bodyChangeUTs = stateLog(bodyChangeInd,1);
    jumpToUT = -1;
    for(i=1:length(bodyChangeInd))
        if(currentUT < bodyChangeUTs(i))
            jumpToUT = bodyChangeUTs(i);
            break;
        end
    end
    
    if(jumpToUT == -1)
        jumpToUT = stateLog(end,1);
    end
    
    set(handles.movieFrameSlider,'Value',jumpToUT);
    movieFrameSlider_Callback(handles.movieFrameSlider, [], handles);
    
    
% --- Executes on button press in playButton.
function playButton_Callback(hObject, eventdata, handles)
% hObject    handle to playButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    frameRate = get(handles.frameRateCombo,'UserData'); %frame/sec
    
    clear('playMovieTimerCallback');
    ma_handlePlayButton(handles, frameRate);


% --- Executes on selection change in frameRateCombo.
function frameRateCombo_Callback(hObject, eventdata, handles)
% hObject    handle to frameRateCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns frameRateCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from frameRateCombo
    contents = cellstr(get(hObject,'String'));
    frameFrateStr = contents{get(hObject,'Value')};
    
    pattern = '([0-9]*) Frame\/Sec';
    tokens = regexp(frameFrateStr,pattern,'tokens');
    set(hObject,'UserData',str2double(tokens{1}{1}));

    
% --- Executes during object creation, after setting all properties.
function frameRateCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to frameRateCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in warpRateCombo.
function warpRateCombo_Callback(hObject, eventdata, handles)
% hObject    handle to warpRateCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns warpRateCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from warpRateCombo
    contents = cellstr(get(hObject,'String'));
    warpRate = contents{get(hObject,'Value')};
    
    pattern = '([0-9]*)x';
    tokens = regexp(warpRate,pattern,'tokens');
    set(hObject,'UserData',str2double(tokens{1}{1}));
    

% --- Executes during object creation, after setting all properties.
function warpRateCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to warpRateCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in spacecraftMarkerCombo.
function spacecraftMarkerCombo_Callback(hObject, eventdata, handles)
% hObject    handle to spacecraftMarkerCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns spacecraftMarkerCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from spacecraftMarkerCombo
    contents = cellstr(get(hObject,'String'));
    marker = contents{get(hObject,'Value')};
    set(hObject,'UserData',marker);
    
    if(get(handles.playButton,'Value')==0)
        plotOneFrame(handles);
    end
    

% --- Executes during object creation, after setting all properties.
function spacecraftMarkerCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to spacecraftMarkerCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in spacecraftMarkerColorCombo.
function spacecraftMarkerColorCombo_Callback(hObject, eventdata, handles)
% hObject    handle to spacecraftMarkerColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns spacecraftMarkerColorCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from spacecraftMarkerColorCombo
    contents = cellstr(get(hObject,'String'));
    colorFull = contents{get(hObject,'Value')};
    
    switch(colorFull)
        case 'Black'
            color = 'k'; 
        case 'Red'
            color = 'r'; 
        case 'Green'
            color = 'g'; 
        case 'Blue'
            color = 'b'; 
        case 'Cyan'
            color = 'c'; 
        case 'Magena'
            color = 'm'; 
        case 'Yellow'
            color = 'y'; 
        case 'White'
            color = 'w';
        otherwise
            color = 'k'; 
    end

    set(hObject,'UserData',color);
    
    if(get(handles.playButton,'Value')==0)
        plotOneFrame(handles);
    end
    

% --- Executes during object creation, after setting all properties.
function spacecraftMarkerColorCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to spacecraftMarkerColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in scMarkerSizeCombo.
function scMarkerSizeCombo_Callback(hObject, eventdata, handles)
% hObject    handle to scMarkerSizeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns scMarkerSizeCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from scMarkerSizeCombo
    contents = cellstr(get(hObject,'String'));
    markerSize = contents{get(hObject,'Value')};
    set(hObject,'UserData',str2double(markerSize));
    
    if(get(handles.playButton,'Value')==0)
        plotOneFrame(handles);
    end

% --- Executes during object creation, after setting all properties.
function scMarkerSizeCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scMarkerSizeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in showChildBodiesCheckbox.
function showChildBodiesCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to showChildBodiesCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showChildBodiesCheckbox
    set(hObject,'UserData',get(hObject,'Value'));
    
    if(get(handles.playButton,'Value')==0)
        plotOneFrame(handles);
    end

% --- Executes on button press in showGroundStationsCheckbox.
function showGroundStationsCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to showGroundStationsCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showGroundStationsCheckbox
    set(hObject,'UserData',get(hObject,'Value'));
    if(get(handles.playButton,'Value')==0)
        plotOneFrame(handles);
    end

% --- Executes on button press in showOtherScCheckbox.
function showOtherScCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to showOtherScCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showOtherScCheckbox
    set(hObject,'UserData',get(hObject,'Value'));
    if(get(handles.playButton,'Value')==0)
        plotOneFrame(handles);
    end
    
    
% --- Executes on button press in showGridCheckbox.
function showGridCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to showGridCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showGridCheckbox
    if(get(hObject,'Value')==1)
        set(hObject,'UserData','on');
    else
        set(hObject,'UserData','off');
    end
    
    if(get(handles.playButton,'Value')==0)
        plotOneFrame(handles);
    end
    

% --- Executes on button press in annoteShowUTCheckbox.
function annoteShowUTCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to annoteShowUTCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of annoteShowUTCheckbox
    set(hObject,'UserData',get(hObject,'Value'));
    if(get(handles.playButton,'Value')==0)
        plotOneFrame(handles);
    end
    
% --- Executes on button press in annoteShowOrbitCheckbox.
function annoteShowOrbitCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to annoteShowOrbitCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of annoteShowOrbitCheckbox
    set(hObject,'UserData',get(hObject,'Value'));
    
    if(get(handles.playButton,'Value')==0)
        plotOneFrame(handles);
    end
% --- Executes on button press in annoteShowLatLongCheckbox.
function annoteShowLatLongCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to annoteShowLatLongCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of annoteShowLatLongCheckbox
    set(hObject,'UserData',get(hObject,'Value'));
    if(get(handles.playButton,'Value')==0)
        plotOneFrame(handles);
    end
    
% --- Executes on button press in annoteShowMassCheckbox.
function annoteShowMassCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to annoteShowMassCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of annoteShowMassCheckbox
    set(hObject,'UserData',get(hObject,'Value'));
    if(get(handles.playButton,'Value')==0)
        plotOneFrame(handles);
    end

    
% --- Executes on button press in showFpsCheckbox.
function showFpsCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to showFpsCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showFpsCheckbox
    set(hObject,'UserData',get(hObject,'Value'));
    if(get(handles.playButton,'Value')==0)
        plotOneFrame(handles);
    end
    
    
% --- Executes on selection change in cameraTypeCombo.
function cameraTypeCombo_Callback(hObject, eventdata, handles)
% hObject    handle to cameraTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns cameraTypeCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from cameraTypeCombo
    contents = cellstr(get(hObject,'String'));
    sel = strtrim(contents{get(hObject,'Value')});
    set(hObject,'UserData',sel);
    
    switch(sel)
        case 'Inertially Fixed'
            set(handles.fieldOfViewText,'Enable','off');
            set(handles.rngOffsetText,'Enable','off');
            set(handles.viewAngleSlider,'Enable','off');
            set(handles.rngOffsetSlider,'Enable','off');
            set(handles.cameraSrcCombo,'Enable','off');
            set(handles.cameraTgtCombo,'Enable','off');
        case 'Spacecraft Fixed'
            set(handles.fieldOfViewText,'Enable','on');
            set(handles.rngOffsetText,'Enable','on');
            set(handles.viewAngleSlider,'Enable','on');
            set(handles.rngOffsetSlider,'Enable','on');
            set(handles.cameraSrcCombo,'Enable','on');
            set(handles.cameraTgtCombo,'Enable','on');
    end
    
    if(get(handles.playButton,'Value')==0)
        plotOneFrame(handles);
    end
    

% --- Executes during object creation, after setting all properties.
function cameraTypeCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cameraTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in backgroundColorCombo.
function backgroundColorCombo_Callback(hObject, eventdata, handles)
% hObject    handle to backgroundColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns backgroundColorCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from backgroundColorCombo
    contents = cellstr(get(hObject,'String'));
    bgColor = contents{get(hObject,'Value')};
    
    switch(bgColor)
        case 'White'
            data = ['wkkk'];
        case 'Black'
            data = ['kwww'];
        otherwise
            data = ['wkkk'];
    end
    
    set(hObject,'UserData',data);
    
    if(get(handles.playButton,'Value')==0)
        plotOneFrame(handles);
    end

% --- Executes during object creation, after setting all properties.
function backgroundColorCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to backgroundColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function fieldOfViewText_Callback(hObject, eventdata, handles)
% hObject    handle to fieldOfViewText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fieldOfViewText as text
%        str2double(get(hObject,'String')) returns contents of fieldOfViewText as a double
    str = attemptStrEval(get(hObject,'String'));
    if(checkStrIsNumeric(str) && str2double(str) >= 1 && str2double(str) <= 180)
        set(hObject, 'UserData', str2double(str));
        set(hObject, 'String', str);
        set(handles.viewAngleSlider, 'Value', str2double(get(hObject,'String')));
        
        if(get(handles.playButton,'Value')==0)
            plotOneFrame(handles);
        end
    else
        set(hObject, 'String', get(hObject,'UserData'));
        set(handles.viewAngleSlider, 'Value', get(hObject,'UserData'));
    end

% --- Executes during object creation, after setting all properties.
function fieldOfViewText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fieldOfViewText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function azOffsetText_Callback(hObject, eventdata, handles)
% hObject    handle to azOffsetText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of azOffsetText as text
%        str2double(get(hObject,'String')) returns contents of azOffsetText as a double
    str = attemptStrEval(get(hObject,'String'));
    if(checkStrIsNumeric(str) && str2double(str) >=-360 && str2double(str) <=360)
        set(hObject, 'UserData', str2double(str));
        set(hObject, 'String', str);
        set(handles.azOffsetSlider, 'Value', str2double(get(hObject,'String')));
        
        if(get(handles.playButton,'Value')==0)
            plotOneFrame(handles);
        end
    else
        set(hObject, 'String', get(hObject,'UserData'));
        set(handles.azOffsetSlider, 'Value', get(hObject,'UserData'));
    end

% --- Executes during object creation, after setting all properties.
function azOffsetText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to azOffsetText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function elOffsetText_Callback(hObject, eventdata, handles)
% hObject    handle to elOffsetText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of elOffsetText as text
%        str2double(get(hObject,'String')) returns contents of elOffsetText as a double
    str = attemptStrEval(get(hObject,'String'));
    if(checkStrIsNumeric(str) && str2double(str) > -89.9 && str2double(str) < 89.9)
        set(hObject, 'UserData', str2double(str));
        set(hObject, 'String', str);
        set(handles.elOffsetSlider, 'Value', str2double(get(hObject,'String')));
        
        if(get(handles.playButton,'Value')==0)
            plotOneFrame(handles);
        end
    else
        set(hObject, 'String', get(hObject,'UserData'));
        set(handles.elOffsetSlider, 'Value', get(hObject,'UserData'));
    end
    

% --- Executes during object creation, after setting all properties.
function elOffsetText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to elOffsetText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function fileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to fileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function recordAnimationMenu_Callback(hObject, eventdata, handles)
% hObject    handle to recordAnimationMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global GLOBAL_VideoWriter GLOBAL_isRecording;

    saveFilePath = getappdata(handles.ma_MainGUI,'current_save_location');
    DefaultName = 'missionAnimation.avi';
    if(~isempty(saveFilePath))
        pathstr = fileparts(saveFilePath);
        DefaultName = [pathstr, filesep, DefaultName];
    end
    [FileName,PathName] = uiputfile('*.avi','Save Animation',DefaultName);
    
    if(FileName~=0)
        button = questdlg('Do you wish to start recording from the start of the mission or the current playback slider position?','Animation Start?','Mission Start','Playback Slider','Mission Start');
        
        warnStr = sprintf('Your animation is about to be recorded.\n\nTo ensure success, please make sure that the screensaver on your PC does not activate during recording.\n\nAdditionally, do not stop the animation until it has cycled back to the starting frame.\n\nYou may, however, manipulate any of the scene, annotation, or camera options during recording and doing so will be captured.');
        hWarn = warndlg(warnStr,'Recording Starting','modal');
        uiwait(hWarn);
        
        set(handles.playButton,'Value',0); pause(0.1);
        
        if(strcmpi(button,'Mission Start'))
            set(handles.movieFrameSlider,'Value',get(handles.movieFrameSlider,'Min')); drawnow(); pause(0.05);
        end

        GLOBAL_VideoWriter = VideoWriter([PathName, FileName]);
        GLOBAL_isRecording = true;

        set(handles.playButton,'Value',1);
        playButton_Callback(handles.playButton, [], handles);
    end




% --- Executes on slider movement.
function viewAngleSlider_Callback(hObject, eventdata, handles)
% hObject    handle to viewAngleSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    set(handles.fieldOfViewText, 'String', num2str(get(hObject,'Value')));
    fieldOfViewText_Callback(handles.fieldOfViewText,[],handles);
    
% --- Executes during object creation, after setting all properties.
function viewAngleSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to viewAngleSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function azOffsetSlider_Callback(hObject, eventdata, handles)
% hObject    handle to azOffsetSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    set(handles.azOffsetText, 'String', num2str(get(hObject,'Value')));
    azOffsetText_Callback(handles.azOffsetText,[],handles);


% --- Executes during object creation, after setting all properties.
function azOffsetSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to azOffsetSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function elOffsetSlider_Callback(hObject, eventdata, handles)
% hObject    handle to elOffsetSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    set(handles.elOffsetText, 'String', num2str(get(hObject,'Value')));
    elOffsetText_Callback(handles.elOffsetText,[],handles);

% --- Executes during object creation, after setting all properties.
function elOffsetSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to elOffsetSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in showChildBodyOrbitsCheckbox.
function showChildBodyOrbitsCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to showChildBodyOrbitsCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showChildBodyOrbitsCheckbox
    set(hObject,'UserData',get(hObject,'Value'));
    
    if(get(handles.playButton,'Value')==0)
        plotOneFrame(handles);
    end


function rngOffsetText_Callback(hObject, eventdata, handles)
% hObject    handle to rngOffsetText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of rngOffsetText as text
%        str2double(get(hObject,'String')) returns contents of rngOffsetText as a double
    str = attemptStrEval(get(hObject,'String'));
    if(checkStrIsNumeric(str) && str2double(str) >= -1.0E7 && str2double(str) <= 1.0E7)
        set(hObject, 'UserData', str2double(str));
        set(hObject, 'String', str);
        set(handles.rngOffsetSlider, 'Value', str2double(get(hObject,'String')));
        
        if(get(handles.playButton,'Value')==0)
            plotOneFrame(handles);
        end
    else
        set(hObject, 'String', get(hObject,'UserData'));
        set(handles.rngOffsetSlider, 'Value', get(hObject,'UserData'));
    end

% --- Executes during object creation, after setting all properties.
function rngOffsetText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rngOffsetText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function rngOffsetSlider_Callback(hObject, eventdata, handles)
% hObject    handle to rngOffsetSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    set(handles.rngOffsetText, 'String', num2str(get(hObject,'Value')));
    rngOffsetText_Callback(handles.rngOffsetText,[],handles);

% --- Executes during object creation, after setting all properties.
function rngOffsetSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rngOffsetSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function setCamSrcTgtComboBoxes(handles)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    
    cBoxStr = {'sc: Spacecraft'; 'cb: Central Body'};
    otherSCs = maData.spacecraft.otherSC;
    stations = maData.spacecraft.stations;
    
    for(i=1:length(otherSCs)) %#ok<*NO4LP>
        otherSC = otherSCs{i};
        cBoxStr{end+1} = sprintf('osc: %s (id: %s)', otherSC.name, fullAccNum2Str(otherSC.id)); %#ok<AGROW>
    end
    
    for(i=1:length(stations)) %#ok<*NO4LP>
        station = stations{i};
        cBoxStr{end+1} = sprintf('grd: %s (id: %s)', station.name, fullAccNum2Str(station.id)); %#ok<AGROW>
    end
    
    set(handles.cameraSrcCombo, 'String', cBoxStr);
    set(handles.cameraTgtCombo, 'String', cBoxStr);



% --- Executes on selection change in cameraSrcCombo.
function cameraSrcCombo_Callback(hObject, eventdata, handles)
% hObject    handle to cameraSrcCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns cameraSrcCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from cameraSrcCombo
    contents = cellstr(get(hObject,'String'));
    sel = strtrim(contents{get(hObject,'Value')});
    set(hObject,'UserData',sel);
    
    if(get(handles.playButton,'Value')==0)
        plotOneFrame(handles);
    end

% --- Executes during object creation, after setting all properties.
function cameraSrcCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cameraSrcCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in cameraTgtCombo.
function cameraTgtCombo_Callback(hObject, eventdata, handles)
% hObject    handle to cameraTgtCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns cameraTgtCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from cameraTgtCombo
    contents = cellstr(get(hObject,'String'));
    sel = strtrim(contents{get(hObject,'Value')});
    set(hObject,'UserData',sel);
    
    if(get(handles.playButton,'Value')==0)
        plotOneFrame(handles);
    end

% --- Executes during object creation, after setting all properties.
function cameraTgtCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cameraTgtCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function sliderUTText_Callback(hObject, eventdata, handles)
% hObject    handle to sliderUTText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sliderUTText as text
%        str2double(get(hObject,'String')) returns contents of sliderUTText as a double
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    stateLog = maData.stateLog;
    minUT = min(stateLog(:,1));
    maxUT = max(stateLog(:,1));
    
    str = attemptStrEval(get(hObject,'String'));
    if(checkStrIsNumeric(str) && str2double(str) >= minUT && str2double(str) <= maxUT)
        set(handles.movieFrameSlider,'Value',str2double(str));
        
        if(get(handles.playButton,'Value')==0)
            plotOneFrame(handles);
        end
    else
        set(hObject, 'String', fullAccNum2Str(get(handles.movieFrameSlider,'Value')));
    end

% --- Executes during object creation, after setting all properties.
function sliderUTText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderUTText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on ma_MissionAnimatorGUI or any of its controls.
function ma_MissionAnimatorGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to ma_MissionAnimatorGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'escape'
            close(handles.ma_MissionAnimatorGUI);
    end



function axesScaleFactorText_Callback(hObject, eventdata, handles)
% hObject    handle to axesScaleFactorText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of axesScaleFactorText as text
%        str2double(get(hObject,'String')) returns contents of axesScaleFactorText as a double
    str = attemptStrEval(get(hObject,'String'));
    if(checkStrIsNumeric(str) && str2double(str) >= 1 && str2double(str) <= 100)
        set(hObject, 'UserData', str2double(str));
        set(hObject, 'String', str);
        set(handles.axesScaleFactorSlider, 'Value', str2double(get(hObject,'String')));
        
        if(get(handles.playButton,'Value')==0)
            plotOneFrame(handles);
        end
    else
        set(hObject, 'String', get(hObject,'UserData'));
        set(handles.axesScaleFactorSlider, 'Value', get(hObject,'UserData'));
    end

% --- Executes during object creation, after setting all properties.
function axesScaleFactorText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axesScaleFactorText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function axesScaleFactorSlider_Callback(hObject, eventdata, handles)
% hObject    handle to axesScaleFactorSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    set(handles.axesScaleFactorText, 'String', num2str(get(hObject,'Value')));
    axesScaleFactorText_Callback(handles.axesScaleFactorText,[],handles);

% --- Executes during object creation, after setting all properties.
function axesScaleFactorSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axesScaleFactorSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
