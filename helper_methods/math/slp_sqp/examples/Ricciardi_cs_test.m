clear
disp(' ')
disp('Ricciardi Complex Step test')
if exist('fmincon','builtin')
   sqpOptions = optimset('fmincon');
else % alternative for Octave
   sqpOptions = optimset('fminsearch');
end
sqpOptions.Display = 'on';
sqpOptions.ComplexStep = 'on';
sqpOptions.DerivativeCheck = 'on';
[x,opts,v,H,status]=sqp(@RicciardiObjCon,[.9;-1],sqpOptions,[-1.5;-1.5],[1.5;1.5]);
