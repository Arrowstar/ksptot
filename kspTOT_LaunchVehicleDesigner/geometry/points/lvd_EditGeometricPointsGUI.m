function varargout = lvd_EditGeometricPointsGUI(varargin)
% LVD_EDITGEOMETRICPOINTSGUI MATLAB code for lvd_EditGeometricPointsGUI.fig
%      LVD_EDITGEOMETRICPOINTSGUI, by itself, creates a new LVD_EDITGEOMETRICPOINTSGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITGEOMETRICPOINTSGUI returns the handle to a new LVD_EDITGEOMETRICPOINTSGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITGEOMETRICPOINTSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITGEOMETRICPOINTSGUI.M with the given input arguments.
%
%      LVD_EDITGEOMETRICPOINTSGUI('Property','Value',...) creates a new LVD_EDITGEOMETRICPOINTSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditGeometricPointsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditGeometricPointsGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditGeometricPointsGUI

% Last Modified by GUIDE v2.5 09-Jan-2021 21:37:24

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditGeometricPointsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditGeometricPointsGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditGeometricPointsGUI is made visible.
function lvd_EditGeometricPointsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditGeometricPointsGUI (see VARARGIN)

    % Choose default command line output for lvd_EditGeometricPointsGUI
    handles.output = hObject;

    lvdData = varargin{1};
    setappdata(hObject,'lvdData',lvdData);
    
    handles.hKsptotMainGUI = varargin{2};
    
    populateGUI(handles, lvdData);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditGeometricPointsGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditGeometricPointsGUI);

function populateGUI(handles, lvdData)
    set(handles.pointsListBox,'String',lvdData.geometry.points.getListboxStr());
    
    numPoints = length(get(handles.pointsListBox,'String'));
    
    if(handles.pointsListBox.Value < 1)
        handles.pointsListBox.Value = 1;
    elseif(handles.pointsListBox.Value > numPoints)
        handles.pointsListBox.Value = numPoints;
    end
    
    if(numPoints <= 0)
        handles.removePointButton.Enable = 'off';
    else
        handles.removePointButton.Enable = 'on';
    end

    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditGeometricPointsGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = [];
    else
        close(handles.lvd_EditGeometricPointsGUI);
    end


% --- Executes on button press in closeButton.
function closeButton_Callback(hObject, eventdata, handles)
% hObject    handle to closeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.lvd_EditGeometricPointsGUI);

% --- Executes on selection change in pointsListBox.
function pointsListBox_Callback(hObject, eventdata, handles)
% hObject    handle to pointsListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pointsListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pointsListBox
    lvdData = getappdata(handles.lvd_EditGeometricPointsGUI,'lvdData');
    if(strcmpi(get(handles.lvd_EditGeometricPointsGUI,'SelectionType'),'open') && ...
       lvdData.geometry.points.getNumPoints() > 0)
   
        selPtInd = hObject.Value;
        selPt = lvdData.geometry.points.getPointAtInd(selPtInd);
        
        selPt.openEditDialog(handles.hKsptotMainGUI);
        
        populateGUI(handles, lvdData);
    end
    

% --- Executes during object creation, after setting all properties.
function pointsListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pointsListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addPointButton.
function addPointButton_Callback(hObject, eventdata, handles)
% hObject    handle to addPointButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditGeometricPointsGUI,'lvdData');
       
    listboxStr = GeometricPointEnum.getListBoxStr();
    [Selection,ok] = listdlgARH('ListString', listboxStr, ...
                                'SelectionMode', 'single', ...
                                'ListSize', [300 300], ...
                                'InitialValue',1, ...
                                'Name', 'Select New Point Type', ...
                                'PromptString', 'Select the type of the point to be created:');
                            
    if(ok)
        enum = GeometricPointEnum.getEnumForListboxStr(listboxStr{Selection});
        
        switch enum
            case GeometricPointEnum.FixedInFrame
                frame = lvdData.getDefaultInitialBodyInfo(lvdData.celBodyData).getBodyCenteredInertialFrame();
                newPoint = FixedPointInFrame([0;0;0], frame, 'New Point', lvdData);
                
            case GeometricPointEnum.CelestialBody
                bodyInfo = lvdData.getDefaultInitialBodyInfo(lvdData.celBodyData);
                newPoint = CelestialBodyPoint(bodyInfo, 'New Point');
                
            case GeometricPointEnum.GroundObj
                numGroundObjs = lvdData.groundObjs.getNumGroundObj();
                if(numGroundObjs >= 1)
                    groundObj = lvdData.groundObjs.getGroundObjAtInd(1);
                    newPoint = GroundObjectPoint(groundObj, 'New Point');
                else
                    errordlg('Cannot create ground object point: no ground objects exist in mission.  Create a new ground object first!','Cannot Create Point');
                    return;
                end
                
            case GeometricPointEnum.Vehicle
                newPoint = VehiclePoint('New Point');
                
            case GeometricPointEnum.TwoBody
                bodyInfo = lvdData.getDefaultInitialBodyInfo(lvdData.celBodyData);
                elemSet = KeplerianElementSet(0, bodyInfo.radius+100, 0, 0, 0, 0, 0, bodyInfo.getBodyCenteredInertialFrame());
                newPoint = TwoBodyPoint(elemSet, 'New Point', lvdData);
                
            otherwise
                error('Unknown Point Type Type: %s', string(enum))
        end
        
        useTF = newPoint.openEditDialog(handles.hKsptotMainGUI);
        
        if(useTF)
            lvdData.geometry.points.addPoint(newPoint);
            
            populateGUI(handles, lvdData);
        end
    end

    
% --- Executes on button press in removePointButton.
function removePointButton_Callback(hObject, eventdata, handles)
% hObject    handle to removePointButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditGeometricPointsGUI,'lvdData');
    
    selPtInd = handles.pointsListBox.Value;
    selPt = lvdData.geometry.points.getPointAtInd(selPtInd);

    tf = selPt.isInUse(lvdData);

    if(tf == false)
        lvdData.geometry.points.removePoint(selPt);
        
        populateGUI(handles, lvdData);

        numPoints = lvdData.geometry.points.getNumPoints();
        if(handles.pointsListBox.Value > numPoints)
            set(handles.pointsListBox,'Value',numPoints);
        end
    else
        warndlg(sprintf('Could not delete the geometric point "%s" because it is in use as part of a vector, coordinate system, or reference frame.  Remove the point dependencies before attempting to delete the point.', selPt.getName()),'Cannot Delete Point','modal');
    end


% --- Executes on key press with focus on lvd_EditGeometricPointsGUI or any of its controls.
function lvd_EditGeometricPointsGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditGeometricPointsGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            uiresume(handles.lvd_EditGeometricPointsGUI);
        case 'enter'
            uiresume(handles.lvd_EditGeometricPointsGUI);
        case 'escape'
            uiresume(handles.lvd_EditGeometricPointsGUI);
    end
