#!/usr/bin/env ruby
#
#   SPDX-License-Identifier: BSD-2-Clause
#   License-Filename: LICENSES/BSD-2-Clause.tcberner.adridg
#
### USAGE
#
# Bumps the PORTREVISION in named directories.
#    bump_revision <dir> ...
# For each named <dir>, tries to bump the PORTREVISION
# in the Makefile in dir. Generally, call this with
# paths relative to a ports tree checkout, e.g.
#    bump_revision devel/cmake devel/cmake-doc
#
### END USAGE


def get_revision(makefile)
	File.readlines(makefile).each do |line|
		if line =~ /\APORTREVISION.*[0-9]+/
			return line.strip.split(/\s+/).last
		end
	end
	return nil
end

def next_revision(num)
	num ||= 0
	return num.to_i + 1
end

def add_portrevision(makefile)
	lines = File.readlines makefile
	# Order according to portlint:
	#     PORTNAME PORTVERSION DISTVERSIONPREFIX DISTVERSION DISTVERSIONSUFFIX PORTREVISION
	pn  = lines.index{|l| l =~ /\APORTNAME.?=.*[A-Za-z]+/} || 0
  pv  = lines.index{|l| l =~ /\APORTVERSION.?=/} || 0
	dvp = lines.index{|l| l =~ /\ADISTVERSIONPREFIX.?=/} || 0
	dv  = lines.index{|l| l =~ /\ADISTVERSION.?=/} || 0
	dvs = lines.index{|l| l =~ /\ADISTVERSIONSUFFIX.?=/} || 0
	no  = [pn, pv, dvp, dv, dvs].sort.last

	puts "adding PORTERVISION=1 to  #{makefile}"
	lines.insert no+1, "PORTREVISION=\t1\n"
	File.open(makefile,'wb'){|f| f.write(lines.join)}
end

def bump_revision(makefile)
	lines = File.readlines makefile
	rev = get_revision makefile
	if rev
		pr = lines.index{|l| l =~ /\APORTREVISION.?=.*[0-9]+/}
		line = lines[pr]
		nrev = next_revision rev
		puts "bumping #{makefile} from #{rev} to #{nrev}"
		newline = line.gsub(rev.to_s, nrev.to_s)
    lines[pr] = newline
    File.open(makefile,'wb'){|f| f.write(lines.join)}
	else
		add_portrevision makefile
	end
end

args = ARGV
if args.length == 0
	puts "no arguments given"
	return 1
end

args.each do |arg|
	makefile = File.join arg, "Makefile"
	next unless File.directory?(arg)
  unless File.exist?(makefile)
    puts "skipping #{arg}"
    next
  end
	revision = get_revision(makefile)
	nextrevision = next_revision(revision)
	bump_revision makefile
end
