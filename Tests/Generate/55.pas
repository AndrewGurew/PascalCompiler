var a:integer;
begin
	while(a < 10) do begin
		a:=a+1;
		if (a mod 3 = 0) then
			continue;
		writeln(a);
	end
end