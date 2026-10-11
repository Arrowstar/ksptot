function tf = lvdIdsEqual(A, B)
%lvdIdsEqual Class-aware identity comparison for LVD id-based objects.
%
%   tf = lvdIdsEqual(A, B) compares object arrays element-wise (with scalar
%   expansion, matching the legacy `[A.id] == [B.id]` semantics) but also
%   requires matching classes.  This prevents cross-type conflation when
%   two objects of different classes happen to share an id value.
%
%   Intended for sealed eq/ne overloads:
%       function tf = eq(A,B), tf = lvdIdsEqual(A,B); end
%       function tf = ne(A,B), tf = ~lvdIdsEqual(A,B); end
%
%   See also: lvdGetNextUniqueId.

    if(isscalar(A) && isscalar(B))
        tf = strcmp(class(A), class(B)) && (A.id == B.id);
        return;
    end

    try
        idEq = ([A.id] == [B.id]);
    catch
        error('Matrix dimensions must agree.');
    end

    if(isscalar(A) && ~isscalar(B))
        A = repmat(A, size(B));
    elseif(isscalar(B) && ~isscalar(A))
        B = repmat(B, size(A));
    end

    if(isempty(A) || isempty(B))
        tf = idEq;
        return;
    end

    tfClass = arrayfun(@(i) strcmp(class(A(i)), class(B(i))), 1:numel(A));
    tfClass = reshape(tfClass, size(idEq));
    tf = tfClass & idEq;
end
