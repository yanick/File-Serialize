package File::Serialize;
# ABSTRACT: 

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use strict;
use warnings;

use Class::Load qw/ load_class /;
use List::Util qw/ pairgrep first none any pairmap /;
use Path::Tiny;

use parent 'Exporter';

our @EXPORT = qw/ serialize_file deserialize_file /;

our %serializers = (
    yaml => {
        extensions => [ 'yml', 'yaml' ],  # first extension is the canonical one
        init => 'YAML',
        serialize   => sub { YAML::Dump(shift) },  # arguments: $data, $options
        deserialize => sub { YAML::Load(shift) },  # arguments: $data, $options
    },
    json => {
        extensions => [ 'json', 'js' ],
        init => 'JSON::XS',
        options => sub { 
            # arguments $options, $serialize
            my $options = shift; 
            my %groomed;
            $groomed{pretty} = $options->{pretty} if defined $options->{pretty};

            return \%groomed;
        },
        serialize => sub { JSON::XS->new->encode($_[0]) },
        deserialize => sub { JSON::XS->new->decode($_[0]) },
    },
);

sub serialize_file {
    my( $file, $content, $options, $format ) = @_;

    $file = path($file);

    my $serializer = _serializer($file, $options);

    $options = map { $_->($options) }
                  first { $_ }
                  map( { $serializer->{$_} } qw/ serialize_options options / ), sub { +{} };
    
    $file->spew($serializer->{serialize}->($content, $options));
}

sub deserialize_file {
    my( $file, $options ) = @_;

    $file = path($file);

    my $serializer = _serializer($file, $options);

    $options = map { $_->($options) }
                  first { $_ }
                  map( { $serializer->{$_} } qw/ deserialize_options options / ), sub { +{} };
    
    return $serializer->{deserialize}->($file->slurp, $options);
}

sub _serializer {
    my( $self, $options ) = @_;

    my $format = $options->{format} || do {
        my( $ext ) = $self->basename =~ /\.(.*?)$/;
        first { $_ } pairmap { $a } pairgrep { any { $_ eq $ext } @{ $b->{extensions} } } %serializers;
    } or die "no serializer found for file '$self'\n";

    my $serializer = $serializers{$format};
    load_class( $serializer->{init} );

    return $serializer;
}

1;
