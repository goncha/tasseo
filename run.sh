#!/bin/sh

bundle exec rackup -I lib -p ${1:-5000} -s thin
