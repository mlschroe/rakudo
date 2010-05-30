class Perl6::BacktracePrinter;

# Drives the overall backtrace production process.
method backtrace_for($exception) {
    my @backtrace := $exception.backtrace();
    if self.is_runtime(@backtrace) {
        # Runtime error. Start with the error message.
        my $trace := pir::getattribute__pps($exception, 'message') ~ "\n";
        
        # If top frame is 'die', drop it from the top.
        if ~@backtrace[0]<sub> eq '&die' {
            @backtrace.shift;
        }

        # Go through frames to find annotations to print.
        my $cur_annotations;
        for @backtrace {
            # If we're seeking an annotation set, take the current one.
            unless $cur_annotations {
                $cur_annotations := $_<annotations>;
            }
            
            # If we hit the end of the user's code, we're done; emit last
            # annotations and say we're in main program body.
            if ~$_<sub> eq '!UNIT_START' {
                $trace := $trace ~ self.backtrace_line(0, $cur_annotations);
                last;
            }

            # If we're not in an intermediate block, then we've hit some sub
            # should emit annotations here. We go on not having a p6type but
            # also checking for some built-in ops can be handy and give more
            # informative line numbers.
            if !pir::isnull(pir::getprop__psp('$!p6type', $_<sub>))
                    || pir::substr(~$_<sub>, 0, 6) eq '&infix' {
                $trace := $trace ~ self.backtrace_line($_<sub>, $cur_annotations);
                $cur_annotations := 0;
            }
        }
        return $trace;
    } else {
        # For parse time exceptions, we just want the message, with no
        # back trace beyond this.
        return "===SORRY!===\n" ~
            pir::getattribute__pps($exception, 'message') ~ "\n";
    }
}

# Checks if we have a !UNIT_START anywhere in the backtrace, in which case
# we must be at runtime.
method is_runtime(@backtrace) {
    for @backtrace {
        if ~$_<sub> eq '!UNIT_START' {
            return 1;
        }
    }
    return 0;
}

# Renders one line in the backtrace, using the given sub name and
# annotations set.
method backtrace_line($current_sub, $location) {
    "in " ~
        ($current_sub    ?? "'" ~ ~$current_sub ~ "'" !! 'main program body') ~
    " at " ~
        ($location<line> ?? 'line ' ~ $location<line> !! '<unknown line>'    ) ~
        ($location<file> ?? ':' ~ $location<file>     !! ''                  ) ~
    "\n"
}