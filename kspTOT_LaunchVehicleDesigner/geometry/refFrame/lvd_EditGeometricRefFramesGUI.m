function varargout = lvd_EditGeometricRefFramesGUI(varargin)
% LVD_EDITGEOMETRICREFFRAMESGUI MATLAB code for lvd_EditGeometricRefFramesGUI.fig
%      LVD_EDITGEOMETRICREFFRAMESGUI, by itself, creates a new LVD_EDITGEOMETRICREFFRAMESGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITGEOMETRICREFFRAMESGUI returns the handle to a new LVD_EDITGEOMETRICREFFRAMESGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITGEOMETRICREFFRAMESGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITGEOMETRICREFFRAMESGUI.M with the given input arguments.
%
%      LVD_EDITGEOMETRICREFFRAMESGUI('Property','Value',...) creates a new LVD_EDITGEOMETRICREFFRAMESGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditGeometricRefFramesGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditGeometricRefFramesGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditGeometricRefFramesGUI

% Last Modified by GUIDE v2.5 11-Jan-2021 18:38:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditGeometricRefFramesGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditGeometricRefFramesGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditGeometricRefFramesGUI is made visible.
function lvd_EditGeometricRefFramesGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditGeometricRefFramesGUI (see VARARGIN)

    % Choose default command line output for lvd_EditGeometricRefFramesGUI
    handles.output = hObject;

    lvdData = varargin{1};
    setappdata(hObject,'lvdData',lvdData);
    
    populateGUI(handles, lvdData);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditGeometricRefFramesGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditGeometricRefFramesGUI);

function populateGUI(handles, lvdData)
    set(handles.refFrameListBox,'String',lvdData.geometry.refFrames.getListboxStr());
    
    numRefFrames = length(get(handles.refFrameListBox,'String'));
    
    if(handles.refFrameListBox.Value < 1)
        handles.refFrameListBox.Value = 1;
    elseif(handles.refFrameListBox.Value > numRefFrames)
        handles.refFrameListBox.Value = numRefFrames;
    end
    
    if(numRefFrames <= 0)
        handles.removeRefFrameButton.Enable = 'off';
    else
        handles.removeRefFrameButton.Enable = 'on';
    end

    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditGeometricRefFramesGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = [];
    else
        close(handles.lvd_EditGeometricRefFramesGUI);
    end


% --- Executes on button press in closeButton.
function closeButton_Callback(hObject, eventdata, handles)
% hObject    handle to closeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.lvd_EditGeometricRefFramesGUI);

% --- Executes on selection change in refFrameListBox.
function refFrameListBox_Callback(hObject, eventdata, handles)
% hObject    handle to refFrameListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns refFrameListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from refFrameListBox
    lvdData = getappdata(handles.lvd_EditGeometricRefFramesGUI,'lvdData');
    if(strcmpi(get(handles.lvd_EditGeometricRefFramesGUI,'SelectionType'),'open') && ...
       lvdData.geometry.refFrames.getNumRefFrames() > 0)
        selRefFrameInd = hObject.Value;
        selRefFrame = lvdData.geometry.refFrames.getRefFrameAtInd(selRefFrameInd);
        
        selRefFrame.openEditDialog();
        
        populateGUI(handles, lvdData);
    end
    

% --- Executes during object creation, after setting all properties.
function refFrameListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to refFrameListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addRefFrameButton.
function addRefFrameButton_Callback(hObject, eventdata, handles)
% hObject    handle to addRefFrameButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditGeometricRefFramesGUI,'lvdData');
       
    listboxStr = GeometricRefFrameEnum.getListBoxStr();
    [Selection,ok] = listdlgARH('ListString', listboxStr, ...
                                'SelectionMode', 'single', ...
                                'ListSize', [300 300], ...
                                'InitialValue',1, ...
                                'Name', 'Select New Coordinate System Type', ...
                                'PromptString', 'Select the type of the coordinate system to be created:');
                            
    if(ok)
        enum = GeometricRefFrameEnum.getEnumForListboxStr(listboxStr{Selection});
        
        switch enum                
            case GeometricRefFrameEnum.CoordSystemOrigin
                numPoints = lvdData.geometry.points.getNumPoints();
                numCoordSystems = lvdData.geometry.coordSyses.getNumCoordSyses();
                if(numPoints >= 1 && numCoordSystems >= 1)
                    origin = lvdData.geometry.points.getPointAtInd(1);
                    coordSys = lvdData.geometry.coordSyses.getCoordSysAtInd(1);
                    newRefFrame = CoordSysPointRefFrame(coordSys, origin, 'New Reference Frame', lvdData);
                    
                else
                    errordlg('Cannot create Coordinate System at Origin Reference Frame: There must be at least one geometric point and one coordinate system available.','Cannot Create Reference Frame');
                    return;
                end
                
            otherwise
                error('Unknown Reference Frame Type: %s', enum.name)
        end
        
        useTF = newRefFrame.openEditDialog();
        
        if(useTF)
            lvdData.geometry.refFrames.addRefFrame(newRefFrame);
            
            populateGUI(handles, lvdData);
        end
    end

    
% --- Executes on button press in removeRefFrameButton.
function removeRefFrameButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeRefFrameButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditGeometricRefFramesGUI,'lvdData');
    
    selRefFrameInd = handles.refFrameListBox.Value;
    selRefFrame = lvdData.geometry.refFrames.getRefFrameAtInd(selRefFrameInd);

	tf = selRefFrame.isInUse(lvdData);

    if(tf == false)
        lvdData.geometry.refFrames.removeRefFrame(selRefFrame);
        
        lvdData.viewSettings.removeGeoRefFrameFromViewProfiles(selRefFrame);
        
        populateGUI(handles, lvdData);

        numRefFrames = lvdData.geometry.refFrames.getNumRefFrames();
        if(handles.refFrameListBox.Value > numRefFrames)
            set(handles.refFrameListBox,'Value',numRefFrames);
        end
    else
        warndlg(sprintf('Could not delete the geometric reference frame "%s" because it is in use elsewhere.  Remove the reference frame dependencies before attempting to delete the reference frame.', selRefFrame.getName()),'Cannot Delete Reference Frame','modal');
    end


% --- Executes on key press with focus on lvd_EditGeometricRefFramesGUI or any of its controls.
function lvd_EditGeometricRefFramesGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditGeometricRefFramesGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            uiresume(handles.lvd_EditGeometricRefFramesGUI);
        case 'enter'
            uiresume(handles.lvd_EditGeometricRefFramesGUI);
        case 'escape'
            uiresume(handles.lvd_EditGeometricRefFramesGUI);
    end
