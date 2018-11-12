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

% Last Modified by GUIDE v2.5 22-Sep-2018 19:58:40

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
    
    %Angle 1
    angle1Const = str2double(get(handles.throttleConstTermText,'String'));
    enteredStr = get(handles.throttleConstTermText,'String');
    numberName = sprintf('Throttle Constant Term');
    lb = 0;
    ub = 100;
    isInt = false;
    errMsg = validateNumber(angle1Const, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle1Linear = str2double(get(handles.throttleLinTermText,'String'));
    enteredStr = get(handles.throttleLinTermText,'String');
    numberName = sprintf('Throttle Linear Term');
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1Linear, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle1Accel = str2double(get(handles.throttleAccelTermText,'String'));
    enteredStr = get(handles.throttleAccelTermText,'String');
    numberName = sprintf('Throttle Acceleration Term');
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1Accel, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    
    %%%%%Bounds
    %Throttle Const
    angle1ConstLB = str2double(get(handles.throttleConstLbText,'String'));
    enteredStr = get(handles.throttleConstLbText,'String');
    numberName = sprintf('Throttle Constant Term Lower Bound');
    lb = 0;
    ub = 100;
    isInt = false;
    errMsg = validateNumber(angle1ConstLB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle1ConstUB = str2double(get(handles.throttleConstUbText,'String'));
    enteredStr = get(handles.throttleConstUbText,'String');
    numberName = sprintf('Throttle Constant Term Upper Bound');
    lb = angle1ConstLB;
    ub = 100;
    isInt = false;
    errMsg = validateNumber(angle1ConstUB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Throttle Linear
    angle1LinearLB = str2double(get(handles.throttleLinLbText,'String'));
    enteredStr = get(handles.throttleLinLbText,'String');
    numberName = sprintf('Throttle Linear Term Lower Bound');
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1LinearLB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle1LinearUB = str2double(get(handles.throttleLinUbText,'String'));
    enteredStr = get(handles.throttleLinUbText,'String');
    numberName = sprintf('Throttle Linear Term Upper Bound');
    lb = angle1LinearLB;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1LinearUB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Throttle Accel
    angle1AccelLB = str2double(get(handles.throttleAccelLbText,'String'));
    enteredStr = get(handles.throttleAccelLbText,'String');
    numberName = sprintf('Throttle Acceleration Term Lower Bound');
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1AccelLB, numberName, lb, ub, isInt, errMsg, enteredStr);

    angle1AccelUB = str2double(get(handles.throttleAccelUbText,'String'));
    enteredStr = get(handles.throttleAccelUbText,'String');
    numberName = sprintf('Throttle Acceleration Term Upper Bound');
    lb = angle1AccelLB;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1AccelUB, numberName, lb, ub, isInt, errMsg, enteredStr);   
    

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
    if(get(hObject,'Value')==1)
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
