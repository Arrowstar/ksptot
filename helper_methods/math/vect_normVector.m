function normVect = vect_normVector(vect)
%vect_normVector Summary of this function goes here
%   Detailed explanation goes here
    normVect = bsxfun(@rdivide, vect, vecNormARH(vect));
end