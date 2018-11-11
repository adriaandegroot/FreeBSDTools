# Updating instructions

> These are the instructions for **my** update process, written
> down mostly so I can cut-and-paste them in future.
> Since I have a host (running 11-STABLE) which has some
> jails managed by ezjail and some jails managed by poudriere,
> it all takes a little bit of messing around to do one round
> of updating. I generally do this together with a big update
> of all my packages.

```
# Make sure sources are up-to-date
cd /usr/src
svn up
# Do build on host
make -j6 buildworld && make -j6 buildkernel 
make installkernel && mergemaster -p -FU
make installworld && mergemaster -FU
# Update the jails
ezjail-admin update -i
# Update the poudriere jail
poudriere jail -u -j 111amd64 -m src=/usr/src
# Reboot and resume into new environment
reboot
# Build all packages that are needed for the "roots" (not-autoinstall)
poudriere bulk -j 111amd64 -p github-kde -t -c `pkg-dependency-graph.py --roots`
```
