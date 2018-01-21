var i,a:integer;
begin
	repeat
		for a:=1 to 10 do
			if(a mod 2 = 0) then
    			i:= i+1;
    	writeln(i);
  	until (i < 10);
  	writeln(i);
end