package Sort::PolySort;

# a module for tokenizing and sorting a list of strings
# $Id: PolySort.pm,v 0.12 1996/08/18 18:06:28 dmacks Rel $

# hacked together thingy by Daniel Macks

### module setup ###
# load anything else we need
# publicize our version
# define named spec sets
####################

use Carp;
use strict;

$Sort::PolySort::VERSION = 
	sprintf("%d.%02d", q$Revision: 0.12 $ =~ /(\d+)\.(\d+)/);
sub Version { $Sort::PolySort::VERSION }

$Sort::PolySort::DEBUG=0;	# sends a lot of debuging info to STDERR

# named spec sets (hased by name)--each is a hash of specs

$Sort::PolySort::named_spec{'datebr'} = {
	GLOBTOP	=> 0,
	LEVELS	=> 0,
	R2L	=> 1,
	NUMERIC	=> 1,
	CASE	=> 0,
	DELIM1	=> '/',
	DELIM2	=> ''
};
$Sort::PolySort::named_spec{'dateus'} = {
	GLOBTOP	=> 0,
	LEVELS	=> 1,
	R2L	=> 1,
	NUMERIC	=> 1,
	CASE	=> 0,
	DELIM1	=> '/',
	DELIM2	=> '/'
};
$Sort::PolySort::named_spec{'email'} = {
	GLOBTOP	=> 0,
	LEVELS	=> 0,
	R2L	=> 1,
	NUMERIC	=> 0,
	CASE	=> 0,
	DELIM1	=> '.',
	DELIM2	=> '@'
};
$Sort::PolySort::named_spec{'email2'} = {
	GLOBTOP	=> 0,
	LEVELS	=> 2,
	R2L	=> 1,
	NUMERIC	=> 0,
	CASE	=> 0,
	DELIM1	=> '.',
	DELIM2	=> '@'
};
$Sort::PolySort::named_spec{'emaild'} = {
	GLOBTOP	=> 1,
	LEVELS	=> 1,
	R2L	=> 1,
	NUMERIC	=> 0,
	CASE	=> 0,
	DELIM1	=> '.',
	DELIM2	=> '@'
};
$Sort::PolySort::named_spec{'ip'} = {
	GLOBTOP	=> 0,
	LEVELS	=> 4,
	R2L	=> 0,
	NUMERIC	=> 1,
	CASE	=> 0,
	DELIM1	=> '.',
	DELIM2	=> ''
};
$Sort::PolySort::named_spec{'name'} = {
	GLOBTOP	=> 0,
	LEVELS	=> 0,
	R2L	=> 1,
	NUMERIC	=> 0,
	CASE	=> 0,
	DELIM1	=> ' ',
	DELIM2	=> ''
};

### constructor ###
# create a new polysort object, possibly with the given named specs
###################
sub new {
	my $name=shift;
	my $specname=(shift || 'name');	# default specs
	my $me=bless {
		GLOBTOP=>0,
		LEVELS=>0,
		R2L=>0,
		NUMERIC=>0,
		CASE=>0,
		DELIM1=>'',
		DELIM2=>'',
	},$name;

	$me->by($specname);
	$me;
}

### destructor ###
# nothing to clean up
##################
sub DESTROY {
}

### public method ###
# set the named specs
#####################
sub by {
	my $me=shift;
	my $specname=shift or croak "No specname given";
	my %specs;

	( %specs = %{ $Sort::PolySort::named_spec{$specname} } )
		? $me->set(%specs)
		: croak "Never heard of specname \"$specname\"";
	warn("Sort::PolySort::by: \"$specname\" installed\n") if $Sort::PolySort::DEBUG;
}

### public method ###
# sets up the sort specs based on the passed associative array
#####################
sub set {
	my $me=shift;
	my %specs=@_;

	foreach (keys %specs) {
		$me->{$_}=$specs{$_};
	};
	warn("Sort::PolySort::set: ".scalar(keys %specs)." specs set\n") if $Sort::PolySort::DEBUG;
}

### public method ###
# returns associtive array of current sort specs
#####################
sub get {
	my $me=shift;
	%$me;
}

### public methods ###
# does the requested sort by temporarily changing the sort specs
######################
sub sortby {
	my $me=shift;
	my $specname=shift or croak "No specname given";

	my %prevspecs=$me->get;		# save what's there now
	$me->by($specname);		# change to new spec
	my @sorted=$me->sort(@_);	# do the sort
	$me->set(%prevspecs);		# restore the old specs

	@sorted;			# return the sorted results
}

### public methods ###
# sorts the passed array
######################
sub sort {
	my $me = shift;
	my @orig = @_;
	my @sorted;

	if ($Sort::PolySort::DEBUG) {
		warn("Sort::PolySort::sort: sort specs:\n");
		foreach (sort keys %$me) {
			warn("\t$_\t".$me->{$_}."\n");
		};
	};

	my($delim1,$delim2)=($me->{DELIM1},$me->{DELIM2});
	my($regex1,$regex2)=(quotemeta $delim1,quotemeta $delim2);

		# need global so don't have to dereference in sort sub
	@Sort::PolySort::sortkeys=();

	my($key,@key,$low);
	my $lprec = ( $me->{R2L} ? '.*' : '.*?' );

	foreach (@orig) {
		$key=$_;
		$key=lc $key unless $me->{CASE};	# deal with mixed case

		if (length($regex2)) {
			($low,@key)=( $me->{R2L}
				? ($key=~/^(.*)$regex2(.*)$/)
				: ($key=~/^(.*?)$regex2(.*)$/)
			);
		} else {
			@key=($key);
		};

					# break the high precedence stuff
		@key=split(/$regex1/,pop @key);

		if ($me->{GLOBTOP}) {	# deal with top-level globbing
			$me->{R2L}
				? push @key,join($delim1,splice(@key,-2))
				: unshift @key,join($delim1,splice(@key,0,2));
		};

		@key=reverse @key if $me->{R2L};	# reverse if necesary

		if ($me->{LEVELS}) {		# pick the important levels
			$key=join("\0",splice(@key,0,$me->{LEVELS}));
		} else {
			$key=join("\0",@key);
		};

		$key.="\0$low" if length($regex2);	# bring back low prec

		if ($me->{LEVELS} && @key) {
			@key=reverse @key if $me->{R2L};
			$key.="\0".join($delim1,@key);
		};

					# stash in global lol (ugh!)
		push @Sort::PolySort::sortkeys,$key;
	};

	if ($Sort::PolySort::DEBUG) {
		warn("Sort::PolySort::sort: parse results:\n");
		my $key;
		foreach (@Sort::PolySort::sortkeys) {
			($key=$_)=~s/\0/\t/g;
			warn("\t=$key=\n");
		};
	};

	$me->{NUMERIC}
		? (@sorted=@orig[ sort Sort::PolySort::_num 0 .. $#orig ])
		: (@sorted=@orig[ sort Sort::PolySort::_str 0 .. $#orig ]);
	@sorted;
}

### private methods ###
# perlfunc sort() comparison for strings
#######################
sub _str {
	$Sort::PolySort::sortkeys[$a] cmp $Sort::PolySort::sortkeys[$b];
}

### private methods ###
# perlfunc sort() comparison for numbers
#######################
sub _num {
	my @a = split(/[\0,\/]/, $Sort::PolySort::sortkeys[$a] );
	my @b = split(/[\0,\/]/, $Sort::PolySort::sortkeys[$b] );
	my $c = 0;

	while ( !$c && @a && @b ) {
		$c = ( shift @a <=> shift @b );
	};
	$c =  1 if !$c && @a;
	$c = -1 if !$c && @b;

	$c;
}

1;
__END__

=head1 NAME

	Sort::PolySort -- general rules-based sorting of lists

=head1 SYNOPSIS

	use Sort::PolySort;
	$s=new Sort::PolySort;			# defaults to 'name'
	@people=('John Doe','Jane Doll','John Quasimodo Doe');
	print join(", ",$s->sort(@people),"\n";
	
	use Sort::PolySort;
	$s=new Sort::PolySort('dateus');	# sets internal
	@dates=$s->sort(@dates);		# uses internal
	$s->by('email');			# sets internal
	@names=$s->sortby('name',@names);	# overrides internal
	@emails=$s->sort(@emails);		# internal is still 'email'

=head1 DESCRIPTION

This module provides methods to sort a list of strings based on 
parsing the strings according to a configurable set of specifications.

=head2 METHODS

The following methods are available:

=over 12

=item I<new>

Creates a new polysort object. Takes optional arguement of initial
named spec set (defaults to I<name>).

=item I<by>

Configures for the named set of sorting specs. Arguement is name of spec set.

=item I<sort>

Sorts by the previously-set (by I<new> or I<by>) specs. Arguement is a
list of items to sort. Returns the sorted list, leaving the original
unchanged.

=item I<sortby>

Sorts by the given (named) set of specs. The specs are only changed for
this particular sort, so future calls to I<sort> will use whatever
specs were in effect before the I<sortby> call. First arguement is
name of spec set, second arguement is a list of items to sort. Returns
the sorted list, leaving the original unchanged.

=item I<get>

Returns an associative array of the current sort specs. See L</"NOTES">.

=item I<set>

Sets the current sort specs to the given associative array. Specs not
appearing in the passed array retain their previous values, so this
method can be used along with I<get> to keep state during a subroutine
call or to alter particular specs to get new sorting
results. Arguement is an associative array. See L</"NOTES">.

=back

=head2 Specs

The following specifications are local to each Sort::PolySort object:

=over 10

=item C<GLOBTOP>

Lump last two levels together?

=item C<LEVELS>

Number of levels to consider (0=all)

=item C<R2L>

Count fields right to left?

=item C<NUMERIC>

Do numerical sort?

=item C<CASE>

Do case-sensitive sort?

=item C<DELIM1>

Primary element delimiter (must not be null).

=item C<DELIM2>

Secondary element delimiter (can be null).

=back

=head2 Parsing Scheme

The following order is followed to determine the keys used to sort the
given array:

=over 3

=item 1

I<DELIM2> (if given)

Remove up to leftmost (rightmost if I<R2L> is true) occurance of I<DELIM2> 
(will be brought back later).

=item 2

I<DELIM1>

Split remainder at all occurances of I<DELIM1>.

=item 3

I<GLOBTOP> (if true)

Rejoin left (right if I<R2L> is true) 2 elements (always joined left-to-right, 
regardless of I<R2L>).

=item 4

I<R2L> (if true)

Reverse list of elements.

=item 5

I<LEVELS>

Store first I<LEVELS> (all if =0) elements (last 2 considered as a 
single element if I<GLOBTOP> is true).

=item 6

I<DELIM2> (if true)

Store string from left of I<DELIM2> as next element.

=item 7

I<LEVELS> (unless 0)

Rejoin remaining elements (in original order, regardless of I<R2L>) and 
store as next element.

=back

=head2 Named Specs

The following (case-sensitive) names are used by I<new>, I<by> and
I<sortby> to represent pre-defined sets of specs:

=over 10

=item I<datebr>

by European (dd/mm/yy) date

=item I<dateus>

by US-style (mm/dd/yy) date

=item I<email>

by user for each machine (all parts of FQDN)

=item I<email2>

by user for each top-level domain (last 2 atoms)

=item I<emaild>

by user for each domain-name (next-to-last atom)

=item I<ip>

by numerical (aaa.bbb.ccc.ddd) ip address

=item I<name>

by last name/first name/middle name or initials

=back

=head1 ERRORS

The following errors may occur:

=over 10

=item B<No specname given>

I<by> or I<sortby> wasn't passed a specname. 

=item B<Never heard of specname ``foo''>

I<new>, I<by>, or I<sortby> was passed a name that was not in the list of
known specnames.

=back

=head1 NOTES

The whole parsing method is pretty perverse, but honestly was the first
thing that came to mind. It works, but is not very fast or extensible.
Enough interested folks mailed me that I wanted to get this out now, but
it's dyin' for a rewrite. So this is just a beta. The main interface will
remain the same, but the parser will be rewritten and the spec variables
changed. Accessor methods will change as a result (using C<%s=$s->get; ...
;$s->set(%s) will probably still work to save state, though). And accessor
methods wll be added so that new names spec sets can be added at runtime
or known ones modified. And new named spec sets will be added. And on and
on and on... 

=head1 AUTHOR

Daniel Macks <dmacks@netspace.org>

=head1 COPYRIGHT

Copyright (c) 1996 by Daniel Macks. All rights reserved.
This module is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut
