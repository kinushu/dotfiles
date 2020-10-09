#!/bin/bash

set -eu

cd ~/.rbenv
git pull

cd ~/.rbenv/plugins/ruby-build
git pull

brew update
