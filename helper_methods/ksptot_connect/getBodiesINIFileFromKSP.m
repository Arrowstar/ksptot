function [FileName,PathName] = getBodiesINIFileFromKSP()
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
    delimiter = -9999999999999;
    dataLength = 17;
    
    c = readDoublesFromKSPTOTConnect('GetCelestialBodyData','',true);
    cInds = find(c==delimiter);
    
    bodiesData = {};
    bodiesINIStr = {};
    
    iniInd = 1;
    for(i=1:length(cInds)) %#ok<*NO4LP>
        finInd = cInds(i);
        
        data = c(iniInd:finInd-1);
        numDbsInName = length(data) - dataLength + 1;
        dataStart = numDbsInName + 1;
        
        bodyData = struct();
        
        bodyData.name = char(data(1:numDbsInName))';
        
        bodyData.epoch = data(dataStart + 0);
        bodyData.sma = data(dataStart + 1);
        bodyData.ecc = data(dataStart + 2);
        bodyData.inc = data(dataStart + 3);
        bodyData.raan = data(dataStart + 4);
        bodyData.arg = data(dataStart + 5);
        bodyData.mean = data(dataStart + 6);
        
        bodyData.gm = data(dataStart + 7);
        bodyData.radius = data(dataStart + 8);
        bodyData.atmoHgt = data(dataStart + 9);
        bodyData.atmoPressSL = data(dataStart + 10);
        bodyData.atmoScaleHgt = data(dataStart + 11);
        bodyData.rotperiod = data(dataStart + 12);
        bodyData.rotini = data(dataStart + 13);
        
        parentID = data(dataStart + 14);
        id = data(dataStart + 15);
        
        if(parentID == id)
            parentID = -1;
        end
        
        bodyData.id = id;
        bodyData.parentID = parentID;
        
        bodyData.canBeCentral = -1;
        bodyData.canBeArriveDepart = -1;
        bodyData.parent = '';
        
        bodiesData{end+1} = bodyData; %#ok<*AGROW>
        
        iniInd = finInd+1;
    end
    
    for(i=1:length(bodiesData))
        bodyI = bodiesData{i};
        numChilds = 0;
        numPeers = 0;
        for(j=1:length(bodiesData))
            bodyJ = bodiesData{j};
            
            if(bodyI.id == bodyJ.id)
                continue;
            end
            
            if(bodyJ.id == bodyI.parentID)
                bodyI.parent = bodyJ.name;
            end
            
            if(bodyJ.parentID == bodyI.id)
                numChilds = numChilds + 1;
            end       
            
            if(bodyJ.parentID == bodyI.parentID)
                numPeers = numPeers + 1;
            end
        end

        if(numChilds >= 2)
            bodyI.canBeCentral = 1;
        else
            bodyI.canBeCentral = 0;
        end
        
        if(numPeers >= 1)
            bodyI.canBeArriveDepart = 1;
        else
            bodyI.canBeArriveDepart = 0;
        end
        
        bodystr = assemBodyDataStr(bodyI.name, bodyI.epoch, bodyI.sma, bodyI.ecc, bodyI.inc, bodyI.raan, bodyI.arg, ...
                                   bodyI.mean, bodyI.gm, bodyI.radius, bodyI.atmoHgt, bodyI.atmoPressSL, bodyI.atmoScaleHgt, bodyI.rotperiod, bodyI.rotini, ...
                                   bodyI.parentID, bodyI.id, bodyI.canBeCentral, bodyI.canBeArriveDepart, bodyI.parent);
                               
        bodiesINIStr{end+1} = bodystr;
    end
    
    if(~isempty(bodiesINIStr))
        [FileName,PathName,~] = uiputfile('*.ini','Save Bodies File','bodies.ini');

        if(~isempty(FileName) && ~isempty(PathName))
            fid = fopen([PathName,FileName],'w+t');
            for(i=1:length(bodiesINIStr))
                fprintf(fid,bodiesINIStr{i});
            end
            fclose(fid);
        end
    else
        FileName = [];
        PathName = [];
        errordlg('There was an error pulling data from KSPTOTConnect.  Is KSP running in the Flight Scene with the KSPTOTConnect plugin loaded?','No Data','modal');
    end
end

function bodystr = assemBodyDataStr(name, epoch, sma, ecc, inc, raan, arg, mean, gm, radius, atmoHgt, pressSL, atmoScaleHgt, rotperiod, rotini, parentID, id, canBeCentral, canBeArriveDepart, parent)

    bodystr = sprintf('[%s]\nepoch = %0.9f\nsma = %0.9f\necc = %0.9f\ninc = %0.9f\nraan = %0.9f\narg = %0.9f\nmean = %0.9f\ngm = %0.9f\nradius = %0.9f\natmoHgt = %0.9f\natmoPressSL = %0.9f\natmoScaleHgt = %0.9f\nrotperiod = %0.9f\nrotini = %0.9f\nbodycolor = gray\ncanBeCentral = %i\ncanBeArriveDepart = %i\nparent = %s\nparentID = %i\nname = %s\nid = %i\n\n', ...
                      name,epoch,sma,ecc,inc,raan,arg,mean,gm,radius,atmoHgt,pressSL,atmoScaleHgt,rotperiod,rotini,canBeCentral,canBeArriveDepart,parent,parentID,name,id);

end
