#!/usr/bin/env bash
git rm -rf doc/
bundle exec rdoc --main README.rdoc --exclude tmp/ --exclude log/ --exclude bin/ --exclude db/

