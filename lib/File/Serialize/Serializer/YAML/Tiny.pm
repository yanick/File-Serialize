package File::Serialize::Serializer::YAML::Tiny;

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


