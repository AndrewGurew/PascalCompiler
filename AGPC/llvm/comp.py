import os

os.system('./llc h.ll -filetype=obj')
os.system('ld h.o libc++.a -lc -e _main -arch x86_64 -macosx_version_min 10.13 -lSystem')
os.system('./a.out')
