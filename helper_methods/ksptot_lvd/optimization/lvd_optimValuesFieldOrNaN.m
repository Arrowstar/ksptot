function v = lvd_optimValuesFieldOrNaN(s, name)
%lvd_optimValuesFieldOrNaN One numeric scalar out of a solver's per-iteration
%info struct, or NaN when it is missing, non-numeric or non-finite.
%
%   The seven optimizers report different fields (fmincon has
%   firstorderopt, IPOPT has inf_pr/inf_du, NOMAD has constrviolation, ...),
%   so the headless progress closures all read through here instead of
%   assuming a field exists.

v = NaN;

try
    c = s.(name);

    if(isnumeric(c) && isscalar(c) && isfinite(c))
        v = c;
    end
catch
end
end
