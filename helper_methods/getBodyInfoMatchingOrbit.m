function [bodyInfo] = getBodyInfoMatchingOrbit(orbit, celBodyData)
%getBodyInfoMatchingOrbit Summary of this function goes here
%   Detailed explanation goes here
    bodyInfo = [];

    bodyNames = fieldnames(celBodyData);
	for(i=1:length(bodyNames)) %#ok<*NO4LP>
        tmpbodyInfo = celBodyData.(bodyNames{i});
        
        if(testParam(orbit(1), tmpbodyInfo.sma) &&...
           testParam(orbit(2), tmpbodyInfo.ecc) &&...
           testParam(orbit(3), deg2rad(tmpbodyInfo.inc)) &&...
           testParam(orbit(4), deg2rad(tmpbodyInfo.raan)) &&...
           testParam(orbit(5), deg2rad(tmpbodyInfo.arg)) &&...
           testParam(orbit(6), deg2rad(tmpbodyInfo.mean)) &&...
           testParam(orbit(7), tmpbodyInfo.epoch))
            bodyInfo = tmpbodyInfo;
            break;
        end
	end
end

function bool = testParam(param, bodyInfoParam)
    bool = false;
    
    if(abs(param - bodyInfoParam) < 1E-10)
        bool = true;
    end
end