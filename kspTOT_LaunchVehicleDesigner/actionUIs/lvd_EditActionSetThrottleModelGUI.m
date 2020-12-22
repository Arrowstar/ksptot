function varargout = lvd_EditActionSetThrottleModelGUI(varargin)
% LVD_EDITACTIONSETTHROTTLEMODELGUI MATLAB code for lvd_EditActionSetThrottleModelGUI.fig
%      LVD_EDITACTIONSETTHROTTLEMODELGUI, by itself, creates a new LVD_EDITACTIONSETTHROTTLEMODELGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITACTIONSETTHROTTLEMODELGUI returns the handle to a new LVD_EDITACTIONSETTHROTTLEMODELGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITACTIONSETTHROTTLEMODELGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITACTIONSETTHROTTLEMODELGUI.M with the given input arguments.
%
%      LVD_EDITACTIONSETTHROTTLEMODELGUI('Property','Value',...) creates a new LVD_EDITACTIONSETTHROTTLEMODELGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditActionSetThrottleModelGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditActionSetThrottleModelGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditActionSetThrottleModelGUI

% Last Modified by GUIDE v2.5 15-Jul-2020 16:44:16

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditActionSetThrottleModelGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditActionSetThrottleModelGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditActionSetThrottleModelGUI is made visible.
function lvd_EditActionSetThrottleModelGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditActionSetThrottleModelGUI (see VARARGIN)

    % Choose default command line output for lvd_EditActionSetThrottleModelGUI
    handles.output = hObject;

    action = varargin{1};
    setappdata(hObject,'action',action);
    
    lv = varargin{2};
    setappdata(hObject,'lv',lv);
    
    populateGUI(handles, action);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditActionSetThrottleModelGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditActionSetThrottleModelGUI);


function populateGUI(handles, action)
    throttleModel = action.throttleModel;
    
    polyModel = throttleModel.throttleModel;
    set(handles.throttleConstTermText,'String',fullAccNum2Str(100*polyModel.constTerm));
    set(handles.throttleLinTermText,'String',fullAccNum2Str(100*polyModel.linearTerm));
    set(handles.throttleAccelTermText,'String',fullAccNum2Str(100*polyModel.accelTerm));
    
    optVar = throttleModel.getExistingOptVar();
    if(isempty(optVar))
        useTf = false([1,3]);
        lb = zeros(size(useTf));
        ub = zeros(size(useTf));
    else
        useTf = optVar.getUseTfForVariable();
        optVar.setUseTfForVariable(true(size(useTf)));
        [lb, ub] = optVar.getBndsForVariable();
        optVar.setUseTfForVariable(useTf);
    end

    set(handles.throttleConstOptCheckbox,'Value',(useTf(1)));
    set(handles.throttleLinOptCheckbox,'Value',(useTf(2)));
    set(handles.throttleAccelOptCheckbox,'Value',(useTf(3)));
    
    throttleConstOptCheckbox_Callback(handles.throttleConstOptCheckbox, [], handles);
    throttleLinOptCheckbox_Callback(handles.throttleLinOptCheckbox, [], handles);    
    throttleAccelOptCheckbox_Callback(handles.throttleAccelOptCheckbox, [], handles);
    
    %LB
    set(handles.throttleConstLbText,'String',fullAccNum2Str(100*lb(1)));
    set(handles.throttleLinLbText,'String',fullAccNum2Str(100*lb(2)));
    set(handles.throttleAccelLbText,'String',fullAccNum2Str(100*lb(3)));
    
    %UB
    set(handles.throttleConstUbText,'String',fullAccNum2Str(100*ub(1)));
    set(handles.throttleLinUbText,'String',fullAccNum2Str(100*ub(2)));
    set(handles.throttleAccelUbText,'String',fullAccNum2Str(100*ub(3)));
    
    handles.throttleContCheckbox.Value = double(throttleModel.throttleContinuity);
    throttleContCheckbox_Callback(handles.throttleContCheckbox, [], handles);
    
    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditActionSetThrottleModelGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else  
        lv = getappdata(hObject,'lv');
        lvdData = lv.lvdData;
        
        action = getappdata(hObject,'action');
        throttleModel = action.throttleModel;
        
        optVar = throttleModel.getExistingOptVar();
        if(not(isempty(optVar))) %need to remove existing var if it exists
            lvdData.optimizer.vars.removeVariable(optVar);
        end
        
        %Set Throttle Terms
        throttleConst = str2double(get(handles.throttleConstTermText,'String'))/100;
        throttleLinear = str2double(get(handles.throttleLinTermText,'String'))/100;
        throttleAccel = str2double(get(handles.throttleAccelTermText,'String'))/100;
        
        throttleModel.setPolyTerms(throttleConst, throttleLinear, throttleAccel);
        throttleModel.throttleContinuity = logical(handles.throttleContCheckbox.Value);
        
        %Set Opt T/F
        useTf(1) = get(handles.throttleConstOptCheckbox,'Value');
        useTf(2) = get(handles.throttleLinOptCheckbox,'Value');
        useTf(3) = get(handles.throttleAccelOptCheckbox,'Value');
        
        if(isempty(optVar))
            optVar = throttleModel.getNewOptVar();
        end
        
        optVar.setUseTfForVariable(useTf);
        
        %UB
        lb(1) = str2double(get(handles.throttleConstLbText,'String'))/100;
        lb(2) = str2double(get(handles.throttleLinLbText,'String'))/100;
        lb(3) = str2double(get(handles.throttleAccelLbText,'String'))/100;
        
        ub(1) = str2double(get(handles.throttleConstUbText,'String'))/100;
        ub(2) = str2double(get(handles.throttleLinUbText,'String'))/100;
        ub(3) = str2double(get(handles.throttleAccelUbText,'String'))/100;
        
        optVar.setUseTfForVariable(true(size(lb))); %need this to get the full lb/set in there
        optVar.setBndsForVariable(lb, ub);
        optVar.setUseTfForVariable(useTf);
               
        lvdData.optimizer.vars.addVariable(optVar);
        
        varargout{1} = true;
        close(handles.lvd_EditActionSetThrottleModelGUI);
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    
    %Throttle
    throttleConst = str2double(get(handles.throttleConstTermText,'String'));
    enteredStr = get(handles.throttleConstTermText,'String');
    numberName = sprintf('Throttle Constant Term');
    lb = 0;
    ub = 100;
    isInt = false;
    errMsg = validateNumber(throttleConst, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    throttleLinear = str2double(get(handles.throttleLinTermText,'String'));
    enteredStr = get(handles.throttleLinTermText,'String');
    numberName = sprintf('Throttle Linear Term');
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(throttleLinear, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    throttleAccel = str2double(get(handles.throttleAccelTermText,'String'));
    enteredStr = get(handles.throttleAccelTermText,'String');
    numberName = sprintf('Throttle Acceleration Term');
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(throttleAccel, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    
    %%%%%Bounds
    %Throttle Const
    if(handles.throttleConstOptCheckbox.Value == 1)
        throttleConstLB = str2double(get(handles.throttleConstLbText,'String'));
        enteredStr = get(handles.throttleConstLbText,'String');
        numberName = sprintf('Throttle Constant Term Lower Bound');
        lb = 0;
        ub = 100;
        isInt = false;
        errMsg = validateNumber(throttleConstLB, numberName, lb, ub, isInt, errMsg, enteredStr);

        throttleConstUB = str2double(get(handles.throttleConstUbText,'String'));
        enteredStr = get(handles.throttleConstUbText,'String');
        numberName = sprintf('Throttle Constant Term Upper Bound');
        lb = throttleConstLB;
        ub = 100;
        isInt = false;
        errMsg = validateNumber(throttleConstUB, numberName, lb, ub, isInt, errMsg, enteredStr);
    end
    
    %Throttle Linear
    if(handles.throttleLinOptCheckbox.Value == 1)
        throttleLinearLB = str2double(get(handles.throttleLinLbText,'String'));
        enteredStr = get(handles.throttleLinLbText,'String');
        numberName = sprintf('Throttle Linear Term Lower Bound');
        lb = -Inf;
        ub = Inf;
        isInt = false;
        errMsg = validateNumber(throttleLinearLB, numberName, lb, ub, isInt, errMsg, enteredStr);

        throttleLinearUB = str2double(get(handles.throttleLinUbText,'String'));
        enteredStr = get(handles.throttleLinUbText,'String');
        numberName = sprintf('Throttle Linear Term Upper Bound');
        lb = throttleLinearLB;
        ub = Inf;
        isInt = false;
        errMsg = validateNumber(throttleLinearUB, numberName, lb, ub, isInt, errMsg, enteredStr);
    end
    
    %Throttle Accel
    if(handles.throttleAccelOptCheckbox.Value == 1)
        throttleAccelLB = str2double(get(handles.throttleAccelLbText,'String'));
        enteredStr = get(handles.throttleAccelLbText,'String');
        numberName = sprintf('Throttle Acceleration Term Lower Bound');
        lb = -Inf;
        ub = Inf;
        isInt = false;
        errMsg = validateNumber(throttleAccelLB, numberName, lb, ub, isInt, errMsg, enteredStr);

        throttleAccelUB = str2double(get(handles.throttleAccelUbText,'String'));
        enteredStr = get(handles.throttleAccelUbText,'String');
        numberName = sprintf('Throttle Acceleration Term Upper Bound');
        lb = throttleAccelLB;
        ub = Inf;
        isInt = false;
        errMsg = validateNumber(throttleAccelUB, numberName, lb, ub, isInt, errMsg, enteredStr);   
    end
    
    if(isempty(errMsg))
        if(handles.throttleConstOptCheckbox.Value == 1 && (throttleConst < throttleConstLB || throttleConst > throttleConstUB))
            errMsg{end+1} = 'Throttle constant term must be between the upper and lower optimization bounds.';
        end
        
        if(handles.throttleLinOptCheckbox.Value == 1 && (throttleLinear < throttleLinearLB || throttleLinear > throttleLinearUB))
            errMsg{end+1} = 'Throttle linear term must be between the upper and lower optimization bounds.';
        end
        
        if(handles.throttleAccelOptCheckbox.Value == 1 && (throttleAccel < throttleAccelLB || throttleAccel > throttleAccelUB))
            errMsg{end+1} = 'Throttle acceleration term must be between the upper and lower optimization bounds.';
        end
    end
    

function throttleConstTermText_Callback(hObject, eventdata, handles)
% hObject    handle to throttleConstTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of throttleConstTermText as text
%        str2double(get(hObject,'String')) returns contents of throttleConstTermText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function throttleConstTermText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to throttleConstTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function throttleLinTermText_Callback(hObject, eventdata, handles)
% hObject    handle to throttleLinTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of throttleLinTermText as text
%        str2double(get(hObject,'String')) returns contents of throttleLinTermText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function throttleLinTermText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to throttleLinTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function throttleAccelTermText_Callback(hObject, eventdata, handles)
% hObject    handle to throttleAccelTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of throttleAccelTermText as text
%        str2double(get(hObject,'String')) returns contents of throttleAccelTermText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function throttleAccelTermText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to throttleAccelTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in throttleConstOptCheckbox.
function throttleConstOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to throttleConstOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of throttleConstOptCheckbox
    if(get(hObject,'Value')==1 && handles.throttleContCheckbox.Value == 0)
        set(handles.throttleConstLbText,'Enable','on');
        set(handles.throttleConstUbText,'Enable','on');
    else
        set(handles.throttleConstLbText,'Enable','off');
        set(handles.throttleConstUbText,'Enable','off');
    end


function throttleConstLbText_Callback(hObject, eventdata, handles)
% hObject    handle to throttleConstLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of throttleConstLbText as text
%        str2double(get(hObject,'String')) returns contents of throttleConstLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function throttleConstLbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to throttleConstLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function throttleConstUbText_Callback(hObject, eventdata, handles)
% hObject    handle to throttleConstUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of throttleConstUbText as text
%        str2double(get(hObject,'String')) returns contents of throttleConstUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function throttleConstUbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to throttleConstUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in throttleLinOptCheckbox.
function throttleLinOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to throttleLinOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of throttleLinOptCheckbox
    if(get(hObject,'Value')==1)
        set(handles.throttleLinLbText,'Enable','on');
        set(handles.throttleLinUbText,'Enable','on');
    else
        set(handles.throttleLinLbText,'Enable','off');
        set(handles.throttleLinUbText,'Enable','off');
    end


function throttleLinLbText_Callback(hObject, eventdata, handles)
% hObject    handle to throttleLinLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of throttleLinLbText as text
%        str2double(get(hObject,'String')) returns contents of throttleLinLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function throttleLinLbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to throttleLinLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function throttleLinUbText_Callback(hObject, eventdata, handles)
% hObject    handle to throttleLinUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of throttleLinUbText as text
%        str2double(get(hObject,'String')) returns contents of throttleLinUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function throttleLinUbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to throttleLinUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in throttleAccelOptCheckbox.
function throttleAccelOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to throttleAccelOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of throttleAccelOptCheckbox
    if(get(hObject,'Value')==1)
        set(handles.throttleAccelLbText,'Enable','on');
        set(handles.throttleAccelUbText,'Enable','on');
    else
        set(handles.throttleAccelLbText,'Enable','off');
        set(handles.throttleAccelUbText,'Enable','off');
    end


function throttleAccelLbText_Callback(hObject, eventdata, handles)
% hObject    handle to throttleAccelLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of throttleAccelLbText as text
%        str2double(get(hObject,'String')) returns contents of throttleAccelLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function throttleAccelLbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to throttleAccelLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function throttleAccelUbText_Callback(hObject, eventdata, handles)
% hObject    handle to throttleAccelUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of throttleAccelUbText as text
%        str2double(get(hObject,'String')) returns contents of throttleAccelUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function throttleAccelUbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to throttleAccelUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);

    if(isempty(errMsg))
        uiresume(handles.lvd_EditActionSetThrottleModelGUI);
    else
        msgbox(errMsg,'Errors were found while editing the throttle model.','error');
    end
    

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditActionSetThrottleModelGUI);


% --- Executes on key press with focus on lvd_EditActionSetThrottleModelGUI or any of its controls.
function lvd_EditActionSetThrottleModelGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditActionSetThrottleModelGUI (see GCBO)
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
            close(handles.lvd_EditActionSetThrottleModelGUI);
    end


% --- Executes on button press in throttleContCheckbox.
function throttleContCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to throttleContCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of throttleContCheckbox
    if(hObject.Value)
        handles.throttleConstTermText.Enable = 'off';
        handles.throttleConstOptCheckbox.Enable = 'off';
        handles.throttleConstLbText.Enable = 'off';
        handles.throttleConstUbText.Enable = 'off';
        
        handles.throttleConstOptCheckbox.Value = 0;
    else
        handles.throttleConstTermText.Enable = 'on';
        handles.throttleConstOptCheckbox.Enable = 'on';
        
        throttleConstOptCheckbox_Callback(handles.throttleConstOptCheckbox, [], handles);
    end
