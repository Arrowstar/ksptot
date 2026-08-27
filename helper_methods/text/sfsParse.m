function rootNode = sfsParse(source)
%sfsParse Parses KSP SFS/config-node format text into a nested MATLAB struct.
%
%   node = sfsParse(filePath) parses the SFS file at filePath.
%   node = sfsParse(textStr) parses raw SFS text content.
%
%   The returned struct maps each key or child-node name to a field:
%       - Simple keys ("key = value") become char fields holding the raw
%         trimmed value string.
%       - Repeated simple keys become cellstr fields, in order of
%         appearance.
%       - Child node blocks ("NAME { ... }") become cell arrays of
%         recursively-parsed node structs, in order of appearance. Empty
%         blocks produce a 1x1 cell containing an empty struct.
%   Values are returned as raw strings; callers convert to numeric types
%   as needed (e.g., str2double/textscan).
%
%   Comments starting with "//" (outside quoted strings) are ignored.
%   Quoted values have their surrounding quotes stripped.

    if(ischar(source) && isfile(source))
        textStr = fileread(source);
    else
        textStr = source;
    end

    % Strip UTF-8 BOM (EF BB BF) which appears as char 65279 or as three
    % bytes 239/187/191 depending on how fileread decodes it. Without this
    % the first PART node becomes '_PART' and is rejected as an invalid
    % field name, causing every GameData file to be skipped.
    if(~isempty(textStr))
        if(double(textStr(1)) == 65279)
            textStr = textStr(2:end);
        elseif(numel(textStr) >= 3 && isequal(double(textStr(1:3)), [239 187 191]))
            textStr = textStr(4:end);
        end
    end

    lines = splitLines(stripComments(textStr));

    cursor = 1;
    rootNode = parseNodeBody(lines, cursor);
    rootNode = rootNode.value;

end

function result = parseNodeBody(lines, startPos)
%parseNodeBody Recursively parses lines into a node struct until a closing
%brace or end of input is reached.
%
% Returns struct with fields:
%   value   - parsed node struct
%   nextPos - index of the first unconsumed line

    node = struct();
    pos = startPos;

    while(pos <= numel(lines))
        line = strtrim(lines{pos});
        pos = pos + 1;

        if(isempty(line))
            continue;
        elseif(startsWith(line, '}'))
            break;
        end

        % Try "key = value" assignment.
        [key, value] = tryExtractKeyValue(line);
        if(~isempty(key))
            if(~isfield(node, key))
                node.(key) = value;
            else
                existingVal = node.(key);
                if(ischar(existingVal))
                    node.(key) = {existingVal, value};
                elseif(iscellstr(existingVal))
                    node.(key) = {existingVal{:}, value};
                end
            end
            continue;
        end

        % Try "NAME {" child-node opener. The brace may sit on the same
        % line or alone on the following line(s).
        [nodeName, openerPos] = findNodeOpener(lines, pos - 1);
        if(~isempty(nodeName))
            [childResult] = parseNodeBody(lines, openerPos + 1);
            childNode = childResult.value;
            pos = childResult.nextPos;

            nodeName = sanitizeFieldName(nodeName);

            if(~isfield(node, nodeName))
                node.(nodeName) = {childNode};
            else
                existingNodes = node.(nodeName);
                existingNodes{end+1} = childNode; %#ok<AGROW>
                node.(nodeName) = existingNodes;
            end
            continue;
        end

        % Unrecognized line: skip silently (stray braces, tokens).
    end

    result = struct('value', node, 'nextPos', pos);

end

function [key, value] = tryExtractKeyValue(line)
%tryExtractKeyValue If the line is a "key = value" assignment, returns the
%sanitized key and cleaned value. Otherwise returns empty key.

    key = '';
    value = '';

    eqInd = find(line == '=', 1, 'first');
    if(isempty(eqInd))
        return;
    end

    candidate = strtrim(line(1:eqInd-1));
    if(isempty(candidate) || any(ismember(candidate, ' {}"')))
        return;
    end

    value = strtrim(line(eqInd+1:end));
    if(startsWith(value, '"') && endsWith(value, '"') && numel(value) >= 2)
        value = value(2:end-1);
    end

    key = sanitizeFieldName(candidate);

end

function [nodeName, openerPos] = findNodeOpener(lines, currentPos)
%findNodeOpener Checks whether the line at currentPos (1-based) opens a
%child-node block. Returns the node name ('' if not a node opener) and the
%position of the line containing the opening brace.
%
% Accepted layouts:
%   "NAME {"          brace on the same line
%   "NAME"            bare name, with "{" alone (or after blank lines) on
%   "{"               one or more following lines
% A bare name is only accepted if the next non-blank line starts with "{";
% otherwise it is treated as an unrecognized line.

    nodeName = '';
    openerPos = currentPos;

    if(currentPos > numel(lines))
        return;
    end

    line = strtrim(lines{currentPos});

    braceInd = find(line == '{', 1, 'first');
    if(~isempty(braceInd))
        candidate = strtrim(line(1:braceInd-1));
        if(isempty(candidate) || any(ismember(candidate, ' ="')))
            return;
        end
        nodeName = candidate;
        openerPos = currentPos;
        return;
    end

    % No same-line brace: accept only a clean bare token.
    if(isempty(line) || any(ismember(line, ' ="{}')))
        return;
    end

    % Look ahead: next non-blank line must start with "{".
    scan = currentPos + 1;
    while(scan <= numel(lines))
        nextLine = strtrim(lines{scan});
        if(isempty(nextLine))
            scan = scan + 1;
            continue;
        end

        if(startsWith(nextLine, '{'))
            nodeName = line;
            openerPos = scan;
        end
        return;
    end

end

function nameOut = sanitizeFieldName(nameIn)
%sanitizeFieldName Makes a string safe for use as a dynamic struct field.

    nameOut = regexprep(nameIn, '[^A-Za-z0-9_]', '_');

    if(isempty(nameOut) || iskeyword(nameOut) || ~isletter(nameOut(1)))
        nameOut = ['x' nameOut];
    end

end

function lines = splitLines(textStr)
%splitLines Splits text into lines, handling Windows/Unix/Mac endings.
%
% Uses explicit char codes rather than escape sequences so behavior does
% not depend on how strsplit/strrep interpret backslash sequences.

    crChar = char(13);
    lfChar = char(10);

    textStr = strrep(textStr, [crChar, lfChar], lfChar);
    textStr = strrep(textStr, crChar, lfChar);

    lines = strsplit(textStr, lfChar);

end

function outText = stripComments(textStr)
%stripComments Removes "//" comments that are not inside quoted strings,
%line by line, preserving everything before the comment start.

    segments = regexp(textStr, '(?s)(.*?)(\n|\Z)', 'match');
    outParts = cell(size(segments));

    for(i = 1:numel(segments))
        seg = segments{i};
        nlChar = '';
        if(~isempty(seg) && seg(end) == newline)
            nlChar = seg(end);
            seg = seg(1:end-1);
        end

        seg = stripCommentFromLine(seg);

        outParts{i} = [seg, nlChar]; %#ok<AGROW>
    end

    outText = [outParts{:}];

end

function outLine = stripCommentFromLine(inLine)
%stripCommentFromLine Trims a single line at the first "//" outside quotes.

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
