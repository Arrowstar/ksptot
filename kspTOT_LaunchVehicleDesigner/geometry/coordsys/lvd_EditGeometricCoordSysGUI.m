function varargout = lvd_EditGeometricCoordSysGUI(varargin)
% LVD_EDITGEOMETRICCOORDSYSGUI MATLAB code for lvd_EditGeometricCoordSysGUI.fig
%      LVD_EDITGEOMETRICCOORDSYSGUI, by itself, creates a new LVD_EDITGEOMETRICCOORDSYSGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITGEOMETRICCOORDSYSGUI returns the handle to a new LVD_EDITGEOMETRICCOORDSYSGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITGEOMETRICCOORDSYSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITGEOMETRICCOORDSYSGUI.M with the given input arguments.
%
%      LVD_EDITGEOMETRICCOORDSYSGUI('Property','Value',...) creates a new LVD_EDITGEOMETRICCOORDSYSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditGeometricCoordSysGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditGeometricCoordSysGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditGeometricCoordSysGUI

% Last Modified by GUIDE v2.5 11-Jan-2021 15:07:35

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditGeometricCoordSysGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditGeometricCoordSysGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditGeometricCoordSysGUI is made visible.
function lvd_EditGeometricCoordSysGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditGeometricCoordSysGUI (see VARARGIN)

    % Choose default command line output for lvd_EditGeometricCoordSysGUI
    handles.output = hObject;

    lvdData = varargin{1};
    setappdata(hObject,'lvdData',lvdData);
    
    populateGUI(handles, lvdData);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditGeometricCoordSysGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditGeometricCoordSysGUI);

function populateGUI(handles, lvdData)
    set(handles.coordSysListBox,'String',lvdData.geometry.coordSyses.getListboxStr());
    
    numCoordSys = length(get(handles.coordSysListBox,'String'));
    
    if(handles.coordSysListBox.Value < 1)
        handles.coordSysListBox.Value = 1;
    elseif(handles.coordSysListBox.Value > numCoordSys)
        handles.coordSysListBox.Value = numCoordSys;
    end
    
    if(numCoordSys <= 0)
        handles.removeCoordSysButton.Enable = 'off';
    else
        handles.removeCoordSysButton.Enable = 'on';
    end

    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditGeometricCoordSysGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = [];
    else
        close(handles.lvd_EditGeometricCoordSysGUI);
    end


% --- Executes on button press in closeButton.
function closeButton_Callback(hObject, eventdata, handles)
% hObject    handle to closeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.lvd_EditGeometricCoordSysGUI);

% --- Executes on selection change in coordSysListBox.
function coordSysListBox_Callback(hObject, eventdata, handles)
% hObject    handle to coordSysListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns coordSysListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from coordSysListBox
    lvdData = getappdata(handles.lvd_EditGeometricCoordSysGUI,'lvdData');
    if(strcmpi(get(handles.lvd_EditGeometricCoordSysGUI,'SelectionType'),'open') && ...
       lvdData.geometry.coordSyses.getNumCoordSyses() > 0)
        selCoordSysInd = hObject.Value;
        selCoordSys = lvdData.geometry.coordSyses.getCoordSysAtInd(selCoordSysInd);
        
        selCoordSys.openEditDialog();
        
        populateGUI(handles, lvdData);
    end
    

% --- Executes during object creation, after setting all properties.
function coordSysListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to coordSysListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addCoordSysButton.
function addCoordSysButton_Callback(hObject, eventdata, handles)
% hObject    handle to addCoordSysButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditGeometricCoordSysGUI,'lvdData');
       
    listboxStr = GeometricCoordSysEnum.getListBoxStr();
    [Selection,ok] = listdlgARH('ListString', listboxStr, ...
                                'SelectionMode', 'single', ...
                                'ListSize', [300 300], ...
                                'InitialValue',1, ...
                                'Name', 'Select New Coordinate System Type', ...
                                'PromptString', 'Select the type of the coordinate system to be created:');
                            
    if(ok)
        enum = GeometricCoordSysEnum.getEnumForListboxStr(listboxStr{Selection});
        
        switch enum                
            case GeometricCoordSysEnum.AlignedConstrained
                numVectors = lvdData.geometry.vectors.getNumVectors();
                if(numVectors >= 2)
                    aVector = lvdData.geometry.vectors.getVectorAtInd(1);
                    cVector = lvdData.geometry.vectors.getVectorAtInd(2);
                    newCoordSys = AlignedConstrainedCoordSystem(aVector, AlignedConstrainedCoordSysAxesEnum.PosX, cVector, AlignedConstrainedCoordSysAxesEnum.PosZ, 'New Coordinate System', lvdData);
                    
                else
                    errordlg('Cannot create Aligned/Constrained Coordinate System: There must be at least two unique geometric vectors available.','Cannot Create Coordinate System');
                    return;
                end
                
            otherwise
                error('Unknown Coordinate System Type: %s', enum.name)
        end
        
        useTF = newCoordSys.openEditDialog();
        
        if(useTF)
            lvdData.geometry.coordSyses.addCoordSys(newCoordSys);
            
            populateGUI(handles, lvdData);
        end
    end

    
% --- Executes on button press in removeCoordSysButton.
function removeCoordSysButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeCoordSysButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditGeometricCoordSysGUI,'lvdData');
    
    selCoordSysInd = handles.coordSysListBox.Value;
    selCoordSys = lvdData.geometry.coordSyses.getCoordSysAtInd(selCoordSysInd);

	tf = selCoordSys.isInUse(lvdData);

    if(tf == false)
        lvdData.geometry.coordSyses.removeCoordSys(selCoordSys);
        
        populateGUI(handles, lvdData);

        numCoordSys = lvdData.geometry.coordSyses.getNumCoordSyses();
        if(handles.coordSysListBox.Value > numCoordSys)
            set(handles.coordSysListBox,'Value',numCoordSys);
        end
    else
        warndlg(sprintf('Could not delete the geometric coordinate system "%s" because it is in use as part of a reference frame.  Remove the coordinate system dependencies before attempting to delete the coordinate system.', selCoordSys.getName()),'Cannot Delete Coordinate System','modal');
    end


% --- Executes on key press with focus on lvd_EditGeometricCoordSysGUI or any of its controls.
function lvd_EditGeometricCoordSysGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditGeometricCoordSysGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            uiresume(handles.lvd_EditGeometricCoordSysGUI);
        case 'enter'
            uiresume(handles.lvd_EditGeometricCoordSysGUI);
        case 'escape'
            uiresume(handles.lvd_EditGeometricCoordSysGUI);
    end
