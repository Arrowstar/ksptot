function varargout = importOrbitGUI(varargin)
% IMPORTORBITGUI MATLAB code for importOrbitGUI.fig
%      IMPORTORBITGUI, by itself, creates a new IMPORTORBITGUI or raises the existing
%      singleton*.
%
%      H = IMPORTORBITGUI returns the handle to a new IMPORTORBITGUI or the handle to
%      the existing singleton*.
%
%      IMPORTORBITGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IMPORTORBITGUI.M with the given input arguments.
%
%      IMPORTORBITGUI('Property','Value',...) creates a new IMPORTORBITGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before importOrbitGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to importOrbitGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help importOrbitGUI

% Last Modified by GUIDE v2.5 12-Jul-2013 20:21:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @importOrbitGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @importOrbitGUI_OutputFcn, ...
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


% --- Executes just before importOrbitGUI is made visible.
function importOrbitGUI_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to importOrbitGUI (see VARARGIN)

% Choose default command line output for importOrbitGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%Possible fix for people with display issues.
checkForCharUnitsInGUI(hObject);

dataSource = varargin{1}; %-1 = KSP TOT Connect, anything else is from SFS file
if(dataSource == -1)
    hRetDataDlg = helpdlg('Retrieving vessel data from KSPTOT Connect...', 'Retrieving Data');
    try
        guids = readManyStringsFromKSPTOTConnect('GetVesselIDList', '', 32, true);
    catch ME
        if(ishandle(hRetDataDlg))
            close(hRetDataDlg);
        end
        if(ishandle(hObject))
            close(hObject);
        end
        errordlg('Could not retrieve orbit data from KSPTOTConnect.  Is KSP and the KSPTOTConnect plugin running?', 'Retrieval Failure');
        return;
    end
    
    orbits = {};
    for(i=1:length(guids))
        guid = guids{i};
        
        name = readStringFromKSPTOTConnect('GetVesselNameByGUID', guid, true);
        status = readStringFromKSPTOTConnect('GetVesselStatusByGUID', guid, true);
        orbitDbl = readDoublesFromKSPTOTConnect('GetVesselOrbitByGUID', guid, true);
        
        orbits{i,1} = name;
        orbits{i,2} = status;
        orbits{i,3} = orbitDbl(1);
        orbits{i,4} = orbitDbl(2);
        orbits{i,5} = orbitDbl(3);
        orbits{i,6} = orbitDbl(4);
        orbits{i,7} = orbitDbl(5);
        orbits{i,8} = orbitDbl(8);
        orbits{i,9} = orbitDbl(9);
        orbits{i,10} = orbitDbl(13);
    end
    if(ishandle(hRetDataDlg))
        close(hRetDataDlg);
    end
else
    prevPathName = varargin{2};
    if(~isempty(prevPathName))
        defaultName = [prevPathName,'persistent.sfs'];
    else
        defaultName = 'persistent.sfs';
    end

    [FileName,PathName] = uigetfile({'*.sfs','KSP Persistence Files (*.sfs)'},'Select SFS file to load...',defaultName);
    if(not(ischar(FileName)) || not(ischar(PathName)))
        close(hObject);
        return;
    end
    filePath = strcat(PathName,FileName);
    orbits = parseSFSForOrbits(filePath);
  
    set(hObject, 'UserData', {PathName});
end

listBoxStrArr = {};
orbitsNotLanded = {};
for(i=1:size(orbits,1))
    orbit = orbits(i,:);
    if(not(strcmpi(orbit{2},'LANDED')) && not(strcmpi(orbit{2},'SPLASHED')) && not(strcmpi(orbit{2},'PRELAUNCH')))
        listBoxStrArr{end+1} = orbit{1};
        orbitsNotLanded{end+1} = orbit;
    end
end
listboxUserData = {orbitsNotLanded, listBoxStrArr};
set(handles.orbitListBox, 'String', char(listBoxStrArr));
set(handles.orbitListBox, 'UserData', listboxUserData);

orbitListBox_Callback(handles.orbitListBox, [], handles);

% UIWAIT makes importOrbitGUI wait for user response (see UIRESUME)
uiwait(handles.importOrbitGUI);


% --- Outputs from this function are returned to the command line.
function varargout = importOrbitGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
try
    listboxUserData = get(handles.orbitListBox,'UserData');
    importOrbitGUIUserData = get(hObject,'UserData');
    orbits = listboxUserData{1};
    varargout{1} = orbits{get(handles.orbitListBox, 'Value')};
    if(~isempty(importOrbitGUIUserData))
        varargout{2} = importOrbitGUIUserData{1,1};
    else
        varargout{2} = [];
    end
    close(hObject);
catch ME
    varargout{1} = [];
    varargout{2} = [];
end


% --- Executes on selection change in orbitListBox.
function orbitListBox_Callback(hObject, eventdata, handles)
% hObject    handle to orbitListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns orbitListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from orbitListBox
listboxUserData = get(hObject,'UserData');
orbits = listboxUserData{1};

orbitNum = get(hObject,'Value');
if(length(orbits) >= orbitNum)
    orbit = orbits{orbitNum};

    set(handles.smaText, 'String', num2str(orbit{3},9));
    set(handles.eccText, 'String', num2str(orbit{4},9));
    set(handles.incText, 'String', num2str(orbit{5},9));
    set(handles.raanText, 'String', num2str(orbit{6},9));
    set(handles.argText, 'String', num2str(orbit{7},9));
end

% --- Executes during object creation, after setting all properties.
function orbitListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to orbitListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function smaText_Callback(hObject, eventdata, handles)
% hObject    handle to smaText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of smaText as text
%        str2double(get(hObject,'String')) returns contents of smaText as a double


% --- Executes during object creation, after setting all properties.
function smaText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to smaText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function eccText_Callback(hObject, eventdata, handles)
% hObject    handle to eccText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eccText as text
%        str2double(get(hObject,'String')) returns contents of eccText as a double


% --- Executes during object creation, after setting all properties.
function eccText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eccText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function incText_Callback(hObject, eventdata, handles)
% hObject    handle to incText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of incText as text
%        str2double(get(hObject,'String')) returns contents of incText as a double


% --- Executes during object creation, after setting all properties.
function incText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to incText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function raanText_Callback(hObject, eventdata, handles)
% hObject    handle to raanText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of raanText as text
%        str2double(get(hObject,'String')) returns contents of raanText as a double


% --- Executes during object creation, after setting all properties.
function raanText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to raanText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function argText_Callback(hObject, eventdata, handles)
% hObject    handle to argText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of argText as text
%        str2double(get(hObject,'String')) returns contents of argText as a double


% --- Executes during object creation, after setting all properties.
function argText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to argText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in useSelOrbitBtn.
function useSelOrbitBtn_Callback(hObject, eventdata, handles)
% hObject    handle to useSelOrbitBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(handles.importOrbitGUI);
