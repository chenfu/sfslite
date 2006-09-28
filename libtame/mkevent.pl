#!/usr/bin/perl
use strict;

##
## This is a script that autogerates the file mkevent.h -- the header file
## of tame autogenerated template classes.
##

my $N_tv = 3;
my $N_wv = 3;
my $name = "_mkevent";

sub mklist ($$)
{
    my ($tmplt, $n) = @_;
    my @out;
    for (my $i = 1; $i <= $n; $i++) {
	my $a = $tmplt;
	$a =~ s/%/$i/g;
	push @out, $a;
    }
    return @out
}

sub mklist_multi (@)
{
    my @arr;
    foreach my $e (@_) {
	if (ref ($e)) {
	    push @arr, mklist ($e->[0], $e->[1]);
	} else {
	    push @arr, $e;
	}
    }
    return @arr;
}

sub commafy {
    return join (", " , @_);
}

sub arglist (@)
{
    return commafy (mklist_multi (@_));
}

sub template_arglist (@)
{
    my $al = arglist (@_);
    if (length ($al) > 0) {
	return "<" . $al . ">";
    } else {
	return "";
    }
}

sub do_mkevent_generic_cb ($$)
{
    my ($t, $w) = @_;
    if ($t > 0 || $w > 0) {
	print ("template<" , arglist (["class W%", $w], ["class T%", $t]) , 
	       "> ");
    }
    print "void\n";
    print ("${name}_cb_${w}_${t} (",
	   arglist ("ptr<closure_t> hold",
		    "ptr<joiner_t<" . arglist (["W%", $w]) . "> > j",
		    "refset_t<" . arglist (["T%", $t]) . "> rs",
		    "value_set_t<" . arglist (["W%", $w]) . "> w",
		    ["T% t%", $t]
		    ),
	   ")\n"
	   );
    
    if ($t > 0 || $w > 0) {
	print "{\n";
	print "  rs.assign (" . arglist (["t%", $t]) . ");\n";
	print "  j->join (w);\n";
	print "}\n\n";
    } else {
	print ";\n\n";
    }
}

sub do_mkevent_generic ($$)
{
    my ($t, $w) = @_;
    if ($t > 0 || $w > 0) {
	print ("template<" , arglist (["class W%", $w], ["class T%", $t]) , 
	       ">\n");
	print "typename ";
    } 
    print "callback<", arglist ("void", ["T%", $t])  , ">::ref\n";
    print ("${name} (" , 
	   arglist ("ptr<closure_t> c",
		    "const char *loc",
		    "rendezvous_t<" . arglist (["W%", $w]) . "> rv",
		    ["const W% &w%", $w],
		    ["T% &t%", $t]
		    ),
	   ")\n"
	   );
    if ($t > 0 || $w > 0) {
	print "{\n";
	print "  rv.launch_one (c);\n";
	my $tl = "";
	my @args = ("${name}_cb_${w}_${t}" .
		    template_arglist (["W%", $w], ["T%", $t]) ,
		    "c",
		    "rv.make_joiner (loc)",
		    "refset_t<" . arglist (["T%", $t]) . ">" 
		    . " (" . arglist (["t%", $t]) . ")" ,
		    "value_set_t<" . arglist (["W%", $w]) . ">"
		    . " (" . arglist (["w%", $w]) . ")");
	print "  return wrap (" . join (",\n               ", @args). ");\n";
	print "}\n\n";
    } else {
	print ";\n\n";
    }
}
    
sub do_generic ($$)
{
    my ($t, $w) = @_;
    do_mkevent_generic_cb ($t, $w);
    do_mkevent_generic ($t, $w);
}


sub do_mkevent_block ($)
{
    my ($t) = @_;
    if ($t > 0) {
	print "template<" . arglist (["class T%", $t]) . ">\n";
	print "typename ";
    }
    print "callback<" . arglist ("void", ["T%", $t]) . ">::ref\n";
    print ("${name} (" ,
	   arglist ("implicit_rendezvous_t *r",
		    "const char *loc",
		    [ "T% &t%", $t ]),
	   ")\n");
    if ($t > 0) {
	print "{\n";
	my $tl = template_arglist (["T%", $t]);
	print ("  return wrap (",
	       arglist ( "${name}_cb_${t}${tl}",
			 "r->make_reenter (loc)",
			 "refset_t<" . arglist (["T%", $t]) 
			 ."> (" . arglist (["t%", $t]) . ")"
			 ),
	       ");\n");
	print "}\n\n";
    } else {
	print ";\n\n";
    }
}

sub do_mkevent_block_cb ($)
{
    my ($t) = @_;
    if ($t > 0) {
	print "template<" . arglist (["class T%", $t]) . ">\n";
    }
    print "void\n";
    print ("${name}_cb_${t} (",
	   arglist ("ptr<reenterer_t> c",
		    "refset_t<" . arglist (["T%", $t]). "> rs",
		    ["T% t%", $t]
		    ),
	   ")\n");
    if ($t > 0) {
	print "{\n";
	print "  rs.assign (" . arglist (["t%", $t]) . ");\n";
	print "  c->maybe_reenter ();\n";
	print "}\n\n";
    } else {
	print ";\n\n";
    }
}

sub do_block ($)
{
    my ($t) = @_;
    do_mkevent_block_cb ($t);
    do_mkevent_block ($t);
}

print <<EOF;
// -*-c++-*-
//
// Autogenerated by mkevent.pl
//

#ifndef _ASYNC_MKEVENT_H_
#define _ASYNC_MKEVENT_H_

#include "tame.h"


EOF


for (my $t = 0; $t <= $N_tv; $t++) {
    do_block ($t);
    for (my $w = 0; $w <= $N_wv; $w++) {
	do_generic ($t, $w);
    }
}


print <<EOF;
#endif // _ASYNC_MKEVENT_H_ 
EOF
