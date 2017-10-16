program name;
var
	a,b,c:SomeType;
	a: arrray[0..123] of someType
begin
 	a:=%1011101;
 	b:=$ff132;
 	c:=&7623;

	a+=b + c + 1.5233 + 1.23e3;
	if(a<>b) writeln('Ok');
	else writeln('Error');

end.