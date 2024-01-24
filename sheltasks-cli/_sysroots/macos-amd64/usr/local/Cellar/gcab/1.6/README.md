GCab
====

A GObject library to create cabinet files

Fuzzing
-------

    CC=afl-gcc meson --default-library=static ../
    AFL_HARDEN=1 ninja
    afl-fuzz -m 300 -i ../tests/fuzzing/ -o findings ./src/gcab-fuzz @@
