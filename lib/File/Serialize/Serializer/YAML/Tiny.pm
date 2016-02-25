package File::Serialize::Serializer::YAML::Tiny;
our $AUTHORITY = 'cpan:YANICK';
$File::Serialize::Serializer::YAML::Tiny::VERSION = '1.0.0';
use strict;
use warnings;

use Moo;
with 'File::Serialize::Serializer';

sub extensions { qw/ yml yaml / };

sub serialize {
    my( $self, $data, $options ) = @_;
    YAML::Tiny->new($data)->write_string
}


sub deserialize {
    my( $self, $data, $options ) = @_;
    YAML::Tiny->new->read_string($data)->[0];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Serialize::Serializer::YAML::Tiny

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
