procedure bar(c:integer);
var i:integer;
begin
	for i:=c to 10 do begin
		if(i mod 2 = 0) then
		writeln(i);
	end
end

var i:integer;
begin
	bar(i);
end