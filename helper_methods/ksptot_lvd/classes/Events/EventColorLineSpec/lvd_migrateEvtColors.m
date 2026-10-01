function evtColors = lvd_migrateEvtColors(val)
%lvd_migrateEvtColors Normalizes stored per-event colors to an Nx3 RGB double.
%   Accepts a legacy ColorSpecEnum array, a struct array with a color
%   field (old .mat files), or an Nx3 RGB double (passed through).
%   See also: lvd_colorSpecToRGB.

if(isempty(val))
    evtColors = zeros(0,3);
elseif(isa(val, 'ColorSpecEnum'))
    evtColors = double(vertcat(val.color));
elseif(isstruct(val) && isfield(val, 'color'))
    n = numel(val);
    evtColors = zeros(n,3);
    for(i=1:n)
        evtColors(i,:) = lvd_colorSpecToRGB(val(i).color);
    end
elseif(isnumeric(val) && size(val,2) == 3 && all(isfinite(val(:))) && all(val(:) >= 0) && all(val(:) <= 1))
    evtColors = double(val);
else
    error('lvd_migrateEvtColors:invalid', 'Cannot interpret stored event colors of class %s.', class(val));
end
end
