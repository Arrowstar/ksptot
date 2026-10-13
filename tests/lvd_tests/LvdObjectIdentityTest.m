classdef LvdObjectIdentityTest < KsptotTestCase
    %LvdObjectIdentityTest Identity, load-stability, and style-value tests.
    %
    %   Regression coverage for UPSTREAM_BUGS_LVD Bugs 1, 2, and 4:
    %     Bug 1: sealed id-based eq/ne plus rand() ids conflated distinct
    %            objects.  eq/ne are now class-aware (lvdIdsEqual) and new
    %            ids come from lvdGetNextUniqueId (integers >= 2^32,
    %            disjoint from every legacy rand() id in [0,1)).
    %     Bug 2: OptimizationVariableSet.loadobj deleted variables on every
    %            file open.  The loadobj hook is removed; opening a case
    %            must preserve the variable set exactly.
    %     Bug 4: LineSpecEnum/MarkerStyleEnum were mutable handle
    %            singletons.  They are now immutable-payload value classes,
    %            and EventColorLineSpec offers copy() for duplication paths.

    methods(Test)

        %% Bug 1: allocator hands out session-unique integer ids

        function allocatorIdsAreUniqueIntegersAboveLegacyRange(testCase)
            n = 500;
            ids = zeros(1, n);
            for(i = 1:n)
                ids(i) = lvdGetNextUniqueId();
            end

            testCase.verifyTrue(all(ids >= 2^32), ...
                'New ids must live at/above 2^32, disjoint from legacy rand() ids in [0,1).');
            testCase.verifyEqual(ids, floor(ids), ...
                'Ids must be exact integers (doubles represent integers exactly below 2^53).');
            testCase.verifyEqual(numel(unique(ids)), n, ...
                'Ids must be unique within the session.');
            testCase.verifyTrue(all(diff(ids) == 1), ...
                'Ids must be monotonically sequential within the session.');
        end

        function newVariablesArriveWithUniqueIds(testCase)
            a = EventDurationOptimizationVariable(EventDurationTermCondition(0));
            b = EventDurationOptimizationVariable(EventDurationTermCondition(0));

            testCase.verifyNotEqual(a.id, b.id, ...
                'Two freshly constructed variables must not share an id.');
            testCase.verifyFalse(a == b);
            testCase.verifyTrue(a ~= b);
        end

        %% Bug 1: equality is class-aware and ne-consistent

        function crossClassVarsWithEqualIdsAreNotEqual(testCase)
            durVar = EventDurationOptimizationVariable(EventDurationTermCondition(0));
            altVar = AltitudeOptimizationVariable(AltitudeTermCondition(0));

            %Simulate a legacy id collision across classes.
            altVar.id = durVar.id;

            testCase.verifyFalse(durVar == altVar, ...
                'Cross-class == must be false even when ids collide.');
            testCase.verifyTrue(durVar ~= altVar, ...
                '~= must negate ==.');
            testCase.verifyFalse(lvdIdsEqual(durVar, altVar));
        end

        function sameClassVarsCompareById(testCase)
            a = EventDurationOptimizationVariable(EventDurationTermCondition(0));
            b = EventDurationOptimizationVariable(EventDurationTermCondition(0));

            testCase.verifyFalse(a == b);
            testCase.verifyTrue(a ~= b);

            b.id = a.id;
            testCase.verifyTrue(a == b, ...
                'Same-class vars with equal ids compare equal (id identity).');
            testCase.verifyFalse(a ~= b);
        end

        function arrayEqSupportsScalarExpansion(testCase)
            a = EventDurationOptimizationVariable(EventDurationTermCondition(0));
            b = EventDurationOptimizationVariable(EventDurationTermCondition(0));

            arr = [a, b];
            testCase.verifyEqual(arr == a, [true, false], ...
                'Array == scalar must expand element-wise like the legacy id-vector comparison.');
            testCase.verifyEqual(arr ~= a, [false, true]);
        end

        function actionEqIsClassAwareAndNeConsistent(testCase)
            a = ConditionalAction();
            b = ConditionalAction();

            testCase.verifyTrue(a == a);
            testCase.verifyFalse(a == b);
            testCase.verifyTrue(a ~= b, ...
                'AbstractEventAction previously defined no ne at all (~= used handle identity).');

            c = EventDurationOptimizationVariable(EventDurationTermCondition(0));
            c.id = a.id;
            %Cross-type comparison must not error and must be false; the
            %class gate is what protects getEventNumberForVar-style scans.
            try
                tf = (a == c);
            catch
                tf = false;
            end
            testCase.verifyFalse(any(tf(:)), ...
                'Action == variable must never report equality.');
        end

        function removeVariableDeletesASingleMatch(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            a = EventDurationOptimizationVariable(EventDurationTermCondition(0));
            b = EventDurationOptimizationVariable(EventDurationTermCondition(0));
            %Simulate a legacy same-class collision: both match.
            b.id = a.id;

            lvdData.optimizer.vars.addVariable(a);
            lvdData.optimizer.vars.addVariable(b);
            nBefore = numel(lvdData.optimizer.vars.vars);

            lvdData.optimizer.vars.removeVariable(a);

            testCase.verifyEqual(numel(lvdData.optimizer.vars.vars), nBefore - 1, ...
                'removeVariable must delete exactly one match, never every colliding id.');
        end

        %% Bug 2: file open must not prune variables

        function variableSetHasNoLoadobjPruning(testCase)
            mt = ?OptimizationVariableSet;
            names = {mt.MethodList.Name};
            testCase.verifyFalse(any(strcmp(names, 'loadobj')), ...
                'OptimizationVariableSet must not define loadobj (it deleted vars on every load).');
        end

        function removeUselessVarsKeepsResolvableVars(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt = lvdData.script.getEventForInd(1);
            evt.termCond = EventDurationTermCondition(100);

            v = EventDurationOptimizationVariable(evt.termCond);
            v.useTf = true;
            lvdData.optimizer.vars.addVariable(v);
            nBefore = numel(lvdData.optimizer.vars.vars);

            removed = lvdData.optimizer.vars.removeUselessVars();

            testCase.verifyEmpty(removed, ...
                'A variable linked to its event must survive removeUselessVars.');
            testCase.verifyEqual(numel(lvdData.optimizer.vars.vars), nBefore);
        end

        function saveLoadRoundTripPreservesVariableCount(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt = lvdData.script.getEventForInd(1);
            evt.termCond = EventDurationTermCondition(100);

            v = EventDurationOptimizationVariable(evt.termCond);
            v.useTf = true;
            v.lb = 10;
            v.ub = 1000;
            lvdData.optimizer.vars.addVariable(v);

            nVars = numel(lvdData.optimizer.vars.vars);
            nX = numel(lvdData.optimizer.vars.getTotalScaledXVector());

            f = [tempname(), '.mat'];
            save(f, 'lvdData');
            clear('lvdData');
            loaded1 = load(f);
            nVars1 = numel(loaded1.lvdData.optimizer.vars.vars);
            nX1 = numel(loaded1.lvdData.optimizer.vars.getTotalScaledXVector());
            clear('loaded1');
            loaded2 = load(f);
            nVars2 = numel(loaded2.lvdData.optimizer.vars.vars);
            nX2 = numel(loaded2.lvdData.optimizer.vars.getTotalScaledXVector());
            delete(f);

            testCase.verifyEqual(nVars1, nVars, ...
                'Loading a case must not delete variables (Bug 2: 62 -> 45 -> 31 shrinkage).');
            testCase.verifyEqual(nVars2, nVars, ...
                'Repeated loads must be stable.');
            testCase.verifyEqual(nX1, nX);
            testCase.verifyEqual(nX2, nX);
        end

        %% Bug 4: style enums are immutable value classes

        function styleEnumsAreValueClasses(testCase)
            testCase.verifyFalse(isa(LineSpecEnum.SolidLine, 'matlab.mixin.SetGet'), ...
                'LineSpecEnum must not be a handle (was a mutable global singleton).');
            testCase.verifyFalse(isa(MarkerStyleEnum.Circle, 'matlab.mixin.SetGet'), ...
                'MarkerStyleEnum must not be a handle.');
        end

        function styleEnumPayloadsAreImmutable(testCase)
            testCase.verifyError(@() mutateLineSpec(), 'MATLAB:class:SetProhibited', ...
                'Enum payloads must be immutable: one write must not restyle every event.');
            testCase.verifyError(@() mutateMarkerShape(), 'MATLAB:class:SetProhibited', ...
                'Enum payloads must be immutable: one write must not restyle every event.');
            testCase.verifyEqual(LineSpecEnum.SolidLine.linespec, '-', ...
                'Failed mutation must leave the member untouched.');
        end

        function eventColorLineSpecCopyIsIndependent(testCase)
            spec = EventColorLineSpec();
            spec.color = [0.2, 0.4, 0.6];

            dup = spec.copy();
            dup.color = [0.9, 0.1, 0.1];
            dup.lineSpec = LineSpecEnum.DashedLine;

            testCase.verifyEqual(spec.color, [0.2, 0.4, 0.6], 'AbsTol', 1e-12, ...
                'Editing a copied style container must not leak into the original event.');
            testCase.verifyEqual(spec.lineSpec, LineSpecEnum.SolidLine, ...
                'Reassigning the copy''s lineSpec must not touch the original.');
        end

        %% Bug 3: safe default

        function incrementalRepropagationDefaultsOff(testCase)
            s = LvdSettings();
            testCase.verifyFalse(s.enableIncrementalRepropagation, ...
                'Production default must be off until the baseline is hash-keyed and audited (Bug 3).');
            testCase.verifyTrue(s.enableSameXPropagationCache, ...
                'The counter-guarded same-x cache stays on.');
        end
    end
end

function mutateLineSpec()
    e = LineSpecEnum.SolidLine;
    e.linespec = '--';
end

function mutateMarkerShape()
    m = MarkerStyleEnum.Circle;
    m.shape = 'x';
end
