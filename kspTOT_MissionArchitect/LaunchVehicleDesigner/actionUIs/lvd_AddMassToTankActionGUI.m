function varargout = lvd_AddMassToTankActionGUI(varargin)
% LVD_ADDMASSTOTANKACTIONGUI MATLAB code for lvd_AddMassToTankActionGUI.fig
%      LVD_ADDMASSTOTANKACTIONGUI, by itself, creates a new LVD_ADDMASSTOTANKACTIONGUI or raises the existing
%      singleton*.
%
%      H = LVD_ADDMASSTOTANKACTIONGUI returns the handle to a new LVD_ADDMASSTOTANKACTIONGUI or the handle to
%      the existing singleton*.
%
%      LVD_ADDMASSTOTANKACTIONGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_ADDMASSTOTANKACTIONGUI.M with the given input arguments.
%
%      LVD_ADDMASSTOTANKACTIONGUI('Property','Value',...) creates a new LVD_ADDMASSTOTANKACTIONGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_AddMassToTankActionGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_AddMassToTankActionGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_AddMassToTankActionGUI

% Last Modified by GUIDE v2.5 17-Dec-2018 16:42:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_AddMassToTankActionGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_AddMassToTankActionGUI_OutputFcn, ...
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


% --- Executes just before lvd_AddMassToTankActionGUI is made visible.
function lvd_AddMassToTankActionGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_AddMassToTankActionGUI (see VARARGIN)

    % Choose default command line output for lvd_AddMassToTankActionGUI
    handles.output = hObject;

    action = varargin{1};
    setappdata(hObject, 'action', action);
    
    lvdData = varargin{2};
    setappdata(hObject, 'lvdData', lvdData);
    
	populateGUI(handles, action, lvdData);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_AddMassToTankActionGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_AddMassToTankActionGUI);

function populateGUI(handles, action, lvdData)
    [tanksListStr, tanks] = lvdData.launchVehicle.getTanksListBoxStr();
    indVal = find(tanks == action.tank, 1);
    if(isempty(indVal))
        indVal = 1;
    end
    
    handles.tankCombo.String = tanksListStr;
    handles.tankCombo.Value = indVal;
    
    handles.massToAddText.String = fullAccNum2Str(action.massToAdd);
    
    optVar = action.optVar;
	if(isempty(optVar))
        optVar = AddMassToTankActionOptimVar(action);
	end
    
    handles.optCheckbox.Value = double(optVar.getUseTfForVariable());
    
    [lb, ub] = optVar.getAllBndsForVariable();
    handles.lbText.String = fullAccNum2Str(lb);
    handles.ubText.String = fullAccNum2Str(ub);
    
    optCheckbox_Callback(handles.optCheckbox, [], handles);

% --- Outputs from this function are returned to the command line.
function varargout = lvd_AddMassToTankActionGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        action = getappdata(handles.lvd_AddMassToTankActionGUI, 'action');
        lvdData = getappdata(handles.lvd_AddMassToTankActionGUI, 'lvdData');
        
        [~, tanks] = lvdData.launchVehicle.getTanksListBoxStr();
        
        action.massToAdd = str2double(handles.massToAddText.String);
        action.tank = tanks(handles.tankCombo.Value);
        
        optVar = action.optVar;
        if(not(isempty(optVar))) %need to remove existing var if it exists
            lvdData.optimizer.vars.removeVariable(optVar);
        end
                
        %Set Opt T/F
        useTf = get(handles.optCheckbox,'Value');
        
        if(isempty(optVar))
            optVar = AddMassToTankActionOptimVar(action);
        end
        
        optVar.setUseTfForVariable(useTf);
        
        %Bnds
        lb = str2double(get(handles.lbText,'String'));
        ub = str2double(get(handles.ubText,'String'));
        
        optVar.setUseTfForVariable(true(size(lb))); %need this to get the full lb/set in there
        optVar.setBndsForVariable(lb, ub);
        optVar.setUseTfForVariable(useTf);
               
        lvdData.optimizer.vars.addVariable(optVar);
        
        varargout{1} = true;
        close(handles.lvd_AddMassToTankActionGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_AddMassToTankActionGUI);
    else
        msgbox(errMsg,'Invalid Tank Inputs','error');
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    
    val = str2double(get(handles.massToAddText,'String'));
    enteredStr = get(handles.massToAddText,'String');
    numberName = 'Mass to Add';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(val, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    lwrBnd = str2double(get(handles.lbText,'String'));
    enteredStr = get(handles.lbText,'String');
    numberName = 'Mass to Add (Lower Bound)';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(lwrBnd, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    uprBnd = str2double(get(handles.ubText,'String'));
    enteredStr = get(handles.ubText,'String');
    numberName = 'Mass to Add (Upper Bound)';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(uprBnd, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        uprBnd = str2double(get(handles.ubText,'String'));
        enteredStr = get(handles.ubText,'String');
        numberName = 'Mass to Add (Upper Bound)';
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
    close(handles.lvd_AddMassToTankActionGUI);



function massToAddText_Callback(hObject, eventdata, handles)
% hObject    handle to massToAddText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of massToAddText as text
%        str2double(get(hObject,'String')) returns contents of massToAddText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function massToAddText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to massToAddText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on selection change in tankCombo.
function tankCombo_Callback(hObject, eventdata, handles)
% hObject    handle to tankCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns tankCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from tankCombo


% --- Executes during object creation, after setting all properties.
function tankCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tankCombo (see GCBO)
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


% --- Executes on key press with focus on lvd_AddMassToTankActionGUI or any of its controls.
function lvd_AddMassToTankActionGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_AddMassToTankActionGUI (see GCBO)
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
            close(handles.lvd_AddMassToTankActionGUI);
    end
