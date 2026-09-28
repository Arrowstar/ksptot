function [occlusions, notes] = kwt_occlusionFromNodes(parts, M)
%kwt_occlusionFromNodes Node-area occlusion multipliers from attach topology.
%
%   [occlusions, notes] = kwt_occlusionFromNodes(parts, M)
%
%   PARTS is a struct array with .instanceID, .cube (.faces 6x3, may be a
%   zero cube), .posCraft (1x3, may be empty), .R_part2vessel (3x3 aero
%   DCM), and .attachNodes (kwt_parseAttachNodes output). M is the
%   craft->aero nose permutation from kwt_buildAeroSpec, so
%   Rpc = M' * R_part2vessel maps craft-frame directions into the part
%   cube frame.
%
%   V1 node-area model (methodology section 6.6: full mesh raycasts
%   deferred): an attached joint covers min(own, partner) of the two
%   mating faces, i.e. the occluded fraction of the own face is
%   clamp(partnerFaceArea / ownFaceArea, 0, 1), using ONLY drag-cube
%   areas plus the attN/srfN topology (node IDs + targets). The craft
%   attN size floats are parsed and stored but deliberately unused --
%   their unit is ambiguous (they match cfg node positions, not areas).
%   Multiple joints on one face combine multiplicatively.
%
%   Face mapping (part-local cube frame, KSP stack axis = Y):
%       top* nodes    -> +Y face (3); partner's -Y face (4)
%       bottom* nodes -> -Y face (4); partner's +Y face (3)
%       other ids (interstage*, srfAttach, ...) -> nearest face to the
%         partner direction from craft positions; partner's face toward
%         us likewise. srfN is restricted to the four side faces; a
%         degenerate (coincident) position falls back to the srfN orient
%         triplet (contact opposite the node orientation).
%   Unattached (Null) or unresolvable targets are skipped; unresolvable
%   non-Null targets are reported in NOTES.
%
%   OCCLUSIONS is Nx6 (N = numel(parts)), one area multiplier per face in
%   +X,-X,+Y,-Y,+Z,-Z order, applied by ksp_setDrag.
%
%   See also: kwt_parseAttachNodes, kwt_buildAeroSpec, ksp_setDrag.

    N = [1 0 0; -1 0 0; 0 1 0; 0 -1 0; 0 0 1; 0 0 -1];
    SIDE_FACES = [1 2 5 6];

    idToIdx = containers.Map('KeyType', 'char', 'ValueType', 'double');
    for(i = 1:numel(parts))
        if(~isKey(idToIdx, parts(i).instanceID))
            idToIdx(parts(i).instanceID) = i;
        end
    end

    occlusions = ones(numel(parts), 6);
    notes = {};

    for(i = 1:numel(parts))
        if(~isfield(parts(i), 'attachNodes') || isempty(parts(i).attachNodes))
            continue;
        end
        Rpc = M' * parts(i).R_part2vessel;
        nodes = parts(i).attachNodes;

        for(s = 1:numel(nodes.stack))
            nd = nodes.stack(s);
            if(isempty(nd.target) || ~isKey(idToIdx, nd.target))
                notes = noteUnresolved(notes, parts(i).instanceID, nd.id, nd.target);
                continue;
            end
            j = idToIdx(nd.target);
            if(j == i)
                continue;
            end
            [own, pface] = stackFaces(nd.id);
            if(own == 0)
                [own, pface] = positionFaces(parts, i, j, M, N, 1:6);
                if(own == 0)
                    continue;
                end
            end
            occlusions(i, own) = occlusions(i, own) * (1 - coverFraction(parts, i, own, j, pface));
        end

        for(s = 1:numel(nodes.srf))
            nd = nodes.srf(s);
            if(isempty(nd.target) || ~isKey(idToIdx, nd.target))
                notes = noteUnresolved(notes, parts(i).instanceID, nd.id, nd.target);
                continue;
            end
            j = idToIdx(nd.target);
            if(j == i)
                continue;
            end
            [own, pface] = srfFaces(parts, i, j, Rpc, nd, M, N, SIDE_FACES);
            if(own == 0)
                continue;
            end
            occlusions(i, own) = occlusions(i, own) * (1 - coverFraction(parts, i, own, j, pface));
            % Mutual: the surface record lives only on the child, so cap
            % the parent's facing patch here too (the stack case is
            % already mutual through both sides' attN records).
            occlusions(j, pface) = occlusions(j, pface) * (1 - coverFraction(parts, j, pface, i, own));
        end
    end
end

function [own, pface] = stackFaces(id)
    l = lower(id);
    if(contains(l, 'bottom'))
        own = 4; pface = 3;   % -Y face; partner's +Y faces us
    elseif(contains(l, 'top'))
        own = 3; pface = 4;   % +Y face; partner's -Y faces us
    else
        own = 0; pface = 0;
    end
end

function [own, pface] = positionFaces(parts, i, j, M, N, faceSet)
%positionFaces Nearest-face pair from craft positions (both directions).

    own = 0; pface = 0;
    pi = getPos(parts(i));
    pj = getPos(parts(j));
    if(any(~isfinite(pi)) || any(~isfinite(pj)))
        return;
    end
    RpcI = M' * parts(i).R_part2vessel;
    RpcJ = M' * parts(j).R_part2vessel;
    dij = pj - pi;
    if(norm(dij) <= 1e-12)
        return;
    end
    own = nearestFace(N(faceSet, :), RpcI' * dij(:) / norm(dij));
    own = faceSet(own);
    dji = -dij;
    q = nearestFace(N, RpcJ' * dji(:) / norm(dji));
    pface = q;
end

function [own, pface] = srfFaces(parts, i, j, Rpc, nd, M, N, sideFaces)
% Contact patch faces the partner: own outward normal most parallel to
% the partner direction (position-based); partner's face toward us.

    own = 0; pface = 0;
    pi = getPos(parts(i));
    pj = getPos(parts(j));
    if(all(isfinite(pi)) && all(isfinite(pj)) && norm(pj - pi) > 1e-12)
        dLocal = Rpc' * (pj(:) - pi(:));
        dLocal = dLocal / norm(dLocal);
        dots = N(sideFaces, :) * dLocal;
        [~, k] = max(dots);
        own = sideFaces(k);
    elseif(all(isfinite(nd.orient)) && norm(nd.orient) > 0)
        % Fallback: srf node orientation points out of the attach patch
        % (KSP node convention), so the contact is the most anti-parallel
        % side face. Documented fallback; positions are the primary rule.
        o = nd.orient(:) / norm(nd.orient);
        dots = N(sideFaces, :) * (-o);
        [~, k] = max(dots);
        own = sideFaces(k);
    else
        return;
    end
    RpcJ = M' * parts(j).R_part2vessel;
    dji = pi(:) - pj(:);
    if(any(~isfinite(dji)) || norm(dji) <= 1e-12)
        pface = own;   % symmetric fallback keeps the fraction finite
    else
        pface = nearestFace(N, RpcJ' * (dji / norm(dji)));
    end
end

function f = coverFraction(parts, i, own, j, pface)
    f = 0;
    if(~isfield(parts(i).cube, 'faces') || ~isfield(parts(j).cube, 'faces'))
        return;
    end
    ownArea = parts(i).cube.faces(own, 1);
    partnerArea = parts(j).cube.faces(pface, 1);
    if(~isfinite(ownArea) || ownArea <= 0 || ~isfinite(partnerArea) || partnerArea < 0)
        return;
    end
    f = min(1, partnerArea / ownArea);
end

function p = getPos(part)
    p = [NaN NaN NaN];
    if(isfield(part, 'posCraft') && numel(part.posCraft) == 3 ...
            && all(isfinite(part.posCraft)))
        p = double(part.posCraft(:)');
    end
end

function idx = nearestFace(normals, dir)
    [~, idx] = max(normals * dir(:));
end

function notes = noteUnresolved(notes, instanceID, nodeId, target)
    if(isempty(target))
        return;   % unattached (Null) nodes: nothing to occlude
    end
    notes{end+1} = sprintf(['Part "%s" node "%s" targets "%s", which is ' ...
        'not in the vessel; skipping its occlusion.'], ...
        instanceID, nodeId, target);
end
