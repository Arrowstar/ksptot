function varargout = dsxy2figxy(varargin)
% dsxy2figxy Transform from data space to normalized figure coordinates
%
% Transforms [x y] or [x y width height] vectors from data space
% coordinates to normalized figure coordinates in order to locate
% annotation objects within a figure. These objects are: arrow,
% doublearrow, textarrow, ellipse line, rectangle, textbox
%
% Syntax:
%    [figx figy] = dsxy2figxy([x1 x2],[y1 y2])  % GCA is used
%    figpos      = dsxy2figxy([x1 y1 width height])  % GCA is used
%    [figx figy] = dsxy2figxy(axes_handle, [x1 x2],[y1 y2])
%    figpos      = dsxy2figxy(axes_handle, [x1 y1 width height])
%
% Usage: Obtain a position on a plot in data space and
%        apply this function to locate an annotation there, e.g.,
%   [axx axy] = ginput(2); (input is in data space)
%   [figx figy] = dsxy2figxy(gca, axx, axy);  (now in figure space)
%   har = annotation('textarrow',figx,figy);
%   set(har,'String',['(' num2str(axx(2)) ',' num2str(axy(2)) ')'])
%
%   Copyright 2006-2009 The MathWorks, Inc.
% Updated by Todd A. Baxter
%   2017-06-25: works for axes embedded in uipanel hierarchy
%   2017-07-13: works for axes with logarithmic scales
%   2017-07-30: works for axes with reverse directions
%   2017-08-02: HG2 update for axes embedded in uipanel hierarchy
% Obtain arguments (limited argument checking is done)
% Determine if axes handle is specified
if length(varargin{1}) == 1 && ishandle(varargin{1}) ...
                            && strcmp(get(varargin{1},'type'),'axes')
	hAx = varargin{1};
	varargin = varargin(2:end); % Remove arg 1 (axes handle)
else
	hAx = gca;
end
% Remaining args are either two point locations or a position vector
if length(varargin) == 1        % Assume a 4-element position vector
	pos = varargin{1};
    % Convert position to linear scale (if necessary)
    if strcmp(get(hAx,'xscale'),'log')
        pos(3) = log10(pos(1)+pos(3)) - log10(pos(1));
        pos(1) = log10(pos(1));
    end
    if strcmp(get(hAx,'yscale'),'log')
        pos(4) = log10(pos(2)+pos(4)) - log10(log(2));
        pos(2) = log10(pos(2));
    end
else
	[x,y] = deal(varargin{:});  % Assume two pairs (start, end points)
    % Convert x,y to linear scale (if necessary)
    if strcmp(get(hAx,'xscale'),'log')
        x = log10(x);
    end
    if strcmp(get(hAx,'yscale'),'log')
        y = log10(y);
    end
end
% Get axes position in pixels
v = ver('matlab');
if str2double(v.Version) >= 8.4 % R2014b
    % w.r.t. axes parent
    hContainer = get(hAx,'parent');
    axpos = getpixelposition(hAx);
else % HG1 backwards compatibility
    % w.r.t. figure
    hContainer = ancestor(hAx,'figure');
    axpos = getpixelposition(hAx, true);
end
% Get the axes limits [xlim ylim (zlim)]
axlim = axis(hAx);
% Reverse order of axes limits (if necessary)
if strcmp(get(hAx,'xdir'),'reverse')
    axlim(1:2) = axlim(2:-1:1);
end
if strcmp(get(hAx,'ydir'),'reverse')
    axlim(3:4) = axlim(4:-1:3);
end
% Convert axes limits to linear scale (if necessary)
if strcmp(get(hAx,'xscale'),'log')
    axlim(1:2) = log10(axlim(1:2));
end
if strcmp(get(hAx,'yscale'),'log')
    axlim(3:4) = log10(axlim(3:4));
end
% Compute axes width and height
axwidth = diff(axlim(1:2));
axheight = diff(axlim(3:4));
% Transform from data space coordinates to normalized figure coordinates
hFig = ancestor(hAx,'figure');
if exist('x','var')     % Transform and return a pair of points
	figx = (x - axlim(1)) / axwidth * axpos(3) + axpos(1);
	figy = (y - axlim(3)) / axheight * axpos(4) + axpos(2);
    for i = 1:numel(figx)
        figpos(i,:) = hgconvertunits(hFig, [figx(i),figy(i),0,0], 'pixels', 'normalized', hContainer); %#ok<AGROW>
    end
    varargout{1} = figpos(:,1)';
    varargout{2} = figpos(:,2)';
else                    % Transform and return a position rectangle
	figpos(1) = (pos(1) - axlim(1)) / axwidth * axpos(3) + axpos(1);
	figpos(2) = (pos(2) - axlim(3)) / axheight * axpos(4) + axpos(2);
	figpos(3) = pos(3) * axpos(3) / axwidth;
	figpos(4) = pos(4) * axpos(4) / axheight;
	varargout{1} = hgconvertunits(hFig, figpos, 'pixels', 'normalized', hContainer);
end