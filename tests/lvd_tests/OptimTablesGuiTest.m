classdef OptimTablesGuiTest < KsptotTestCase
    %OptimTablesGuiTest Variable table and constraint status table (E4).
    %
    % Covers LvdOptimTableModel (the UI-free data/edit logic) and the two
    % thin uifigure wrappers lvd_VariableTableGUI_App and
    % lvd_ConstraintTableGUI_App, which are constructed hidden.  Every
    % expected number below is hand computed from values the test itself
    % installs; nothing is propagated.
    %
    % Fixture: stock vehicle plus a second coast event.  Variables:
    %   * Event 2 duration                 (no unit conversion)
    %   * Event 1 pitch termination angle  (stored rad, displayed deg)
    %   * Event 1 delta-v components       (stored km/s, displayed m/s;
    %                                       only X active)
    % Constraints (Throttle carrier, value = 100*throttle):
    %   * FixedBounds [10, 90] with throttle 0.95  -> violation 5
    %   * StateComparison Equals vs Event 2 with
    %     throttles 0.50 / 0.30                    -> violation 20
    %   * FixedBounds [0, 100] satisfied           -> violation 0
    % Status (ok / marginal / violated) is judged on the scaled violation, so
    % a satisfied "Y == X" comparison reads ok however large Y and X are.

    methods(Test)
        function variableRowsListEveryElementInDisplayUnits(testCase)
            fx = testCase.buildFixture();

            [data, meta] = LvdOptimTableModel.getVariableRows(fx.lvdData);
            cols = LvdOptimTableModel.VarColumns;

            testCase.verifyEqual(size(data), [5, numel(cols)], ...
                'One row per variable element: 1 duration + 1 pitch + 3 delta-v components.');
            testCase.verifyEqual(numel(meta), 5);

            rows = testCase.rowsFor(meta, fx.durVar);
            testCase.verifyEqual(numel(rows), 1);
            testCase.verifyEqual(data{rows, testCase.col('Event')}, 'Event 2');
            testCase.verifyEqual(data{rows, testCase.col('Value')}, 100, 'AbsTol', 1e-12);
            testCase.verifyEqual(data{rows, testCase.col('Lower Bound')}, 10);
            testCase.verifyEqual(data{rows, testCase.col('Upper Bound')}, 1000);
            testCase.verifyTrue(data{rows, testCase.col('Active')});
            testCase.verifyEqual(meta(rows).unitType, 'none');

            rows = testCase.rowsFor(meta, fx.pitchVar);
            testCase.verifyEqual(numel(rows), 1);
            testCase.verifyEqual(data{rows, testCase.col('Event')}, 'Event 1');
            testCase.verifyEqual(data{rows, testCase.col('Value')}, rad2deg(0.5), 'AbsTol', 1e-12, ...
                'Radian-stored variables must be displayed in degrees.');
            testCase.verifyEqual(data{rows, testCase.col('Lower Bound')}, -90, 'AbsTol', 1e-12);
            testCase.verifyEqual(data{rows, testCase.col('Upper Bound')}, 90, 'AbsTol', 1e-12);
            testCase.verifyEqual(meta(rows).unitType, 'rad');

            rows = testCase.rowsFor(meta, fx.dvVar);
            testCase.verifyEqual(numel(rows), 3, 'All three delta-v components must be listed even though only X is active.');
            testCase.verifyEqual([meta(rows).elemInd], [1 2 3]);
            testCase.verifyEqual(data{rows(1), testCase.col('Value')}, 100, 'AbsTol', 1e-9, ...
                '0.1 km/s must be displayed as 100 m/s.');
            testCase.verifyEqual(data{rows(1), testCase.col('Upper Bound')}, 500, 'AbsTol', 1e-9);
            testCase.verifyTrue(data{rows(1), testCase.col('Active')});
            testCase.verifyFalse(data{rows(2), testCase.col('Active')});
            testCase.verifyFalse(data{rows(3), testCase.col('Active')});
            testCase.verifyEqual(data{rows(2), testCase.col('Note')}, 'Inactive');
            testCase.verifyTrue(isnan(data{rows(2), testCase.col('Scaled Value')}), ...
                'Inactive elements are not in the x vector and have no scaled value.');
            testCase.verifyTrue(contains(data{rows(1), testCase.col('Variable')}, 'X'));
            testCase.verifyTrue(contains(data{rows(2), testCase.col('Variable')}, 'Y'));
            testCase.verifyEqual(fx.dvVar.getUseTfForVariable(), [true false false], ...
                'Listing inactive elements must leave the variable''s use flags untouched.');

            %Scaled values agree with the variable set's own x vector.
            xS = fx.lvdData.optimizer.vars.getTotalScaledXVector();
            inXRows = find([meta.inX]);
            testCase.verifyEqual(numel(inXRows), numel(xS));
            testCase.verifyEqual(cell2mat(data(inXRows, testCase.col('Scaled Value')))', xS, 'AbsTol', 1e-12);
        end

        function editingBoundsConvertsBackToStoredUnits(testCase)
            fx = testCase.buildFixture();
            [~, meta] = LvdOptimTableModel.getVariableRows(fx.lvdData);

            r = testCase.rowsFor(meta, fx.pitchVar);
            [ok, msg] = LvdOptimTableModel.applyVariableEdit(fx.lvdData, meta(r), 'Lower Bound', -30);
            testCase.verifyTrue(ok, msg);
            testCase.verifyEqual(fx.pitchVar.lb, deg2rad(-30), 'AbsTol', 1e-12, ...
                'A degree entry must be stored in radians.');
            testCase.verifyEqual(fx.pitchVar.ub, deg2rad(90), 'AbsTol', 1e-12, 'The other bound must not move.');

            r = testCase.rowsFor(meta, fx.dvVar);
            [ok, msg] = LvdOptimTableModel.applyVariableEdit(fx.lvdData, meta(r(1)), 'Upper Bound', 250);
            testCase.verifyTrue(ok, msg);
            testCase.verifyEqual(fx.dvVar.ub, [0.25 0.5 0.5], 'AbsTol', 1e-12, ...
                'A m/s entry must be stored in km/s and only touch its own element.');
            testCase.verifyEqual(fx.dvVar.lb, [-0.5 -0.5 -0.5], 'AbsTol', 1e-12);

            [ok, msg] = LvdOptimTableModel.applyVariableEdit(fx.lvdData, meta(r(3)), 'Lower Bound', '-125');
            testCase.verifyTrue(ok, sprintf('Text entries (as uitable delivers them) must be accepted: %s', msg));
            testCase.verifyEqual(fx.dvVar.lb(3), -0.125, 'AbsTol', 1e-12, ...
                'Inactive elements must be editable too.');

            r = testCase.rowsFor(meta, fx.durVar);
            [ok, msg] = LvdOptimTableModel.applyVariableEdit(fx.lvdData, meta(r), 'Lower Bound', 20);
            testCase.verifyTrue(ok, msg);
            testCase.verifyEqual(fx.durVar.lb, 20);
        end

        function invalidBoundEditsAreRejectedWithoutChange(testCase)
            fx = testCase.buildFixture();
            [~, meta] = LvdOptimTableModel.getVariableRows(fx.lvdData);
            r = testCase.rowsFor(meta, fx.durVar);

            [ok, msg] = LvdOptimTableModel.applyVariableEdit(fx.lvdData, meta(r), 'Lower Bound', 5000);
            testCase.verifyFalse(ok, 'A lower bound above the upper bound must be rejected.');
            testCase.verifyNotEmpty(msg);
            testCase.verifyEqual(fx.durVar.lb, 10);

            [ok, ~] = LvdOptimTableModel.applyVariableEdit(fx.lvdData, meta(r), 'Upper Bound', 1);
            testCase.verifyFalse(ok, 'An upper bound below the lower bound must be rejected.');
            testCase.verifyEqual(fx.durVar.ub, 1000);

            [ok, ~] = LvdOptimTableModel.applyVariableEdit(fx.lvdData, meta(r), 'Upper Bound', 'abc');
            testCase.verifyFalse(ok, 'Non-numeric text must be rejected.');
            testCase.verifyEqual(fx.durVar.ub, 1000);

            [ok, ~] = LvdOptimTableModel.applyVariableEdit(fx.lvdData, meta(r), 'Value', 55);
            testCase.verifyFalse(ok, 'Value is not an editable column.');
        end

        function togglingActiveChangesTheXVector(testCase)
            fx = testCase.buildFixture();
            [~, meta] = LvdOptimTableModel.getVariableRows(fx.lvdData);

            x0 = fx.lvdData.optimizer.vars.getTotalScaledXVector();
            testCase.assertEqual(numel(x0), 3, 'Fixture: duration + pitch + delta-v X.');

            r = testCase.rowsFor(meta, fx.dvVar);
            [ok, msg] = LvdOptimTableModel.applyVariableEdit(fx.lvdData, meta(r(2)), 'Active', true);
            testCase.verifyTrue(ok, msg);
            testCase.verifyEqual(fx.dvVar.getUseTfForVariable(), [true true false]);

            x1 = fx.lvdData.optimizer.vars.getTotalScaledXVector();
            testCase.verifyEqual(numel(x1), 4, 'Activating an element must add it to the x vector.');

            [data, meta] = LvdOptimTableModel.getVariableRows(fx.lvdData);
            r = testCase.rowsFor(meta, fx.dvVar);
            testCase.verifyTrue(data{r(2), testCase.col('Active')});
            testCase.verifyTrue(meta(r(2)).inX);
            testCase.verifyFalse(isnan(data{r(2), testCase.col('Scaled Value')}));

            r = testCase.rowsFor(meta, fx.durVar);
            [ok, ~] = LvdOptimTableModel.applyVariableEdit(fx.lvdData, meta(r), 'Active', 'false');
            testCase.verifyTrue(ok);
            testCase.verifyFalse(fx.durVar.useTf);
            x2 = fx.lvdData.optimizer.vars.getTotalScaledXVector();
            testCase.verifyEqual(numel(x2), 3);
        end

        function onBoundAndDisabledEventRowsAreFlagged(testCase)
            fx = testCase.buildFixture();

            fx.evt2.termCond.duration = 1000;   %sits on the upper bound
            [data, meta] = LvdOptimTableModel.getVariableRows(fx.lvdData);
            r = testCase.rowsFor(meta, fx.durVar);
            testCase.verifyTrue(meta(r).onBound);
            testCase.verifyEqual(data{r, testCase.col('Scaled Value')}, 1, 'AbsTol', 1e-12);
            testCase.verifyEqual(data{r, testCase.col('Note')}, 'On bound');

            fx.evt2.termCond.duration = 100;
            [~, meta] = LvdOptimTableModel.getVariableRows(fx.lvdData);
            r = testCase.rowsFor(meta, fx.durVar);
            testCase.verifyFalse(meta(r).onBound);

            fx.evt1.toggleOptimDisable(fx.lvdData);
            [data, meta] = LvdOptimTableModel.getVariableRows(fx.lvdData);
            r = testCase.rowsFor(meta, fx.pitchVar);
            testCase.verifyFalse(meta(r).inX, 'A variable whose event has optimization disabled is not in x.');
            testCase.verifyEqual(data{r, testCase.col('Note')}, 'Event optimization disabled');
            testCase.verifyTrue(data{r, testCase.col('Active')}, 'The use flag itself is unchanged.');
            r = testCase.rowsFor(meta, fx.durVar);
            testCase.verifyTrue(meta(r).inX, 'Event 2 is unaffected.');
        end

        function constraintRowsReportHandComputedViolations(testCase)
            fx = testCase.buildFixture();
            fx = testCase.addConstraintsAndEvaluate(fx);

            [data, meta] = LvdOptimTableModel.getConstraintRows(fx.lvdData);
            cols = LvdOptimTableModel.ConstrColumns;
            testCase.verifyEqual(size(data), [3, numel(cols)]);

            %FixedBounds [10, 90], value 95 -> violation 5, scaled violation 5/normFact(=1)
            r = testCase.constRow(meta, fx.constFixed);
            testCase.verifyEqual(data{r, testCase.ccol('Value')}, 95, 'AbsTol', 1e-9);
            testCase.verifyEqual(data{r, testCase.ccol('Lower Bound')}, 10);
            testCase.verifyEqual(data{r, testCase.ccol('Upper Bound')}, 90);
            testCase.verifyEqual(data{r, testCase.ccol('Violation')}, 5, 'AbsTol', 1e-9);
            testCase.verifyEqual(data{r, testCase.ccol('Scaled Violation')}, 5, 'AbsTol', 1e-9);
            testCase.verifyEqual(data{r, testCase.ccol('Event')}, 1);
            testCase.verifyEqual(data{r, testCase.ccol('Type')}, 'Throttle');
            testCase.verifyEqual(meta(r).status, 'violated');
            testCase.verifyEqual(data{r, testCase.ccol('Note')}, 'Violated');

            %StateComparison Equals: 50 vs 30 -> violation 20; Type names the comparison event
            r = testCase.constRow(meta, fx.constComp);
            testCase.verifyEqual(data{r, testCase.ccol('Value')}, 50, 'AbsTol', 1e-9);
            testCase.verifyEqual(data{r, testCase.ccol('Lower Bound')}, 30, 'AbsTol', 1e-9, ...
                'For a state comparison the bound columns show the comparison value.');
            testCase.verifyEqual(data{r, testCase.ccol('Violation')}, 20, 'AbsTol', 1e-9);
            testCase.verifyEqual(data{r, testCase.ccol('Scaled Violation')}, 20, 'AbsTol', 1e-9);
            testCase.verifyEqual(data{r, testCase.ccol('Type')}, 'Throttle (== Event 2)');
            testCase.verifyEqual(meta(r).status, 'violated');

            %Satisfied FixedBounds [0, 100], value 95 -> 0
            r = testCase.constRow(meta, fx.constOk);
            testCase.verifyEqual(data{r, testCase.ccol('Violation')}, 0);
            testCase.verifyEqual(data{r, testCase.ccol('Scaled Violation')}, 0);
            testCase.verifyEqual(meta(r).status, 'ok');
            testCase.verifyEqual(data{r, testCase.ccol('Note')}, '');

            %Scale factor column reflects setScaleFactor
            fx.constFixed.setScaleFactor(2.5);
            fx = testCase.addConstraintsAndEvaluate(fx, false);
            [data, meta] = LvdOptimTableModel.getConstraintRows(fx.lvdData);
            r = testCase.constRow(meta, fx.constFixed);
            testCase.verifyEqual(data{r, testCase.ccol('Scale Factor')}, 2.5);
            testCase.verifyEqual(data{r, testCase.ccol('Scaled Violation')}, 5/2.5, 'AbsTol', 1e-9, ...
                'Scaled violation is the raw c value, which carries the scale factor.');
            testCase.verifyEqual(data{r, testCase.ccol('Violation')}, 5, 'AbsTol', 1e-9, ...
                'The unscaled violation ignores the scale factor.');
        end

        function violationMathCoversAllComparisonTypes(testCase)
            fx = testCase.buildFixture();
            const = ThrottleConstraint(fx.evt1, 0, 0);
            const.evalType = ConstraintEvalTypeEnum.StateComparison;
            const.stateCompEvent = fx.evt2;

            const.stateCompType = ConstraintStateComparisonTypeEnum.Equals;
            testCase.verifyEqual(LvdOptimTableModel.computeViolation(const, 7, 10, 0, 0, true), 3);
            testCase.verifyEqual(LvdOptimTableModel.computeViolation(const, 13, 10, 0, 0, true), 3);

            const.stateCompType = ConstraintStateComparisonTypeEnum.GreaterThan;  %value >= comp
            testCase.verifyEqual(LvdOptimTableModel.computeViolation(const, 7, 10, 0, 0, true), 3);
            testCase.verifyEqual(LvdOptimTableModel.computeViolation(const, 13, 10, 0, 0, true), 0);

            const.stateCompType = ConstraintStateComparisonTypeEnum.LessThan;     %value <= comp
            testCase.verifyEqual(LvdOptimTableModel.computeViolation(const, 7, 10, 0, 0, true), 0);
            testCase.verifyEqual(LvdOptimTableModel.computeViolation(const, 13, 10, 0, 0, true), 3);

            %Fixed bounds: below, inside, above, NaN
            testCase.verifyEqual(LvdOptimTableModel.computeViolation(const, 2, NaN, 5, 8, false), 3);
            testCase.verifyEqual(LvdOptimTableModel.computeViolation(const, 6, NaN, 5, 8, false), 0);
            testCase.verifyEqual(LvdOptimTableModel.computeViolation(const, 9.5, NaN, 5, 8, false), 1.5);
            testCase.verifyTrue(isnan(LvdOptimTableModel.computeViolation(const, NaN, NaN, 5, 8, false)));

            %Classification is by the SCALED violation: <= 1e-6 ok (the
            %optimizer's own tolerance), < 1e-3 marginal, else violated.  The
            %size of the constraint value plays no part.
            [s, rel] = LvdOptimTableModel.classifyViolation(0, 0, 100);
            testCase.verifyEqual(s, 'ok'); testCase.verifyEqual(rel, 0);
            [s, ~] = LvdOptimTableModel.classifyViolation(1e-9, 1e-9, 7000);
            testCase.verifyEqual(s, 'ok', 'An equality constraint is never exactly zero in floating point; within tolerance is satisfied.');
            [s, rel] = LvdOptimTableModel.classifyViolation(0.05, 0.05, 1000);
            testCase.verifyEqual(s, 'violated', 'A 0.05 violation is a violation however large the value it sits on.');
            testCase.verifyEqual(rel, 5e-5, 'AbsTol', 1e-15, 'The relative violation is still reported for information.');
            [s, ~] = LvdOptimTableModel.classifyViolation(5, 5, 95);
            testCase.verifyEqual(s, 'violated');
            [s, ~] = LvdOptimTableModel.classifyViolation(0.0005, 0.0005, 0.1);
            testCase.verifyEqual(s, 'marginal');
            [s, ~] = LvdOptimTableModel.classifyViolation(2, 2e-4, 100);
            testCase.verifyEqual(s, 'marginal', 'The scale factor decides: 2 units under a 1e4 scale factor is marginal.');
            [s, ~] = LvdOptimTableModel.classifyViolation(0.5, NaN, 10);
            testCase.verifyEqual(s, 'violated', 'Without a scaled value the unscaled violation stands in.');
            [s, rel] = LvdOptimTableModel.classifyViolation(NaN, NaN, 5);
            testCase.verifyEqual(s, 'unknown'); testCase.verifyTrue(isnan(rel));
        end

        function satisfiedStateComparisonReadsOkWhateverTheMagnitude(testCase)
            %Y == X between two events: when both throttles are 50 the
            %difference is 0, so the row is satisfied even though the values
            %themselves are far from 0.
            fx = testCase.buildFixture();
            fx = testCase.addConstraintsAndEvaluate(fx, true, [0.50, 0.95, 0.50]);

            [data, meta] = LvdOptimTableModel.getConstraintRows(fx.lvdData);
            r = testCase.constRow(meta, fx.constComp);
            testCase.verifyEqual(data{r, testCase.ccol('Value')}, 50, 'AbsTol', 1e-9);
            testCase.verifyEqual(data{r, testCase.ccol('Lower Bound')}, 50, 'AbsTol', 1e-9);
            testCase.verifyEqual(data{r, testCase.ccol('Upper Bound')}, 50, 'AbsTol', 1e-9);
            testCase.verifyEqual(data{r, testCase.ccol('Violation')}, 0, 'AbsTol', 1e-9);
            testCase.verifyEqual(data{r, testCase.ccol('Scaled Violation')}, 0, 'AbsTol', 1e-9);
            testCase.verifyEqual(meta(r).status, 'ok', 'Y == X is satisfied regardless of Y.');
            testCase.verifyEqual(data{r, testCase.ccol('Note')}, '');

            %A converged optimizer leaves a residual of the order of its
            %tolerance, never exactly zero; that must still read as satisfied.
            fx = testCase.addConstraintsAndEvaluate(fx, false, [0.50, 0.95, 0.50 + 1e-11]);
            [data, meta] = LvdOptimTableModel.getConstraintRows(fx.lvdData);
            r = testCase.constRow(meta, fx.constComp);
            testCase.verifyEqual(data{r, testCase.ccol('Violation')}, 1e-9, 'RelTol', 1e-3);
            testCase.verifyEqual(meta(r).status, 'ok', 'A residual within the optimizer tolerance is satisfied, not marginal.');

            %A real mismatch on the same large values is a violation.
            fx = testCase.addConstraintsAndEvaluate(fx, false, [0.50, 0.95, 0.49]);
            [~, meta] = LvdOptimTableModel.getConstraintRows(fx.lvdData);
            r = testCase.constRow(meta, fx.constComp);
            testCase.verifyEqual(meta(r).violation, 1, 'AbsTol', 1e-9);
            testCase.verifyEqual(meta(r).status, 'violated', 'A 1-unit mismatch is not marginal just because the values are 50.');
        end

        function comparisonBoundsShowTheDirectionOfTheInequality(testCase)
            fx = testCase.buildFixture();
            fx = testCase.addConstraintsAndEvaluate(fx);

            %value >= comparison: the comparison value is a lower bound only
            fx.constComp.stateCompType = ConstraintStateComparisonTypeEnum.GreaterThan;
            fx = testCase.addConstraintsAndEvaluate(fx, false);
            [data, meta] = LvdOptimTableModel.getConstraintRows(fx.lvdData);
            r = testCase.constRow(meta, fx.constComp);
            testCase.verifyEqual(data{r, testCase.ccol('Type')}, 'Throttle (>= Event 2)');
            testCase.verifyEqual(data{r, testCase.ccol('Lower Bound')}, 30, 'AbsTol', 1e-9);
            testCase.verifyEqual(data{r, testCase.ccol('Upper Bound')}, Inf);
            testCase.verifyEqual(data{r, testCase.ccol('Violation')}, 0);
            testCase.verifyEqual(meta(r).status, 'ok', '50 >= 30 is satisfied.');

            %value <= comparison: an upper bound only, and 50 <= 30 is violated by 20
            fx.constComp.stateCompType = ConstraintStateComparisonTypeEnum.LessThan;
            fx = testCase.addConstraintsAndEvaluate(fx, false);
            [data, meta] = LvdOptimTableModel.getConstraintRows(fx.lvdData);
            r = testCase.constRow(meta, fx.constComp);
            testCase.verifyEqual(data{r, testCase.ccol('Type')}, 'Throttle (<= Event 2)');
            testCase.verifyEqual(data{r, testCase.ccol('Lower Bound')}, -Inf);
            testCase.verifyEqual(data{r, testCase.ccol('Upper Bound')}, 30, 'AbsTol', 1e-9);
            testCase.verifyEqual(data{r, testCase.ccol('Violation')}, 20, 'AbsTol', 1e-9);
            testCase.verifyEqual(meta(r).status, 'violated');
        end

        function aConstraintWhoseEventNeverRanKeepsTheOtherRowsAligned(testCase)
            %A constraint on an event with no state log entries (the script
            %stopped early) used to contribute nothing to the per-constraint
            %value arrays, shifting every later constraint's values onto the
            %wrong row of the table.
            fx = testCase.buildFixture();
            constNeverRan = ThrottleConstraint(fx.evt3, 0, 100);
            fx.lvdData.optimizer.constraints.addConstraint(constNeverRan);
            fx = testCase.addConstraintsAndEvaluate(fx);   %adds the three carriers after it
            fx.constFixed = fx.lvdData.optimizer.constraints.consts(2);
            fx.constComp = fx.lvdData.optimizer.constraints.consts(3);
            fx.constOk = fx.lvdData.optimizer.constraints.consts(4);

            lastRun = fx.lvdData.optimizer.constraints.lastRunValues;
            testCase.verifyEqual(numel(lastRun.value), numel(lastRun.consts), 'One value per evaluated constraint.');
            testCase.verifyEqual(numel(lastRun.valueStateComps), numel(lastRun.consts));
            testCase.verifyEqual(numel(lastRun.lb), numel(lastRun.consts));

            [data, meta] = LvdOptimTableModel.getConstraintRows(fx.lvdData);
            testCase.verifyEqual(size(data,1), 4);

            r = testCase.constRow(meta, constNeverRan);
            testCase.verifyTrue(isnan(data{r, testCase.ccol('Value')}));
            testCase.verifyEqual(meta(r).status, 'unknown');
            testCase.verifyEqual(data{r, testCase.ccol('Note')}, 'Not evaluated');

            r = testCase.constRow(meta, fx.constFixed);
            testCase.verifyEqual(data{r, testCase.ccol('Value')}, 95, 'AbsTol', 1e-9, 'The later rows must carry their own values.');
            testCase.verifyEqual(data{r, testCase.ccol('Violation')}, 5, 'AbsTol', 1e-9);
            r = testCase.constRow(meta, fx.constComp);
            testCase.verifyEqual(data{r, testCase.ccol('Value')}, 50, 'AbsTol', 1e-9);
            testCase.verifyEqual(data{r, testCase.ccol('Lower Bound')}, 30, 'AbsTol', 1e-9);
            r = testCase.constRow(meta, fx.constOk);
            testCase.verifyEqual(data{r, testCase.ccol('Violation')}, 0);

            %The validator indexes the same arrays and must not error.
            [errs, ~] = ConstraintValidator(fx.lvdData).validate();
            testCase.verifyEmpty(errs);
        end

        function unevaluatedAndInactiveConstraintsAreReported(testCase)
            fx = testCase.buildFixture();
            constA = ThrottleConstraint(fx.evt1, 10, 90);
            fx.lvdData.optimizer.constraints.addConstraint(constA);

            [data, meta] = LvdOptimTableModel.getConstraintRows(fx.lvdData);
            testCase.verifyEqual(size(data,1), 1);
            testCase.verifyTrue(isnan(data{1, testCase.ccol('Value')}));
            testCase.verifyTrue(isnan(data{1, testCase.ccol('Violation')}));
            testCase.verifyEqual(meta(1).status, 'unknown');
            testCase.verifyEqual(data{1, testCase.ccol('Note')}, 'Not evaluated');

            [ok, msg] = LvdOptimTableModel.applyConstraintEdit(fx.lvdData, meta(1), 'Active', false);
            testCase.verifyTrue(ok, msg);
            testCase.verifyFalse(constA.active);
            [data, ~] = LvdOptimTableModel.getConstraintRows(fx.lvdData);
            testCase.verifyFalse(data{1, testCase.ccol('Active')});
            testCase.verifyEqual(data{1, testCase.ccol('Note')}, 'Inactive');

            [ok, ~] = LvdOptimTableModel.applyConstraintEdit(fx.lvdData, meta(1), 'Value', 3);
            testCase.verifyFalse(ok, 'Only Active is editable on the constraint table.');

            %Evaluate Now needs a propagated state log
            [ok, msg] = LvdOptimTableModel.evaluateConstraintsNow(fx.lvdData);
            testCase.verifyFalse(ok);
            testCase.verifyTrue(contains(msg, 'not been propagated'));
        end

        function highlightedCellsPinTheirFontColour(testCase)
            %Both tables paint light highlight backgrounds; under a dark theme
            %the default (light) font disappears on them, so every highlight
            %style must carry its own font colour.  Inactive rows are greyed
            %by a row style that must not override the highlight's font.
            fx = testCase.buildFixture();
            fx = testCase.addConstraintsAndEvaluate(fx);
            fx.constFixed.active = false;      %a highlighted cell on a greyed row
            fx.evt2.termCond.duration = 1000;  %an on-bound variable row

            constApp = lvd_ConstraintTableGUI_App(fx.lvdData, false);
            cleanupC = onCleanup(@() delete(constApp)); %#ok<NASGU>
            varApp = lvd_VariableTableGUI_App(fx.lvdData, false);
            cleanupV = onCleanup(@() delete(varApp)); %#ok<NASGU>

            for(tbl = [constApp.ConstrTable, varApp.VarTable])
                cfg = tbl.StyleConfigurations;
                styles = cfg.Style;
                hasBg = arrayfun(@(s) not(isempty(s.BackgroundColor)), styles);
                testCase.assertTrue(any(hasBg), 'Fixture: the table must have highlighted cells.');
                testCase.verifyTrue(all(arrayfun(@(s) not(isempty(s.FontColor)), styles(hasBg))), ...
                    'Every highlight background must pin its font colour.');
                for(s = styles(hasBg)')
                    testCase.verifyLessThan(max(s.FontColor), 0.5, 'Highlight text must be dark on the light background.');
                end
            end

            %The greyed inactive row is applied before the cell highlights, so
            %the highlight (later, on top) wins on those cells.
            cfg = constApp.ConstrTable.StyleConfigurations;
            targets = string(cfg.Target);   %categorical in the configuration table
            rowStyleIdx = find(targets == "row", 1);
            cellStyleIdx = find(targets == "cell", 1);
            testCase.assertNotEmpty(rowStyleIdx); testCase.assertNotEmpty(cellStyleIdx);
            testCase.verifyLessThan(rowStyleIdx, cellStyleIdx, 'Row greying must be added before the cell highlights.');
        end

        function variableTableAppReflectsModelAndEdits(testCase)
            fx = testCase.buildFixture();

            app = lvd_VariableTableGUI_App(fx.lvdData, false);
            cleanup = onCleanup(@() delete(app));

            testCase.verifyEqual(app.UIFigure.Visible, matlab.lang.OnOffSwitchState.off);
            testCase.verifyEqual(app.UIFigure.Name, 'LVD Optimization Variables');

            [modelData, meta] = LvdOptimTableModel.getVariableRows(fx.lvdData);
            testCase.verifyEqual(app.getTableData(), modelData, 'The table shows exactly the model rows.');

            %Edit a bound through the cell-edit path (fake event indices)
            r = testCase.rowsFor(meta, fx.pitchVar);
            [ok, msg] = app.applyCellEdit(r, testCase.col('Upper Bound'), 45, 90);
            testCase.verifyTrue(ok, msg);
            testCase.verifyEqual(fx.pitchVar.ub, deg2rad(45), 'AbsTol', 1e-12);
            data = app.getTableData();
            testCase.verifyEqual(data{r, testCase.col('Upper Bound')}, 45, 'AbsTol', 1e-12, 'The table refreshes after an edit.');

            %Toggle Active
            r = testCase.rowsFor(meta, fx.dvVar);
            [ok, ~] = app.applyCellEdit(r(3), testCase.col('Active'), true, false);
            testCase.verifyTrue(ok);
            testCase.verifyEqual(fx.dvVar.getUseTfForVariable(), [true false true]);

            %Invalid edit restores the previous cell value
            r = testCase.rowsFor(meta, fx.durVar);
            [ok, ~] = app.applyCellEdit(r, testCase.col('Lower Bound'), 99999, 10);
            testCase.verifyFalse(ok);
            data = app.getTableData();
            testCase.verifyEqual(data{r, testCase.col('Lower Bound')}, 10);

            %Adding a variable fires the set's event and the table grows
            numRows0 = size(app.getTableData(), 1);
            newVar = EventDurationOptimizationVariable(fx.evt3.termCond);
            newVar.useTf = true; newVar.lb = 1; newVar.ub = 50;
            fx.lvdData.optimizer.vars.addVariable(newVar);
            testCase.verifyEqual(size(app.getTableData(), 1), numRows0 + 1, ...
                'VarsListUpdatedAddedVar must refresh the table.');
            fx.lvdData.optimizer.vars.removeVariable(newVar);
            testCase.verifyEqual(size(app.getTableData(), 1), numRows0, ...
                'VarsListUpdatedRemovedVar must refresh the table.');

            %Clipboard text: header line is tab separated column names
            txt = app.copyToClipboard();
            lines = strsplit(txt, newline);
            testCase.verifyEqual(lines{1}, strjoin(LvdOptimTableModel.VarColumns, sprintf('\t')));
            testCase.verifyEqual(numel(lines), numRows0 + 1);
            testCase.verifyEqual(numel(strsplit(lines{2}, sprintf('\t'))), numel(LvdOptimTableModel.VarColumns));

            %Deleting the app removes its listeners: later notifications are harmless
            delete(app);
            testCase.verifyFalse(isvalid(app));
            notify(fx.lvdData.optimizer.vars, 'VarsListUpdatedAddedVar');
            notify(fx.lvdData.script, 'ScriptPropagationFinished');
            testCase.verifyTrue(true, 'Notifications after delete must not error.');
        end

        function constraintTableAppReflectsModelAndEdits(testCase)
            fx = testCase.buildFixture();
            fx = testCase.addConstraintsAndEvaluate(fx);

            app = lvd_ConstraintTableGUI_App(fx.lvdData, false);
            cleanup = onCleanup(@() delete(app));

            testCase.verifyEqual(app.UIFigure.Name, 'LVD Constraint Status');

            [modelData, meta] = LvdOptimTableModel.getConstraintRows(fx.lvdData);
            testCase.verifyEqual(app.getTableData(), modelData);
            testCase.verifyEqual({app.getRowMeta().status}, {meta.status});

            r = testCase.constRow(meta, fx.constFixed);
            [ok, msg] = app.applyCellEdit(r, testCase.ccol('Active'), false, true);
            testCase.verifyTrue(ok, msg);
            testCase.verifyFalse(fx.constFixed.active);
            data = app.getTableData();
            testCase.verifyFalse(data{r, testCase.ccol('Active')});

            [ok, ~] = app.applyCellEdit(r, testCase.ccol('Value'), 1, 95);
            testCase.verifyFalse(ok);

            txt = app.copyToClipboard();
            lines = strsplit(txt, newline);
            testCase.verifyEqual(lines{1}, strjoin(LvdOptimTableModel.ConstrColumns, sprintf('\t')));
            testCase.verifyEqual(numel(lines), 4);

            %Evaluate Now without a propagated mission state log reports, does not throw
            [ok, msg] = app.evaluateNow();
            testCase.verifyFalse(ok);
            testCase.verifyNotEmpty(msg);

            %Propagation-finished notification refreshes (no error, data still consistent)
            notify(fx.lvdData.script, 'ScriptPropagationFinished');
            testCase.verifyEqual(size(app.getTableData(), 1), 3);

            delete(app);
            testCase.verifyFalse(isvalid(app));
            notify(fx.lvdData.script, 'ScriptPropagationFinished');
        end
    end

    methods(Access=private)
        function fx = buildFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            template = lvdData.initStateModel.getInitialStateLogEntry();

            evt1 = lvdData.script.getEventForInd(1);
            evt1.termCond = PitchTermCondition(0.5);

            evt2 = LaunchVehicleEvent(lvdData.script);
            evt2.termCond = EventDurationTermCondition(100);
            evt2.propagatorObj = evt2.twoBodyPropagator;
            lvdData.script.addEvent(evt2);

            %A third event with no variables of its own; tests that need to
            %add a variable at runtime hang it off this event's condition.
            evt3 = LaunchVehicleEvent(lvdData.script);
            evt3.termCond = EventDurationTermCondition(50);
            evt3.propagatorObj = evt3.twoBodyPropagator;
            lvdData.script.addEvent(evt3);

            dvAction = AddDeltaVAction([0.1; 0.02; 0], DeltaVFrameEnum.Inertial, false);
            dvAction.event = evt1;
            evt1.addAction(dvAction);

            %Create every variable BEFORE registering any of them: adding a
            %variable sorts the set by event number, which memoizes each
            %event's active-variable list, and a variable created after that
            %memo would be invisible to getEventNumberForVar.
            pitchVar = PitchAngleTermCondOptimVar(evt1.termCond);
            pitchVar.useTf = true;
            pitchVar.lb = deg2rad(-90);
            pitchVar.ub = deg2rad(90);

            durVar = EventDurationOptimizationVariable(evt2.termCond);
            durVar.useTf = true;
            durVar.lb = 10;
            durVar.ub = 1000;

            dvVar = AddDeltaVActionVariable(dvAction);
            dvVar.setUseTfForVariable([true false false]);
            dvVar.setBndsForVariable([-0.5 -0.5 -0.5], [0.5 0.5 0.5]);

            lvdData.optimizer.vars.addVariable(pitchVar);
            lvdData.optimizer.vars.addVariable(durVar);
            lvdData.optimizer.vars.addVariable(dvVar);

            fx = struct('lvdData', lvdData, 'template', template, 'evt1', evt1, 'evt2', evt2, 'evt3', evt3, ...
                        'pitchVar', pitchVar, 'durVar', durVar, 'dvVar', dvVar, ...
                        'constFixed', [], 'constComp', [], 'constOk', []);
        end

        function fx = addConstraintsAndEvaluate(testCase, fx, addConsts, throttles)
            %addConstraintsAndEvaluate Installs the three carrier constraints
            %(unless addConsts is false) and evaluates them against a
            %synthesized state log whose throttles are [event 1 first entry,
            %event 1 last entry, event 2] (default 0.50 / 0.95 / 0.30).
            if(nargin < 3)
                addConsts = true;
            end
            if(nargin < 4)
                throttles = [0.50, 0.95, 0.30];
            end

            cSet = fx.lvdData.optimizer.constraints;

            if(addConsts)
                fx.constFixed = ThrottleConstraint(fx.evt1, 10, 90);

                fx.constComp = ThrottleConstraint(fx.evt1, 0, 0);
                fx.constComp.evalType = ConstraintEvalTypeEnum.StateComparison;
                fx.constComp.stateCompEvent = fx.evt2;
                fx.constComp.stateCompType = ConstraintStateComparisonTypeEnum.Equals;

                fx.constOk = ThrottleConstraint(fx.evt1, 0, 100);

                cSet.addConstraint(fx.constFixed);
                cSet.addConstraint(fx.constComp);
                cSet.addConstraint(fx.constOk);
            elseif(isempty(fx.constFixed))
                fx.constFixed = cSet.consts(1);
                fx.constComp = cSet.consts(2);
                fx.constOk = cSet.consts(3);
            end

            e1 = fx.template.deepCopy();  e1.event = fx.evt1;  e1.time = 0;
            e2 = fx.template.deepCopy();  e2.event = fx.evt2;  e2.time = 10;

            %The FixedBounds constraints read event 1 (throttle 0.95 -> 95)
            %while the state comparison reads event 1 vs event 2.  A single
            %event-1 entry can only carry one throttle, so the comparison
            %constraint is given its own event-1 entry via eventNode:
            %InitialState (first entry, throttle 0.50) and the fixed-bounds
            %constraints read the FinalState (last entry, throttle 0.95).
            e1b = fx.template.deepCopy(); e1b.event = fx.evt1; e1b.time = 5;
            testCase.setThrottle(e1, throttles(1));
            testCase.setThrottle(e1b, throttles(2));
            testCase.setThrottle(e2, throttles(3));
            fx.constComp.eventNode = ConstraintStateComparisonNodeEnum.InitialState;

            stateLog = LaunchVehicleStateLog(fx.lvdData);
            stateLog.appendStateLogEntries([e1, e1b, e2]);

            cSet.evalConstraints([], false, [], false, stateLog);
        end

        function setThrottle(testCase, entry, frac)
            model = ThrottlePolyModel.getDefaultThrottleModel();
            model.throttleModel.constTerm = frac;
            entry.throttleModel = model;
            testCase.assertEqual(entry.throttle, frac, 'AbsTol', 1e-12);
        end

        function rows = rowsFor(~, meta, var)
            rows = find(arrayfun(@(m) isequal(class(m.var), class(var)) && m.var == var, meta));
        end

        function r = constRow(~, meta, const)
            r = find(arrayfun(@(m) m.const == const, meta), 1, 'first');
        end

        function c = col(~, name)
            c = find(strcmp(LvdOptimTableModel.VarColumns, name), 1, 'first');
        end

        function c = ccol(~, name)
            c = find(strcmp(LvdOptimTableModel.ConstrColumns, name), 1, 'first');
        end
    end
end
