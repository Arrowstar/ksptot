function varargout = lvd_EditActionSetQuatInterpSteeringModelGUI(varargin)
% LVD_EDITACTIONSETQUATINTERPSTEERINGMODELGUI MATLAB code for lvd_EditActionSetQuatInterpSteeringModelGUI.fig
%      LVD_EDITACTIONSETQUATINTERPSTEERINGMODELGUI, by itself, creates a new LVD_EDITACTIONSETQUATINTERPSTEERINGMODELGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITACTIONSETQUATINTERPSTEERINGMODELGUI returns the handle to a new LVD_EDITACTIONSETQUATINTERPSTEERINGMODELGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITACTIONSETQUATINTERPSTEERINGMODELGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITACTIONSETQUATINTERPSTEERINGMODELGUI.M with the given input arguments.
%
%      LVD_EDITACTIONSETQUATINTERPSTEERINGMODELGUI('Property','Value',...) creates a new LVD_EDITACTIONSETQUATINTERPSTEERINGMODELGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditActionSetQuatInterpSteeringModelGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditActionSetQuatInterpSteeringModelGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditActionSetQuatInterpSteeringModelGUI

% Last Modified by GUIDE v2.5 10-Aug-2020 10:03:49

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditActionSetQuatInterpSteeringModelGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditActionSetQuatInterpSteeringModelGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditActionSetQuatInterpSteeringModelGUI is made visible.
function lvd_EditActionSetQuatInterpSteeringModelGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditActionSetQuatInterpSteeringModelGUI (see VARARGIN)

    % Choose default command line output for lvd_EditActionSetQuatInterpSteeringModelGUI
    handles.output = hObject;

    action = varargin{1};
    setappdata(hObject,'action',action);
    
    lv = varargin{2};
    setappdata(hObject,'lv',lv);
    
    populateGUI(handles, action, lv);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditActionSetQuatInterpSteeringModelGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditActionSetQuatInterpSteeringModelGUI);


function populateGUI(handles, action, lv)
    steeringModel = action.steeringModel;
    
    handles.baseFrameCombo.String = ReferenceFrameEnum.getListBoxStr();

    if(steeringModel.usesRefFrame())
        handles.baseFrameCombo.Enable = 'on';
        baseFrame = steeringModel.getRefFrame();
        
        if(isempty(baseFrame))
            baseFrame = lv.lvdData.getDefaultInitialBodyInfo(lv.lvdData.celBodyData).getBodyCenteredInertialFrame();
            steeringModel.setRefFrame(baseFrame);
        end
    else
        handles.baseFrameCombo.Enable = 'off';
        baseFrame = lv.lvdData.getDefaultInitialBodyInfo(lv.lvdData.celBodyData).getBodyCenteredInertialFrame();
    end
    
    handles.baseFrameCombo.Value = ReferenceFrameEnum.getIndForName(baseFrame.typeEnum.name);
    setappdata(handles.lvd_EditActionSetQuatInterpSteeringModelGUI, 'baseFrame', baseFrame);

    handles.controlFrameCombo.String = ControlFramesEnum.getListBoxStr();
    
    if(steeringModel.usesControlFrame())
        handles.controlFrameCombo.Enable = 'on';
        controlFrame = steeringModel.getControlFrame();
        
        if(isempty(controlFrame))
            controlFrame = NedControlFrame();
            steeringModel.setControlFrame(controlFrame);
        end
        
        handles.controlFrameCombo.Value = ControlFramesEnum.getIndForName(controlFrame.enum.name);
        
    else
        handles.controlFrameCombo.Enable = 'off';
        handles.controlFrameCombo.Value = ControlFramesEnum.getIndForName(ControlFramesEnum.NedFrame.name);
    end
    
    [angle1Name, angle2Name, angle3Name] = steeringModel.getAngleNames();
    set(handles.angle1Panel,'Title',sprintf('%s', angle1Name));
    set(handles.angle2Panel,'Title',sprintf('%s', angle2Name));
    set(handles.angle3Panel,'Title',sprintf('%s', angle3Name));
       
    tDur = steeringModel.getDuration();
    [gamma0, beta0, alpha0] = steeringModel.getInitAngles();
    [gamma1, beta1, alpha1] = steeringModel.getFinalAngles();
    
    set(handles.tDurText,'String',fullAccNum2Str(tDur));
    
    set(handles.angle1InitText,'String',fullAccNum2Str(rad2deg(gamma0)));
    set(handles.angle1FinalText,'String',fullAccNum2Str(rad2deg(gamma1)));

    set(handles.angle2InitText,'String',fullAccNum2Str(rad2deg(beta0)));
    set(handles.angle2FinalText,'String',fullAccNum2Str(rad2deg(beta1)));
    
    set(handles.angle3InitText,'String',fullAccNum2Str(rad2deg(alpha0)));
    set(handles.angle3FinalText,'String',fullAccNum2Str(rad2deg(alpha1)));
    
    angleCont = steeringModel.getContinuityTerms();
    handles.angleContCheckbox.Value = double(angleCont);
    angleContCheckbox_Callback(handles.angleContCheckbox, [], handles);
    
    optVar = steeringModel.getExistingOptVar();
    if(isempty(optVar))
        useTf = false([1,7]);
        lb = zeros(size(useTf));
        ub = zeros(size(useTf));
    else
        useTf = optVar.getUseTfForVariable();
        optVar.setUseTfForVariable(true(size(useTf)));
        [lb, ub] = optVar.getBndsForVariable();
        optVar.setUseTfForVariable(useTf);
    end

    set(handles.tDurOptCheckbox,'Value',useTf(1));
    
    set(handles.angle1InitOptCheckbox,'Value',(useTf(2)));
    set(handles.angle1FinalOptCheckbox,'Value',(useTf(3)));
    
    set(handles.angle2InitOptCheckbox,'Value',(useTf(4)));
    set(handles.angle2FinalOptCheckbox,'Value',(useTf(5)));

    set(handles.angle3InitOptCheckbox,'Value',(useTf(6)));
    set(handles.angle3FinalOptCheckbox,'Value',(useTf(7)));
    
    tDurOptCheckbox_Callback(handles.tDurOptCheckbox, [], handles);
    
    angle1InitOptCheckbox_Callback(handles.angle1InitOptCheckbox, [], handles);
    angle2InitOptCheckbox_Callback(handles.angle2InitOptCheckbox, [], handles);
    angle3InitOptCheckbox_Callback(handles.angle3InitOptCheckbox, [], handles);
    
    angle1FinalOptCheckbox_Callback(handles.angle1FinalOptCheckbox, [], handles);
    angle2FinalOptCheckbox_Callback(handles.angle2FinalOptCheckbox, [], handles);
    angle3FinalOptCheckbox_Callback(handles.angle3FinalOptCheckbox, [], handles);
          
    %LB
    set(handles.tDurLbText,'String',fullAccNum2Str(lb(1)));
    
    set(handles.angle1InitLbText,'String',fullAccNum2Str(rad2deg(lb(2))));
    set(handles.angle1FinalLbText,'String',fullAccNum2Str(rad2deg(lb(3))));
    
    set(handles.angle2InitLbText,'String',fullAccNum2Str(rad2deg(lb(4))));
    set(handles.angle2FinalLbText,'String',fullAccNum2Str(rad2deg(lb(5))));
    
    set(handles.angle3InitLbText,'String',fullAccNum2Str(rad2deg(lb(6))));
    set(handles.angle3FinalLbText,'String',fullAccNum2Str(rad2deg(lb(7))));
    
    %UB
    set(handles.tDurUbText,'String',fullAccNum2Str(ub(1)));
    
    set(handles.angle1InitUbText,'String',fullAccNum2Str(rad2deg(ub(2))));
    set(handles.angle1FinalUbText,'String',fullAccNum2Str(rad2deg(ub(3))));
    
    set(handles.angle2InitUbText,'String',fullAccNum2Str(rad2deg(ub(4))));
    set(handles.angle2FinalUbText,'String',fullAccNum2Str(rad2deg(ub(5))));
    
    set(handles.angle3InitUbText,'String',fullAccNum2Str(rad2deg(ub(6))));
    set(handles.angle3FinalUbText,'String',fullAccNum2Str(rad2deg(ub(7))));
    
    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditActionSetQuatInterpSteeringModelGUI_OutputFcn(hObject, eventdata, handles) 
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
        steeringModel = action.steeringModel;
        
        optVar = steeringModel.getExistingOptVar();
        if(not(isempty(optVar))) %need to remove existing var if it exists
            lvdData.optimizer.vars.removeVariable(optVar);
        end
               
        if(steeringModel.usesRefFrame())
            steeringModel.setRefFrame(getappdata(hObject,'baseFrame'));
        end

        if(steeringModel.usesControlFrame())
            contents = cellstr(get(handles.controlFrameCombo,'String'));
            cFrameName = contents{get(handles.controlFrameCombo,'Value')};
            cFrameEnum = ControlFramesEnum.getEnumForListboxStr(cFrameName);
            cFrame = ControlFramesEnum.getControlFrameForEnum(cFrameEnum);
            
            steeringModel.setControlFrame(cFrame);
        end
        
        %Set Steering Terms
        tDur = str2double(get(handles.tDurText,'String'));
        
        angle1Init = deg2rad(str2double(get(handles.angle1InitText,'String')));
        angle1Final = deg2rad(str2double(get(handles.angle1FinalText,'String')));

        angle2Init = deg2rad(str2double(get(handles.angle2InitText,'String')));
        angle2Final = deg2rad(str2double(get(handles.angle2FinalText,'String')));
        
        angle3Init = deg2rad(str2double(get(handles.angle3InitText,'String')));
        angle3Final = deg2rad(str2double(get(handles.angle3FinalText,'String')));
        
        steeringModel.setDuration(tDur);
        
        steeringModel.setInitAngles(angle1Init, angle2Init, angle3Init);
        steeringModel.setFinalAngles(angle1Final, angle2Final, angle3Final);
        
        contTf = logical(handles.angleContCheckbox.Value);
        steeringModel.setContinuityTerms(contTf);
        
        %Set Opt T/F
        useTf(1) = get(handles.tDurOptCheckbox,'Value');
        
        useTf(2) = get(handles.angle1InitOptCheckbox,'Value');
        useTf(3) = get(handles.angle1FinalOptCheckbox,'Value');

        useTf(4) = get(handles.angle2InitOptCheckbox,'Value');
        useTf(5) = get(handles.angle2FinalOptCheckbox,'Value');

        useTf(6) = get(handles.angle3InitOptCheckbox,'Value');
        useTf(7) = get(handles.angle3FinalOptCheckbox,'Value');
        
        optVar = steeringModel.getNewOptVar();
        
        optVar.setUseTfForVariable(useTf);
        
        %LB
        lb(1) = str2double(handles.tDurLbText.String);
        
        lb(2) = deg2rad(str2double(get(handles.angle1InitLbText,'String')));
        lb(3) = deg2rad(str2double(get(handles.angle1FinalLbText,'String')));

        lb(4) = deg2rad(str2double(get(handles.angle2InitLbText,'String')));
        lb(5) = deg2rad(str2double(get(handles.angle2FinalLbText,'String')));

        lb(6) = deg2rad(str2double(get(handles.angle3InitLbText,'String')));
        lb(7) = deg2rad(str2double(get(handles.angle3FinalLbText,'String')));
        
        %UB
        ub(1) = str2double(handles.tDurUbText.String);
        
        ub(2) = deg2rad(str2double(get(handles.angle1InitUbText,'String')));
        ub(3) = deg2rad(str2double(get(handles.angle1FinalUbText,'String')));

        ub(4) = deg2rad(str2double(get(handles.angle2InitUbText,'String')));
        ub(5) = deg2rad(str2double(get(handles.angle2FinalUbText,'String')));

        ub(6) = deg2rad(str2double(get(handles.angle3InitUbText,'String')));
        ub(7) = deg2rad(str2double(get(handles.angle3FinalUbText,'String')));
        
        optVar.setUseTfForVariable(true(size(lb))); %need this to get the full lb/set in there
        optVar.setBndsForVariable(lb, ub);
        optVar.setUseTfForVariable(useTf);
               
        lvdData.optimizer.vars.addVariable(optVar);
        
        varargout{1} = true;
        close(handles.lvd_EditActionSetQuatInterpSteeringModelGUI);
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    action = getappdata(handles.lvd_EditActionSetQuatInterpSteeringModelGUI,'action');
    [angle1Name, angle2Name, angle3Name] = action.steeringModel.getAngleNames();
    
    %Duration
    tDur = str2double(get(handles.tDurText,'String'));
    enteredStr = get(handles.tDurText,'String');
    numberName = sprintf('Rotation Duration');
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(tDur, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Angle 1
    angle1Init = str2double(get(handles.angle1InitText,'String'));
    enteredStr = get(handles.angle1InitText,'String');
    numberName = sprintf('%s Initial Value', angle1Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1Init, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle1Final = str2double(get(handles.angle1FinalText,'String'));
    enteredStr = get(handles.angle1FinalText,'String');
    numberName = sprintf('%s Final Value', angle1Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1Final, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Angle 2
    angle2Init = str2double(get(handles.angle2InitText,'String'));
    enteredStr = get(handles.angle2InitText,'String');
    numberName = sprintf('%s Initial Value', angle2Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle2Init, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle2Final = str2double(get(handles.angle2FinalText,'String'));
    enteredStr = get(handles.angle2FinalText,'String');
    numberName = sprintf('%s Final Value', angle2Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle2Final, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Angle 3
    angle3Init = str2double(get(handles.angle3InitText,'String'));
    enteredStr = get(handles.angle3InitText,'String');
    numberName = sprintf('%s Initial Value', angle3Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle3Init, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle3Final = str2double(get(handles.angle3FinalText,'String'));
    enteredStr = get(handles.angle3FinalText,'String');
    numberName = sprintf('%s Final Value', angle3Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle3Final, numberName, lb, ub, isInt, errMsg, enteredStr);
        
    %%%%%Bounds
    %Angle 1 Const
    angle1InitLB = str2double(get(handles.angle1InitLbText,'String'));
    enteredStr = get(handles.angle1InitLbText,'String');
    numberName = sprintf('%s Initial Value Lower Bound', angle1Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1InitLB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle1InitUB = str2double(get(handles.angle1InitUbText,'String'));
    enteredStr = get(handles.angle1InitUbText,'String');
    numberName = sprintf('%s Initial Value Upper Bound', angle1Name);
    lb = angle1InitLB;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1InitUB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Angle 1 Linear
    angle1FinalLB = str2double(get(handles.angle1FinalLbText,'String'));
    enteredStr = get(handles.angle1FinalLbText,'String');
    numberName = sprintf('%s Final Value Lower Bound', angle1Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1FinalLB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle1FinalUB = str2double(get(handles.angle1FinalUbText,'String'));
    enteredStr = get(handles.angle1FinalUbText,'String');
    numberName = sprintf('%s Final Value Upper Bound', angle1Name);
    lb = angle1FinalLB;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1FinalUB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Angle 2 Const
    angle2InitLB = str2double(get(handles.angle2InitLbText,'String'));
    enteredStr = get(handles.angle2InitLbText,'String');
    numberName = sprintf('%s Initial Value Lower Bound', angle2Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle2InitLB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle2InitUB = str2double(get(handles.angle2InitUbText,'String'));
    enteredStr = get(handles.angle2InitUbText,'String');
    numberName = sprintf('%s Initial Value Upper Bound', angle2Name);
    lb = angle2InitLB;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle2InitUB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Angle 2 Linear
    angle2FinalLB = str2double(get(handles.angle2FinalLbText,'String'));
    enteredStr = get(handles.angle2FinalLbText,'String');
    numberName = sprintf('%s Final Value Lower Bound', angle2Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle2FinalLB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle2FinalUB = str2double(get(handles.angle2FinalUbText,'String'));
    enteredStr = get(handles.angle2FinalUbText,'String');
    numberName = sprintf('%s Final Value Upper Bound', angle2Name);
    lb = angle2FinalLB;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle2FinalUB, numberName, lb, ub, isInt, errMsg, enteredStr);
        
    %Angle 3 Const
    angle3InitLB = str2double(get(handles.angle3InitLbText,'String'));
    enteredStr = get(handles.angle3InitLbText,'String');
    numberName = sprintf('%s Initial Value Lower Bound', angle3Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle3InitLB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle3InitUB = str2double(get(handles.angle3InitUbText,'String'));
    enteredStr = get(handles.angle3InitUbText,'String');
    numberName = sprintf('%s Initial Value Upper Bound', angle3Name);
    lb = angle3InitLB;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle3InitUB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Angle 2 Linear
    angle3FinalLB = str2double(get(handles.angle3FinalLbText,'String'));
    enteredStr = get(handles.angle3FinalLbText,'String');
    numberName = sprintf('%s Final Value Lower Bound', angle3Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle3FinalLB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle3FinalUB = str2double(get(handles.angle3FinalUbText,'String'));
    enteredStr = get(handles.angle3FinalUbText,'String');
    numberName = sprintf('%s Final Value Upper Bound', angle3Name);
    lb = angle3FinalLB;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle3FinalUB, numberName, lb, ub, isInt, errMsg, enteredStr);
   
    

function angle1InitText_Callback(hObject, eventdata, handles)
% hObject    handle to angle1InitText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle1InitText as text
%        str2double(get(hObject,'String')) returns contents of angle1InitText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle1InitText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle1InitText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle1FinalText_Callback(hObject, eventdata, handles)
% hObject    handle to angle1FinalText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle1FinalText as text
%        str2double(get(hObject,'String')) returns contents of angle1FinalText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle1FinalText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle1FinalText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in angle1InitOptCheckbox.
function angle1InitOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to angle1InitOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of angle1InitOptCheckbox
    if(get(hObject,'Value')==1)
        set(handles.angle1InitLbText,'Enable','on');
        set(handles.angle1InitUbText,'Enable','on');
    else
        set(handles.angle1InitLbText,'Enable','off');
        set(handles.angle1InitUbText,'Enable','off');
    end


function angle1InitLbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle1InitLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle1InitLbText as text
%        str2double(get(hObject,'String')) returns contents of angle1InitLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle1InitLbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle1InitLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle1InitUbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle1InitUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle1InitUbText as text
%        str2double(get(hObject,'String')) returns contents of angle1InitUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle1InitUbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle1InitUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in angle1FinalOptCheckbox.
function angle1FinalOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to angle1FinalOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of angle1FinalOptCheckbox
    if(get(hObject,'Value')==1)
        set(handles.angle1FinalLbText,'Enable','on');
        set(handles.angle1FinalUbText,'Enable','on');
    else
        set(handles.angle1FinalLbText,'Enable','off');
        set(handles.angle1FinalUbText,'Enable','off');
    end


function angle1FinalLbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle1FinalLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle1FinalLbText as text
%        str2double(get(hObject,'String')) returns contents of angle1FinalLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle1FinalLbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle1FinalLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle1FinalUbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle1FinalUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle1FinalUbText as text
%        str2double(get(hObject,'String')) returns contents of angle1FinalUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle1FinalUbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle1FinalUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function angle3FinalUbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle3FinalUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle3FinalUbText as text
%        str2double(get(hObject,'String')) returns contents of angle3FinalUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle3FinalUbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle3FinalUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle3FinalLbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle3FinalLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle3FinalLbText as text
%        str2double(get(hObject,'String')) returns contents of angle3FinalLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle3FinalLbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle3FinalLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in angle3FinalOptCheckbox.
function angle3FinalOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to angle3FinalOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of angle3FinalOptCheckbox
    if(get(hObject,'Value')==1)
        set(handles.angle3FinalLbText,'Enable','on');
        set(handles.angle3FinalUbText,'Enable','on');
    else
        set(handles.angle3FinalLbText,'Enable','off');
        set(handles.angle3FinalUbText,'Enable','off');
    end


function angle3InitUbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle3InitUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle3InitUbText as text
%        str2double(get(hObject,'String')) returns contents of angle3InitUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle3InitUbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle3InitUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle3InitLbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle3InitLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle3InitLbText as text
%        str2double(get(hObject,'String')) returns contents of angle3InitLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle3InitLbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle3InitLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in angle3InitOptCheckbox.
function angle3InitOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to angle3InitOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of angle3InitOptCheckbox
    if(get(hObject,'Value')==1)
        set(handles.angle3InitLbText,'Enable','on');
        set(handles.angle3InitUbText,'Enable','on');
    else
        set(handles.angle3InitLbText,'Enable','off');
        set(handles.angle3InitUbText,'Enable','off');
    end


function angle3FinalText_Callback(hObject, eventdata, handles)
% hObject    handle to angle3FinalText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle3FinalText as text
%        str2double(get(hObject,'String')) returns contents of angle3FinalText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle3FinalText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle3FinalText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle3InitText_Callback(hObject, eventdata, handles)
% hObject    handle to angle3InitText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle3InitText as text
%        str2double(get(hObject,'String')) returns contents of angle3InitText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle3InitText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle3InitText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle2InitText_Callback(hObject, eventdata, handles)
% hObject    handle to angle2InitText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle2InitText as text
%        str2double(get(hObject,'String')) returns contents of angle2InitText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle2InitText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle2InitText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle2FinalText_Callback(hObject, eventdata, handles)
% hObject    handle to angle2FinalText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle2FinalText as text
%        str2double(get(hObject,'String')) returns contents of angle2FinalText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle2FinalText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle2FinalText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in angle2InitOptCheckbox.
function angle2InitOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to angle2InitOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of angle2InitOptCheckbox
    if(get(hObject,'Value')==1)
        set(handles.angle2InitLbText,'Enable','on');
        set(handles.angle2InitUbText,'Enable','on');
    else
        set(handles.angle2InitLbText,'Enable','off');
        set(handles.angle2InitUbText,'Enable','off');
    end


function angle2InitLbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle2InitLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle2InitLbText as text
%        str2double(get(hObject,'String')) returns contents of angle2InitLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle2InitLbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle2InitLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle2InitUbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle2InitUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle2InitUbText as text
%        str2double(get(hObject,'String')) returns contents of angle2InitUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle2InitUbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle2InitUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in angle2FinalOptCheckbox.
function angle2FinalOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to angle2FinalOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of angle2FinalOptCheckbox
    if(get(hObject,'Value')==1)
        set(handles.angle2FinalLbText,'Enable','on');
        set(handles.angle2FinalUbText,'Enable','on');
    else
        set(handles.angle2FinalLbText,'Enable','off');
        set(handles.angle2FinalUbText,'Enable','off');
    end


function angle2FinalLbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle2FinalLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle2FinalLbText as text
%        str2double(get(hObject,'String')) returns contents of angle2FinalLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle2FinalLbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle2FinalLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle2FinalUbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle2FinalUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle2FinalUbText as text
%        str2double(get(hObject,'String')) returns contents of angle2FinalUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle2FinalUbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle2FinalUbText (see GCBO)
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
        uiresume(handles.lvd_EditActionSetQuatInterpSteeringModelGUI);
    else
        msgbox(errMsg,'Errors were found while editing the steering model.','error');
    end
    

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditActionSetQuatInterpSteeringModelGUI);


% --- Executes on button press in angleContCheckbox.
function angleContCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to angleContCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of angleContCheckbox
    if(get(hObject,'Value'))
        handles.angle1InitText.Enable = 'off';
        handles.angle2InitText.Enable = 'off';
        handles.angle3InitText.Enable = 'off';
        
        handles.angle1InitOptCheckbox.Enable = 'off';
        handles.angle2InitOptCheckbox.Enable = 'off';
        handles.angle3InitOptCheckbox.Enable = 'off';
        
        handles.angle1InitOptCheckbox.Value = 0;
        handles.angle2InitOptCheckbox.Value = 0;
        handles.angle3InitOptCheckbox.Value = 0;
                
        angle1InitOptCheckbox_Callback(handles.angle1InitOptCheckbox, [], handles);
        angle2InitOptCheckbox_Callback(handles.angle2InitOptCheckbox, [], handles);
        angle3InitOptCheckbox_Callback(handles.angle3InitOptCheckbox, [], handles);
    else
        handles.angle1InitText.Enable = 'on';
        handles.angle2InitText.Enable = 'on';
        handles.angle3InitText.Enable = 'on';
        
        handles.angle1InitOptCheckbox.Enable = 'on';
        handles.angle2InitOptCheckbox.Enable = 'on';
        handles.angle3InitOptCheckbox.Enable = 'on';

        angle1InitOptCheckbox_Callback(handles.angle1InitOptCheckbox, [], handles);
        angle2InitOptCheckbox_Callback(handles.angle2InitOptCheckbox, [], handles);
        angle3InitOptCheckbox_Callback(handles.angle3InitOptCheckbox, [], handles);
    end
    


% --- Executes on key press with focus on lvd_EditActionSetQuatInterpSteeringModelGUI or any of its controls.
function lvd_EditActionSetQuatInterpSteeringModelGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditActionSetQuatInterpSteeringModelGUI (see GCBO)
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
            close(handles.lvd_EditActionSetQuatInterpSteeringModelGUI);
    end

    
function bodyInfo = getSelectedBodyInfo(handles)
    baseFrame = getappdata(handles.lvd_EditActionSetQuatInterpSteeringModelGUI,'baseFrame');
    bodyInfo = baseFrame.getOriginBody();
    

% --- Executes on selection change in baseFrameCombo.
function baseFrameCombo_Callback(hObject, eventdata, handles)
% hObject    handle to baseFrameCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns baseFrameCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from baseFrameCombo
    contents = cellstr(get(handles.baseFrameCombo,'String'));
    selFrameType = contents{get(handles.baseFrameCombo,'Value')};
    refFrameEnum = ReferenceFrameEnum.getEnumForListboxStr(selFrameType);
    
    switch refFrameEnum
        case ReferenceFrameEnum.BodyCenteredInertial
            bodyInfo = getSelectedBodyInfo(handles);           
            newFrame = bodyInfo.getBodyCenteredInertialFrame();

        case ReferenceFrameEnum.BodyFixedRotating
            bodyInfo = getSelectedBodyInfo(handles);
            newFrame = bodyInfo.getBodyFixedFrame();
            
        case ReferenceFrameEnum.TwoBodyRotating            
            bodyInfo = getSelectedBodyInfo(handles);
            if(not(isempty(bodyInfo.childrenBodyInfo)))
                primaryBody = bodyInfo;
                secondaryBody = bodyInfo.childrenBodyInfo(1);
            else
                primaryBody = bodyInfo.getParBodyInfo();
                secondaryBody = bodyInfo;
            end

            originPt = TwoBodyRotatingFrameOriginEnum.Primary;

            newFrame = TwoBodyRotatingFrame(primaryBody, secondaryBody, originPt, bodyInfo.celBodyData);

        otherwise
            error('Unknown reference frame type: %s', class(refFrameEnum));                
    end
    
    setappdata(handles.lvd_EditActionSetQuatInterpSteeringModelGUI, 'baseFrame', newFrame);

% --- Executes during object creation, after setting all properties.
function baseFrameCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to baseFrameCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in setBaseFrameOptionsButton.
function setBaseFrameOptionsButton_Callback(hObject, eventdata, handles)
% hObject    handle to setBaseFrameOptionsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    baseFrame = getappdata(handles.lvd_EditActionSetQuatInterpSteeringModelGUI, 'baseFrame');
    newFrame = baseFrame.editFrameDialogUI();
    
    setappdata(handles.lvd_EditActionSetQuatInterpSteeringModelGUI, 'baseFrame', newFrame);

% --- Executes on selection change in controlFrameCombo.
function controlFrameCombo_Callback(hObject, eventdata, handles)
% hObject    handle to controlFrameCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns controlFrameCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from controlFrameCombo
    contents = cellstr(get(hObject,'String'));
    listBoxStr = contents{get(hObject,'Value')};
    
    enum = ControlFramesEnum.getEnumForListboxStr(listBoxStr);
    angleNames = enum.angleNames;

    set(handles.angle1Panel,'Title',sprintf('%s', angleNames{1}));
    set(handles.angle2Panel,'Title',sprintf('%s', angleNames{2}));
    set(handles.angle3Panel,'Title',sprintf('%s', angleNames{3}));

% --- Executes during object creation, after setting all properties.
function controlFrameCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to controlFrameCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tDurText_Callback(hObject, eventdata, handles)
% hObject    handle to tDurText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tDurText as text
%        str2double(get(hObject,'String')) returns contents of tDurText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function tDurText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tDurText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in tDurOptCheckbox.
function tDurOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to tDurOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tDurOptCheckbox
    if(get(hObject,'Value')==1)
        set(handles.tDurLbText,'Enable','on');
        set(handles.tDurUbText,'Enable','on');
    else
        set(handles.tDurLbText,'Enable','off');
        set(handles.tDurUbText,'Enable','off');
    end


function tDurLbText_Callback(hObject, eventdata, handles)
% hObject    handle to tDurLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tDurLbText as text
%        str2double(get(hObject,'String')) returns contents of tDurLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function tDurLbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tDurLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tDurUbText_Callback(hObject, eventdata, handles)
% hObject    handle to tDurUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tDurUbText as text
%        str2double(get(hObject,'String')) returns contents of tDurUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function tDurUbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tDurUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
