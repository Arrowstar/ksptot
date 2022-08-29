function out = grammaticalList(strs)
    %takes a cell array of strings and concatenates them with punctuation, ie.
    %first, second, third, and last.  Oxford comma.
    if isempty(strs)
        out = '';
        return
    elseif length(strs)==1
        out = strs{1};
        return
    elseif size(strs,2)>1
        strs = reshape(strs,[],1);
    end
    punct = [repmat({', '},length(strs)-2,1); {' and '}; {''}];
    strings = strcat(strs,punct);
    out = [strings{:}];
end