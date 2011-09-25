#!/usr/bin/perl

use strict;
use warnings;
use PPI;

my $text = do {
    local undef $/;
    <>;
};

binmode STDOUT;
print golf_with_ppi( $text );

sub tok { "PPI::Token::$_[0]" }

sub finder_subs {
    return (
        comments => sub { $_[1]->isa( 'PPI::Token::Comment' ) },

        whitespace => sub {
            my ( $top, $current ) = @_;
            return 0 if !$current->isa( 'PPI::Token::Whitespace' );
            my $prev = $current->previous_token;
            my $next = $current->next_token;
            return 1
              if $prev->isa( 'PPI::Token::ArrayIndex' )
                  and $next->isa( 'PPI::Token::Whitespace' )
                  and $next->next_token->isa( 'PPI::Token::Operator' ); # !!! change this to collapse double whitespaces

            return 1
              if $prev->isa( 'PPI::Token::Symbol' )
                  and $next->isa( 'PPI::Token::Whitespace' )
                  and $next->next_token->isa( 'PPI::Token::Operator' ); # !!! change this to collapse double whitespaces

            return 1 if $prev->isa( tok 'Symbol' )     and $next->isa( tok 'Operator' );         # $VERSION =
            return 1 if $prev->isa( tok 'Word' )       and $next->isa( tok 'Symbol' );           # my $P
            return 1 if $prev->isa( tok 'Word' )       and $next->isa( tok 'Structure' );        # sub {
            return 1 if $prev->isa( tok 'Word' )       and $next->isa( tok 'Quote::Double' );    # eval "
            return 1 if $prev->isa( tok 'Symbol' )     and $next->isa( tok 'Structure' );        # %a )
            return 1 if $prev->isa( tok 'ArrayIndex' ) and $next->isa( tok 'Operator' );         # $#_ ?
            return 1 if $prev->isa( tok 'Word' )       and $next->isa( tok 'Cast' );             # exists &$_
            return 0;
        },

        trailing_whitespace => sub {
            my ( $top, $current ) = @_;
            return 0 if !$current->isa( 'PPI::Token::Whitespace' );
            my $prev = $current->previous_token;

            return 1 if $prev->isa( tok 'Structure' );                                           # ;[\n\s]
            return 1 if $prev->isa( tok 'Operator' );                                            # = 0.24
            return 1 if $prev->isa( tok 'Quote::Double' );                                       # " .

            return 0;
        },

        del_last_semicolon_in_block => sub {
            my ( $top, $current ) = @_;
            return 0 if !$current->isa( 'PPI::Structure::Block' );

            my $last = $current->last_token;

            return 0 if !$last->isa( tok 'Structure' );
            return 0 if $last->content ne '}';

            my $maybe_semi = $last->previous_token;

            return 0 if !$maybe_semi->isa( tok 'Structure' );
            return 0 if $maybe_semi->content ne ';';

            $maybe_semi->delete;

            return 1;
        },

        del_superfluous_concat => sub {
            my ( $top, $current ) = @_;
            return 0 if !$current->isa( tok 'Operator' );

            my $prev = $current->previous_token;
            my $next = $current->next_token;

            return 0 if $current->content ne '.';
            return 0 if !$prev->isa( tok 'Quote::Double' );
            return 0 if !$next->isa( tok 'Quote::Double' );

            $current->delete;
            $prev->set_content( $prev->{separator} . $prev->string . $next->string . $prev->{separator} );
            $next->delete;

            return 1;
        },

        separate_version => sub {
            my ( $top, $current ) = @_;
            return 0 if !$current->isa( 'PPI::Statement' );

            my $first = $current->first_token;
            return 0 if $first->content ne '$VERSION';

            $current->$_( PPI::Token::Whitespace->new( "\n" ) ) for qw( insert_before insert_after );

            return 1;
        },
    );
}

sub golf_with_ppi {
    my ( $text ) = @_;

    my $tree = PPI::Document->new( \$text );

    my %finder_subs = finder_subs();

    # whitespace needs to be double for now so i can compare things easier, needs to go later
    my @order = qw( comments whitespace whitespace trailing_whitespace trailing_whitespace );

    for my $name ( @order ) {
        my $elements = $tree->find( $finder_subs{$name} );
        die $@ if !$elements;
        $_->delete for @{$elements};
    }

    $tree->find( $finder_subs{$_} ) for qw( del_superfluous_concat del_last_semicolon_in_block separate_version );

    return $tree->serialize . "\n";
}
