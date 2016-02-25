package File::Serialize::Serializer::JSON::MaybeXS;

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
