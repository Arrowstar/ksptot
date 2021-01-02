function hrOut = getLVD_HR(hText)
%getMA_HR Summary of this function goes here
%   Detailed explanation goes here

%     hr = '#############################################################################################';
    hr = {repmat('# ',1,250)};
    hrOut = textwrap(hText,hr);
    hrOut = strtrim(hrOut{1});
    hrOut = strrep(hrOut,' ','#');
    hrOut = hrOut(1:end-4);
end