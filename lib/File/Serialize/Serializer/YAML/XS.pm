package File::Serialize::Serializer::YAML::XS;
#ABSTRACT: YAML:XS serializer for File::Serialize

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

If you have problems with utf8, pass the option C<<utf => 0>>
to C<serialize_file>/C<deserialize_file>. Or if you use C<transerialize>,
pass C<utf8=0> as the first argument.

=back
