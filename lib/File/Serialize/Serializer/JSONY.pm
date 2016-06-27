package File::Serialize::Serializer::JSONY;
# abstract: JSONY serializer for File::Serialize

use strict;
use warnings;

use File::Serialize;

use Moo;
with 'File::Serialize::Serializer';

sub extensions { qw/ jsony / };

sub serialize {
    my( $self, $data, $options ) = @_;
    serialize_file \my $output, $data, { format => 'json' };
    return $output;
}


sub deserialize {
    my( $self, $data, $options ) = @_;
    JSONY->new->load($data);
}

1;

__END__

=head1 DESCRIPTION

Serializer for L<JSONY>.

Registered against the extension C<jsony>.

This serializer actually only deserializes. Its serialization
is taken care of by any available JSON serializer.

=cut

