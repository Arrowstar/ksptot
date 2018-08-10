function [rVect,vVect] = getAbsPositBetweenSpacecraftAndBody(time, rVectSC, bodySC, bodyOther, celBodyData, varargin)
%getAbsPositBetweenSpacecraftAndBody Summary of this function goes here
%   Detailed explanation goes here

    [rVectBodySC, vVectBodySC] = getPositOfBodyWRTSun(time, bodySC, celBodyData);
    rVectSCTot = bsxfun(@plus, rVectBodySC, rVectSC);
    
    [rVectB, vVectB] = getPositOfBodyWRTSun(time, bodyOther, celBodyData);
    
    rVect = bsxfun(@minus, rVectB, rVectSCTot);
    
    if(~isempty(varargin))
        vVectSC = varargin{1};
        vVectSCTot = bsxfun(@plus, vVectBodySC, vVectSC);

        vVect = bsxfun(@minus, vVectB, vVectSCTot);
    else
        vVect = nan(size(rVect));
    end
end