classdef SetGenericTabularQuatInterpSteeringModelActionOptimVar < AbstractOptimizationVariable
    %SetGenericTabularQuatInterpSteeringModelActionOptimVar Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj = GenericTabularQuatInterpSteeringModel.getDefaultSteeringModel()
                
        %Var Flags
        varGamma0(1,1) logical = false;       
        varBeta0(1,1) logical = false;        
        varAlpha0(1,1) logical = false;

        varTDur(:,1) logical = false;
        varGammaAngles(:,1) logical = false;
        varBetaAngles(:,1) logical = false;
        varAlphaAngles(:,1) logical = false;

        %Lower Bounds
        lbGamma0(1,1) double = 0;
        lbBeta0(1,1) double = 0;
        lbAlpha0(1,1) double = 0;

        lbTDur(:,1) double = 0;
        lbGammaAngles(:,1) double = 0;
        lbBetaAngles(:,1) double = 0;
        lbAlphaAngles(:,1) double = 0;

        %Upper Bounds
        ubGamma0(1,1) double = 0;
        ubBeta0(1,1) double = 0;
        ubAlpha0(1,1) double = 0;

        ubTDur(:,1) double = 0;
        ubGammaAngles(:,1) double = 0;
        ubBetaAngles(:,1) double = 0;
        ubAlphaAngles(:,1) double = 0;
    end
    
    methods
        function obj = SetGenericTabularQuatInterpSteeringModelActionOptimVar(varObj)
            obj.varObj = varObj;
            obj.varObj.optVar = obj;
            
            obj.id = rand();
        end
        
        function x = getXsForVariable(obj)            
            xInitState = NaN(1, 3);           
            if(obj.varGamma0)
                xInitState(1) = obj.varObj.gamma0;
            end
            if(obj.varBeta0)
                xInitState(2) = obj.varObj.beta0;
            end
            if(obj.varAlpha0)
                xInitState(3) = obj.varObj.alpha0;
            end

            numTabularVarRows = numel(obj.varTDur);
    
            xTDur = NaN(1, numTabularVarRows);
            xTDur(obj.varTDur) = obj.varObj.tDurs(obj.varTDur);

            xGammaAngles = NaN(1, numTabularVarRows);
            xGammaAngles(obj.varGammaAngles) = obj.varObj.gammaAngs(obj.varGammaAngles);

            xBetaAngles = NaN(1, numTabularVarRows);
            xBetaAngles(obj.varBetaAngles) = obj.varObj.betaAngs(obj.varBetaAngles);

            xAphaAngles = NaN(1, numTabularVarRows);
            xAphaAngles(obj.varAlphaAngles) = obj.varObj.alphaAngs(obj.varAlphaAngles);

            x = [xInitState, xTDur, xGammaAngles, xBetaAngles, xAphaAngles];
            
            x(isnan(x)) = [];
        end
        
        function [lb, ub] = getBndsForVariable(obj)            
            useTf = obj.getUseTfForVariable();

            [lb, ub] = obj.getAllBndsForVariable();
            lb = lb(useTf);
            ub = ub(useTf);
        end
        
        function [lb, ub] = getAllBndsForVariable(obj)
            lb = [obj.lbGamma0, obj.lbBeta0, obj.lbAlpha0, ...
                  obj.lbTDur(:)', ...
                  obj.lbGammaAngles(:)', ...
                  obj.lbBetaAngles(:)', ...
                  obj.lbAlphaAngles(:)'];

            ub = [obj.ubGamma0, obj.ubBeta0, obj.ubAlpha0, ...
                  obj.ubTDur(:)', ...
                  obj.ubGammaAngles(:)', ...
                  obj.ubBetaAngles(:)', ...
                  obj.ubAlphaAngles(:)'];
        end
        
        function setBndsForVariable(obj, lb, ub)
            ind = 1;
            if(obj.varGamma0)
                obj.lbGamma0 = lb(ind);
                obj.ubGamma0 = ub(ind);
                ind = ind + 1;
            end
            if(obj.varBeta0)
                obj.lbBeta0 = lb(ind);
                obj.ubBeta0 = ub(ind);
                ind = ind + 1;
            end
            if(obj.varAlpha0)
                obj.lbAlpha0 = lb(ind);
                obj.ubAlpha0 = ub(ind);
                ind = ind + 1;
            end

            if(any(obj.varTDur))
                inds = ind:ind+sum(obj.varTDur)-1;
                obj.lbTDur(obj.varTDur) = lb(inds);
                obj.ubTDur(obj.varTDur) = ub(inds);
                ind = inds(end)+1;
            end
            if(any(obj.varGammaAngles))
                inds = ind:ind+sum(obj.varGammaAngles)-1;
                obj.lbGammaAngles(obj.varGammaAngles) = lb(inds);
                obj.ubGammaAngles(obj.varGammaAngles) = ub(inds);
                ind = inds(end)+1;
            end
            if(any(obj.varBetaAngles))
                inds = ind:ind+sum(obj.varBetaAngles)-1;
                obj.lbBetaAngles(obj.varBetaAngles) = lb(inds);
                obj.ubBetaAngles(obj.varBetaAngles) = ub(inds);
                ind = inds(end)+1;
            end
            if(any(obj.varAlphaAngles))
                inds = ind:ind+sum(obj.varAlphaAngles)-1;
                obj.lbAlphaAngles(obj.varAlphaAngles) = lb(inds);
                obj.ubAlphaAngles(obj.varAlphaAngles) = ub(inds);
            end
        end
        
        function useTf = getUseTfForVariable(obj)
            useTf = [obj.varGamma0, obj.varBeta0, obj.varAlpha0, ...
                     obj.varTDur(:)', ...
                     obj.varGammaAngles(:)', ...
                     obj.varBetaAngles(:)', ...
                     obj.varAlphaAngles(:)'];
        end
        
        function setUseTfForVariable(obj, useTf) 
            obj.varGamma0 = useTf(1);
            obj.varBeta0 = useTf(2);
            obj.varAlpha0 = useTf(3);

            numTabularVarRows = (numel(useTf)-3)/4;

            inds = 4 : 4+numTabularVarRows-1;
            obj.varTDur = useTf(inds);

            inds = inds(end)+1 : inds(end)+numTabularVarRows;
            obj.varGammaAngles = useTf(inds);

            inds = inds(end)+1 : inds(end)+numTabularVarRows;
            obj.varBetaAngles = useTf(inds);

            inds = inds(end)+1 : inds(end)+numTabularVarRows;
            obj.varAlphaAngles = useTf(inds);
        end
        
        function updateObjWithVarValue(obj, x)
            ind = 1;

            if(obj.varGamma0)
                obj.varObj.gamma0 = x(ind);
                ind = ind + 1;
            end
            if(obj.varBeta0)
                obj.varObj.beta0 = x(ind);
                ind = ind + 1;
            end
            if(obj.varAlpha0)
                obj.varObj.alpha0 = x(ind);
                ind = ind + 1;
            end

            if(any(obj.varTDur))
                inds = ind:ind+sum(obj.varTDur)-1;
                obj.varObj.tDurs(obj.varTDur) = x(inds);
                ind = inds(end)+1;
            end
            if(any(obj.varGammaAngles))
                inds = ind:ind+sum(obj.varGammaAngles)-1;
                obj.varObj.gammaAngs(obj.varGammaAngles) = x(inds);
                ind = inds(end)+1;
            end
            if(any(obj.varBetaAngles))
                inds = ind:ind+sum(obj.varBetaAngles)-1;
                obj.varObj.betaAngs(obj.varBetaAngles) = x(inds);
                ind = inds(end)+1;
            end
            if(any(obj.varAlphaAngles))
                inds = ind:ind+sum(obj.varAlphaAngles)-1;
                obj.varObj.alphaAngs(obj.varAlphaAngles) = x(inds);
            end
        end
        
        function nameStrs = getStrNamesOfVars(obj, evtNum, varLocType)
           if(evtNum > 0)
                subStr = sprintf('Event %i',evtNum);
            else
                subStr = varLocType;
            end
            
            nameStrs = {sprintf('%s Initial Gamma Angle', subStr), ...
                        sprintf('%s Initial Beta Angle', subStr), ...
                        sprintf('%s Initial Alpha Angle', subStr)};

            numTabularVarRows = numel(obj.varTDur);
            for(i=1:numTabularVarRows)
                nameStrs = horzcat(nameStrs, ...
                                   {sprintf('%s Attitude %u Rotation Duration', subStr, i)}); %#ok<AGROW>
            end

            for(i=1:numTabularVarRows)
                nameStrs = horzcat(nameStrs, ...
                                   {sprintf('%s Attitude %u Gamma Angle', subStr, i)}); %#ok<AGROW>
            end

            for(i=1:numTabularVarRows)
                nameStrs = horzcat(nameStrs, ...
                                   {sprintf('%s Attitude %u Beta Angle', subStr, i)}); %#ok<AGROW>
            end

            for(i=1:numTabularVarRows)
                nameStrs = horzcat(nameStrs, ...
                                   {sprintf('%s Attitude %u Alpha Angle', subStr, i)}); %#ok<AGROW>
            end

            [angle1Name, angle2Name, angle3Name] = obj.varObj.getAngleNames();
            nameStrs = strrep(nameStrs, 'Gamma Angle', angle1Name);
            nameStrs = strrep(nameStrs, 'Beta Angle',  angle2Name);
            nameStrs = strrep(nameStrs, 'Alpha Angle', angle3Name);

            nameStrs = nameStrs(obj.getUseTfForVariable());
        end

        function varsStoredInRad = getVarsStoredInRad(obj)
            useTf = obj.getUseTfForVariable();
            numTabularVarRows = numel(obj.varTDur);

            varsStoredInRad = true([1, numel(useTf)]); %All variables are stored in rad except the durations
            varsStoredInRad(4 : 4+numTabularVarRows-1) = false; %TDur are stored in seconds, not radians
        end
    end
end