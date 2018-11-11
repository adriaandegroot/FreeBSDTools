#! /usr/bin/env python3.6
#
# A script to generate a .dot file (Graphviz) from installed
# packages, to show what depends on what. Prints the dot code
# to standard output.
#
# Use the option --root to print out, one per line, the roots
# of the forest of installed packages (this suppresses regular
# dot output).

import argparse
import os
import subprocess
import sys

if sys.version_info < (3, 5):
    raise ValueError("Python 3.5 or later is required.")

def collect_pkg():
    """
    Run pkg, and returns a dictionary
    where the keys are names of packages,
    and the values are lists of packages that the key depends on.
    """
    deps = {}
    PKG = "/usr/sbin/pkg"
    QUERY = "query"

    # Gather all packages, init deps to an empty dependency list per package
    r = subprocess.run(
        [PKG, QUERY, "%o"],
        stdout=subprocess.PIPE)
    output = r.stdout.split(b"\n")
    for line in output:
        if line:
            line = line.decode("ascii")
            deps[line] = []

    # Now build up the dependency graph
    r = subprocess.run(
        [PKG, QUERY, "%o::%do"], 
        stdout=subprocess.PIPE)
    output = r.stdout.split(b"\n")
    for line in output:
        if line:
            line = line.decode("ascii")
            package, dep = line.split("::")
            deps[package].append(dep)
    
    return deps
    
def normalize_deps(deps):
    """
    Normalize the dependencies.
    
    A package in @p deps now has a dependency list that contains
    all the transitive dependencies; prune it down to only the
    first-level dependencies.
    """
    normalized_deps = {}
    for key in deps.keys():
        all_deps = set(deps[key])
        second_deps = set()
        for k in all_deps:
            second_deps.update(set(deps[k]))

        l = list(all_deps - second_deps)
        l.sort()
        
        normalized_deps[key] = l
        
    return normalized_deps

def count_reverse(deps):
    """
    For a dependency graph pkg -> [pkgs], returns a dictionary
    with pkg as key, and the number of *other* packages that depend
    on this one. May be done with a normalized, or not-normalized graph.
    
    The keys that keep count 0 are the "root" nodes of the forest of
    installed packages.
    """
    reverse_count = {}
    for key in deps.keys():
        reverse_count[key] = 0
    for key in deps.keys():
        for d in deps[key]:
            # These are the packages that k depends on, so they all get +1
            reverse_count[d] += 1
            
    return reverse_count
    
def parse_args():
    parser = argparse.ArgumentParser(description="pkg(8) graphing tool")
    parser.add_argument("--roots", "-r", dest="roots", action="store_true", default=False)
    return parser.parse_args()
    
def do_graph(dependency_graph):
    packages = list(dependency_graph.keys())
    packages.sort()

    print("### Root nodes:\n###\n#")
    count = count_reverse(dependency_graph)
    for k in packages:
        if count[k] == 0:
            print("#  p%d %s" % (packages.index(k), k))
            
    print("digraph {")
    for k in packages:
        print("  p%d [label=\"%s\"];" % (packages.index(k), str(k)))
        
    c = 1
    for k in packages:
        for dep in dependency_graph[k]:
            print("  p%d -> p%d;" % (packages.index(k), packages.index(dep)) )
            
    print("}")
    
def do_roots(dependency_graph):
    count = count_reverse(dependency_graph)
    packages = list(dependency_graph.keys())
    packages.sort()
    for k in packages:
        if count[k] == 0:
            print(k)
    
if __name__ == "__main__":
    args = parse_args()
    dependency_graph = normalize_deps(collect_pkg())

    if args.roots:
        do_roots(dependency_graph)
    else:
        do_graph(dependency_graph)
        
