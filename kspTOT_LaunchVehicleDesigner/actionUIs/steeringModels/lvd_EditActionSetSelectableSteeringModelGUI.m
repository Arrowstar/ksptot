function varargout = lvd_EditActionSetSelectableSteeringModelGUI(varargin)
% LVD_EDITACTIONSETSELECTABLESTEERINGMODELGUI MATLAB code for lvd_EditActionSetSelectableSteeringModelGUI.fig
%      LVD_EDITACTIONSETSELECTABLESTEERINGMODELGUI, by itself, creates a new LVD_EDITACTIONSETSELECTABLESTEERINGMODELGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITACTIONSETSELECTABLESTEERINGMODELGUI returns the handle to a new LVD_EDITACTIONSETSELECTABLESTEERINGMODELGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITACTIONSETSELECTABLESTEERINGMODELGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITACTIONSETSELECTABLESTEERINGMODELGUI.M with the given input arguments.
%
%      LVD_EDITACTIONSETSELECTABLESTEERINGMODELGUI('Property','Value',...) creates a new LVD_EDITACTIONSETSELECTABLESTEERINGMODELGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditActionSetSelectableSteeringModelGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditActionSetSelectableSteeringModelGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditActionSetSelectableSteeringModelGUI

% Last Modified by GUIDE v2.5 23-Apr-2021 15:53:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditActionSetSelectableSteeringModelGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditActionSetSelectableSteeringModelGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditActionSetSelectableSteeringModelGUI is made visible.
function lvd_EditActionSetSelectableSteeringModelGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditActionSetSelectableSteeringModelGUI (see VARARGIN)

    % Choose default command line output for lvd_EditActionSetSelectableSteeringModelGUI
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

    % UIWAIT makes lvd_EditActionSetSelectableSteeringModelGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditActionSetSelectableSteeringModelGUI);


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
    setappdata(handles.lvd_EditActionSetSelectableSteeringModelGUI, 'baseFrame', baseFrame);

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

    steeringMathModelsStr = SteerMathModelTypeEnum.getListBoxStr();
    
    gammaInd = SteerMathModelTypeEnum.getIndForName(steeringModel.gammaSelModel.name);
    handles.angle1ModelTypeCombo.String = steeringMathModelsStr;
    handles.angle1ModelTypeCombo.Value = gammaInd;
    
    betaInd = SteerMathModelTypeEnum.getIndForName(steeringModel.betaSelModel.name);
    handles.angle2ModelTypeCombo.String = steeringMathModelsStr;
    handles.angle2ModelTypeCombo.Value = betaInd;
    
    alphaInd = SteerMathModelTypeEnum.getIndForName(steeringModel.alphaSelModel.name);
    handles.angle3ModelTypeCombo.String = steeringMathModelsStr;
    handles.angle3ModelTypeCombo.Value = alphaInd;
    
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
        useTf = false([1,1]);
        lb = zeros(size(useTf));
        ub = zeros(size(useTf));
    else
        useTf = optVar.getUseTfForVariable();
        optVar.setUseTfForVariable(true(size(useTf)));
        [lb, ub] = optVar.getBndsForVariable();
        optVar.setUseTfForVariable(useTf);
    end
    
    set(handles.timeOffsetConstOptCheckbox,'Value',(useTf(1)));
       
    timeOffsetConstOptCheckbox_Callback(handles.timeOffsetConstOptCheckbox, [], handles);
        
    %LB
    set(handles.timeOffsetConstLbText,'String',fullAccNum2Str(lb(1)));
    
    %UB
    set(handles.timeOffsetConstUbText,'String',fullAccNum2Str(ub(1)));
    
    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditActionSetSelectableSteeringModelGUI_OutputFcn(hObject, eventdata, handles) 
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
        steeringModel.setTimeOffsets(timeOffset);

        contTf = logical(handles.angleContCheckbox.Value);
        steeringModel.setContinuityTerms(contTf,contTf,contTf);
        
        [~,enums] = SteerMathModelTypeEnum.getListBoxStr();
        steeringModel.gammaSelModel = enums(handles.angle1ModelTypeCombo.Value);
        steeringModel.betaSelModel = enums(handles.angle2ModelTypeCombo.Value);
        steeringModel.alphaSelModel = enums(handles.angle3ModelTypeCombo.Value);
        
        %Set Opt T/F       
        optVar = steeringModel.getNewOptVar();
        useTf = optVar.getUseTfForVariable();
        useTf(1) = logical(handles.timeOffsetConstOptCheckbox.Value);
        optVar.setUseTfForVariable(useTf);
        
        %Bounds
        [lb, ub] = optVar.getAllBndsForVariable();
        
        lb(1) = str2double(get(handles.timeOffsetConstLbText,'String'));
        ub(1) = str2double(get(handles.timeOffsetConstUbText,'String'));
        
        optVar.setBndsForVariable(lb, ub);
                       
        lvdData.optimizer.vars.addVariable(optVar);
        
        varargout{1} = true;
        close(handles.lvd_EditActionSetSelectableSteeringModelGUI);
    end


function errMsg = validateInputs(handles)
    errMsg = {};
       
    %Time offset
    timeOffset = str2double(get(handles.timeOffsetText,'String'));
    enteredStr = get(handles.timeOffsetText,'String');
    numberName = 'Time Offset';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(timeOffset, numberName, lb, ub, isInt, errMsg, enteredStr);
    
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
    


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);

    if(isempty(errMsg))
        uiresume(handles.lvd_EditActionSetSelectableSteeringModelGUI);
    else
        msgbox(errMsg,'Errors were found while editing the steering model.','error');
    end
    

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditActionSetSelectableSteeringModelGUI);


% % --- Executes on selection change in steeringModelTypeCombo.
% function steeringModelTypeCombo_Callback(hObject, eventdata, handles)
% % hObject    handle to steeringModelTypeCombo (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hints: contents = cellstr(get(hObject,'String')) returns steeringModelTypeCombo contents as cell array
% %        contents{get(hObject,'Value')} returns selected item from steeringModelTypeCombo
%     indFromCombo = get(handles.steeringModelTypeCombo,'Value');
% 
%     [m,~] = enumeration('SteeringModelEnum');
%     steeringModel = eval(sprintf('%s.getDefaultSteeringModel()', m(indFromCombo).classNameStr));
% 
%     [angle1Name, angle2Name, angle3Name] = steeringModel.getAngleNames();
%     set(handles.angle1Panel,'Title',sprintf('%s', angle1Name));
%     set(handles.angle2Panel,'Title',sprintf('%s', angle2Name));
%     set(handles.angle3Panel,'Title',sprintf('%s', angle3Name));
%     
%     if(steeringModel.usesRefFrame())
%         handles.baseFrameCombo.Enable = 'on';
%     else
%         handles.baseFrameCombo.Enable = 'off';
%     end
%     
%     if(steeringModel.usesControlFrame())
%         handles.controlFrameCombo.Enable = 'on';        
%     else
%         handles.controlFrameCombo.Enable = 'off';
%     end
    
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
        %time offset
        handles.timeOffsetText.Enable = 'off';        
        handles.timeOffsetConstOptCheckbox.Enable = 'off';
        handles.timeOffsetConstOptCheckbox.Value = 0;
        
        timeOffsetConstOptCheckbox_Callback(handles.timeOffsetConstOptCheckbox, [], handles);
    else
        %time offset
        handles.timeOffsetText.Enable = 'on';        
        handles.timeOffsetConstOptCheckbox.Enable = 'on';
        
        timeOffsetConstOptCheckbox_Callback(handles.timeOffsetConstOptCheckbox, [], handles);
    end
    


% --- Executes on key press with focus on lvd_EditActionSetSelectableSteeringModelGUI or any of its controls.
function lvd_EditActionSetLinearTangentSteeringModelGUI_WindowKeyPressFn(hObject, eventdata, handles)
% hObject    handle to lvd_EditActionSetSelectableSteeringModelGUI (see GCBO)
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
            close(handles.lvd_EditActionSetSelectableSteeringModelGUI);
    end

    
function bodyInfo = getSelectedBodyInfo(handles)
    baseFrame = getappdata(handles.lvd_EditActionSetSelectableSteeringModelGUI,'baseFrame');
    bodyInfo = baseFrame.getOriginBody();
    

% --- Executes on selection change in baseFrameCombo.
function baseFrameCombo_Callback(hObject, eventdata, handles)
% hObject    handle to baseFrameCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns baseFrameCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from baseFrameCombo
    lv = getappdata(handles.lvd_EditActionSetSelectableSteeringModelGUI,'lv');
    lvdData = lv.lvdData;

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
            
        case ReferenceFrameEnum.UserDefined
            numFrames = lvdData.geometry.refFrames.getNumRefFrames();
            if(numFrames >= 1)
                geometricFrame = lvdData.geometry.refFrames.getRefFrameAtInd(1);
                newFrame = UserDefinedGeometricFrame(geometricFrame, lvdData);
            else
                newFrame = bodyInfo.getBodyCenteredInertialFrame();
                warndlg('There are no geometric frames available.  A body-centered inertial frame will be selected instead.');
            end

        otherwise
            error('Unknown reference frame type: %s', string(refFrameEnum));                
    end
    
    if(not(isempty(newFrame)) && newFrame.typeEnum ~= refFrameEnum)
        refFrameEnum = newFrame.typeEnum;
        handles.baseFrameCombo.Value = ReferenceFrameEnum.getIndForName(refFrameEnum.name);
    end
    
    setappdata(handles.lvd_EditActionSetSelectableSteeringModelGUI, 'baseFrame', newFrame);

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
    baseFrame = getappdata(handles.lvd_EditActionSetSelectableSteeringModelGUI, 'baseFrame');
    newFrame = baseFrame.editFrameDialogUI(EditReferenceFrameContextEnum.ForSteering);
    
    setappdata(handles.lvd_EditActionSetSelectableSteeringModelGUI, 'baseFrame', newFrame);

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


% --- Executes on key press with focus on lvd_EditActionSetSelectableSteeringModelGUI or any of its controls.
function lvd_EditActionSetSelectableSteeringModelGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditActionSetSelectableSteeringModelGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)


function editMathModel(model)
    switch class(model)
        case 'SumOfPolyTermsModel'
            lvd_EditSumOfPolynomialTermsModelGUI(model);

        case 'SumOfSinesModel'
            lvd_EditSumOfSinesModelGUI(model);
            
        case 'LinearTangentSelectableModel'
            lvd_EditLinearTangentModelGUI(model);
            
        case 'FitNetModel'
            lvd_EditFitNetModelGUI(model);

        otherwise
            error('Unknown angle steering model class');
    end
    

% --- Executes on button press in editAngle1ModelButton.
function editAngle1ModelButton_Callback(hObject, eventdata, handles)
% hObject    handle to editAngle1ModelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
	action = getappdata(handles.lvd_EditActionSetSelectableSteeringModelGUI,'action');
    steeringModel = action.steeringModel;

    [~,enums] = SteerMathModelTypeEnum.getListBoxStr();
    enum = enums(handles.angle1ModelTypeCombo.Value);

    switch enum
        case SteerMathModelTypeEnum.GenericPoly
            model = steeringModel.gammaAngleSumPoly;
            
        case SteerMathModelTypeEnum.SumOfSines
            model = steeringModel.gammaAngleSumSines;
            
        case SteerMathModelTypeEnum.LinearTangent
            model = steeringModel.gammaAngleLinearTan;
            
        case SteerMathModelTypeEnum.FitNet
            model = steeringModel.gammaAngleFitNet;
            
        otherwise
            error('Unknown Gamma angle steering model');
    end
    
    editMathModel(model);
    

% --- Executes on button press in editAngle2ModelButton.
function editAngle2ModelButton_Callback(hObject, eventdata, handles)
% hObject    handle to editAngle2ModelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
	action = getappdata(handles.lvd_EditActionSetSelectableSteeringModelGUI,'action');
    steeringModel = action.steeringModel;

    [~,enums] = SteerMathModelTypeEnum.getListBoxStr();
    enum = enums(handles.angle2ModelTypeCombo.Value);

    switch enum
        case SteerMathModelTypeEnum.GenericPoly
            model = steeringModel.betaAngleSumPoly;
            
        case SteerMathModelTypeEnum.SumOfSines
            model = steeringModel.betaAngleSumSines;
            
        case SteerMathModelTypeEnum.LinearTangent
            model = steeringModel.betaAngleLinearTan;
            
        case SteerMathModelTypeEnum.FitNet
            model = steeringModel.betaAngleFitNet;
            
        otherwise
            error('Unknown Beta angle steering model');
    end

    editMathModel(model);

% --- Executes on button press in editAngle3ModelButton.
function editAngle3ModelButton_Callback(hObject, eventdata, handles)
% hObject    handle to editAngle3ModelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
	action = getappdata(handles.lvd_EditActionSetSelectableSteeringModelGUI,'action');
    steeringModel = action.steeringModel;

    [~,enums] = SteerMathModelTypeEnum.getListBoxStr();
    enum = enums(handles.angle3ModelTypeCombo.Value);

    switch enum
        case SteerMathModelTypeEnum.GenericPoly
            model = steeringModel.alphaAngleSumPoly;
            
        case SteerMathModelTypeEnum.SumOfSines
            model = steeringModel.alphaAngleSumSines;
            
        case SteerMathModelTypeEnum.LinearTangent
            model = steeringModel.alphaAngleLinearTan;
            
        case SteerMathModelTypeEnum.FitNet
            model = steeringModel.alphaAngleFitNet;
            
        otherwise
            error('Unknown Alpha angle steering model');
    end

    editMathModel(model);


% --- Executes on selection change in angle1ModelTypeCombo.
function angle1ModelTypeCombo_Callback(hObject, eventdata, handles)
% hObject    handle to angle1ModelTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns angle1ModelTypeCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from angle1ModelTypeCombo


% --- Executes during object creation, after setting all properties.
function angle1ModelTypeCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle1ModelTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in angle2ModelTypeCombo.
function angle2ModelTypeCombo_Callback(hObject, eventdata, handles)
% hObject    handle to angle2ModelTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns angle2ModelTypeCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from angle2ModelTypeCombo


% --- Executes during object creation, after setting all properties.
function angle2ModelTypeCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle2ModelTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in angle3ModelTypeCombo.
function angle3ModelTypeCombo_Callback(hObject, eventdata, handles)
% hObject    handle to angle3ModelTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns angle3ModelTypeCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from angle3ModelTypeCombo


% --- Executes during object creation, after setting all properties.
function angle3ModelTypeCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angle3ModelTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
