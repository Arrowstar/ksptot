function [A,B,C] = coeff_lmm2(method)
switch method
case '801',
	A = [1;0;1;0.5];
	B = [17671;-23622;61449;-25258]/12096;
case '802',
	A = [1;2;3;1.75];
	B = [192481;6582;816783;-78406]/120960;
case '803',
	A = [1;1;1;0.5];
	B = [13207;-8934;42873;-16906]/8640;
otherwise
	error(['The required method "' method '" is not implemented']);
end
C = [672;-168;32;-3]/840;
