function nodes = getManeuverNodesFromKSPActiveVessel()
%getManeuverNodesFromKSPActiveVessel Summary of this function goes here
%   Detailed explanation goes here

    outDoubles = readDoublesFromKSPTOTConnect('GetManeuverNodes', 'Active', true, []);
    if(isempty(outDoubles))
        nodes = [];
        return
    end
    
    lengthD = length(outDoubles);
    numRows = 4;
    numCols = lengthD / numRows;
    nodes = reshape(outDoubles, numRows, numCols)';
end

