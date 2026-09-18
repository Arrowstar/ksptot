classdef LvdViewPlaybackController < handle
    %LvdViewPlaybackController Plays the LVD 3-D view forward in time.
    %
    %   The controller owns a MATLAB timer that, on every tick, advances the
    %   current time by (wall-clock seconds elapsed) x simSecPerRealSec and
    %   renders through renderFcn(time).  Everything except the timer itself
    %   is a pure state machine (advance / stepTo / stop) so it can be unit
    %   tested without waiting on real time.
    %
    %   ctrl = LvdViewPlaybackController(settings, timeLimits, renderFcn)
    %   ctrl = LvdViewPlaybackController.fromMainApp(lvdData, handles, app)

    properties(SetAccess = private)
        settings LvdViewPlaybackSettings
        renderFcn function_handle = @(t) [];
        timeLimits(1,2) double = [NaN NaN];
        currentTime(1,1) double = NaN;
        state(1,1) string {mustBeMember(state, ["stopped", "playing", "paused"])} = "stopped";
        timerObj = [];
        lastTic = [];
    end

    events
        StateChanged
        FrameRendered
    end

    methods
        function obj = LvdViewPlaybackController(settings, timeLimits, renderFcn)
            arguments
                settings(1,1) LvdViewPlaybackSettings
                timeLimits(1,2) double
                renderFcn(1,1) function_handle
            end
            obj.settings = settings;
            obj.renderFcn = renderFcn;
            obj.setTimeLimits(timeLimits);
        end

        function delete(obj)
            obj.destroyTimer();
        end

        %% ------------------------------------------------------- controls
        function play(obj)
            if(not(all(isfinite(obj.timeLimits))) || obj.timeLimits(2) <= obj.timeLimits(1))
                error('LvdViewPlaybackController:noTimeRange', ...
                      'There is no propagated trajectory to play back.');
            end
            if(obj.state == "playing")
                return;
            end

            if(isnan(obj.currentTime) || obj.currentTime >= obj.timeLimits(2))
                obj.currentTime = obj.timeLimits(1);
            end

            obj.destroyTimer();
            obj.timerObj = timer('ExecutionMode', 'fixedSpacing', ...
                                 'Period', max(0.001, round(1/obj.settings.fps, 3)), ...
                                 'BusyMode', 'drop', ...
                                 'Name', 'LvdViewPlaybackTimer', ...
                                 'Tag', 'LvdViewPlaybackTimer', ...
                                 'TimerFcn', @(~,~) obj.tick(), ...
                                 'ErrorFcn', @(~,evt) obj.onTimerError(evt));
            obj.lastTic = tic;
            obj.setState("playing");
            obj.stepTo(obj.currentTime);
            start(obj.timerObj);
        end

        function pause(obj)
            obj.haltTimer();
            if(obj.state == "playing")
                obj.setState("paused");
            end
        end

        function stop(obj, resetToStart)
            arguments
                obj(1,1) LvdViewPlaybackController
                resetToStart(1,1) logical = true
            end
            obj.haltTimer();
            if(resetToStart && isfinite(obj.timeLimits(1)))
                obj.stepTo(obj.timeLimits(1));
            end
            obj.setState("stopped");
        end

        function togglePlayPause(obj)
            if(obj.state == "playing")
                obj.pause();
            else
                obj.play();
            end
        end

        function stepTo(obj, time)
            %stepTo Renders one frame at `time` (clamped to the time range).
            arguments
                obj(1,1) LvdViewPlaybackController
                time(1,1) double
            end
            if(all(isfinite(obj.timeLimits)))
                time = min(max(time, obj.timeLimits(1)), obj.timeLimits(2));
            end
            obj.currentTime = time;
            obj.renderFcn(time);
            notify(obj, 'FrameRendered');
        end

        function stepFrames(obj, numFrames)
            %stepFrames Advances (or rewinds) by whole playback frames.
            arguments
                obj(1,1) LvdViewPlaybackController
                numFrames(1,1) double
            end
            if(isnan(obj.currentTime))
                obj.currentTime = obj.timeLimits(1);
            end
            dt = numFrames * obj.settings.simSecPerRealSec / obj.settings.fps;
            obj.stepTo(obj.currentTime + dt);
        end

        function advance(obj, dtReal)
            %advance Moves playback forward by dtReal wall-clock seconds.
            %Pure apart from the render: stops (or wraps, when looping) at
            %the end of the time range.
            arguments
                obj(1,1) LvdViewPlaybackController
                dtReal(1,1) double {mustBeNonnegative}
            end
            tStart = obj.timeLimits(1);
            tEnd = obj.timeLimits(2);
            if(isnan(obj.currentTime))
                obj.currentTime = tStart;
            end

            newT = obj.currentTime + dtReal * obj.settings.simSecPerRealSec;
            stopAfter = false;

            if(newT >= tEnd)
                if(obj.settings.loop)
                    span = tEnd - tStart;
                    if(span > 0)
                        newT = tStart + mod(newT - tStart, span);
                    else
                        newT = tStart;
                    end
                else
                    newT = tEnd;
                    stopAfter = true;
                end
            end

            obj.stepTo(newT);

            if(stopAfter)
                obj.stop(false);
            end
        end

        function setTimeLimits(obj, timeLimits)
            arguments
                obj(1,1) LvdViewPlaybackController
                timeLimits(1,2) double
            end
            obj.timeLimits = timeLimits;
            if(all(isfinite(timeLimits)))
                if(isnan(obj.currentTime))
                    obj.currentTime = timeLimits(1);
                else
                    obj.currentTime = min(max(obj.currentTime, timeLimits(1)), timeLimits(2));
                end
            end
        end

        function tf = isPlaying(obj)
            tf = obj.state == "playing";
        end

        function tf = hasTimeRange(obj)
            tf = all(isfinite(obj.timeLimits)) && obj.timeLimits(2) > obj.timeLimits(1);
        end
    end

    methods(Access = private)
        function tick(obj)
            if(not(isvalid(obj)) || obj.state ~= "playing")
                return;
            end
            dt = toc(obj.lastTic);
            obj.lastTic = tic;
            try
                obj.advance(dt);
            catch ME
                obj.haltTimer();
                obj.setState("stopped");
                warning('LvdViewPlaybackController:renderFailed', 'Playback stopped: %s', ME.message);
            end
        end

        function onTimerError(obj, evt)
            try
                obj.haltTimer();
                obj.setState("stopped");
            catch
            end
            try
                warning('LvdViewPlaybackController:timerError', 'Playback timer error: %s', evt.Data.message);
            catch
            end
        end

        function haltTimer(obj)
            if(not(isempty(obj.timerObj)) && isvalid(obj.timerObj))
                try
                    stop(obj.timerObj);
                catch
                end
            end
        end

        function destroyTimer(obj)
            obj.haltTimer();
            if(not(isempty(obj.timerObj)) && isvalid(obj.timerObj))
                try
                    delete(obj.timerObj);
                catch
                end
            end
            obj.timerObj = [];
        end

        function setState(obj, newState)
            if(obj.state ~= newState)
                obj.state = newState;
                notify(obj, 'StateChanged');
            end
        end
    end

    methods(Static)
        function times = frameSchedule(tStart, tEnd, fps, simSecPerRealSec)
            %frameSchedule The frame times a deterministic export renders:
            %tStart : simSecPerRealSec/fps : tEnd, with tEnd appended when
            %the step does not land on it.
            arguments
                tStart(1,1) double
                tEnd(1,1) double
                fps(1,1) double {mustBePositive}
                simSecPerRealSec(1,1) double {mustBePositive}
            end
            if(not(isfinite(tStart)) || not(isfinite(tEnd)) || tEnd <= tStart)
                times = tStart;
                return;
            end
            step = simSecPerRealSec / fps;
            times = tStart:step:tEnd;
            if(abs(times(end) - tEnd) > 1e-9 * max(1, abs(tEnd)))
                times(end+1) = tEnd;
            end
        end

        function ctrl = fromMainApp(lvdData, handles, app)
            %fromMainApp A controller wired to the LVD main window: each frame
            %moves the time slider and renders the scene un-throttled.
            arguments
                lvdData(1,1) LvdData
                handles struct
                app ma_LvdMainGUI_App
            end
            profile = lvdData.viewSettings.selViewProfile;
            profile.ensureF8Defaults();

            slider = app.DispAxesTimeSlider;
            renderFcn = @(t) LvdViewPlaybackController.renderMainAppFrame(t, lvdData, handles, app);

            lims = slider.Limits;
            if(lvdData.stateLog.getNumberOfEntries() == 0)
                lims = [NaN NaN];
            end
            ctrl = LvdViewPlaybackController(profile.playbackSettings, lims, renderFcn);
            ctrl.currentTime = slider.Value;
        end

        function renderMainAppFrame(t, lvdData, handles, app)
            slider = app.DispAxesTimeSlider;
            lims = slider.Limits;
            if(all(isfinite(lims)))
                slider.Value = min(max(t, lims(1)), lims(2));
            end
            lvd_renderSceneAtTime(t, lvdData, handles, app, "full");
        end
    end
end
