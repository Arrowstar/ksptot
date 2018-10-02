function varargout = lvd_EditActionSetSteeringModelGUI(varargin)
% LVD_EDITACTIONSETSTEERINGMODELGUI MATLAB code for lvd_EditActionSetSteeringModelGUI.fig
%      LVD_EDITACTIONSETSTEERINGMODELGUI, by itself, creates a new LVD_EDITACTIONSETSTEERINGMODELGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITACTIONSETSTEERINGMODELGUI returns the handle to a new LVD_EDITACTIONSETSTEERINGMODELGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITACTIONSETSTEERINGMODELGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITACTIONSETSTEERINGMODELGUI.M with the given input arguments.
%
%      LVD_EDITACTIONSETSTEERINGMODELGUI('Property','Value',...) creates a new LVD_EDITACTIONSETSTEERINGMODELGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditActionSetSteeringModelGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditActionSetSteeringModelGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditActionSetSteeringModelGUI

% Last Modified by GUIDE v2.5 24-Sep-2018 17:36:47

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditActionSetSteeringModelGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditActionSetSteeringModelGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditActionSetSteeringModelGUI is made visible.
function lvd_EditActionSetSteeringModelGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditActionSetSteeringModelGUI (see VARARGIN)

    % Choose default command line output for lvd_EditActionSetSteeringModelGUI
    handles.output = hObject;

    action = varargin{1};
    setappdata(hObject,'action',action);
    
    lv = varargin{2};
    setappdata(hObject,'lv',lv);
    
    populateGUI(handles, action, lv);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditActionSetSteeringModelGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditActionSetSteeringModelGUI);


function populateGUI(handles, action, lv)
    steeringModel = action.steeringModel;
    
    [angle1Name, angle2Name, angle3Name] = steeringModel.getAngleNames();
    set(handles.angle1Panel,'Title',sprintf('%s Angle', angle1Name));
    set(handles.angle2Panel,'Title',sprintf('%s Angle', angle2Name));
    set(handles.angle3Panel,'Title',sprintf('%s Angle', angle3Name));
    
    strs = SteeringModelEnum.getSteeringModelTypeNameStrs();
    set(handles.steeringModelTypeCombo,'String',strs);
    ind = SteeringModelEnum.getIndOfListboxStrsForSteeringModel(steeringModel);
    set(handles.steeringModelTypeCombo,'Value',ind);
    
    [angleModel, ~] = steeringModel.getAngleNModel(1);
    set(handles.angle1ConstTermText,'String',fullAccNum2Str(rad2deg(angleModel.constTerm)));
    set(handles.angle1LinTermText,'String',fullAccNum2Str(rad2deg(angleModel.linearTerm)));
    set(handles.angle1AccelTermText,'String',fullAccNum2Str(rad2deg(angleModel.accelTerm)));
    
    [angleModel, ~] = steeringModel.getAngleNModel(2);
    set(handles.angle2ConstTermText,'String',fullAccNum2Str(rad2deg(angleModel.constTerm)));
    set(handles.angle2LinTermText,'String',fullAccNum2Str(rad2deg(angleModel.linearTerm)));
    set(handles.angle2AccelTermText,'String',fullAccNum2Str(rad2deg(angleModel.accelTerm)));
    
    [angleModel, ~] = steeringModel.getAngleNModel(3);
    set(handles.angle3ConstTermText,'String',fullAccNum2Str(rad2deg(angleModel.constTerm)));
    set(handles.angle3LinTermText,'String',fullAccNum2Str(rad2deg(angleModel.linearTerm)));
    set(handles.angle3AccelTermText,'String',fullAccNum2Str(rad2deg(angleModel.accelTerm)));
    
    [contTf1,contTf2,contTf3] = steeringModel.getContinuityTerms();
    contTf = any([contTf1,contTf2,contTf3]);
    handles.angleContCheckbox.Value = double(contTf);
    angleContCheckbox_Callback(handles.angleContCheckbox, [], handles);
    
    optVar = steeringModel.getExistingOptVar();
    if(isempty(optVar))
        useTf = false([1,9]);
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
    
    set(handles.angle2ConstOptCheckbox,'Value',(useTf(4)));
    set(handles.angle2LinOptCheckbox,'Value',(useTf(5)));
    set(handles.angle2AccelOptCheckbox,'Value',(useTf(6)));

    set(handles.angle3ConstOptCheckbox,'Value',(useTf(7)));
    set(handles.angle3LinOptCheckbox,'Value',(useTf(8)));
    set(handles.angle3AccelOptCheckbox,'Value',(useTf(9)));
    
    angle1ConstOptCheckbox_Callback(handles.angle1ConstOptCheckbox, [], handles);
    angle2ConstOptCheckbox_Callback(handles.angle2ConstOptCheckbox, [], handles);
    angle3ConstOptCheckbox_Callback(handles.angle3ConstOptCheckbox, [], handles);
    
    angle1LinOptCheckbox_Callback(handles.angle1LinOptCheckbox, [], handles);
    angle2LinOptCheckbox_Callback(handles.angle2LinOptCheckbox, [], handles);
    angle3LinOptCheckbox_Callback(handles.angle3LinOptCheckbox, [], handles);
    
    angle1AccelOptCheckbox_Callback(handles.angle1AccelOptCheckbox, [], handles);
    angle2AccelOptCheckbox_Callback(handles.angle2AccelOptCheckbox, [], handles);
    angle3AccelOptCheckbox_Callback(handles.angle3AccelOptCheckbox, [], handles);
    
%     lb = zeros(size(useTf));
%     lb(useTf) = lbTemp;
%     
%     ub = zeros(size(useTf));
%     ub(useTf) = ubTemp;
    
    %LB
    set(handles.angle1ConstLbText,'String',fullAccNum2Str(rad2deg(lb(1))));
    set(handles.angle1LinLbText,'String',fullAccNum2Str(rad2deg(lb(2))));
    set(handles.angle1AccelLbText,'String',fullAccNum2Str(rad2deg(lb(3))));
    
    set(handles.angle2ConstLbText,'String',fullAccNum2Str(rad2deg(lb(4))));
    set(handles.angle2LinLbText,'String',fullAccNum2Str(rad2deg(lb(5))));
    set(handles.angle2AccelLbText,'String',fullAccNum2Str(rad2deg(lb(6))));
    
    set(handles.angle3ConstLbText,'String',fullAccNum2Str(rad2deg(lb(7))));
    set(handles.angle3LinLbText,'String',fullAccNum2Str(rad2deg(lb(8))));
    set(handles.angle3AccelLbText,'String',fullAccNum2Str(rad2deg(lb(9))));
    
    %UB
    set(handles.angle1ConstUbText,'String',fullAccNum2Str(rad2deg(ub(1))));
    set(handles.angle1LinUbText,'String',fullAccNum2Str(rad2deg(ub(2))));
    set(handles.angle1AccelUbText,'String',fullAccNum2Str(rad2deg(ub(3))));
    
    set(handles.angle2ConstUbText,'String',fullAccNum2Str(rad2deg(ub(4))));
    set(handles.angle2LinUbText,'String',fullAccNum2Str(rad2deg(ub(5))));
    set(handles.angle2AccelUbText,'String',fullAccNum2Str(rad2deg(ub(6))));
    
    set(handles.angle3ConstUbText,'String',fullAccNum2Str(rad2deg(ub(7))));
    set(handles.angle3LinUbText,'String',fullAccNum2Str(rad2deg(ub(8))));
    set(handles.angle3AccelUbText,'String',fullAccNum2Str(rad2deg(ub(9))));
    
    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditActionSetSteeringModelGUI_OutputFcn(hObject, eventdata, handles) 
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
        ind = SteeringModelEnum.getIndOfListboxStrsForSteeringModel(steeringModel);
        indFromCombo = get(handles.steeringModelTypeCombo,'Value');
        
        optVar = steeringModel.getExistingOptVar();
        if(ind ~= indFromCombo)
            if(not(isempty(optVar))) %need to remove existing var if it exists
                lvdData.optimizer.vars.removeVariable(optVar);
            end
            
            [m,~] = enumeration('SteeringModelEnum');
            steeringModel = eval(sprintf('%s.getDefaultSteeringModel()', m(indFromCombo).classNameStr));
            action.steeringModel = steeringModel;
        end
        
        %Set Steering Terms
        angle1Const = deg2rad(str2double(get(handles.angle1ConstTermText,'String')));
        angle1Linear = deg2rad(str2double(get(handles.angle1LinTermText,'String')));
        angle1Accel = deg2rad(str2double(get(handles.angle1AccelTermText,'String')));

        angle2Const = deg2rad(str2double(get(handles.angle2ConstTermText,'String')));
        angle2Linear = deg2rad(str2double(get(handles.angle2LinTermText,'String')));
        angle2Accel = deg2rad(strar2double(get(handles.angle2AccelTermText,'String')));
        
        angle3Const = deg2rad(str2double(get(handles.angle3ConstTermText,'String')));
        angle3Linear = deg2rad(str2double(get(handles.angle3LinTermText,'String')));
        angle3Accel = deg2rad(str2double(get(handles.angle3AccelTermText,'String')));
        
        steeringModel.setConstTerms(angle1Const, angle2Const, angle3Const);
        steeringModel.setLinearTerms(angle1Linear, angle2Linear, angle3Linear);
        steeringModel.setAccelTerms(angle1Accel, angle2Accel, angle3Accel);
        
        contTf = logical(handles.angleContCheckbox.Value);
        steeringModel.setContinuityTerms(contTf,contTf,contTf);
        
        %Set Opt T/F
        useTf(1) = get(handles.angle1ConstOptCheckbox,'Value');
        useTf(2) = get(handles.angle1LinOptCheckbox,'Value');
        useTf(3) = get(handles.angle1AccelOptCheckbox,'Value');

        useTf(4) = get(handles.angle2ConstOptCheckbox,'Value');
        useTf(5) = get(handles.angle2LinOptCheckbox,'Value');
        useTf(6) = get(handles.angle2AccelOptCheckbox,'Value');

        useTf(7) = get(handles.angle3ConstOptCheckbox,'Value');
        useTf(8) = get(handles.angle3LinOptCheckbox,'Value');
        useTf(9) = get(handles.angle3AccelOptCheckbox,'Value');
        
        if(isempty(optVar))
            optVar = steeringModel.getNewOptVar();
        end
        
        optVar.setUseTfForVariable(useTf);
        
        %UB
        lb(1) = deg2rad(str2double(get(handles.angle1ConstLbText,'String')));
        lb(2) = deg2rad(str2double(get(handles.angle1LinLbText,'String')));
        lb(3) = deg2rad(str2double(get(handles.angle1AccelLbText,'String')));

        lb(4) = deg2rad(str2double(get(handles.angle2ConstLbText,'String')));
        lb(5) = deg2rad(str2double(get(handles.angle2LinLbText,'String')));
        lb(6) = deg2rad(str2double(get(handles.angle2AccelLbText,'String')));

        lb(7) = deg2rad(str2double(get(handles.angle3ConstLbText,'String')));
        lb(8) = deg2rad(str2double(get(handles.angle3LinLbText,'String')));
        lb(9) = deg2rad(str2double(get(handles.angle3AccelLbText,'String')));
        
        
        ub(1) = deg2rad(str2double(get(handles.angle1ConstUbText,'String')));
        ub(2) = deg2rad(str2double(get(handles.angle1LinUbText,'String')));
        ub(3) = deg2rad(str2double(get(handles.angle1AccelUbText,'String')));

        ub(4) = deg2rad(str2double(get(handles.angle2ConstUbText,'String')));
        ub(5) = deg2rad(str2double(get(handles.angle2LinUbText,'String')));
        ub(6) = deg2rad(str2double(get(handles.angle2AccelUbText,'String')));

        ub(7) = deg2rad(str2double(get(handles.angle3ConstUbText,'String')));
        ub(8) = deg2rad(str2double(get(handles.angle3LinUbText,'String')));
        ub(9) = deg2rad(str2double(get(handles.angle3AccelUbText,'String')));
        
        optVar.setUseTfForVariable(true(size(lb))); %need this to get the full lb/set in there
        optVar.setBndsForVariable(lb, ub);
        optVar.setUseTfForVariable(useTf);
               
        lvdData.optimizer.vars.addVariable(optVar);
        
        varargout{1} = true;
        close(handles.lvd_EditActionSetSteeringModelGUI);
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    action = getappdata(handles.lvd_EditActionSetSteeringModelGUI,'action');
    [angle1Name, angle2Name, angle3Name] = action.steeringModel.getAngleNames();
    
    %Angle 1
    angle1Const = str2double(get(handles.angle1ConstTermText,'String'));
    enteredStr = get(handles.angle1ConstTermText,'String');
    numberName = sprintf('%s Angle Constant Term', angle1Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1Const, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle1Linear = str2double(get(handles.angle1LinTermText,'String'));
    enteredStr = get(handles.angle1LinTermText,'String');
    numberName = sprintf('%s Angle Linear Term', angle1Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1Linear, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle1Accel = str2double(get(handles.angle1AccelTermText,'String'));
    enteredStr = get(handles.angle1AccelTermText,'String');
    numberName = sprintf('%s Angle Acceleration Term', angle1Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1Accel, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Angle 2
    angle2Const = str2double(get(handles.angle2ConstTermText,'String'));
    enteredStr = get(handles.angle2ConstTermText,'String');
    numberName = sprintf('%s Angle Constant Term', angle2Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle2Const, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle2Linear = str2double(get(handles.angle2LinTermText,'String'));
    enteredStr = get(handles.angle2LinTermText,'String');
    numberName = sprintf('%s Angle Linear Term', angle2Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle2Linear, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle2Accel = str2double(get(handles.angle2AccelTermText,'String'));
    enteredStr = get(handles.angle2AccelTermText,'String');
    numberName = sprintf('%s Angle Acceleration Term', angle2Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle2Accel, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Angle 3
    angle3Const = str2double(get(handles.angle3ConstTermText,'String'));
    enteredStr = get(handles.angle3ConstTermText,'String');
    numberName = sprintf('%s Angle Constant Term', angle3Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle3Const, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle3Linear = str2double(get(handles.angle3LinTermText,'String'));
    enteredStr = get(handles.angle3LinTermText,'String');
    numberName = sprintf('%s Angle Linear Term', angle3Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle3Linear, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle3Accel = str2double(get(handles.angle3AccelTermText,'String'));
    enteredStr = get(handles.angle3AccelTermText,'String');
    numberName = sprintf('%s Angle Acceleration Term', angle3Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle3Accel, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %%%%%Bounds
    %Angle 1 Const
    angle1ConstLB = str2double(get(handles.angle1ConstLbText,'String'));
    enteredStr = get(handles.angle1ConstLbText,'String');
    numberName = sprintf('%s Angle Constant Term Lower Bound', angle1Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1ConstLB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle1ConstUB = str2double(get(handles.angle1ConstUbText,'String'));
    enteredStr = get(handles.angle1ConstUbText,'String');
    numberName = sprintf('%s Angle Constant Term Upper Bound', angle1Name);
    lb = angle1ConstLB;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1ConstUB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Angle 1 Linear
    angle1LinearLB = str2double(get(handles.angle1LinLbText,'String'));
    enteredStr = get(handles.angle1LinLbText,'String');
    numberName = sprintf('%s Angle Linear Term Lower Bound', angle1Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1LinearLB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle1LinearUB = str2double(get(handles.angle1LinUbText,'String'));
    enteredStr = get(handles.angle1LinUbText,'String');
    numberName = sprintf('%s Angle Linear Term Upper Bound', angle1Name);
    lb = angle1LinearLB;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1LinearUB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Angle 1 Accel
    angle1AccelLB = str2double(get(handles.angle1AccelLbText,'String'));
    enteredStr = get(handles.angle1AccelLbText,'String');
    numberName = sprintf('%s Angle Acceleration Term Lower Bound', angle1Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1AccelLB, numberName, lb, ub, isInt, errMsg, enteredStr);

    angle1AccelUB = str2double(get(handles.angle1AccelUbText,'String'));
    enteredStr = get(handles.angle1AccelUbText,'String');
    numberName = sprintf('%s Angle Acceleration Term Upper Bound', angle1Name);
    lb = angle1AccelLB;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle1AccelUB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Angle 2 Const
    angle2ConstLB = str2double(get(handles.angle2ConstLbText,'String'));
    enteredStr = get(handles.angle2ConstLbText,'String');
    numberName = sprintf('%s Angle Constant Term Lower Bound', angle2Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle2ConstLB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle2ConstUB = str2double(get(handles.angle2ConstUbText,'String'));
    enteredStr = get(handles.angle2ConstUbText,'String');
    numberName = sprintf('%s Angle Constant Term Upper Bound', angle2Name);
    lb = angle2ConstLB;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle2ConstUB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Angle 2 Linear
    angle2LinearLB = str2double(get(handles.angle2LinLbText,'String'));
    enteredStr = get(handles.angle2LinLbText,'String');
    numberName = sprintf('%s Angle Linear Term Lower Bound', angle2Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle2LinearLB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle2LinearUB = str2double(get(handles.angle2LinUbText,'String'));
    enteredStr = get(handles.angle2LinUbText,'String');
    numberName = sprintf('%s Angle Linear Term Upper Bound', angle2Name);
    lb = angle2LinearLB;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle2LinearUB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Angle 2 Accel
    angle2AccelLB = str2double(get(handles.angle2AccelLbText,'String'));
    enteredStr = get(handles.angle2AccelLbText,'String');
    numberName = sprintf('%s Angle Acceleration Term Lower Bound', angle2Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle2AccelLB, numberName, lb, ub, isInt, errMsg, enteredStr);

    angle2AccelUB = str2double(get(handles.angle1AccelUbText,'String'));
    enteredStr = get(handles.angle1AccelUbText,'String');
    numberName = sprintf('%s Angle Acceleration Term Upper Bound', angle1Name);
    lb = angle2AccelLB;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle2AccelUB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Angle 3 Const
    angle3ConstLB = str2double(get(handles.angle3ConstLbText,'String'));
    enteredStr = get(handles.angle3ConstLbText,'String');
    numberName = sprintf('%s Angle Constant Term Lower Bound', angle3Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle3ConstLB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle3ConstUB = str2double(get(handles.angle3ConstUbText,'String'));
    enteredStr = get(handles.angle3ConstUbText,'String');
    numberName = sprintf('%s Angle Constant Term Upper Bound', angle3Name);
    lb = angle3ConstLB;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle3ConstUB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Angle 2 Linear
    angle3LinearLB = str2double(get(handles.angle3LinLbText,'String'));
    enteredStr = get(handles.angle3LinLbText,'String');
    numberName = sprintf('%s Angle Linear Term Lower Bound', angle3Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle3LinearLB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    angle3LinearUB = str2double(get(handles.angle3LinUbText,'String'));
    enteredStr = get(handles.angle3LinUbText,'String');
    numberName = sprintf('%s Angle Linear Term Upper Bound', angle3Name);
    lb = angle3LinearLB;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle3LinearUB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    %Angle 2 Accel
    angle3AccelLB = str2double(get(handles.angle3AccelLbText,'String'));
    enteredStr = get(handles.angle3AccelLbText,'String');
    numberName = sprintf('%s Angle Acceleration Term Lower Bound', angle3Name);
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle3AccelLB, numberName, lb, ub, isInt, errMsg, enteredStr);

    angle3AccelUB = str2double(get(handles.angle3AccelUbText,'String'));
    enteredStr = get(handles.angle3AccelUbText,'String');
    numberName = sprintf('%s Angle Acceleration Term Upper Bound', angle3Name);
    lb = angle3AccelLB;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(angle3AccelUB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    

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



function angle2ConstTermText_Callback(hObject, eventdata, handles)
% hObject    handle to angle2ConstTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle2ConstTermText as text
%        str2double(get(hObject,'String')) returns contents of angle2ConstTermText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle2ConstTermText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle2ConstTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle2LinTermText_Callback(hObject, eventdata, handles)
% hObject    handle to angle2LinTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle2LinTermText as text
%        str2double(get(hObject,'String')) returns contents of angle2LinTermText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle2LinTermText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle2LinTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle2AccelTermText_Callback(hObject, eventdata, handles)
% hObject    handle to angle2AccelTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle2AccelTermText as text
%        str2double(get(hObject,'String')) returns contents of angle2AccelTermText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle2AccelTermText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle2AccelTermText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in angle2ConstOptCheckbox.
function angle2ConstOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to angle2ConstOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of angle2ConstOptCheckbox
    if(get(hObject,'Value')==1)
        set(handles.angle2ConstLbText,'Enable','on');
        set(handles.angle2ConstUbText,'Enable','on');
    else
        set(handles.angle2ConstLbText,'Enable','off');
        set(handles.angle2ConstUbText,'Enable','off');
    end


function angle2ConstLbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle2ConstLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle2ConstLbText as text
%        str2double(get(hObject,'String')) returns contents of angle2ConstLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle2ConstLbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle2ConstLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle2ConstUbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle2ConstUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle2ConstUbText as text
%        str2double(get(hObject,'String')) returns contents of angle2ConstUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle2ConstUbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle2ConstUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in angle2LinOptCheckbox.
function angle2LinOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to angle2LinOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of angle2LinOptCheckbox
    if(get(hObject,'Value')==1)
        set(handles.angle2LinLbText,'Enable','on');
        set(handles.angle2LinUbText,'Enable','on');
    else
        set(handles.angle2LinLbText,'Enable','off');
        set(handles.angle2LinUbText,'Enable','off');
    end


function angle2LinLbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle2LinLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle2LinLbText as text
%        str2double(get(hObject,'String')) returns contents of angle2LinLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle2LinLbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle2LinLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle2LinUbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle2LinUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle2LinUbText as text
%        str2double(get(hObject,'String')) returns contents of angle2LinUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle2LinUbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle2LinUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in angle2AccelOptCheckbox.
function angle2AccelOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to angle2AccelOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of angle2AccelOptCheckbox
    if(get(hObject,'Value')==1)
        set(handles.angle2AccelLbText,'Enable','on');
        set(handles.angle2AccelUbText,'Enable','on');
    else
        set(handles.angle2AccelLbText,'Enable','off');
        set(handles.angle2AccelUbText,'Enable','off');
    end


function angle2AccelLbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle2AccelLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle2AccelLbText as text
%        str2double(get(hObject,'String')) returns contents of angle2AccelLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle2AccelLbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle2AccelLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angle2AccelUbText_Callback(hObject, eventdata, handles)
% hObject    handle to angle2AccelUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angle2AccelUbText as text
%        str2double(get(hObject,'String')) returns contents of angle2AccelUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function angle2AccelUbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle2AccelUbText (see GCBO)
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
        uiresume(handles.lvd_EditActionSetSteeringModelGUI);
    else
        msgbox(errMsg,'Errors were found while editing the steering model.','error');
    end
    

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditActionSetSteeringModelGUI);


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
    set(handles.angle1Panel,'Title',sprintf('%s Angle', angle1Name));
    set(handles.angle2Panel,'Title',sprintf('%s Angle', angle2Name));
    set(handles.angle3Panel,'Title',sprintf('%s Angle', angle3Name));
    
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
        handles.angle1ConstTermText.Enable = 'off';
        handles.angle2ConstTermText.Enable = 'off';
        handles.angle3ConstTermText.Enable = 'off';
        
        handles.angle1ConstOptCheckbox.Enable = 'off';
        handles.angle2ConstOptCheckbox.Enable = 'off';
        handles.angle3ConstOptCheckbox.Enable = 'off';
        
        handles.angle1ConstOptCheckbox.Value = 0;
        handles.angle2ConstOptCheckbox.Value = 0;
        handles.angle3ConstOptCheckbox.Value = 0;
                
        angle1ConstOptCheckbox_Callback(handles.angle1ConstOptCheckbox, [], handles);
        angle2ConstOptCheckbox_Callback(handles.angle2ConstOptCheckbox, [], handles);
        angle3ConstOptCheckbox_Callback(handles.angle3ConstOptCheckbox, [], handles);
    else
        handles.angle1ConstTermText.Enable = 'on';
        handles.angle2ConstTermText.Enable = 'on';
        handles.angle3ConstTermText.Enable = 'on';
        
        handles.angle1ConstOptCheckbox.Enable = 'on';
        handles.angle2ConstOptCheckbox.Enable = 'on';
        handles.angle3ConstOptCheckbox.Enable = 'on';

        angle1ConstOptCheckbox_Callback(handles.angle1ConstOptCheckbox, [], handles);
        angle2ConstOptCheckbox_Callback(handles.angle2ConstOptCheckbox, [], handles);
        angle3ConstOptCheckbox_Callback(handles.angle3ConstOptCheckbox, [], handles);
    end
    
