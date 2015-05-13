function [capStr] = cap1stLetter(str)
%cap1stLetter Summary of this function goes here
%   Detailed explanation goes here
    capStr = regexprep(str,'(\<[a-z])','${upper($1)}');
end

