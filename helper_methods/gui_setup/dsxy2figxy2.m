function varargout = dsxy2figxy2(varargin)
% dsxy2figxy -- Transform point or position from axis to figure coords
% Transforms [axx axy] or [xypos] from axes hAx (data) coords into coords
% wrt GCF for placing annotation objects that use figure coords into data
% space. The annotation objects this can be used for are
%    arrow, doublearrow, textarrow
%    ellipses (coordinates must be transformed to [x, y, width, height])
% Note that line, text, and rectangle anno objects already are placed
% on a plot using axes coordinates and must be located within an axes.
% Usage: Compute a position and apply to an annotation, e.g.,
%   [axx axy] = ginput(2);
%   [figx figy] = getaxannopos(gca, axx, axy);
%   har = annotation('textarrow',figx,figy);
%   set(har,'String',['(' num2str(axx(2)) ',' num2str(axy(2)) ')'])
%% Obtain arguments (only limited argument checking is performed).
% Determine if axes handle is specified
if length(varargin{1})== 1 && ishandle(varargin{1}) && ...
  strcmp(get(varargin{1},'type'),'axes') 
 hAx = varargin{1};
 varargin = varargin(2:end);
else
 hAx = gca;
end;
% Parse either a position vector or two 2-D point tuples
if length(varargin)==1 % Must be a 4-element POS vector
 pos = varargin{1};
else
 [x,y] = deal(varargin{:});  % Two tuples (start & end points)
end
%% Get limits
axun = get(hAx,'Units');
set(hAx,'Units','normalized');  % Need normaized units to do the xform
axpos = get(hAx,'Position');
axlim = axis(hAx);              % Get the axis limits [xlim ylim (zlim)]
axwidth = diff(axlim(1:2));
axheight = diff(axlim(3:4));
yisreversed = strcmpi(get(hAx,'ydir'),'reverse');
xisreversed = strcmpi(get(hAx,'xdir'),'reverse');
%% Transform data from figure space to data space
if exist('x','var')     % Transform a and return pair of points
  xout = (x-axlim(1))/axwidth;
  yout = (y-axlim(3))/axheight;
  if xisreversed,
    xout = 1 - xout;
  end
  if yisreversed
    yout = 1 - yout;
  end
  
  varargout{1} = xout*axpos(3) + axpos(1);
  varargout{2} = yout*axpos(4) + axpos(2);
else                    % Transform and return a position rectangle
  xout = (pos(1)-axlim(1))/axwidth;
  yout = (pos(2)-axlim(3))/axheight;
  if xisreversed,
    xout = 1 - xout;
  end
  if yisreversed,
    yout = 1 - yout;
  end
  pos(1) = xout*axpos(3) + axpos(1);
  pos(2) = yout*axpos(4) + axpos(2);
  pos(3) = pos(3)*axpos(3)/axwidth;
  pos(4) = pos(4)*axpos(4)/axheight;
  varargout{1} = pos;
end
%% Restore axes units
set(hAx,'Units',axun)