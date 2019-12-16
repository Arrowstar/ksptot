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

function [lia,locb] = ismemberBuiltinTypes(a,b)
    % General handling.
    % Use FIND method for very small sizes of the input vector to avoid SORT.
    if nargout > 1
        locb = zeros(size(a));
    end
    % Handle empty arrays and scalars.
    numelA = numel(a);
    numelB = numel(b);
    if numelA == 0 || numelB <= 1
        if numelA > 0 && numelB == 1
            lia = (a == b);
            if nargout > 1
                % Use DOUBLE to convert logical "1" index to double "1" index.
                locb = double(lia);
            end
        else
            lia = false(size(a));
        end
        return
    end
    
    scalarcut = 5;
    if numelA <= scalarcut
        lia = false(size(a));
        if nargout <= 1
            for i=1:numelA
                lia(i) = any(a(i)==b(:));
            end
        else
            for i=1:numelA
                found = a(i)==b(:);
                if any(found)
                    lia(i) = true;
                    locb(i) = find(found,1);
                end
            end
        end
    else
        % Use method which sorts list, then performs binary search.
        % Convert to full to work in C helper.
        if issparse(a)
            a = full(a);
        end
        if issparse(b)
            b = full(b);
        end
        
        if (isreal(b))
            % Find out whether list is presorted before sort
            sortedlist = issorted(b(:));
            if nargout > 1
                if ~sortedlist
                    [b,idx] = sort(b(:));
                end
            elseif ~sortedlist
                b = sort(b(:));
            end
        else
            sortedlist = 0;
            [~,idx] = sort(real(b(:)));
            b = b(idx);
        end
        
        % Use builtin helper function ISMEMBERHELPER:
        % [LIA,LOCB] = ISMEMBERHELPER(A,B) Returns logical array LIA indicating
        % which elements of A occur in B and a double array LOCB with the
        % locations of the elements of A occuring in B. If multiple instances
        % occur, the first occurence is returned. B must be already sorted.
        
        if ~isobject(a) && ~isobject(b) && (isnumeric(a) || ischar(a) || islogical(a))
            if (isnan(b(end)))
                % If NaNs detected, remove NaNs from B.
                b = b(~isnan(b(:)));
            end
            if nargout <= 1
                lia = builtin('_ismemberhelper',a,b);
            else
                [lia, locb] = builtin('_ismemberhelper',a,b);
            end
        else % a,b, are some other class like gpuArray, sym object.
            lia = false(size(a));
            if nargout <= 1
                for i=1:numelA
                    lia(i) = any(a(i)==b(:));   % ANY returns logical.
                end
            else
                for i=1:numelA
                    found = a(i)==b(:); % FIND returns indices for LOCB.
                    if any(found)
                        lia(i) = true;
                        found = find(found);
                        locb(i) = found(1);
                    end
                end
            end
        end
        if nargout > 1 && ~sortedlist
            % Re-reference locb to original list if it was unsorted
            locb(lia) = idx(locb(lia));
        end
    end
end