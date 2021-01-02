function varargout = lvd_EditConstraintsGUI(varargin)
% LVD_EDITCONSTRAINTSGUI MATLAB code for lvd_EditConstraintsGUI.fig
%      LVD_EDITCONSTRAINTSGUI, by itself, creates a new LVD_EDITCONSTRAINTSGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITCONSTRAINTSGUI returns the handle to a new LVD_EDITCONSTRAINTSGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITCONSTRAINTSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITCONSTRAINTSGUI.M with the given input arguments.
%
%      LVD_EDITCONSTRAINTSGUI('Property','Value',...) creates a new LVD_EDITCONSTRAINTSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditConstraintsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditConstraintsGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditConstraintsGUI

% Last Modified by GUIDE v2.5 03-Dec-2018 17:19:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditConstraintsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditConstraintsGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditConstraintsGUI is made visible.
function lvd_EditConstraintsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditConstraintsGUI (see VARARGIN)

    % Choose default command line output for lvd_EditConstraintsGUI
    handles.output = hObject;
    
    lvdData = varargin{1};
    setappdata(hObject,'lvdData',lvdData);
    
    populateGUI(handles, lvdData);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditConstraintsGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditConstraintsGUI);

function populateGUI(handles, lvdData)
    set(handles.constraintsListBox,'String',lvdData.optimizer.constraints.getListboxStr());
    
    hListbox = handles.constraintsListBox;
    jScrollPane = findjobj(hListbox);
    jListbox = jScrollPane.getViewport.getComponent(0);
    jListbox = handle(jListbox, 'CallbackProperties');
    
    tooltipStrs = lvdData.optimizer.constraints.getToolboxStrs();
    set(jListbox, 'MouseMovedCallback', @(src, evt) mouseMovedCallback(src, evt, hListbox, tooltipStrs));

    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditConstraintsGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        varargout{1} = true;
        close(handles.lvd_EditConstraintsGUI);
    end


% --- Executes on button press in closeButton.
function closeButton_Callback(hObject, eventdata, handles)
% hObject    handle to closeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.lvd_EditConstraintsGUI);

% --- Executes on selection change in constraintsListBox.
function constraintsListBox_Callback(hObject, eventdata, handles)
% hObject    handle to constraintsListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns constraintsListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from constraintsListBox
    if(strcmpi(get(handles.lvd_EditConstraintsGUI,'SelectionType'),'open'))
        lvdData = getappdata(handles.lvd_EditConstraintsGUI,'lvdData');

        constraintSet = lvdData.optimizer.constraints;
        selConstraint = get(handles.constraintsListBox,'Value');
        constraint = constraintSet.getConstraintForInd(selConstraint);
        
        constraint.openEditConstraintUI(lvdData);

        listBoxStr = constraintSet.getListboxStr();
        set(handles.constraintsListBox,'String',listBoxStr);
    end

% --- Executes during object creation, after setting all properties.
function constraintsListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to constraintsListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addConstraintButton.
function addConstraintButton_Callback(hObject, eventdata, handles)
% hObject    handle to addConstraintButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)    
    lvdData = getappdata(handles.lvd_EditConstraintsGUI,'lvdData');
    
    listBoxStr = ConstraintEnum.getListBoxStr();
    
    [Selection,ok] = listdlg('PromptString','Select the constraint type:',...
                    'SelectionMode','single',...
                    'Name','Constraint Type',...
                    'ListString',listBoxStr, ...
                    'ListSize',[300 300]);
                
    if(ok == 1)
        [~, enum] = ConstraintEnum.getIndForName(listBoxStr{Selection});
        constClass = enum.class;
        input1 = enum.constructorInput1;
        
        newConstraint = eval(sprintf('%s.getDefaultConstraint(%s, %s)', constClass, 'input1', 'lvdData'));
        
        addConstraintTf = newConstraint.openEditConstraintUI(lvdData);
        
        if(addConstraintTf)
            constraintSet = lvdData.optimizer.constraints;  
            constraintSet.addConstraint(newConstraint);
            
            listBoxStr = constraintSet.getListboxStr();
            set(handles.constraintsListBox,'String',listBoxStr);
            
            if(handles.constraintsListBox.Value <= 0)
                handles.constraintsListBox.Value = 1;
            elseif(handles.constraintsListBox.Value > length(listBoxStr))
                handles.constraintsListBox.Value = length(listBoxStr);
            end
        end
    end
    
% --- Executes on button press in removeConstraintButton.
function removeConstraintButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeConstraintButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditConstraintsGUI,'lvdData');
    constraintSet = lvdData.optimizer.constraints;
    
    selConstraint = get(handles.constraintsListBox,'Value');
    constraint = constraintSet.getConstraintForInd(selConstraint);
            
    constraintSet.removeConstraint(constraint);
        
	listBoxStr = constraintSet.getListboxStr();
	set(handles.constraintsListBox,'String',listBoxStr);

	numConstraints = length(listBoxStr);
    if(selConstraint > numConstraints)
        set(handles.constraintsListBox,'Value',numConstraints);
    end


% --- Executes on key press with focus on lvd_EditConstraintsGUI or any of its controls.
function lvd_EditConstraintsGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditConstraintsGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            uiresume(handles.lvd_EditConstraintsGUI);
        case 'enter'
            uiresume(handles.lvd_EditConstraintsGUI);
        case 'escape'
            uiresume(handles.lvd_EditConstraintsGUI);
    end
    
    
% Mouse-movement callback
function mouseMovedCallback(jListbox, jEventData, hListbox, tooltipStrs)
   % Get the currently-hovered list-item
   mousePos = java.awt.Point(jEventData.getX, jEventData.getY);
   hoverIndex = jListbox.locationToIndex(mousePos) + 1;
%    listValues = get(hListbox,'string');
%    hoverValue = listValues{hoverIndex};

   % Modify the tooltip based on the hovered item
   if(hoverIndex > 0 && hoverIndex <= length(tooltipStrs))
       msgStr = tooltipStrs{hoverIndex};
       set(hListbox, 'Tooltip',msgStr);
   else
       set(hListbox, 'Tooltip','');
   end
       
