function obj = lvd_copyMigratedProps(obj, s, colorProps)
%lvd_copyMigratedProps Copies a saved struct over a fresh object.
%   Used by static loadobj methods of classes whose constructors require
%   arguments (so the struct-return migration path is unavailable): the
%   caller constructs with saved (or dummy) arguments, then this copies
%   every saved field over, converting the listed color fields from legacy
%   ColorSpecEnum to RGB with lvd_colorSpecToRGB. Unknown or failing fields
%   keep the freshly constructed values.
%   See also: lvd_migrateColorProps.

fields = fieldnames(s);
for(i=1:numel(fields))
    p = fields{i};
    if(ismember(p, colorProps))
        try
            obj.(p) = lvd_colorSpecToRGB(s.(p));
        catch
        end
    else
        try
            obj.(p) = s.(p);
        catch
        end
    end
end
end
