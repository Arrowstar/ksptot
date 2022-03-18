function varargout = ma_SelectConstraintTypesGUI(varargin)
% MA_SELECTCONSTRAINTTYPESGUI MATLAB code for ma_SelectConstraintTypesGUI.fig
%      MA_SELECTCONSTRAINTTYPESGUI, by itself, creates a new MA_SELECTCONSTRAINTTYPESGUI or raises the existing
%      singleton*.
%
%      H = MA_SELECTCONSTRAINTTYPESGUI returns the handle to a new MA_SELECTCONSTRAINTTYPESGUI or the handle to
%      the existing singleton*.
%
%      MA_SELECTCONSTRAINTTYPESGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_SELECTCONSTRAINTTYPESGUI.M with the given input arguments.
%
%      MA_SELECTCONSTRAINTTYPESGUI('Property','Value',...) creates a new MA_SELECTCONSTRAINTTYPESGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_SelectConstraintTypesGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_SelectConstraintTypesGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_SelectConstraintTypesGUI

% Last Modified by GUIDE v2.5 31-May-2014 21:27:58

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_SelectConstraintTypesGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_SelectConstraintTypesGUI_OutputFcn, ...
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


% --- Executes just before ma_SelectConstraintTypesGUI is made visible.
function ma_SelectConstraintTypesGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_SelectConstraintTypesGUI (see VARARGIN)

% Choose default command line output for ma_SelectConstraintTypesGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ma_SelectConstraintTypesGUI wait for user response (see UIRESUME)
uiwait(handles.maSelectConstraintTypesGUI);


% --- Outputs from this function are returned to the command line.
function varargout = ma_SelectConstraintTypesGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if(isempty(handles))
        varargout{1} = [];
    else
        constNames = {};

        if(get(handles.smaCheckbox,'Value'))
            constNames{end+1} = 'Semi-major Axis';
        end
        if(get(handles.eccCheckbox,'Value'))
            constNames{end+1} = 'Eccentricity';
        end
        if(get(handles.incCheckbox,'Value'))
            constNames{end+1} = 'Inclination';
        end
        if(get(handles.raanCheckbox,'Value'))
            constNames{end+1} = 'Right Asc. of the Asc. Node';
        end
        if(get(handles.argCheckbox,'Value'))
            constNames{end+1} = 'Argument of Periapsis';
        end
        if(get(handles.truCheckbox,'Value'))
            constNames{end+1} = 'True Anomaly';
        end
        if(get(handles.rApCheckbox,'Value'))
            constNames{end+1} = 'Radius of Apoapsis';
        end
        if(get(handles.rPeCheckbox,'Value'))
            constNames{end+1} = 'Radius of Periapsis';
        end
        if(get(handles.longCheckbox,'Value'))
            constNames{end+1} = 'Longitude (East)';
        end
        if(get(handles.latCheckbox,'Value'))
            constNames{end+1} = 'Latitude (North)';
        end
        if(get(handles.cbCheckbox,'Value'))
            constNames{end+1} = 'Central Body ID';
        end
        
        varargout{1} = constNames;
        close(handles.maSelectConstraintTypesGUI);
    end
    

% --- Executes on button press in saveCloseButton.
function saveCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.maSelectConstraintTypesGUI);

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.maSelectConstraintTypesGUI);

% --- Executes on button press in smaCheckbox.
function smaCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to smaCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of smaCheckbox


% --- Executes on button press in incCheckbox.
function incCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to incCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of incCheckbox


% --- Executes on button press in argCheckbox.
function argCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to argCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of argCheckbox


% --- Executes on button press in raanCheckbox.
function raanCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to raanCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of raanCheckbox


% --- Executes on button press in eccCheckbox.
function eccCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to eccCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of eccCheckbox


% --- Executes on button press in truCheckbox.
function truCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to truCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of truCheckbox


% --- Executes on button press in rApCheckbox.
function rApCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to rApCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rApCheckbox


% --- Executes on button press in rPeCheckbox.
function rPeCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to rPeCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rPeCheckbox


% --- Executes on button press in longCheckbox.
function longCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to longCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of longCheckbox


% --- Executes on button press in latCheckbox.
function latCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to latCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of latCheckbox


% --- Executes on button press in cbCheckbox.
function cbCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to cbCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cbCheckbox


% --- Executes on key press with focus on maSelectConstraintTypesGUI or any of its controls.
function maSelectConstraintTypesGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to maSelectConstraintTypesGUI (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            saveCloseButton_Callback(handles.saveCloseButton, [], handles);
        case 'enter'
            saveCloseButton_Callback(handles.saveCloseButton, [], handles);
        case 'escape'
            close(handles.maSelectConstraintTypesGUI);
    end
