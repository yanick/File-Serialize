package File::Serialize::Serializer::JSON::MaybeXS;
#ABSTRACT: JSON::MaybeXS serializer for File::Serialize

use strict;
use warnings;

use Moo;
with 'File::Serialize::Serializer';

sub extensions { qw/ json js / };

sub serialize {
    my( $self, $data, $options ) = @_;
    JSON::MaybeXS->new(%$options)->encode( $data);
}

sub deserialize {
    my( $self, $data, $options ) = @_;
    JSON::MaybeXS->new(%$options)->decode( $data);
}

sub groom_options {
   my( $self, $options ) = @_;

    my %groomed;
    for my $k( qw/ pretty canonical allow_nonref / ) {
        $groomed{$k} = $options->{$k} if defined $options->{$k};
    }

    return \%groomed;
}

1;

__END__

=head1 DESCRIPTION

=over

=item B<extensions>

C<json>, C<js>.

=item B<precedence>

100


=item B<module used>

L<JSON::MaybeXS>

=item B<supported options>

pretty (default: true), canonical (default: true), allow_nonref (default: true)

=back
