classdef PlaybackControllerTest < KsptotTestCase
    %PlaybackControllerTest LvdViewPlaybackController (F8 playback): the
    %deterministic frame schedule and the play/pause/stop/advance state
    %machine, driven without real time except for two short timer cases.

    methods(Test)

        %% -------------------------------------------------- frame schedule

        function frameScheduleIsDeterministic(testCase)
            times = LvdViewPlaybackController.frameSchedule(0, 3, 4, 2);
            testCase.verifyEqual(times, 0:0.5:3, 'AbsTol', 1e-12, 'step = speed/fps');

            %the end is appended when the step does not land on it
            times = LvdViewPlaybackController.frameSchedule(0, 1, 4, 3);   % step 0.75
            testCase.verifyEqual(times, [0 0.75 1], 'AbsTol', 1e-12);

            %and not duplicated when it does
            times = LvdViewPlaybackController.frameSchedule(10, 12, 2, 1);  % step 0.5
            testCase.verifyEqual(times, 10:0.5:12, 'AbsTol', 1e-12);
        end

        function frameScheduleHandlesDegenerateRanges(testCase)
            testCase.verifyEqual(LvdViewPlaybackController.frameSchedule(5, 5, 30, 10), 5);
            testCase.verifyEqual(LvdViewPlaybackController.frameSchedule(5, 4, 30, 10), 5);
            testCase.verifyEqual(LvdViewPlaybackController.frameSchedule(0, NaN, 30, 10), 0);

            %a range shorter than one step still yields both ends
            times = LvdViewPlaybackController.frameSchedule(0, 0.1, 1, 1);
            testCase.verifyEqual(times, [0 0.1], 'AbsTol', 1e-12);
        end

        %% ----------------------------------------------- state machine

        function advanceStepsBySpeedAndRendersOnce(testCase)
            [ctrl, rec] = testCase.controller(60, 30, false, [0 1000]);
            ctrl.advance(0.5);
            testCase.verifyEqual(ctrl.currentTime, 30, 'AbsTol', 1e-12, '0.5 s wall time at 60x = 30 s sim time');
            testCase.verifyEqual(rec.times, 30, 'One render per advance');
            ctrl.advance(0.25);
            testCase.verifyEqual(ctrl.currentTime, 45, 'AbsTol', 1e-12);
            testCase.verifyEqual(rec.times, [30 45]);
        end

        function advanceStopsAtTheEndWithoutLoop(testCase)
            [ctrl, rec] = testCase.controller(10, 30, false, [100 200]);
            states = CallRecorder();
            addlistener(ctrl, 'StateChanged', @(~,~) states.record(ctrl.state));

            ctrl.play();   %state -> playing, renders the first frame
            testCase.verifyEqual(ctrl.state, "playing");
            ctrl.pause();  %keep the real timer out of the pure stepping below
            %(the timer may already have ticked once, so measure from here)
            t0 = ctrl.currentTime;
            testCase.verifyLessThan(t0, 110, 'Playback barely started before the pause');
            ctrl.advance(5);    % t0 + 50
            testCase.verifyEqual(ctrl.currentTime, t0 + 50, 'AbsTol', 1e-12);
            testCase.verifyEqual(ctrl.state, "paused", 'advance alone does not change the state before the end');
            ctrl.advance(20);   % would be 350 -> clamps to 200 and stops
            testCase.verifyEqual(ctrl.currentTime, 200, 'AbsTol', 1e-12, 'Clamped to the end');
            testCase.verifyEqual(ctrl.state, "stopped");
            testCase.verifyEqual(rec.times(end), 200);
            testCase.verifyEqual(states.firstArgs(), {"playing", "paused", "stopped"}, 'StateChanged fired for every transition');
        end

        function advanceWrapsWithLoop(testCase)
            [ctrl, rec] = testCase.controller(10, 30, true, [100 200]);
            stateBefore = ctrl.state;
            ctrl.advance(12);   % 100 + 120 = 220 -> wraps to 120
            testCase.verifyEqual(ctrl.currentTime, 120, 'AbsTol', 1e-12);
            testCase.verifyEqual(ctrl.state, stateBefore, 'Looping never stops playback');
            ctrl.advance(100);  % 120 + 1000 = 1120 -> (1120-100) mod 100 = 20 -> 120
            testCase.verifyEqual(ctrl.currentTime, 120, 'AbsTol', 1e-9);
            ctrl.advance(8);    % exactly the end -> wraps to the start
            testCase.verifyEqual(ctrl.currentTime, 100, 'AbsTol', 1e-9);
            testCase.verifyEqual(rec.times, [120 120 100], 'AbsTol', 1e-9);
        end

        function stepToClampsAndStopResets(testCase)
            [ctrl, rec] = testCase.controller(10, 30, false, [100 200]);
            ctrl.stepTo(150);
            testCase.verifyEqual(ctrl.currentTime, 150);
            ctrl.stepTo(-5);
            testCase.verifyEqual(ctrl.currentTime, 100, 'Clamped below');
            ctrl.stepTo(1e9);
            testCase.verifyEqual(ctrl.currentTime, 200, 'Clamped above');

            ctrl.stop();
            testCase.verifyEqual(ctrl.currentTime, 100, 'stop() returns to the start');
            testCase.verifyEqual(ctrl.state, "stopped");
            testCase.verifyEqual(rec.times, [150 100 200 100]);

            ctrl.stepTo(175);
            ctrl.stop(false);
            testCase.verifyEqual(ctrl.currentTime, 175, 'stop(false) keeps the time');
        end

        function stepFramesMovesByWholeFrames(testCase)
            [ctrl, ~] = testCase.controller(60, 30, false, [0 1000]);
            ctrl.stepTo(100);
            ctrl.stepFrames(1);
            testCase.verifyEqual(ctrl.currentTime, 102, 'AbsTol', 1e-12, 'one frame = speed/fps sim seconds');
            ctrl.stepFrames(-3);
            testCase.verifyEqual(ctrl.currentTime, 96, 'AbsTol', 1e-12);
        end

        function pauseKeepsTimeAndPlayResumes(testCase)
            [ctrl, ~] = testCase.controller(10, 30, false, [0 100]);
            ctrl.play();
            ctrl.pause();
            testCase.verifyEqual(ctrl.state, "paused");
            ctrl.stepTo(40);
            ctrl.play();
            testCase.verifyEqual(ctrl.state, "playing");
            ctrl.pause();
            %the timer may have ticked once or twice (10x speed, 30 fps)
            testCase.verifyGreaterThanOrEqual(ctrl.currentTime, 40, 'Play resumes from the paused time');
            testCase.verifyLessThan(ctrl.currentTime, 45, 'Play resumes from the paused time, not from the start');
            testCase.verifyEqual(ctrl.state, "paused");
            ctrl.togglePlayPause();
            testCase.verifyEqual(ctrl.state, "playing");
            ctrl.togglePlayPause();
            testCase.verifyEqual(ctrl.state, "paused");
            ctrl.stop();
        end

        function playFromTheEndRestarts(testCase)
            [ctrl, rec] = testCase.controller(10, 30, false, [0 100]);
            ctrl.stepTo(100);
            ctrl.play();
            ctrl.pause();
            testCase.verifyLessThan(ctrl.currentTime, 5, 'Playing from the end starts over (a tick or two may have run)');
            lastEndFrame = find(rec.times == 100, 1, 'last');
            testCase.assertNotEmpty(lastEndFrame, 'The end frame was shown before play');
            testCase.verifyEqual(rec.times(lastEndFrame + 1), 0, 'Play rendered the start frame right after the end frame');
            ctrl.stop();
        end

        function playWithoutATimeRangeErrors(testCase)
            settings = LvdViewPlaybackSettings();
            ctrl = LvdViewPlaybackController(settings, [NaN NaN], @(t) []);
            cleanup = onCleanup(@() delete(ctrl)); %#ok<NASGU>
            testCase.verifyFalse(ctrl.hasTimeRange());
            testCase.verifyError(@() ctrl.play(), 'LvdViewPlaybackController:noTimeRange');
            ctrl.setTimeLimits([0 10]);
            testCase.verifyTrue(ctrl.hasTimeRange());
            testCase.verifyEqual(ctrl.currentTime, 0);
        end

        function setTimeLimitsClampsTheCurrentTime(testCase)
            [ctrl, ~] = testCase.controller(10, 30, false, [0 100]);
            ctrl.stepTo(80);
            ctrl.setTimeLimits([0 50]);
            testCase.verifyEqual(ctrl.currentTime, 50);
            ctrl.setTimeLimits([60 90]);
            testCase.verifyEqual(ctrl.currentTime, 60);
        end

        %% ----------------------------------------------------- real timer

        function realTimerAdvancesAndIsCleanedUp(testCase)
            timersBefore = timerfindall('Tag', 'LvdViewPlaybackTimer');
            [ctrl, rec] = testCase.controller(100, 20, false, [0 1e6]);

            ctrl.play();
            pause(0.6);
            ctrl.pause();
            tAfter = ctrl.currentTime;

            testCase.verifyGreaterThan(tAfter, 10, 'Time advanced while the timer ran');
            testCase.verifyGreaterThan(numel(rec.times), 2, 'Several frames were rendered');
            testCase.verifyEqual(ctrl.state, "paused");

            pause(0.15);
            testCase.verifyEqual(ctrl.currentTime, tAfter, 'No frames render while paused');

            delete(ctrl);
            timersAfter = timerfindall('Tag', 'LvdViewPlaybackTimer');
            testCase.verifyEqual(numel(timersAfter), numel(timersBefore), 'Deleting the controller deletes its timer');
        end

        function renderErrorStopsPlaybackCleanly(testCase)
            settings = LvdViewPlaybackSettings();
            settings.fps = 20;
            settings.simSecPerRealSec = 1;
            rec = RenderRecorder();
            ctrl = LvdViewPlaybackController(settings, [0 100], @(t) failAfterTwoRenders(rec, t));
            cleanup = onCleanup(@() delete(ctrl)); %#ok<NASGU>

            warnState = warning('off', 'LvdViewPlaybackController:renderFailed');
            cleanupWarn = onCleanup(@() warning(warnState)); %#ok<NASGU>

            ctrl.play();
            pause(0.5);
            testCase.verifyEqual(ctrl.state, "stopped", 'A render error stops playback cleanly');
            testCase.verifyEqual(numel(rec.times), 3, 'The failing render was the last one attempted');
        end
    end

    methods(Access = private)
        function [ctrl, rec] = controller(testCase, speed, fps, loop, limits)
            settings = LvdViewPlaybackSettings();
            settings.simSecPerRealSec = speed;
            settings.fps = fps;
            settings.loop = loop;
            rec = RenderRecorder();
            ctrl = LvdViewPlaybackController(settings, limits, @(t) rec.record(t));
            testCase.addTeardown(@() deleteIfValid(ctrl));
        end
    end
end

function failAfterTwoRenders(rec, t)
    rec.record(t);
    if(numel(rec.times) > 2)
        error('test:boom', 'render failed');
    end
end

function deleteIfValid(h)
    if(not(isempty(h)) && isvalid(h))
        delete(h);
    end
end
