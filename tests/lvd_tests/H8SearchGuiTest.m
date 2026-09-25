classdef H8SearchGuiTest < matlab.uitest.TestCase
    properties(Access=private)
        celBodyData
        kerbinFrame
        stubMainFig
        figuresBefore
        fixture UiwaitInterceptorFixture
    end

    methods(TestClassSetup)
        function setUpEnvironment(testCase)
            testCase.celBodyData = ksptotTestBodyData();
            testCase.kerbinFrame = testCase.celBodyData.kerbin.getBodyCenteredInertialFrame();
            global GLOBAL_AppThemer %#ok<GVMIS>
            if(isempty(GLOBAL_AppThemer) || not(isvalid(GLOBAL_AppThemer)))
                GLOBAL_AppThemer = AppThemer();
            end
            global ksptot_TimeSystem options_UseEarthTimeSystem %#ok<GVMIS>
            if(isempty(ksptot_TimeSystem))
                [rawIni, ~, ~] = inifile(fullfile(ksptotTestRoot(), 'bodies.ini'), 'readall');
                ksptot_TimeSystem = getTimeSystemFromConfig(getAppOptionsFromFile(), rawIni);
                options_UseEarthTimeSystem = strcmpi(ksptot_TimeSystem.system, 'earth_stock');
            end
        end
    end

    methods(TestMethodSetup)
        function interceptUiwait(testCase)
            testCase.fixture = testCase.applyFixture(UiwaitInterceptorFixture());
            testCase.figuresBefore = findall(groot, 'Type', 'figure');
            testCase.addTeardown(@() testCase.closeNewFigures());
        end
    end

    methods(Test)
        function eventTagsRoundTripThroughEditor(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt = lvdData.script.getEventForInd(1);
            evt.tags = 'upper stage';
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(@() lvd_editEventGUI_App(evt, false, out));

            testCase.verifyEqual(app.eventTagsText.Value, 'upper stage');
            app.eventTagsText.Value = 'coast check';
            testCase.press(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyEqual(evt.tags, 'coast check');
        end

        function constraintSearchAndTagsFilterWithoutEnter(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt = lvdData.script.getEventForInd(1);
            first = ThrottleConstraint(evt, 10, 90);
            first.tags = 'ascent limit';
            second = ThrottleConstraint(evt, 0, 100);
            lvdData.optimizer.constraints.addConstraint(first);
            lvdData.optimizer.constraints.addConstraint(second);
            app = testCase.openDialog(@() lvd_EditConstraintsGUI_App(lvdData));

            testCase.verifyTrue(isa(app.constraintSearchText, 'matlab.ui.control.EditField'));
            testCase.verifyTrue(isa(app.constraintTagsText, 'matlab.ui.control.EditField'));
            app.constraintsListBox.Value = first;
            app.constraintsListBox.ValueChangedFcn(app.constraintsListBox, struct('Source', app.constraintsListBox, 'EventName', 'ValueChanged'));
            testCase.verifyEqual(app.constraintTagsText.Value, 'ascent limit');

            app.constraintTagsText.Value = 'coast check';
            app.constraintTagsText.ValueChangedFcn(app.constraintTagsText, struct('Source', app.constraintTagsText, 'EventName', 'ValueChanged', 'Value', 'coast check'));
            testCase.verifyEqual(first.tags, 'coast check');
            testCase.fireSearch(app.constraintSearchText, 'coast');
            testCase.verifyEqual(numel(app.constraintsListBox.Items), 1);
            testCase.verifyTrue(app.constraintsListBox.ItemsData(1) == first);
            testCase.verifyTrue(any(contains(app.ConstraintInfoTextArea.Value, 'Throttle')));

            testCase.verifyWarningFree(@() testCase.fireSearch(app.constraintSearchText, 'zzz'));
            testCase.verifyEmpty(app.constraintsListBox.Items);
            testCase.verifyEmpty(app.constraintsListBox.Value);
            testCase.verifyEqual(app.removeConstraintButton.Enable, matlab.lang.OnOffSwitchState.off);
            testCase.verifyEqual(app.applyConstraintTagsButton.Enable, matlab.lang.OnOffSwitchState.off);
        end

        function variableSearchPreservesTheXIndex(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt = lvdData.script.getEventForInd(1);
            evt.termCond = EventDurationTermCondition(100);
            durVar = EventDurationOptimizationVariable(evt.termCond);
            durVar.useTf = true;
            durVar.lb = 10;
            durVar.ub = 1000;
            lvdData.optimizer.vars.addVariable(durVar);
            pitchCond = PitchTermCondition(0.5);
            evt.addTermCond(pitchCond);
            pitchVar = PitchAngleTermCondOptimVar(pitchCond);
            pitchVar.useTf = true;
            pitchVar.lb = deg2rad(-90);
            pitchVar.ub = deg2rad(90);
            lvdData.optimizer.vars.addVariable(pitchVar);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(@() lvd_adjustOptVarGUI_App(lvdData, @()[], @()[], out));

            [~, ~, names] = lvdData.optimizer.vars.getTotalScaledXVector();
            pitchInd = find(contains(names, 'Pitch'), 1, 'first');
            testCase.assertFalse(isempty(pitchInd), 'Fixture must contain a pitch variable.');
            testCase.fireSearch(app.variableSearchText, 'pitch');
            testCase.verifyEqual(app.variablesCombo.ItemsData, pitchInd);
            testCase.verifyEqual(app.variablesCombo.Value, pitchInd);
            testCase.verifyEqual(str2double(app.varValueText.Value), rad2deg(0.5), 'AbsTol', 1e-9);

            testCase.verifyWarningFree(@() testCase.fireSearch(app.variableSearchText, 'zzz'));
            testCase.verifyEmpty(app.variablesCombo.Items);
            testCase.verifyEqual(app.variablesCombo.Enable, matlab.lang.OnOffSwitchState.off);
            testCase.verifyEqual(app.varValueText.Enable, matlab.lang.OnOffSwitchState.off);
            testCase.verifyEqual(app.saveAndCloseButton.Enable, matlab.lang.OnOffSwitchState.off);

            testCase.fireSearch(app.variableSearchText, 'pitch');
            testCase.verifyEqual(app.variablesCombo.ItemsData, pitchInd);
            testCase.verifyEqual(app.variablesCombo.Enable, matlab.lang.OnOffSwitchState.on);
            testCase.verifyEqual(app.varValueText.Enable, matlab.lang.OnOffSwitchState.on);
        end

        function geometryBrowsersFilterWithoutEnter(testCase)
            cases = { ...
                'lvd_EditGeometricPointsGUI_App', 'pointsSearchText', 'pointsListBox', 'removePointButton', @testCase.makePoint; ...
                'lvd_EditGeometricVectorsGUI_App', 'vectorsSearchText', 'vectorsListBox', 'removeVectorButton', @testCase.makeVector; ...
                'lvd_EditGeometricPlanesGUI_App', 'planesSearchText', 'planesListBox', 'removePlaneButton', @testCase.makePlane; ...
                'lvd_EditGeometricAnglesGUI_App', 'anglesSearchText', 'anglesListBox', 'removeAngleButton', @testCase.makeAngle; ...
                'lvd_EditGeometricCoordSysGUI_App', 'coordSysSearchText', 'coordSysListBox', 'removeCoordSysButton', @testCase.makeCoordSys; ...
                'lvd_EditGeometricRefFramesGUI_App', 'refFrameSearchText', 'refFrameListBox', 'removeRefFrameButton', @testCase.makeRefFrame};
            for i = 1:size(cases, 1)
                lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
                target = cases{i, 5}(lvdData, 'Target Object');
                other = cases{i, 5}(lvdData, 'Other Object');
                app = testCase.openDialog(@() feval(cases{i, 1}, lvdData));
                listBox = app.(cases{i, 3});

                testCase.verifyTrue(isa(app.(cases{i, 2}), 'matlab.ui.control.EditField'));
                testCase.fireSearch(app.(cases{i, 2}), 'target');
                testCase.verifyEqual(numel(listBox.Items), 1);
                testCase.verifyTrue(listBox.Value == target);
                testCase.verifyEqual(listBox.ItemsData(1), target);
                testCase.verifyTrue(contains(listBox.Items{1}, 'Target Object'));

                testCase.verifyWarningFree(@() testCase.fireSearch(app.(cases{i, 2}), 'zzz'));
                testCase.verifyEmpty(listBox.Items);
                testCase.verifyEmpty(listBox.Value);
                testCase.verifyEqual(app.(cases{i, 4}).Enable, matlab.lang.OnOffSwitchState.off);

                testCase.fireSearch(app.(cases{i, 2}), '');
                testCase.verifyEqual(numel(listBox.Items), 2);
                testCase.verifyTrue(any(listBox.ItemsData == target) && any(listBox.ItemsData == other));
                delete(app);
            end
        end

        function graphicalAnalysisSearchFiltersWithoutEnter(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(@() lvd_GraphicalAnalysisGUI_App(lvdData, testCase.stubMainFig));
            fullList = getappdata(app.lvd_GraphicalAnalysisGUI, 'fullDepVarList');

            testCase.verifyEqual(app.SearchTaskText.Placeholder, 'Type to filter tasks...');
            testCase.fireSearch(app.SearchTaskText, 'altitude');
            testCase.verifyNotEmpty(app.depVarListbox.Items);
            testCase.verifyTrue(all(contains(lower(app.depVarListbox.Items), 'altitude')));
            testCase.verifyTrue(numel(app.depVarListbox.Items) < numel(fullList));

            testCase.verifyWarningFree(@() testCase.fireSearch(app.SearchTaskText, 'zzz'));
            testCase.verifyEmpty(app.depVarListbox.Items);
            testCase.verifyEmpty(app.depVarListbox.Value);
            testCase.verifyEqual(app.AddTasksButton.Enable, matlab.lang.OnOffSwitchState.off);

            testCase.fireSearch(app.SearchTaskText, '');
            testCase.verifyEqual(app.depVarListbox.Items(:), fullList(:));
        end
    end

    methods(Access=private)
        function app = openDialog(testCase, launchFcn)
            app = launchFcn();
            drawnow;
            testCase.assertTrue(not(isempty(app)));
            testCase.addTeardown(@() deleteIfValid(app));
        end

        function fireSearch(~, field, query)
            field.ValueChangingFcn(field, matlab.ui.eventdata.ValueChangingData(query));
            field.Value = query;
            drawnow;
        end

        function point = makePoint(testCase, lvdData, name)
            point = FixedPointInFrame([0; 0; 0], testCase.kerbinFrame, name, lvdData);
            lvdData.geometry.points.addPoint(point);
        end

        function vector = makeVector(testCase, lvdData, name)
            vector = FixedVectorInFrame([1; 0; 0], testCase.kerbinFrame, name, lvdData);
            lvdData.geometry.vectors.addVector(vector);
        end

        function plane = makePlane(testCase, lvdData, name)
            point = FixedPointInFrame([0; 0; 0], testCase.kerbinFrame, 'Plane Point', lvdData);
            vector = FixedVectorInFrame([0; 0; 1], testCase.kerbinFrame, 'Plane Vector', lvdData);
            plane = PointVectorPlane(point, vector, name, lvdData);
            lvdData.geometry.planes.addPlane(plane);
        end

        function angle = makeAngle(testCase, lvdData, name)
            first = FixedVectorInFrame([1; 0; 0], testCase.kerbinFrame, 'Angle Vector 1', lvdData);
            second = FixedVectorInFrame([0; 1; 0], testCase.kerbinFrame, 'Angle Vector 2', lvdData);
            angle = TwoVectorAngle(first, second, name, lvdData);
            lvdData.geometry.angles.addAngle(angle);
        end

        function coordSys = makeCoordSys(testCase, lvdData, name)
            coordSys = ParallelToFrameCoordSystem(testCase.kerbinFrame, name, lvdData);
            lvdData.geometry.coordSyses.addCoordSys(coordSys);
        end

        function refFrame = makeRefFrame(testCase, lvdData, name)
            point = FixedPointInFrame([0; 0; 0], testCase.kerbinFrame, 'Frame Point', lvdData);
            coordSys = ParallelToFrameCoordSystem(testCase.kerbinFrame, 'Frame System', lvdData);
            refFrame = CoordSysPointRefFrame(coordSys, point, name, lvdData);
            lvdData.geometry.refFrames.addRefFrame(refFrame);
        end

        function closeNewFigures(testCase)
            figs = findall(groot, 'Type', 'figure');
            figs = figs(not(ismember(figs, testCase.figuresBefore)));
            delete(figs(isvalid(figs)));
        end
    end
end

function deleteIfValid(h)
if(not(isempty(h)) && isvalid(h))
    delete(h);
end
end
