@hello = private constant [7 x i8] c"%lf %d "
declare i32 @printf(i8*, ...)
define i32 @main() 
{%b = alloca i32, align 4
store i32 0, i32* %b, align 4
%a = alloca double, align 4
store double 0.0, double* %a, align 4
%s4-9 = add i32 1, 2
store i32 %s4-9, i32* %b, align 4
%s5-5 = load i32, i32* %b, align 4
%s5-7cast = sitofp i32 %s5-5 to double
%s5-7 = fdiv double %s5-7cast, 2.0
store double %s5-7, double* %a, align 4
%s6-10 = load double, double* %a, align 4
%s6-12 = load i32, i32* %b, align 4
%ptr = bitcast [7 x i8] * @hello to i8*
call i32 (i8*, ...) @printf(i8* %ptr, double %s6-10,i32 %s6-12)
ret i32 0 
}