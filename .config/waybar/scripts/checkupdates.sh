#!/usr/bin/env bash

pkg=0
pkg=$(apt list --upgradeable 2>/dev/null | wc -l)


if [ "$pkg" -lt 45 ]; then
    echo ""
    exit
fi

class="medium"

if [ "$pkg" -ge 120 ]; then
    class="high"
fi

echo "{\"text\":\"󰚰\",\"tooltip\":\"${pkg} packages upgradeable\n\",\"class\":\"$class\"}"
