package Mo::class_xsaccessor;
$VERSION = 0.24;
package Mo;$MoPKG = __PACKAGE__."::";

require Class::XSAccessor;

*{$MoPKG.'class_xsaccessor::e'} = sub {
    my $caller_pkg = shift;
    $caller_pkg =~ s/::$//;
    my %exports = @_;
    my $old_export = $exports{has};
    $exports{has} = sub {
        my ( $name, %args ) = @_;
        $args{default} || $args{builder}
          and return $old_export->(@_);
        Class::XSAccessor->import(
          class => $caller_pkg,
          accessors => { $name => $name }
        );
    };
    %exports;
};
