classdef ForceModelsEnum < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %ForceModelsEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        Gravity('Gravity',GravityForceModel(),false);
        Drag('Drag Force',DragForceModel(),true);
        Thrust('Thrust',ThrustForceModel(),true);
        Normal('Normal Force',NormalForceModel(),true);
        Lift('Lift Force',LiftForceModel(),true);
        Gravity3rdBody('3rd Body Gravity',Gravity3rdBodyForceModel(),true);
    end
    
    properties
        name char
        model AbstractForceModel
        canBeDisabled(1,1) logical = false;
    end
    
    methods
        function obj = ForceModelsEnum(name, model, canBeDisabled)
            obj.name = name;
            obj.model = model;
            obj.canBeDisabled = canBeDisabled;
        end
    end
    
    methods(Static)    
        function m = getEnumsOfDisablableForceModels()
            [m,~] = enumeration('ForceModelsEnum');
            m = m([m.canBeDisabled]);
        end
        
        function listBoxStrs = getListBoxStrs()
            [m,~] = enumeration('ForceModelsEnum');
            
            listBoxStrs = {};
            for(i=1:length(m)) %#ok<*NO4LP>
                listBoxStrs{end+1} = m(i).name; %#ok<AGROW>
            end
        end
        
        function listBoxStrs = getListBoxStrsOfDisablableModels()
            m = ForceModelsEnum.getEnumsOfDisablableForceModels();
            
            listBoxStrs = {};
            for(i=1:length(m)) %#ok<*NO4LP>
                listBoxStrs{end+1} = m(i).name; %#ok<AGROW>
            end
        end
        
        function [ind, fmE] = getIndOfListboxStrsForModel(model)
            [m,~] = enumeration('ForceModelsEnum');
            
            ind = -1;
            for(i=1:length(m))
                if(strcmpi(class(m(i).model),class(model)))
                    ind = i;
                    fmE = m(i);
                    break;
                end
            end
        end
        
        function [ind, fmE] = getIndOfDisablableListboxStrsForModel(model)
            m = ForceModelsEnum.getEnumsOfDisablableForceModels();
            
            ind = -1;
            for(i=1:length(m))
                if(strcmpi(class(m(i).model),class(model)))
                    ind = i;
                    fmE = m(i);
                    break;
                end
            end
        end
        
        function fmArr = getDefaultArrayOfForceModelEnums()
            fmArr = [ForceModelsEnum.Gravity, ForceModelsEnum.Drag, ForceModelsEnum.Thrust, ForceModelsEnum.Lift, ForceModelsEnum.Normal];
        end
        
        function fmArr = getAllForceModelsThatCannotBeDisabled()
            [m,~] = enumeration('ForceModelsEnum');
            
            fmArr = ForceModelsEnum.empty(1,0);
            for(i=1:length(m))
                if(m(i).canBeDisabled == false)
                    fmArr(end+1) = m(i);
                end
            end
        end
    end
end

