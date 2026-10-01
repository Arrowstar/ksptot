function bgColorRgb = lvd_bestGreyBackgroundColor(colors)
%lvd_bestGreyBackgroundColor Grey background most distinct from all colors.
%   colors is an Nx3 RGB double. Same largest-gap algorithm as the legacy
%   ColorSpecEnum.getBestGreyBackgroundColor, but without the enum.
%   See also: lvd_colorSpecToRGB.

if(isempty(colors))
    bgColorRgb = [0, 0, 0];
    return;
end

cHSV = rgb2hsv(double(colors));
origValues = cHSV(:,3);
values = unique(sort([0; origValues(:); 1]));
valueDiffs = diff(values);
[~, I] = max(valueDiffs);

if(I == 1 && not(ismember(0, origValues)))
    useThisValue = 0;
elseif(I == numel(valueDiffs) && not(ismember(1, origValues)))
    useThisValue = 1;
else
    useThisValue = mean([values(I), values(I+1)]);
end

bgColorRgb = hsv2rgb([0, 0, useThisValue]);
end
