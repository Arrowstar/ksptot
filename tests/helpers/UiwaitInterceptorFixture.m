classdef UiwaitInterceptorFixture < matlab.unittest.fixtures.Fixture
    %UiwaitInterceptorFixture Scripts the user's side of blocking (uiwait) dialogs.
    %
    %   Almost every LVD editor is an App Designer dialog that calls uiwait
    %   on its own figure and returns its result through an
    %   AppDesignerGUIOutput once the user presses Save & Close.  Under
    %   "matlab -batch" a uiwait cannot be released from a timer, so an app
    %   flow that opens such a dialog (press "Insert Sequential Event", pick a
    %   context menu item, ...) cannot be driven end to end the ordinary way.
    %
    %   While this fixture is applied, a stand-in uiwait.m sits at the top of
    %   the path.  When a dialog calls uiwait(fig) the stand-in looks up the
    %   handler registered for that figure's Name and calls handler(fig) -
    %   the handler plays the user, filling controls in and pressing the
    %   dialog's buttons - and then returns, exactly as the real uiwait would
    %   once the dialog closed.  The calling app code then continues with the
    %   dialog's output already set.
    %
    %       fixture = testCase.applyFixture(UiwaitInterceptorFixture());
    %       fixture.whenShown('Edit Event', @(fig) pressButton(fig, 'Save & Close'));
    %       testCase.press(app.insertEventButton);          % blocks in uiwait -> handler runs
    %       testCase.verifyEmpty(fixture.errors());
    %       testCase.verifyEmpty(fixture.unhandled());
    %
    %   Figures with no registered handler are left open and recorded in
    %   unhandled(); the stand-in still returns so a test can never hang.
    %   Handler errors are caught and recorded in errors() rather than
    %   propagated into the dialog's callback.

    properties(Access = private)
        shadowDir(1,:) char = ''
        warnState
    end

    properties(Constant, Access = private)
        RegistryKey = 'UiwaitInterceptorFixture_registry';
        ErrorsKey = 'UiwaitInterceptorFixture_errors';
        UnhandledKey = 'UiwaitInterceptorFixture_unhandled';
    end

    methods
        function setup(fixture)
            fixture.shadowDir = tempname();
            mkdir(fixture.shadowDir);

            fid = fopen(fullfile(fixture.shadowDir, 'uiwait.m'), 'w');
            fprintf(fid, 'function uiwait(varargin)\n');
            fprintf(fid, '%%uiwait Stand-in installed by UiwaitInterceptorFixture (see that class).\n');
            fprintf(fid, '    if(nargin >= 1)\n');
            fprintf(fid, '        UiwaitInterceptorFixture.dispatch(varargin{1});\n');
            fprintf(fid, '    end\n');
            fprintf(fid, 'end\n');
            fclose(fid);

            setappdata(groot, UiwaitInterceptorFixture.RegistryKey, struct('name', {}, 'fcn', {}, 'once', {}));
            setappdata(groot, UiwaitInterceptorFixture.ErrorsKey, {});
            setappdata(groot, UiwaitInterceptorFixture.UnhandledKey, {});

            fixture.warnState = warning('off', 'MATLAB:dispatcher:nameConflict');
            addpath(fixture.shadowDir);

            fixture.SetupDescription = 'Replaced uiwait with the UiwaitInterceptorFixture stand-in.';
            fixture.TeardownDescription = 'Restored the real uiwait.';
        end

        function teardown(fixture)
            if(not(isempty(fixture.shadowDir)))
                rmpath(fixture.shadowDir);
                if(isfolder(fixture.shadowDir))
                    rmdir(fixture.shadowDir, 's');
                end
            end

            if(not(isempty(fixture.warnState)))
                warning(fixture.warnState);
            end

            for key = {UiwaitInterceptorFixture.RegistryKey, UiwaitInterceptorFixture.ErrorsKey, UiwaitInterceptorFixture.UnhandledKey}
                if(isappdata(groot, key{1}))
                    rmappdata(groot, key{1});
                end
            end
        end

        function whenShown(~, figName, handlerFcn, once)
            %whenShown Registers handlerFcn(fig) for dialogs whose Name equals
            %figName (or starts with it when figName ends in '*').  Handlers
            %are one-shot unless once is false.
            arguments
                ~
                figName(1,:) char
                handlerFcn(1,1) function_handle
                once(1,1) logical = true
            end

            registry = getappdata(groot, UiwaitInterceptorFixture.RegistryKey);
            registry(end+1) = struct('name', figName, 'fcn', handlerFcn, 'once', once);
            setappdata(groot, UiwaitInterceptorFixture.RegistryKey, registry);
        end

        function errs = errors(~)
            %errors Reports (cellstr) of handler errors caught so far.
            errs = getappdata(groot, UiwaitInterceptorFixture.ErrorsKey);
        end

        function names = unhandled(~)
            %unhandled Names of dialogs that reached uiwait with no handler.
            names = getappdata(groot, UiwaitInterceptorFixture.UnhandledKey);
        end
    end

    methods(Static)
        function dispatch(fig)
            %dispatch Called by the stand-in uiwait.  Not for direct use.
            if(not(isappdata(groot, UiwaitInterceptorFixture.RegistryKey)))
                return; %fixture torn down while a dialog was still around
            end

            name = '';
            if(isa(fig, 'matlab.ui.Figure') && isvalid(fig))
                name = fig.Name;
            end

            registry = getappdata(groot, UiwaitInterceptorFixture.RegistryKey);
            idx = [];
            for k = 1:numel(registry)
                pat = registry(k).name;
                if(endsWith(pat, '*'))
                    hit = startsWith(name, pat(1:end-1));
                else
                    hit = strcmp(name, pat);
                end
                if(hit)
                    idx = k;
                    break;
                end
            end

            if(isempty(idx))
                unhandled = getappdata(groot, UiwaitInterceptorFixture.UnhandledKey);
                unhandled{end+1} = name;
                setappdata(groot, UiwaitInterceptorFixture.UnhandledKey, unhandled);
                return;
            end

            handler = registry(idx).fcn;
            if(registry(idx).once)
                registry(idx) = [];
                setappdata(groot, UiwaitInterceptorFixture.RegistryKey, registry);
            end

            try
                handler(fig);
                drawnow;
            catch ME
                errs = getappdata(groot, UiwaitInterceptorFixture.ErrorsKey);
                errs{end+1} = sprintf('[%s] %s', name, getReport(ME, 'basic', 'hyperlinks', 'off'));
                setappdata(groot, UiwaitInterceptorFixture.ErrorsKey, errs);
            end
        end

        function pushButton(fig, buttonText)
            %pushButton Fires the callback of the uibutton in fig whose Text is
            %buttonText, the way a click would.  GUIDE-migrated callbacks read
            %event.Source, so a minimal event structure is supplied.
            btns = findall(fig, 'Type', 'uibutton');
            btn = btns(strcmp({btns.Text}, buttonText));
            if(isempty(btn))
                error('UiwaitInterceptorFixture:noButton', 'No button "%s" in dialog "%s".', buttonText, fig.Name);
            end
            btn = btn(1);
            btn.ButtonPushedFcn(btn, struct('Source', btn, 'EventName', 'ButtonPushed'));
            drawnow;
        end

        function dd = findDropDownWithItem(fig, itemText)
            %findDropDownWithItem The uidropdown in fig whose Items contain itemText.
            dds = findall(fig, 'Type', 'uidropdown');
            dd = dds(arrayfun(@(d) any(strcmp(d.Items, itemText)), dds));
            if(isempty(dd))
                error('UiwaitInterceptorFixture:noDropDown', 'No dropdown offering "%s" in dialog "%s".', itemText, fig.Name);
            end
            dd = dd(1);
        end
    end
end
