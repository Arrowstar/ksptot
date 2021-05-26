function varargout = lvd_EditExtremaGUI(varargin)
% LVD_EDITEXTREMAGUI MATLAB code for lvd_EditExtremaGUI.fig
%      LVD_EDITEXTREMAGUI, by itself, creates a new LVD_EDITEXTREMAGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITEXTREMAGUI returns the handle to a new LVD_EDITEXTREMAGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITEXTREMAGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITEXTREMAGUI.M with the given input arguments.
%
%      LVD_EDITEXTREMAGUI('Property','Value',...) creates a new LVD_EDITEXTREMAGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditExtremaGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditExtremaGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditExtremaGUI

% Last Modified by GUIDE v2.5 04-May-2021 20:58:39

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditExtremaGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditExtremaGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditExtremaGUI is made visible.
function lvd_EditExtremaGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditExtremaGUI (see VARARGIN)

    % Choose default command line output for lvd_EditExtremaGUI
    handles.output = hObject;

    extrema = varargin{1};
    setappdata(hObject, 'extrema', extrema);
    
    lvdData = varargin{2};
    setappdata(hObject, 'lvdData', lvdData);
    
	populateGUI(handles, extrema, lvdData);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditExtremaGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditExtremaGUI);

function populateGUI(handles, extrema, lvdData)
    exclude = getLvdGAExcludeList();
    exclude{end+1} = 'Distance Traveled';
    [extremaGAStr, ~] = lvdData.launchVehicle.getExtremaGraphAnalysisTaskStrs();
    exclude = horzcat(exclude,extremaGAStr);
    taskList = lvd_getGraphAnalysisTaskList(lvdData, exclude);
    
    handles.extremaQuantCombo.String = taskList;
    if(isempty(extrema.quantStr))
        value = 1;
    else
        value = findValueFromComboBox(extrema.quantStr, handles.extremaQuantCombo);
    end
    handles.extremaQuantCombo.Value = value;
    
    handles.typeCombo.String = LaunchVehicleExtremaTypeEnum.getNameStrs();
    handles.typeCombo.Value = LaunchVehicleExtremaTypeEnum.getIndOfListboxStrs(extrema.type);
    
%     populateBodiesCombo(lvdData.celBodyData, handles.refFrameTypeCombo);
%     if(isempty(extrema.refBody))
%         value = 1;
%     else
%         value = findValueFromComboBox(extrema.refBody.name, handles.refFrameTypeCombo);
%     end
%     handles.refFrameTypeCombo.Value = value;

    frame = extrema.frame;
    if(isempty(frame))
        frame = LvdData.getDefaultInitialBodyInfo(lvdData.celBodyData).getBodyCenteredInertialFrame();
        extrema.frame = frame;
    end
    setappdata(handles.lvd_EditExtremaGUI,'frame',frame);
    
    handles.refFrameTypeCombo.String = ReferenceFrameEnum.getListBoxStr();
    [ind, ~] = ReferenceFrameEnum.getIndForName(frame.typeEnum.name);
    handles.refFrameTypeCombo.Value = ind;
    handles.setFrameOptionsButton.TooltipString = sprintf('Current Frame: %s', frame.getNameStr());
    handles.refFrameNameLabel.String = sprintf('%s', frame.getNameStr());
    handles.refFrameNameLabel.TooltipString = sprintf('%s', frame.getNameStr());
    
    handles.startRecordingCombo.String = LaunchVehicleExtremaRecordingEnum.getNameStrs();
    handles.startRecordingCombo.Value = LaunchVehicleExtremaRecordingEnum.getIndOfListboxStrs(extrema.startingState);

% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditExtremaGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        extremum = getappdata(hObject, 'extrema');
        lvdData = getappdata(hObject, 'lvdData');
                
        quantityStrs = handles.extremaQuantCombo.String;
        quantity = strtrim(quantityStrs{handles.extremaQuantCombo.Value});
        extremum.quantStr = quantity;
        
        m = enumeration('LaunchVehicleExtremaTypeEnum');
        mI = m(handles.typeCombo.Value);
        extremum.type = mI;
        
%         celBodyStrs = handles.refFrameTypeCombo.String;
%         celBodyStr = celBodyStrs{handles.refFrameTypeCombo.Value};
%         extremum.refBody = lvdData.celBodyData.(strtrim(lower(celBodyStr)));

        frame = getappdata(handles.lvd_EditExtremaGUI,'frame');
        extremum.frame = frame;
        
        m = enumeration('LaunchVehicleExtremaRecordingEnum');
        mI = m(handles.startRecordingCombo.Value);
        extremum.startingState = mI;
        
        varargout{1} = true;
        close(handles.lvd_EditExtremaGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.lvd_EditExtremaGUI);

    
% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditExtremaGUI);


function extremaQuantCombo_Callback(hObject, eventdata, handles)
% hObject    handle to extremaQuantCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of extremaQuantCombo as text
%        str2double(get(hObject,'String')) returns contents of extremaQuantCombo as a double


% --- Executes during object creation, after setting all properties.
function extremaQuantCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to extremaQuantCombo see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function typeCombo_Callback(hObject, eventdata, handles)
% hObject    handle to typeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of typeCombo as text
%        str2double(get(hObject,'String')) returns contents of typeCombo as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function typeCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to typeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on key press with focus on lvd_EditExtremaGUI or any of its controls.
function lvd_EditExtremaGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditExtremaGUI (see GCBO)
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
            close(handles.lvd_EditExtremaGUI);
    end


% --- Executes on selection change in startRecordingCombo.
function startRecordingCombo_Callback(hObject, eventdata, handles)
% hObject    handle to startRecordingCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns startRecordingCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from startRecordingCombo


% --- Executes during object creation, after setting all properties.
function startRecordingCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to startRecordingCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in refFrameTypeCombo.
function refFrameTypeCombo_Callback(hObject, eventdata, handles)
% hObject    handle to refFrameTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns refFrameTypeCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from refFrameTypeCombo
    updateFrameChange(handles);

% --- Executes during object creation, after setting all properties.
function refFrameTypeCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to refFrameTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in setFrameOptionsButton.
function setFrameOptionsButton_Callback(hObject, eventdata, handles)
% hObject    handle to setFrameOptionsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    curFrame = getappdata(handles.lvd_EditExtremaGUI,'frame');
    curFrame = curFrame.editFrameDialogUI(EditReferenceFrameContextEnum.ForState);
    
    setappdata(handles.lvd_EditExtremaGUI,'frame',curFrame);
    
    handles.setFrameOptionsButton.Tooltip = sprintf('Current Frame: %s', curFrame.getNameStr());
    handles.refFrameNameLabel.String = sprintf('%s', curFrame.getNameStr());
    handles.refFrameNameLabel.TooltipString = sprintf('%s', curFrame.getNameStr());

function updateFrameChange(handles)
    lvdData = getappdata(handles.lvd_EditExtremaGUI,'lvdData');
    celBodyData = lvdData.celBodyData;

    refEnumListBoxStr = ReferenceFrameEnum.getListBoxStr();
    selFrameTypeInd = handles.refFrameTypeCombo.Value;
    refFrameEnum = ReferenceFrameEnum.getEnumForListboxStr(refEnumListBoxStr{selFrameTypeInd});

%             if(not(isempty(newFrame)) && newFrame.typeEnum ~= refFrameEnum)
%                 refFrameEnum = newFrame.typeEnum;
%                 app.refFrameTypeCombo.Value = ReferenceFrameEnum.getIndForName(refFrameEnum.name);
%             end

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

            newFrame = TwoBodyRotatingFrame(primaryBody, secondaryBody, originPt, celBodyData);

        case ReferenceFrameEnum.UserDefined
            numFrames = lvdData.geometry.refFrames.getNumRefFrames();
            if(numFrames >= 1)
                geometricFrame = AbstractGeometricRefFrame.empty(1,0);
                for(i=1:numFrames)
                    frame = lvdData.geometry.refFrames.getRefFrameAtInd(i);
                    if(frame.isVehDependent() == false)
                        geometricFrame = frame;
                        break;
                    end
                end

                if(not(isempty(geometricFrame)))
                    newFrame = UserDefinedGeometricFrame(geometricFrame, lvdData);
                else
                    bodyInfo = getSelectedBodyInfo(handles);
                    newFrame = bodyInfo.getBodyCenteredInertialFrame();

                    warndlg('There are no geometric frames available which are not dependent on vehicle properties.  A body-centered inertial frame will be selected instead.');
                end
            else
                bodyInfo = getSelectedBodyInfo(handles);
                newFrame = bodyInfo.getBodyCenteredInertialFrame();

                warndlg('There are no geometric frames available which are not dependent on vehicle properties.  A body-centered inertial frame will be selected instead.');
            end

        otherwise
            error('Unknown reference frame type: %s', string(refFrameEnum));                
    end

    if(not(isempty(newFrame)) && newFrame.typeEnum ~= refFrameEnum)
        refFrameEnum = newFrame.typeEnum;
        handles.refFrameTypeCombo.Value = ReferenceFrameEnum.getIndForName(refFrameEnum.name);
    end

    setappdata(handles.lvd_EditExtremaGUI,'frame', newFrame);
    handles.setFrameOptionsButton.TooltipString = sprintf('Current Frame: %s', newFrame.getNameStr());
    handles.refFrameNameLabel.String = sprintf('%s', newFrame.getNameStr());
    handles.refFrameNameLabel.TooltipString = sprintf('%s', newFrame.getNameStr());
    
function bodyInfo = getSelectedBodyInfo(handles)
    curFrame = getappdata(handles.lvd_EditExtremaGUI,'frame');
    bodyInfo = curFrame.getOriginBody();
    
