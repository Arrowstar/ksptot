classdef NomadOptionsDialogTest < KsptotTestCase
    %NomadOptionsDialogTest Full round-trip UI tests for the NOMAD options
    %editor (Phase 1: optimization).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/optimization/optimizer/lvd_editNomadOptionsGUI_App.mlapp
    %   ('Edit NOMAD Options'; ctor (wrapper, output) per
    %   NomadOptimizer.openOptionsDialog -- the wrapper's getOptions()
    %   handle is edited in place).
    %   Options class: helper_methods/.../optimizers/options/nomad/@NomadOptions/NomadOptions.m
    %   (surrogate set via the .surrogateOptions sub-object; the Surrogate
    %   button constructs lvd_editNomadSurrogateOptionsGUI_App with it).
    %   Note: NomadOptions.useParallel is typed PatternSearchUseParallelEnum
    %   (verified in NomadOptions.m) -- the test uses that class.
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   TankConstraintDialogTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  The dialog has no Cancel
    %   button (Save & Close only), so dismissal-without-save is the
    %   window-X close.  The surrogate-options sub-dialog is stubbed with a
    %   whenShown handler that presses its Save & Close (no-edit dismiss)
    %   and the fixture error log is asserted empty.
    %
    % COVERED
    %   Open shows stored values; every enum combo lists its members;
    %   no-edit Save changes nothing (numeric/logical snapshot);
    %   edit+save writes texts, combos and the surrogate checkbox through;
    %   a negative maxBbEvals is rejected leaving the dialog open and the
    %   model alone; a blank field stores NaN; the surrogate button opens
    %   the surrogate dialog; window-X close preserves the model.

    properties(Access=private)
        fixture UiwaitInterceptorFixture
    end

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.fixture = testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [wrapper, ~, ~] = testCase.buildFixture();
            opt = wrapper.getOptions();
            opt.direction_type = NomadDirectionTypeEnum.GPS2NStatic;
            opt.max_bb_eval = 2000;
            opt.max_time = 600;
            opt.max_iterations = 100;
            opt.initial_mesh_size = 0.5;
            opt.stop_if_feasible = NomadStopIfFeasibleEnum.StopIfFeasible;
            opt.constrType = NomadConstraintType.EB;
            opt.h_norm = NomadHNormTypeEnum.LInf;
            opt.useSurrogateModelSearch = true;

            app = testCase.openDialog(wrapper);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(handles.directionTypeCombo.Value, ...
                NomadDirectionTypeEnum.getIndForName(opt.direction_type.name));
            testCase.verifyEqual(str2double(get(handles.maxBbEvalsText, 'String')), 2000, 'AbsTol', 0);
            testCase.verifyEqual(str2double(get(handles.maxTimeText, 'String')), 600, 'AbsTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.maxIterationsText, 'String')), 100, 'AbsTol', 0);
            testCase.verifyEqual(str2double(get(handles.initialMeshSizeText, 'String')), 0.5, 'AbsTol', 1e-12);
            testCase.verifyEqual(handles.stopIfFeasibleCombo.Value, ...
                NomadStopIfFeasibleEnum.getIndForName(opt.stop_if_feasible.name));
            testCase.verifyEqual(handles.constrTypeCombo.Value, ...
                NomadConstraintType.getIndForName(opt.constrType.name));
            testCase.verifyEqual(handles.hNormCombo.Value, ...
                NomadHNormTypeEnum.getIndForName(opt.h_norm.name));
            testCase.verifyTrue(logical(app.UseSurrogateSearchCheckBox.Value));
            testCase.verifyEqual(string(app.SurrogateSearchOptionsButton.Enable), "on", ...
                'Enabling surrogate search must enable its options button.');
        end

        function combosOfferEveryEnumChoice(testCase)
            [wrapper, ~, ~] = testCase.buildFixture();
            app = testCase.openDialog(wrapper);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            dirItems = cellstr(handles.directionTypeCombo.String);
            testCase.verifyEqual(numel(dirItems), numel(enumeration('NomadDirectionTypeEnum')), ...
                'Every NOMAD direction type must be offered.');
            testCase.verifyTrue(any(strcmp(dirItems, NomadDirectionTypeEnum.OrthoN1Quad.name)), ...
                'The default direction type must be offered.');
            testCase.verifyEqual(numel(cellstr(handles.stopIfFeasibleCombo.String)), ...
                numel(enumeration('NomadStopIfFeasibleEnum')));
            testCase.verifyEqual(numel(cellstr(handles.constrTypeCombo.String)), ...
                numel(enumeration('NomadConstraintType')), 'Every constraint handling mode must be offered.');
            testCase.verifyEqual(numel(cellstr(handles.hNormCombo.String)), ...
                numel(enumeration('NomadHNormTypeEnum')));
            testCase.verifyEqual(numel(cellstr(handles.useParallelCombo.String)), ...
                numel(enumeration('PatternSearchUseParallelEnum')), 'Both parallel modes must be offered.');
        end

        function savingWithoutEditsChangesNothing(testCase)
            [wrapper, ~, ~] = testCase.buildFixture();
            before = testCase.snapshot(wrapper.getOptions());
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(wrapper, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_editNomadOptionsGUI;

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            after = testCase.snapshot(wrapper.getOptions());
            f = fieldnames(before);
            for i = 1:numel(f)
                testCase.verifyTrue(isequaln(before.(f{i}), after.(f{i})), ...
                    sprintf('%s changed on a no-edit save.', f{i}));
            end
        end

        function editAndSaveWritesThrough(testCase)
            [wrapper, ~, ~] = testCase.buildFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(wrapper, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.maxBbEvalsText, 'String', '5000');
            set(handles.maxTimeText, 'String', '900');
            set(handles.initialMeshSizeText, 'String', '0.25');
            handles.directionTypeCombo.Value = ...
                NomadDirectionTypeEnum.getIndForName(NomadDirectionTypeEnum.GPS2NStatic.name);
            handles.stopIfFeasibleCombo.Value = ...
                NomadStopIfFeasibleEnum.getIndForName(NomadStopIfFeasibleEnum.StopIfFeasible.name);
            handles.constrTypeCombo.Value = ...
                NomadConstraintType.getIndForName(NomadConstraintType.EB.name);
            handles.hNormCombo.Value = ...
                NomadHNormTypeEnum.getIndForName(NomadHNormTypeEnum.LInf.name);
            app.UseSurrogateSearchCheckBox.Value = true;
            opt = wrapper.getOptions();

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyEqual(opt.max_bb_eval, 5000, 'AbsTol', 0);
            testCase.verifyEqual(opt.max_time, 900, 'AbsTol', 1e-9);
            testCase.verifyEqual(opt.initial_mesh_size, 0.25, 'AbsTol', 1e-12);
            testCase.verifyEqual(opt.direction_type, NomadDirectionTypeEnum.GPS2NStatic);
            testCase.verifyEqual(opt.stop_if_feasible, NomadStopIfFeasibleEnum.StopIfFeasible);
            testCase.verifyEqual(opt.constrType, NomadConstraintType.EB);
            testCase.verifyEqual(opt.h_norm, NomadHNormTypeEnum.LInf);
            testCase.verifyTrue(opt.useSurrogateModelSearch);
        end

        function negativeMaxBbEvalsIsRejected(testCase)
            [wrapper, ~, ~] = testCase.buildFixture();
            wrapper.getOptions().max_bb_eval = 2000;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(wrapper, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.maxBbEvalsText, 'String', '-2');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A negative maxBbEvals must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_editNomadOptionsGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(wrapper.getOptions().max_bb_eval, 2000, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function blankTextMeansDefaultNaN(testCase)
            %Empty is explicitly legal in validateDoubleValue (it implies
            %the solver default) and round-trips as NaN.
            [wrapper, ~, ~] = testCase.buildFixture();
            wrapper.getOptions().max_bb_eval = 2000;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(wrapper, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.maxBbEvalsText, 'String', '');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'A blank field must save as the default.');
            testCase.verifyTrue(isnan(wrapper.getOptions().max_bb_eval), ...
                'A blank maxBbEvals must store NaN (solver default).');
        end

        function surrogateButtonOpensSurrogateDialog(testCase)
            [wrapper, ~, ~] = testCase.buildFixture();
            before = testCase.snapshot(wrapper.getOptions().surrogateOptions);
            app = testCase.openDialog(wrapper);

            % The button starts disabled until surrogate search is on.
            app.UseSurrogateSearchCheckBox.Value = true;
            testCase.fireValueChanged(app.UseSurrogateSearchCheckBox);

            seen = containers.Map();
            testCase.fixture.whenShown('Edit NOMAD Surrogate Options', @(fig) recordAndPush(fig, seen, 'Save & Close'));
            testCase.pushButton(app.SurrogateSearchOptionsButton);

            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
            testCase.verifyTrue(seen.isKey('Edit NOMAD Surrogate Options'), ...
                'The surrogate button must open the surrogate options dialog.');
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            testCase.verifyTrue(isvalid(handles.lvd_editNomadOptionsGUI), ...
                'Dismissing the nested dialog must leave the NOMAD dialog open.');
            after = testCase.snapshot(wrapper.getOptions().surrogateOptions);
            f = fieldnames(before);
            for i = 1:numel(f)
                testCase.verifyTrue(isequaln(before.(f{i}), after.(f{i})), ...
                    sprintf('Surrogate option %s changed on a no-edit dismiss.', f{i}));
            end
        end

        function closeWithoutSavingPreservesModel(testCase)
            [wrapper, ~, ~] = testCase.buildFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(wrapper, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_editNomadOptionsGUI;

            set(handles.maxBbEvalsText, 'String', '9999');
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Close must close the dialog.');
            testCase.verifyTrue(isnan(wrapper.getOptions().max_bb_eval), ...
                'Closing without saving must leave the model alone.');
        end
    end

    methods(Access=private)
        function [wrapper, lvdData, out] = buildFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            wrapper = lvdData.optimizer.getOptimizerForEnum(LvdOptimizerAlgoEnum.Nomad);
            out = AppDesignerGUIOutput({false});
        end

        function app = openDialog(testCase, wrapper, out)
            if nargin < 3 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_editNomadOptionsGUI_App(wrapper, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() NomadOptionsDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function fireValueChanged(~, comp)
            evt = struct('Source', comp, 'EventName', 'ValueChanged', ...
                'Value', comp.Value, 'PreviousValue', comp.Value);
            comp.ValueChangedFcn(comp, evt);
            drawnow;
        end

        function s = snapshot(~, o)
            %SNAPSHOT  Every numeric/logical option property, as a struct.
            s = struct();
            mc = metaclass(o);
            for p = mc.PropertyList.'
                if p.Dependent || p.Constant || ~strcmp(p.GetAccess, 'public'), continue; end
                v = o.(p.Name);
                if isnumeric(v) || islogical(v), s.(p.Name) = v; end
            end
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit NOMAD Options')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
            drawnow;
        end
    end

    methods(Static, Access=private)
        function deleteIfValid(app)
            if ~isempty(app) && isvalid(app)
                delete(app);
            end
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit NOMAD Options')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end

function recordAndPush(fig, seen, buttonText)
    seen(fig.Name) = true; %#ok<NASGU> containers.Map is a handle
    UiwaitInterceptorFixture.pushButton(fig, buttonText);
end
