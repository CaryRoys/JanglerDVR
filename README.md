# JanglerDVR

Storing a collection of scripts I have used over the years to scrape web streams of The Bone Jangler - a Chicago suburban area horror host TV show.

## Powershell

The latest and greatest is a powershell script.  It takes a single parameter for the download folder, and then downloads a file if it's not already in the target folder.

This makes it really easy to set up a scheduled task or CRON job or similar to just run it once a week to get episodes.

Most of this script was written by the Chromium browser dev mode, once I sniffed out the REST call which got the list of program streams.  

## Batch file stuff

Before there was powershell, there was VLC!  One could just feed in some URI's which were of live streams and dump the content at specific times. 

This is no longer necessary, but it took so long to figure out the VLC commands, it's worth parking here if I have to do something similar again.
