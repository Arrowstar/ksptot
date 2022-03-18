function varargout = lvd_dataExplorerGUI(varargin)
    % LVD_DATAEXPLORERGUI MATLAB code for lvd_dataExplorerGUI.fig
    %      LVD_DATAEXPLORERGUI, by itself, creates a new LVD_DATAEXPLORERGUI or raises the existing
    %      singleton*.
    %
    %      H = LVD_DATAEXPLORERGUI returns the handle to a new LVD_DATAEXPLORERGUI or the handle to
    %      the existing singleton*.
    %
    %      LVD_DATAEXPLORERGUI('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in LVD_DATAEXPLORERGUI.M with the given input arguments.
    %
    %      LVD_DATAEXPLORERGUI('Property','Value',...) creates a new LVD_DATAEXPLORERGUI or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before lvd_dataExplorerGUI_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to lvd_dataExplorerGUI_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES
    
    % Edit the above text to modify the response to help lvd_dataExplorerGUI
    
    % Last Modified by GUIDE v2.5 27-Jun-2020 20:50:25
    
    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
        'gui_Singleton',  gui_Singleton, ...
        'gui_OpeningFcn', @lvd_dataExplorerGUI_OpeningFcn, ...
        'gui_OutputFcn',  @lvd_dataExplorerGUI_OutputFcn, ...
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
    
    
    % --- Executes just before lvd_dataExplorerGUI is made visible.
function lvd_dataExplorerGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_dataExplorerGUI (see VARARGIN)
    
    % Choose default command line output for lvd_dataExplorerGUI
    handles.output = hObject;
    
    centerUIFigure(hObject);
    
    explrInput = varargin{1};
    explrInputNames = varargin{2};
    
%     setappdata(hObject,'lvdData',lvdData);
    setappdata(hObject,'explrInput',explrInput);
    setappdata(hObject,'explrInputNames',explrInputNames);
    
    handles = populateGUI(explrInput, explrInputNames, handles);
    
    % Update handles structure
    guidata(hObject, handles);
    
    % UIWAIT makes lvd_dataExplorerGUI wait for user response (see UIRESUME)
    % uiwait(handles.lvd_dataExplorerGUI);
    
function handles = populateGUI(explrInput, explrInputNames, handles)
    panelPos = handles.propGridPanel.Position;
    
    model = com.jidesoft.grid.PropertyTableModel();
    grid = com.jidesoft.grid.PropertyTable(model);
    pane = com.jidesoft.grid.PropertyPane(grid);
    javacomponent(pane, [0 0 panelPos(3)-2 panelPos(4)-2], handles.propGridPanel);
    
    panelPos = handles.breadcrumbPanel.Position;
    
    jBreadCrumbBar = com.jidesoft.navigation.BreadcrumbBar();
    [hBreadCrumbBar,~] = javacomponent(jBreadCrumbBar, [1 1 panelPos(3) panelPos(4)], handles.breadcrumbPanel);
    handles.jBreadCrumbBar = jBreadCrumbBar;
    
    iconsClassName = 'com.mathworks.widgets.BusyAffordance$AffordanceSize';
    iconsSizeEnums = javaMethod('values',iconsClassName);
    SIZE_32x32 = iconsSizeEnums(2);  % (1) = 16x16,  (2) = 32x32
    jSpinnerIcon = com.mathworks.widgets.BusyAffordance(SIZE_32x32, 'testing...');  % icon, label

    jSpinnerIcon.setPaintsWhenStopped(false);  % default = false
    jSpinnerIcon.useWhiteDots(false);         % default = false (true is good for dark backgrounds)
    [hSpinnerIcon] = javacomponent(jSpinnerIcon.getComponent, [0,0,33,33], handles.busySpinnerIconPanel);
    handles.hSpinnerIcon = hSpinnerIcon;
    handles.jSpinnerIcon = jSpinnerIcon;
    
    uistack(handles.busySpinnerIconPanel,'top');
    
    jSpinnerIcon.start();
    
    if(isa(explrInput,'LvdData'))
        lvdDataNode = ScalarObjPropertyNode(explrInput, explrInputNames, AbstractObjPropertyNode.empty(1,0));
        lvdDataNode.createPropertyTableModel(grid, jBreadCrumbBar, jSpinnerIcon);
    elseif(iscell(explrInput))
        funcScopeNode = FuncScopePropertyNode(explrInput, explrInputNames);
        funcScopeNode.createPropertyTableModel(grid, jBreadCrumbBar, jSpinnerIcon);
    else
        error('Unknown input into Data Explorer');
    end
    
    jSpinnerIcon.stop();    
    
    
    % --- Outputs from this function are returned to the command line.
function varargout = lvd_dataExplorerGUI_OutputFcn(hObject, eventdata, handles)
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Get default command line output from handles structure
    varargout{1} = hObject;
    
    
    % --- Executes on button press in closeButton.
function closeButton_Callback(hObject, eventdata, handles)
    % hObject    handle to closeButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    delete(handles.lvd_dataExplorerGUI);
