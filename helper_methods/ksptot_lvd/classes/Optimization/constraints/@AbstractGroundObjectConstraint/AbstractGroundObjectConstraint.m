classdef (Abstract) AbstractGroundObjectConstraint < AbstractConstraint
    %AbstractGroundObjectConstraint Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function groundObj = selectConstraintObj(obj, lvdData)
            [listBoxStr, groundObjs] = lvdData.groundObjs.getListboxStr();

            groundObj = [];
            if(isempty(groundObjs))                
                warndlg('Cannot create ground object value object: no ground objects have been created.  Create a ground object first.','Ground Object Value Constraint','modal');
            else
                [Selection,ok] = listdlg('PromptString',{'Select a ground object:'},...
                                'SelectionMode','single',...
                                'Name','Ground Objects',...
                                'ListString',listBoxStr);
                            
                if(ok == 0)
                    groundObj = [];
                else
                    groundObj = groundObjs(Selection);
                end
            end
        end
        
        function useObjFcn = setupForUseAsObjectiveFcn(obj,lvdData)
            groundObj = obj.selectConstraintObj(lvdData);
            
            if(not(isempty(groundObj)))
                obj.groundObj = groundObj;
                useObjFcn = true;
            else
                useObjFcn = false;
            end
        end
    end
end