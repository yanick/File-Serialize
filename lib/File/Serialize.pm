package File::Serialize;
# ABSTRACT: DWIM file serialization/deserialization

use strict;
use warnings;

use Class::Load qw/ load_class /;
use List::Util 1.41 qw/ pairgrep first none any pairmap /;
use Path::Tiny;

use parent 'Exporter::Tiny';

our @EXPORT = qw/ serialize_file deserialize_file /;

our %serializers = (
    YAML => {
        extensions => [ 'yml', 'yaml' ],  # first extension is the canonical one
        init => 'YAML::Tiny',
        serialize   => sub { YAML::Tiny->new(shift)->write_string },  # arguments: $data, $options
        deserialize => sub { YAML::Tiny->new->read_string(shift)->[0] },  # arguments: $data, $options
    },
    JSON => {
        extensions => [ 'json', 'js' ],
        init => 'JSON::MaybeXS',
        options => sub { 
            # arguments $options, $serialize
            my $options = shift; 
            my %groomed;
            for my $k( qw/ pretty canonical / ) {
                $groomed{$k} = $options->{$k} if defined $options->{$k};
            }

            return \%groomed;
        },
        serialize => sub { JSON::MaybeXS->new(%{$_[1]})->encode( $_[0] ); },
        deserialize => sub { JSON::MaybeXS->new(%{$_[1]})->decode($_[0]) },
    },
    TOML => {
        extensions => [ 'toml' ],
        init => 'TOML',
        serialize   => sub { TOML::to_toml( shift ) },
        deserialize => sub { TOML::from_toml( shift ) },
    },
);

sub _generate_serialize_file {
    my( undef, undef, undef, $global )= @_;

    return sub {
        my( $file, $content, $options ) = @_;

        $options = { %$global, %{ $options||{} } } if $global;

        $file = path($file);

        my $serializer = _serializer($file, $options);

        $file = path( join '.', $file, $serializer->{extensions}[0] )
            if $options->{add_extension};

        $options = $_->($options, 1) for
                    first { $_ }
                    map( { $serializer->{$_} } qw/ options / ), sub { +{} };
        
        $file->spew($serializer->{serialize}->($content, $options));
    }
}

sub _generate_deserialize_file {
    my( undef, undef, undef, $global ) = @_;

    return sub {
        my( $file, $options ) = @_;

        $file = path($file);

        $options = { %$global, %{ $options||{} } } if $global;

        my $serializer = _serializer($file, $options);

        $file = path( join '.', $file, $serializer->{extensions}[0] )
            if $options->{add_extension};

        ($options) = map { $_->($options) }
                    first { $_ }
                    map( { $serializer->{$_} } qw/ options / ), sub { +{} };
        
        return $serializer->{deserialize}->($file->slurp, $options);
    }
}

sub _serializer {
    my( $self, $options ) = @_;

    no warnings qw/ uninitialized /;

    my $format = $options->{format} || do {
        no warnings;
        my( $ext ) = $self->basename =~ /\.(.*?)$/;
        first { $_ } pairmap { $a } pairgrep { any { $_ eq $ext } @{ $b->{extensions} } } %serializers;
    };

    $format = lc $format;

    my( $key ) = grep { lc($_) eq $format } keys %serializers;
    my $serializer = $serializers{$key} or die "no serializer found for file '$self'\n";

    load_class( $serializer->{init} );

    return $serializer;
}

1;
