# lua-broken-hash

> Lua has broken hashes, and is unusable.

This is a proof of concept that Lua is unusable for
anything where similar strings might appear in a table.

These strings don't even need to be adversarial!
Lua uses sparse hashes, and reads only 16-31 bytes.
And there's basically only two implementations of lua,
so collisions happen whenever your strings are equal
in those 16-31 bytes.

## Table of Contents

- [Unpredictable Running Time](#unpredictable-running-time)
- [How It Works](#how-it-works)
- [Usage](#usage)
- [TODO](#todo)

## Unpredictable Running Time

The running times are unpredictable.
We insert 64K keys into a table, and here's how long it takes:

```
lua5.1 nice ...
0.17user 0.00system 0:00.18elapsed 98%CPU (0avgtext+0avgdata 10280maxresident)k
0.18user 0.00system 0:00.19elapsed 97%CPU (0avgtext+0avgdata 10284maxresident)k
0.17user 0.00system 0:00.18elapsed 99%CPU (0avgtext+0avgdata 10444maxresident)k
lua5.1 naughty ...
57.83user 0.25system 0:58.41elapsed 99%CPU (0avgtext+0avgdata 10280maxresident)k
57.85user 0.99system 0:59.35elapsed 99%CPU (0avgtext+0avgdata 10280maxresident)k
58.43user 0.94system 1:00.04elapsed 98%CPU (0avgtext+0avgdata 10280maxresident)k
lua5.2 nice ...
0.16user 0.00system 0:00.25elapsed 66%CPU (0avgtext+0avgdata 9956maxresident)k
0.16user 0.02system 0:00.18elapsed 97%CPU (0avgtext+0avgdata 9952maxresident)k
0.17user 0.00system 0:00.17elapsed 99%CPU (0avgtext+0avgdata 9952maxresident)k
lua5.2 naughty ...
62.13user 0.87system 1:03.59elapsed 99%CPU (0avgtext+0avgdata 9948maxresident)k
61.61user 0.57system 1:02.59elapsed 99%CPU (0avgtext+0avgdata 9948maxresident)k
62.65user 0.59system 1:03.80elapsed 99%CPU (0avgtext+0avgdata 9952maxresident)k
lua5.3 nice ...
0.12user 0.01system 0:00.16elapsed 84%CPU (0avgtext+0avgdata 9296maxresident)k
0.13user 0.01system 0:00.15elapsed 97%CPU (0avgtext+0avgdata 9300maxresident)k
0.12user 0.00system 0:00.13elapsed 97%CPU (0avgtext+0avgdata 9292maxresident)k
lua5.3 naughty ...
57.53user 0.47system 0:58.51elapsed 99%CPU (0avgtext+0avgdata 9204maxresident)k
58.37user 1.16system 1:00.09elapsed 99%CPU (0avgtext+0avgdata 9204maxresident)k
58.45user 0.92system 0:59.98elapsed 98%CPU (0avgtext+0avgdata 9204maxresident)k
luajit nice ...
0.45user 0.02system 0:00.51elapsed 91%CPU (0avgtext+0avgdata 8316maxresident)k
0.40user 0.00system 0:00.41elapsed 99%CPU (0avgtext+0avgdata 8404maxresident)k
0.43user 0.00system 0:00.44elapsed 97%CPU (0avgtext+0avgdata 8412maxresident)k
luajit naughty ...
47.17user 0.59system 0:48.12elapsed 99%CPU (0avgtext+0avgdata 8348maxresident)k
48.08user 0.53system 0:49.09elapsed 99%CPU (0avgtext+0avgdata 8344maxresident)k
48.40user 0.41system 0:49.25elapsed 99%CPU (0avgtext+0avgdata 8344maxresident)k
```

That's somewhere between 100x and 1000x difference, for the same code,
even across implementations.

## How It Works

Both Lua and luajit use sparse hashes.  So let's use the string `Proof of concept that small changes get lost.` as an example:

    Source string:
    Proof of concept that small changes get lost.
    What lua sees:
    __o_f_o_ _o_c_p_ _h_t_s_a_l_c_a_g_s_g_t_l_s_.
    What luajit sees:
    Proo______once______t sm_________________ost.

For longer strings, the gaps are even larger.  Now you have a lot of strings
that only differ where your implementation doesn't read from, and bam, you have seriously bad running time.

"Nice" and "naughty" do the same thing: Insert 64K strings as keys in a table.

The only difference is that the "nice" strings differ in places that will be considered by lua/luajit (thus resulting in different hashes, usually).

In contrast, the "naughty" strings only differ in places that will *not* be considered by lua/luajit (thus resulting in lots of collisions, meaning O(n) access times).  In other words: **Slow as hell.**

## Usage

The main code is in `antihash.lua`.  As you can see, the functions `do_naughty()`
and `do_nice()` just create a table, insert 64K (well, 65025) strings as keys
into them (the value doesn't matter), and are done.

Note that the strings are similar, but there's no brute-force hash-breaking going on.
Lua's hashes just are that bad.

I wrote and used `run_antihash.sh` to generate the [above results](#unpredictable-running-time).

If you have a nice lua implementation that is neither lua nor luajit and want to test it,
you can check whether it even looks at those positions by
changing `yourluahere` to your lua implementation.
Note that "merely not failing" does not imply that your lua implementation uses a sane hashing scheme.

## TODO

I don't know what's wrong with lua.
Hashing is avoided because "it's faster", thus making lua slower.

There's a [HashDOS patch](http://lua-users.org/wiki/HashDos) floating around.
Note that it isn't in mainstream lua 5.2.4 nor 5.3 nor luajit.

Even "we must be faster than C"-Rust has accepted that string hashing and hashing in general
needs to be [safe by default](https://github.com/rust-lang/rust/blob/master/src/libstd/collections/hash/map.rs#L2523).

Meanwhile, in lua you could probably write a poem where each line has the same hash.
(Take this as a challenge!)

Alright, maybe SipHash is overkill for lua.  But at least *looking at the input* should be a
good start for a hash function that doesn't make the language feel like a minefield where
inserting your data as keys could make it grind to a halt.
It's not like hashing was invented yesterday.
