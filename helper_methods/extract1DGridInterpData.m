function data = extract1DGridInterpData(gi)
    data = {gi.GridVectors{1}, ...
            gi.Values, ...
            gi.Method};
end