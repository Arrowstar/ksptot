function parseSFSForMasses(filePath)
%parseSFSForOrbits Summary of this function goes here
%   Detailed explanation goes here

    vesselExp = 'VESSEL\n[\t]+\{.*?\}';
    
    fid = fopen(filePath);
    C = textscan(fid,'%s','Delimiter','\n');
    C = C{1};
    
    numParen = 0;
    dataBorders = zeros(0,3);
    for(i=1:length(C)) %#ok<NO4LP>
        line = C{i};
        
        %start of new block
        if(strcmpi(line,'{'))
            numParen = numParen + 1;
            dataBorders(end+1,:) = [i,-1, numParen];
        elseif(strcmpi(line,'}'))
            open = dataBorders(dataBorders(:,2)==-1,:);    
            maxOpen = max(open(:,3));
            maxDb = dataBorders(dataBorders(:,2)==-1 & dataBorders(:,3)==maxOpen,:);
            maxDb = maxDb(end,:);
            
            Lia = ismember(dataBorders,maxDb,'rows');
            dataBorders(Lia,2) = i;
            
            numParen = numParen - 1;
        end
    end
    
    dataBorders(:,4) = dataBorders(:,2) - dataBorders(:,1);
    dataBorders = sortrows(dataBorders,1);
    
    sfsData = {};
    dataStart = {};
    for(i=1:size(dataBorders,1)) %#ok<*NO4LP>
        border = dataBorders(i,:);
        if(i<size(dataBorders,1))
            nextBorder = dataBorders(i+1,:);
        else
            nextBorder = [Inf, Inf, Inf];
        end
        
        if(border(2) > nextBorder(1))
            data = char(C{border(1)+1:nextBorder(1)-2});
        else
            data = char(C{border(1)+1:border(2)-1});
        end
        dataStart(end+1,:) = {border(1), data};
    end
    
    
end
