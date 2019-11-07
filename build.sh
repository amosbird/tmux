#!/usr/bin/env bash

git clean -fdX && sh autogen.sh && ./configure --prefix=/home/amos/gentoo/usr/local/ && make && make install
