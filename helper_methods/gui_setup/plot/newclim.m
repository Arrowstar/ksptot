function CLim = newclim(BeginSlot,EndSlot,CDmin,CDmax,CmLength)
   % 				Convert slot number and range
   % 				to percent of colormap
   PBeginSlot    = (BeginSlot - 1) / (CmLength - 1);
   PEndSlot      = (EndSlot - 1) / (CmLength - 1);
   PCmRange      = PEndSlot - PBeginSlot;
   % 				Determine range and min and max 
   % 				of new CLim values
   DataRange     = CDmax - CDmin;
   ClimRange     = DataRange / PCmRange;
   NewCmin       = CDmin - (PBeginSlot * ClimRange);
   NewCmax       = CDmax + (1 - PEndSlot) * ClimRange;
   CLim          = [NewCmin,NewCmax];
end