function varargout = lvd_EditGeometricVectorsGUI(varargin)
% LVD_EDITGEOMETRICVECTORSGUI MATLAB code for lvd_EditGeometricVectorsGUI.fig
%      LVD_EDITGEOMETRICVECTORSGUI, by itself, creates a new LVD_EDITGEOMETRICVECTORSGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITGEOMETRICVECTORSGUI returns the handle to a new LVD_EDITGEOMETRICVECTORSGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITGEOMETRICVECTORSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITGEOMETRICVECTORSGUI.M with the given input arguments.
%
%      LVD_EDITGEOMETRICVECTORSGUI('Property','Value',...) creates a new LVD_EDITGEOMETRICVECTORSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditGeometricVectorsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditGeometricVectorsGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditGeometricVectorsGUI

% Last Modified by GUIDE v2.5 10-Jan-2021 20:02:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditGeometricVectorsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditGeometricVectorsGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditGeometricVectorsGUI is made visible.
function lvd_EditGeometricVectorsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditGeometricVectorsGUI (see VARARGIN)

    % Choose default command line output for lvd_EditGeometricVectorsGUI
    handles.output = hObject;

    lvdData = varargin{1};
    setappdata(hObject,'lvdData',lvdData);
    
    populateGUI(handles, lvdData);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditGeometricVectorsGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditGeometricVectorsGUI);

function populateGUI(handles, lvdData)
    set(handles.vectorsListBox,'String',lvdData.geometry.vectors.getListboxStr());
    
    numVectors = length(get(handles.vectorsListBox,'String'));
    
    if(handles.vectorsListBox.Value < 1)
        handles.vectorsListBox.Value = 1;
    elseif(handles.vectorsListBox.Value > numVectors)
        handles.vectorsListBox.Value = numVectors;
    end
    
    if(numVectors <= 0)
        handles.removeVectorButton.Enable = 'off';
    else
        handles.removeVectorButton.Enable = 'on';
    end

    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditGeometricVectorsGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = [];
    else
        close(handles.lvd_EditGeometricVectorsGUI);
    end


% --- Executes on button press in closeButton.
function closeButton_Callback(hObject, eventdata, handles)
% hObject    handle to closeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.lvd_EditGeometricVectorsGUI);

% --- Executes on selection change in vectorsListBox.
function vectorsListBox_Callback(hObject, eventdata, handles)
% hObject    handle to vectorsListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns vectorsListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from vectorsListBox
    lvdData = getappdata(handles.lvd_EditGeometricVectorsGUI,'lvdData');
    if(strcmpi(get(handles.lvd_EditGeometricVectorsGUI,'SelectionType'),'open') && ...
       lvdData.geometry.vectors.getNumVectors() > 0)
        selVectorInd = hObject.Value;
        selVector = lvdData.geometry.vectors.getVectorAtInd(selVectorInd);
        
        selVector.openEditDialog();
        
        populateGUI(handles, lvdData);
    end
    

% --- Executes during object creation, after setting all properties.
function vectorsListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vectorsListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addVectorButton.
function addVectorButton_Callback(hObject, eventdata, handles)
% hObject    handle to addVectorButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditGeometricVectorsGUI,'lvdData');
       
    listboxStr = GeometricVectorEnum.getListBoxStr();
    [Selection,ok] = listdlgARH('ListString', listboxStr, ...
                                'SelectionMode', 'single', ...
                                'ListSize', [300 300], ...
                                'InitialValue',1, ...
                                'Name', 'Select New Vector Type', ...
                                'PromptString', 'Select the type of the vector to be created:');
                            
    if(ok)
        enum = GeometricVectorEnum.getEnumForListboxStr(listboxStr{Selection});
        
        switch enum
            case GeometricVectorEnum.FixedInFrame
                frame = lvdData.getDefaultInitialBodyInfo(lvdData.celBodyData).getBodyCenteredInertialFrame();
                newVector = FixedVectorInFrame([1;0;0], frame, 'New Vector', lvdData);
                
            case GeometricVectorEnum.TwoPoint
                numPoints = lvdData.geometry.points.getNumPoints();
                if(numPoints >= 2)
                    plane = lvdData.geometry.points.getPointAtInd(1);
                    point = lvdData.geometry.points.getPointAtInd(2);
                    newVector = TwoPointVector(plane, point, 'New Vector', lvdData);
                else
                    errordlg('Cannot create Two Point Vector: There must be at least two unique geometric points available.','Cannot Create Vector');
                    return;
                end
                
            case GeometricVectorEnum.Scaled
                numVectors = lvdData.geometry.vectors.getNumVectors();
                if(numVectors >= 1)
                    vector = lvdData.geometry.vectors.getVectorAtInd(1);
                    newVector = ScaledVector(vector, 1.0, 'New Vector', lvdData);
                else
                    errordlg('Cannot create Scaled Vector: There must be at least one geometric vector available.','Cannot Create Vector');
                    return;
                end
                
            case GeometricVectorEnum.CrossProd
                numVectors = lvdData.geometry.vectors.getNumVectors();
                if(numVectors >= 2)
                    vector1 = lvdData.geometry.vectors.getVectorAtInd(1);
                    vector2 = lvdData.geometry.vectors.getVectorAtInd(2);
                    newVector = CrossProductVector(vector1, vector2, 'New Vector', lvdData);
                else
                    errordlg('Cannot create Cross Product Vector: There must be at least two unique geometric vectors available.','Cannot Create Vector');
                    return;
                end
                
            case GeometricVectorEnum.VehicleState
                newVector = VehicleStateVector(VehicleStateVectorTypeEnum.Velocity, 1, 'New Vector', lvdData);
                
            case GeometricVectorEnum.Projected
                numVectors = lvdData.geometry.vectors.getNumVectors();
                if(numVectors >= 2)
                    vector1 = lvdData.geometry.vectors.getVectorAtInd(1);
                    vector2 = lvdData.geometry.vectors.getVectorAtInd(2);
                    newVector = ProjectedVector(vector1, vector2, 'New Vector', lvdData);
                else
                    errordlg('Cannot create Projected Vector: There must be at least two unique geometric vectors available.','Cannot Create Vector');
                    return;
                end
                
            case GeometricVectorEnum.PlaneToPoint
                numPoints = lvdData.geometry.points.getNumPoints();
                numPlanes = lvdData.geometry.planes.getNumPlanes();
                if(numPoints >= 1 && numPlanes >= 1)
                    plane = lvdData.geometry.planes.getPlaneAtInd(1);
                    point = lvdData.geometry.points.getPointAtInd(1);
                    newVector = PlaneToPointVector(point, plane, 'New Vector', lvdData);
                else
                    errordlg('Cannot create Plane to Point Vector: There must be at least one unique geometric point and one unique geometric plane available.','Cannot Create Vector');
                    return;
                end
                
            otherwise
                error('Unknown Vector Type Type: %s', string(enum))
        end
        
        useTF = newVector.openEditDialog();
        
        if(useTF)
            lvdData.geometry.vectors.addVector(newVector);
            
            populateGUI(handles, lvdData);
        end
    end

    
% --- Executes on button press in removeVectorButton.
function removeVectorButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeVectorButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditGeometricVectorsGUI,'lvdData');
    
    selVectorInd = handles.vectorsListBox.Value;
    selVector = lvdData.geometry.vectors.getVectorAtInd(selVectorInd);

	tf = selVector.isInUse(lvdData);

    if(tf == false)
        lvdData.geometry.vectors.removeVector(selVector);
        
        lvdData.viewSettings.removeGeoVectorFromViewProfiles(selVector);
        
        populateGUI(handles, lvdData);

        numVectors = lvdData.geometry.vectors.getNumVectors();
        if(handles.vectorsListBox.Value > numVectors)
            set(handles.vectorsListBox,'Value',numVectors);
        end
    else
        warndlg(sprintf('Could not delete the geometric vector "%s" because it is in use as part of a vector, coordinate system, or reference frame.  Remove the vector dependencies before attempting to delete the vector.', selVector.getName()),'Cannot Delete Vector','modal');
    end


% --- Executes on key press with focus on lvd_EditGeometricVectorsGUI or any of its controls.
function lvd_EditGeometricVectorsGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditGeometricVectorsGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            uiresume(handles.lvd_EditGeometricVectorsGUI);
        case 'enter'
            uiresume(handles.lvd_EditGeometricVectorsGUI);
        case 'escape'
            uiresume(handles.lvd_EditGeometricVectorsGUI);
    end
