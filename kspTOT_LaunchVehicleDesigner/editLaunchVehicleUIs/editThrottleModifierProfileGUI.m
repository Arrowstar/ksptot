function varargout = editThrottleModifierProfileGUI(varargin)
% EDITTHROTTLEMODIFIERPROFILEGUI MATLAB code for editThrottleModifierProfileGUI.fig
%      EDITTHROTTLEMODIFIERPROFILEGUI, by itself, creates a new EDITTHROTTLEMODIFIERPROFILEGUI or raises the existing
%      singleton*.
%
%      H = EDITTHROTTLEMODIFIERPROFILEGUI returns the handle to a new EDITTHROTTLEMODIFIERPROFILEGUI or the handle to
%      the existing singleton*.
%
%      EDITTHROTTLEMODIFIERPROFILEGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EDITTHROTTLEMODIFIERPROFILEGUI.M with the given input arguments.
%
%      EDITTHROTTLEMODIFIERPROFILEGUI('Property','Value',...) creates a new EDITTHROTTLEMODIFIERPROFILEGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before editThrottleModifierProfileGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to editThrottleModifierProfileGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help editThrottleModifierProfileGUI

% Last Modified by GUIDE v2.5 08-Jan-2019 21:37:27

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @editThrottleModifierProfileGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @editThrottleModifierProfileGUI_OutputFcn, ...
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


% --- Executes just before editThrottleModifierProfileGUI is made visible.
function editThrottleModifierProfileGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to editThrottleModifierProfileGUI (see VARARGIN)

% Choose default command line output for editThrottleModifierProfileGUI
    handles.output = hObject;

    throttleCurve = varargin{1};
    setappdata(hObject,'throttleCurve',throttleCurve);

    % Update handles structure
    guidata(hObject, handles);

    populateUI(throttleCurve, handles);
    
    % UIWAIT makes editThrottleModifierProfileGUI wait for user response (see UIRESUME)
    uiwait(handles.editThrottleModifierProfileGUI);

    
function populateUI(throttleCurve, handles)
    handles.titleLabel.String = sprintf('Edit %s Profile', throttleCurve.getCurveName());
    handles.elementsListbox.String = throttleCurve.getListboxStr();
	plotProfile(handles);
    
function plotProfile(handles)
    throttleCurve = getappdata(handles.editThrottleModifierProfileGUI,'throttleCurve');
    [x, y] = throttleCurve.getPlotablePoints();
    
    indMin = throttleCurve.elems(1).minIndepValue;
    if(isnan(indMin))
        indMin = min(x);
    end
    
    indMax = throttleCurve.elems(1).maxIndepValue;
    if(isnan(indMax))
        indMax = max(x);
    end
    
    depMin = throttleCurve.elems(1).minDepValue;
    if(isnan(depMin))
        depMin = min(y);
    end
    
    depMax = throttleCurve.elems(1).maxDepValue;
    if(isnan(depMax))
        depMax = max(y);
    end
    
    xq = linspace(indMin,indMax,1000);
    yq = throttleCurve.evalCurve(xq);
    
    cla(handles.profileAxes,'reset');
    
    hold(handles.profileAxes,'on');
    axes(handles.profileAxes);
    plot(handles.profileAxes,x,y,'ro');
    plot(handles.profileAxes,xq,yq,'b-');
    grid(handles.profileAxes,'minor');
    xlabel(handles.profileAxes,sprintf('%s [%s]', throttleCurve.getIndepVarName(), throttleCurve.getIndepVarUnit()));
    ylabel(handles.profileAxes,sprintf('%s [%s]', throttleCurve.getDepVarName(), throttleCurve.getDepVarUnit()));
    xlim(handles.profileAxes,[indMin,indMax]);
    ylim(handles.profileAxes,[depMin,1.1*depMax]);
    hold(handles.profileAxes,'off');
    
    dcmObj = datacursormode;
    set(dcmObj,'UpdateFcn',@dataTipFormatFunc,'Enable','on');
    
    handles.elementsListbox.TooltipString = throttleCurve.getListboxTooltipStr();
    
    hManager = uigetmodemanager(handles.editThrottleModifierProfileGUI);
    try
        set(hManager.WindowListenerHandles, 'Enable', 'off');  % HG1
    catch
        [hManager.WindowListenerHandles.Enabled] = deal(false);  % HG2
    end
    set(handles.editThrottleModifierProfileGUI, 'WindowKeyPressFcn', @(hObject, eventdata) editThrottleModifierProfileGUI_WindowKeyPressFcn(hObject, eventdata, guidata(handles.editThrottleModifierProfileGUI)));
    
function output_txt = dataTipFormatFunc(obj,event_obj)
% Display the position of the data cursor
% obj          Currently not used (empty)
% event_obj    Handle to event object
% output_txt   Data cursor text string (string or cell array of strings).
    pos = get(event_obj,'Position');
    output_txt = {['X: ',num2str(pos(1),'%12.5f')],...
        ['Y: ',num2str(pos(2),'%12.5f')]};

    % If there is a Z-coordinate in the position, display it as well
    if length(pos) > 2
        output_txt{end+1} = ['Z: ',num2str(pos(3),'%12.5f')];
    end
    
% --- Outputs from this function are returned to the command line.
function varargout = editThrottleModifierProfileGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        
        varargout{1} = true;
        close(handles.editThrottleModifierProfileGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = {};
%     errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.editThrottleModifierProfileGUI);
    else
        msgbox(errMsg,'Invalid Inputs','error');
    end

% --- Executes on selection change in elementsListbox.
function elementsListbox_Callback(hObject, eventdata, handles)
% hObject    handle to elementsListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns elementsListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from elementsListbox
    if(strcmpi(handles.editThrottleModifierProfileGUI.SelectionType,'open'))
        editElementButton_Callback(handles.editElementButton, [], handles);
    end

% --- Executes during object creation, after setting all properties.
function elementsListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to elementsListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addElementButton.
function addElementButton_Callback(hObject, eventdata, handles)
% hObject    handle to addElementButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    throttleCurve = getappdata(handles.editThrottleModifierProfileGUI,'throttleCurve');

    elem = throttleCurve.createNewElement();
    useTf = lvd_editThrottleModifierProfileElementGUI(elem, true, throttleCurve);
    
    if(useTf)
        throttleCurve = getappdata(handles.editThrottleModifierProfileGUI,'throttleCurve');
        throttleCurve.addElement(elem);
        
        populateUI(throttleCurve, handles);
    end

% --- Executes on button press in editElementButton.
function editElementButton_Callback(hObject, eventdata, handles)
% hObject    handle to editElementButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    throttleCurve = getappdata(handles.editThrottleModifierProfileGUI,'throttleCurve');
    elem = getSelectedElem(handles);
    
    if(ismember(elem.indepVar, elem.mandatoryIndepValues))
        allowIndVarEdit = false;
    else
        allowIndVarEdit = true;
    end
    
    useTf = lvd_editThrottleModifierProfileElementGUI(elem, allowIndVarEdit, throttleCurve);
    
    if(useTf)
        throttleCurve = getappdata(handles.editThrottleModifierProfileGUI,'throttleCurve');
        throttleCurve.generateCurve();
        populateUI(throttleCurve, handles);
    end

% --- Executes on button press in deleteElementButton.
function deleteElementButton_Callback(hObject, eventdata, handles)
% hObject    handle to deleteElementButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    elem = getSelectedElem(handles);
    throttleCurve = getappdata(handles.editThrottleModifierProfileGUI,'throttleCurve');
    
    if(ismember(elem.indepVar, elem.mandatoryIndepValues))
        errordlg(sprintf('Cannot delete the endpoint elements at %.1f or %.1f.  The profile must have points at these two locations.',elem.minIndepValue,elem.maxIndepValue));
    else
        throttleCurve.removeElement(elem);
        populateUI(throttleCurve, handles);
    end

function elem = getSelectedElem(handles)
    throttleCurve = getappdata(handles.editThrottleModifierProfileGUI,'throttleCurve');
    [~, elemArr] = throttleCurve.getListboxStr();
    
    ind = get(handles.elementsListbox,'Value');
    elem = elemArr(ind);    


% --- Executes on key press with focus on editThrottleModifierProfileGUI or any of its controls.
function editThrottleModifierProfileGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to editThrottleModifierProfileGUI (see GCBO)
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
            close(handles.editThrottleModifierProfileGUI);
    end
