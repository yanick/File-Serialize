package File::Serialize::Serializer::YAML::XS;
our $AUTHORITY = 'cpan:YANICK';
#ABSTRACT: YAML:XS serializer for File::Serialize
$File::Serialize::Serializer::YAML::XS::VERSION = '1.3.0';
use strict;
use warnings;

use Moo;

with 'File::Serialize::Serializer';

sub extensions { qw/ yml yaml / };

sub precedence { 110 }

sub serialize {
    my( $self, $data, $options ) = @_;
    YAML::XS::Dump($data);
}


sub deserialize {
    my( $self, $data, $options ) = @_;
    YAML::XS::Load($data);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Serialize::Serializer::YAML::XS - YAML:XS serializer for File::Serialize

=head1 VERSION

version 1.3.0

=head1 DESCRIPTION

=over

=item B<extensions>

C<yaml>, C<yml>.

=item B<precedence>

110

=item B<module used>

L<YAML::XS>

=item B<supported options>

none

=back

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
