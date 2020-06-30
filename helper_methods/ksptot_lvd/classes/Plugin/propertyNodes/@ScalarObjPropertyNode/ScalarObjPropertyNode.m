classdef ScalarObjPropertyNode < AbstractObjPropertyNode
    %ScalarObjPropertyNode Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        nodeObj
        nodeName(1,:) char
        
        nodeParent(1,:) AbstractObjPropertyNode = AbstractObjPropertyNode.empty(1,0)
    end
    
    methods
        function obj = ScalarObjPropertyNode(nodeObj, nodeName, nodeParent)
            obj.nodeObj = nodeObj;
            obj.nodeName = nodeName;
            obj.nodeParent = nodeParent;
        end
        
        function createPropertyTableModel(obj, grid, jBreadCrumbBar, jSpinnerIcon)
            list = java.util.ArrayList();
            
            propertyList = properties(obj.nodeObj);
            
            category = obj.nodeName;
            for(i=1:length(propertyList))
                objPropName = propertyList{i};
                objProp = obj.nodeObj.(objPropName);
                
                desc = sprintf('Type: %s', ...
                    class(objProp));
                
                [type, value] = AbstractObjPropertyNode.getTypeOfObject(objProp);
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
            tf = true;
        end
    end
end