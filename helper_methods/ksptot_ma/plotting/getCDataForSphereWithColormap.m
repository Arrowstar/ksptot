function [CData] = getCDataForSphereWithColormap(Z, colormapName)
    cmap = feval(colormapName,100);
    cmap = vertcat(cmap(end:-1:1,:),cmap);

    CData = zeros(size(Z));
    minZ = min(min(Z));
    maxZ = max(max(Z));
    for(i=1:size(Z,1))
        for(j=1:size(Z,2))
            interpVal = (Z(i,j)-minZ)/(maxZ-minZ);
            index = round(interpVal*size(cmap,1));

            if(index == 0)
                index = 1;
            elseif(index > size(cmap,1))
                index = size(cmap,1);
            end

            CData(i,j,1) = cmap(index,1);
            CData(i,j,2) = cmap(index,2);
            CData(i,j,3) = cmap(index,3);
        end
    end
end

