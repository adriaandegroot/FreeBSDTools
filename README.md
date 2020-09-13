# FreeBSD (new) Committer's Tools

> This repo contains notes from my new-committer period, as well as links 
> to useful FreeBSD resources (mostly for new committers) and some tools 
> of mixed parentage.

## Links

* [Committer's Guide](https://www.freebsd.org/doc/en_US.ISO8859-1/articles/committers-guide/) -- [log messages](https://www.freebsd.org/doc/en_US.ISO8859-1/articles/committers-guide/commit-log-message.html)
* [Porter's Handbook](https://www.freebsd.org/doc/en_US.ISO8859-1/books/porters-handbook/book.html)
* [FreeBSD bugzilla](https://bugs.freebsd.org/)
* [FreeBSD phab](https://reviews.freebsd.org/)
* [FreeBSD package builders](https://pkg-status.freebsd.org/)

## Tools

* [instant-workstation](bin/instant-workstation)
  > This script uses `dialog(1)` to ask a few questions, and then
  > installs the software and configuration needed for that workstation-use.
  > It is tailored to my needs, but accepts PRs for other uses.
* [sparse-checkout](bin/sparse-ports-checkout.sh)
  > This script checks out a (writable) ports-tree suitable for working
  > on individual ports. The ports tree is checked out in *sparse*
  > mode, which means that you only get the bits needed to modify
  > and build the ports you ask for. Can also be used to create
  > a ports tree from a Phab review. Joint work with tcberner@
  >
  > Typical use is to create a writable checkout (that is, one over
  > ssh which you can commit from) with a particular name, for one
  > or more ports that need to be modified:
  >     sparse-ports-checkout.sh -w -n ports-tree-name -p category/portname
* [bump_revision](bin/bump_revision.rb)
  > This script bumps the `PORTREVISION` value in each named
  > port, by editing the Makefile. If no `PORTREVISION` exists,
  > adds one with value 1.
* Ports graphs [perl](bin/pkg-dependency-graph.pl) [python](bin/pkg-dependency-graph.py)
  > Both scripts use dot (`graphics/graphviz`) to produce a graph of the 
  > dependencies for a given port. Both use the output from `pkg` to
  > obtain the dependency tree.


## Instructions

* [Updating with jails](UPDATING.md)

## Contributors

The work in this repository is not only my own. Other contributors
alphabetically by first name or nickname are:

- natethegreat44
- Tobias Berner
