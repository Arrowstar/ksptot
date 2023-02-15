function [rVect,vVect] = getAbsPositBetweenSpacecraftAndBody(time, rVectSC, bodySC, bodyOther, celBodyData, varargin)
%getAbsPositBetweenSpacecraftAndBody Summary of this function goes here
%   Detailed explanation goes here

    if(bodySC == bodyOther)
        rVect = -rVectSC;
        if(~isempty(varargin))
            vVectSC = varargin{1};
            vVect = -vVectSC;
        else
            vVect = nan(size(rVect));
        end
                
    else
        [rVectBodySC, vVectBodySC] = getPositOfBodyWRTSun(time, bodySC, celBodyData);
        if(numel(rVectBodySC) == 3 && numel(rVectSC) == 3)
            rVectSCTot = rVectBodySC + rVectSC;
        else
            rVectSCTot = bsxfun(@plus, rVectBodySC, rVectSC);
        end

        [rVectB, vVectB] = getPositOfBodyWRTSun(time, bodyOther, celBodyData);

        if(numel(rVectB) == 3 && numel(rVectSCTot) == 3)
            rVect = rVectB - rVectSCTot;
        else
            rVect = bsxfun(@minus, rVectB, rVectSCTot);
        end

        if(~isempty(varargin))
            vVectSC = varargin{1};
            if(numel(rVectB) == 3 && numel(rVectSCTot) == 3)
                vVectSCTot = vVectBodySC + vVectSC;
            else
                vVectSCTot = bsxfun(@plus, vVectBodySC, vVectSC);
            end

            vVect = bsxfun(@minus, vVectB, vVectSCTot);
        else
            vVect = nan(size(rVect));
        end
    end
end