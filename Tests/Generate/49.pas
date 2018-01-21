var i:integer;
begin
	repeat
    	i := i+1;
    	writeln(i);
    	if(i mod 3 = 0) then break;
  	until (i < 10);
end