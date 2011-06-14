# This represents a group of parametric roles. For example, given
# we have the declarations:
# 
#   role Foo[] { } # (which is same as role Foo { })
#   role Foo[::T] { }
#   role Foo[::T1, ::T2] { }
# 
# Each of them results in a type object that has a HOW of type
# Perl6::Metamodel::ParametricRoleHOW. In here, we keep the whole
# group of those, and know how to specialize to a certain parameter
# list by multi-dispatching over the set of possibilities to pick
# a particular candidate.
class Perl6::Metamodel::ParametricRoleGroupHOW
    does Perl6::Metamodel::Naming
    does Perl6::Metamodel::NonGeneric
{
    has @!possibilities;
    has $!selector;
    
    method new_type(:$name!) {
        my $meta := self.new(:name($name));
        pir::repr_type_object_for__PPS($meta, 'Uninstantiable');
    }
    
    method add_possibility($obj, $possible) {
        @!possibilities.push($possible);
        $!selector := 0;
    }
    
    method curry($obj, *@pos_args, *%named_args) {
        # XXX We really want to keep a cache here of previously
        # seen curryings.
        Perl6::Metamodel::CurriedRoleHOW.new_type(:curried_role($obj),
            :pos_args(@pos_args), |named_args(%named_args))
    }
    
    method specialize($obj, *@pos_args, *%named_args) {
        my $error;
        my $result;
        try {
            $result := (self.get_selector($obj))(|@pos_args, |%named_args);
            CATCH { $error := $! }
        }
        if $error {
            pir::die("None of the parametric role variants for '" ~
                self.name($obj) ~ "' matched the arguments supplied.\n" ~
                $error);
        }
        $result
    }
    
    method get_selector($obj) {
        unless $!selector {
            
        }
        $!selector
    }
}