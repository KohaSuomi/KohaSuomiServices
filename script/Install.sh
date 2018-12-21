#!/bin/bash

DEPS=( \
  "Try::Tiny@0.30" \
  "Modern::Perl@1.20181021" \
  "Digest::SHA@5.96" \
  "Mojolicious@7.59" \
  "Mojolicious::Plugin::OpenAPI@1.17" \
  "DBIx::Class@0.082840" \
  "DBIx::Class::Migration" \
  "Exception::Class@1.44" \
  "File::Slurp@9999.19" \
  "JSON::Patch@0.04" \
)

for dep in "${DEPS[@]}"
do
  sudo cpanm $dep
done
