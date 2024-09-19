#!/bin/bash

WINUSER=$(perl -e 'use Env; ($_) = ${PATH} =~ /Users\/([^\/]+)\/AppData/; print;')

ln -s "/mnt/c/Users/${WINUSER}/OneDrive - Wolfe Research/" ${HOME}/docs/onedrive

# crontab
##* * * * *  rsync -av --exclude onedrive $HOME/docs/ $HOME/docs/onedrive/docs >> /tmp/cron.log 2>&1
#*/15 * * * *  rsync -a --exclude onedrive $HOME/docs/ $HOME/docs/onedrive/docs &> /dev/null
