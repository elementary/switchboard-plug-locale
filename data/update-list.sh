#!/bin/bash

# basic script to update the list of available languages on apt-based systems

echo "" > langlist

for fn in $(/usr/bin/apt-cache search language-pack); do
    if [[ $fn =~ ^language-pack-[a-z][a-z]$ ]]; then
        echo ${fn##*-} >> languagelist
    fi
done


