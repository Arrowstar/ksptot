function tf = testIfObjectsAreEq(A,B)
    if(strcmpi(class(A),class(B)))
        tf = eq(A, B);
    else
        tf = false;
    end
end