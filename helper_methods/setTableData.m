function setTableData(hTable, tableData)
%setTableData Summary of this function goes here
%   Detailed explanation goes here

    try               
%         jScrollPane = findjobj(hTable);
%         jscroll = jScrollPane.getVerticalScrollBar(); 
%         sVal = get(jscroll,'value');
        set(hTable,'Data',tableData);
%         drawnow;
%         set(jscroll, 'value', sVal);
%         jScrollPane.repaint;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
%         jScrollPane = findjobj(hTable);
%         jscroll = jScrollPane.getVerticalScrollBar();  
%         sVal = get(jscroll,'value');
%         
%         jTable = jScrollPane.getViewport.getView;
%         model = jTable.getModel();
%         if(model.getRowCount() == size(tableData,1))
%             for(i=1:size(tableData,1))
%                 for(j=1:size(tableData,2))
%                     value = tableData{i,j};
%                     if(isnumeric(value))
%                         value = num2str(value);
%                     end
% %                     javaMethodEDT('setValueAt', jTable, value,i-1,j-1);
%                     jTable.setValueAt(value,i-1,j-1);
%                 end
%             end
%             drawnow;
%         else
%             set(hTable,'Data',tableData);
%             drawnow;
%             set(jscroll, 'value', sVal);
%             jScrollPane.repaint;
%         end

    catch ME
        disp(ME.message);
        set(hTable,'Data',tableData);
    end
end

