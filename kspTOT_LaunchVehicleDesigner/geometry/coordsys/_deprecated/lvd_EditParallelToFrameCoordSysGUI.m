function varargout = lvd_EditParallelToFrameCoordSysGUI(varargin)
% LVD_EDITPARALLELTOFRAMECOORDSYSGUI MATLAB code for lvd_EditParallelToFrameCoordSysGUI.fig
%      LVD_EDITPARALLELTOFRAMECOORDSYSGUI, by itself, creates a new LVD_EDITPARALLELTOFRAMECOORDSYSGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITPARALLELTOFRAMECOORDSYSGUI returns the handle to a new LVD_EDITPARALLELTOFRAMECOORDSYSGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITPARALLELTOFRAMECOORDSYSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITPARALLELTOFRAMECOORDSYSGUI.M with the given input arguments.
%
%      LVD_EDITPARALLELTOFRAMECOORDSYSGUI('Property','Value',...) creates a new LVD_EDITPARALLELTOFRAMECOORDSYSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditParallelToFrameCoordSysGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditParallelToFrameCoordSysGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditParallelToFrameCoordSysGUI

% Last Modified by GUIDE v2.5 15-Jan-2021 12:17:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditParallelToFrameCoordSysGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditParallelToFrameCoordSysGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditParallelToFrameCoordSysGUI is made visible.
function lvd_EditParallelToFrameCoordSysGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditParallelToFrameCoordSysGUI (see VARARGIN)

    % Choose default command line output for lvd_EditParallelToFrameCoordSysGUI
    handles.output = hObject;
    
    centerUIFigure(hObject);

    coordSys = varargin{1};
    setappdata(hObject, 'coordSys', coordSys);
    
    lvdData = varargin{2};
    setappdata(hObject, 'lvdData', lvdData);
    
	populateGUI(handles, coordSys);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditParallelToFrameCoordSysGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditFixedInFrameVectorGUI);

function populateGUI(handles, coordSys)
    set(handles.coordSysNameText,'String',coordSys.getName());
    setappdata(handles.lvd_EditFixedInFrameVectorGUI,'frame',coordSys.frame);
    
    frame = coordSys.frame;
    handles.refFrameTypeCombo.String = ReferenceFrameEnum.getListBoxStr();
    handles.refFrameTypeCombo.Value = ReferenceFrameEnum.getIndForName(frame.typeEnum.name);
    handles.setFrameOptionsButton.TooltipString = sprintf('Current Frame: %s', frame.getNameStr()); 


% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditParallelToFrameCoordSysGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        coordSys = getappdata(hObject, 'coordSys');
        
        coordSys.setName(handles.coordSysNameText.String);
                
        coordSys.frame = getappdata(hObject,'frame');
        
        varargout{1} = true;
        close(handles.lvd_EditFixedInFrameVectorGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_EditFixedInFrameVectorGUI);
    else
        msgbox(errMsg,'Invalid Coordinate System Inputs','error');
    end


function errMsg = validateInputs(handles)
    errMsg = {};
       
    if(isempty(strtrim(handles.coordSysNameText.String)))
        errMsg{end+1} = 'Vector name must contain more than white space and must not be empty.';
    end
    
% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditFixedInFrameVectorGUI);


function coordSysNameText_Callback(hObject, eventdata, handles)
% hObject    handle to coordSysNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of coordSysNameText as text
%        str2double(get(hObject,'String')) returns contents of coordSysNameText as a double


% --- Executes during object creation, after setting all properties.
function coordSysNameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to coordSysNameText see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on lvd_EditParallelToFrameCoordSysGUI or any of its controls.
function lvd_EditFixedInFrameVectorGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditParallelToFrameCoordSysGUI (see GCBO)
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
            close(handles.lvd_EditFixedInFrameVectorGUI);
    end
    

% --- Executes on selection change in refFrameTypeCombo.
function refFrameTypeCombo_Callback(hObject, eventdata, handles)
% hObject    handle to refFrameTypeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns refFrameTypeCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from refFrameTypeCombo
    frameUpdated(handles);

    
function frameUpdated(handles)
    lvdData = getappdata(handles.lvd_EditFixedInFrameVectorGUI, 'lvdData');
    
    frame = getappdata(handles.lvd_EditFixedInFrameVectorGUI,'frame'); %curElemSet
    bodyInfo = frame.getOriginBody();    
    
    contents = cellstr(get(handles.refFrameTypeCombo,'String'));
    selFrameType = contents{get(handles.refFrameTypeCombo,'Value')};
    refFrameEnum = ReferenceFrameEnum.getEnumForListboxStr(selFrameType);
    
    switch refFrameEnum
        case ReferenceFrameEnum.BodyCenteredInertial
            newFrame = bodyInfo.getBodyCenteredInertialFrame();

        case ReferenceFrameEnum.BodyFixedRotating
            newFrame = bodyInfo.getBodyFixedFrame();
            
        case ReferenceFrameEnum.TwoBodyRotating       
            if(frame.typeEnum == ReferenceFrameEnum.TwoBodyRotating)
                newFrame = frame;
            else
                if(not(isempty(bodyInfo.childrenBodyInfo)))
                    primaryBody = bodyInfo;
                    secondaryBody = bodyInfo.childrenBodyInfo(1);
                else
                    primaryBody = bodyInfo.getParBodyInfo();
                    secondaryBody = bodyInfo;
                end
                
                originPt = TwoBodyRotatingFrameOriginEnum.Primary;
                
                newFrame = TwoBodyRotatingFrame(primaryBody, secondaryBody, originPt, bodyInfo.celBodyData);
            end
            
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
        handles.refFrameTypeCombo.Value = ReferenceFrameEnum.getIndForName(refFrameEnum.name);
    end
    
    setappdata(handles.lvd_EditFixedInFrameVectorGUI,'frame',newFrame);
    handles.setFrameOptionsButton.TooltipString = sprintf('Current Frame: %s', newFrame.getNameStr()); 
    

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
    frame = getappdata(handles.lvd_EditFixedInFrameVectorGUI,'frame');

    newFrame = frame.editFrameDialogUI(EditReferenceFrameContextEnum.ForGeometry);
    
    setappdata(handles.lvd_EditFixedInFrameVectorGUI,'frame',newFrame);
    
    frameUpdated(handles);
