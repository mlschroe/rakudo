my class Exception {
    has $!ex;

    method backtrace() { Backtrace.new(self) }

    method Str() {
        nqp::p6box_s(nqp::atkey($!ex, 'message'))
    }

    multi method Numeric(Exception:D:) {
        self.Str.Numeric()
    }

    method throw() {
        nqp::bindattr(self, Exception, '$!ex', pir::new('Exception'))
            unless pir::defined($!ex);
        pir::setattribute__vPsP($!ex, 'payload', pir::perl6_decontainerize__PP(self));
        pir::throw__0P($!ex)
    }
    method rethrow() {
        pir::rethrow__0P($!ex)
    }

    method Bool() { False }
}

sub EXCEPTION(|$) {
    my Mu $parrot_ex := nqp::shift(pir::perl6_current_args_rpa__P());
    my Mu $payload   := nqp::atkey($parrot_ex, 'payload');
    if nqp::p6bool(pir::type_check__IPP($payload, Exception)) {
        nqp::bindattr($payload, Exception, '$!ex', $parrot_ex);
        $payload;
    } else {
        my $ex := nqp::create(Exception);
        nqp::bindattr($ex, Exception, '$!ex', $parrot_ex);
        $ex;
    }
}


do {
    sub is_runtime($bt) {
        for $bt.keys {
            try {
                return True if nqp::iseq_s($bt[$_]<sub>, 'eval')
                    && nqp::iseq_s(
                            pir::join(';', $bt[$_]<sub>.get_namespace.get_name),
                            'nqp;HLL;Compiler'
                    );
                return False if nqp::iseq_s($bt[$_]<sub>, 'compile')
                    && nqp::iseq_s(
                            pir::join(';', $bt[$_]<sub>.get_namespace.get_name),
                            'nqp;HLL;Compiler'
                    );
            }
        }
        return False;
    }

    sub print_exception(|$) is hidden_from_backtrace {
        my Mu $ex := nqp::atpos(pir::perl6_current_args_rpa__P(), 0);
        try {
            if is_runtime($ex.backtrace) {
                my $e := EXCEPTION($ex);
                my Mu $err := pir::getstderr__P();
                $err.print: $e;
                $err.print: "\n";
                $err.print: Backtrace.new($e);
            } else {
                my Mu $err := pir::getstderr__P();
                $err.print: "===SORRY!===\n";
                $err.print: $ex;
                $err.print: "\n";
            }
        }
        # must not open a block here...
        $! ?? pir::perl6_rethrow_skipnextctx__0P(nqp::getattr($!, Exception, '$!ex')) !! pir::perl6_returncc__0P($ex);
    }

    sub print_control(|$) is hidden_from_backtrace {
        my Mu $ex := nqp::atpos(pir::perl6_current_args_rpa__P(), 0);
        my $type = nqp::p6box_i(nqp::atkey($ex, 'type'));
        if ($type == nqp::p6box_i(pir::const::CONTROL_OK)) {
            my Mu $err := pir::getstderr__P();
            my $msg = nqp::p6box_s(nqp::atkey($ex, 'message'));
            $err.print: $msg ?? "$msg\n" !! "Warning\n";
            my $resume := nqp::atkey($ex, 'resume');
            if ($resume) {
                $resume();
            }
        }
        if ($type == nqp::p6box_i(pir::const::CONTROL_RETURN)) {
            die("stray return control exception\n");
        }
        if ($type == nqp::p6box_i(pir::const::CONTROL_LOOP_LAST)) {
            die("last without loop construct\n");
        }
        if ($type == nqp::p6box_i(pir::const::CONTROL_LOOP_NEXT)) {
            die("next without loop construct\n");
        }
        if ($type == nqp::p6box_i(pir::const::CONTROL_LOOP_REDO)) {
            die("redo without loop construct\n");
        }
        if ($type == nqp::p6box_i(pir::const::CONTROL_CONTINUE)) {
            die("proceed without when clause\n");
        }
        if ($type == nqp::p6box_i(pir::const::CONTROL_BREAK)) {
            # XXX: should work like leave() ?
            die("succeed without when clause\n");
        }
        if ($type == nqp::p6box_i(pir::const::CONTROL_TAKE)) {
            die("stray take statement\n");
        }
        pir::perl6_returncc($ex);
        0;
    }

    my Mu $comp := pir::compreg__Ps('perl6');
    $comp.HOW.add_method($comp, 'handle-exception',
        method (|$) {
            my Mu $ex := nqp::atpos(pir::perl6_current_args_rpa__P(), 1);
            pir::perl6_invoke_catchhandler(nqp::getattr(&print_exception, Code, '$!do'), $ex);
            pir::exit(1);
            0;
        }
    );
    $comp.HOW.add_method($comp, 'handle-control',
        method (|$) {
            my Mu $ex := nqp::atpos(pir::perl6_current_args_rpa__P(), 1);
            pir::perl6_invoke_catchhandler(nqp::getattr(&print_control, Code, '$!do'), $ex);
            pir::rethrow__0P($ex);
        }
    );
}
