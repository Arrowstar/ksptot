%% TSUITE  test suite MATLAB script of optimization problems for sqp.m
%
%% Inputs:      Requires fsuite.m and gsuite.m
%
%  Written by:  Robert A. Canfield
%  Created:     2/20/95
%  Modified:     6/3/20

%  Modifications
%  3/28/95 - Compare to known solutions
%   5/1/95 - Add status return
%   5/7/04 - Clean up comparison print
%   4/6/19 - Error for failed regression tests
% 11/10/19 - delete last diary log
%   6/3/20 - add back probs 7,8
clear
format compact;
delete tsuite.log;
diary  tsuite.log;
disp(' ')
disp(' ')
disp(date)
disp(' ')
runprobs = 1:21;
f=zeros(1,length(runprobs));
nlast=0;
for n=runprobs
   [nx,ng,opts(13),x0,vlb,vub] = fsuite([],n);
   opts(15)=0; opts(14)=0; opts(9)=0; opts(6)=-1; opts(5)=0; opts(1)=2;
   disp(' ')
   disp(['test suite problem # ',int2str(n)])
	if n==3
		disp('Premature termination. Merit gradient zero');
	elseif n==4,  opts(6)=0; opts(9)=1; % w Derivative check
		if n==nlast
			disp('d.v. scaling OFF, ')
		else
			disp('d.v. scaling ON'); opts(5)=-1e3;
		end
	elseif n==7
		disp('Function scaling'); opts(5)=1.e3; opts(6)=0;
	elseif n==8;                 opts(15)=1; % stop@iter=1
		disp('Unconstrained, unbounded problem')
	elseif n==12
		disp('Check z0p1>eps to avoid infinite r')
	elseif n==13
		disp('Equality constraint')
	elseif n==15
		disp('vlb is subset of x0')
	elseif n==19
		disp('Modified search: aS mS'); opts(6)=0;
	elseif n==20
		disp('Grd code error: Max Fcn Eval'); opts(6)=2; opts(14)=50;
	elseif n==21
		disp('1 equality constraint')
		disp('Andy Grace termination criteria'); opts(6)=1;
	end

   % Complex Step and Finite difference gradients
	if n==6 || n==11
		disp('Complex Step gradients')
      opts(9) = -1;
	   xcs=sqp('fsuite',x0,opts,vlb,vub,[],n);
      opts(9) = 0;
		disp('Finite difference gradients')
	   [x,opt]=sqp('fsuite',x0,opts,vlb,vub,[],n);
	% Analytic gradients
	else
	   [x,opt,u,H,stat]=sqp('fsuite',x0,opts,vlb,vub,'gsuite',n);
	end
%	f=opt(8),nfcn=opt(10),ngrd=opt(11),nit=opt(14)
	f(n)=opt(8);
   x %#ok<NOPTS>
   disp(['nfcn=' int2str(opt(10)) ', ngrd=' int2str(opt(11)) ', nit=' int2str(opt(14))])
	nlast=n;
end

%% Verify results.
%fans=[5.6061, 1.508,  18.47, 1.34, 0, 2994.89, 112500, 10250, .2, .5, ...
%      -1, 52, -8.333, 93.254, 3.5, 9.037, 911.88, 3.951, 0.02355, -360875*[1 1]];
fans=[5.6061, 1.508,  18.47, 1.34, 0, 2994.89, 112500, -24510, .2, .5, ...
      -1, 52, -8.333, 93.254, 3.5, 9.037, 911.88, 3.951, 0.02355, -434360, -360875];
difr=(f(runprobs)-fans(runprobs))./(fans(runprobs)+eps);
disp(' ')
disp('Percent difference between objective and known solution')
disp('Problem #      % Error')
disp('---------      -------')
disp(sprintf('%7.0f   %12.4f\n',[runprobs; 100*difr])) %#ok<DSPS>
tolerance = 0.005;
except_prob = [18 20];
except_tol  = [1.8 2.4];
except_viol = abs(difr(ismember(runprobs,except_prob)))>except_tol;
tight_viol  = setdiff( runprobs(abs(difr)>tolerance),except_prob );
if any(tight_viol)
   warning(['Tsuite regression tests ',num2str(tight_viol),...
           ' failed: tolerance>',num2str(tolerance)])
end
if any(except_viol)
   warning(['Tsuite regression tests ',num2str(except_prob(except_viol)),...
           ' failed: loose tolerance>',num2str(except_tol(except_viol))])
end
if ~any(tight_viol) && ~any(except_viol)
   disp('Tsuite passed all regression tests.')
end
diary off
