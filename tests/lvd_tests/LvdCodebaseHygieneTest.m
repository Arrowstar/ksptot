classdef LvdCodebaseHygieneTest < KsptotTestCase
    %LvdCodebaseHygieneTest Static checks that dead or dangling LVD code stays gone.
    %
    % Two pieces of unreachable code were removed because they referred to
    % classes that no longer exist or duplicated live logic:
    %   * ObjectiveFunctionEnum and CompositeObjectiveFcn.upgradeExistingObjFuncs
    %     named three objective-function classes that had been deleted.
    %   * classes/Simulation/ode (AbstractODE, FirstOrderODE) was a superseded
    %     copy of the propagator code with no callers.
    %
    % The generic check below would have caught the first case: every class
    % name that appears as an isa() literal in LVD source must resolve.

    methods(Test)
        function removedDeadCodeStaysRemoved(testCase)
            testCase.verifyEqual(exist('ObjectiveFunctionEnum', 'class'), 0, ...
                'ObjectiveFunctionEnum referenced deleted objective classes and was removed.');
            testCase.verifyEqual(exist('FirstOrderODE', 'class'), 0, ...
                'Simulation/ode/@FirstOrderODE was a dead duplicate of the propagator logic.');
            testCase.verifyEqual(exist('AbstractODE', 'class'), 0, ...
                'Simulation/ode/@AbstractODE was a dead duplicate of the propagator logic.');
            testCase.verifyFalse(ismember('upgradeExistingObjFuncs', methods('CompositeObjectiveFcn')), ...
                'CompositeObjectiveFcn.upgradeExistingObjFuncs referenced deleted classes and was removed.');
        end

        function everyIsaLiteralInLvdRefersToAnExistingClass(testCase)
            lvdRoot = fullfile(ksptotTestRoot(), 'helper_methods', 'ksptot_lvd');
            files = dir(fullfile(lvdRoot, '**', '*.m'));

            isDeprecated = contains({files.folder}, 'deprecated', 'IgnoreCase', true);
            files = files(~isDeprecated);
            testCase.assertNotEmpty(files, 'No LVD source files found; the path lookup is wrong.');

            %isa(x, 'Name') -- only simple identifiers; dotted/package names
            %and built-in category names are handled below.
            pattern = 'isa\(\s*[^,()]+?,\s*''([A-Za-z_]\w*)''\s*\)';

            builtinTypes = {'double','single','char','string','logical','cell','struct','numeric', ...
                            'float','integer','function_handle','handle','table','datetime','duration', ...
                            'int8','int16','int32','int64','uint8','uint16','uint32','uint64','dictionary', ...
                            'categorical','timetable','calendarDuration','sym','gpuArray'};

            missing = {};
            for i = 1:numel(files)
                txt = fileread(fullfile(files(i).folder, files(i).name));
                tokens = regexp(txt, pattern, 'tokens');

                for k = 1:numel(tokens)
                    name = tokens{k}{1};

                    if(ismember(name, builtinTypes))
                        continue;
                    end

                    if(exist(name, 'class') == 8 || exist(name, 'file') == 2 || exist(name, 'builtin') == 5)
                        continue;
                    end

                    missing{end+1} = sprintf('%s -> isa(..., ''%s'')', files(i).name, name); %#ok<AGROW>
                end
            end

            testCase.verifyEmpty(missing, sprintf( ...
                'isa() literals that name a class no longer on the path:\n  %s', strjoin(unique(missing), sprintf('\n  '))));
        end
    end
end
