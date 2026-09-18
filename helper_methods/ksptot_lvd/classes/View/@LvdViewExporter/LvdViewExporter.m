classdef LvdViewExporter
    %LvdViewExporter Video, animated GIF, still image and clipboard export
    %of the LVD 3-D view.  Stateless; every method is static.
    %
    %   Frames are rendered deterministically (one render per scheduled
    %   time, plain drawnow, then a capture), so the exported video never
    %   depends on how fast the machine happened to be.

    methods(Static)
        function numFrames = exportVideo(filePath, format, fps, quality, times, renderFcn, captureFcn, progressFcn)
            %exportVideo Renders every time in `times` and writes a video.
            %
            %   format      "MPEG-4" | "Motion JPEG AVI" | "GIF"
            %   renderFcn   @(t) renders the scene at t
            %   captureFcn  @() -> H x W x 3 uint8 RGB frame
            %   progressFcn @(k, n) -> true to cancel (optional)
            %
            %   Returns the number of frames written.  On cancel the partial
            %   file is deleted and the count written so far is returned.
            arguments
                filePath(1,:) char
                format(1,1) string
                fps(1,1) double {mustBePositive}
                quality(1,1) double {mustBeInRange(quality, 1, 100)}
                times(1,:) double
                renderFcn(1,1) function_handle
                captureFcn(1,1) function_handle
                progressFcn = []
            end

            if(isempty(times))
                error('LvdViewExporter:noFrames', 'There are no frames to export.');
            end
            format = string(format);
            if(not(ismember(format, LvdViewPlaybackSettings.getVideoFormats())))
                error('LvdViewExporter:badFormat', 'Unknown video format "%s".', format);
            end

            if(isfile(filePath))
                delete(filePath);
            end

            numFrames = 0;
            cancelled = false;
            writer = [];
            firstSize = [];
            cleanup = onCleanup(@() LvdViewExporter.closeWriter(writer)); %#ok<NASGU>

            for k = 1:numel(times)
                if(not(isempty(progressFcn)))
                    if(progressFcn(k, numel(times)))
                        cancelled = true;
                        break;
                    end
                end

                renderFcn(times(k));
                drawnow;
                frame = captureFcn();
                frame = LvdViewExporter.normalizeFrame(frame, firstSize);
                if(isempty(firstSize))
                    firstSize = size(frame);
                end

                switch(format)
                    case "GIF"
                        [ind, cmap] = rgb2ind(frame, 256, 'nodither');
                        if(numFrames == 0)
                            imwrite(ind, cmap, filePath, 'gif', 'LoopCount', Inf, 'DelayTime', 1/fps);
                        else
                            imwrite(ind, cmap, filePath, 'gif', 'WriteMode', 'append', 'DelayTime', 1/fps);
                        end

                    otherwise
                        if(isempty(writer))
                            writer = VideoWriter(filePath, char(format));
                            writer.FrameRate = fps;
                            if(isprop(writer, 'Quality'))
                                writer.Quality = quality;
                            end
                            open(writer);
                            cleanup = onCleanup(@() LvdViewExporter.closeWriter(writer)); %#ok<NASGU>
                        end
                        writeVideo(writer, frame);
                end

                numFrames = numFrames + 1;
            end

            LvdViewExporter.closeWriter(writer);
            writer = []; %#ok<NASGU>

            if(cancelled && isfile(filePath))
                delete(filePath);
            end
        end

        function exportImage(hAx, filePath, dpi)
            %exportImage Writes the axes as a PNG or JPEG at `dpi`.
            arguments
                hAx
                filePath(1,:) char
                dpi(1,1) double {mustBePositive} = 150
            end
            [~, ~, ext] = fileparts(filePath);
            if(not(ismember(lower(ext), {'.png', '.jpg', '.jpeg', '.tif', '.tiff', '.pdf'})))
                error('LvdViewExporter:badImageExt', 'Unsupported image type "%s". Use .png, .jpg, .tif or .pdf.', ext);
            end
            exportgraphics(hAx, filePath, 'Resolution', dpi, 'BackgroundColor', 'current');
        end

        function tf = copyImageToClipboard(hAx)
            %copyImageToClipboard Copies the axes to the system clipboard as
            %an image; false when the clipboard is unavailable (headless).
            tf = false;
            try
                copygraphics(hAx, 'BackgroundColor', 'current');
                tf = true;
            catch
                tf = false;
            end
        end

        function frame = captureAxesFrame(hAx)
            %captureAxesFrame The axes' current pixels as an RGB uint8 image.
            f = getframe(hAx);
            frame = f.cdata;
        end

        function [t0, t1] = exportTimeRange(settings, sliderLimits)
            %exportTimeRange The export window: the settings' start/end, or
            %the slider limits where those are NaN.
            arguments
                settings(1,1) LvdViewPlaybackSettings
                sliderLimits(1,2) double
            end
            t0 = settings.exportStartTime;
            t1 = settings.exportEndTime;
            if(isnan(t0)); t0 = sliderLimits(1); end
            if(isnan(t1)); t1 = sliderLimits(2); end
            if(not(isfinite(t0)) || not(isfinite(t1)))
                error('LvdViewExporter:noTimeRange', 'There is no propagated trajectory to export.');
            end
            if(t1 <= t0)
                error('LvdViewExporter:badTimeRange', 'The export end time must be later than the start time.');
            end
        end

        function frame = normalizeFrame(frame, targetSize)
            %normalizeFrame Even width/height (required by MPEG-4) and, when
            %given, the same size as the first frame.
            if(ndims(frame) == 2) %#ok<ISMAT>
                frame = repmat(frame, 1, 1, 3);
            end
            if(not(isa(frame, 'uint8')))
                frame = im2uint8(frame);
            end
            h = size(frame, 1);
            w = size(frame, 2);
            if(not(isempty(targetSize)))
                th = targetSize(1);
                tw = targetSize(2);
                if(h < th || w < tw)
                    padded = zeros(max(h,th), max(w,tw), 3, 'uint8');
                    padded(1:h, 1:w, :) = frame;
                    frame = padded;
                end
                frame = frame(1:th, 1:tw, :);
            else
                frame = frame(1:2*floor(h/2), 1:2*floor(w/2), :);
            end
        end
    end

    methods(Static, Access = private)
        function closeWriter(writer)
            if(not(isempty(writer)))
                try
                    close(writer);
                catch
                end
            end
        end
    end
end
