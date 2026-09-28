function entry = ksp_lookupCube(cubeDB, partName)
%ksp_lookupCube Finds the drag-cube entry for a part name or url.
%
%   entry = ksp_lookupCube(cubeDB, partName)
%
%   Tries the full url, the url tail, and dot/underscore swapped variants
%   (craft files use '.', cfgs use '_'). Returns [] when the part has no
%   cubes. Callers treat a miss as a hard error naming the part rather
%   than substituting another part's cubes.

    entry = [];
    if(isempty(cubeDB) || ~isfield(cubeDB, 'cubes') || isempty(partName))
        return;
    end
    map = cubeDB.cubes;
    candidates = {lower(partName), ...
        lower(strrep(partName, '.', '_')), ...
        lower(strrep(partName, '_', '.'))};
    slash = find(partName == '/', 1, 'last');
    if(~isempty(slash))
        tail = partName(slash+1:end);
        candidates{end+1} = lower(tail);
        candidates{end+1} = lower(strrep(tail, '.', '_'));
        candidates{end+1} = lower(strrep(tail, '_', '.'));
    end
    for(k = 1:numel(candidates))
        if(isKey(map, candidates{k}))
            entry = map(candidates{k});
            return;
        end
    end
end
