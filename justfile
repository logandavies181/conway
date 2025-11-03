@build-windows:
    zig build -Dtarget=x86_64-windows

@run: build-windows
    ./zig-out/bin/conway.exe
