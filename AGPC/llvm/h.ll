@hello1 = private constant [3 x i8] c"%d "
declare i32 @printf(i8*, ...)
define i32 @main() 
{%a = alloca i32, align 4
store i32 0, i32* %a, align 4
%s3-6 = sub i32 1, 2
%s3-10 = mul i32 3, 4
%s3-13 = sdiv i32 %s3-10, 2
%s3-8 = add i32 %s3-6, %s3-13
store i32 %s3-8, i32* %a, align 4
%s4-10 = load i32, i32* %a, align 4
%s4-11 = add i32 %s4-10, 1
%ptr4 = bitcast [3 x i8] * @hello1 to i8*
call i32 (i8*, ...) @printf(i8* %ptr4, i32 %s4-11)
ret i32 0 
}