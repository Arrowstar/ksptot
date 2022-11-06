function vecNorms = vecNormARH(a)
    if(size(a,1) == 3)
        vecNorms = sqrt(sum(a.^2,1));
    else
        error('Must use column vectors with three rows.');
    end
end