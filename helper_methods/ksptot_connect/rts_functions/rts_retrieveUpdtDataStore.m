function rts_retrieveUpdtDataStore(obj, event, tmRetUpdtFuncs)
%rts_retrieveUpdtDataStore Summary of this function goes here
%   Detailed explanation goes here
    for(i=1:length(tmRetUpdtFuncs))
        func = tmRetUpdtFuncs{i};
        func(obj, event);
    end
end

