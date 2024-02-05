function flag = contains( str, pattern )
flag = ~isempty(strfind( str, pattern )); %#ok<STREMP>
end