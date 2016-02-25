package File::Serialize::Serializer::XML::Simple;
our $AUTHORITY = 'cpan:YANICK';
$File::Serialize::Serializer::XML::Simple::VERSION = '1.0.0';
use strict;
use warnings;

use Moo;
with 'File::Serialize::Serializer';

sub extensions { qw/ xml / };

sub serialize {
    my( $self, $data, $options ) = @_;
    XML::Simple->new->XMLout($data);
}


sub deserialize {
    my( $self, $data, $options ) = @_;
    XML::Simple->new->XMLin($data);
}

1;


use warnings;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Serialize::Serializer::XML::Simple

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
