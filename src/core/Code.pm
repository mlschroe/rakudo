my class Code does Callable {
    multi method ACCEPTS(Code:D $self: Mu $topic) {
        $self.count ?? $self($topic) !! $self()
    }
    
    method arity(Code:D:) { $!signature.arity }
    
    method count(Code:D:) { $!signature.count }
    
    method signature(Code:D:) { $!signature }
    
    multi method Str(Code:D:) { self.name }

    method leave(Code:D $self: |$) {
        my Mu $rpa := pir::perl6_current_args_rpa__P();
        my Mu $code := nqp::shift($rpa);
        pir::perl6_leave_block__1PP($code, nqp::p6parcel($rpa, Nil))
    }
}
