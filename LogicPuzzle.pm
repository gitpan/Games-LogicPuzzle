package Games::LogicPuzzle;
# Perl module to help solve some logic riddles
# (C) 2004 Andy Adler

use strict;
use warnings;
use Carp;

our $VERSION= 0.13;

sub new {
    my $class = shift;
    my %args = @_;
    my $self = {
                 type => 'SimplePuzzle',
                 sameok => 0,
                 verbose => 0,
                 all_solutions => 0,
                 initialized => 0,
               };
    bless $self, $class;
    for ( keys %args ) {
        $self->ProcessArg( $_, $args{$_} );
    }
    return $self;
}

# the "Computer Science" solution is to do recursion,
# but that involves so many method calls, it's sick.
# Instead, we autogenerate the code
sub make_solve_code {
    my $self= shift();
    my $code= "";

    # autogenerate subroutines from possesions
    # such that smoke(beverage=>'beer') = get('smoke',beverage=>'beer')
    for my $poss (keys %{$self->{possesions}},
                  keys %{$self->{assignlist}}  ) {
       $code.= qq(
           sub $poss { return \$_[0]->get('$poss',\$_[1],\$_[2]) };
           );
    }
 
    my @thing     = @{$self->{things}};
    my @solve_order;
    if ( $self->{solve_order} ) {
        @solve_order = @{$self->{solve_order}};
    } else {
        @solve_order = keys %{$self->{possesions}};
    }

    # setup code, disable warnings for verify
    $code.= q(
    my @thing     = @{$self->{things}};
    my %possesion = %{$self->{possesions}};
    local $^W;
    LOOP:);

    # loop through all the possibilities
    for my $p ( @solve_order ) {
        for my $t ( 0 .. $#thing ) {
            $code .= sprintf q(
    for (@{$possesion{ "%s" }}) {
        local $thing[ %d ]->{ "%s" } = $_;
        next unless $self->verify(); ),
        $p , $t, $p;
        }
    }
    
    # now we have a solution, return it if required;
    $code.= q(
    push @solutions, clone( \@thing );
    last LOOP unless $self->{all_solutions};);

    # add all the close braces for the code
    for my $p ( @solve_order ) {
        for my $t ( 0 .. $#thing ) {
            $code .= q(
    });
        }
    }

    return $code;
}

sub solve {
    my $self = shift;
    $self->initialize() unless $self->{initialized};
    my $code = $self->make_solve_code();

    my @solutions;
    eval $code;

    return undef unless @solutions;
    return $solutions[0] unless $self->{all_solutions};
    return \@solutions;
}

sub verify {
    my $self= shift;
    if (! $self->{sameok}) {
        return 0 unless $self->verify_not_same();
    }
    my $verify_proc= $self->{verify_proc};
    return 0 unless $verify_proc->( $self, $self->{things} );

    return 1;
}

# check that no two things have same members
sub verify_not_same {
    my $self= shift;
    my @things= @{$self->{things}};
    my @posses= keys %{$self->{possesions}};
    for my $cat (@posses) {
        my %verif;
        for my $thing (@things) {
            my $thing_cat = $thing->{$cat};
            next unless $thing_cat;
            return 0 if $verif{$thing_cat};
            $verif{$thing_cat}=1;
        }
    }
    return 1;
}


sub initialize {
    my $self = shift;
    my @things= ();
    my @posses= keys %{$self->{possesions}};
    my @assign= keys %{$self->{assignlist}};
    for my $n (1 .. $self->{num_things}) {
        my %thing;
        for (@posses) {
            $thing{$_}= undef 
        }
        for (@assign) {
            $thing{$_}= $self->{assignlist}->{$_}->[$n-1]; 
        }
        push @things, \%thing;
    }
    $self->{things} = \@things;
    $self->{initialized}= 1;
}

# get all things (pers) who have $cat eq $val
sub getpers {
    my ($things, $cat, $val) = @_;

    return undef unless defined $val;
    my @getpers= grep { $_->{$cat} and 
                        $_->{$cat} eq $val } @$things;

    return @getpers;
}

# get the $want possession of the thing who's $cat is $val
sub get {
    my ($self, $want, $cat, $val, $soln) = @_;

    my $things= $self->{things};
       $things= $soln if $soln;
    my @getpers= getpers($things, $cat, $val );

    return undef unless @getpers;
    my @getwant= map {$_->{$want}} @getpers;
    return $getwant[0];
}


my %cmds = (
    num_things => \&num_things,
    possesions => \&possesions,
    sameok => \&sameok,
    verify_proc => \&verify_proc,
);

sub ProcessArg {
    my $self = shift;
    my ($cmd, $detail) = @_;
    if ($cmds{$cmd}) {
        $cmds{$cmd}->($self, $detail );
    } else {
        die "Can't $cmd $detail";
    }
}

sub num_things {
    my $self = shift;
    $self->{num_things}= shift();
}

# possesions are properties to be distributed to things
sub possesions {
    my $self = shift;
    $self->{possesions}= shift();
}

# assign are properties that are preassigned to things
sub assign {
    my $self = shift;
    $self->{assignlist}= shift();
}

sub sameok {
    my $self = shift;
    $self->{sameok}= shift();
}

sub verify_proc {
    my $self = shift;
    $self->{verify_proc}= shift();
}

# cheap clone routine
sub clone {
    my @data= @{shift()};
    my @copy;
    for (@data) {
        my %data= ( %{$_} );
        push @copy, \%data;
    }
    return \@copy;
}

sub solve_order {
    my $self = shift;
    $self->{solve_order}= shift();
}

1;

__END__
=head1 NAME

LogicPuzzle - Perl extension for helping to solve brain teaser puzzles

=head1 SYNOPSIS

    use Games::LogicPuzzle;
    my $p= new Games::LogicPuzzle (
        num_things => 5
    );
    $p->assign( { ... } );
    $p->possesions( { ... } );
    $p->verify_proc( \&my_verify );

    $solution = $p->solve();

=head1 DESCRIPTION

Games::LogicPuzzle may help you solve brain teaser puzzles where
there are lots of solution possibilities. You setup a
local subroutine which rejects wrong solutions, give
the module the working parameters, and it will do the
rest.

=head1 EXAMPLE

I initially used this to help me solve the famous problem
attributed to Einstein. Details and a manual solution can
be found here:

http://mathforum.org/library/drmath/view/60971.html

=head2 SAMPLE PUZZLE

    There are 5 houses sitting next to each other, each with a different 
    color, occupied by 5 guys, each from a different country, 
    and with a favorite drink, cigarette, and pet.  Here are the facts:

    The British occupies the red house.
    The Swedish owns a dog.
    The Danish drinks tea.
    The green house is on the left of the white house.
    The person who smokes "Pall Mall" owns a bird.
    The owner of the yellow house smokes "Dunhill".
    The owner of the middle house drinks milk.
    The Norwegian occupies the 1st house.
    The person who smokes "Blend" lives next door
        to the person who owns a cat.
    The person who owns a horse live next door to
        the person who smokes "Dunhill".
    The person who smokes "Blue Master" drinks beer.
    The German smokes "Prince".
    The Norwegian lives next door to the blue house.
    The person who smokes "Blend" lives next door to
        the person who drinks water.

    The question is: Who owns the fish?

=head2 SOLUTION CODE

This module solves this puzzle as follows:

    use Games::LogicPuzzle;
    my $p= new Games::LogicPuzzle (
        num_things => 5
    );

    $p->assign( {
        houseposition=> [ 1 .. 5 ],
    } );

    $p->possesions( {
        housecolour => [qw(blue green red white yellow)],
        nationality => [qw(Brit Dane German Norwegian Swede)],
        beverage    => [qw(beer coffee milk tea water)],
        smokebrand  => [qw(BlueMaster Dunhill PaulMaul Prince Blend)],
        pet         => [qw(cat bird fish horse dog)],
    } );

    # some solve orders are _really_ slow
    $p->solve_order( [
      "housecolour", "nationality", "beverage", "smokebrand", "pet" ]);

    $p->verify_proc( \&my_verify );

    my $soln= $p->solve();

    my $who = $p->get("nationality", "pet" => "fish", $soln);
    print "$who keeps fish";

    sub my_verify
    {
        my $c=      shift();
 
    #   1. The Brit lives in a red house. 
      { my $p = $c->housecolour(nationality => "Brit");
        return 0 if $p && $p ne "red"; }
    #   2. The Swede keeps dogs as pets. 
      { my $p = $c->pet(nationality => "Swede");
        return 0 if $p && $p ne "dog"; }
    #   3. The Dane drinks tea. 
      { my $p = $c->beverage(nationality => "Dane");
        return 0 if $p && $p ne "tea"; }
    #   4. The green house is on the left of the white house (next to it). 
      { my $p1 = $c->houseposition(housecolour => "green");
        my $p2 = $c->houseposition(housecolour => "white");
        return 0 if $p1 && $p2 && ( $p1 - $p2 != 1); #arbirary choice of left
     }
    #   5. The green house owner drinks coffee. 
      { my $p = $c->beverage(housecolour => "green");
        return 0 if $p && $p ne "coffee"; }
    #   6. The person who smokes Pall Mall rears birds. 
      { my $p = $c->pet(smokebrand => "PaulMaul");
        return 0 if $p && $p ne "bird"; }
    #   7. The owner of the yellow house smokes Dunhill. 
      { my $p = $c->smokebrand(housecolour => "yellow");
        return 0 if $p && $p ne "Dunhill"; }
    #   8. The man living in the house right in the center drinks milk. 
      { my $p = $c->beverage(houseposition => "3");
        return 0 if $p && $p ne "milk"; }
    #   9. The Norwegian lives in the first house. 
      { my $p = $c->houseposition(nationality => "Norwegian");
        return 0 if $p && $p ne "1"; }
    #  10. The man who smokes blend lives next to the one who keeps cats. 
      { my $p1 = $c->houseposition(smokebrand => "Blend");
        my $p2 = $c->houseposition(pet =>  "cats");
        return 0 if $p1 && $p2 && (abs($p2 - $p1) != 1); }
    #  11. The man who keeps horses lives next to the man who smokes Dunhill. 
      { my $p1 = $c->houseposition(pet => "horse");
        my $p2 = $c->houseposition(smokebrand => "Dunhill");
        return 0 if $p1 && $p2 && (abs($p2 - $p1) != 1); }
    #  12. The owner who smokes Blue Master drinks beer. 
      { my $p = $c->beverage(smokebrand => "BlueMaster");
        return 0 if $p && $p ne "beer"; }
    #  13. The German smokes Prince. 
      { my $p = $c->smokebrand(nationality => "German");
        return 0 if $p && $p ne "Prince"; }
    #  14. The Norwegian lives next to the blue house. 
      { my $p1 = $c->houseposition(nationality => "Norwegian");
        my $p2 = $c->houseposition(housecolour => "blue");
        return 0 if $p1 && $p2 && (abs($p2 - $p1) != 1); }
    #  15. The man who smokes blend has a neighbor who drinks water. 
      { my $p1 = $c->houseposition(smokebrand => "Blend");
        my $p2 = $c->houseposition(beverage => "water");
        return 0 if $p1 && $p2 && (abs($p2 - $p1) != 1); }
 
        return 1;
    }

The heart of the solution is the &verify subroutine. Here
is where the puzzle details are translated into a definition
of a valid solution.

Within the verify subroutine, we call 'get' with various
parameters to extract the current solution scenario. This
is then tested to see if it is correct. If the current
scenario is 'undef' then that should be verified as 'ok'

A number of 'convenience' subroutines are autodefined, so
that you can do 1) instead of 2).

   1)  my $p = $c->housecolour(nationality => "Brit");

   2)  my $p = $c->get("housecolour", 
                      "nationality" => "Brit");

When $p->solve() is called, Games::LogicPuzzle will
(somewhat intelligently) iterate through the solution space
to find a solution that satisfies &verify.

There are additional methods to get all valid solutions, and
set a variety of other parameters.

=head1 AUTHOR

Andy Adler < adler at site dot uOttawa dot ca >

All Rights Reserved. This module is free software. It may be used,
redistributed and/or modified under the same terms as Perl itself.

=cut

