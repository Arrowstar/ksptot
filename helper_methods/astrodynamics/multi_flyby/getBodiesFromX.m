function [bodiesInfo] = getBodiesFromX(x,bodiesInfo,numIntermWayPt,childrenNames,celBodyData)
%getBodiesFromX Summary of this function goes here
%   Detailed explanation goes here
    interBodiesX = x(:,end-(numIntermWayPt-1):end);
    bodiesInfoTemp = cell(size(interBodiesX,1), numIntermWayPt+2);
    
    bodiesInfoTemp(:,1) = bodiesInfo(1);
    for(h=1:size(interBodiesX,1))
        for(i=1:numIntermWayPt) %#ok<*NO4LP>
            bodiesInfoTemp{h,i+1} = celBodyData.(lower(childrenNames{interBodiesX(i)}));
        end
    end
    bodiesInfoTemp(:,end) = bodiesInfo(2);

    bodiesInfo = bodiesInfoTemp;
end

