function report_mosek_error(r,res)
  % REPORT_MOSEK_ERROR issue warning or error on return values from running
  % mosekopt
  %
  % [r,res] = report_mosek_error(r,res)
  %
  % Example:
  %   [r,res]=mosekopt('minimize echo(0)',prob,param);
  %   [r,res] = report_mosek_error(r,res)
  %

  % check for mosek error
  if(r == 4006)
    warning(['MOSEK ERROR. rcode: ' ...
      num2str(res.rcode) ' ' ...
      res.rcodestr ' ' ...
      res.rmsg ...
      'The solution is probably OK, but ' ...
      'to make this error go away, increase: ' ...
      'MSK_DPAR_INTPNT_CO_TOL_REL_GAP' ...
      ]);
  elseif(r ~= 0)
    error(['FATAL MOSEK ERROR. rcode: ' ...
      num2str(res.rcode) ' ' ...
      res.rcodestr ' ' ...
      res.rmsg]);
  end
end
