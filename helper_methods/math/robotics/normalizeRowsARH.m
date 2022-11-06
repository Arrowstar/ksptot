function normRowMatrix = normalizeRowsARH(matrix)
%This function is for internal use only. It may be removed in the future.

%normalizeRows Normalize the rows of a matrix.
%   NORMROWMATRIX = normalizeRows(MATRIX) returns a matrix the same
%   size as the input MATRIX, with each row normalized to a unit vector
%   with length of 1.
%   This is achieved by dividing each vector element by the 2-norm
%   (Euclidean norm) of the whole vector.

%   Copyright 2014 The MathWorks, Inc.

%#codegen

normRowMatrix = bsxfun(@times, matrix, 1./sqrt(sum(matrix.^2,2)));

end

