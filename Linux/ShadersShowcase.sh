#!/bin/sh
echo -ne '\033c\033]0;Opal Dawn\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/ShadersShowcase.x86_64" "$@"
