function varargout = lvd_EditTankGUI(varargin)
% LVD_EDITTANKGUI MATLAB code for lvd_EditTankGUI.fig
%      LVD_EDITTANKGUI, by itself, creates a new LVD_EDITTANKGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITTANKGUI returns the handle to a new LVD_EDITTANKGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITTANKGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITTANKGUI.M with the given input arguments.
%
%      LVD_EDITTANKGUI('Property','Value',...) creates a new LVD_EDITTANKGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditTankGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditTankGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditTankGUI

% Last Modified by GUIDE v2.5 04-Oct-2018 19:57:26

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditTankGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditTankGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditTankGUI is made visible.
function lvd_EditTankGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditTankGUI (see VARARGIN)

    % Choose default command line output for lvd_EditTankGUI
    handles.output = hObject;

    tank = varargin{1};
    setappdata(hObject, 'tank', tank);
    
	populateGUI(handles, tank);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditTankGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditTankGUI);

function populateGUI(handles, tank)
    lv = tank.stage.launchVehicle;
    [stagesListboxStr, ~] = lv.getStagesListBoxStr();
    ind = lv.getIndOfStage(tank.stage);

    if(isempty(ind))
        ind = 1;
    end
    
    set(handles.tankNameText,'String',tank.name);
    set(handles.stageCombo,'String',stagesListboxStr);
    set(handles.stageCombo,'Value',ind);
    set(handles.initPropMassText,'String',fullAccNum2Str(tank.getInitialMass()));
    
    optVar = tank.getExistingOptVar();
	if(isempty(optVar))
        optVar = tank.getNewOptVar();
	end
    
    handles.optCheckbox.Value = double(optVar.getUseTfForVariable());
    
    [lb, ub] = optVar.getBndsForVariable();
    handles.lbText.String = fullAccNum2Str(lb);
    handles.ubText.String = fullAccNum2Str(ub);
    
    optCheckbox_Callback(handles.optCheckbox, [], handles);

% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditTankGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        tank = getappdata(hObject, 'tank');
        lv = tank.stage.launchVehicle;
        
        stage = lv.getStageForInd(handles.stageCombo.Value);
        
        name = handles.tankNameText.String;
        initialMass = str2double(handles.initPropMassText.String);
        
        tank.name = name;
        tank.stage = stage;
        tank.initialMass = initialMass;
        
        optVar = tank.getExistingOptVar();
        if(not(isempty(optVar)))
            tank.stage.launchVehicle.lvdData.optimizer.vars.removeVariable(optVar);
        end
        optVar = tank.getNewOptVar();
        tank.stage.launchVehicle.lvdData.optimizer.vars.addVariable(optVar);
        
        optInitMass = logical(handles.optCheckbox.Value);
        lbInitMass = str2double(handles.lbText.String);
        ubInitMass = str2double(handles.ubText.String);
        
        optVar.setUseTfForVariable(optInitMass);
        optVar.setBndsForVariable(lbInitMass,ubInitMass);
        
        varargout{1} = true;
        close(handles.lvd_EditTankGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_EditTankGUI);
    else
        msgbox(errMsg,'Invalid Tank Inputs','error');
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    
    val = str2double(get(handles.initPropMassText,'String'));
    enteredStr = get(handles.initPropMassText,'String');
    numberName = 'Initial Propellant Mass';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(val, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    lwrBnd = str2double(get(handles.lbText,'String'));
    enteredStr = get(handles.lbText,'String');
    numberName = 'Initial Propellant Mass (Lower Bound)';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(lwrBnd, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    uprBnd = str2double(get(handles.ubText,'String'));
    enteredStr = get(handles.ubText,'String');
    numberName = 'Initial Propellant Mass (Upper Bound)';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(uprBnd, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        uprBnd = str2double(get(handles.ubText,'String'));
        enteredStr = get(handles.ubText,'String');
        numberName = 'Initial Propellant Mass (Upper Bound)';
        lb = lwrBnd;
        ub = Inf;
        isInt = false;
        errMsg = validateNumber(uprBnd, numberName, lb, ub, isInt, errMsg, enteredStr);
    end
    

    
% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditTankGUI);


function tankNameText_Callback(hObject, eventdata, handles)
% hObject    handle to tankNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tankNameText as text
%        str2double(get(hObject,'String')) returns contents of tankNameText as a double


% --- Executes during object creation, after setting all properties.
function tankNameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tankNameText see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function initPropMassText_Callback(hObject, eventdata, handles)
% hObject    handle to initPropMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of initPropMassText as text
%        str2double(get(hObject,'String')) returns contents of initPropMassText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function initPropMassText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to initPropMassText (see GCBO)
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


% --- Executes on button press in optCheckbox.
function optCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to optCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of optCheckbox
    if(get(hObject,'Value'))
        handles.lbText.Enable = 'on';
        handles.ubText.Enable = 'on';
    else
        handles.lbText.Enable = 'off';
        handles.ubText.Enable = 'off';
    end


function lbText_Callback(hObject, eventdata, handles)
% hObject    handle to lbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lbText as text
%        str2double(get(hObject,'String')) returns contents of lbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function lbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ubText_Callback(hObject, eventdata, handles)
% hObject    handle to ubText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ubText as text
%        str2double(get(hObject,'String')) returns contents of ubText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function ubText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ubText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
