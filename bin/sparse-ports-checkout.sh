#!/bin/sh
#
#   SPDX-License-Identifier: BSD-2-Clause
#   License-Filename: LICENSES/BSD-2-Clause.tcberner.adridg
#
# Checkout a shallow copy of the FreeBSD ports tree with only the
# ports given as arguments filled in. Also checks out .arcconfig
# (for convenient reviews) and Mk/ (so that there's a chance of using
# the checked-out ports tree to build something) and other ports-
# infrastructure. For a single port, that's still about 7MB.
#
# Usage:
#    sparse-ports-checkout <-n name|-a name> [-f portlist] <-p cat/port> ...
#
# Usage:
#    -n <name>     is for checking out a new sparse tree
#    -a <name>     is for working on an existing tree
#    -p <cat/port> names a port to check out
#    -f <portlist> names a file to read a list of ports from
#    -w            writable checkout (svn+ssh) instead of read-only (https)
#    -R <repopath> provide a repo-path to use
#    -d <diffnum>  checks out paths named in differential revision <diffnum>
#
# Example:
#     sparse-ports-checkout.sh -n ports-amarok \
#        -p audio/amarok-kde4 \
#        -p audio/libofa \
#        -p devel/qtscriptgenerator
#    sparse-ports-checkout.sh -n ports-kgraph \
#        -w -d 12530


### LICENSES/BSD-2-Clause.tcberner.adridg
#
# Copyright 2017 Tobias C. Berner <tcberner@FreeBSD.org>
# Copyright 2017 Adriaan de Groot <adridg@FreeBSD.org>
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 
#   1. Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#   2. Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in the
#      documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
###

# Writable vs non-writable SVN base
REP_w=svn+ssh://repo.freebsd.org/ports/head
REP=https://svn.FreeBSD.org/ports/head

unique_line ()
{
    echo `echo "$*" | tr ' ' '\n' | sort -u | tr ' ' '\n'`
}

main ()
{
    local tree=""
    local categories=""
    local ports=""

    while getopts "a:n:p:f:wR:d:" opt ; do
        case $opt in
        w)
            REP="${REP_w}"
            ;;
        R)
            REP="${OPTARG}"
            ;;
        d)
            diffnum="${OPTARG}"
            # Digits come before char 'D', extend 12296 to D12296
            if test 'D' '>' "${diffnum}" ; then
                diffnum="D${diffnum}"
            fi
            echo "Loading differential revision ${diffnum}"
            tmplist=/tmp/$$.portlist
            fetch -o - "https://reviews.freebsd.org/${diffnum}?download=true" | egrep '^[+-]{3} [^/]' | cut -d' ' -f2 | cut -d/ -f1,2 | sort -u > ${tmplist}
            category=`awk -F '/' '($1 && $2){print $1}' < ${tmplist} | sort | uniq`
            port=`awk -F '/' '($1 && $2){print $1"/"$2}' < ${tmplist} | sort | uniq`
            categories="${category} ${categories}"
            ports="${port} ${ports}"
            echo "  .. loaded" `wc -l < ${tmplist}` "ports from differential revision ${diffnum}"
            rm -f $$.portlist
            ;;
        n)
            if [ "x${tree}y" == "xy" ] ; then
                tree="${OPTARG}"
                if [ -e "${tree}" ] ; then
                    echo "argument -n '${tree}' already exists in working directory"
                    return 1
                fi
            else
                echo "multiple -n or -a arguments given: ${tree}, ${OPTARG}"
                return 1
            fi
            ;;
        a)
            if [ "x${tree}y" == "xy" ] ; then
                tree="${OPTARG}"
                if [ ! -d "${tree}" ] ; then
                    echo "argument to -a '${tree}' does not  exist in working directory, you need -n"
                    return 1
                fi
            else
                echo "multiple -n or -a arguments given: ${tree}, ${OPTARG}"
                return 1
            fi
            ;;
        p)
            category=`echo "${OPTARG}" | awk -F '/' '{print $1}'`
            port=`echo "${OPTARG}" | awk -F '/' '{print $2}'`
            if [ "x${category}y" != "xy" -a "x${port}y" != "xy" ] ; then
                categories="${category} ${categories}"
                ports="${category}/${port} ${ports}"
            else
                echo "could not understand -p argument '${OPTARG}'"
                return 1
            fi
            ;;
        f)
            if [ -f "${OPTARG}" ] ; then
                category=`cat "${OPTARG}" | awk -F '/' '($1 && $2){print $1}' | sort | uniq`
                port=`cat "${OPTARG}" | awk -F '/' '($1 && $2){print $1"/"$2}' | sort | uniq`
                categories="${category} ${categories}"
                ports="${port} ${ports}"
            else
                echo "could not read ports list from -f file '${OPTARG}'"
                return 1
            fi
            ;;
        esac
    done

    if [ "x${tree}y" == "xy" ] ; then
        echo "Need a tree argument -a, or -n"
        return 1
    fi

    if [ ! -d ${tree} ] ; then
        svn co --depth empty "${REP}" "${tree}"
    else
        svn up "${tree}"
    fi

    categories=`unique_line "${categories}"`
    ports=`unique_line "${ports}"`

    echo -e "Checking out cats:  \033[33m${categories}\033[0m"
    echo -e "Chekcout out ports: \033[33m${ports}\033[0m"

    if [ -d ${tree} ] ; then
        cd ${tree}
        echo -e "\033[32mChecking out CATEGORIES\033[0m"
        svn update --set-depth=empty ${categories}
        echo -e "\033[32mChecking out PORTS\033[0m"
        svn update --set-depth=infinity ${ports}
        echo -e "\033[32mChecking out Mk\033[0m"
    svn update --set-depth=infinity Mk Keywords Templates .arcconfig MOVED UPDATING
    fi
}

main $*
