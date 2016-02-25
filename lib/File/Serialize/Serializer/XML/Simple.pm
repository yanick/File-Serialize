package File::Serialize::Serializer::XML::Simple;

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


use warnings;




