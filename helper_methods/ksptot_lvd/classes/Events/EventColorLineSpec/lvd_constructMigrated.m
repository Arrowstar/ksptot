function obj = lvd_constructMigrated(className, ctorFields, s, colorProps)
%lvd_constructMigrated loadobj helper for classes with required ctor args.
%   Old .mat files arrive as a struct (MATLAB cannot restore legacy
%   ColorSpecEnum values into the new RGB double properties): the object
%   is rebuilt with the real constructor using saved values, then every
%   saved field is copied over with color fields converted to RGB (see
%   lvd_copyMigratedProps). Nested objects arrive already resolved.
%   New objects pass through with colors normalized.
%
%   Call from a static loadobj as:
%       obj = lvd_constructMigrated('UnitVector', {'vector','name','lvdData'}, s, {'lineColor'});
%   See also: lvd_migrateColorProps, lvd_copyMigratedProps.

if(isstruct(s))
    args = cell(1, numel(ctorFields));
    for(k=1:numel(ctorFields))
        args{k} = s.(ctorFields{k});
    end
    obj = feval(className, args{:});
    obj = lvd_copyMigratedProps(obj, s, colorProps);
else
    obj = lvd_migrateColorProps(s, colorProps);
end
end
