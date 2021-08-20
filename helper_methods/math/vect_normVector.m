function normVect = vect_normVector(vect)
%vect_normVector Returns the column unit vectors of the 3xN array of column vectors
%   Detailed explanation goes here
    normVect = bsxfun(@rdivide, vect, vecNormARH(vect));
end