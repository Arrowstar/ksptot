classdef ViewExporterTest < KsptotTestCase
    %ViewExporterTest LvdViewExporter (F8 export): frame-exact video
    %(Motion JPEG AVI, MPEG-4), animated GIF, cancellation, still images and
    %the export time range, against a stand-in uifigure/uiaxes whose
    %render callback moves a line.

    methods(Test)

        function motionJpegAviHasOneFramePerScheduledTime(testCase)
            testCase.assumeVideoProfile('Motion JPEG AVI');
            [renderFcn, captureFcn, rec] = testCase.standInScene();
            filePath = [tempname(), '.avi'];
            cleanup = onCleanup(@() deleteIfExists(filePath)); %#ok<NASGU>

            times = 0:0.5:2;   % 5 frames
            n = LvdViewExporter.exportVideo(filePath, "Motion JPEG AVI", 4, 80, times, renderFcn, captureFcn);

            testCase.verifyEqual(n, 5);
            testCase.verifyEqual(rec.times, times, 'Every scheduled time was rendered, in order');
            testCase.assertTrue(isfile(filePath));

            v = VideoReader(filePath);
            testCase.verifyEqual(v.FrameRate, 4, 'AbsTol', 1e-9);
            testCase.verifyEqual(testCase.countFrames(v), 5, 'One video frame per scheduled time');
            testCase.verifyEqual(mod(v.Width, 2), 0, 'Even width');
            testCase.verifyEqual(mod(v.Height, 2), 0, 'Even height');
            delete(v);   %release the file before the cleanup deletes it
        end

        function mpeg4Writes(testCase)
            testCase.assumeVideoProfile('MPEG-4');
            [renderFcn, captureFcn] = testCase.standInScene();
            filePath = [tempname(), '.mp4'];
            cleanup = onCleanup(@() deleteIfExists(filePath)); %#ok<NASGU>

            times = linspace(0, 1, 6);
            n = LvdViewExporter.exportVideo(filePath, "MPEG-4", 6, 90, times, renderFcn, captureFcn);
            testCase.verifyEqual(n, 6);
            testCase.assertTrue(isfile(filePath));

            v = VideoReader(filePath);
            testCase.verifyGreaterThanOrEqual(testCase.countFrames(v), 5, 'H.264 may drop at most one frame at the tail');
            delete(v);   %release the file before the cleanup deletes it
        end

        function gifHasOneImagePerFrameAndLoops(testCase)
            [renderFcn, captureFcn] = testCase.standInScene();
            filePath = [tempname(), '.gif'];
            cleanup = onCleanup(@() deleteIfExists(filePath)); %#ok<NASGU>

            times = 0:0.25:1;   % 5 frames
            n = LvdViewExporter.exportVideo(filePath, "GIF", 8, 90, times, renderFcn, captureFcn);
            testCase.verifyEqual(n, 5);

            info = imfinfo(filePath);
            testCase.verifyNumElements(info, 5, 'One GIF image per frame');
            testCase.verifyEqual(info(1).DelayTime, 100/8, 'AbsTol', 1, 'Delay in 1/100 s matches the frame rate');
        end

        function cancelStopsEarlyAndRemovesThePartialFile(testCase)
            testCase.assumeVideoProfile('Motion JPEG AVI');
            [renderFcn, captureFcn, rec] = testCase.standInScene();
            filePath = [tempname(), '.avi'];
            cleanup = onCleanup(@() deleteIfExists(filePath)); %#ok<NASGU>

            progressFcn = @(k, n) k == 3;   % cancel when asked to render frame 3
            n = LvdViewExporter.exportVideo(filePath, "Motion JPEG AVI", 4, 80, 0:0.5:4, renderFcn, captureFcn, progressFcn);

            testCase.verifyEqual(n, 2, 'Two frames were written before the cancel');
            testCase.verifyEqual(numel(rec.times), 2);
            testCase.verifyFalse(isfile(filePath), 'The partial file is removed on cancel');
        end

        function progressCallbackSeesEveryFrame(testCase)
            [renderFcn, captureFcn] = testCase.standInScene();
            filePath = [tempname(), '.gif'];
            cleanup = onCleanup(@() deleteIfExists(filePath)); %#ok<NASGU>
            seen = CallRecorder();
            progressFcn = @(k, n) recordAndContinue(seen, k, n);
            LvdViewExporter.exportVideo(filePath, "GIF", 10, 90, [0 1 2], renderFcn, captureFcn, progressFcn);
            testCase.verifyEqual(seen.calls, {{1 3}, {2 3}, {3 3}});
        end

        function badInputsError(testCase)
            [renderFcn, captureFcn] = testCase.standInScene();
            testCase.verifyError(@() LvdViewExporter.exportVideo([tempname() '.avi'], "Motion JPEG AVI", 4, 80, [], renderFcn, captureFcn), ...
                'LvdViewExporter:noFrames');
            testCase.verifyError(@() LvdViewExporter.exportVideo([tempname() '.xyz'], "Betamax", 4, 80, [0 1], renderFcn, captureFcn), ...
                'LvdViewExporter:badFormat');
        end

        function stillImagesAreWrittenInPngAndJpg(testCase)
            [hFig, hAx] = testCase.standInFigure();
            cleanupFig = onCleanup(@() delete(hFig)); %#ok<NASGU>

            pngPath = [tempname(), '.png'];
            jpgPath = [tempname(), '.jpg'];
            cleanup = onCleanup(@() cellfun(@deleteIfExists, {pngPath, jpgPath})); %#ok<NASGU>

            LvdViewExporter.exportImage(hAx, pngPath, 96);
            LvdViewExporter.exportImage(hAx, jpgPath, 72);

            infoPng = imfinfo(pngPath);
            infoJpg = imfinfo(jpgPath);
            testCase.verifyEqual(infoPng.Format, 'png');
            testCase.verifyGreaterThan(infoPng.Width, 0);
            testCase.verifyEqual(infoJpg.Format, 'jpg');
            testCase.verifyGreaterThan(infoJpg.Height, 0);

            testCase.verifyError(@() LvdViewExporter.exportImage(hAx, [tempname(), '.bmp'], 96), 'LvdViewExporter:badImageExt');
        end

        function clipboardCopyReturnsALogical(testCase)
            [hFig, hAx] = testCase.standInFigure();
            cleanupFig = onCleanup(@() delete(hFig)); %#ok<NASGU>
            tf = LvdViewExporter.copyImageToClipboard(hAx);
            testCase.verifyClass(tf, 'logical');
        end

        function captureAxesFrameIsRgbUint8(testCase)
            [hFig, hAx] = testCase.standInFigure();
            cleanupFig = onCleanup(@() delete(hFig)); %#ok<NASGU>
            frame = LvdViewExporter.captureAxesFrame(hAx);
            testCase.verifyClass(frame, 'uint8');
            testCase.verifyEqual(size(frame, 3), 3);
            testCase.verifyGreaterThan(size(frame, 1), 10);
        end

        function normalizeFrameEvensAndMatchesTheFirstFrame(testCase)
            odd = uint8(randi(255, 11, 13, 3));
            f1 = LvdViewExporter.normalizeFrame(odd, []);
            testCase.verifySize(f1, [10 12 3]);

            bigger = uint8(randi(255, 20, 20, 3));
            f2 = LvdViewExporter.normalizeFrame(bigger, size(f1));
            testCase.verifySize(f2, [10 12 3], 'Cropped to the first frame');

            smaller = uint8(randi(255, 4, 5, 3));
            f3 = LvdViewExporter.normalizeFrame(smaller, size(f1));
            testCase.verifySize(f3, [10 12 3], 'Padded to the first frame');
            testCase.verifyEqual(f3(1:4, 1:5, :), smaller);

            gray = uint8(randi(255, 8, 8));
            f4 = LvdViewExporter.normalizeFrame(gray, []);
            testCase.verifySize(f4, [8 8 3], 'Grayscale is expanded to RGB');
        end

        function exportTimeRangeUsesTheSliderForNaNs(testCase)
            s = LvdViewPlaybackSettings();
            [t0, t1] = LvdViewExporter.exportTimeRange(s, [100 200]);
            testCase.verifyEqual([t0 t1], [100 200]);

            s.exportStartTime = 120;
            [t0, t1] = LvdViewExporter.exportTimeRange(s, [100 200]);
            testCase.verifyEqual([t0 t1], [120 200]);

            s.exportEndTime = 110;
            testCase.verifyError(@() LvdViewExporter.exportTimeRange(s, [100 200]), 'LvdViewExporter:badTimeRange');

            s2 = LvdViewPlaybackSettings();
            testCase.verifyError(@() LvdViewExporter.exportTimeRange(s2, [NaN NaN]), 'LvdViewExporter:noTimeRange');
        end
    end

    methods(Access = private)
        function [hFig, hAx, hLine] = standInFigure(~)
            hFig = uifigure('Visible', 'off');
            hFig.Position(3:4) = [320 240];
            hAx = uiaxes(hFig);
            hAx.Position = [10 10 300 220];
            hLine = plot3(hAx, [0 1], [0 1], [0 0], 'LineWidth', 3);
            hAx.XLim = [0 1]; hAx.YLim = [0 1]; hAx.ZLim = [-1 3];
            view(hAx, 3);
            drawnow;
        end

        function [renderFcn, captureFcn, rec] = standInScene(testCase)
            [hFig, hAx, hLine] = testCase.standInFigure();
            testCase.addTeardown(@() delete(hFig));
            rec = RenderRecorder();
            renderFcn = @(t) renderStandIn(rec, hLine, t);
            captureFcn = @() LvdViewExporter.captureAxesFrame(hAx);
        end

        function assumeVideoProfile(testCase, name)
            profiles = VideoWriter.getProfiles();
            testCase.assumeTrue(any(strcmp({profiles.Name}, name)), ...
                sprintf('VideoWriter profile "%s" is not available on this machine.', name));
        end

        function n = countFrames(~, v)
            n = 0;
            while(hasFrame(v))
                readFrame(v);
                n = n + 1;
            end
        end
    end
end

function renderStandIn(rec, hLine, t)
    rec.record(t);
    hLine.ZData = [t t];
end

function tf = recordAndContinue(rec, k, n)
    rec.record(k, n);
    tf = false;
end

function deleteIfExists(filePath)
    if(isfile(filePath))
        delete(filePath);
    end
end
