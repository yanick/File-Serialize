package File::Serialize::Serializer::TOML;
#ABSTRACT: TOML serializer for File::Serialize

use strict;
use warnings;

use Moo;
with 'File::Serialize::Serializer';

sub extensions { qw/ toml / };

sub serialize {
    my( $self, $data, $options ) = @_;
    TOML::to_toml( $data );
}


sub deserialize {
    my( $self, $data, $options ) = @_;
    TOML::from_toml( $data );
}

1;

__END__

=head1 DESCRIPTION

=over

=item B<extensions>

C<toml>

=item B<precedence>

100


=item B<module used>

L<TOML>

=item B<supported options>

None

=back
