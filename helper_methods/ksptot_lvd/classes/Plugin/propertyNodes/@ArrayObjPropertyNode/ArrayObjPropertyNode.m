classdef ArrayObjPropertyNode < AbstractObjPropertyNode
    %ScalarObjPropertyNode Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        nodeObj
        nodeName(1,:) char
        
        nodeParent(1,:) AbstractObjPropertyNode = AbstractObjPropertyNode.empty(1,0)
    end
    
    methods
        function obj = ArrayObjPropertyNode(nodeObj, nodeName, nodeParent)
            obj.nodeObj = nodeObj;
            obj.nodeName = nodeName;
            obj.nodeParent = nodeParent;
        end
                
        function createPropertyTableModel(obj, grid, jBreadCrumbBar, jSpinnerIcon)
            list = java.util.ArrayList();
                        
            category = obj.nodeName;
            sizeOfObj = size(obj.nodeObj);
            for(i=1:numel(obj.nodeObj))
                nodeObjItem = obj.nodeObj(i);
                
                out = cell(size(sizeOfObj));
                [out{:}] = ind2sub(sizeOfObj,i);
                out = cell2mat(out);
                
                dimStr = regexprep(sprintf('%d,',out),{'^(.)',',$'},{'($1',')'});
                
                objPropName = sprintf('%s%s', obj.nodeName, dimStr);
                objProp = nodeObjItem;
                
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
    end
end