function varargout = disperse(x)
% DISPERSE was created so that you can stop doing things like this:
%
%   x1 = array(1); % ...repetitive assignments from an array
%   x2 = array(2);
%   x3 = array(3);
%   x4 = array(4);
%
% and start doing things like this:
%
%   [x1 x2 x3 x4] = disperse(array);
%
% DISPERSE generalizes to arbitrary dimensions, and is extended to follow
% analogous behavior on cell arrays and structure arrays. See the html
% documentation for more details and examples.
%
% Example:
%   Grab the color channels from an RGB image:
%   [r g b] = disperse(im);

% Sam Hallman
% shallman@uci.edu
% May 26, 2010

% num2cell on column vectors is problematic
if ndims(x)==2 && size(x,2)==1
    x = x';
end

if isnumeric(x) || ischar(x) || islogical(x) || isstruct(x)
    dims = 1:ndims(x)-1;
    varargout = num2cell(x,dims);
elseif iscell(x)
    if size(x,1) == 1
        varargout = x;
    else
        dims = 1:ndims(x)-1;
        varargout = num2cell(x,dims);
    end
else
    error('unknown data type');
end
