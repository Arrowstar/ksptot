function errMsg = checkIfInputBodiesAreSame(departBody, arriveBody, prevErrMsgs, varargin)
%checkIfInputBodiesAreSame Summary of this function goes here
%   Detailed explanation goes here
    if(nargin==5)
        bodyName1 = varargin{1};
        bodyName2 = varargin{2};
    else
        bodyName1 = 'Departure body';
        bodyName2 = 'arrival body';
    end
    errMsg = prevErrMsgs;
    if(strcmpi(departBody, arriveBody))
        departBody = ['(', cap1stLetter(lower(departBody)), ')'];
        arriveBody = ['(', cap1stLetter(lower(arriveBody)), ')'];
        errMsg{end+1} = [bodyName1, ' ', departBody, ' and ', bodyName2, ' ', arriveBody, ' must be different.'];
    end
end

