function Out = LimitFigSize(FigH, Prop, Ext)
    % LimitFigSize - Set and get minimum or maximum figure size
    % Out = LimitFigSize(FigH, Prop, Ext)
    % INPUT:
    %   FigH: Handle of a Matlab figure.
    %         Optional, default: current figure.
    %   Prop: String, command:
    %         'min': Set minimum extent.
    %         'max': Set maximum extent.
    %         'get': Reply a struct with fields MinSize and MaxSize. If not limited,
    %                the empty matrix [] is replied.
    %         'clear': Clear the min and max limits.
    %         Optional, default: 'min'
    %   Ext:  [width, height] vector to determing the extent of the inner position
    %         in pixels. Optional, default: Current extent.
    %
    % OUTPUT:
    %   Out:  Output for the 'get' command.
    %
    % EXAMPLES:
    %   FigH = figure;
    %   LimitFigSize(FigH, 'min', [200, 200])
    %   LimitFigSize('max', [400, 400])        % Current figure as default
    %   LimitFigSize('min')                    % Current figure, current extent
    %   Limit = LimitFigSize(FigH, 'get')
    %
    % NOTE: This function is based on undocumented functions, such that it might
    % fail in future versions.
    %
    % Tested: Matlab 7.7, 7.8, 7.13, 8.6, WinXP/32, Win7/64
    %         Not compatible to Matlab 6.5.
    % Author: Jan Simon, Heidelberg, (C) 2012-2015 matlab.2010(a)n(MINUS)simon.de
    %
    % See also MaximizeFig, AlphaFig, ClipFig, TopFig, ToMonitorFig, WindowAPI.
    % $JRev: R-i V:008 Sum:6o/8OiL6gm/Z Date:20-Dec-2015 17:20:36 $
    % $License: BSD (use/copy/change/redistribute on own risk, mention the author) $
    % $UnitTest: uTest_LimitFigSize $
    % $File: Tools\GLGui\LimitFigSize.m $
    % History:
    % 001: 07-Oct-2012 15:02, First version.
    % 005: 02-Nov-2014 02:31, Consider HG2 client.
    %      BUGFIX: Replies empty matrix for 'get' if size has not been limited.
    % Initialize: ==================================================================
    % Global Interface: ------------------------------------------------------------
    % Consider dependencies to Matlab versions:
    MatlabVer = [100, 1] * sscanf(version, '%d.', 2);
    hasHG2    = (MatlabVer >= 804);
    hasHG1    = (MatlabVer >= 706);
    % hasHG2 = isa(FigH, 'matlab.ui.Figure');
    % hasHG2 = ~isnumeric(FigH);
    if ~usejava('jvm') || MatlabVer < 700
        % Should this be an error, a warning or a message??
        warning(['JSimon:', mfilename, ':NeedJava'], ...
            '*** %s: Require java and Matlab >= R14.', mfilename);
        return;
    end
    % Initial values: --------------------------------------------------------------
    % Program Interface: -----------------------------------------------------------
    % Parse the inputs:
    switch nargin
        case 0
            FigH = gcf;
            Prop = 'min';
            Ext  = [];
        case 1
            if numel(FigH) == 1 && ishandle(FigH)  % LimitFigSize(FigH)
                Prop = 'min';
                Ext  = [];
            elseif ischar(FigH)                    % LimitFigSize('string')
                Prop = FigH;
                Ext  = [];
                FigH = GetCurrentFigure(hasHG2);
            else                                   % LimitFigSize([W, H])
                Prop = 'min';
                Ext  = FigH;
                FigH = GetCurrentFigure(hasHG2);
            end
        case 2
            if ischar(FigH)                        % LimitFigSize('string', [W, H])
                Ext  = Prop;
                Prop = FigH;
                FigH = GetCurrentFigure(hasHG2);
            elseif numel(FigH) == 1 && ishandle(FigH)
                if ischar(Prop)                     % LimitFigSize(FigH, 'string')
                    Ext  = [];
                else                                % LimitFigSize(FigH, [W, H])
                    Ext  = Prop;
                    Prop = 'min';
                end
            else
                error(['JSimon:', mfilename, ':BadHandle'], ...
                    '*** %s: 1st input is not a figure handle or string.', mfilename);
            end
        case 3
            % Nothing to do
        otherwise
    end
    % Check if input is a figure handle:
    if numel(FigH) ~= 1 || ~ishandle(FigH) || ...     % Short-circuit
            ~strcmpi(get(FigH, 'Type'), 'figure')
        error(['JSimon:', mfilename, ':BadHandle'], ...
            '*** %s: 1st input is not a figure handle.', mfilename);
    end
    % User Interface: --------------------------------------------------------------
    % Do the work: =================================================================
    % Get the Java frame:
    if hasHG2
        % Suppress warnings:
        bakWarn = warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
        jFrame  = get(handle(FigH), 'JavaFrame');  % Fails in Matlab < 7.0
        warning(bakWarn);
    else
        jFrame = get(handle(FigH), 'JavaFrame');  % Fails in Matlab < 7.0
    end
    try
        if hasHG2      % HG2 since R2014b:
            jClient = jFrame.fHG2Client;
        elseif hasHG1  % R2008a up to 2014a:
            jClient = jFrame.fHG1Client;
        else           % R14 (7.0) to R2011a:
            jClient = jFrame.fFigureClient;
        end
    catch ME          % Getting the client is not documented and subject to changes:
        error(['JSimon:', mfilename, ':NoJClient'], ...
            'Cannot get Java Figure Client: %s', ME.message);
    end
    % The com.mathworks.hg.peer.FigureFrameProxy is empty, if no DRAWNOW allowed to
    % update the figure since its creation:
    jWindow = jClient.getWindow;
    if isempty(jWindow)
        drawnow;
        pause(0.2);
        jWindow = jClient.getWindow;
    end
    % Apply, clear or get the limits:
    if strncmpi(Prop, 'min', 3)
        Ext = GetExtent(FigH, Ext);
        jWindow.setMinimumSize(java.awt.Dimension(Ext(1), Ext(2)));
    elseif strncmpi(Prop, 'max', 3)
        Ext = GetExtent(FigH, Ext);
        jWindow.setMaximumSize(java.awt.Dimension(Ext(1), Ext(2)));
    elseif strcmpi(Prop, 'clear')
        jWindow.setMinimumSize([]);
        jWindow.setMaximumSize([]);
    elseif strcmpi(Prop, 'get')
        % Get difference to outer limits:
        bakUnits = get(FigH, 'Units');
        set(FigH, 'Units', 'pixels');
        DiffPos = get(FigH, 'OuterPosition') - get(FigH, 'Position');
        set(FigH, 'Units', bakUnits);
        jDim = jWindow.getMinimumSize;
        if isempty(jDim)  % Size has not been limited before:
            Out.MinSize = [];
        else
            Out.MinSize = [jDim.getWidth, jDim.getHeight] - DiffPos(3:4);
        end
        
        jDim = jWindow.getMaximumSize;
        if isempty(jDim)
            Out.MaxSize = [];
        else
            Out.MaxSize = [jDim.getWidth, jDim.getHeight] - DiffPos(3:4);
        end
    end
    % return;
    % ******************************************************************************
function FigH = GetCurrentFigure(hasHG2)
    % A DRAWNOW is required when the figure is created to update the Java handle.
    % See GCF.
    if hasHG2
        FigH = get(groot,'CurrentFigure');
    else
        FigH = get(0, 'CurrentFigure');
    end
    if isempty(FigH)
        FigH = figure;
        drawnow;
    end
    % return;
    % ******************************************************************************
function Ext = GetExtent(FigH, Ext)
    % Get or convert extent to outer position.
    bakUnits = get(FigH, 'Units');
    set(FigH, 'Units', 'pixels');
    OuterPos = get(FigH, 'OuterPosition');
    if isempty(Ext)
        Ext = OuterPos(3:4);
    elseif isnumeric(Ext) && numel(Ext) == 2 && all(Ext >= 0)
        InnerPos = get(FigH, 'Position');
        Ext      = [Ext(1) + OuterPos(3) - InnerPos(3), ...
            Ext(2) + OuterPos(4) - InnerPos(4)];
    else
        error(['JSimon:', mfilename, ':BadSize'], ...
            '*** %s: Extent must be a positive [1 x 2] vector.', mfilename);
    end
    set(FigH, 'Units', bakUnits);
    % return;
