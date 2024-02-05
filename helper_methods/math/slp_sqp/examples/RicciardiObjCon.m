function [ob,con]= RicciardiObjCon(X)
x = X(1);
y = X(2);
con = -realmax;
ob = (y - sin(x-2*y)+cos(x+3*y)) * (x - sin(2*x + 3*y) - cos(3*x - 5*y));