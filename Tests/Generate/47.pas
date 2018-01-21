var a,b:integer;
begin
for a:=1 to 10 do begin
	if(a > 2) then 
		break;
	for b:=1 to 10 do begin
		if(b > 2) then 
			break;
	write(a,b);
	end
end
end