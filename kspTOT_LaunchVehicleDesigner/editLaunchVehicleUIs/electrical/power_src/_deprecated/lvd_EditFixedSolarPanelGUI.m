function varargout = lvd_EditFixedSolarPanelGUI(varargin)
% LVD_EDITFIXEDSOLARPANELGUI MATLAB code for lvd_EditFixedSolarPanelGUI.fig
%      LVD_EDITFIXEDSOLARPANELGUI, by itself, creates a new LVD_EDITFIXEDSOLARPANELGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITFIXEDSOLARPANELGUI returns the handle to a new LVD_EDITFIXEDSOLARPANELGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITFIXEDSOLARPANELGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITFIXEDSOLARPANELGUI.M with the given input arguments.
%
%      LVD_EDITFIXEDSOLARPANELGUI('Property','Value',...) creates a new LVD_EDITFIXEDSOLARPANELGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditFixedSolarPanelGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditFixedSolarPanelGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditFixedSolarPanelGUI

% Last Modified by GUIDE v2.5 01-Aug-2020 18:17:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditFixedSolarPanelGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditFixedSolarPanelGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditFixedSolarPanelGUI is made visible.
function lvd_EditFixedSolarPanelGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditFixedSolarPanelGUI (see VARARGIN)

    % Choose default command line output for lvd_EditFixedSolarPanelGUI
    handles.output = hObject;
    
    centerUIFigure(hObject);

    fixedSolarPanel = varargin{1};
    setappdata(hObject, 'fixedSolarPanel', fixedSolarPanel);
    
	populateGUI(handles, fixedSolarPanel);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditFixedSolarPanelGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditFixedSolarPanelGUI);

function populateGUI(handles, fixedSolarPanel)
    lv = fixedSolarPanel.getAttachedStage().launchVehicle;
    [stagesListboxStr, ~] = lv.getStagesListBoxStr();
    ind = lv.getIndOfStage(fixedSolarPanel.stage);

    if(isempty(ind))
        ind = 1;
    end
    
    set(handles.solarPanelNameText,'String',fixedSolarPanel.getName());
    
    set(handles.stageCombo,'String',stagesListboxStr);
    set(handles.stageCombo,'Value',ind);
    
    set(handles.refChargeRateText,'String',fullAccNum2Str(fixedSolarPanel.refChargeRate));
    set(handles.refDistText,'String',fullAccNum2Str(fixedSolarPanel.refChargeRateDist));
    
    set(handles.panelXText,'String',fullAccNum2Str(fixedSolarPanel.bodyFrameNormVect(1)));
    set(handles.panelYText,'String',fullAccNum2Str(fixedSolarPanel.bodyFrameNormVect(2)));
    set(handles.panelZText,'String',fullAccNum2Str(fixedSolarPanel.bodyFrameNormVect(3)));


% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditFixedSolarPanelGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        fixedSolarPanel = getappdata(hObject, 'fixedSolarPanel');
        lv = fixedSolarPanel.getAttachedStage().launchVehicle;
                
%         fixedSolarPanel.getAttachedStage().removePwrSrc(fixedSolarPanel);
        
        stage = lv.getStageForInd(handles.stageCombo.Value);
        
        name = handles.solarPanelNameText.String;
        refChargeRate = str2double(handles.refChargeRateText.String);
        refDist = str2double(handles.refDistText.String);
        
        xVect = str2double(handles.panelXText.String);
        yVect = str2double(handles.panelYText.String);
        zVect = str2double(handles.panelZText.String);
        
        fixedSolarPanel.name = name;
        fixedSolarPanel.stage = stage;
        fixedSolarPanel.refChargeRate = refChargeRate;
        fixedSolarPanel.refChargeRateDist = refDist;
        fixedSolarPanel.bodyFrameNormVect = normVector([xVect; yVect; zVect]);
        
%         fixedSolarPanel.getAttachedStage().addPwrSrc(fixedSolarPanel);
        lv.movePwrSrcToStage(fixedSolarPanel, stage);
                
        varargout{1} = true;
        close(handles.lvd_EditFixedSolarPanelGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_EditFixedSolarPanelGUI);
    else
        msgbox(errMsg,'Invalid Solar Panel Inputs','error');
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    
    chargeRate = str2double(get(handles.refChargeRateText,'String'));
    enteredStr = get(handles.refChargeRateText,'String');
    numberName = 'Ref. Charge Rate';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(chargeRate, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    dist = str2double(get(handles.refDistText,'String'));
    enteredStr = get(handles.refDistText,'String');
    numberName = 'Ref. Distance';
    lb = 0.001;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(dist, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    xVect = str2double(get(handles.panelXText,'String'));
    enteredStr = get(handles.panelXText,'String');
    numberName = 'Panel Normal Vector X';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(xVect, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    yVect = str2double(get(handles.panelYText,'String'));
    enteredStr = get(handles.panelYText,'String');
    numberName = 'Panel Normal Vector Y';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(yVect, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    zVect = str2double(get(handles.panelZText,'String'));
    enteredStr = get(handles.panelZText,'String');
    numberName = 'Panel Normal Vector Z';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(zVect, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        if(norm([xVect; yVect; zVect]) <= 0)
            errMsg{end+1} = 'Magnitude of the solar panel normal vector must be greater than 0.0.';
        end
    end
    
% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditFixedSolarPanelGUI);


function solarPanelNameText_Callback(hObject, eventdata, handles)
% hObject    handle to solarPanelNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of solarPanelNameText as text
%        str2double(get(hObject,'String')) returns contents of solarPanelNameText as a double


% --- Executes during object creation, after setting all properties.
function solarPanelNameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to solarPanelNameText see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function refChargeRateText_Callback(hObject, eventdata, handles)
% hObject    handle to refChargeRateText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of refChargeRateText as text
%        str2double(get(hObject,'String')) returns contents of refChargeRateText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function refChargeRateText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to refChargeRateText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on selection change in stageCombo.
function stageCombo_Callback(hObject, eventdata, handles)
% hObject    handle to stageCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns stageCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from stageCombo


% --- Executes during object creation, after setting all properties.
function stageCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stageCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on key press with focus on lvd_EditFixedSolarPanelGUI or any of its controls.
function lvd_EditFixedSolarPanelGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditFixedSolarPanelGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            saveAndCloseButton_Callback(handles.saveAndCloseButton, [], handles);
        case 'enter'
            saveAndCloseButton_Callback(handles.saveAndCloseButton, [], handles);
        case 'escape'
            close(handles.lvd_EditFixedSolarPanelGUI);
    end



function refDistText_Callback(hObject, eventdata, handles)
% hObject    handle to refDistText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of refDistText as text
%        str2double(get(hObject,'String')) returns contents of refDistText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function refDistText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to refDistText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function panelXText_Callback(hObject, eventdata, handles)
% hObject    handle to panelXText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of panelXText as text
%        str2double(get(hObject,'String')) returns contents of panelXText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function panelXText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to panelXText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function panelYText_Callback(hObject, eventdata, handles)
% hObject    handle to panelYText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of panelYText as text
%        str2double(get(hObject,'String')) returns contents of panelYText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function panelYText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to panelYText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function panelZText_Callback(hObject, eventdata, handles)
% hObject    handle to panelZText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of panelZText as text
%        str2double(get(hObject,'String')) returns contents of panelZText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function panelZText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to panelZText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
