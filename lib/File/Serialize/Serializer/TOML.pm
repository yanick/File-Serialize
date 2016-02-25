package File::Serialize::Serializer::TOML;

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


use warnings;



