classdef NativeDialogInterceptorFixture < matlab.unittest.fixtures.Fixture
    %NativeDialogInterceptorFixture Stubs native modal dialogs for headless smoke tests.
    %
    %   The LVD main window reaches four blocking builtins that would hang
    %   under "matlab -batch": uigetfile, uiputfile, uiconfirm and inputdlg.
    %   Copy/paste menus also hit clipboard('copy',...), which is a no-op
    %   here so headless runs do not depend on a system clipboard.
    %
    %   While applied, shadow .m files sit at the top of the path and
    %   delegate to this fixture.  Defaults are pure cancel:
    %       uigetfile -> 0, uiputfile -> 0, uiconfirm -> 'No', inputdlg -> {}
    %   Tests opt into success with setUigetfileSuccess / setUiputfileSuccess
    %   / setUiconfirmResponse / setInputdlgResponse, then assert calls().
    %
    %       fixture = testCase.applyFixture(NativeDialogInterceptorFixture());
    %       fixture.setUiconfirmResponse('Yes');
    %       testCase.press(app.newMissionPlanMenu);
    %       testCase.verifyGreaterThan(fixture.calls().uiconfirm, 0);

    properties(Access = private)
        shadowDir(1,:) char = ''
        warnState
    end

    properties(Constant, Access = private)
        CallsKey = 'NativeDialogInterceptorFixture_calls';
        UigetfileKey = 'NativeDialogInterceptorFixture_uigetfile';
        UiputfileKey = 'NativeDialogInterceptorFixture_uiputfile';
        UiconfirmKey = 'NativeDialogInterceptorFixture_uiconfirm';
        InputdlgKey = 'NativeDialogInterceptorFixture_inputdlg';
    end

    methods
        function setup(fixture)
            fixture.shadowDir = tempname();
            mkdir(fixture.shadowDir);

            fixture.writeShadow('uigetfile.m', {
                'function [FileName, PathName, FilterIndex] = uigetfile(varargin)'
                '%uigetfile Stand-in installed by NativeDialogInterceptorFixture.'
                '    [FileName, PathName, FilterIndex] = NativeDialogInterceptorFixture.dispatchUigetfile(varargin);'
                'end'
            });
            fixture.writeShadow('uiputfile.m', {
                'function [FileName, PathName, FilterIndex] = uiputfile(varargin)'
                '%uiputfile Stand-in installed by NativeDialogInterceptorFixture.'
                '    [FileName, PathName, FilterIndex] = NativeDialogInterceptorFixture.dispatchUiputfile(varargin);'
                'end'
            });
            fixture.writeShadow('uiconfirm.m', {
                'function response = uiconfirm(varargin)'
                '%uiconfirm Stand-in installed by NativeDialogInterceptorFixture.'
                '    response = NativeDialogInterceptorFixture.dispatchUiconfirm(varargin);'
                'end'
            });
            fixture.writeShadow('inputdlg.m', {
                'function answer = inputdlg(varargin)'
                '%inputdlg Stand-in installed by NativeDialogInterceptorFixture.'
                '    answer = NativeDialogInterceptorFixture.dispatchInputdlg(varargin);'
                'end'
            });
            fixture.writeShadow('clipboard.m', {
                'function varargout = clipboard(varargin)'
                '%clipboard Stand-in installed by NativeDialogInterceptorFixture.'
                '    [varargout{1:nargout}] = NativeDialogInterceptorFixture.dispatchClipboard(varargin{:});'
                'end'
            });

            setappdata(groot, NativeDialogInterceptorFixture.CallsKey, struct('uigetfile', 0, 'uiputfile', 0, 'uiconfirm', 0, 'inputdlg', 0, 'clipboardCopy', 0));
            setappdata(groot, NativeDialogInterceptorFixture.UigetfileKey, {0, 0, 0});
            setappdata(groot, NativeDialogInterceptorFixture.UiputfileKey, {0, 0, 0});
            setappdata(groot, NativeDialogInterceptorFixture.UiconfirmKey, 'No');
            setappdata(groot, NativeDialogInterceptorFixture.InputdlgKey, {{}});

            fixture.warnState = warning('off', 'MATLAB:dispatcher:nameConflict');
            addpath(fixture.shadowDir);

            fixture.SetupDescription = 'Stubbed uigetfile/uiputfile/uiconfirm/inputdlg/clipboard with cancel defaults.';
            fixture.TeardownDescription = 'Restored the real native dialogs.';
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

            for key = {NativeDialogInterceptorFixture.CallsKey, ...
                    NativeDialogInterceptorFixture.UigetfileKey, ...
                    NativeDialogInterceptorFixture.UiputfileKey, ...
                    NativeDialogInterceptorFixture.UiconfirmKey, ...
                    NativeDialogInterceptorFixture.InputdlgKey}
                if(isappdata(groot, key{1}))
                    rmappdata(groot, key{1});
                end
            end
        end

        function setUigetfileSuccess(fixture, fullPath)
            [p, f, e] = fileparts(fullPath);
            setappdata(groot, NativeDialogInterceptorFixture.UigetfileKey, {[f, e], [p, filesep], 1});
        end

        function setUigetfileCancel(~)
            setappdata(groot, NativeDialogInterceptorFixture.UigetfileKey, {0, 0, 0});
        end

        function setUiputfileSuccess(fixture, fullPath)
            [p, f, e] = fileparts(fullPath);
            setappdata(groot, NativeDialogInterceptorFixture.UiputfileKey, {[f, e], [p, filesep], 1});
        end

        function setUiputfileCancel(~)
            setappdata(groot, NativeDialogInterceptorFixture.UiputfileKey, {0, 0, 0});
        end

        function setUiconfirmResponse(~, response)
            setappdata(groot, NativeDialogInterceptorFixture.UiconfirmKey, response);
        end

        function setInputdlgResponse(~, answer)
            %setInputdlgResponse {} cancels; {'1.0'} accepts with that string.
            setappdata(groot, NativeDialogInterceptorFixture.InputdlgKey, {answer});
        end

        function s = calls(~)
            s = getappdata(groot, NativeDialogInterceptorFixture.CallsKey);
        end
    end

    methods(Static)
        function [FileName, PathName, FilterIndex] = dispatchUigetfile(~)
            NativeDialogInterceptorFixture.bump('uigetfile');
            resp = getappdata(groot, NativeDialogInterceptorFixture.UigetfileKey);
            FileName = resp{1};
            PathName = resp{2};
            FilterIndex = resp{3};
        end

        function [FileName, PathName, FilterIndex] = dispatchUiputfile(~)
            NativeDialogInterceptorFixture.bump('uiputfile');
            resp = getappdata(groot, NativeDialogInterceptorFixture.UiputfileKey);
            FileName = resp{1};
            PathName = resp{2};
            FilterIndex = resp{3};
        end

        function response = dispatchUiconfirm(~)
            NativeDialogInterceptorFixture.bump('uiconfirm');
            response = getappdata(groot, NativeDialogInterceptorFixture.UiconfirmKey);
        end

        function answer = dispatchInputdlg(~)
            NativeDialogInterceptorFixture.bump('inputdlg');
            wrapped = getappdata(groot, NativeDialogInterceptorFixture.InputdlgKey);
            answer = wrapped{1};
        end

        function varargout = dispatchClipboard(varargin)
            NativeDialogInterceptorFixture.bump('clipboardCopy');
            %Only 'copy' is stubbed; reads return empty so tests never hang.
            if(nargin >= 1 && ischar(varargin{1}) && strcmpi(varargin{1}, 'copy'))
                varargout = {};
                return;
            end
            try
                [varargout{1:nargout}] = builtin('clipboard', varargin{:});
            catch
                varargout = cell(1, nargout);
                [varargout{:}] = deal('');
            end
        end
    end

    methods(Access = private)
        function writeShadow(fixture, name, lines)
            fid = fopen(fullfile(fixture.shadowDir, name), 'w');
            for i = 1:numel(lines)
                fprintf(fid, '%s\n', lines{i});
            end
            fclose(fid);
        end
    end

    methods(Static, Access = private)
        function fixture = bump(field)
            fixture = [];
            if(isappdata(groot, NativeDialogInterceptorFixture.CallsKey))
                s = getappdata(groot, NativeDialogInterceptorFixture.CallsKey);
                s.(field) = s.(field) + 1;
                setappdata(groot, NativeDialogInterceptorFixture.CallsKey, s);
            end
        end
    end
end
