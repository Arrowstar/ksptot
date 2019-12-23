function r = readPartStrAndDblsFromDblArr(DblArr, numDbls)
%readPartStrAndDblsFromDblArr Summary of this function goes here
%   Detailed explanation goes here

    term = -9999999999999;

    r = {};
    
    termInds = find((DblArr==term));
    pTermInd = 0;
    for(i=1:length(termInds))
        termInd = termInds(i);
        dArr = DblArr(pTermInd+1:termInd-1);

        r{i,1} = char(dArr(1:length(dArr)-numDbls))';
        
        k=2;
        for(j=numDbls-1:-1:0)
            r{i,k} = dArr(end-j);
            k = k+1;
        end

        pTermInd = termInd;
    end
end

