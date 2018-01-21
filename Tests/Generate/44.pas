var a,b,c:integer;
begin
	while(a < 10) do begin
		if(a mod 2 = 0) then
			a:=a+1;
		else 
			a:=a+2;
		writeln(a);
	end
end