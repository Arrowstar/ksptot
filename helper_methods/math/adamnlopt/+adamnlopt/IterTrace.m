classdef IterTrace < handle
%ITERTRACE  Structured per-iteration diagnostic record for a solve.
%   An IterTrace accumulates one row of scalar diagnostics per solver
%   iteration into a preallocated numeric matrix, and hands the result back as
%   a plain struct-of-arrays via TOSTRUCT. It exists so that solver behaviour
%   is machine-readable: before it, the only trace of a run was the printed
%   iteration table, and every probe in this project (probeBarrierGate,
%   bfgsDescentProbe, memSweep) regex-parsed that text back into numbers.
%
%   The trace is strictly OBSERVATIONAL. Nothing recorded here is ever read
%   back to make a solver decision, so a run records identical steps whether
%   the trace is on or off. That property is asserted by tests/tIterTrace.
%
%   Design notes:
%     - One capacity-by-nCol double matrix, not an array of structs: MATLAB
%       grows an array of structs by copy, and post-hoc analysis of one would
%       need [T.field] on every column.
%     - A handle class, not a value struct threaded through the loop: solve's
%       iteration body would otherwise need the trace as both an input and an
%       output at every level, forcing copy-on-write on each record.
%     - NaN, not zero, is the "not recorded" sentinel. A dual regularization
%       that was measured to be zero and one that was never measured are
%       different facts, and conflating them would defeat the purpose.
%
%   Properties:
%     nRows    - number of rows recorded so far.
%     capacity - number of preallocated rows.
%     level    - detail level this trace was constructed for (see solve).
%     fields   - 1-by-nCol cellstr of column names, fixed at construction.
%
%   Methods:
%     IterTrace - construct a trace with a column list and row capacity.
%     record    - append one row from a scalar struct of named values.
%     toStruct  - return a trimmed struct-of-arrays plus column metadata.
%     reset     - discard all recorded rows.
%
%   See also SOLVE, DIAGNOSE.

    properties (SetAccess = private)
        nRows    = 0
        capacity = 0
        level    = 0
        fields   = {}
        meta     = struct()   % scalars that do not vary per iteration
    end

    properties (Access = private)
        data      = []        % capacity-by-nCol matrix of recorded values
        colOfName = []        % containers.Map from field name to column index
    end

    methods
        function obj = IterTrace(fields, capacity, level)
        %ITERTRACE  Construct a per-iteration diagnostic trace.
        %   obj = IterTrace(fields, capacity, level) preallocates a
        %   capacity-by-numel(fields) matrix of NaN and fixes the column names.
        %   Recording more than CAPACITY rows doubles the storage rather than
        %   failing, so CAPACITY is a hint, not a hard cap.
        %
        %   Inputs:
        %     fields   - 1-by-nCol cellstr of column names.
        %     capacity - (optional) preallocated row count; default 1000.
        %     level    - (optional) detail level to report back; default 1.
        %
        %   Outputs:
        %     obj - the constructed IterTrace handle object.
            if nargin < 2 || isempty(capacity), capacity = 1000; end
            if nargin < 3 || isempty(level),    level    = 1;    end
            capacity     = max(1, round(capacity));
            obj.fields   = fields(:).';
            obj.capacity = capacity;
            obj.level    = level;
            obj.data     = nan(capacity, numel(obj.fields));
            obj.colOfName = containers.Map(obj.fields, ...
                                           num2cell(1:numel(obj.fields)));
        end

        function record(obj, s)
        %RECORD  Append one row of diagnostics from a scalar struct.
        %   record(obj, s) appends a row whose entries are taken from the
        %   fields of S by name. Columns with no matching field stay NaN, and
        %   fields of S that are not columns are ignored -- so a caller may
        %   record whatever subset of the quantities it happens to have,
        %   which is what lets the two solver cores share one column list.
        %
        %   Logicals are stored as 0/1 and empty or non-scalar values as NaN,
        %   so that every column stays a plain double vector.
        %
        %   Inputs:
        %     obj - the IterTrace handle object.
        %     s   - scalar struct of named values to record.
        %
        %   Outputs:
        %     (none) obj is modified in place.
            if obj.nRows >= obj.capacity
                obj.grow();
            end
            k = obj.nRows + 1;
            row = nan(1, numel(obj.fields));
            nm = fieldnames(s);
            for i = 1:numel(nm)
                if ~obj.colOfName.isKey(nm{i}), continue; end
                v = s.(nm{i});
                if isempty(v) || ~isscalar(v) || ~(isnumeric(v) || islogical(v))
                    continue;   % leave NaN
                end
                row(obj.colOfName(nm{i})) = double(v);
            end
            obj.data(k, :) = row;
            obj.nRows      = k;
        end

        function S = toStruct(obj)
        %TOSTRUCT  Return the recorded rows as a struct-of-arrays.
        %   S = toStruct(obj) returns one nRows-by-1 double column per recorded
        %   quantity, named after that column, plus S.columns (the column
        %   names), S.level, and S.meta (per-solve scalars such as the BFGS B0
        %   scaling). The result is a plain struct, so downstream analysis and
        %   saved .mat files need no class on the path.
        %
        %   Inputs:
        %     obj - the IterTrace handle object.
        %
        %   Outputs:
        %     S - struct of nRows-by-1 columns plus columns/level/meta metadata.
            S = struct();
            for j = 1:numel(obj.fields)
                S.(obj.fields{j}) = obj.data(1:obj.nRows, j);
            end
            S.columns = obj.fields;
            S.level   = obj.level;
            S.meta    = obj.meta;
        end

        function setMeta(obj, name, value)
        %SETMETA  Record a per-solve scalar that does not vary per iteration.
        %   setMeta(obj, name, value) stores VALUE under S.meta.(NAME) in the
        %   struct returned by TOSTRUCT. Use this for quantities that are set
        %   once (the BFGS B0 scaling gamma0, the problem dimensions) rather
        %   than adding a constant column.
        %
        %   Inputs:
        %     obj   - the IterTrace handle object.
        %     name  - char field name.
        %     value - any value to store.
        %
        %   Outputs:
        %     (none) obj is modified in place.
            obj.meta.(name) = value;
        end

        function reset(obj)
        %RESET  Discard all recorded rows, keeping the column list.
        %   reset(obj) rewinds the trace to empty without reallocating.
        %
        %   Inputs:
        %     obj - the IterTrace handle object.
        %
        %   Outputs:
        %     (none) obj is modified in place.
            obj.nRows = 0;
            obj.data(:) = NaN;
        end
    end

    methods (Access = private)
        function grow(obj)
        %GROW  Double the preallocated row capacity.
        %   Called only when a solve runs past the initial capacity estimate,
        %   which the caller sizes from MaxIterations, so this is rare.
            obj.data     = [obj.data; nan(obj.capacity, numel(obj.fields))];
            obj.capacity = size(obj.data, 1);
        end
    end
end
