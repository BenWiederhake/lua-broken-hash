#!/bin/sh

ITERATIONS=3
FILENAME="results_$(date +%s).txt"
echo "Writing to $FILENAME."

(

echo "Running $ITERATIONS iterations of each combination."
echo "This might take a while ..."

for LUA in lua5.1 lua5.2 lua5.3 luajit yourluahere
do
    if ! (command -v "$LUA") >/dev/null 2>&1
    then
        echo "$LUA not installed.  Skipping that."
    else
        for MODE in nice naughty
        do
            echo "$LUA $MODE ..."
            for _ in $(seq $ITERATIONS)
            do
                /usr/bin/time $LUA -e "require('antihash') do_$MODE()"
            done
        done
    fi
done 2>&1

) | unbuffer -p grep -v pagefaults | tee $FILENAME

echo "Done."
