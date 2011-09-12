$Mo'VERSION = '0.22';
no warnings;

sub Mo'import {
    import warnings; $^H |= 0x602;
    my $p = caller."'";
    @_ = ( ISA, extends, has, sub {
        my ( $n, %a ) = @_;
        my $d = $a{default}||$a{builder};
        *{ $p . $n } = $d
          ? sub {
            $#_ ? $_[0]{$n} = $_[1]
              : exists $_[0]{$n} ? $_[0]{$n}
              : ( $_[0]{$n} = $_[0]->$d )
          }
          : sub { $#_ ? $_[0]{$n} = $_[1] : $_[0]{$n} }
      }, sub { @{ $p . ISA } = $_[0]; eval "no $_[0] ()" }, [Mo'_]);
      *{ $p.$_ } = pop for @_;
}

sub Mo'_'new {
    $c = shift;
    my $s = bless {@_}, $c;
    my @c;
    do { unshift @c, $c . "'BUILD" } while $c = ${ $c . "'ISA" }[0];
    defined &$_ && &$_($s) for @c;
    $s
}
