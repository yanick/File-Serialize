package File::Serialize::Serializer::XML::Simple;
#ABSTRACT: XML::Simple serializer for File::Serialize

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

__END__

=head1 DESCRIPTION

=over

=item B<extensions>

C<xml>.

=item B<module used>

L<XML::Simple>

=item B<supported options>

None

=back
