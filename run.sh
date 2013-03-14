#!/bin/sh

bundle exec rackup -I lib -p $1 -s thin
