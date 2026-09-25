function keep = lvd_filterListboxItems(query, items, extraText)
arguments
    query = ''
    items(1,:) cell = {}
    extraText(1,:) cell = {}
end

query = strtrim(char(string(query)));
if isempty(query)
    keep = true(size(items));
    return
end

corpus = string(items(:));
if not(isempty(extraText))
    extraText = string(extraText(:));
    if isscalar(extraText)
        extraText = repmat(extraText, size(corpus));
    end
    corpus = corpus + " " + extraText;
end

keep = reshape(contains(lower(corpus), lower(string(query))), size(items));
end
