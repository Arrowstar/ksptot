function [locMap, warnings] = lvd_import_loadLocalization(source, langTag)
%lvd_import_loadLocalization Builds a KSP localization tag -> text lookup.
%
%   locMap = lvd_import_loadLocalization(source) scans KSP localization
%   dictionaries and returns a containers.Map from lower-cased tag
%   (e.g. '#autoloc_500439') to the localized display string
%   (e.g. 'LV-T30 "Reliant" Liquid Fuel Engine').
%
%   SOURCE may be:
%       - a GameData (or KSP root) folder, scanned recursively for
%         Localization/*.cfg dictionaries
%       - a single .cfg dictionary path
%       - a cellstr of .cfg dictionary paths
%
%   langTag selects the language block inside each dictionary and defaults
%   to 'en-us'. When a dictionary has no block for langTag, 'en-us' is
%   tried, then the first language block present.
%
%   [locMap, warnings] = ... also returns a cellstr of non-fatal issues.
%
%   KSP dictionaries look like:
%       Localization
%       {
%           en-us
%           {
%               #autoLOC_500439 = LV-T30 "Reliant" Liquid Fuel Engine
%           }
%       }

    warnings = {};

    if(nargin < 2 || isempty(langTag))
        langTag = 'en-us';
    end

    locMap = containers.Map('KeyType', 'char', 'ValueType', 'char');

    files = resolveDictionaryFiles(source);

    for(i = 1:numel(files))
        try
            entries = parseLocalizationFile(files{i}, langTag);
        catch ME
            warnings{end+1} = sprintf('Skipping localization file %s: %s', ...
                files{i}, ME.message); %#ok<AGROW>
            continue;
        end

        entryKeys = keys(entries);
        for(j = 1:numel(entryKeys))
            if(~isKey(locMap, entryKeys{j}))
                locMap(entryKeys{j}) = entries(entryKeys{j});
            end
        end
    end

end

function files = resolveDictionaryFiles(source)
%resolveDictionaryFiles Normalizes SOURCE into a cellstr of .cfg paths.

    files = {};

    if(iscellstr(source)) %#ok<ISCLSTR>
        files = source(:)';
        return;
    end

    if(~ischar(source) || isempty(source))
        return;
    end

    if(isfile(source))
        files = {source};
        return;
    end

    if(~isfolder(source))
        return;
    end

    root = source;
    if(isfolder(fullfile(root, 'GameData')))
        root = fullfile(root, 'GameData');
    end

    files = findDictionariesRecursive(root);

end

function files = findDictionariesRecursive(root)
%findDictionariesRecursive Finds localization .cfg files under ROOT.

    files = {};

    entries = dir(root);
    for(i = 1:numel(entries))
        name = entries(i).name;
        if(strcmp(name, '.') || strcmp(name, '..'))
            continue;
        end

        full = fullfile(root, name);
        if(entries(i).isdir)
            files = [files, findDictionariesRecursive(full)]; %#ok<AGROW>
        elseif(lvd_import_isLocalizationCfg(full))
            files{end+1} = full; %#ok<AGROW>
        end
    end

end

function entries = parseLocalizationFile(filePath, langTag)
%parseLocalizationFile Extracts one language block from a dictionary file.

    entries = containers.Map('KeyType', 'char', 'ValueType', 'char');

    txt = fileread(filePath);
    txt = stripBom(txt);

    if(isempty(txt) || isempty(strfind(lower(txt), 'localization'))) %#ok<STREMP>
        return;
    end

    lines = regexp(txt, '\r\n|\r|\n', 'split');

    % Language blocks encountered in this file, keyed by lower-cased tag.
    byLang = containers.Map('KeyType', 'char', 'ValueType', 'any');
    langOrder = {};

    stack = {};
    pendingName = '';

    for(i = 1:numel(lines))
        line = strtrim(stripInlineComment(lines{i}));
        if(isempty(line))
            continue;
        end

        [key, value, isAssignment] = splitAssignment(line);
        if(isAssignment)
            if(numel(stack) == 2 && strcmpi(stack{1}, 'Localization'))
                lang = lower(stack{2});
                if(~isKey(byLang, lang))
                    byLang(lang) = containers.Map('KeyType', 'char', 'ValueType', 'char');
                    langOrder{end+1} = lang; %#ok<AGROW>
                end
                langMap = byLang(lang);
                mapKey = lower(key);
                if(~isKey(langMap, mapKey))
                    langMap(mapKey) = unescapeLocValue(value);
                end
            end
            pendingName = '';
            continue;
        end

        % Structural line: a node name, an opening brace, or a closing brace.
        braceInd = find(line == '{', 1, 'first');
        if(~isempty(braceInd))
            candidate = strtrim(line(1:braceInd-1));
            if(isempty(candidate))
                candidate = pendingName;
            end
            stack{end+1} = candidate; %#ok<AGROW>
            pendingName = '';
            continue;
        end

        if(startsWith(line, '}'))
            if(~isempty(stack))
                stack(end) = [];
            end
            pendingName = '';
            continue;
        end

        pendingName = line;
    end

    if(byLang.Count == 0)
        return;
    end

    wanted = lower(langTag);
    if(isKey(byLang, wanted))
        entries = byLang(wanted);
    elseif(isKey(byLang, 'en-us'))
        entries = byLang('en-us');
    else
        entries = byLang(langOrder{1});
    end

end

function [key, value, isAssignment] = splitAssignment(line)
%splitAssignment Recognizes a "key = value" line, mirroring sfsParse rules.

    key = '';
    value = '';
    isAssignment = false;

    eqInd = find(line == '=', 1, 'first');
    if(isempty(eqInd))
        return;
    end

    candidate = strtrim(line(1:eqInd-1));
    if(isempty(candidate) || any(ismember(candidate, ' {}"')))
        return;
    end

    key = candidate;
    value = strtrim(line(eqInd+1:end));
    isAssignment = true;

end

function outLine = stripInlineComment(inLine)
%stripInlineComment Trims a line at the first "//" outside double quotes.

    outLine = inLine;
    quoteOpen = false;

    j = 1;
    while(j <= numel(outLine) - 1)
        ch = outLine(j);
        if(ch == '"')
            quoteOpen = ~quoteOpen;
            j = j + 1;
        elseif(~quoteOpen && ch == '/' && outLine(j+1) == '/')
            outLine = outLine(1:j-1);
            return;
        else
            j = j + 1;
        end
    end

end

function val = unescapeLocValue(val)
%unescapeLocValue Strips wrapping quotes and expands KSP escape sequences.

    if(numel(val) >= 2 && val(1) == '"' && val(end) == '"')
        val = val(2:end-1);
    end

    if(isempty(strfind(val, '\'))) %#ok<STREMP>
        return;
    end

    % Guard real backslashes before expanding \n and \t.
    sentinel = char(1);
    val = strrep(val, '\\', sentinel);
    val = strrep(val, '\n', newline);
    val = strrep(val, '\t', sprintf('\t'));
    val = strrep(val, sentinel, '\');

end

function txt = stripBom(txt)
%stripBom Removes a UTF-8 BOM however fileread decoded it.

    if(isempty(txt))
        return;
    end

    if(double(txt(1)) == 65279)
        txt = txt(2:end);
    elseif(numel(txt) >= 3 && isequal(double(txt(1:3)), [239 187 191]))
        txt = txt(4:end);
    end

end
