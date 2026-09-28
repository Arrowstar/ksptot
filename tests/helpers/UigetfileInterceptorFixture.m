classdef UigetfileInterceptorFixture < matlab.unittest.fixtures.Fixture
    %UigetfileInterceptorFixture Scripts the user's side of uigetfile prompts.
    %
    %   Companion to UiwaitInterceptorFixture for dialog flows that pick
    %   files: while this fixture is applied, a stand-in uigetfile.m sits
    %   at the top of the path.  The stand-in pops the next queued
    %   response and returns [file, path] exactly as a user's click
    %   would; an empty queue returns 0 (Cancel) and is recorded as an
    %   unexpected prompt in errors().
    %
    %       fixture = testCase.applyFixture(UigetfileInterceptorFixture());
    %       fixture.queueResponse('craft.craft', tmpDir);   % 1st prompt
    %       fixture.queueResponse('PartDatabase.cfg', tmpDir);   % 2nd prompt
    %       testCase.press(app.generateFromCraftButton);
    %       testCase.verifyEmpty(fixture.errors());
    %
    %   Tests fail loudly when a callback prompts more times than the
    %   test scripted (the extra prompt cancels the flow and the queue
    %   exhaustion lands in errors()).
    %
    %   See also: UiwaitInterceptorFixture.

    properties(Access = private)
        shadowDir(1,:) char = ''
        warnState
    end

    properties(Constant, Access = private)
        QueueKey = 'UigetfileInterceptorFixture_queue'
        ErrorsKey = 'UigetfileInterceptorFixture_errors'
    end

    methods
        function setup(fixture)
            fixture.shadowDir = tempname();
            mkdir(fixture.shadowDir);

            fid = fopen(fullfile(fixture.shadowDir, 'uigetfile.m'), 'w');
            fprintf(fid, 'function [file, path] = uigetfile(varargin)\n');
            fprintf(fid, '%%uigetfile Stand-in installed by UigetfileInterceptorFixture (see that class).\n');
            fprintf(fid, '    [file, path] = UigetfileInterceptorFixture.next();\n');
            fprintf(fid, 'end\n');
            fclose(fid);

            setappdata(groot, UigetfileInterceptorFixture.QueueKey, ...
                struct('file', {}, 'path', {}, 'label', {}));
            setappdata(groot, UigetfileInterceptorFixture.ErrorsKey, {});

            fixture.warnState = warning('off', 'MATLAB:dispatcher:nameConflict');
            addpath(fixture.shadowDir);

            fixture.SetupDescription = 'Replaced uigetfile with the UigetfileInterceptorFixture stand-in.';
            fixture.TeardownDescription = 'Restored the real uigetfile.';
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

            for key = {UigetfileInterceptorFixture.QueueKey, ...
                    UigetfileInterceptorFixture.ErrorsKey}
                if(isappdata(groot, key{1}))
                    rmappdata(groot, key{1});
                end
            end
        end

        function queueResponse(~, file, path, label)
            %queueResponse Scripts the next uigetfile prompt to "choose"
            %(file, path). LABEL (optional) tags the response for
            %debugging.
            arguments
                ~
                file
                path
                label(1,:) char = ''
            end
            queue = getappdata(groot, UigetfileInterceptorFixture.QueueKey);
            queue(end+1) = struct('file', file, 'path', path, 'label', label);
            setappdata(groot, UigetfileInterceptorFixture.QueueKey, queue);
        end

        function errs = errors(~)
            %errors Reports (cellstr) unexpected prompts and pop failures.
            errs = getappdata(groot, UigetfileInterceptorFixture.ErrorsKey);
        end

        function n = remaining(~)
            %remaining Number of scripted responses not yet consumed.
            queue = getappdata(groot, UigetfileInterceptorFixture.QueueKey);
            n = numel(queue);
        end
    end

    methods(Static)
        function [file, path] = next()
            %next Called by the stand-in uigetfile. Not for direct use.
            if(~isappdata(groot, UigetfileInterceptorFixture.QueueKey))
                file = 0;   %fixture torn down while a dialog was still around
                path = 0;
                return;
            end

            queue = getappdata(groot, UigetfileInterceptorFixture.QueueKey);
            if(isempty(queue))
                errs = getappdata(groot, UigetfileInterceptorFixture.ErrorsKey);
                errs{end+1} = 'uigetfile prompted with an empty response queue; cancelling.';
                setappdata(groot, UigetfileInterceptorFixture.ErrorsKey, errs);
                file = 0;
                path = 0;
                return;
            end

            resp = queue(1);
            queue(1) = [];
            setappdata(groot, UigetfileInterceptorFixture.QueueKey, queue);
            file = resp.file;
            path = resp.path;
        end
    end
end
