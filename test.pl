# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };

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

$p->solve_order( [
    "housecolour", "nationality", "beverage", "smokebrand", "pet", ] );

$p->verify_proc( \&my_verify );


my $soln= $p->solve();
my $who = $p->get("nationality", "pet" => "fish", $soln);

ok ($who, "German" );

sub my_verify
{
    my $c=      shift();
    my @pers= @{shift()};
    my $p;

#   1. The Brit lives in a red house. 
    $p = $c->get("housecolour", 
                 "nationality" => "Brit");
    return 0 if $p && $p ne "red";
#   2. The Swede keeps dogs as pets. 
    $p = $c->get("pet",
                 "nationality" => "Swede");
    return 0 if $p && $p ne "dog";
#   3. The Dane drinks tea. 
    $p = $c->get("beverage",
                 "nationality" => "Dane");
    return 0 if $p && $p ne "tea";
#   4. The green house is on the left of the white house (next to it). 
    $p1 = $c->get("houseposition", "housecolour" => "green");
    $p2 = $c->get("houseposition", "housecolour" => "white");
    return 0 if $p1 && $p2 && ( $p1 - $p2 != 1); #arbirary choice of left
#   5. The green house owner drinks coffee. 
    $p = $c->get("beverage", 
                 "housecolour" => "green");
    return 0 if $p && $p ne "coffee";
#   6. The person who smokes Pall Mall rears birds. 
    $p = $c->get("pet",
                 "smokebrand" => "PaulMaul");
    return 0 if $p && $p ne "bird";
#   7. The owner of the yellow house smokes Dunhill. 
    $p = $c->get("smokebrand",
                 "housecolour" => "yellow");
    return 0 if $p && $p ne "Dunhill";
#   8. The man living in the house right in the center drinks milk. 
    $p = $c->get("beverage",
                 "houseposition" => "3");
    return 0 if $p && $p ne "milk";
#   9. The Norwegian lives in the first house. 
    $p = $c->get("houseposition",
                 "nationality" => "Norwegian");
    return 0 if $p && $p ne "1";
#  10. The man who smokes blend lives next to the one who keeps cats. 
    $p1 = $c->get("houseposition", "smokebrand" => "Blend");
    $p2 = $c->get("houseposition", "pet" =>  "cats");
    return 0 if $p1 && $p2 && (abs($p2 - $p1) != 1);
#  11. The man who keeps horses lives next to the man who smokes Dunhill. 
    $p1 = $c->get("houseposition", "pet" => "horse");
    $p2 = $c->get("houseposition", "smokebrand" => "Dunhill");
    return 0 if $p1 && $p2 && (abs($p2 - $p1) != 1);
#  12. The owner who smokes Blue Master drinks beer. 
    $p = $c->get("beverage",
                "smokebrand" => "BlueMaster");
    return 0 if $p && $p ne "beer";
#  13. The German smokes Prince. 
    $p = $c->get("smokebrand",
                 "nationality" => "German");
    return 0 if $p && $p ne "Prince";
#  14. The Norwegian lives next to the blue house. 
    $p1 = $c->get("houseposition", "nationality" => "Norwegian");
    $p2 = $c->get("houseposition", "housecolour" => "blue");
    return 0 if $p1 && $p2 && (abs($p2 - $p1) != 1);
#  15. The man who smokes blend has a neighbor who drinks water. 
    $p1 = $c->get("houseposition", "smokebrand" => "Blend");
    $p2 = $c->get("houseposition", "beverage" => "water");
    return 0 if $p1 && $p2 && (abs($p2 - $p1) != 1);

    return 1;
}
