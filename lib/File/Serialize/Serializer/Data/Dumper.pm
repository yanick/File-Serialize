package File::Serialize::Serializer::Data::Dumper;
#ABSTRACT: Data::Dumper serializer for File::Serialize

use strict;
use warnings;

use Moo;
with 'File::Serialize::Serializer';

use Module::Runtime 'use_module';

sub extensions { qw/ pl perl / };

sub serialize {
    my( $self, $data, $options ) = @_;
    Data::Dumper::Dumper($data);
}


sub deserialize {
    my( $self, $data, $options ) = @_;
    no strict;
    no warnings;
    return eval $data;
}

1;

__END__

=head1 DESCRIPTION

=over

=item B<extensions>

C<pl>, C<perl>.

=item B<precedence>

100

=item B<module used>

L<Data::Dumper>

=item B<supported options>

none

=back
