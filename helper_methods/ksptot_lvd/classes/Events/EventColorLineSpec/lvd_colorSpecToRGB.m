function rgb = lvd_colorSpecToRGB(val)
%lvd_colorSpecToRGB Tolerant converter to a 1x3 RGB double in [0,1].
%   Accepts a 1x3 RGB double (passed through, validated), a legacy
%   ColorSpecEnum member (unwrapped via .color), or a struct with a color
%   field (as found in old .mat files). Anything else throws.
%   See also: lvd_defaultEventPalette, EventColorLineSpec.

if(isa(val, 'ColorSpecEnum'))
    rgb = double(val.color);
elseif(isstruct(val) && isfield(val, 'color'))
    rgb = lvd_colorSpecToRGB(val.color);
elseif(isnumeric(val) && isequal(size(val), [1,3]) && all(isfinite(val(:))) && all(val(:) >= 0) && all(val(:) <= 1))
    rgb = double(reshape(val, 1, 3));
else
    error('lvd_colorSpecToRGB:invalid', 'Expected a 1x3 RGB double in [0,1] or a legacy ColorSpecEnum; got %s.', class(val));
end
end
