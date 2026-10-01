function obj = lvd_migrateColorProps(s, colorProps)
%lvd_migrateColorProps loadobj helper: legacy ColorSpecEnum -> RGB double.
%   Call from a class's static loadobj as:
%       obj = lvd_migrateColorProps(s, {'lineColor','markerColor'});
%
%   Old .mat files arrive as a struct (MATLAB cannot restore the enum
%   into the new double properties): listed color fields are converted
%   with lvd_colorSpecToRGB and the struct is returned for MATLAB to
%   build the object from (no constructor call needed). New objects pass
%   through with their colors normalized. Fields that fail conversion
%   are left untouched.
%   See also: lvd_colorSpecToRGB, EventColorLineSpec.loadobj.

obj = s;
if(isstruct(s))
    for(k=1:numel(s))
        for(j=1:numel(colorProps))
            p = colorProps{j};
            if(isfield(s(k), p))
                s(k).(p) = lvd_tryColorToRGB(s(k).(p));
            end
        end
    end
    obj = s;
else
    for(k=1:numel(s))
        for(j=1:numel(colorProps))
            p = colorProps{j};
            try
                s(k).(p) = lvd_colorSpecToRGB(s(k).(p));
            catch
            end
        end
    end
    obj = s;
end
end

function rgb = lvd_tryColorToRGB(val)
%lvd_tryColorToRGB lvd_colorSpecToRGB that returns the input on failure.
try
    rgb = lvd_colorSpecToRGB(val);
catch
    rgb = val;
end
end
