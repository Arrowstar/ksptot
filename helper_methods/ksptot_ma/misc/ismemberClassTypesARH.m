function [lia,locb] = ismemberClassTypesARH(a,b)
    if issparse(a)
        a = full(a);
    end
    if issparse(b)
        b = full(b);
    end
    % Duplicates within the sets are eliminated
    if isscalar(a) || isscalar(b)
        ab = [a(:);b(:)];
        numa = numel(a);
        lia = ab(1:numa)==ab(1+numa:end);
        if ~any(lia)
            lia  = false(size(a));
            locb = zeros(size(a));
            return
        end
        if ~isscalar(b)
            locb = find(lia);
            locb = locb(1);
            lia = any(lia);
        else
            locb = double(lia);
        end
    else
        % Duplicates within the sets are eliminated
        [uA,~,icA] = unique(a(:),'sorted');
        if nargout <= 1
            uB = unique(b(:),'sorted');
        else
            [uB,ib] = unique(b(:),'sorted');
        end
        
        % Sort the unique elements of A and B, duplicate entries are adjacent
        [sortuAuB,IndSortuAuB] = sort([uA;uB]);
        
        % Find matching entries
        d = sortuAuB(1:end-1)==sortuAuB(2:end);         % d indicates the indices matching entries
        ndx1 = IndSortuAuB(d);                          % NDX1 are locations of repeats in C
        
        if nargout <= 1
            lia = ismemberBuiltinTypes(icA,ndx1);       % Find repeats among original list
        else
            szuA = size(uA,1);
            d = find(d);
            [lia,locb] = ismemberBuiltinTypes(icA,ndx1);% Find locb by using given indices
            newd = d(locb(lia));                        % NEWD is D for non-unique A
            where = ib(IndSortuAuB(newd+1)-szuA);       % Index values of uB through UNIQUE
            locb(lia) = where;                          % Return first or last occurrence of A within B
        end
    end
    
    lia = reshape(lia,size(a));
    if nargout > 1
        locb = reshape(locb,size(a));
    end
end