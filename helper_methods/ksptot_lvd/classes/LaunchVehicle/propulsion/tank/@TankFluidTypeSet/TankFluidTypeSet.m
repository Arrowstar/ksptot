classdef TankFluidTypeSet < matlab.mixin.SetGet & matlab.mixin.Copyable
    %TankFluidTypeSet Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        types TankFluidType = TankFluidType.empty(1,0);
    end
    
    methods
        function obj = TankFluidTypeSet()

        end
        
        function addType(obj, type)
            obj.types(end+1) = type;
        end
        
        function removeType(obj, type)
            obj.types(obj.types == type) = [];
        end
        
        function threeTypesCell = getFirstThreeTypesCellArr(obj)
            threeTypes = obj.types(1:3);
            threeTypesCell = {threeTypes.name};
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = {obj.types.name};
        end
        
        function fType = getTypeForInd(obj, ind)
            fType = obj.types(ind);
        end
        
        function ind = getIndForType(obj, type)
            ind = find(obj.types == type, 1);
        end
        
        function moveTypeUp(obj, type)
            ind = obj.getIndForType(type);
            
            if(ind >= 2)
                obj.types(ind-1:ind) = obj.types(ind:-1:ind-1);
            end
        end
        
        function moveTypeDown(obj, type)
            ind = obj.getIndForType(type);
            
            if(ind < length(obj.types))
                obj.types(ind:ind+1) = obj.types(ind+1:-1:ind);
            end
        end
    end
    
    methods(Static)
        function defaultSet = getDefaultFluidTypeSet()
            defaultSet = TankFluidTypeSet();
            defaultSet.types(end+1) = TankFluidType('Liquid Fuel/Ox');
            defaultSet.types(end+1) = TankFluidType('Monopropellant');
            defaultSet.types(end+1) = TankFluidType('Xenon');
        end
    end
end