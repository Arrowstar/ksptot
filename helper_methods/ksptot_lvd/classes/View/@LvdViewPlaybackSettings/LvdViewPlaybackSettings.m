classdef LvdViewPlaybackSettings < matlab.mixin.SetGet
    %LvdViewPlaybackSettings Playback and export preferences of an LVD view
    %profile (frame rate, time warp, looping, video/image formats).

    properties
        fps(1,1) double {mustBePositive} = 30;
        simSecPerRealSec(1,1) double {mustBePositive} = 60;
        loop(1,1) logical = false;

        videoFormat(1,1) string {mustBeMember(videoFormat, ["MPEG-4", "Motion JPEG AVI", "GIF"])} = "MPEG-4";
        videoQuality(1,1) double {mustBeInRange(videoQuality, 1, 100)} = 90;
        imageDpi(1,1) double {mustBePositive} = 150;

        exportStartTime(1,1) double = NaN;   %NaN = slider start
        exportEndTime(1,1) double = NaN;     %NaN = slider end
    end

    methods
        function obj = LvdViewPlaybackSettings()

        end

        function ext = getVideoExtension(obj)
            ext = LvdViewPlaybackSettings.extensionForFormat(obj.videoFormat);
        end

        function newObj = copyForExport(obj)
            %copyForExport An independent copy, so per-call overrides do not
            %change the saved settings.
            newObj = LvdViewPlaybackSettings();
            props = properties(obj);
            for(i=1:numel(props))
                newObj.(props{i}) = obj.(props{i});
            end
        end
    end

    methods(Static)
        function formats = getVideoFormats()
            formats = ["MPEG-4", "Motion JPEG AVI", "GIF"];
        end

        function ext = extensionForFormat(format)
            switch(string(format))
                case "MPEG-4"
                    ext = '.mp4';
                case "Motion JPEG AVI"
                    ext = '.avi';
                case "GIF"
                    ext = '.gif';
                otherwise
                    error('LvdViewPlaybackSettings:badFormat', 'Unknown video format "%s".', format);
            end
        end

        function obj = loadobj(obj)
            if(isstruct(obj))
                s = obj;
                obj = LvdViewPlaybackSettings();
                props = properties(obj);
                for(i=1:numel(props)) %#ok<*NO4LP>
                    if(isfield(s, props{i}))
                        try
                            obj.(props{i}) = s.(props{i});
                        catch
                        end
                    end
                end
            end
        end
    end
end
