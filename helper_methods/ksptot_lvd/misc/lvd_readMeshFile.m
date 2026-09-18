function [V, F, info] = lvd_readMeshFile(filePath)
%lvd_readMeshFile Reads a triangle mesh from an STL (binary or ASCII) or
%Wavefront OBJ file.
%
%   [V, F, info] = lvd_readMeshFile(filePath)
%
%   V    - N x 3 vertex positions in the file's own units
%   F    - M x 3 one-based triangle vertex indices
%   info - struct(format, numVertices, numFaces, bbox) where bbox is a 2x3
%          [min; max] over the vertices and format is one of
%          'stl-binary', 'stl-ascii', 'obj'
%
%   STL facets are welded into a shared-vertex mesh (exactly coincident
%   vertices are merged).  OBJ polygons with more than three vertices are
%   fan-triangulated; texture/normal indices in face tokens (v/vt/vn) and
%   negative (relative) indices are handled.
%
%   Self-contained on purpose: the repository ships a binary-only third
%   party stlread.m that shadows MATLAB's own, so neither can be relied on.
%
%   Error identifiers:
%       lvd_readMeshFile:fileNotFound
%       lvd_readMeshFile:badExtension
%       lvd_readMeshFile:badStl
%       lvd_readMeshFile:badObj
%       lvd_readMeshFile:emptyMesh

    arguments
        filePath(1,:) char
    end

    if(not(isfile(filePath)))
        error('lvd_readMeshFile:fileNotFound', 'Mesh file not found: %s', filePath);
    end

    [~, ~, ext] = fileparts(filePath);
    switch(lower(ext))
        case '.stl'
            [V, F, format] = readStl(filePath);
        case '.obj'
            [V, F] = readObj(filePath);
            format = 'obj';
        otherwise
            error('lvd_readMeshFile:badExtension', ...
                  'Unsupported mesh file type "%s". Supported types are .stl and .obj.', ext);
    end

    if(isempty(F) || isempty(V))
        error('lvd_readMeshFile:emptyMesh', 'The mesh file "%s" contains no triangles.', filePath);
    end

    if(any(F(:) < 1) || any(F(:) > size(V,1)) || any(F(:) ~= round(F(:))))
        error('lvd_readMeshFile:badObj', 'The mesh file "%s" references vertices that do not exist.', filePath);
    end

    info = struct('format', format, ...
                  'numVertices', size(V,1), ...
                  'numFaces', size(F,1), ...
                  'bbox', [min(V,[],1); max(V,[],1)]);
end

%% ------------------------------------------------------------------ STL
function [V, F, format] = readStl(filePath)
    fileInfo = dir(filePath);
    fileBytes = fileInfo.bytes;

    fid = fopen(filePath, 'r');
    if(fid < 0)
        error('lvd_readMeshFile:fileNotFound', 'Could not open mesh file: %s', filePath);
    end
    closer = onCleanup(@() fclose(fid));

    isBinary = false;
    if(fileBytes >= 84)
        fseek(fid, 80, 'bof');
        numFacets = fread(fid, 1, 'uint32');
        if(not(isempty(numFacets)) && 84 + 50*numFacets == fileBytes)
            isBinary = true;
        end
    end

    if(isBinary)
        format = 'stl-binary';
        fseek(fid, 84, 'bof');
        raw = fread(fid, [12, numFacets], '12*float32', 2); %skip the 2 attribute bytes per facet
        raw = double(raw);
        if(size(raw,2) ~= numFacets)
            error('lvd_readMeshFile:badStl', 'Binary STL "%s" is truncated.', filePath);
        end
        %rows 1:3 normal, 4:6 v1, 7:9 v2, 10:12 v3
        tri = [raw(4:6,:); raw(7:9,:); raw(10:12,:)];   % 9 x numFacets
        Vraw = reshape(tri, 3, 3*numFacets)';           % vertices in facet order
    else
        format = 'stl-ascii';
        fseek(fid, 0, 'bof');
        txt = fread(fid, [1, Inf], '*char');
        %Header check: an ASCII STL starts with "solid"; anything else with a
        %non-matching facet count is a damaged binary file.
        if(not(startsWith(strtrim(txt), 'solid')))
            error('lvd_readMeshFile:badStl', 'STL file "%s" is neither a valid binary nor a valid ASCII STL.', filePath);
        end
        tokens = regexp(txt, 'vertex\s+([-+0-9.eEdD]+)\s+([-+0-9.eEdD]+)\s+([-+0-9.eEdD]+)', 'tokens');
        if(isempty(tokens))
            Vraw = zeros(0,3);
        else
            Vraw = cellfun(@(c) str2double(strrep(strrep(c,'d','e'),'D','e')), vertcat(tokens{:}));
        end
        if(mod(size(Vraw,1), 3) ~= 0)
            error('lvd_readMeshFile:badStl', 'ASCII STL "%s" has a vertex count that is not a multiple of three.', filePath);
        end
    end

    if(isempty(Vraw))
        V = zeros(0,3);
        F = zeros(0,3);
        return;
    end

    [V, ~, ic] = unique(Vraw, 'rows', 'stable');
    F = reshape(ic, 3, [])';
end

%% ------------------------------------------------------------------ OBJ
function [V, F] = readObj(filePath)
    txt = fileread(filePath);
    lines = regexp(txt, '\r\n|\n|\r', 'split');

    V = zeros(0,3);
    faceLines = {};
    for i = 1:numel(lines)
        line = strtrim(lines{i});
        if(isempty(line) || line(1) == '#')
            continue;
        end
        if(startsWith(line, 'v '))
            vals = sscanf(line(3:end), '%f');
            if(numel(vals) < 3)
                error('lvd_readMeshFile:badObj', 'OBJ file "%s" has a malformed vertex line: "%s"', filePath, line);
            end
            V(end+1,:) = vals(1:3)'; %#ok<AGROW>
        elseif(startsWith(line, 'f '))
            faceLines{end+1} = line(3:end); %#ok<AGROW>
        end
    end

    F = zeros(0,3);
    numV = size(V,1);
    for i = 1:numel(faceLines)
        tokens = strsplit(strtrim(faceLines{i}));
        idx = zeros(1, numel(tokens));
        for j = 1:numel(tokens)
            parts = strsplit(tokens{j}, '/');
            k = str2double(parts{1});
            if(isnan(k) || k == 0)
                error('lvd_readMeshFile:badObj', 'OBJ file "%s" has a malformed face line: "f %s"', filePath, faceLines{i});
            end
            if(k < 0)
                k = numV + 1 + k;
            end
            idx(j) = k;
        end
        if(numel(idx) < 3)
            continue;
        end
        for j = 2:numel(idx)-1
            F(end+1,:) = [idx(1), idx(j), idx(j+1)]; %#ok<AGROW>
        end
    end
end
