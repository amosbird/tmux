#!/usr/bin/env bash

CFLAGS+=' -fcommon'
git clean -fdX && sh autogen.sh && ./configure --prefix=/tmp/gentoo/usr/local/ && make && make install
