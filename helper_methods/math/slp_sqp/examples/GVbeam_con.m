function [g, ceq,gradg,ceqgrad] = GVbeam_con( x )
%GVbeam_con Constraints for Cantilever beam with N design variables
%           from Vanderplaats (1984) Example 5-1, pp. 147-150.
ceq = [];
ceqgrad = [];
[~,g] = fbeamGV( x );
[~,gradg] = gbeamGV( x );
end