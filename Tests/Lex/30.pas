var x,y,m,n: integer;

procedure MaxNumber(a,b: integer; var max: integer);
begin
   if a>b then max:=a else max:=b;
end;

begin
   write('Input x,y ');
   readln(x,y);
   MaxNumber(x,y,m);
   MaxNumber(2,x+y,n);
   writeln('m=',m,'n=',n);
end.
