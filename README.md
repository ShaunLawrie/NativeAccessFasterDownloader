# Native Access Faster Downloader

You can start all the downloads in the legit installer then pause them all and run this script and it will download all the partially downloaded files into the user downloads folder. Then you can just run the exes in the installer zips or disk images to install the applications.

Next time you launch the Native Access app it will detect the apps are installed and activate them.  

The Native Access installer downloads with a single TCP stream because it's not passing a parallel download flag to the aria2 exe that's packaged with it. All this does is uses the metadata files at `C:\.native-instruments.tmp\` to kick off the aria2 downloader with this flag set `--max-connection-per-server=10`