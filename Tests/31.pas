var x,y,m,n: integer;

function MaxNumber(a,b: integer): integer;
   var max: integer;
begin
   if a>b then max:=a else max:=b;
   MaxNumber := max;
end;

begin
   write('Input x,y ');
   readln(x,y);
   m := MaxNumber(x,y);
   n := MaxNumber(2,x+y);
   writeln('m=',m,'n=',n);
end.
