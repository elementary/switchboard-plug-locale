#!/bin/bash

# basic script to update the list of available languages on apt-based systems

rm ../data/languagelist

for fn in $(/usr/bin/apt-cache search language-pack); do
    if [[ $fn =~ ^language-pack-[a-z][a-z]$ ]]; then
        echo ${fn:14} >> ../data/languagelist
    fi
    if [[ $fn =~ ^language-pack-[a-z][a-z][a-z]$ ]]; then
        echo ${fn:14} >> ../data/languagelist
    fi
done

#adding Chinese as a language because I have no clue to proper regex this out of language-pack-blah
echo "zh" >> ../data/languagelist
