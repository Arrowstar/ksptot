function varargout = lvd_EditTankToTankConnGUI(varargin)
% LVD_EDITTANKTOTANKCONNGUI MATLAB code for lvd_EditTankToTankConnGUI.fig
%      LVD_EDITTANKTOTANKCONNGUI, by itself, creates a new LVD_EDITTANKTOTANKCONNGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITTANKTOTANKCONNGUI returns the handle to a new LVD_EDITTANKTOTANKCONNGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITTANKTOTANKCONNGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITTANKTOTANKCONNGUI.M with the given input arguments.
%
%      LVD_EDITTANKTOTANKCONNGUI('Property','Value',...) creates a new LVD_EDITTANKTOTANKCONNGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditTankToTankConnGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditTankToTankConnGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditTankToTankConnGUI

% Last Modified by GUIDE v2.5 21-Jan-2019 11:49:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditTankToTankConnGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditTankToTankConnGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditTankToTankConnGUI is made visible.
function lvd_EditTankToTankConnGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditTankToTankConnGUI (see VARARGIN)

    % Choose default command line output for lvd_EditTankToTankConnGUI
    handles.output = hObject;

    centerUIFigure(hObject);
    
    t2TConn = varargin{1};
    setappdata(hObject, 't2TConn', t2TConn);
    
	populateGUI(handles, t2TConn);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditTankToTankConnGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditTankToTankConnGUI);

function populateGUI(handles, t2TConn)
    lv = t2TConn.lvdData.launchVehicle;
    
    [tanksListStr, ~] = lv.getTanksListBoxStr();
    tanksListStr = horzcat('<External>',tanksListStr);
    
    if(not(isempty(t2TConn.srcTank)))
        indSrcTank = 1 + lv.getListBoxIndForTank(t2TConn.srcTank);
    else
        indSrcTank = 1;
    end
    
    if(not(isempty(t2TConn.tgtTank)))
        indTgtTank = 1 + lv.getListBoxIndForTank(t2TConn.tgtTank);
    else
        indTgtTank = 1;
    end
    
    set(handles.srcTankCombo,'String',tanksListStr);
    set(handles.srcTankCombo,'Value',indSrcTank);
    set(handles.tgtTankCombo,'String',tanksListStr);
    set(handles.tgtTankCombo,'Value',indTgtTank);
    set(handles.flowRateText,'String',fullAccNum2Str(t2TConn.initFlowRate));
    


% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditTankToTankConnGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        t2TConn = getappdata(hObject, 't2TConn');
        lv = t2TConn.lvdData.launchVehicle;
        
        srcTankInd = handles.srcTankCombo.Value;
        if(srcTankInd == 1)
            srcTank = LaunchVehicleTank.empty(1,0);
        else
            srcTank = lv.getTankForInd(srcTankInd-1);
        end
        
        tgtTankInd = handles.tgtTankCombo.Value;
        if(tgtTankInd == 1)
            tgtTank = LaunchVehicleTank.empty(1,0);
        else
            tgtTank = lv.getTankForInd(tgtTankInd-1);
        end
        
        t2TConn.srcTank = srcTank;
        t2TConn.tgtTank = tgtTank;
        t2TConn.initFlowRate = str2double(handles.flowRateText.String);
        
        varargout{1} = true;
        close(handles.lvd_EditTankToTankConnGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)   
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_EditTankToTankConnGUI);
    else
        msgbox(errMsg,'Invalid Inputs','error');
    end
    
    
function errMsg = validateInputs(handles)
    errMsg = {};
    
    val = str2double(get(handles.flowRateText,'String'));
    enteredStr = get(handles.flowRateText,'String');
    numberName = 'Initial Flow Rate';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(val, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    srcTankInd = handles.srcTankCombo.Value;       
    tgtTankInd = handles.tgtTankCombo.Value;
    
    if(srcTankInd == 1 && tgtTankInd == 1)
        errMsg{end+1} = 'At least the source or destination tank must be a tank on the vehicle.  It is not allowable to have both the source and destination tank be <External>.';
    elseif(srcTankInd == tgtTankInd)
        errMsg{end+1} = 'The source and destination tanks may not be the same.  They must be different.';
    end
    


% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditTankToTankConnGUI);


function srcTankCombo_Callback(hObject, eventdata, handles)
% hObject    handle to srcTankCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of srcTankCombo as text
%        str2double(get(hObject,'String')) returns contents of srcTankCombo as a double


% --- Executes during object creation, after setting all properties.
function srcTankCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to srcTankCombo see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in tgtTankCombo.
function tgtTankCombo_Callback(hObject, eventdata, handles)
% hObject    handle to tgtTankCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns tgtTankCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from tgtTankCombo


% --- Executes during object creation, after setting all properties.
function tgtTankCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tgtTankCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on lvd_EditTankToTankConnGUI or any of its controls.
function lvd_EditTankToTankConnGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditTankToTankConnGUI (see GCBO)
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
            close(handles.lvd_EditTankToTankConnGUI);
    end



function flowRateText_Callback(hObject, eventdata, handles)
% hObject    handle to flowRateText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of flowRateText as text
%        str2double(get(hObject,'String')) returns contents of flowRateText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function flowRateText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to flowRateText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
