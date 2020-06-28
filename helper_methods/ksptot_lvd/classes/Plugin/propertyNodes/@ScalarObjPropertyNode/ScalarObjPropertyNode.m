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
        
        function createPropertyTableModel(obj, grid, jBreadCrumbBar)
            list = java.util.ArrayList();
            
            mco = metaclass(obj.nodeObj);
            propertyList = mco.PropertyList;
            
            propertyList = properties(obj.nodeObj);
            
            category = obj.nodeName;
            for(i=1:length(propertyList))
%                 propertyListItem = propertyList(i);
                objPropName = propertyList{i};

%                 if(propertyListItem.Dependent == 0 && strcmpi(propertyListItem.GetAccess,'public') && strcmpi(propertyListItem.SetAccess,'public'))
%                     objPropName = propertyListItem.Name;
                    objProp = obj.nodeObj.(objPropName);

                    [type, value] = AbstractObjPropertyNode.getTypeOfObject(objProp);
                    propNode = AbstractObjPropertyNode.createNewPropertyNode(value, objPropName, objPropName, type, '', [], category);

                    list.add(propNode);
%                 end
            end
            
            model = com.jidesoft.grid.PropertyTableModel(list);
            model.expandAll();
            
            grid.setModel(model);
            
            hgrid = handle(grid, 'CallbackProperties');
            set(hgrid,'MouseClickedCallback',@(src,evt) AbstractObjPropertyNode.getGridMouseDoubleClickCallback(src,evt,obj,grid,jBreadCrumbBar));
            
            obj.createBreadcrumbs(grid, jBreadCrumbBar);
        end
        
        function str = getCodeStr(obj)
            str = obj.nodeName;
        end
    end
end