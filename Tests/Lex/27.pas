function MaxNumber(a,b: integer): integer;
   var max: integer;
begin
   if a>b then max:=a else max:=b;
   MaxNumber := max;
end;