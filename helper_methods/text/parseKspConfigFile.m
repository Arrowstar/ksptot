function finalStruct = parseKspConfigFile(fileTxt)
    pos1 = strfind(fileTxt,'{');
    
    pairs = NaN(length(pos1),2);
    for(i=1:length(pos1))
        pos2 = getbracketpairpos(fileTxt,pos1(i));
        pairs(i,:) = [pos1(i), pos2];
    end
    
    structs = {};
    structsStartEnd = [];
    for(i=1:size(pairs,1))
        pair = pairs(i,:);
        
        internalPairs = pairs(pairs(:,1) > pair(1) & pairs(:,2) < pair(2),:);
        
        if(not(isempty(internalPairs)))
            endInd = min(internalPairs(:,1));
        else
            endInd = pair(2)-1;
        end
        startInd = pair(1)+1;
        subText = fileTxt(startInd:endInd);
        
        priorText = fileTxt(1:pair(1)-1);
        tokens = regexp(priorText,'(\S)+\s*$','tokens');
        if(not(isempty(tokens)))
            className = matlab.lang.makeValidName(tokens{1}{1});
        else
            className = '';
        end
        
        subTextLines = strtrim(strsplit(subText,'\n'));
        s = struct('ClassName',className);
        for(j=1:length(subTextLines))
            line = subTextLines{j};
            tokens = regexp(line,'(\w+)\s*\=\s*([ \S]+)','tokens');
            
            if(not(isempty(tokens)))
                token = tokens{1};
                name = matlab.lang.makeValidName(token{1});
                data = token{2};
                
                if(isfield(s,name))
                    if(not(iscell(s.(name))))
                        s.(name) = {s.(name)};
                    end
                    s.(name){end+1} = data;
                else
                    s.(name) = data;
                end
            end
        end
        
        if(not(isempty(fields(s))))
            structs{end+1} = s; %#ok<AGROW>
            structsStartEnd(end+1,:) = pair; %#ok<AGROW>
        end
    end
    
    width = structsStartEnd(:,2) - structsStartEnd(:,1);
    [~,I] = sort(width);
    structsStartEnd = structsStartEnd(I,:);
    structs = structs(I);
    
    for(i=1:length(structsStartEnd))
        structStartEnd = structsStartEnd(i,:);
        
        greaterStructs = structsStartEnd(structsStartEnd(:,1) < structStartEnd(1) & ...
                                         structsStartEnd(:,2) > structStartEnd(2), :);
                                     
        if(not(isempty(greaterStructs)))
            [~,I] = min(greaterStructs(:,2) - greaterStructs(:,1));
            greaterStruct = greaterStructs(I,:);
            
            [~, index] = ismember(greaterStruct, structsStartEnd, 'rows');
            
            if(not(isfield(structs{index},structs{i}.ClassName)))
                structs{index}.(structs{i}.ClassName) = structs{i};
            else
                if(not(iscell(structs{index}.(structs{i}.ClassName))))
                    structs{index}.(structs{i}.ClassName) = {structs{index}.(structs{i}.ClassName)};
                end
                
                structs{index}.(structs{i}.ClassName){end+1} = structs{i};
            end
        end
    end
    
    finalStruct = structs{end};
end