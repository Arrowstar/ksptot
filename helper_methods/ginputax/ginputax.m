function [out1,out2,out3,out4] = ginputax(ax,arg1)
%GINPUT Graphical input from mouse.
%   [X,Y] = GINPUTAX(N) gets N points from the current axes and returns
%   the X- and Y-coordinates in length N vectors X and Y.  The cursor
%   can be positioned using a mouse.  Data points are entered by pressing
%   a mouse button or any key on the keyboard except carriage return,
%   which terminates the input before N points are entered.
%
%   [X,Y] = GINPUTAX gathers an unlimited number of points until the
%   return key is pressed.
%
%   [X,Y,BUTTON] = GINPUTAX(N) returns a third result, BUTTON, that
%   contains a vector of integers specifying which mouse button was
%   used (1,2,3 from left) or ASCII numbers if a key on the keyboard
%   was used.
%
%   [X,Y] = GINPUTAX(N,AX) and
%   [X,Y,BUTTON] = GINPUTAX(N,AX) works similar to the GINPUT but it
%   presents a croshair whenever the mouse is inside the specified axes AX 
%
%   [X,Y,BUTTON,AXN] = GINPUTAX(N,AX) returns a fourth result, AXN, in
%   which AXES did the user click the mouse.
%
%   Examples:
%       [x,y] = ginputax;
%
%       [x,y] = ginputax(5);
%
%       [x, y, button] = ginputax(1);
%
%---------------
%       -to be used within GUIs
%       [x,y] = ginputax(5,{handles.axes1 handles.axes2});
%
%       [x, y, button, ax] = ginputax(1,gca);
%
%
%   See also GINPUT, GTEXT, WAITFORBUTTONPRESS.

%   Copyright 1984-2011 The MathWorks, Inc.
%   $Revision: 5.32.4.18 $  $Date: 2011/05/17 02:35:09 $
%   Modified by Pedro Teodoro  $Date: 2013/01/10 


out1 = []; out2 = []; out3 = []; y = [];
c = computer;
if ~strcmp(c(1:2),'PC')
    tp = get(0,'TerminalProtocol');
else
    tp = 'micro';
end

if ~strcmp(tp,'none') && ~strcmp(tp,'x') && ~strcmp(tp,'micro'),
    if nargout == 1,
        if nargin == 2,
            out1 = trmginput(ax,arg1);
        elseif nargin == 1,
            out1 = trmginput(ax);
        else
            out1 = trmginput;
        end
    elseif nargout == 2 || nargout == 0,
        if nargin == 2,
            [out1,out2] = trmginput(ax,arg1);
        elseif nargin == 1,
            [out1,out2] = trmginput(ax);
        else
            [out1,out2] = trmginput;
        end
        if  nargout == 0
            out1 = [ out1 out2 ];
        end
    elseif nargout == 3,
        if nargin == 2,
            [out1,out2,out3] = trmginput(ax,arg1);
        elseif nargin == 1,
            [out1,out2,out3] = trmginput(ax);
        else
            [out1,out2,out3] = trmginput;
        end
    elseif nargout == 4,
        if nargin == 2,
            [out1,out2,out3,out4] = trmginput(ax,arg1);
        elseif nargin == 1,
            [out1,out2,out3,out4] = trmginput(ax);
        else
            [out1,out2,out3,out4] = trmginput;
        end
    end
else
    
    fig = gcf;
    figure(gcf);
    
    if nargin < 2
        how_many = -1;
        b = [];
    else
        how_many = arg1;
        b = [];
        if  ischar(how_many) ...
                || size(how_many,1) ~= 1 || size(how_many,2) ~= 1 ...
                || ~(fix(how_many) == how_many) ...
                || how_many < 0
            error(message('MATLAB:ginput:NeedPositiveInt'))
        end
        if how_many == 0
            % If input argument is equal to zero points,
            % give a warning and return empty for the outputs.
            
            warning (message('MATLAB:ginput:InputArgumentZero'));
        end
    end
    
    % Setup the figure to disable interactive modes and activate pointers. 
    if nargin<2
        ax=[];
    end
    initialState = setupFcn(fig,ax);
    
    % onCleanup object to restore everything to original state in event of
    % completion, closing of figure errors or ctrl+c. 
    c = onCleanup(@() restoreFcn(initialState));
       
    
    % We need to pump the event queue on unix
    % before calling WAITFORBUTTONPRESS
    drawnow
    char = 0;
    
    while how_many ~= 0
%         set(fig,'WindowButtonMotionFcn',@changepointer)

        % Use no-side effect WAITFORBUTTONPRESS
        outax=[];
        waserr = 0;
        try
            keydown = wfbp;
        catch %#ok<CTCH>
            waserr = 1;
        end
        if(waserr == 1)
            if(ishghandle(fig))
                cleanup(c);
                error(message('MATLAB:ginput:Interrupted'));
            else
                cleanup(c);
                error(message('MATLAB:ginput:FigureDeletionPause'));
            end
        end
        % g467403 - ginput failed to discern clicks/keypresses on the figure it was
        % registered to operate on and any other open figures whose handle
        % visibility were set to off
        figchildren = allchild(0);
        if ~isempty(figchildren)
            ptr_fig = figchildren(1);
        else
            error(message('MATLAB:ginput:FigureUnavailable'));
        end
        %         old code -> ptr_fig = get(0,'CurrentFigure'); Fails when the
        %         clicked figure has handlevisibility set to callback
        if(ptr_fig == fig)
            if keydown
                char = get(fig, 'CurrentCharacter');
                button = abs(get(fig, 'CurrentCharacter'));
            else
                button = get(fig, 'SelectionType');
                if strcmp(button,'open')
                    button = 1;
                elseif strcmp(button,'normal')
                    button = 1;
                elseif strcmp(button,'extend')
                    button = 2;
                elseif strcmp(button,'alt')
                    button = 3;
                else
                    error(message('MATLAB:ginput:InvalidSelection'))
                end
            end
            axes_handle = gca;
            drawnow;
            pt = get(axes_handle, 'CurrentPoint');
            
            outax=find(ax==axes_handle);
            
            how_many = how_many - 1;
            
            if(char == 13) % & how_many ~= 0)
                % if the return key was pressed, char will == 13,
                % and that's our signal to break out of here whether
                % or not we have collected all the requested data
                % points.
                % If this was an early breakout, don't include
                % the <Return> key info in the return arrays.
                % We will no longer count it if it's the last input.
                break;
            end
            
            out1 = [out1;pt(1,1)]; %#ok<AGROW>
            y = [y;pt(1,2)]; %#ok<AGROW>
            b = [b;button]; %#ok<AGROW>
        end
    end
    
    % Cleanup and Restore 
    cleanup(c);
    
    if nargout > 1
        out2 = y;
        if nargout > 2
            out3 = b;
            if nargout > 3
                out4=outax;
            end
        end
    else
        out1 = [out1 y];
    end
    
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function key = wfbp
%WFBP   Replacement for WAITFORBUTTONPRESS that has no side effects.

fig = gcf;
current_char = []; %#ok<NASGU>

% Now wait for that buttonpress, and check for error conditions
waserr = 0;
try
    h=findall(fig,'Type','uimenu','Accelerator','C');   % Disabling ^C for edit menu so the only ^C is for
    set(h,'Accelerator','');                            % interrupting the function.
    keydown = waitforbuttonpress;
    current_char = double(get(fig,'CurrentCharacter')); % Capturing the character.
    if~isempty(current_char) && (keydown == 1)          % If the character was generated by the
        if(current_char == 3)                           % current keypress AND is ^C, set 'waserr'to 1
            waserr = 1;                                 % so that it errors out.
        end
    end
    
    set(h,'Accelerator','C');                           % Set back the accelerator for edit menu.
catch %#ok<CTCH>
    waserr = 1;
end
drawnow;
if(waserr == 1)
    set(h,'Accelerator','C');                          % Set back the accelerator if it errored out.
    error(message('MATLAB:ginput:Interrupted'));
end

if nargout>0, key = keydown; end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

function initialState = setupFcn(fig,ax)

% Store Figure Handle. 
initialState.figureHandle = fig; 

% Suspend figure functions
initialState.uisuspendState = uisuspend(fig);

% Disable Plottools Buttons
initialState.toolbar = findobj(allchild(fig),'flat','Type','uitoolbar');
if ~isempty(initialState.toolbar)
    initialState.ptButtons = [uigettool(initialState.toolbar,'Plottools.PlottoolsOff'), ...
        uigettool(initialState.toolbar,'Plottools.PlottoolsOn')];
    initialState.ptState = get (initialState.ptButtons,'Enable');
    set (initialState.ptButtons,'Enable','off');
end

% Setup FullCrosshair Pointer without warning. 
% oldwarnstate = warning('off', 'MATLAB:hg:Figure:Pointer');
% set(fig,'Pointer','crosshair')
% warning(oldwarnstate);

% Adding this to enable automatic updating of currentpoint on the figure 
set(fig,'WindowButtonMotionFcn',@(o,e) dummy(fig,ax));

% Get the initial Figure Units
initialState.fig_units = get(fig,'Units');
end

function restoreFcn(initialState)
if ishghandle(initialState.figureHandle)
    % Figure Units
    set(initialState.figureHandle,'Units',initialState.fig_units);
    set(initialState.figureHandle,'WindowButtonMotionFcn','');
    
    % Plottools Icons
    if ~isempty(initialState.toolbar) && ~isempty(initialState.ptButtons)
        set (initialState.ptButtons(1),'Enable',initialState.ptState{1});
        set (initialState.ptButtons(2),'Enable',initialState.ptState{2});
    end
    
    % UISUSPEND
    uirestore(initialState.uisuspendState);
end
end

function dummy(fig,ax)
% do nothing, this is there to update the GINPUT WindowButtonMotionFcn. 

%if mouse is inside the axes specified by the user, then a
%crosshair is shown
set(fig,'Pointer','arrow')
posfig = getpixelposition(fig);
for i=1:length(ax)
    posax = getpixelposition(ax(i));
    pos = get(0,'PointerLocation');
    if  pos(1)>posax(1)+posfig(1) && pos(1)<posax(1)+posax(3)+posfig(1) ...
     && pos(2)>posax(2)+posfig(2) && pos(2)<posax(2)+posax(4)+posfig(2)
        set(fig,'Pointer','crosshair')
    end
end

end

function cleanup(c)
if isvalid(c)
    delete(c);
end
end
