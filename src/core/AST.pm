# XXX: Would like to have this class as Perl6::AST, but ran up against
#      problems with the serialization context calling it that.
my class AST {
    has $!past;

    submethod BUILD(:$past) {
        $!past := $past;
    }
}
