@hello = private constant [2 x i8] c"%d"
declare i32 @printf(i8*, ...)
define i32 @main() 
{%b = alloca i32, align 4
%a = alloca i32, align 4
%c = alloca i32, align 4
store i32 200, i32* %b, align 4
store i32 200, i32* %c, align 4
%s5-5 = load i32, i32* %b, align 4
%s5-7 = load i32, i32* %c, align 4
%s5-6 = add nsw i32 %s5-5, %s5-7
store i32 %s5-6, i32* %a, align 4
%s6-8 = load i32, i32* %a, align 4
%ptr = bitcast [2 x i8] * @hello to i8*
call i32 (i8*, ...) @printf(i8* %ptr, i32 %s6-8)
ret i32 0 
}