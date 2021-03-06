# New Install

> These are instructions for getting a system up-and-running for **me**.

Fetch the instant-workstation script, as root, and then run it.
```
# fetch https://raw.githubusercontent.com/adriaandegroot/FreeBSDTools/main/bin/instant-workstation
# sh instant-workstation
```

# Updating Jails

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

## SSL Certs

> Since I have a home "Certificate Authority" with which I sign
> my SSL certificates for in-home use (e.g. for my IMAP server),
> I need to make the CA certificate acceptable system-wide.

Sources:
 - https://forums.freebsd.org/threads/adding-certificate-to-ca_root_nss.51945/
 - https://blog.socruel.nu/freebsd/how-to-install-private-CA-on-freebsd.html (mostly this one)
 
After updating ca-nss or reinstalling, I need to tell clients about
my home CA. I have the public certificate from my home CA as `ca.crt`, and:

 - Copy `ca.crt` into `/etc/ssl/`
 - Append the contents of `ca.crt` to `/etc/ssl/cert.pem` (this is the
   big list of root-CAs, generated by *ca_root_nss*). When the certs update
   normally, this needs to be re-done.
   ```
   cat /etc/ssl/ca.crt >> /etc/ssl/cert.pem
   ```
 - Link `ca.crt` into the hashes directory by finding the hash and soft-linking.
   The `.0` at the end is important.
   ```
   cd /etc/ssl/certs
   ln -s ../ca.crt `openssl x509 -noout -hash -in ../ca.crt`.0
   ```
