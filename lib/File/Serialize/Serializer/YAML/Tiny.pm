package File::Serialize::Serializer::YAML::Tiny;
#ABSTRACT: YAML::Tiny serializer for File::Serialize

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

=head1 DESCRIPTION

=over

=item B<extensions>

C<yaml>, C<yml>.

=item B<module used>

L<YAML::Tiny>

=item B<supported options>

none

=back
