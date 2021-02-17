function varargout = lvd_EditGeometricAnglesGUI(varargin)
% LVD_EDITGEOMETRICANGLESGUI MATLAB code for lvd_EditGeometricAnglesGUI.fig
%      LVD_EDITGEOMETRICANGLESGUI, by itself, creates a new LVD_EDITGEOMETRICANGLESGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITGEOMETRICANGLESGUI returns the handle to a new LVD_EDITGEOMETRICANGLESGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITGEOMETRICANGLESGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITGEOMETRICANGLESGUI.M with the given input arguments.
%
%      LVD_EDITGEOMETRICANGLESGUI('Property','Value',...) creates a new LVD_EDITGEOMETRICANGLESGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditGeometricAnglesGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditGeometricAnglesGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditGeometricAnglesGUI

% Last Modified by GUIDE v2.5 17-Feb-2021 13:48:37

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditGeometricAnglesGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditGeometricAnglesGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditGeometricAnglesGUI is made visible.
function lvd_EditGeometricAnglesGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditGeometricAnglesGUI (see VARARGIN)

    % Choose default command line output for lvd_EditGeometricAnglesGUI
    handles.output = hObject;

    lvdData = varargin{1};
    setappdata(hObject,'lvdData',lvdData);
    
    populateGUI(handles, lvdData);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditGeometricAnglesGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditGeometricAnglesGUI);

function populateGUI(handles, lvdData)
    set(handles.anglesListBox,'String',lvdData.geometry.angles.getListboxStr());
    
    numAngles = length(get(handles.anglesListBox,'String'));
    
    if(handles.anglesListBox.Value < 1)
        handles.anglesListBox.Value = 1;
    elseif(handles.anglesListBox.Value > numAngles)
        handles.anglesListBox.Value = numAngles;
    end
    
    if(numAngles <= 0)
        handles.removeAngleButton.Enable = 'off';
    else
        handles.removeAngleButton.Enable = 'on';
    end

    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditGeometricAnglesGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = [];
    else
        close(handles.lvd_EditGeometricAnglesGUI);
    end


% --- Executes on button press in closeButton.
function closeButton_Callback(hObject, eventdata, handles)
% hObject    handle to closeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.lvd_EditGeometricAnglesGUI);

% --- Executes on selection change in anglesListBox.
function anglesListBox_Callback(hObject, eventdata, handles)
% hObject    handle to anglesListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns anglesListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from anglesListBox
    lvdData = getappdata(handles.lvd_EditGeometricAnglesGUI,'lvdData');
    if(strcmpi(get(handles.lvd_EditGeometricAnglesGUI,'SelectionType'),'open') && ...
       lvdData.geometry.refFrames.getNumRefFrames() > 0)
        selAngleInd = hObject.Value;
        selAngle = lvdData.geometry.angles.getAngleAtInd(selAngleInd);
        
        selAngle.openEditDialog();
        
        populateGUI(handles, lvdData);
    end
    

% --- Executes during object creation, after setting all properties.
function anglesListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to anglesListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addAngleButton.
function addAngleButton_Callback(hObject, eventdata, handles)
% hObject    handle to addAngleButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditGeometricAnglesGUI,'lvdData');
       
    listboxStr = GeometricAngleEnum.getListBoxStr();
    [Selection,ok] = listdlgARH('ListString', listboxStr, ...
                                'SelectionMode', 'single', ...
                                'ListSize', [300 300], ...
                                'InitialValue',1, ...
                                'Name', 'Select New Angle Type', ...
                                'PromptString', 'Select the type of the angle to be created:');
                            
    if(ok)
        enum = GeometricAngleEnum.getEnumForListboxStr(listboxStr{Selection});
        
        switch enum                
            case GeometricAngleEnum.AngleBetweenVectors
                numVectors = lvdData.geometry.vectors.getNumVectors();
                if(numVectors >= 2)
                    vector1 = lvdData.geometry.vectors.getVectorAtInd(1);
                    vector2 = lvdData.geometry.vectors.getVectorAtInd(2);
                    newAngle = TwoVectorAngle(vector1, vector2, 'New Angle', lvdData);
                    
                else
                    errordlg('Cannot create angle between vectors: There must be at least two geometric vectors available.','Cannot Create Angle');
                    return;
                end
                
            otherwise
                error('Unknown Angle Type: %s', enum.name)
        end
        
        useTF = newAngle.openEditDialog();
        
        if(useTF)
            lvdData.geometry.angles.addAngle(newAngle);
            
            populateGUI(handles, lvdData);
        end
    end

    
% --- Executes on button press in removeAngleButton.
function removeAngleButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeAngleButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditGeometricAnglesGUI,'lvdData');
    
    selAngleInd = handles.anglesListBox.Value;
    selAngle = lvdData.geometry.angles.getAngleAtInd(selAngleInd);

	tf = selAngle.isInUse(lvdData);

    if(tf == false)
        lvdData.geometry.angles.removeAngle(selAngle);
        
%         lvdData.viewSettings.removeGeoRefFrameFromViewProfiles(selAngle);
        
        populateGUI(handles, lvdData);

        numAngles = lvdData.geometry.angles.getNumAngles();
        if(handles.anglesListBox.Value > numAngles)
            set(handles.anglesListBox,'Value',numAngles);
        end
    else
        warndlg(sprintf('Could not delete the geometric angle "%s" because it is in use elsewhere.  Remove the angle dependencies before attempting to delete the angle.', selAngle.getName()),'Cannot Delete Angle','modal');
    end


% --- Executes on key press with focus on lvd_EditGeometricAnglesGUI or any of its controls.
function lvd_EditGeometricAnglesGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditGeometricAnglesGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            uiresume(handles.lvd_EditGeometricAnglesGUI);
        case 'enter'
            uiresume(handles.lvd_EditGeometricAnglesGUI);
        case 'escape'
            uiresume(handles.lvd_EditGeometricAnglesGUI);
    end
