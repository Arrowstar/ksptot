function varargout = lvd_EditGeometricPlanesGUI(varargin)
% LVD_EDITGEOMETRICPLANESGUI MATLAB code for lvd_EditGeometricPlanesGUI.fig
%      LVD_EDITGEOMETRICPLANESGUI, by itself, creates a new LVD_EDITGEOMETRICPLANESGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITGEOMETRICPLANESGUI returns the handle to a new LVD_EDITGEOMETRICPLANESGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITGEOMETRICPLANESGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITGEOMETRICPLANESGUI.M with the given input arguments.
%
%      LVD_EDITGEOMETRICPLANESGUI('Property','Value',...) creates a new LVD_EDITGEOMETRICPLANESGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditGeometricPlanesGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditGeometricPlanesGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditGeometricPlanesGUI

% Last Modified by GUIDE v2.5 17-Feb-2021 14:00:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditGeometricPlanesGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditGeometricPlanesGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditGeometricPlanesGUI is made visible.
function lvd_EditGeometricPlanesGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditGeometricPlanesGUI (see VARARGIN)

    % Choose default command line output for lvd_EditGeometricPlanesGUI
    handles.output = hObject;

    lvdData = varargin{1};
    setappdata(hObject,'lvdData',lvdData);
    
    populateGUI(handles, lvdData);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditGeometricPlanesGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditGeometricPlanesGUI);

function populateGUI(handles, lvdData)
    set(handles.planesListBox,'String',lvdData.geometry.planes.getListboxStr());
    
    numPlanes = length(get(handles.planesListBox,'String'));
    
    if(handles.planesListBox.Value < 1)
        handles.planesListBox.Value = 1;
    elseif(handles.planesListBox.Value > numPlanes)
        handles.planesListBox.Value = numPlanes;
    end
    
    if(numPlanes <= 0)
        handles.removePlaneButton.Enable = 'off';
    else
        handles.removePlaneButton.Enable = 'on';
    end

    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditGeometricPlanesGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = [];
    else
        close(handles.lvd_EditGeometricPlanesGUI);
    end


% --- Executes on button press in closeButton.
function closeButton_Callback(hObject, eventdata, handles)
% hObject    handle to closeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.lvd_EditGeometricPlanesGUI);

% --- Executes on selection change in planesListBox.
function planesListBox_Callback(hObject, eventdata, handles)
% hObject    handle to planesListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns planesListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from planesListBox
    lvdData = getappdata(handles.lvd_EditGeometricPlanesGUI,'lvdData');
    if(strcmpi(get(handles.lvd_EditGeometricPlanesGUI,'SelectionType'),'open') && ...
       lvdData.geometry.planes.getNumPlanes() > 0)
        selPlaneInd = hObject.Value;
        selPlane = lvdData.geometry.planes.getPlaneAtInd(selPlaneInd);
        
        selPlane.openEditDialog();
        
        populateGUI(handles, lvdData);
    end
    

% --- Executes during object creation, after setting all properties.
function planesListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to planesListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addPlaneButton.
function addPlaneButton_Callback(hObject, eventdata, handles)
% hObject    handle to addPlaneButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditGeometricPlanesGUI,'lvdData');
       
    listboxStr = GeometricPlaneEnum.getListBoxStr();
    [Selection,ok] = listdlgARH('ListString', listboxStr, ...
                                'SelectionMode', 'single', ...
                                'ListSize', [300 300], ...
                                'InitialValue',1, ...
                                'Name', 'Select New Plane Type', ...
                                'PromptString', 'Select the type of the plane to be created:');
                            
    if(ok)
        enum = GeometricPlaneEnum.getEnumForListboxStr(listboxStr{Selection});
        
        switch enum                
            case GeometricPlaneEnum.PointVectorPlane
                numVectors = lvdData.geometry.vectors.getNumVectors();
                numPoints = lvdData.geometry.points.getNumPoints();
                if(numVectors >= 1 && numPoints >= 1)
                    vector = lvdData.geometry.vectors.getVectorAtInd(1);
                    point = lvdData.geometry.points.getPointAtInd(1);
                    newPlane = PointVectorPlane(point, vector, 'New Plane', lvdData);
                    
                else
                    errordlg('Cannot create plane: There must be at least one geometric vector and one geometric point available.','Cannot Create Plane');
                    return;
                end
                
            case GeometricPlaneEnum.ThreePointPlane
                numPoints = lvdData.geometry.points.getNumPoints();
                if(numPoints >= 3)
                    point1 = lvdData.geometry.points.getPointAtInd(1);
                    point2 = lvdData.geometry.points.getPointAtInd(2);
                    point3 = lvdData.geometry.points.getPointAtInd(3);
                    newPlane = ThreePointPlane(point1, point2, point3, 'New Plane', lvdData);
                    
                else
                    errordlg('Cannot create plane: There must be at least three geometric points available.','Cannot Create Plane');
                    return;
                end
                
            otherwise
                error('Unknown Plane Type: %s', enum.name)
        end
        
        useTF = newPlane.openEditDialog();
        
        if(useTF)
            lvdData.geometry.planes.addPlane(newPlane);
            
            populateGUI(handles, lvdData);
        end
    end

    
% --- Executes on button press in removePlaneButton.
function removePlaneButton_Callback(hObject, eventdata, handles)
% hObject    handle to removePlaneButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditGeometricPlanesGUI,'lvdData');
    
    selPlaneInd = handles.planesListBox.Value;
    selPlane = lvdData.geometry.planes.getPlaneAtInd(selPlaneInd);

	tf = selPlane.isInUse(lvdData);

    if(tf == false)
        lvdData.geometry.planes.removePlane(selPlane);
        
        lvdData.viewSettings.removeGeoPlaneFromViewProfiles(selPlane);
        
        populateGUI(handles, lvdData);

        numPlanes = lvdData.geometry.planes.getNumPlanes();
        if(handles.planesListBox.Value > numPlanes)
            set(handles.planesListBox,'Value',numPlanes);
        end
    else
        warndlg(sprintf('Could not delete the geometric plane "%s" because it is in use elsewhere.  Remove the plane dependencies before attempting to delete the plane.', selPlane.getName()),'Cannot Delete Plane','modal');
    end


% --- Executes on key press with focus on lvd_EditGeometricPlanesGUI or any of its controls.
function lvd_EditGeometricPlanesGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditGeometricPlanesGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            uiresume(handles.lvd_EditGeometricPlanesGUI);
        case 'enter'
            uiresume(handles.lvd_EditGeometricPlanesGUI);
        case 'escape'
            uiresume(handles.lvd_EditGeometricPlanesGUI);
    end
