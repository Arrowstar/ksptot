function value = lvd_selectVisibleListValue(candidates, visible)
    arguments
        candidates(1,:) cell
        visible
    end

    value = {};
    for(i=1:numel(candidates))
        candidate = candidates{i};
        if(isempty(candidate) || isempty(visible))
            continue
        end
        if(ischar(candidate) || isstring(candidate))
            continue
        end
        if(not(isa(candidate, class(visible))))
            continue
        end
        if(any(candidate == visible))
            value = candidate;
            return
        end
    end
end
