function varargout = lvd_EditStageGUI(varargin)
% LVD_EDITSTAGEGUI MATLAB code for lvd_EditStageGUI.fig
%      LVD_EDITSTAGEGUI, by itself, creates a new LVD_EDITSTAGEGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITSTAGEGUI returns the handle to a new LVD_EDITSTAGEGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITSTAGEGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITSTAGEGUI.M with the given input arguments.
%
%      LVD_EDITSTAGEGUI('Property','Value',...) creates a new LVD_EDITSTAGEGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditStageGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditStageGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditStageGUI

% Last Modified by GUIDE v2.5 03-Dec-2018 17:15:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditStageGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditStageGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditStageGUI is made visible.
function lvd_EditStageGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditStageGUI (see VARARGIN)

    % Choose default command line output for lvd_EditStageGUI
    handles.output = hObject;

    stage = varargin{1};
    setappdata(hObject, 'stage', stage);
    
	populateGUI(handles, stage);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditStageGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditStageGUI);

function populateGUI(handles, stage)
    set(handles.stageNameText,'String',stage.name);
    set(handles.dryMassText,'String',fullAccNum2Str(stage.getStageDryMass()));
    
    optVar = stage.getExistingOptVar();
	if(isempty(optVar))
        optVar = stage.getNewOptVar();
	end
    
    handles.optCheckbox.Value = double(optVar.getUseTfForVariable());
    
    [lb, ub] = optVar.getAllBndsForVariable();
    handles.lbText.String = fullAccNum2Str(lb);
    handles.ubText.String = fullAccNum2Str(ub);
    
    optCheckbox_Callback(handles.optCheckbox, [], handles);
    
    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditStageGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        stage = getappdata(hObject, 'stage');
        
        name = handles.stageNameText.String;
        dryMass = str2double(handles.dryMassText.String);
        
        stage.name = name;
        stage.dryMass = dryMass;
        
        optVar = stage.getExistingOptVar();
        if(not(isempty(optVar)))
            stage.launchVehicle.lvdData.optimizer.vars.removeVariable(optVar);
        end
        optVar = stage.getNewOptVar();
        
        optDryMass = logical(handles.optCheckbox.Value);
        lbDryMass = str2double(handles.lbText.String);
        ubDryMass = str2double(handles.ubText.String);
        
        optVar.setUseTfForVariable(optDryMass);
        optVar.setBndsForVariable(lbDryMass,ubDryMass);
        stage.launchVehicle.lvdData.optimizer.vars.addVariable(optVar);
        
        varargout{1} = true;
        close(handles.lvd_EditStageGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_EditStageGUI);
    else
        msgbox(errMsg,'Invalid Stage Inputs','error');
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    
    dryMass = str2double(get(handles.dryMassText,'String'));
    enteredStr = get(handles.dryMassText,'String');
    numberName = 'Dry Mass';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(dryMass, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    lwrBnd = str2double(get(handles.lbText,'String'));
    enteredStr = get(handles.lbText,'String');
    numberName = 'Dry Mass (Lower Bound)';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(lwrBnd, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    uprBnd = str2double(get(handles.ubText,'String'));
    enteredStr = get(handles.ubText,'String');
    numberName = 'Dry Mass (Upper Bound)';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(uprBnd, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        uprBnd = str2double(get(handles.ubText,'String'));
        enteredStr = get(handles.ubText,'String');
        numberName = 'Dry Mass (Upper Bound)';
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
    close(handles.lvd_EditStageGUI);


function stageNameText_Callback(hObject, eventdata, handles)
% hObject    handle to stageNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of stageNameText as text
%        str2double(get(hObject,'String')) returns contents of stageNameText as a double


% --- Executes during object creation, after setting all properties.
function stageNameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stageNameText see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dryMassText_Callback(hObject, eventdata, handles)
% hObject    handle to dryMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dryMassText as text
%        str2double(get(hObject,'String')) returns contents of dryMassText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function dryMassText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dryMassText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
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


% --- Executes on key press with focus on lvd_EditStageGUI or any of its controls.
function lvd_EditStageGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditStageGUI (see GCBO)
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
            close(handles.lvd_EditStageGUI);
    end
