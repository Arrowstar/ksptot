function nodes = kwt_parseAttachNodes(rawPart)
%kwt_parseAttachNodes Parses KSP craft PART attach-node lines (attN/srfN).
%
%   nodes = kwt_parseAttachNodes(rawPart)
%
%   RAWPART is one parsed craft PART struct (sfsParse output). Returns a
%   struct with:
%       .stack - struct array for attN (stack/interstage) nodes:
%                .id (e.g. 'top', 'bottom', 'bottom01', 'interstage02a'),
%                .target (other part's instanceID, '' when unattached or
%                unresolvable here), .size (first float after the target,
%                NaN when absent; stored for future use, NOT used by the
%                v1 occlusion model), .raw (original line).
%       .srf   - struct array for srfN (surface) nodes: .id (usually
%                'srfAttach'), .target, .pos (3x1, may be NaN), .orient
%                (3x1 unit-ish, may be NaN), .raw.
%
%   Wire formats observed in KSP 1.12 craft files:
%       attN = <id>,<target>_<symIdx>|<size>|... (long, doubled node
%              descriptors) or <id>,<target>_<symIdx>|<size>|<flag>
%              (short, e.g. Dynawing cargo bay '|5|0'). The first float
%              matches the cfg node_stack_* position for uncanted parts.
%       srfN = <id>,<target>,<flag>,<pos3 pipe-separated>,
%              <orient3 pipe-separated>,<third3 pipe-separated>
%              (e.g. 'srfAttach,fuelTank...,,0|0|0,1|0|0,0|0|0'; the flag
%              is '' or 'COL'). srfN targets carry no _symIdx suffix.
%   Unattached nodes point at 'Null...' and yield target ''.
%
%   See also: kwt_buildAeroSpec, kwt_occlusionFromNodes.

    nodes = struct();
    nodes.stack = struct.empty(0, 0);
    nodes.srf = struct.empty(0, 0);

    if(~isfield(rawPart, 'attN') && ~isfield(rawPart, 'srfN'))
        return;
    end

    if(isfield(rawPart, 'attN'))
        for(line = asCellStr(rawPart.attN))
            nd = parseAttN(line{1});
            if(~isempty(nd))
                nodes.stack = appendStruct(nodes.stack, nd);
            end
        end
    end

    if(isfield(rawPart, 'srfN'))
        for(line = asCellStr(rawPart.srfN))
            nd = parseSrfN(line{1});
            if(~isempty(nd))
                nodes.srf = appendStruct(nodes.srf, nd);
            end
        end
    end
end

function nd = parseAttN(line)
    nd = [];
    if(~ischar(line))
        return;
    end
    comma = find(line == ',', 1, 'first');
    if(isempty(comma))
        return;
    end
    id = strtrim(line(1:comma-1));
    rest = line(comma+1:end);
    % NOTE: CollapseDelimiters=false matters for srfN (below); kept here
    % for the same reason (empty tokens are positional).
    toks = strsplit(rest, '|', 'CollapseDelimiters', false);
    if(numel(toks) < 1)
        return;
    end
    target = stripSymSuffix(strtrim(toks{1}));
    if(startsWith(target, 'Null'))
        target = '';
    end
    sizeVal = NaN;
    if(numel(toks) >= 2)
        v = str2double(strtrim(toks{2}));
        if(isfinite(v))
            sizeVal = v;
        end
    end
    nd = struct('id', id, 'target', target, 'size', sizeVal, 'raw', line);
end

function nd = parseSrfN(line)
    nd = [];
    if(~ischar(line))
        return;
    end
    fields = strsplit(line, ',', 'CollapseDelimiters', false);
    if(numel(fields) < 2)
        return;
    end
    id = strtrim(fields{1});
    target = strtrim(fields{2});
    if(startsWith(target, 'Null') || isempty(target))
        target = '';
    end
    % Field 3 is the surface-attach flag ('' or 'COL'); fields 4-6 are
    % the pos/orient/third pipe-triplets. strsplit MUST NOT collapse the
    % empty flag (CollapseDelimiters=false) or every triplet shifts.
    pos = [NaN; NaN; NaN];
    orient = [NaN; NaN; NaN];
    if(numel(fields) >= 4)
        pos = parsePipeTriplet(fields{4});
    end
    if(numel(fields) >= 5)
        orient = parsePipeTriplet(fields{5});
    end
    nd = struct('id', id, 'target', target, 'pos', pos, ...
        'orient', orient, 'raw', line);
end

function v = parsePipeTriplet(tok)
    v = [NaN; NaN; NaN];
    nums = sscanf(strtrim(tok), '%f|%f|%f');
    if(numel(nums) == 3)
        v = nums(:);
    end
end

function base = stripSymSuffix(target)
%stripSymSuffix Removes ONE trailing _<digits> attach-symmetry suffix:
% 'Decoupler.1_4294606904_0' -> 'Decoupler.1_4294606904' (the instanceID).

    base = target;
    tok = regexp(target, '^(.*)_\d+$', 'tokens', 'once');
    if(~isempty(tok))
        base = tok{1};
    end
end

function c = asCellStr(v)
    if(ischar(v) || isstring(v))
        c = cellstr(v);
    elseif(iscellstr(v))
        c = v;
    else
        c = {};
    end
end

function arr = appendStruct(arr, item)
    if(isempty(arr))
        arr = item;
    else
        arr(end+1) = item;
    end
end
