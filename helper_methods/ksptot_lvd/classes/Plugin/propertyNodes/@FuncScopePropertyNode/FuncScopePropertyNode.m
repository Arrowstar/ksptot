classdef FuncScopePropertyNode < AbstractObjPropertyNode
    %FuncScopePropertyNode Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        nodeObj(1,:) cell = {};
        nodeObjsNames(1,:) cell = {};
        
        nodeName(1,:) char = 'Function Scope';
        
        nodeParent(1,:) AbstractObjPropertyNode = AbstractObjPropertyNode.empty(1,0)
    end
    
    methods
        function obj = FuncScopePropertyNode(nodeObj, nodeObjsNames)
            obj.nodeObj = nodeObj;
            obj.nodeObjsNames = nodeObjsNames;
        end
        
        function createPropertyTableModel(obj, grid, jBreadCrumbBar, jSpinnerIcon)
            list = java.util.ArrayList();
            
            objs = obj.nodeObj;
            
            category = obj.nodeName;
            for(i=1:length(objs))
                nodeObject = objs{i};
                
                try
                objPropName = obj.nodeObjsNames{i};
                catch ME
                    a=1;
                end
                
                desc = sprintf('Type: %s', ...
                    class(nodeObject));
                
                [type, value] = AbstractObjPropertyNode.getTypeOfObject(nodeObject);
                propNode = AbstractObjPropertyNode.createNewPropertyNode(value, objPropName, objPropName, type, desc, [], category);
                
                list.add(propNode);
            end
            
            model = com.jidesoft.grid.PropertyTableModel(list);
            model.expandAll();
            
            grid.setModel(model);
            
            hgrid = handle(grid, 'CallbackProperties');
            set(hgrid,'MouseClickedCallback',@(src,evt) AbstractObjPropertyNode.getGridMouseDoubleClickCallback(src,evt,obj,grid,jBreadCrumbBar,jSpinnerIcon));
            
            obj.createBreadcrumbs(grid, jBreadCrumbBar, jSpinnerIcon);
        end
        
        function str = getCodeStr(obj)
            str = obj.nodeName;
        end
        
        function tf = useInObjPropBreadcrumbCopy(obj)
            tf = false;
        end
    end
end

function out = getVarName(var)
    out = inputname(1);
end

