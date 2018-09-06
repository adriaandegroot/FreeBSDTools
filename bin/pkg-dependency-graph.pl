#!/usr/bin/env perl
#
# Produces a dot file with dependency information extracted from pkg.
#
# Comes from https://forums.freebsd.org/threads/perl-script-to-plot-dependencies.55756/

use v5.010;
use warnings;

use Data::Dumper;

#############################################
sub parse_pkg_name
{
  my $name = shift;
  if ($name =~ m/(.+)-([^-]+)/)
  {
    return ($1,$2);
  } else {
    return ($name, '');
  }
}

#############################################
# Retrieve all package info
my @pkg_info_output = `pkg info -ad`;

# Record all seen package names, and all seen dependencies
my %pkgs;
my %deps;
# Links between pkg and dep
my %edges;

# Parse the results of the pkg info output
{
  my $pkg_name = '';
  my $pkg_version = '';
  foreach my $line(@pkg_info_output)
  {
    chomp $line;
    if ($line =~ m/^([^\t:]+):$/) {
      # here is pkg definition
      $pkg_name = $1;
      $pkgs{$pkg_name} = 1;

      # Set up empty dependency list
      $edges{$pkg_name} = ();
    } elsif ($line =~ m/^\t([^\t:]+)$/) {
      # here is a dependency
      my $dep_name = $1;
      $deps{$dep_name} = 1;

      # record a dependency
      push (@{$edges{$pkg_name}}, $dep_name);
    } else {
      die 'whoops';
    }
  }
}

#############################################
# print DOT format
# Print output header
say "digraph dependencies {";
# default style
say "\tnode [shape=circle style=filled color=red];";
# style the boxes
foreach my $pkg (sort keys %pkgs)
{
  my ($pkg_name,$pkg_version) = parse_pkg_name($pkg);
  print "\t\"$pkg_name\" [";
  if (!defined ($deps{$pkg})) {
    # root port (has no dependencies)
    print "shape=house color=green";
  } elsif (!defined ($edges{$pkg})) {
    # leaf port (not depended on)
    print "shape=invhouse color=red";
  } else {
    print "shape=box color=yellow";
  }
  say " style=solid label=\"$pkg_name\\n$pkg_version\"];";
}

# dependency chain
foreach my $dep (sort keys %edges)
{
  my ($dep_name,$dep_version) = parse_pkg_name($dep);
  foreach my $parent (@{$edges{$dep}})
  {
    my ($parent_name,$parent_version) = parse_pkg_name($parent);
    say "\t\"$parent_name\" -> \"$dep_name\";";
  }
}
say "}";
