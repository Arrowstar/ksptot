function root = ksptotTestRoot()
% ksptotTestRoot Returns the absolute path to the KSPTOT repository root.
%
% The repository root is the folder two levels above this file
% (tests/helpers/ksptotTestRoot.m -> repo root).

    persistent cachedRoot
    if(isempty(cachedRoot))
        cachedRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    end

    root = cachedRoot;
end
