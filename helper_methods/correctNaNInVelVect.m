function [ newVelVect ] = correctNaNInVelVect(velVect)
%correctNaNInVelVect Summary of this function goes here
%   Detailed explanation goes here

    if(isempty(find(isnan(velVect), 1)))
        newVelVect = velVect;
    else 
        newVelVect = [1E25 1E25 1E25];
    end
end

