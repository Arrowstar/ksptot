function varargout = ma_InsertDVManeuverGUI(varargin)
% MA_INSERTDVMANEUVERGUI MATLAB code for ma_InsertDVManeuverGUI.fig
%      MA_INSERTDVMANEUVERGUI, by itself, creates a new MA_INSERTDVMANEUVERGUI or raises the existing
%      singleton*.
%
%      H = MA_INSERTDVMANEUVERGUI returns the handle to a new MA_INSERTDVMANEUVERGUI or the handle to
%      the existing singleton*.
%
%      MA_INSERTDVMANEUVERGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_INSERTDVMANEUVERGUI.M with the given input arguments.
%
%      MA_INSERTDVMANEUVERGUI('Property','Value',...) creates a new MA_INSERTDVMANEUVERGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_InsertDVManeuverGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_InsertDVManeuverGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_InsertDVManeuverGUI

% Last Modified by GUIDE v2.5 20-Jan-2019 16:32:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_InsertDVManeuverGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_InsertDVManeuverGUI_OutputFcn, ...
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


% --- Executes just before ma_InsertDVManeuverGUI is made visible.
function ma_InsertDVManeuverGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_InsertDVManeuverGUI (see VARARGIN)

% Choose default command line output for ma_InsertDVManeuverGUI
handles.output = hObject;
handles.ma_MainGUI = varargin{1};

% Update handles structure
guidata(hObject, handles);

typeCombo_Callback(handles.typeCombo, eventdata, handles);

if(length(varargin)>1) 
    event = varargin{2};
    if(isstruct(event))
        populateGUIWithEvent(handles, event);
    end
    set(hObject,'UserData',event);
else
    set(hObject,'UserData',[]);
end

% GUI Setup
populateThrusterCombo(handles, handles.thrustersCombo);
optVar1ChkBox_Callback(handles.optVar1ChkBox, [], handles);
optVar2ChkBox_Callback(handles.optVar2ChkBox, [], handles);
optVar3ChkBox_Callback(handles.optVar3ChkBox, [], handles);
% UIWAIT makes ma_InsertDVManeuverGUI wait for user response (see UIRESUME)
uiwait(handles.ma_InsertDVManeuverGUI);

function populateThrusterCombo(handles, hThrustersCombo)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    thrusters = maData.spacecraft.thrusters;
    
    thrusterComboStr = cell(length(thrusters),1);
    for(i=1:length(thrusters)) %#ok<*NO4LP>
        thrusterComboStr{i} = thrusters{i}.name;
    end
    
    set(hThrustersCombo,'String',thrusterComboStr);

    
function populateGUIWithEvent(handles, event)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    
    set(handles.titleLabel, 'String', 'Edit DV Maneuver');
    set(handles.ma_InsertDVManeuverGUI, 'Name', 'Edit DV Maneuver');
    set(handles.nameText, 'String', event.name);
    
    value = event.maneuverValue;
    opt = event.vars;
    
    switch event.maneuverType
        case 'dv_inertial'
            set(handles.typeCombo,'value',findValueFromComboBox('Proscribed Delta-V (Inertial Vector)', handles.typeCombo));
            set(handles.vector1Text,'String',fullAccNum2Str(value(1)*1000)); %convert km/s to m/s
            set(handles.vector2Text,'String',fullAccNum2Str(value(2)*1000)); %convert km/s to m/s
            set(handles.vector3Text,'String',fullAccNum2Str(value(3)*1000)); %convert km/s to m/s
            
            set(handles.optVar1LwrText, 'string', fullAccNum2Str(opt(2,1)*1000));
            set(handles.optVar2LwrText, 'string', fullAccNum2Str(opt(2,2)*1000));
            set(handles.optVar3LwrText, 'string', fullAccNum2Str(opt(2,3)*1000));

            set(handles.optVar1UprText, 'string', fullAccNum2Str(opt(3,1)*1000));
            set(handles.optVar2UprText, 'string', fullAccNum2Str(opt(3,2)*1000));
            set(handles.optVar3UprText, 'string', fullAccNum2Str(opt(3,3)*1000));
        case 'dv_orbit'
            set(handles.typeCombo,'value',findValueFromComboBox('Proscribed Delta-V (Orbital Vector)', handles.typeCombo));
            set(handles.vector1Text,'String',fullAccNum2Str(value(1)*1000)); %convert km/s to m/s
            set(handles.vector2Text,'String',fullAccNum2Str(value(2)*1000)); %convert km/s to m/s
            set(handles.vector3Text,'String',fullAccNum2Str(value(3)*1000)); %convert km/s to m/s
            
            set(handles.optVar1LwrText, 'string', fullAccNum2Str(opt(2,1)*1000));
            set(handles.optVar2LwrText, 'string', fullAccNum2Str(opt(2,2)*1000));
            set(handles.optVar3LwrText, 'string', fullAccNum2Str(opt(2,3)*1000));

            set(handles.optVar1UprText, 'string', fullAccNum2Str(opt(3,1)*1000));
            set(handles.optVar2UprText, 'string', fullAccNum2Str(opt(3,2)*1000));
            set(handles.optVar3UprText, 'string', fullAccNum2Str(opt(3,3)*1000));
        case 'finite_inertial'
            set(handles.typeCombo,'value',findValueFromComboBox('Finite Duration (Inertial Vector)', handles.typeCombo));
            set(handles.vector1Text,'String',fullAccNum2Str(value(1)*1000)); %convert km/s to m/s
            set(handles.vector2Text,'String',fullAccNum2Str(value(2)*1000)); %convert km/s to m/s
            set(handles.vector3Text,'String',fullAccNum2Str(value(3)*1000)); %convert km/s to m/s
            
            set(handles.optVar1LwrText, 'string', fullAccNum2Str(opt(2,1)*1000));
            set(handles.optVar2LwrText, 'string', fullAccNum2Str(opt(2,2)*1000));
            set(handles.optVar3LwrText, 'string', fullAccNum2Str(opt(2,3)*1000));

            set(handles.optVar1UprText, 'string', fullAccNum2Str(opt(3,1)*1000));
            set(handles.optVar2UprText, 'string', fullAccNum2Str(opt(3,2)*1000));
            set(handles.optVar3UprText, 'string', fullAccNum2Str(opt(3,3)*1000));
        case 'finite_steered'
            set(handles.typeCombo,'value',findValueFromComboBox('Finite Duration (Orbital Vector)', handles.typeCombo));
            set(handles.vector1Text,'String',fullAccNum2Str(value(1)*1000)); %convert km/s to m/s
            set(handles.vector2Text,'String',fullAccNum2Str(value(2)*1000)); %convert km/s to m/s
            set(handles.vector3Text,'String',fullAccNum2Str(value(3)*1000)); %convert km/s to m/s
            
            set(handles.optVar1LwrText, 'string', fullAccNum2Str(opt(2,1)*1000));
            set(handles.optVar2LwrText, 'string', fullAccNum2Str(opt(2,2)*1000));
            set(handles.optVar3LwrText, 'string', fullAccNum2Str(opt(2,3)*1000));

            set(handles.optVar1UprText, 'string', fullAccNum2Str(opt(3,1)*1000));
            set(handles.optVar2UprText, 'string', fullAccNum2Str(opt(3,2)*1000));
            set(handles.optVar3UprText, 'string', fullAccNum2Str(opt(3,3)*1000));
        case 'dv_inertial_spherical'
            set(handles.typeCombo,'value',findValueFromComboBox('Proscribed Delta-V (Inertial Spherical)', handles.typeCombo));
            set(handles.vector1Text,'String',fullAccNum2Str(rad2deg(value(1)))); 
            set(handles.vector2Text,'String',fullAccNum2Str(rad2deg(value(2)))); 
            set(handles.vector3Text,'String',fullAccNum2Str(value(3)*1000)); %convert km/s to m/s
            
            set(handles.optVar1LwrText, 'string', fullAccNum2Str(rad2deg(opt(2,1))));
            set(handles.optVar2LwrText, 'string', fullAccNum2Str(rad2deg(opt(2,2))));
            set(handles.optVar3LwrText, 'string', fullAccNum2Str(opt(2,3)*1000));

            set(handles.optVar1UprText, 'string', fullAccNum2Str(rad2deg(opt(3,1))));
            set(handles.optVar2UprText, 'string', fullAccNum2Str(rad2deg(opt(3,2))));
            set(handles.optVar3UprText, 'string', fullAccNum2Str(opt(3,3)*1000));
        case 'dv_orbit_spherical'
            set(handles.typeCombo,'value',findValueFromComboBox('Proscribed Delta-V (Orbital Spherical)', handles.typeCombo));
            set(handles.vector1Text,'String',fullAccNum2Str(rad2deg(value(1)))); 
            set(handles.vector2Text,'String',fullAccNum2Str(rad2deg(value(2)))); 
            set(handles.vector3Text,'String',fullAccNum2Str(value(3)*1000)); %convert km/s to m/s
            
            set(handles.optVar1LwrText, 'string', fullAccNum2Str(rad2deg(opt(2,1))));
            set(handles.optVar2LwrText, 'string', fullAccNum2Str(rad2deg(opt(2,2))));
            set(handles.optVar3LwrText, 'string', fullAccNum2Str(opt(2,3)*1000));

            set(handles.optVar1UprText, 'string', fullAccNum2Str(rad2deg(opt(3,1))));
            set(handles.optVar2UprText, 'string', fullAccNum2Str(rad2deg(opt(3,2))));
            set(handles.optVar3UprText, 'string', fullAccNum2Str(opt(3,3)*1000));
        case 'finite_inertial_spherical'
            set(handles.typeCombo,'value',findValueFromComboBox('Finite Duration (Inertial Spherical)', handles.typeCombo));
            set(handles.vector1Text,'String',fullAccNum2Str(rad2deg(value(1)))); 
            set(handles.vector2Text,'String',fullAccNum2Str(rad2deg(value(2)))); 
            set(handles.vector3Text,'String',fullAccNum2Str(value(3)*1000)); %convert km/s to m/s
            
            set(handles.optVar1LwrText, 'string', fullAccNum2Str(rad2deg(opt(2,1))));
            set(handles.optVar2LwrText, 'string', fullAccNum2Str(rad2deg(opt(2,2))));
            set(handles.optVar3LwrText, 'string', fullAccNum2Str(opt(2,3)*1000));

            set(handles.optVar1UprText, 'string', fullAccNum2Str(rad2deg(opt(3,1))));
            set(handles.optVar2UprText, 'string', fullAccNum2Str(rad2deg(opt(3,2))));
            set(handles.optVar3UprText, 'string', fullAccNum2Str(opt(3,3)*1000));
        case 'finite_steered_spherical'
            set(handles.typeCombo,'value',findValueFromComboBox('Finite Duration (Orbital Spherical)', handles.typeCombo));
            set(handles.vector1Text,'String',fullAccNum2Str(rad2deg(value(1)))); 
            set(handles.vector2Text,'String',fullAccNum2Str(rad2deg(value(2)))); 
            set(handles.vector3Text,'String',fullAccNum2Str(value(3)*1000)); %convert km/s to m/s
            
            set(handles.optVar1LwrText, 'string', fullAccNum2Str(rad2deg(opt(2,1))));
            set(handles.optVar2LwrText, 'string', fullAccNum2Str(rad2deg(opt(2,2))));
            set(handles.optVar3LwrText, 'string', fullAccNum2Str(opt(2,3)*1000));

            set(handles.optVar1UprText, 'string', fullAccNum2Str(rad2deg(opt(3,1))));
            set(handles.optVar2UprText, 'string', fullAccNum2Str(rad2deg(opt(3,2))));
            set(handles.optVar3UprText, 'string', fullAccNum2Str(opt(3,3)*1000));
        case 'circularize'
            set(handles.typeCombo,'value',findValueFromComboBox('Circularize', handles.typeCombo));
    end
    
    set(handles.optVar1ChkBox, 'value', opt(1,1));
    set(handles.optVar2ChkBox, 'value', opt(1,2));
    set(handles.optVar3ChkBox, 'value', opt(1,3));
    
    thrusters = maData.spacecraft.thrusters;
    thrusterVal = 1;
    for(i=1:length(thrusters))
        thrusterFromArr = thrusters{i};
        if(thrusterFromArr.id == event.thruster.id)
            thrusterVal = i;
            break;
        end
    end

    set(handles.thrustersCombo,'value',thrusterVal);
    
    colorStr = getStringFromLineSpecColor(event.lineColor);
    colorValue = findValueFromComboBox(colorStr, handles.manueverLineColorCombo);
    set(handles.manueverLineColorCombo,'value',colorValue);
    
	styleStr = getLineStyleFromString(event.lineStyle);
    styleValue = findValueFromComboBox(styleStr, handles.mnvrLineStyleCombo);
 	set(handles.mnvrLineStyleCombo,'Value',styleValue);
    
    contents = handles.lineWidthCombo.String;
    contentsDouble = str2double(contents);
    ind = find(contentsDouble == event.lineWidth);
    set(handles.lineWidthCombo,'Value',ind);
    

% --- Outputs from this function are returned to the command line.
function varargout = ma_InsertDVManeuverGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if(isempty(handles))
    varargout{1} = [];
else
    name = get(handles.nameText, 'String');
    
    contents = cellstr(get(handles.typeCombo,'String'));
    selected = contents{get(handles.typeCombo,'Value')};
    
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    thrusters = maData.spacecraft.thrusters;
    thrusterNum = get(handles.thrustersCombo,'value');
    thruster = thrusters{thrusterNum};
    
    switch selected
        case 'Proscribed Delta-V (Inertial Vector)';
            vector1 = str2double(get(handles.vector1Text,'String'));
            vector2 = str2double(get(handles.vector2Text,'String'));
            vector3 = str2double(get(handles.vector3Text,'String'));
            vector = [vector1; vector2; vector3]/1000; %store in km/s
                
            vars(1,1) = [get(handles.optVar1ChkBox,'value')];
            vars(1,2) = [get(handles.optVar2ChkBox,'value')];
            vars(1,3) = [get(handles.optVar3ChkBox,'value')];
            
            vars(2,1) = [str2double(get(handles.optVar1LwrText,'string'))] / 1000;
            vars(2,2) = [str2double(get(handles.optVar2LwrText,'string'))] / 1000;
            vars(2,3) = [str2double(get(handles.optVar3LwrText,'string'))] / 1000;
            
            vars(3,1) = [str2double(get(handles.optVar1UprText,'string'))] / 1000;
            vars(3,2) = [str2double(get(handles.optVar2UprText,'string'))] / 1000;
            vars(3,3) = [str2double(get(handles.optVar3UprText,'string'))] / 1000;
            
            maneuverType = 'dv_inertial';
        case 'Proscribed Delta-V (Orbital Vector)';
            vector1 = str2double(get(handles.vector1Text,'String'));
            vector2 = str2double(get(handles.vector2Text,'String'));
            vector3 = str2double(get(handles.vector3Text,'String'));
            vector = [vector1; vector2; vector3]/1000; %store in km/s
            
            vars(1,1) = [get(handles.optVar1ChkBox,'value')];
            vars(1,2) = [get(handles.optVar2ChkBox,'value')];
            vars(1,3) = [get(handles.optVar3ChkBox,'value')];
            
            vars(2,1) = [str2double(get(handles.optVar1LwrText,'string'))] / 1000;
            vars(2,2) = [str2double(get(handles.optVar2LwrText,'string'))] / 1000;
            vars(2,3) = [str2double(get(handles.optVar3LwrText,'string'))] / 1000;
            
            vars(3,1) = [str2double(get(handles.optVar1UprText,'string'))] / 1000;
            vars(3,2) = [str2double(get(handles.optVar2UprText,'string'))] / 1000;
            vars(3,3) = [str2double(get(handles.optVar3UprText,'string'))] / 1000;
            
            maneuverType = 'dv_orbit';
        case 'Finite Duration (Inertial Vector)'
            vector1 = str2double(get(handles.vector1Text,'String'));
            vector2 = str2double(get(handles.vector2Text,'String'));
            vector3 = str2double(get(handles.vector3Text,'String'));
            vector = [vector1; vector2; vector3]/1000; %store in km/s
                
            vars(1,1) = [get(handles.optVar1ChkBox,'value')];
            vars(1,2) = [get(handles.optVar2ChkBox,'value')];
            vars(1,3) = [get(handles.optVar3ChkBox,'value')];
            
            vars(2,1) = [str2double(get(handles.optVar1LwrText,'string'))] / 1000;
            vars(2,2) = [str2double(get(handles.optVar2LwrText,'string'))] / 1000;
            vars(2,3) = [str2double(get(handles.optVar3LwrText,'string'))] / 1000;
            
            vars(3,1) = [str2double(get(handles.optVar1UprText,'string'))] / 1000;
            vars(3,2) = [str2double(get(handles.optVar2UprText,'string'))] / 1000;
            vars(3,3) = [str2double(get(handles.optVar3UprText,'string'))] / 1000;
            
            maneuverType = 'finite_inertial';
        case 'Finite Duration (Orbital Vector)'  
            vector1 = str2double(get(handles.vector1Text,'String'));
            vector2 = str2double(get(handles.vector2Text,'String'));
            vector3 = str2double(get(handles.vector3Text,'String'));
            vector = [vector1; vector2; vector3]/1000; %store in km/s
            
            vars(1,1) = [get(handles.optVar1ChkBox,'value')];
            vars(1,2) = [get(handles.optVar2ChkBox,'value')];
            vars(1,3) = [get(handles.optVar3ChkBox,'value')];
            
            vars(2,1) = [str2double(get(handles.optVar1LwrText,'string'))] / 1000;
            vars(2,2) = [str2double(get(handles.optVar2LwrText,'string'))] / 1000;
            vars(2,3) = [str2double(get(handles.optVar3LwrText,'string'))] / 1000;
            
            vars(3,1) = [str2double(get(handles.optVar1UprText,'string'))] / 1000;
            vars(3,2) = [str2double(get(handles.optVar2UprText,'string'))] / 1000;
            vars(3,3) = [str2double(get(handles.optVar3UprText,'string'))] / 1000;
            
            maneuverType = 'finite_steered';
        case 'Proscribed Delta-V (Inertial Spherical)'   
            vector1 = deg2rad(str2double(get(handles.vector1Text,'String')));
            vector2 = deg2rad(str2double(get(handles.vector2Text,'String')));
            vector3 = str2double(get(handles.vector3Text,'String'))/1000;
            vector = [vector1; vector2; vector3]; %store in km/s
                
            vars(1,1) = [get(handles.optVar1ChkBox,'value')];
            vars(1,2) = [get(handles.optVar2ChkBox,'value')];
            vars(1,3) = [get(handles.optVar3ChkBox,'value')];
            
            vars(2,1) = [deg2rad(str2double(get(handles.optVar1LwrText,'string')))];
            vars(2,2) = [deg2rad(str2double(get(handles.optVar2LwrText,'string')))];
            vars(2,3) = [str2double(get(handles.optVar3LwrText,'string'))] / 1000; %store in km/s
            
            vars(3,1) = [deg2rad(str2double(get(handles.optVar1UprText,'string')))];
            vars(3,2) = [deg2rad(str2double(get(handles.optVar2UprText,'string')))];
            vars(3,3) = [str2double(get(handles.optVar3UprText,'string'))] / 1000; %store in km/s
            
            maneuverType = 'dv_inertial_spherical';
        case 'Proscribed Delta-V (Orbital Spherical)'
            vector1 = deg2rad(str2double(get(handles.vector1Text,'String')));
            vector2 = deg2rad(str2double(get(handles.vector2Text,'String')));
            vector3 = str2double(get(handles.vector3Text,'String'))/1000;
            vector = [vector1; vector2; vector3]; %store in km/s
                
            vars(1,1) = [get(handles.optVar1ChkBox,'value')];
            vars(1,2) = [get(handles.optVar2ChkBox,'value')];
            vars(1,3) = [get(handles.optVar3ChkBox,'value')];
            
            vars(2,1) = [deg2rad(str2double(get(handles.optVar1LwrText,'string')))];
            vars(2,2) = [deg2rad(str2double(get(handles.optVar2LwrText,'string')))];
            vars(2,3) = [str2double(get(handles.optVar3LwrText,'string'))] / 1000; %store in km/s
            
            vars(3,1) = [deg2rad(str2double(get(handles.optVar1UprText,'string')))];
            vars(3,2) = [deg2rad(str2double(get(handles.optVar2UprText,'string')))];
            vars(3,3) = [str2double(get(handles.optVar3UprText,'string'))] / 1000; %store in km/s
            
            maneuverType = 'dv_orbit_spherical';
        case 'Finite Duration (Inertial Spherical)'
            vector1 = deg2rad(str2double(get(handles.vector1Text,'String')));
            vector2 = deg2rad(str2double(get(handles.vector2Text,'String')));
            vector3 = str2double(get(handles.vector3Text,'String'))/1000;
            vector = [vector1; vector2; vector3]; %store in km/s
                
            vars(1,1) = [get(handles.optVar1ChkBox,'value')];
            vars(1,2) = [get(handles.optVar2ChkBox,'value')];
            vars(1,3) = [get(handles.optVar3ChkBox,'value')];
            
            vars(2,1) = [deg2rad(str2double(get(handles.optVar1LwrText,'string')))];
            vars(2,2) = [deg2rad(str2double(get(handles.optVar2LwrText,'string')))];
            vars(2,3) = [str2double(get(handles.optVar3LwrText,'string'))] / 1000; %store in km/s
            
            vars(3,1) = [deg2rad(str2double(get(handles.optVar1UprText,'string')))];
            vars(3,2) = [deg2rad(str2double(get(handles.optVar2UprText,'string')))];
            vars(3,3) = [str2double(get(handles.optVar3UprText,'string'))] / 1000; %store in km/s
            
            maneuverType = 'finite_inertial_spherical';
        case 'Finite Duration (Orbital Spherical)'
            vector1 = deg2rad(str2double(get(handles.vector1Text,'String')));
            vector2 = deg2rad(str2double(get(handles.vector2Text,'String')));
            vector3 = str2double(get(handles.vector3Text,'String'))/1000;
            vector = [vector1; vector2; vector3]; %store in km/s
                
            vars(1,1) = [get(handles.optVar1ChkBox,'value')];
            vars(1,2) = [get(handles.optVar2ChkBox,'value')];
            vars(1,3) = [get(handles.optVar3ChkBox,'value')];
            
            vars(2,1) = [deg2rad(str2double(get(handles.optVar1LwrText,'string')))];
            vars(2,2) = [deg2rad(str2double(get(handles.optVar2LwrText,'string')))];
            vars(2,3) = [str2double(get(handles.optVar3LwrText,'string'))] / 1000; %store in km/s
            
            vars(3,1) = [deg2rad(str2double(get(handles.optVar1UprText,'string')))];
            vars(3,2) = [deg2rad(str2double(get(handles.optVar2UprText,'string')))];
            vars(3,3) = [str2double(get(handles.optVar3UprText,'string'))] / 1000; %store in km/s
            
            maneuverType = 'finite_steered_spherical';
        case 'Circularize';
            vector = [];
            
            vars = [0 0 0; 0 0 0; 0 0 0];
            
            maneuverType = 'circularize';
    end
    
    contents = cellstr(get(handles.manueverLineColorCombo,'String'));
	colorStr = contents{get(handles.manueverLineColorCombo,'Value')};
    lineSpecColor = getLineSpecColorFromString(colorStr);
    
    contents = cellstr(get(handles.mnvrLineStyleCombo,'String'));
    lineStyleStr = contents{get(handles.mnvrLineStyleCombo,'Value')};
    lineStyle = getLineStyleStrFromText(lineStyleStr);
    
    contents = handles.lineWidthCombo.String;
    contentsDouble = str2double(contents);
    contensInd = get(handles.lineWidthCombo,'Value');
    lineWidth = contentsDouble(contensInd);
    
    varargout{1} = ma_createDVManeuver(name, maneuverType, vector, thruster, vars, lineSpecColor, lineStyle, lineWidth);
    close(handles.ma_InsertDVManeuverGUI);
end

% --- Executes on selection change in typeCombo.
function typeCombo_Callback(hObject, eventdata, handles)
% hObject    handle to typeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns typeCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from typeCombo
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    stateLog = maData.stateLog;
    script = maData.script;
    event = get(handles.ma_InsertDVManeuverGUI,'UserData');

    if(~isempty(event) && isstruct(event))
        for(i=1:length(script))
            if(script{i}.id == event.id)
                eventNum = i;
                break;
            else
                eventNum = [];
            end
        end

        preEventLog = stateLog(stateLog(:,13)==eventNum-1,:);
        eventLog = stateLog(stateLog(:,13)==eventNum,:);
        
        stateRowPreEvent = preEventLog(end,:);
        stateRowEvent = eventLog(end,:);
    elseif(~isempty(event) && isnumeric(event))
        eventNum = event+1;
        preEventLog = stateLog(stateLog(:,13)==eventNum-1,:);
        eventLog = stateLog(stateLog(:,13)==eventNum,:);
        
        stateRowPreEvent = preEventLog(end,:);
        stateRowEvent = stateRowPreEvent;
    else
        eventNum = [];
        stateRowPreEvent = [];
        stateRowEvent = [];
    end

    contents = cellstr(get(hObject,'String'));
    selected = contents{get(hObject,'Value')};
    
    switch selected
        case 'Proscribed Delta-V (Inertial Vector)';
            set(handles.vector1Text,'Enable','on');
            set(handles.vector2Text,'Enable','on');
            set(handles.vector3Text,'Enable','on');
            
            set(handles.vector1Label,'String','X');
            set(handles.vector2Label,'String','Y');
            set(handles.vector3Label,'String','Z');
            
            if(~isempty(eventNum))
                returnValue = ma_convertDVManeuverValue(stateRowPreEvent, stateRowEvent, selected);
                if(~isempty(returnValue))
                    set(handles.vector1Text, 'String', num2str(returnValue(1),'%15.10f'));
                    set(handles.vector2Text, 'String', num2str(returnValue(2),'%15.10f'));
                    set(handles.vector3Text, 'String', num2str(returnValue(3),'%15.10f'));
                end
            end
            
            set(handles.optVar1LwrText, 'TooltipString', 'Optimization lower bound for Inertial DV Vector X');
            set(handles.optVar2LwrText, 'TooltipString', 'Optimization lower bound for Inertial DV Vector Y');
            set(handles.optVar3LwrText, 'TooltipString', 'Optimization lower bound for Inertial DV Vector Z');
            
            set(handles.optVar1UprText, 'TooltipString', 'Optimization upper bound for Inertial DV Vector X');
            set(handles.optVar2UprText, 'TooltipString', 'Optimization upper bound for Inertial DV Vector Y');
            set(handles.optVar3UprText, 'TooltipString', 'Optimization upper bound for Inertial DV Vector Z');
            
            set(handles.optVar1ChkBox, 'Enable', 'on');
            set(handles.optVar2ChkBox, 'Enable', 'on');
            set(handles.optVar3ChkBox, 'Enable', 'on');
            
            set(handles.optVar1LwrText, 'Enable', 'on');
            set(handles.optVar2LwrText, 'Enable', 'on');
            set(handles.optVar3LwrText, 'Enable', 'on');
            
            set(handles.optVar1UprText, 'Enable', 'on');
            set(handles.optVar2UprText, 'Enable', 'on');
            set(handles.optVar3UprText, 'Enable', 'on');
            
            set(handles.vector1UnitLabel, 'String', 'm/s');
            set(handles.vector2UnitLabel, 'String', 'm/s');
            set(handles.vector3UnitLabel, 'String', 'm/s');
            
            set(handles.estBurnLabel,'Visible','off');
            set(handles.finiteDurBurnWarnLabel,'Visible','off');
        case 'Proscribed Delta-V (Orbital Vector)';
            set(handles.vector1Text,'Enable','on');
            set(handles.vector2Text,'Enable','on');
            set(handles.vector3Text,'Enable','on');
            
            set(handles.vector1Label,'String','Prograde');
            set(handles.vector2Label,'String','Normal');
            set(handles.vector3Label,'String','Radial');
            
            if(~isempty(eventNum))
                returnValue = ma_convertDVManeuverValue(stateRowPreEvent, stateRowEvent, selected);
                if(~isempty(returnValue))
                    set(handles.vector1Text, 'String', num2str(returnValue(1),'%15.10f'));
                    set(handles.vector2Text, 'String', num2str(returnValue(2),'%15.10f'));
                    set(handles.vector3Text, 'String', num2str(returnValue(3),'%15.10f'));
                end
            end
            
            set(handles.optVar1LwrText, 'TooltipString', 'Optimization lower bound for Orbital DV Vector P');
            set(handles.optVar2LwrText, 'TooltipString', 'Optimization lower bound for Orbital DV Vector N');
            set(handles.optVar3LwrText, 'TooltipString', 'Optimization lower bound for Orbital DV Vector R');
            
            set(handles.optVar1UprText, 'TooltipString', 'Optimization upper bound for Orbital DV Vector P');
            set(handles.optVar2UprText, 'TooltipString', 'Optimization upper bound for Orbital DV Vector N');
            set(handles.optVar3UprText, 'TooltipString', 'Optimization upper bound for Orbital DV Vector R');
            
            set(handles.optVar1ChkBox, 'Enable', 'on');
            set(handles.optVar2ChkBox, 'Enable', 'on');
            set(handles.optVar3ChkBox, 'Enable', 'on');
            
            set(handles.optVar1LwrText, 'Enable', 'on');
            set(handles.optVar2LwrText, 'Enable', 'on');
            set(handles.optVar3LwrText, 'Enable', 'on');
            
            set(handles.optVar1UprText, 'Enable', 'on');
            set(handles.optVar2UprText, 'Enable', 'on');
            set(handles.optVar3UprText, 'Enable', 'on');
            
            set(handles.vector1UnitLabel, 'String', 'm/s');
            set(handles.vector2UnitLabel, 'String', 'm/s');
            set(handles.vector3UnitLabel, 'String', 'm/s');
            
            set(handles.estBurnLabel,'Visible','off');
            set(handles.finiteDurBurnWarnLabel,'Visible','off');
        case 'Finite Duration (Inertial Vector)'
            set(handles.vector1Text,'Enable','on');
            set(handles.vector2Text,'Enable','on');
            set(handles.vector3Text,'Enable','on');
            
            set(handles.vector1Label,'String','X');
            set(handles.vector2Label,'String','Y');
            set(handles.vector3Label,'String','Z');
                        
            set(handles.optVar1LwrText, 'TooltipString', 'Optimization lower bound for Inertial DV Vector X');
            set(handles.optVar2LwrText, 'TooltipString', 'Optimization lower bound for Inertial DV Vector Y');
            set(handles.optVar3LwrText, 'TooltipString', 'Optimization lower bound for Inertial DV Vector Z');
            
            set(handles.optVar1UprText, 'TooltipString', 'Optimization upper bound for Inertial DV Vector X');
            set(handles.optVar2UprText, 'TooltipString', 'Optimization upper bound for Inertial DV Vector Y');
            set(handles.optVar3UprText, 'TooltipString', 'Optimization upper bound for Inertial DV Vector Z');
            
            set(handles.optVar1ChkBox, 'Enable', 'on');
            set(handles.optVar2ChkBox, 'Enable', 'on');
            set(handles.optVar3ChkBox, 'Enable', 'on');
            
            set(handles.optVar1LwrText, 'Enable', 'on');
            set(handles.optVar2LwrText, 'Enable', 'on');
            set(handles.optVar3LwrText, 'Enable', 'on');
            
            set(handles.optVar1UprText, 'Enable', 'on');
            set(handles.optVar2UprText, 'Enable', 'on');
            set(handles.optVar3UprText, 'Enable', 'on');
            
            set(handles.vector1UnitLabel, 'String', 'm/s');
            set(handles.vector2UnitLabel, 'String', 'm/s');
            set(handles.vector3UnitLabel, 'String', 'm/s');
            
            set(handles.estBurnLabel,'Visible','on');
            set(handles.finiteDurBurnWarnLabel,'Visible','on');
            
            recomputeBurnDurStr(handles);
        case 'Finite Duration (Orbital Vector)'
            set(handles.vector1Text,'Enable','on');
            set(handles.vector2Text,'Enable','on');
            set(handles.vector3Text,'Enable','on');
            
            set(handles.vector1Label,'String','Prograde');
            set(handles.vector2Label,'String','Normal');
            set(handles.vector3Label,'String','Radial');
                       
            set(handles.optVar1LwrText, 'TooltipString', 'Optimization lower bound for Orbital DV Vector P');
            set(handles.optVar2LwrText, 'TooltipString', 'Optimization lower bound for Orbital DV Vector N');
            set(handles.optVar3LwrText, 'TooltipString', 'Optimization lower bound for Orbital DV Vector R');
            
            set(handles.optVar1UprText, 'TooltipString', 'Optimization upper bound for Orbital DV Vector P');
            set(handles.optVar2UprText, 'TooltipString', 'Optimization upper bound for Orbital DV Vector N');
            set(handles.optVar3UprText, 'TooltipString', 'Optimization upper bound for Orbital DV Vector R');
            
            set(handles.optVar1ChkBox, 'Enable', 'on');
            set(handles.optVar2ChkBox, 'Enable', 'on');
            set(handles.optVar3ChkBox, 'Enable', 'on');
            
            set(handles.optVar1LwrText, 'Enable', 'on');
            set(handles.optVar2LwrText, 'Enable', 'on');
            set(handles.optVar3LwrText, 'Enable', 'on');
            
            set(handles.optVar1UprText, 'Enable', 'on');
            set(handles.optVar2UprText, 'Enable', 'on');
            set(handles.optVar3UprText, 'Enable', 'on');
            
            set(handles.vector1UnitLabel, 'String', 'm/s');
            set(handles.vector2UnitLabel, 'String', 'm/s');
            set(handles.vector3UnitLabel, 'String', 'm/s');
            
            set(handles.estBurnLabel,'Visible','on');
            set(handles.finiteDurBurnWarnLabel,'Visible','on');
            
            recomputeBurnDurStr(handles);
            
        case 'Proscribed Delta-V (Inertial Spherical)'  
            set(handles.vector1Text,'Enable','on');
            set(handles.vector2Text,'Enable','on');
            set(handles.vector3Text,'Enable','on');
            
            set(handles.vector1Label,'String','Az.');
            set(handles.vector2Label,'String','El.');
            set(handles.vector3Label,'String','DV Mag.');
            
            if(~isempty(eventNum))
                returnValue = ma_convertDVManeuverValue(stateRowPreEvent, stateRowEvent, selected);
                if(~isempty(returnValue))
                    set(handles.vector1Text, 'String', num2str(returnValue(1),'%15.10f'));
                    set(handles.vector2Text, 'String', num2str(returnValue(2),'%15.10f'));
                    set(handles.vector3Text, 'String', num2str(returnValue(3),'%15.10f'));
                end
            end
            
            set(handles.optVar1LwrText, 'TooltipString', 'Optimization lower bound for Inertial Azimuth Angle');
            set(handles.optVar2LwrText, 'TooltipString', 'Optimization lower bound for Inertial Elevation Angle');
            set(handles.optVar3LwrText, 'TooltipString', 'Optimization lower bound for Inertial Delta-v Magnitude');
            
            set(handles.optVar1UprText, 'TooltipString', 'Optimization upper bound for Inertial Azimuth Angle');
            set(handles.optVar2UprText, 'TooltipString', 'Optimization upper bound for Inertial Elevation Angle');
            set(handles.optVar3UprText, 'TooltipString', 'Optimization upper bound for Inertial Delta-v Magnitude');
            
            set(handles.optVar1ChkBox, 'Enable', 'on');
            set(handles.optVar2ChkBox, 'Enable', 'on');
            set(handles.optVar3ChkBox, 'Enable', 'on');
            
            set(handles.optVar1LwrText, 'Enable', 'on');
            set(handles.optVar2LwrText, 'Enable', 'on');
            set(handles.optVar3LwrText, 'Enable', 'on');
            
            set(handles.optVar1UprText, 'Enable', 'on');
            set(handles.optVar2UprText, 'Enable', 'on');
            set(handles.optVar3UprText, 'Enable', 'on');
            
            set(handles.vector1UnitLabel, 'String', 'deg');
            set(handles.vector2UnitLabel, 'String', 'deg');
            set(handles.vector3UnitLabel, 'String', 'm/s');
            
            set(handles.estBurnLabel,'Visible','off');
            set(handles.finiteDurBurnWarnLabel,'Visible','off');
            
        case 'Proscribed Delta-V (Orbital Spherical)'
            set(handles.vector1Text,'Enable','on');
            set(handles.vector2Text,'Enable','on');
            set(handles.vector3Text,'Enable','on');
            
            set(handles.vector1Label,'String','Az.');
            set(handles.vector2Label,'String','El.');
            set(handles.vector3Label,'String','DV Mag.');
            
            if(~isempty(eventNum))
                returnValue = ma_convertDVManeuverValue(stateRowPreEvent, stateRowEvent, selected);
                if(~isempty(returnValue))
                    set(handles.vector1Text, 'String', num2str(returnValue(1),'%15.10f'));
                    set(handles.vector2Text, 'String', num2str(returnValue(2),'%15.10f'));
                    set(handles.vector3Text, 'String', num2str(returnValue(3),'%15.10f'));
                end
            end
            
            set(handles.optVar1LwrText, 'TooltipString', 'Optimization lower bound for Orbital Azimuth Angle');
            set(handles.optVar2LwrText, 'TooltipString', 'Optimization lower bound for Orbital Elevation Angle');
            set(handles.optVar3LwrText, 'TooltipString', 'Optimization lower bound for Orbital Delta-v Magnitude');
            
            set(handles.optVar1UprText, 'TooltipString', 'Optimization upper bound for Orbital Azimuth Angle');
            set(handles.optVar2UprText, 'TooltipString', 'Optimization upper bound for Orbital Elevation Angle');
            set(handles.optVar3UprText, 'TooltipString', 'Optimization upper bound for Orbital Delta-v Magnitude');
            
            set(handles.optVar1ChkBox, 'Enable', 'on');
            set(handles.optVar2ChkBox, 'Enable', 'on');
            set(handles.optVar3ChkBox, 'Enable', 'on');
            
            set(handles.optVar1LwrText, 'Enable', 'on');
            set(handles.optVar2LwrText, 'Enable', 'on');
            set(handles.optVar3LwrText, 'Enable', 'on');
            
            set(handles.optVar1UprText, 'Enable', 'on');
            set(handles.optVar2UprText, 'Enable', 'on');
            set(handles.optVar3UprText, 'Enable', 'on');
            
            set(handles.vector1UnitLabel, 'String', 'deg');
            set(handles.vector2UnitLabel, 'String', 'deg');
            set(handles.vector3UnitLabel, 'String', 'm/s');
            
            set(handles.estBurnLabel,'Visible','off');
            set(handles.finiteDurBurnWarnLabel,'Visible','off');
            
        case 'Finite Duration (Inertial Spherical)'
            set(handles.vector1Text,'Enable','on');
            set(handles.vector2Text,'Enable','on');
            set(handles.vector3Text,'Enable','on');
            
            set(handles.vector1Label,'String','Az.');
            set(handles.vector2Label,'String','El.');
            set(handles.vector3Label,'String','DV Mag.');
            
            set(handles.optVar1LwrText, 'TooltipString', 'Optimization lower bound for Inertial Azimuth Angle');
            set(handles.optVar2LwrText, 'TooltipString', 'Optimization lower bound for Inertial Elevation Angle');
            set(handles.optVar3LwrText, 'TooltipString', 'Optimization lower bound for Inertial Delta-v Magnitude');
            
            set(handles.optVar1UprText, 'TooltipString', 'Optimization upper bound for Inertial Azimuth Angle');
            set(handles.optVar2UprText, 'TooltipString', 'Optimization upper bound for Inertial Elevation Angle');
            set(handles.optVar3UprText, 'TooltipString', 'Optimization upper bound for Inertial Delta-v Magnitude');
            
            set(handles.optVar1ChkBox, 'Enable', 'on');
            set(handles.optVar2ChkBox, 'Enable', 'on');
            set(handles.optVar3ChkBox, 'Enable', 'on');
            
            set(handles.optVar1LwrText, 'Enable', 'on');
            set(handles.optVar2LwrText, 'Enable', 'on');
            set(handles.optVar3LwrText, 'Enable', 'on');
            
            set(handles.optVar1UprText, 'Enable', 'on');
            set(handles.optVar2UprText, 'Enable', 'on');
            set(handles.optVar3UprText, 'Enable', 'on');
            
            set(handles.vector1UnitLabel, 'String', 'deg');
            set(handles.vector2UnitLabel, 'String', 'deg');
            set(handles.vector3UnitLabel, 'String', 'm/s');
            
            set(handles.estBurnLabel,'Visible','on');
            set(handles.finiteDurBurnWarnLabel,'Visible','on');
            
            recomputeBurnDurStr(handles);
            
        case 'Finite Duration (Orbital Spherical)'
            set(handles.vector1Text,'Enable','on');
            set(handles.vector2Text,'Enable','on');
            set(handles.vector3Text,'Enable','on');
            
            set(handles.vector1Label,'String','Az.');
            set(handles.vector2Label,'String','El.');
            set(handles.vector3Label,'String','DV Mag.');
            
            set(handles.optVar1LwrText, 'TooltipString', 'Optimization lower bound for Orbital Azimuth Angle');
            set(handles.optVar2LwrText, 'TooltipString', 'Optimization lower bound for Orbital Elevation Angle');
            set(handles.optVar3LwrText, 'TooltipString', 'Optimization lower bound for Orbital Delta-v Magnitude');
            
            set(handles.optVar1UprText, 'TooltipString', 'Optimization upper bound for Orbital Azimuth Angle');
            set(handles.optVar2UprText, 'TooltipString', 'Optimization upper bound for Orbital Elevation Angle');
            set(handles.optVar3UprText, 'TooltipString', 'Optimization upper bound for Orbital Delta-v Magnitude');
            
            set(handles.optVar1ChkBox, 'Enable', 'on');
            set(handles.optVar2ChkBox, 'Enable', 'on');
            set(handles.optVar3ChkBox, 'Enable', 'on');
            
            set(handles.optVar1LwrText, 'Enable', 'on');
            set(handles.optVar2LwrText, 'Enable', 'on');
            set(handles.optVar3LwrText, 'Enable', 'on');
            
            set(handles.optVar1UprText, 'Enable', 'on');
            set(handles.optVar2UprText, 'Enable', 'on');
            set(handles.optVar3UprText, 'Enable', 'on');
            
            set(handles.vector1UnitLabel, 'String', 'deg');
            set(handles.vector2UnitLabel, 'String', 'deg');
            set(handles.vector3UnitLabel, 'String', 'm/s');
            
            set(handles.estBurnLabel,'Visible','on');
            set(handles.finiteDurBurnWarnLabel,'Visible','on');
            
            recomputeBurnDurStr(handles);                  
            
        case 'Circularize';
            set(handles.vector1Text,'Enable','off');
            set(handles.vector2Text,'Enable','off');
            set(handles.vector3Text,'Enable','off');
            
            set(handles.optVar1LwrText, 'TooltipString', '');
            set(handles.optVar2LwrText, 'TooltipString', '');
            set(handles.optVar3LwrText, 'TooltipString', '');
            
            set(handles.optVar1UprText, 'TooltipString', '');
            set(handles.optVar2UprText, 'TooltipString', '');
            set(handles.optVar3UprText, 'TooltipString', '');
            
            set(handles.optVar1ChkBox, 'Enable', 'off');
            set(handles.optVar2ChkBox, 'Enable', 'off');
            set(handles.optVar3ChkBox, 'Enable', 'off');
            
            set(handles.optVar1LwrText, 'Enable', 'off');
            set(handles.optVar2LwrText, 'Enable', 'off');
            set(handles.optVar3LwrText, 'Enable', 'off');
            
            set(handles.optVar1UprText, 'Enable', 'off');
            set(handles.optVar2UprText, 'Enable', 'off');
            set(handles.optVar3UprText, 'Enable', 'off');
            
            set(handles.vector1UnitLabel, 'String', 'm/s');
            set(handles.vector2UnitLabel, 'String', 'm/s');
            set(handles.vector3UnitLabel, 'String', 'm/s');
            
            set(handles.estBurnLabel,'Visible','off');
            set(handles.finiteDurBurnWarnLabel,'Visible','off');
    end

% --- Executes during object creation, after setting all properties.
function typeCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to typeCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function nameText_Callback(hObject, eventdata, handles)
% hObject    handle to nameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nameText as text
%        str2double(get(hObject,'String')) returns contents of nameText as a double


% --- Executes during object creation, after setting all properties.
function nameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in saveCloseButton.
function saveCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);

    if(isempty(errMsg))
        uiresume(handles.ma_InsertDVManeuverGUI);
    else
        msgbox(errMsg,'Errors were found while inserting a delta-v maneuver.','error');
    end
    
    
function errMsg = validateInputs(handles)
    errMsg = {};
    contents = cellstr(get(handles.typeCombo,'String'));
    selected = contents{get(handles.typeCombo,'Value')};
    
    switch selected
        case 'Proscribed Delta-V (Inertial Vector)';
            vector1 = str2double(get(handles.vector1Text,'String'));
            enteredStr = get(handles.vector1Text,'String');
            numberName = 'DV Vector X Component';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector1, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector2 = str2double(get(handles.vector2Text,'String'));
            enteredStr = get(handles.vector2Text,'String');
            numberName = 'DV Vector Y Component';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector2, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector3 = str2double(get(handles.vector3Text,'String'));
            enteredStr = get(handles.vector3Text,'String');
            numberName = 'DV Vector Z Component';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector3, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1LB = str2double(get(handles.optVar1LwrText,'String'));
            enteredStr = get(handles.optVar1LwrText,'String');
            numberName = 'DV Vector X Component Opt Lower Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector1LB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector2LB = str2double(get(handles.optVar2LwrText,'String'));
            enteredStr = get(handles.optVar2LwrText,'String');
            numberName = 'DV Vector Y Component Opt Lower Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector2LB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector3LB = str2double(get(handles.optVar3LwrText,'String'));
            enteredStr = get(handles.optVar3LwrText,'String');
            numberName = 'DV Vector Z Component Opt Lower Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector3LB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1UB = str2double(get(handles.optVar1UprText,'String'));
            enteredStr = get(handles.optVar1UprText,'String');
            numberName = 'DV Vector X Component Opt Upper Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector1UB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector2UB = str2double(get(handles.optVar2UprText,'String'));
            enteredStr = get(handles.optVar2UprText,'String');
            numberName = 'DV Vector Y Component Opt Upper Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector2UB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector3UB = str2double(get(handles.optVar3UprText,'String'));
            enteredStr = get(handles.optVar3UprText,'String');
            numberName = 'DV Vector Z Component Opt Upper Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector3UB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            if(isempty(errMsg))
                if(get(handles.optVar1ChkBox,'value')==1 && strcmpi(get(handles.optVar1ChkBox,'Enable'),'On'))
                    errSize = length(errMsg);
                    
                    vector1UB = str2double(get(handles.optVar1UprText,'String'));
                    enteredStr = get(handles.optVar1UprText,'String');
                    numberName = 'DV Vector X Component Opt Upper Bound';
                    lb = vector1LB;
                    ub = Inf;
                    isInt = false;
                    errMsg = validateNumber(vector1UB, numberName, lb, ub, isInt, errMsg, enteredStr);

                    if(length(errMsg) <= errSize)
                        vector1 = str2double(get(handles.vector1Text,'String'));
                        enteredStr = get(handles.vector1Text,'String');
                        numberName = 'DV Vector X Component';
                        lb = vector1LB;
                        ub = vector1UB;
                        isInt = false;
                        errMsg = validateNumber(vector1, numberName, lb, ub, isInt, errMsg, enteredStr);
                    end
                end
                
                if(get(handles.optVar2ChkBox,'value')==1 && strcmpi(get(handles.optVar2ChkBox,'Enable'),'On'))
                    errSize = length(errMsg);
                    
                    vector2UB = str2double(get(handles.optVar2UprText,'String'));
                    enteredStr = get(handles.optVar2UprText,'String');
                    numberName = 'DV Vector Y Component Opt Upper Bound';
                    lb = vector2LB;
                    ub = Inf;
                    isInt = false;
                    errMsg = validateNumber(vector2UB, numberName, lb, ub, isInt, errMsg, enteredStr);
                    
                    if(length(errMsg) <= errSize)
                        vector2 = str2double(get(handles.vector2Text,'String'));
                        enteredStr = get(handles.vector2Text,'String');
                        numberName = 'DV Vector Y Component';
                        lb = vector2LB;
                        ub = vector2UB;
                        isInt = false;
                        errMsg = validateNumber(vector2, numberName, lb, ub, isInt, errMsg, enteredStr);
                    end
                end
                
                if(get(handles.optVar3ChkBox,'value')==1 && strcmpi(get(handles.optVar3ChkBox,'Enable'),'On'))
                    errSize = length(errMsg);
                    
                    vector3UB = str2double(get(handles.optVar3UprText,'String'));
                    enteredStr = get(handles.optVar3UprText,'String');
                    numberName = 'DV Vector Z Component Opt Upper Bound';
                    lb = vector3LB;
                    ub = Inf;
                    isInt = false;
                    errMsg = validateNumber(vector3UB, numberName, lb, ub, isInt, errMsg, enteredStr);

                    if(length(errMsg) <= errSize)
                        vector3 = str2double(get(handles.vector3Text,'String'));
                        enteredStr = get(handles.vector3Text,'String');
                        numberName = 'DV Vector Z Component';
                        lb = vector3LB;
                        ub = vector3UB;
                        isInt = false;
                        errMsg = validateNumber(vector3, numberName, lb, ub, isInt, errMsg, enteredStr);
                    end
                end
            end
            
        case 'Proscribed Delta-V (Orbital Vector)';
            vector1 = str2double(get(handles.vector1Text,'String'));
            enteredStr = get(handles.vector1Text,'String');
            numberName = 'DV Vector Prograde Component';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector1, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector2 = str2double(get(handles.vector2Text,'String'));
            enteredStr = get(handles.vector2Text,'String');
            numberName = 'DV Vector Normal Component';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector2, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector3 = str2double(get(handles.vector3Text,'String'));
            enteredStr = get(handles.vector3Text,'String');
            numberName = 'DV Vector Radial Component';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector3, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1LB = str2double(get(handles.optVar1LwrText,'String'));
            enteredStr = get(handles.optVar1LwrText,'String');
            numberName = 'DV Vector Prograde Component Opt Lower Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector1LB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector2LB = str2double(get(handles.optVar2LwrText,'String'));
            enteredStr = get(handles.optVar2LwrText,'String');
            numberName = 'DV Vector Normal Component Opt Lower Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector2LB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector3LB = str2double(get(handles.optVar3LwrText,'String'));
            enteredStr = get(handles.optVar3LwrText,'String');
            numberName = 'DV Vector Radial Component Opt Lower Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector3LB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1UB = str2double(get(handles.optVar1UprText,'String'));
            enteredStr = get(handles.optVar1UprText,'String');
            numberName = 'DV Vector Prograde Component Opt Upper Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector1UB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector2UB = str2double(get(handles.optVar2UprText,'String'));
            enteredStr = get(handles.optVar2UprText,'String');
            numberName = 'DV Vector Normal Component Opt Upper Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector2UB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector3UB = str2double(get(handles.optVar3UprText,'String'));
            enteredStr = get(handles.optVar3UprText,'String');
            numberName = 'DV Vector Radial Component Opt Upper Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector3UB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            if(isempty(errMsg))
                if(get(handles.optVar1ChkBox,'value')==1 && strcmpi(get(handles.optVar1ChkBox,'Enable'),'On'))
                    errSize = length(errMsg);
                    
                    vector1UB = str2double(get(handles.optVar1UprText,'String'));
                    enteredStr = get(handles.optVar1UprText,'String');
                    numberName = 'DV Vector Prograde Component Opt Upper Bound';
                    lb = vector1LB;
                    ub = Inf;
                    isInt = false;
                    errMsg = validateNumber(vector1UB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
                    if(length(errMsg) <= errSize)
                        vector1 = str2double(get(handles.vector1Text,'String'));
                        enteredStr = get(handles.vector1Text,'String');
                        numberName = 'DV Vector Prograde Component';
                        lb = vector1LB;
                        ub = vector1UB;
                        isInt = false;
                        errMsg = validateNumber(vector1, numberName, lb, ub, isInt, errMsg, enteredStr);
                    end
                end
                
                if(get(handles.optVar2ChkBox,'value')==1 && strcmpi(get(handles.optVar2ChkBox,'Enable'),'On'))
                    errSize = length(errMsg);
                    
                    vector2UB = str2double(get(handles.optVar2UprText,'String'));
                    enteredStr = get(handles.optVar2UprText,'String');
                    numberName = 'DV Vector Normal Component Opt Upper Bound';
                    lb = vector2LB;
                    ub = Inf;
                    isInt = false;
                    errMsg = validateNumber(vector2UB, numberName, lb, ub, isInt, errMsg, enteredStr);

                    if(length(errMsg) <= errSize)
                        vector2 = str2double(get(handles.vector2Text,'String'));
                        enteredStr = get(handles.vector2Text,'String');
                        numberName = 'DV Vector Normal Component';
                        lb = vector2LB;
                        ub = vector2UB;
                        isInt = false;
                        errMsg = validateNumber(vector2, numberName, lb, ub, isInt, errMsg, enteredStr);
                    end
                end
                
                if(get(handles.optVar3ChkBox,'value')==1 && strcmpi(get(handles.optVar3ChkBox,'Enable'),'On'))
                    errSize = length(errMsg);
                    
                    vector3UB = str2double(get(handles.optVar3UprText,'String'));
                    enteredStr = get(handles.optVar3UprText,'String');
                    numberName = 'DV Vector Radial Component Opt Upper Bound';
                    lb = vector3LB;
                    ub = Inf;
                    isInt = false;
                    errMsg = validateNumber(vector3UB, numberName, lb, ub, isInt, errMsg, enteredStr);

                    if(length(errMsg) <= errSize)
                        vector3 = str2double(get(handles.vector3Text,'String'));
                        enteredStr = get(handles.vector3Text,'String');
                        numberName = 'DV Vector Radial Component';
                        lb = vector3LB;
                        ub = vector3UB;
                        isInt = false;
                        errMsg = validateNumber(vector3, numberName, lb, ub, isInt, errMsg, enteredStr);
                    end
                end
            end
            
        case 'Finite Duration (Inertial Vector)'
            vector1 = str2double(get(handles.vector1Text,'String'));
            enteredStr = get(handles.vector1Text,'String');
            numberName = 'DV Vector X Component';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector1, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector2 = str2double(get(handles.vector2Text,'String'));
            enteredStr = get(handles.vector2Text,'String');
            numberName = 'DV Vector Y Component';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector2, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector3 = str2double(get(handles.vector3Text,'String'));
            enteredStr = get(handles.vector3Text,'String');
            numberName = 'DV Vector Z Component';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector3, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1LB = str2double(get(handles.optVar1LwrText,'String'));
            enteredStr = get(handles.optVar1LwrText,'String');
            numberName = 'DV Vector X Component Opt Lower Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector1LB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector2LB = str2double(get(handles.optVar2LwrText,'String'));
            enteredStr = get(handles.optVar2LwrText,'String');
            numberName = 'DV Vector Y Component Opt Lower Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector2LB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector3LB = str2double(get(handles.optVar3LwrText,'String'));
            enteredStr = get(handles.optVar3LwrText,'String');
            numberName = 'DV Vector Z Component Opt Lower Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector3LB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1UB = str2double(get(handles.optVar1UprText,'String'));
            enteredStr = get(handles.optVar1UprText,'String');
            numberName = 'DV Vector X Component Opt Upper Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector1UB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector2UB = str2double(get(handles.optVar2UprText,'String'));
            enteredStr = get(handles.optVar2UprText,'String');
            numberName = 'DV Vector Y Component Opt Upper Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector2UB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector3UB = str2double(get(handles.optVar3UprText,'String'));
            enteredStr = get(handles.optVar3UprText,'String');
            numberName = 'DV Vector Z Component Opt Upper Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector3UB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            if(isempty(errMsg))
                if(get(handles.optVar1ChkBox,'value')==1 && strcmpi(get(handles.optVar1ChkBox,'Enable'),'On'))
                    errSize = length(errMsg);
                    
                    vector1UB = str2double(get(handles.optVar1UprText,'String'));
                    enteredStr = get(handles.optVar1UprText,'String');
                    numberName = 'DV Vector X Component Opt Upper Bound';
                    lb = vector1LB;
                    ub = Inf;
                    isInt = false;
                    errMsg = validateNumber(vector1UB, numberName, lb, ub, isInt, errMsg, enteredStr);

                    if(length(errMsg) <= errSize)
                        vector1 = str2double(get(handles.vector1Text,'String'));
                        enteredStr = get(handles.vector1Text,'String');
                        numberName = 'DV Vector X Component';
                        lb = vector1LB;
                        ub = vector1UB;
                        isInt = false;
                        errMsg = validateNumber(vector1, numberName, lb, ub, isInt, errMsg, enteredStr);
                    end
                end
                
                if(get(handles.optVar2ChkBox,'value')==1 && strcmpi(get(handles.optVar2ChkBox,'Enable'),'On'))
                    errSize = length(errMsg);
                    
                    vector2UB = str2double(get(handles.optVar2UprText,'String'));
                    enteredStr = get(handles.optVar2UprText,'String');
                    numberName = 'DV Vector Y Component Opt Upper Bound';
                    lb = vector2LB;
                    ub = Inf;
                    isInt = false;
                    errMsg = validateNumber(vector2UB, numberName, lb, ub, isInt, errMsg, enteredStr);
                    
                    if(length(errMsg) <= errSize)
                        vector2 = str2double(get(handles.vector2Text,'String'));
                        enteredStr = get(handles.vector2Text,'String');
                        numberName = 'DV Vector Y Component';
                        lb = vector2LB;
                        ub = vector2UB;
                        isInt = false;
                        errMsg = validateNumber(vector2, numberName, lb, ub, isInt, errMsg, enteredStr);
                    end
                end
                
                if(get(handles.optVar3ChkBox,'value')==1 && strcmpi(get(handles.optVar3ChkBox,'Enable'),'On'))
                    errSize = length(errMsg);
                    
                    vector3UB = str2double(get(handles.optVar3UprText,'String'));
                    enteredStr = get(handles.optVar3UprText,'String');
                    numberName = 'DV Vector Z Component Opt Upper Bound';
                    lb = vector3LB;
                    ub = Inf;
                    isInt = false;
                    errMsg = validateNumber(vector3UB, numberName, lb, ub, isInt, errMsg, enteredStr);

                    if(length(errMsg) <= errSize)
                        vector3 = str2double(get(handles.vector3Text,'String'));
                        enteredStr = get(handles.vector3Text,'String');
                        numberName = 'DV Vector Z Component';
                        lb = vector3LB;
                        ub = vector3UB;
                        isInt = false;
                        errMsg = validateNumber(vector3, numberName, lb, ub, isInt, errMsg, enteredStr);
                    end
                end
            end
            
        case 'Finite Duration (Orbital Vector)'
            vector1 = str2double(get(handles.vector1Text,'String'));
            enteredStr = get(handles.vector1Text,'String');
            numberName = 'DV Vector Prograde Component';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector1, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector2 = str2double(get(handles.vector2Text,'String'));
            enteredStr = get(handles.vector2Text,'String');
            numberName = 'DV Vector Normal Component';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector2, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector3 = str2double(get(handles.vector3Text,'String'));
            enteredStr = get(handles.vector3Text,'String');
            numberName = 'DV Vector Radial Component';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector3, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1LB = str2double(get(handles.optVar1LwrText,'String'));
            enteredStr = get(handles.optVar1LwrText,'String');
            numberName = 'DV Vector Prograde Component Opt Lower Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector1LB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector2LB = str2double(get(handles.optVar2LwrText,'String'));
            enteredStr = get(handles.optVar2LwrText,'String');
            numberName = 'DV Vector Normal Component Opt Lower Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector2LB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector3LB = str2double(get(handles.optVar3LwrText,'String'));
            enteredStr = get(handles.optVar3LwrText,'String');
            numberName = 'DV Vector Radial Component Opt Lower Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector3LB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1UB = str2double(get(handles.optVar1UprText,'String'));
            enteredStr = get(handles.optVar1UprText,'String');
            numberName = 'DV Vector Prograde Component Opt Upper Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector1UB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector2UB = str2double(get(handles.optVar2UprText,'String'));
            enteredStr = get(handles.optVar2UprText,'String');
            numberName = 'DV Vector Normal Component Opt Upper Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector2UB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector3UB = str2double(get(handles.optVar3UprText,'String'));
            enteredStr = get(handles.optVar3UprText,'String');
            numberName = 'DV Vector Radial Component Opt Upper Bound';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector3UB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            if(isempty(errMsg))
                if(get(handles.optVar1ChkBox,'value')==1 && strcmpi(get(handles.optVar1ChkBox,'Enable'),'On'))
                    errSize = length(errMsg);
                    
                    vector1UB = str2double(get(handles.optVar1UprText,'String'));
                    enteredStr = get(handles.optVar1UprText,'String');
                    numberName = 'DV Vector Prograde Component Opt Upper Bound';
                    lb = vector1LB;
                    ub = Inf;
                    isInt = false;
                    errMsg = validateNumber(vector1UB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
                    if(length(errMsg) <= errSize)
                        vector1 = str2double(get(handles.vector1Text,'String'));
                        enteredStr = get(handles.vector1Text,'String');
                        numberName = 'DV Vector Prograde Component';
                        lb = vector1LB;
                        ub = vector1UB;
                        isInt = false;
                        errMsg = validateNumber(vector1, numberName, lb, ub, isInt, errMsg, enteredStr);
                    end
                end
                
                if(get(handles.optVar2ChkBox,'value')==1 && strcmpi(get(handles.optVar2ChkBox,'Enable'),'On'))
                    errSize = length(errMsg);
                    
                    vector2UB = str2double(get(handles.optVar2UprText,'String'));
                    enteredStr = get(handles.optVar2UprText,'String');
                    numberName = 'DV Vector Normal Component Opt Upper Bound';
                    lb = vector2LB;
                    ub = Inf;
                    isInt = false;
                    errMsg = validateNumber(vector2UB, numberName, lb, ub, isInt, errMsg, enteredStr);

                    if(length(errMsg) <= errSize)
                        vector2 = str2double(get(handles.vector2Text,'String'));
                        enteredStr = get(handles.vector2Text,'String');
                        numberName = 'DV Vector Normal Component';
                        lb = vector2LB;
                        ub = vector2UB;
                        isInt = false;
                        errMsg = validateNumber(vector2, numberName, lb, ub, isInt, errMsg, enteredStr);
                    end
                end
                
                if(get(handles.optVar3ChkBox,'value')==1 && strcmpi(get(handles.optVar3ChkBox,'Enable'),'On'))
                    errSize = length(errMsg);
                    
                    vector3UB = str2double(get(handles.optVar3UprText,'String'));
                    enteredStr = get(handles.optVar3UprText,'String');
                    numberName = 'DV Vector Radial Component Opt Upper Bound';
                    lb = vector3LB;
                    ub = Inf;
                    isInt = false;
                    errMsg = validateNumber(vector3UB, numberName, lb, ub, isInt, errMsg, enteredStr);

                    if(length(errMsg) <= errSize)
                        vector3 = str2double(get(handles.vector3Text,'String'));
                        enteredStr = get(handles.vector3Text,'String');
                        numberName = 'DV Vector Radial Component';
                        lb = vector3LB;
                        ub = vector3UB;
                        isInt = false;
                        errMsg = validateNumber(vector3, numberName, lb, ub, isInt, errMsg, enteredStr);
                    end
                end
            end
            
        case {'Proscribed Delta-V (Inertial Spherical)','Finite Duration (Inertial Spherical)'}
            vector1 = str2double(get(handles.vector1Text,'String'));
            enteredStr = get(handles.vector1Text,'String');
            numberName = 'DV Vector Inertial Azimuth Angle';
            lb = -360;
            ub = 540;
            isInt = false;
            errMsg = validateNumber(vector1, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector2 = str2double(get(handles.vector2Text,'String'));
            enteredStr = get(handles.vector2Text,'String');
            numberName = 'DV Vector Inertial Elevation Angle';
            lb = -90;
            ub = 90;
            isInt = false;
            errMsg = validateNumber(vector2, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector3 = str2double(get(handles.vector3Text,'String'));
            enteredStr = get(handles.vector3Text,'String');
            numberName = 'DV Vector Magnitude';
            lb = 0;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector3, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1LB = str2double(get(handles.optVar1LwrText,'String'));
            enteredStr = get(handles.optVar1LwrText,'String');
            numberName = 'DV Vector Inertial Azimuth Angle Opt Lower Bound';
            lb = -360;
            ub = 540;
            isInt = false;
            errMsg = validateNumber(vector1LB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector2LB = str2double(get(handles.optVar2LwrText,'String'));
            enteredStr = get(handles.optVar2LwrText,'String');
            numberName = 'DV Vector Inertial Elevation Angle Opt Lower Bound';
            lb = -90;
            ub = 90;
            isInt = false;
            errMsg = validateNumber(vector2LB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector3LB = str2double(get(handles.optVar3LwrText,'String'));
            enteredStr = get(handles.optVar3LwrText,'String');
            numberName = 'DV Vector Magnitude Opt Lower Bound';
            lb = 0;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector3LB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1UB = str2double(get(handles.optVar1UprText,'String'));
            enteredStr = get(handles.optVar1UprText,'String');
            numberName = 'DV Vector Inertial Azimuth Angle Opt Upper Bound';
            lb = -360;
            ub = 540;
            isInt = false;
            errMsg = validateNumber(vector1UB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector2UB = str2double(get(handles.optVar2UprText,'String'));
            enteredStr = get(handles.optVar2UprText,'String');
            numberName = 'DV Vector Inertial Elevation Angle Opt Upper Bound';
            lb = -90;
            ub = 90;
            isInt = false;
            errMsg = validateNumber(vector2UB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector3UB = str2double(get(handles.optVar3UprText,'String'));
            enteredStr = get(handles.optVar3UprText,'String');
            numberName = 'DV Vector Magnitude Opt Upper Bound';
            lb = 0;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector3UB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            if(isempty(errMsg))
                if(get(handles.optVar1ChkBox,'value')==1 && strcmpi(get(handles.optVar1ChkBox,'Enable'),'On'))
                    errSize = length(errMsg);
                    
                    vector1UB = str2double(get(handles.optVar1UprText,'String'));
                    enteredStr = get(handles.optVar1UprText,'String');
                    numberName = 'DV Vector Inertial Azimuth Angle Opt Upper Bound';
                    lb = vector1LB;
                    ub = 540;
                    isInt = false;
                    errMsg = validateNumber(vector1UB, numberName, lb, ub, isInt, errMsg, enteredStr);

                    if(length(errMsg) <= errSize)
                        vector1 = str2double(get(handles.vector1Text,'String'));
                        enteredStr = get(handles.vector1Text,'String');
                        numberName = 'DV Vector Inertial Azimuth Angle';
                        lb = vector1LB;
                        ub = vector1UB;
                        isInt = false;
                        errMsg = validateNumber(vector1, numberName, lb, ub, isInt, errMsg, enteredStr);
                    end
                end
                
                if(get(handles.optVar2ChkBox,'value')==1 && strcmpi(get(handles.optVar2ChkBox,'Enable'),'On'))
                    errSize = length(errMsg);
                    
                    vector2UB = str2double(get(handles.optVar2UprText,'String'));
                    enteredStr = get(handles.optVar2UprText,'String');
                    numberName = 'DV Vector Inertial Elevation Angle Opt Upper Bound';
                    lb = vector2LB;
                    ub = 90;
                    isInt = false;
                    errMsg = validateNumber(vector2UB, numberName, lb, ub, isInt, errMsg, enteredStr);
                    
                    if(length(errMsg) <= errSize)
                        vector2 = str2double(get(handles.vector2Text,'String'));
                        enteredStr = get(handles.vector2Text,'String');
                        numberName = 'DV Vector Inertial Elevation Angle';
                        lb = vector2LB;
                        ub = vector2UB;
                        isInt = false;
                        errMsg = validateNumber(vector2, numberName, lb, ub, isInt, errMsg, enteredStr);
                    end
                end
                
                if(get(handles.optVar3ChkBox,'value')==1 && strcmpi(get(handles.optVar3ChkBox,'Enable'),'On'))
                    errSize = length(errMsg);
                    
                    vector3UB = str2double(get(handles.optVar3UprText,'String'));
                    enteredStr = get(handles.optVar3UprText,'String');
                    numberName = 'DV Vector Magnitude Opt Upper Bound';
                    lb = vector3LB;
                    ub = Inf;
                    isInt = false;
                    errMsg = validateNumber(vector3UB, numberName, lb, ub, isInt, errMsg, enteredStr);

                    if(length(errMsg) <= errSize)
                        vector3 = str2double(get(handles.vector3Text,'String'));
                        enteredStr = get(handles.vector3Text,'String');
                        numberName = 'DV Vector Magnitude';
                        lb = vector3LB;
                        ub = vector3UB;
                        isInt = false;
                        errMsg = validateNumber(vector3, numberName, lb, ub, isInt, errMsg, enteredStr);
                    end
                end
            end
            
        case {'Proscribed Delta-V (Orbital Spherical)','Finite Duration (Orbital Spherical)'}
            vector1 = str2double(get(handles.vector1Text,'String'));
            enteredStr = get(handles.vector1Text,'String');
            numberName = 'DV Vector Orbital Azimuth Angle';
            lb = -360;
            ub = 540;
            isInt = false;
            errMsg = validateNumber(vector1, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector2 = str2double(get(handles.vector2Text,'String'));
            enteredStr = get(handles.vector2Text,'String');
            numberName = 'DV Vector Orbital Elevation Angle';
            lb = -90;
            ub = 90;
            isInt = false;
            errMsg = validateNumber(vector2, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector3 = str2double(get(handles.vector3Text,'String'));
            enteredStr = get(handles.vector3Text,'String');
            numberName = 'DV Vector Magnitude';
            lb = 0;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector3, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1LB = str2double(get(handles.optVar1LwrText,'String'));
            enteredStr = get(handles.optVar1LwrText,'String');
            numberName = 'DV Vector Orbital Azimuth Angle Opt Lower Bound';
            lb = -360;
            ub = 540;
            isInt = false;
            errMsg = validateNumber(vector1LB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector2LB = str2double(get(handles.optVar2LwrText,'String'));
            enteredStr = get(handles.optVar2LwrText,'String');
            numberName = 'DV Vector Orbital Elevation Angle Opt Lower Bound';
            lb = -90;
            ub = 90;
            isInt = false;
            errMsg = validateNumber(vector2LB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector3LB = str2double(get(handles.optVar3LwrText,'String'));
            enteredStr = get(handles.optVar3LwrText,'String');
            numberName = 'DV Vector Magnitude Opt Lower Bound';
            lb = 0;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector3LB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector1UB = str2double(get(handles.optVar1UprText,'String'));
            enteredStr = get(handles.optVar1UprText,'String');
            numberName = 'DV Vector Orbital Azimuth Angle Opt Upper Bound';
            lb = -360;
            ub = 540;
            isInt = false;
            errMsg = validateNumber(vector1UB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector2UB = str2double(get(handles.optVar2UprText,'String'));
            enteredStr = get(handles.optVar2UprText,'String');
            numberName = 'DV Vector Orbital Elevation Angle Opt Upper Bound';
            lb = -90;
            ub = 90;
            isInt = false;
            errMsg = validateNumber(vector2UB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            vector3UB = str2double(get(handles.optVar3UprText,'String'));
            enteredStr = get(handles.optVar3UprText,'String');
            numberName = 'DV Vector Magnitude Opt Upper Bound';
            lb = 0;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(vector3UB, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            if(isempty(errMsg))
                if(get(handles.optVar1ChkBox,'value')==1 && strcmpi(get(handles.optVar1ChkBox,'Enable'),'On'))
                    errSize = length(errMsg);
                    
                    vector1UB = str2double(get(handles.optVar1UprText,'String'));
                    enteredStr = get(handles.optVar1UprText,'String');
                    numberName = 'DV Vector Orbital Azimuth Angle Opt Upper Bound';
                    lb = vector1LB;
                    ub = 540;
                    isInt = false;
                    errMsg = validateNumber(vector1UB, numberName, lb, ub, isInt, errMsg, enteredStr);

                    if(length(errMsg) <= errSize)
                        vector1 = str2double(get(handles.vector1Text,'String'));
                        enteredStr = get(handles.vector1Text,'String');
                        numberName = 'DV Vector Orbital Azimuth Angle';
                        lb = vector1LB;
                        ub = vector1UB;
                        isInt = false;
                        errMsg = validateNumber(vector1, numberName, lb, ub, isInt, errMsg, enteredStr);
                    end
                end
                
                if(get(handles.optVar2ChkBox,'value')==1 && strcmpi(get(handles.optVar2ChkBox,'Enable'),'On'))
                    errSize = length(errMsg);
                    
                    vector2UB = str2double(get(handles.optVar2UprText,'String'));
                    enteredStr = get(handles.optVar2UprText,'String');
                    numberName = 'DV Vector Orbital Elevation Angle Opt Upper Bound';
                    lb = vector2LB;
                    ub = 90;
                    isInt = false;
                    errMsg = validateNumber(vector2UB, numberName, lb, ub, isInt, errMsg, enteredStr);
                    
                    if(length(errMsg) <= errSize)
                        vector2 = str2double(get(handles.vector2Text,'String'));
                        enteredStr = get(handles.vector2Text,'String');
                        numberName = 'DV Vector Orbital Elevation Angle';
                        lb = vector2LB;
                        ub = vector2UB;
                        isInt = false;
                        errMsg = validateNumber(vector2, numberName, lb, ub, isInt, errMsg, enteredStr);
                    end
                end
                
                if(get(handles.optVar3ChkBox,'value')==1 && strcmpi(get(handles.optVar3ChkBox,'Enable'),'On'))
                    errSize = length(errMsg);
                    
                    vector3UB = str2double(get(handles.optVar3UprText,'String'));
                    enteredStr = get(handles.optVar3UprText,'String');
                    numberName = 'DV Vector Magnitude Opt Upper Bound';
                    lb = vector3LB;
                    ub = Inf;
                    isInt = false;
                    errMsg = validateNumber(vector3UB, numberName, lb, ub, isInt, errMsg, enteredStr);

                    if(length(errMsg) <= errSize)
                        vector3 = str2double(get(handles.vector3Text,'String'));
                        enteredStr = get(handles.vector3Text,'String');
                        numberName = 'DV Vector Magnitude';
                        lb = vector3LB;
                        ub = vector3UB;
                        isInt = false;
                        errMsg = validateNumber(vector3, numberName, lb, ub, isInt, errMsg, enteredStr);
                    end
                end
            end
            
        case 'Circularize';
            %none
    end
    
% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.ma_InsertDVManeuverGUI);


function vector2Text_Callback(hObject, eventdata, handles)
% hObject    handle to vector2Text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of vector2Text as text
%        str2double(get(hObject,'String')) returns contents of vector2Text as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

recomputeBurnDurStr(handles);

% --- Executes during object creation, after setting all properties.
function vector2Text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vector2Text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function vector3Text_Callback(hObject, eventdata, handles)
% hObject    handle to vector3Text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of vector3Text as text
%        str2double(get(hObject,'String')) returns contents of vector3Text as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

recomputeBurnDurStr(handles);

% --- Executes during object creation, after setting all properties.
function vector3Text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vector3Text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function vector1Text_Callback(hObject, eventdata, handles)
% hObject    handle to vector1Text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of vector1Text as text
%        str2double(get(hObject,'String')) returns contents of vector1Text as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    recomputeBurnDurStr(handles);

% --- Executes during object creation, after setting all properties.
function vector1Text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vector1Text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in thrustersCombo.
function thrustersCombo_Callback(hObject, eventdata, handles)
% hObject    handle to thrustersCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns thrustersCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from thrustersCombo
    recomputeBurnDurStr(handles);

% --- Executes during object creation, after setting all properties.
function thrustersCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to thrustersCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in optVar1ChkBox.
function optVar1ChkBox_Callback(hObject, eventdata, handles)
% hObject    handle to optVar1ChkBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of optVar1ChkBox
if(get(hObject,'Value'))
    set(handles.optVar1LwrText,'Enable','on');
    set(handles.optVar1UprText,'Enable','on');
else
    set(handles.optVar1LwrText,'Enable','off');
    set(handles.optVar1UprText,'Enable','off');
end


function optVar1LwrText_Callback(hObject, eventdata, handles)
% hObject    handle to optVar1LwrText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of optVar1LwrText as text
%        str2double(get(hObject,'String')) returns contents of optVar1LwrText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function optVar1LwrText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to optVar1LwrText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function optVar1UprText_Callback(hObject, eventdata, handles)
% hObject    handle to optVar1UprText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of optVar1UprText as text
%        str2double(get(hObject,'String')) returns contents of optVar1UprText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function optVar1UprText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to optVar1UprText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in optVar2ChkBox.
function optVar2ChkBox_Callback(hObject, eventdata, handles)
% hObject    handle to optVar2ChkBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of optVar2ChkBox
if(get(hObject,'Value'))
    set(handles.optVar2LwrText,'Enable','on');
    set(handles.optVar2UprText,'Enable','on');
else
    set(handles.optVar2LwrText,'Enable','off');
    set(handles.optVar2UprText,'Enable','off');
end


function optVar2LwrText_Callback(hObject, eventdata, handles)
% hObject    handle to optVar2LwrText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of optVar2LwrText as text
%        str2double(get(hObject,'String')) returns contents of optVar2LwrText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function optVar2LwrText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to optVar2LwrText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function optVar2UprText_Callback(hObject, eventdata, handles)
% hObject    handle to optVar2UprText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of optVar2UprText as text
%        str2double(get(hObject,'String')) returns contents of optVar2UprText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function optVar2UprText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to optVar2UprText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in optVar3ChkBox.
function optVar3ChkBox_Callback(hObject, eventdata, handles)
% hObject    handle to optVar3ChkBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of optVar3ChkBox
if(get(hObject,'Value'))
    set(handles.optVar3LwrText,'Enable','on');
    set(handles.optVar3UprText,'Enable','on');
else
    set(handles.optVar3LwrText,'Enable','off');
    set(handles.optVar3UprText,'Enable','off');
end


function optVar3LwrText_Callback(hObject, eventdata, handles)
% hObject    handle to optVar3LwrText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of optVar3LwrText as text
%        str2double(get(hObject,'String')) returns contents of optVar3LwrText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function optVar3LwrText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to optVar3LwrText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function optVar3UprText_Callback(hObject, eventdata, handles)
% hObject    handle to optVar3UprText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of optVar3UprText as text
%        str2double(get(hObject,'String')) returns contents of optVar3UprText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function optVar3UprText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to optVar3UprText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on ma_InsertDVManeuverGUI or any of its controls.
function ma_InsertDVManeuverGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to ma_InsertDVManeuverGUI (see GCBO)
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
            close(handles.ma_InsertDVManeuverGUI);
    end
  
function recomputeBurnDurStr(handles)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    stateLog = maData.stateLog;
    script = maData.script;
    event = get(handles.ma_InsertDVManeuverGUI,'UserData');

    if(~isempty(event) && isstruct(event))
        for(i=1:length(script)) 
            if(script{i}.id == event.id)
                eventNum = i;
                break;
            else
                eventNum = [];
            end
        end

        preEventLog = stateLog(stateLog(:,13)==eventNum-1,:);
        eventLog = stateLog(stateLog(:,13)==eventNum,:);
        
        stateRowPreEvent = preEventLog(end,:);
        stateRowEvent = eventLog(1,:);
    elseif(~isempty(event) && isnumeric(event))
        eventNum = event+1;
        preEventLog = stateLog(stateLog(:,13)==eventNum-1,:);
        eventLog = stateLog(stateLog(:,13)==eventNum,:);
        
        stateRowPreEvent = preEventLog(end,:);
        stateRowEvent = stateRowPreEvent;
    else
        eventNum = [];
        stateRowPreEvent = [];
        stateRowEvent = [];
    end

    thrusters = maData.spacecraft.thrusters;
    thrusterNum = get(handles.thrustersCombo,'value');
    thruster = thrusters{thrusterNum};

    vector1 = str2double(get(handles.vector1Text,'String'));
    vector2 = str2double(get(handles.vector2Text,'String'));
    vector3 = str2double(get(handles.vector3Text,'String'));
    vector = [vector1; vector2; vector3]/1000; %store in km/s

    isp = thruster.isp;
    thrust = thruster.thrust;
    mass0 = sum(stateRowPreEvent(9:12));
    dvMag = norm(vector);
    massFlowRate = getMdotFromThrustIsp(thrust, isp);
    burnDur = getBurnDuration(mass0, massFlowRate, isp, dvMag);
    
    burnDurStr = sprintf('Est. Burn Duration: %0.3f s', burnDur);
    set(handles.estBurnLabel,'String',burnDurStr);


% --- Executes on selection change in manueverLineColorCombo.
function manueverLineColorCombo_Callback(hObject, eventdata, handles)
% hObject    handle to manueverLineColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns manueverLineColorCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from manueverLineColorCombo


% --- Executes during object creation, after setting all properties.
function manueverLineColorCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to manueverLineColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in mnvrLineStyleCombo.
function mnvrLineStyleCombo_Callback(hObject, eventdata, handles)
% hObject    handle to mnvrLineStyleCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns mnvrLineStyleCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from mnvrLineStyleCombo


% --- Executes during object creation, after setting all properties.
function mnvrLineStyleCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mnvrLineStyleCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in lineWidthCombo.
function lineWidthCombo_Callback(hObject, eventdata, handles)
% hObject    handle to lineWidthCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lineWidthCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lineWidthCombo


% --- Executes during object creation, after setting all properties.
function lineWidthCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lineWidthCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
