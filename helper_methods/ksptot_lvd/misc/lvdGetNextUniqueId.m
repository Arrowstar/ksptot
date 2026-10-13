function id = lvdGetNextUniqueId()
%lvdGetNextUniqueId Session-unique integer id for LVD handle objects.
%
%   id = lvdGetNextUniqueId() returns a double that is an exact integer,
%   unique within this MATLAB session (monotonically increasing).
%
%   Rationale: object identity throughout LVD is defined by sealed
%   id-based eq methods (AbstractOptimizationVariable, AbstractEventAction,
%   and siblings).  The legacy pattern obj.id = rand() draws from [0,1),
%   and fresh MATLAB processes reuse the default random stream, so ids
%   repeat across sessions and can collide within a session.  Collisions
%   silently conflate distinct variables/actions (wrong event resolution,
%   wrong deletions).
%
%   New ids live in integer space at/above 2^32, which is disjoint from
%   every legacy rand() id in [0,1), so old .mat files can never collide
%   with newly created objects.  Doubles represent integers exactly up to
%   2^53, so incrementing integers here is collision-free.
%
%   The per-session base mixes wall-clock time, process id, and a random
%   draw so two processes started at the same moment still diverge.  The
%   global random stream is not disturbed (no rng('shuffle') call), so
%   perturbVar and solver stochasticity are unaffected.
%
%   See also: AbstractOptimizationVariable, AbstractEventAction.

    persistent nextId;

    if(isempty(nextId))
        nextId = computeSessionBase();
    end

    nextId = nextId + 1;
    id = double(nextId);
end

function base = computeSessionBase()
    %COMPUTESESSIONBASE First id base for this session (>= 2^32).
    baseOffset = uint64(0);
    try
        % Milliseconds within the day, mod 2^20 (~12 days of ms range
        % folded down; enough entropy combined with pid below).
        t = now; %#ok<TNOW1>
        msOfDay = uint64(floor(mod(t * 86400 * 1000, 2^20)));
        baseOffset = bitxor(baseOffset, bitshift(msOfDay, 8));
    catch
        % clock unavailable: fall through with zero time component
    end

    try
        pid = uint64(feature('getpid'));
        baseOffset = bitxor(baseOffset, bitshift(bitand(pid, uint64(2^20-1)), 4));
    catch
        % getpid unavailable (e.g. deployed): skip pid component
    end

    try
        % Random component without touching the global stream.
        rs = RandStream.create('mt19937ar', 'Seed', sum(100*clock));
        baseOffset = bitxor(baseOffset, uint64(randi(rs, 2^20-1)));
    catch
        try
            baseOffset = bitxor(baseOffset, uint64(floor(rand()*2^20)));
        catch
            % last resort: time/pid only
        end
    end

    try
        % Java UUID adds cross-process entropy on workers sharing pid/time.
        uuidStr = char(java.util.UUID.randomUUID().toString());
        uuidHash = uint64(mod(sum(double(uuidStr)) * 2654435761, 2^20));
        baseOffset = bitxor(baseOffset, uuidHash);
    catch
        % Java unavailable: skip
    end

    baseOffset = bitand(baseOffset, uint64(2^28-1));
    base = double(uint64(2^32) + baseOffset);
end
