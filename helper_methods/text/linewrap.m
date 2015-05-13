function c = linewrap(s, maxchars)
%LINEWRAP Separate a single string into multiple strings
%   C = LINEWRAP(S, MAXCHARS) separates a single string into multiple
%   strings by separating the input string, S, on word breaks.  S must be a
%   single-row char array. MAXCHARS is a nonnegative integer scalar
%   specifying the maximum length of the broken string.  C is a cell array
%   of strings.
%
%   C = LINEWRAP(S) is the same as C = LINEWRAP(S, 80).
%
%   Note: Words longer than MAXCHARS are not broken into separate lines.
%   This means that C may contain strings longer than MAXCHARS.
%
%   This implementation was inspired a blog posting about a Java line
%   wrapping function:
%   http://joust.kano.net/weblog/archives/000060.html
%   In particular, the regular expression used here is the one mentioned in
%   Jeremy Stein's comment.
%
%   Example
%       s = 'Image courtesy of Joe and Frank Hardy, MIT, 1993.'
%       c = linewrap(s, 40)
%
%   See also TEXTWRAP.

% Steven L. Eddins
% $Revision: 1.7 $  $Date: 2006/02/08 16:54:51 $

error(nargchk(1, 2, nargin));

bad_s = ~ischar(s) || (ndims(s) > 2) || (size(s, 1) ~= 1);
if bad_s
   error('S must be a single-row char array.');
end

if nargin < 2
   % Default value for second input argument.
   maxchars = 80;
end

% Trim leading and trailing whitespace.
s = strtrim(s);

% Form the desired regular expression from maxchars.
exp = sprintf('(\\S\\S{%d,}|.{1,%d})(?:\\s+|$)', maxchars, maxchars);

% Interpretation of regular expression (for maxchars = 80):
% '(\\S\\S{80,}|.{1,80})(?:\\s+|$)'
%
% Match either a non-whitespace character followed by 80 or more
% non-whitespace characters, OR any sequence of between 1 and 80
% characters; all followed by either one or more whitespace characters OR
% end-of-line.

tokens = regexp(s, exp, 'tokens').';

% Each element if the cell array tokens is single-element cell array 
% containing a string.  Convert this to a cell array of strings.
get_contents = @(f) f{1};
c = cellfun(get_contents, tokens, 'UniformOutput', false);

% Remove trailing whitespace characters from strings in c.  This can happen
% if multiple whitespace characters separated the last word on a line from
% the first word on the following line.
c = deblank(c);


