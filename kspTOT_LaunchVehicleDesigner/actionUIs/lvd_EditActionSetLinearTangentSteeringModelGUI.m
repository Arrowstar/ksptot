function varargout = lvd_EditActionSetLinearTangentSteeringModelGUI(varargin)
% LVD_EDITACTIONSETLINEARTANGENTSTEERINGMODELGUI MATLAB code for lvd_EditActionSetLinearTangentSteeringModelGUI.fig
%      LVD_EDITACTIONSETLINEARTANGENTSTEERINGMODELGUI, by itself, creates a new LVD_EDITACTIONSETLINEARTANGENTSTEERINGMODELGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITACTIONSETLINEARTANGENTSTEERINGMODELGUI returns the handle to a new LVD_EDITACTIONSETLINEARTANGENTSTEERINGMODELGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITACTIONSETLINEARTANGENTSTEERINGMODELGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITACTIONSETLINEARTANGENTSTEERINGMODELGUI.M with the given input arguments.
%
%      LVD_EDITACTIONSETLINEARTANGENTSTEERINGMODELGUI('Property','Value',...) creates a new LVD_EDITACTIONSETLINEARTANGENTSTEERINGMODELGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditActionSetLinearTangentSteeringModelGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditActionSetLinearTangentSteeringModelGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditActionSetLinearTangentSteeringModelGUI

% Last Modified by GUIDE v2.5 29-Dec-2020 13:39:59

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditActionSetLinearTangentSteeringModelGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditActionSetLinearTangentSteeringModelGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditActionSetLinearTangentSteeringModelGUI is made visible.
function lvd_EditActionSetLinearTangentSteeringModelGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditActionSetLinearTangentSteeringModelGUI (see VARARGIN)

    % Choose default command line output for lvd_EditActionSetLinearTangentSteeringModelGUI
    handles.output = hObject;

    action = varargin{1};
    setappdata(hObject,'action',action);
    
    lv = varargin{2};
    setappdata(hObject,'lv',lv);
    
    useContinuity = varargin{3};
    setappdata(hObject,'useContinuity',useContinuity);
    
    populateGUI(handles, action, lv, useContinuity);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditActionSetLinearTangentSteeringModelGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditActionSetLinearTangentSteeringModelGUI);


function populateGUI(handles, action, lv, useContinuity)
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
    setappdata(handles.lvd_EditActionSetLinearTangentSteeringModelGUI, 'baseFrame', baseFrame);

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
        
    [angleModel, ~] = steeringModel.getAngleNModel(1);
    handles.timeOffsetText.String = fullAccNum2Str(angleModel.tOffset); %first angle model will be the offset used everywhere
    set(handles.angle1ConstTermText,'String',fullAccNum2Str(rad2deg(angleModel.constTerm)));
    set(handles.angle1LinTermText,'String',fullAccNum2Str(rad2deg(angleModel.linearTerm)));
    set(handles.angle1AccelTermText,'String',fullAccNum2Str(rad2deg(angleModel.accelTerm)));
    
    [angleModel, ~] = steeringModel.getAngleNModel(2);
    set(handles.angle2ATermText,'String',fullAccNum2Str(angleModel.a));
    set(handles.angle2ADotTermText,'String',fullAccNum2Str(angleModel.a_dot));
    set(handles.angle2BTermText,'String',fullAccNum2Str(angleModel.b));
    set(handles.angle2BDotTermText,'String',fullAccNum2Str(angleModel.b_dot));
    
    [angleModel, ~] = steeringModel.getAngleNModel(3);
    set(handles.angle3ConstTermText,'String',fullAccNum2Str(rad2deg(angleModel.constTerm)));
    set(handles.angle3LinTermText,'String',fullAccNum2Str(rad2deg(angleModel.linearTerm)));
    set(handles.angle3AccelTermText,'String',fullAccNum2Str(rad2deg(angleModel.accelTerm)));
    
    [contTf1,contTf2,contTf3] = steeringModel.getContinuityTerms();
    contTf = any([contTf1,contTf2,contTf3]);
    if(useContinuity)
        handles.angleContCheckbox.Enable = 'on';
    else
        handles.angleContCheckbox.Enable = 'off';
    end
    handles.angleContCheckbox.Value = double(contTf);
    angleContCheckbox_Callback(handles.angleContCheckbox, [], handles);
    
    optVar = steeringModel.getExistingOptVar();
    if(isempty(optVar))
        useTf = false([1,11]);
        lb = zeros(size(useTf));
        ub = zeros(size(useTf));
    else
        useTf = optVar.getUseTfForVariable();
        optVar.setUseTfForVariable(true(size(useTf)));
        [lb, ub] = optVar.getBndsForVariable();
        optVar.setUseTfForVariable(useTf);
    end

    set(handles.angle1ConstOptCheckbox,'Value',(useTf(1)));
    set(handles.angle1LinOptCheckbox,'Value',(useTf(2)));
    set(handles.angle1AccelOptCheckbox,'Value',(useTf(3)));
    
    set(handles.angle2AOptCheckbox,'Value',(useTf(4)));
    set(handles.angle2ADotOptCheckbox,'Value',(useTf(5)));
    set(handles.angle2BOptCheckbox,'Value',(useTf(6)));
    set(handles.angle2BDotOptCheckbox,'Value',(useTf(7)));

    set(handles.angle3ConstOptCheckbox,'Value',(useTf(8)));
    set(handles.angle3LinOptCheckbox,'Value',(useTf(9)));
    set(handles.angle3AccelOptCheckbox,'Value',(useTf(10)));
    
    set(handles.timeOffsetConstOptCheckbox,'Value',(useTf(11)));
    
    angle1ConstOptCheckbox_Callback(handles.angle1ConstOptCheckbox, [], handles);
    angle3ConstOptCheckbox_Callback(handles.angle3ConstOptCheckbox, [], handles);
    
    angle1LinOptCheckbox_Callback(handles.angle1LinOptCheckbox, [], handles);
    angle3LinOptCheckbox_Callback(handles.angle3LinOptCheckbox, [], handles);
    
    angle1AccelOptCheckbox_Callback(handles.angle1AccelOptCheckbox, [], handles);
    angle3AccelOptCheckbox_Callback(handles.angle3AccelOptCheckbox, [], handles);
    
    angle2AOptCheckbox_Callback(handles.angle2AOptCheckbox, [], handles);
    angle2ADotOptCheckbox_Callback(handles.angle2ADotOptCheckbox, [], handles);
    angle2BOptCheckbox_Callback(handles.angle2BOptCheckbox, [], handles);
    angle2BDotOptCheckbox_Callback(handles.angle2BDotOptCheckbox, [], handles);
    
    timeOffsetConstOptCheckbox_Callback(handles.timeOffsetConstOptCheckbox, [], handles);
        
    %LB
    set(handles.angle1ConstLbText,'String',fullAccNum2Str(rad2deg(lb(1))));
    set(handles.angle1LinLbText,'String',fullAccNum2Str(rad2deg(lb(2))));
    set(handles.angle1AccelLbText,'String',fullAccNum2Str(rad2deg(lb(3))));
    
    set(handles.angle2ALbText,'String',fullAccNum2Str(lb(4)));
    set(handles.angle2ADotLbText,'String',fullAccNum2Str(lb(5)));
    set(handles.angle2BLbText,'String',fullAccNum2Str(lb(6)));
    set(handles.angle2BDotLbText,'String',fullAccNum2Str(lb(7)));
    
    set(handles.angle3ConstLbText,'String',fullAccNum2Str(rad2deg(lb(8))));
    set(handles.angle3LinLbText,'String',fullAccNum2Str(rad2deg(lb(9))));
    set(handles.angle3AccelLbText,'String',fullAccNum2Str(rad2deg(lb(10))));
    
    set(handles.timeOffsetConstLbText,'String',fullAccNum2Str(lb(11)));
    
    %UB
    set(handles.angle1ConstUbText,'String',fullAccNum2Str(rad2deg(ub(1))));
    set(handles.angle1LinUbText,'String',fullAccNum2Str(rad2deg(ub(2))));
    set(handles.angle1AccelUbText,'String',fullAccNum2Str(rad2deg(ub(3))));
    
    set(handles.angle2AUbText,'String',fullAccNum2Str(ub(4)));
    set(handles.angle2ADotUbText,'String',fullAccNum2Str(ub(5)));
    set(handles.angle2BUbText,'String',fullAccNum2Str(ub(6)));
    set(handles.angle2BDotUbText,'String',fullAccNum2Str(ub(7)));
    
    set(handles.angle3ConstUbText,'String',fullAccNum2Str(rad2deg(ub(8))));
    set(handles.angle3LinUbText,'String',fullAccNum2Str(rad2deg(ub(9))));
    set(handles.angle3AccelUbText,'String',fullAccNum2Str(rad2deg(ub(10))));
    
    set(handles.timeOffsetConstUbText,'String',fullAccNum2Str(ub(11)));
    
    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditActionSetLinearTangentSteeringModelGUI_OutputFcn(hObject, eventdata, handles) 
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
        timeOffset = str2double(get(handles.timeOffsetText,'String'));
        
        angle1Const = deg2rad(str2double(get(handles.angle1ConstTermText,'String')));
        angle1Linear = deg2rad(str2double(get(handles.angle1LinTermText,'String')));
        angle1Accel = deg2rad(str2double(get(handles.angle1AccelTermText,'String')));

        angle2A = str2double(get(handles.angle2ATermText,'String'));
        angle2ADot = str2double(get(handles.angle2ADotTermText,'String'));
        angle2B = str2double(get(handles.angle2BTermText,'String'));
        angle2BDot = str2double(get(handles.angle2BDotTermText,'String'));
        
        angle3Const = deg2rad(str2double(get(handles.angle3ConstTermText,'String')));
        angle3Linear = deg2rad(str2double(get(handles.angle3LinTermText,'String')));
        angle3Accel = deg2rad(str2double(get(handles.angle3AccelTermText,'String')));
        
        steeringModel.setTimeOffsets(timeOffset);
        steeringModel.setConstTerms(angle1Const, angle3Const);
        steeringModel.setLinearTerms(angle1Linear, angle3Linear);
        steeringModel.setAccelTerms(angle1Accel,  angle3Accel);
        steeringModel.setLinearTangentTerms(angle2A,  angle2ADot, angle2B, angle2BDot);
        
        contTf = logical(handles.angleContCheckbox.Value);
        steeringModel.setContinuityTerms(contTf,contTf,contTf);
        
        %Set Opt T/F
        useTf(1) = get(handles.angle1ConstOptCheckbox,'Value');
        useTf(2) = get(handles.angle1LinOptCheckbox,'Value');
        useTf(3) = get(handles.angle1AccelOptCheckbox,'Value');

        useTf(4) = get(handles.angle2AOptCheckbox,'Value');
        useTf(5) = get(handles.angle2ADotOptCheckbox,'Value');
        useTf(6) = get(handles.angle2BOptCheckbox,'Value');
        useTf(7) = get(handles.angle2BDotOptCheckbox,'Value');

        useTf(8) = get(handles.angle3ConstOptCheckbox,'Value');
        useTf(9) = get(handles.angle3LinOptCheckbox,'Value');
        useTf(10) = get(handles.angle3AccelOptCheckbox,'Value');
        
        useTf(11) = handles.timeOffsetConstOptCheckbox.Value;
        
        optVar = steeringModel.getNewOptVar();
        
        optVar.setUseTfForVariable(useTf);
        
        %LB
        lb(1) = deg2rad(str2double(get(handles.angle1ConstLbText,'String')));
        lb(2) = deg2rad(str2double(get(handles.angle1LinLbText,'String')));
        lb(3) = deg2rad(str2double(get(handles.angle1AccelLbText,'String')));

        lb(4) = str2double(get(handles.angle2ALbText,'String'));
        lb(5) = str2double(get(handles.angle2ADotLbText,'String'));
        lb(6) = str2double(get(handles.angle2BLbText,'String'));
        lb(7) = str2double(get(handles.angle2BDotLbText,'String'));

        lb(8) = deg2rad(str2double(get(handles.angle3ConstLbText,'String')));
        lb(9) = deg2rad(str2double(get(handles.angle3LinLbText,'String')));
        lb(10) = deg2rad(str2double(get(handles.angle3AccelLbText,'String')));
        
        lb(11) = str2double(get(handles.timeOffsetConstLbText,'String'));
        
        %UB
        ub(1) = deg2rad(str2double(get(handles.angle1ConstUbText,'String')));
        ub(2) = deg2rad(str2double(get(handles.angle1LinUbText,'String')));
        ub(3) = deg2rad(str2double(get(handles.angle1AccelUbText,'String')));

        ub(4) = str2double(get(handles.angle2AUbText,'String'));
        ub(5) = str2double(get(handles.angle2ADotUbText,'String'));
        ub(6) = str2double(get(handles.angle2BUbText,'String'));
        ub(7) = str2double(get(handles.angle2BDotUbText,'String'));

        ub(8) = deg2rad(str2double(get(handles.angle3ConstUbText,'String')));
        ub(9) = deg2rad(str2double(get(handles.angle3LinUbText,'String')));
        ub(10) = deg2rad(str2double(get(handles.angle3AccelUbText,'String')));
        
        ub(11) = str2double(get(handles.timeOffsetConstUbText,'String'));
        
        optVar.setUseTfForVariable(true(size(lb))); %need this to get the full lb/set in there
        optVar.setBndsForVariable(lb, ub);
        optVar.setUseTfForVariable(useTf);
               
        lvdData.optimizer.vars.addVariable(optVar);
        
        varargout{1} = true;
        close(handles.lvd_EditActionSetLinearTangentSteeringModelGUI);
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    action = getappdata(handles.lvd_EditActionSetLinearTangentSteeringModelGUI,'action');
    [angle1Name, angle2Name, angle3Name] = action.steeringModel.getAngleNames();
    
    %Angle 1
    angle1Const = str2double(get(handles.angle1ConstTermText,'String'));
    enteredStr = get(handles.angle1ConstTermText,'String');
    numberName = sprintf('%s Constant Term', angle1Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1Const, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle1Linear = str2double(get(handles.angle1LinTermText,'String'));
    enteredStr = get(handles.angle1LinTermText,'String');
    numberName = sprintf('%s Linear Term', angle1Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1Linear, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle1Accel = str2double(get(handles.angle1AccelTermText,'String'));
    enteredStr = get(handles.angle1AccelTermText,'String');
    numberName = sprintf('%s Acceleration Term', angle1Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1Accel, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Angle 2
    angle2A = str2double(get(handles.angle2ATermText,'String'));
    enteredStr = get(handles.angle2ATermText,'String');
    numberName = sprintf('%s A Term', angle2Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle2A, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle2ADot = str2double(get(handles.angle2ADotTermText,'String'));
    enteredStr = get(handles.angle2ADotTermText,'String');
    numberName = sprintf('%s A Dot Term', angle2Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle2ADot, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle2B = str2double(get(handles.angle2BTermText,'String'));
    enteredStr = get(handles.angle2BTermText,'String');
    numberName = sprintf('%s B Term', angle2Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle2B, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle2BDot = str2double(get(handles.angle2BDotTermText,'String'));
    enteredStr = get(handles.angle2BDotTermText,'String');
    numberName = sprintf('%s B Dot Term', angle2Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle2BDot, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Angle 3
    angle3Const = str2double(get(handles.angle3ConstTermText,'String'));
    enteredStr = get(handles.angle3ConstTermText,'String');
    numberName = sprintf('%s Constant Term', angle3Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle3Const, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle3Linear = str2double(get(handles.angle3LinTermText,'String'));
    enteredStr = get(handles.angle3LinTermText,'String');
    numberName = sprintf('%s Linear Term', angle3Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle3Linear, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle3Accel = str2double(get(handles.angle3AccelTermText,'String'));
    enteredStr = get(handles.angle3AccelTermText,'String');
    numberName = sprintf('%s Acceleration Term', angle3Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle3Accel, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Time offset
    timeOffset = str2double(get(handles.timeOffsetText,'String'));
    enteredStr = get(handles.timeOffsetText,'String');
    numberName = 'Time Offset';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(timeOffset, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %%%%%Bounds
    %Angle 1 Const
    angle1ConstLB = str2double(get(handles.angle1ConstLbText,'String'));
    enteredStr = get(handles.angle1ConstLbText,'String');
    numberName = sprintf('%s Constant Term Lower Bound', angle1Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1ConstLB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle1ConstUB = str2double(get(handles.angle1ConstUbText,'String'));
    enteredStr = get(handles.angle1ConstUbText,'String');
    numberName = sprintf('%s Constant Term Upper Bound', angle1Name);
    lb = angle1ConstLB;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1ConstUB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Angle 1 Linear
    angle1LinearLB = str2double(get(handles.angle1LinLbText,'String'));
    enteredStr = get(handles.angle1LinLbText,'String');
    numberName = sprintf('%s Linear Term Lower Bound', angle1Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1LinearLB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle1LinearUB = str2double(get(handles.angle1LinUbText,'String'));
    enteredStr = get(handles.angle1LinUbText,'String');
    numberName = sprintf('%s Linear Term Upper Bound', angle1Name);
    lb = angle1LinearLB;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1LinearUB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Angle 1 Accel
    angle1AccelLB = str2double(get(handles.angle1AccelLbText,'String'));
    enteredStr = get(handles.angle1AccelLbText,'String');
    numberName = sprintf('%s Acceleration Term Lower Bound', angle1Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1AccelLB, numberName, lb, ub, isInt, errMsg, enteredStr);

    angle1AccelUB = str2double(get(handles.angle1AccelUbText,'String'));
    enteredStr = get(handles.angle1AccelUbText,'String');
    numberName = sprintf('%s Acceleration Term Upper Bound', angle1Name);
    lb = angle1AccelLB;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1AccelUB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Angle 2 A
    angle2ALB = str2double(get(handles.angle2ALbText,'String'));
    enteredStr = get(handles.angle2ALbText,'String');
    numberName = sprintf('%s A Term Lower Bound', angle2Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle2ALB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle2AUB = str2double(get(handles.angle2AUbText,'String'));
    enteredStr = get(handles.angle2AUbText,'String');
    numberName = sprintf('%s A Term Upper Bound', angle2Name);
    lb = angle2ALB;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle2AUB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Angle 2 A Dot
    angle2ADotLB = str2double(get(handles.angle2ADotLbText,'String'));
    enteredStr = get(handles.angle2ADotLbText,'String');
    numberName = sprintf('%s A Dot Term Lower Bound', angle2Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle2ADotLB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle2ADotUB = str2double(get(handles.angle2ADotUbText,'String'));
    enteredStr = get(handles.angle2ADotUbText,'String');
    numberName = sprintf('%s A Dot Term Upper Bound', angle2Name);
    lb = angle2ADotLB;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle2ADotUB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Angle 2 B
    angle2BLB = str2double(get(handles.angle2BLbText,'String'));
    enteredStr = get(handles.angle2BLbText,'String');
    numberName = sprintf('%s B Term Lower Bound', angle2Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle2BLB, numberName, lb, ub, isInt, errMsg, enteredStr);

    angle2BUB = str2double(get(handles.angle2BUbText,'String'));
    enteredStr = get(handles.angle2BUbText,'String');
    numberName = sprintf('%s B Term Upper Bound', angle2Name);
    lb = angle2BLB;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle2BUB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Angle 2 B Dot
    angle2BDotLB = str2double(get(handles.angle2BDotLbText,'String'));
    enteredStr = get(handles.angle2BDotLbText,'String');
    numberName = sprintf('%s B Dot Term Lower Bound', angle2Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle2BDotLB, numberName, lb, ub, isInt, errMsg, enteredStr);

    angle2BDotUB = str2double(get(handles.angle2BDotUbText,'String'));
    enteredStr = get(handles.angle2BDotUbText,'String');
    numberName = sprintf('%s B Dot Term Upper Bound', angle2Name);
    lb = angle2BDotLB;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle2BDotUB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Angle 3 Const
    angle3ConstLB = str2double(get(handles.angle3ConstLbText,'String'));
    enteredStr = get(handles.angle3ConstLbText,'String');
    numberName = sprintf('%s Constant Term Lower Bound', angle3Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle3ConstLB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle3ConstUB = str2double(get(handles.angle3ConstUbText,'String'));
    enteredStr = get(handles.angle3ConstUbText,'String');
    numberName = sprintf('%s Constant Term Upper Bound', angle3Name);
    lb = angle3ConstLB;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle3ConstUB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Angle 2 Linear
    angle3LinearLB = str2double(get(handles.angle3LinLbText,'String'));
    enteredStr = get(handles.angle3LinLbText,'String');
    numberName = sprintf('%s Linear Term Lower Bound', angle3Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle3LinearLB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle3LinearUB = str2double(get(handles.angle3LinUbText,'String'));
    enteredStr = get(handles.angle3LinUbText,'String');
    numberName = sprintf('%s Linear Term Upper Bound', angle3Name);
    lb = angle3LinearLB;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle3LinearUB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Angle 2 Accel
    angle3AccelLB = str2double(get(handles.angle3AccelLbText,'String'));
    enteredStr = get(handles.angle3AccelLbText,'String');
    numberName = sprintf('%s Acceleration Term Lower Bound', angle3Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle3AccelLB, numberName, lb, ub, isInt, errMsg, enteredStr);

    angle3AccelUB = str2double(get(handles.angle3AccelUbText,'String'));
    enteredStr = get(handles.angle3AccelUbText,'String');
    numberName = sprintf('%s Acceleration Term Upper Bound', angle3Name);
    lb = angle3AccelLB;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle3AccelUB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Time Offset
    timeOffsetLb = str2double(get(handles.timeOffsetConstLbText,'String'));
    enteredStr = get(handles.timeOffsetConstLbText,'String');
    numberName = 'Time Offset Lower Bound';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(timeOffsetLb, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    timeOffsetUb = str2double(get(handles.timeOffsetConstUbText,'String'));
    enteredStr = get(handles.timeOffsetConstUbText,'String');
    numberName = 'Time Offset Upper Bound';
    lb = timeOffsetLb;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(timeOffsetUb, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    

function angle1ConstTermText_Callback(hObject, eventdata, handles)
% hObject    handle to angle1ConstTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle1ConstTermText as text
%        str2double(get(hObject,'String')) returns contents of angle1ConstTermText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle1ConstTermText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle1ConstTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle1LinTermText_Callback(hObject, eventdata, handles)
% hObject    handle to angle1LinTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle1LinTermText as text
%        str2double(get(hObject,'String')) returns contents of angle1LinTermText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle1LinTermText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle1LinTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle1AccelTermText_Callback(hObject, eventdata, handles)
% hObject    handle to angle1AccelTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle1AccelTermText as text
%        str2double(get(hObject,'String')) returns contents of angle1AccelTermText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle1AccelTermText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle1AccelTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in angle1ConstOptCheckbox.
function angle1ConstOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to angle1ConstOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of angle1ConstOptCheckbox
    if(get(hObject,'Value')==1)
        set(handles.angle1ConstLbText,'Enable','on');
        set(handles.angle1ConstUbText,'Enable','on');
    else
        set(handles.angle1ConstLbText,'Enable','off');
        set(handles.angle1ConstUbText,'Enable','off');
    end


function angle1ConstLbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle1ConstLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle1ConstLbText as text
%        str2double(get(hObject,'String')) returns contents of angle1ConstLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle1ConstLbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle1ConstLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle1ConstUbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle1ConstUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle1ConstUbText as text
%        str2double(get(hObject,'String')) returns contents of angle1ConstUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle1ConstUbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle1ConstUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in angle1LinOptCheckbox.
function angle1LinOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to angle1LinOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of angle1LinOptCheckbox
    if(get(hObject,'Value')==1)
        set(handles.angle1LinLbText,'Enable','on');
        set(handles.angle1LinUbText,'Enable','on');
    else
        set(handles.angle1LinLbText,'Enable','off');
        set(handles.angle1LinUbText,'Enable','off');
    end


function angle1LinLbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle1LinLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle1LinLbText as text
%        str2double(get(hObject,'String')) returns contents of angle1LinLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle1LinLbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle1LinLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle1LinUbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle1LinUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle1LinUbText as text
%        str2double(get(hObject,'String')) returns contents of angle1LinUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle1LinUbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle1LinUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in angle1AccelOptCheckbox.
function angle1AccelOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to angle1AccelOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of angle1AccelOptCheckbox
    if(get(hObject,'Value')==1)
        set(handles.angle1AccelLbText,'Enable','on');
        set(handles.angle1AccelUbText,'Enable','on');
    else
        set(handles.angle1AccelLbText,'Enable','off');
        set(handles.angle1AccelUbText,'Enable','off');
    end


function angle1AccelLbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle1AccelLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle1AccelLbText as text
%        str2double(get(hObject,'String')) returns contents of angle1AccelLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle1AccelLbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle1AccelLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle1AccelUbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle1AccelUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle1AccelUbText as text
%        str2double(get(hObject,'String')) returns contents of angle1AccelUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle1AccelUbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle1AccelUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle3AccelUbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle3AccelUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle3AccelUbText as text
%        str2double(get(hObject,'String')) returns contents of angle3AccelUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle3AccelUbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle3AccelUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle3AccelLbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle3AccelLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle3AccelLbText as text
%        str2double(get(hObject,'String')) returns contents of angle3AccelLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle3AccelLbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle3AccelLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in angle3AccelOptCheckbox.
function angle3AccelOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to angle3AccelOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of angle3AccelOptCheckbox
    if(get(hObject,'Value')==1)
        set(handles.angle3AccelLbText,'Enable','on');
        set(handles.angle3AccelUbText,'Enable','on');
    else
        set(handles.angle3AccelLbText,'Enable','off');
        set(handles.angle3AccelUbText,'Enable','off');
    end


function angle3LinUbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle3LinUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle3LinUbText as text
%        str2double(get(hObject,'String')) returns contents of angle3LinUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle3LinUbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle3LinUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle3LinLbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle3LinLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle3LinLbText as text
%        str2double(get(hObject,'String')) returns contents of angle3LinLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle3LinLbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle3LinLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in angle3LinOptCheckbox.
function angle3LinOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to angle3LinOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of angle3LinOptCheckbox
    if(get(hObject,'Value')==1)
        set(handles.angle3LinLbText,'Enable','on');
        set(handles.angle3LinUbText,'Enable','on');
    else
        set(handles.angle3LinLbText,'Enable','off');
        set(handles.angle3LinUbText,'Enable','off');
    end


function angle3ConstUbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle3ConstUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle3ConstUbText as text
%        str2double(get(hObject,'String')) returns contents of angle3ConstUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle3ConstUbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle3ConstUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle3ConstLbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle3ConstLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle3ConstLbText as text
%        str2double(get(hObject,'String')) returns contents of angle3ConstLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle3ConstLbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle3ConstLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in angle3ConstOptCheckbox.
function angle3ConstOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to angle3ConstOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of angle3ConstOptCheckbox
    if(get(hObject,'Value')==1)
        set(handles.angle3ConstLbText,'Enable','on');
        set(handles.angle3ConstUbText,'Enable','on');
    else
        set(handles.angle3ConstLbText,'Enable','off');
        set(handles.angle3ConstUbText,'Enable','off');
    end


function angle3AccelTermText_Callback(hObject, eventdata, handles)
% hObject    handle to angle3AccelTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle3AccelTermText as text
%        str2double(get(hObject,'String')) returns contents of angle3AccelTermText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle3AccelTermText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle3AccelTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle3LinTermText_Callback(hObject, eventdata, handles)
% hObject    handle to angle3LinTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle3LinTermText as text
%        str2double(get(hObject,'String')) returns contents of angle3LinTermText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle3LinTermText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle3LinTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle3ConstTermText_Callback(hObject, eventdata, handles)
% hObject    handle to angle3ConstTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle3ConstTermText as text
%        str2double(get(hObject,'String')) returns contents of angle3ConstTermText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle3ConstTermText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle3ConstTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle2ATermText_Callback(hObject, eventdata, handles)
% hObject    handle to angle2ATermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle2ATermText as text
%        str2double(get(hObject,'String')) returns contents of angle2ATermText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle2ATermText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle2ATermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle2ADotTermText_Callback(hObject, eventdata, handles)
% hObject    handle to angle2ADotTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle2ADotTermText as text
%        str2double(get(hObject,'String')) returns contents of angle2ADotTermText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle2ADotTermText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle2ADotTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle2BTermText_Callback(hObject, eventdata, handles)
% hObject    handle to angle2BTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle2BTermText as text
%        str2double(get(hObject,'String')) returns contents of angle2BTermText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle2BTermText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle2BTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in angle2AOptCheckbox.
function angle2AOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to angle2AOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of angle2AOptCheckbox
    if(get(hObject,'Value')==1)
        set(handles.angle2ALbText,'Enable','on');
        set(handles.angle2AUbText,'Enable','on');
    else
        set(handles.angle2ALbText,'Enable','off');
        set(handles.angle2AUbText,'Enable','off');
    end


function angle2ALbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle2ALbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle2ALbText as text
%        str2double(get(hObject,'String')) returns contents of angle2ALbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle2ALbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle2ALbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle2AUbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle2AUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle2AUbText as text
%        str2double(get(hObject,'String')) returns contents of angle2AUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle2AUbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle2AUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in angle2ADotOptCheckbox.
function angle2ADotOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to angle2ADotOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of angle2ADotOptCheckbox
    if(get(hObject,'Value')==1)
        set(handles.angle2ADotLbText,'Enable','on');
        set(handles.angle2ADotUbText,'Enable','on');
    else
        set(handles.angle2ADotLbText,'Enable','off');
        set(handles.angle2ADotUbText,'Enable','off');
    end


function angle2ADotLbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle2ADotLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle2ADotLbText as text
%        str2double(get(hObject,'String')) returns contents of angle2ADotLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle2ADotLbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle2ADotLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle2ADotUbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle2ADotUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle2ADotUbText as text
%        str2double(get(hObject,'String')) returns contents of angle2ADotUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle2ADotUbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle2ADotUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in angle2BOptCheckbox.
function angle2BOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to angle2BOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of angle2BOptCheckbox
    if(get(hObject,'Value')==1)
        set(handles.angle2BLbText,'Enable','on');
        set(handles.angle2BUbText,'Enable','on');
    else
        set(handles.angle2BLbText,'Enable','off');
        set(handles.angle2BUbText,'Enable','off');
    end


function angle2BLbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle2BLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle2BLbText as text
%        str2double(get(hObject,'String')) returns contents of angle2BLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle2BLbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle2BLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle2BUbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle2BUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle2BUbText as text
%        str2double(get(hObject,'String')) returns contents of angle2BUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle2BUbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle2BUbText (see GCBO)
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
        uiresume(handles.lvd_EditActionSetLinearTangentSteeringModelGUI);
    else
        msgbox(errMsg,'Errors were found while editing the steering model.','error');
    end
    

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditActionSetLinearTangentSteeringModelGUI);


% --- Executes on selection change in steeringModelTypeCombo.
function steeringModelTypeCombo_Callback(hObject, eventdata, handles)
% hObject    handle to steeringModelTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns steeringModelTypeCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from steeringModelTypeCombo
    indFromCombo = get(handles.steeringModelTypeCombo,'Value');

    [m,~] = enumeration('SteeringModelEnum');
    steeringModel = eval(sprintf('%s.getDefaultSteeringModel()', m(indFromCombo).classNameStr));

    [angle1Name, angle2Name, angle3Name] = steeringModel.getAngleNames();
    set(handles.angle1Panel,'Title',sprintf('%s', angle1Name));
    set(handles.angle2Panel,'Title',sprintf('%s', angle2Name));
    set(handles.angle3Panel,'Title',sprintf('%s', angle3Name));
    
    if(steeringModel.usesRefFrame())
        handles.baseFrameCombo.Enable = 'on';
    else
        handles.baseFrameCombo.Enable = 'off';
    end
    
    if(steeringModel.usesControlFrame())
        handles.controlFrameCombo.Enable = 'on';        
    else
        handles.controlFrameCombo.Enable = 'off';
    end
    
% --- Executes during object creation, after setting all properties.
function steeringModelTypeCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to steeringModelTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in angleContCheckbox.
function angleContCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to angleContCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of angleContCheckbox
    if(get(hObject,'Value'))
        %angle constants
        handles.angle1ConstTermText.Enable = 'off';
        handles.angle2BTermText.Enable = 'off';
        handles.angle3ConstTermText.Enable = 'off';
        
        handles.angle1ConstOptCheckbox.Enable = 'off';
        handles.angle2BOptCheckbox.Enable = 'off';
        handles.angle3ConstOptCheckbox.Enable = 'off';
        
        handles.angle1ConstOptCheckbox.Value = 0;
        handles.angle2BOptCheckbox.Value = 0;
        handles.angle3ConstOptCheckbox.Value = 0;
                
        angle1ConstOptCheckbox_Callback(handles.angle1ConstOptCheckbox, [], handles);
        angle2BOptCheckbox_Callback(handles.angle2BOptCheckbox, [], handles);
        angle3ConstOptCheckbox_Callback(handles.angle3ConstOptCheckbox, [], handles);
        
        %time offset
        handles.timeOffsetText.Enable = 'off';        
        handles.timeOffsetConstOptCheckbox.Enable = 'off';
        handles.timeOffsetConstOptCheckbox.Value = 0;
        
        timeOffsetConstOptCheckbox_Callback(handles.timeOffsetConstOptCheckbox, [], handles);
    else
        %angle constants
        handles.angle1ConstTermText.Enable = 'on';
        handles.angle2BTermText.Enable = 'on';
        handles.angle3ConstTermText.Enable = 'on';
        
        handles.angle1ConstOptCheckbox.Enable = 'on';
        handles.angle2BOptCheckbox.Enable = 'on';
        handles.angle3ConstOptCheckbox.Enable = 'on';

        angle1ConstOptCheckbox_Callback(handles.angle1ConstOptCheckbox, [], handles);
        angle2BOptCheckbox_Callback(handles.angle2BOptCheckbox, [], handles);
        angle3ConstOptCheckbox_Callback(handles.angle3ConstOptCheckbox, [], handles);
        
        %time offset
        handles.timeOffsetText.Enable = 'on';        
        handles.timeOffsetConstOptCheckbox.Enable = 'on';
        
        timeOffsetConstOptCheckbox_Callback(handles.timeOffsetConstOptCheckbox, [], handles);
    end
    


% --- Executes on key press with focus on lvd_EditActionSetLinearTangentSteeringModelGUI or any of its controls.
function lvd_EditActionSetLinearTangentSteeringModelGUI_WindowKeyPressFn(hObject, eventdata, handles)
% hObject    handle to lvd_EditActionSetLinearTangentSteeringModelGUI (see GCBO)
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
            close(handles.lvd_EditActionSetLinearTangentSteeringModelGUI);
    end

    
function bodyInfo = getSelectedBodyInfo(handles)
    baseFrame = getappdata(handles.lvd_EditActionSetLinearTangentSteeringModelGUI,'baseFrame');
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
    
    setappdata(handles.lvd_EditActionSetLinearTangentSteeringModelGUI, 'baseFrame', newFrame);

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
    baseFrame = getappdata(handles.lvd_EditActionSetLinearTangentSteeringModelGUI, 'baseFrame');
    newFrame = baseFrame.editFrameDialogUI();
    
    setappdata(handles.lvd_EditActionSetLinearTangentSteeringModelGUI, 'baseFrame', newFrame);

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



function angle2BDotTermText_Callback(hObject, eventdata, handles)
% hObject    handle to angle2BDotTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle2BDotTermText as text
%        str2double(get(hObject,'String')) returns contents of angle2BDotTermText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle2BDotTermText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle2BDotTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in angle2BDotOptCheckbox.
function angle2BDotOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to angle2BDotOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of angle2BDotOptCheckbox
    if(get(hObject,'Value')==1)
        set(handles.angle2BDotLbText,'Enable','on');
        set(handles.angle2BDotUbText,'Enable','on');
    else
        set(handles.angle2BDotLbText,'Enable','off');
        set(handles.angle2BDotUbText,'Enable','off');
    end


function angle2BDotLbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle2BDotLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle2BDotLbText as text
%        str2double(get(hObject,'String')) returns contents of angle2BDotLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle2BDotLbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle2BDotLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle2BDotUbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle2BDotUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle2BDotUbText as text
%        str2double(get(hObject,'String')) returns contents of angle2BDotUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle2BDotUbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle2BDotUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function timeOffsetText_Callback(hObject, eventdata, handles)
% hObject    handle to timeOffsetText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of timeOffsetText as text
%        str2double(get(hObject,'String')) returns contents of timeOffsetText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function timeOffsetText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timeOffsetText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in timeOffsetConstOptCheckbox.
function timeOffsetConstOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to timeOffsetConstOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of timeOffsetConstOptCheckbox
    if(get(hObject,'Value')==1)
        set(handles.timeOffsetConstLbText,'Enable','on');
        set(handles.timeOffsetConstUbText,'Enable','on');
    else
        set(handles.timeOffsetConstLbText,'Enable','off');
        set(handles.timeOffsetConstUbText,'Enable','off');
    end


function timeOffsetConstLbText_Callback(hObject, eventdata, handles)
% hObject    handle to timeOffsetConstLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of timeOffsetConstLbText as text
%        str2double(get(hObject,'String')) returns contents of timeOffsetConstLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function timeOffsetConstLbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timeOffsetConstLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function timeOffsetConstUbText_Callback(hObject, eventdata, handles)
% hObject    handle to timeOffsetConstUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of timeOffsetConstUbText as text
%        str2double(get(hObject,'String')) returns contents of timeOffsetConstUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function timeOffsetConstUbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timeOffsetConstUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
