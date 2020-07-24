function varargout = lvd_EditCalculusObjsGUI(varargin)
% LVD_EDITCALCULUSOBJSGUI MATLAB code for lvd_EditCalculusObjsGUI.fig
%      LVD_EDITCALCULUSOBJSGUI, by itself, creates a new LVD_EDITCALCULUSOBJSGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITCALCULUSOBJSGUI returns the handle to a new LVD_EDITCALCULUSOBJSGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITCALCULUSOBJSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITCALCULUSOBJSGUI.M with the given input arguments.
%
%      LVD_EDITCALCULUSOBJSGUI('Property','Value',...) creates a new LVD_EDITCALCULUSOBJSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditCalculusObjsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditCalculusObjsGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditCalculusObjsGUI

% Last Modified by GUIDE v2.5 23-Jul-2020 19:56:32

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditCalculusObjsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditCalculusObjsGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditCalculusObjsGUI is made visible.
function lvd_EditCalculusObjsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditCalculusObjsGUI (see VARARGIN)

    % Choose default command line output for lvd_EditCalculusObjsGUI
    handles.output = hObject;

    lvdData = varargin{1};
    setappdata(hObject,'lvdData',lvdData);
    
    populateGUI(handles, lvdData);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditCalculusObjsGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditCalculusObjsGUI);

function populateGUI(handles, lvdData)
    set(handles.calcObjListBox,'String',lvdData.launchVehicle.getCalculusCalcObjListBoxStr());
    
    numCalcObjs = length(get(handles.calcObjListBox,'String'));
    if(numCalcObjs <= 0)
        handles.removeCalcObjButton.Enable = 'off';
    end

    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditCalculusObjsGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = [];
    else
        close(handles.lvd_EditCalculusObjsGUI);
    end


% --- Executes on button press in closeButton.
function closeButton_Callback(hObject, eventdata, handles)
% hObject    handle to closeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.lvd_EditCalculusObjsGUI);

% --- Executes on selection change in calcObjListBox.
function calcObjListBox_Callback(hObject, eventdata, handles)
% hObject    handle to calcObjListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns calcObjListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from calcObjListBox
    if(strcmpi(get(handles.lvd_EditCalculusObjsGUI,'SelectionType'),'open'))
        lvdData = getappdata(handles.lvd_EditCalculusObjsGUI,'lvdData');
        lv = lvdData.launchVehicle;

        selCalcObj = get(handles.calcObjListBox,'Value');
        calcObj = lv.getCalculusCalcObjForInd(selCalcObj);
        
        lvd_EditCalculusObjGUI(calcObj, lvdData);
        
        set(handles.calcObjListBox,'String',lvdData.launchVehicle.getCalculusCalcObjListBoxStr());
    end
    

% --- Executes during object creation, after setting all properties.
function calcObjListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to calcObjListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addCalcObjButton.
function addCalcObjButton_Callback(hObject, eventdata, handles)
% hObject    handle to addCalcObjButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditCalculusObjsGUI,'lvdData');
    
    listBoxStr = CalculusCalculationEnum.getListBoxStr();
    [Selection,ok] = listdlgARH('ListString',listBoxStr, ...
                                'SelectionMode','single', ...
                                'PromptString','Select the type of calculus calculation you wish to perform:', ...
                                'Name','Calculation Type');

    if(ok == 1)
        calcObjEnum = CalculusCalculationEnum.getEnumForListboxStr(listBoxStr{Selection});
        switch calcObjEnum
            case CalculusCalculationEnum.Derivative
                calcObj = LaunchVehicleDerivativeCalc(lvdData);
                
            case CalculusCalculationEnum.Integral
                calcObj = LaunchVehicleIntegralCalc(lvdData);
                
            otherwise
                error('Invalid calculus calculation type: %s', class(calcObjEnum));
        end
    
        useCalcObj = lvd_EditCalculusObjGUI(calcObj, lvdData);

        if(useCalcObj)        
            lvdData.launchVehicle.addCalculusCalcObj(calcObj);

            set(handles.calcObjListBox,'String',lvdData.launchVehicle.getCalculusCalcObjListBoxStr());

            if(handles.calcObjListBox.Value <= 0)
                handles.calcObjListBox.Value = 1;
            end

            handles.removeCalcObjButton.Enable = 'on';
        end
    end
    
% --- Executes on button press in removeCalcObjButton.
function removeCalcObjButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeCalcObjButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditCalculusObjsGUI,'lvdData');
    lv = lvdData.launchVehicle;
    
    selCalcObj = get(handles.calcObjListBox,'Value');
    calcObj = lv.getCalculusCalcObjForInd(selCalcObj);
    
    tf = calcObj.isInUse();
    
    if(tf == false)
        lv.removeCalculusCalcObj(calcObj);
        
        set(handles.calcObjListBox,'String',lvdData.launchVehicle.getCalculusCalcObjListBoxStr());
        
        numCalcObj = length(handles.calcObjListBox.String);
        if(selCalcObj > numCalcObj)
            set(handles.calcObjListBox,'Value',numCalcObj);
        end
        
        if(numCalcObj <= 0)
            handles.removeCalcObjButton.Enable = 'off';
        end
    else
        warndlg(sprintf('Could not delete the calculus calculation "%s" because it is in use as part of an event termination condition, event action, objective function, or constraint.  Remove these dependencies before attempting to delete the calculus calculation.', calcObj.getNameStr()),'Cannot Delete Calculus Calculation','modal');
    end


% --- Executes on key press with focus on lvd_EditCalculusObjsGUI or any of its controls.
function lvd_EditCalculusObjsGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditCalculusObjsGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            uiresume(handles.lvd_EditCalculusObjsGUI);
        case 'enter'
            uiresume(handles.lvd_EditCalculusObjsGUI);
        case 'escape'
            uiresume(handles.lvd_EditCalculusObjsGUI);
    end
