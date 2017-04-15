package SandboxXServer;
use strict;
use warnings;
use Carp;
use Try::Tiny;

=head1 DESCRIPTION

This module attempts to create a child process X server, primarily for testing
purposes.  Right now it only checks for Xephyr, but I'd like to expand it to
support others like Xnest or Xdmx or Xvfb.

This may eventually be officially published with this package, or made into
its own package.

=cut

my $host_programs;
sub host_programs {
    $host_programs ||= do {
        my %progs;
        if (`Xephyr -help 2>&1`) { # Can't figure out how to check version...
            $progs{Xephyr}= {
                class => 'SandboxXServer::Xephyr'
            },
        }
        \%progs;
    };
}

sub new {
    my ($class, %attrs)= @_;
    my $prog= host_programs->{Xephyr}
        || croak("No sandboxing Xserver program is available");
    $prog->{class}->new(%attrs);
}

sub DESTROY {
    shift->close;
}

sub client  { croak "Uninplemented" }
sub close   { croak "Uninplemented" }

package SandboxXServer::Xephyr;
@SandboxXServer::Xephyr::ISA= 'SandboxXServer';
use strict;
use warnings;
use Carp;
use Try::Tiny;


sub new {
    my ($class, %attrs)= @_;
    my $title= $attrs{title};
    # No good way to determine which display numbers are free, when other
    # test cases might be running in parallel, so just iterate 10 times and give up.
    my ($dpy, $pid);
    for my $disp_num (1..11) {
        # Can't find any way to start it and connect without a race condition.
        # Some other server could be occupting the display number, and then Xephyr
        # would fail even if we are able to connect, and if the system was lagged
        # there's no telling how long it would take for the failing Xephyr process
        # to exit.  Would like to use -verbosity to get stdout that says it is ready
        # for connections but I get no output at all.        my $child= fork();
        $pid= fork();
        defined $pid or die "fork: $!";
        unless ($pid) {
            exec("Xephyr", ":$disp_num", ($title? (-title => $title) : ()) );
            warn("exec(Xephyr): $!");
            exec($^X, '-e', 'die "exec failed"'); # attempt to end process abruptly
            exit(2); # This could run perl cleanup code that breaks things, but oh well...
        }
        sleep 1;

        $dpy= try { X11::Xlib->new(connect => ":$disp_num") }
            and last;

        kill TERM => $pid;
        waitpid($pid, 0) > 0 or die "waitpid: $!";
    }
    defined $dpy or croak("Can't start and connect to Xephyr");
    
    return bless { display => $dpy, pid => $pid }, $class;
}

sub client {
    shift->{display}
}

sub close {
    my $self= shift;
    my $dpy= delete $self->{display};
    $dpy->XCloseDisplay;
    my $pid= delete $self->{pid};
    kill TERM => $pid;
    waitpid($pid, 0) > 0 or die "waitpid: $!";
}

1;
