classdef TankToTankConnection < matlab.mixin.SetGet
    %TankToTankConnection Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        srcTank LaunchVehicleTank 
        tgtTank LaunchVehicleTank
        initFlowRate(1,1) double = 0;
    end
    
    properties(Dependent)
        lvdData
    end
    
    methods
        function obj = TankToTankConnection(srcTank, tgtTank)
            if(nargin > 0)
                obj.srcTank = srcTank;
                obj.tgtTank = tgtTank;
            end
        end
        
        function lvdData = get.lvdData(obj)
            if(not(isempty(obj.srcTank)))
                lvdData = obj.srcTank.stage.launchVehicle.lvdData;
            else
                lvdData = obj.tgtTank.stage.launchVehicle.lvdData;
            end
        end
        
        function nameStr = getName(obj)
            if(isempty(obj.srcTank))
                srcNameStr = '<External>';
            else
                srcNameStr = obj.srcTank.name;
            end
            
            if(isempty(obj.tgtTank))
                tgtNameStr = '<External>';
            else
                tgtNameStr = obj.tgtTank.name;
            end
            
            nameStr = sprintf('%s to %s (%.3f mT/s)', srcNameStr, tgtNameStr, obj.initFlowRate);
        end
        
        function tf = isInUse(obj)
            tf = obj.lvdData.usesTankToTankConn(obj);
        end        
    end
    
    methods(Static)
        function tankMassDots = getTankMassFlowRatesFromTankToTankConnections(tankStates, tankStatesMasses, t2tConnStates)
            activeT2TConnStates = t2tConnStates([t2tConnStates.active]);
                       
            tankMassDots = zeros(size(tankStates));
            tankMassDots = tankMassDots(:);
            
            if(isempty(activeT2TConnStates))
                return;
            end
            
            tanks = [tankStates.tank];

            for(i=1:length(activeT2TConnStates))
                t2tConnState = activeT2TConnStates(i);
                
                srcTank = t2tConnState.conn.srcTank;
                if(not(isempty(srcTank)))
                    srcBool = tanks == srcTank;
                    if(any(srcBool))
                        srcTankState = tankStates(srcBool);
                        srcStageState = srcTankState.stageState.active;
                        srcIsTank = true;
                    else
                        srcIsTank = true;
                        srcStageState = false;
                    end
                else
                    srcStageState = true;
                    srcIsTank = false;
                end
                
                tgtTank = t2tConnState.conn.tgtTank;
                if(not(isempty(tgtTank)))
                    tgtBool = tanks == tgtTank;
                    if(any(tgtBool))
                        tgtTankState = tankStates(tgtBool);
                        tgtStageState = tgtTankState.stageState.active;
                        tgtIsTank = true;
                    else
                        tgtStageState = false;
                        tgtIsTank = true;
                    end
                else
                    tgtStageState = true;
                    tgtIsTank = false;
                end
                
                
                if(srcStageState && tgtStageState)
                    flowRate = t2tConnState.flowRate;
                    
                    if(srcIsTank && tgtIsTank)
                        if(tankStatesMasses(srcBool) > 0)
                            tankMassDots(srcBool) = tankMassDots(srcBool) - flowRate;
                            tankMassDots(tgtBool) = tankMassDots(tgtBool) + flowRate;
                        end
                        
                    elseif(srcIsTank && tgtIsTank == false)
                        if(tankStatesMasses(srcBool) > 0)
                            tankMassDots(srcBool) = tankMassDots(srcBool) - flowRate;
                        end
                        
                    elseif(srcIsTank == false && tgtIsTank)
                        tankMassDots(tgtBool) = tankMassDots(tgtBool) + flowRate;
                    end
                end
            end
        end
    end
end