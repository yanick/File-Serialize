package File::Serialize;
BEGIN {
  $File::Serialize::AUTHORITY = 'cpan:YANICK';
}
# ABSTRACT: DWIM file serialization/deserialization
$File::Serialize::VERSION = '0.0.1';

use strict;
use warnings;

use Class::Load qw/ load_class /;
use List::Util qw/ pairgrep first none any pairmap /;
use Path::Tiny;

use parent 'Exporter::Tiny';

our @EXPORT = qw/ serialize_file deserialize_file /;

our %serializers = (
    YAML => {
        extensions => [ 'yml', 'yaml' ],  # first extension is the canonical one
        init => 'YAML',
        serialize   => sub { YAML::Dump(shift) },  # arguments: $data, $options
        deserialize => sub { YAML::Load(shift) },  # arguments: $data, $options
    },
    JSON => {
        extensions => [ 'json', 'js' ],
        init => 'JSON::MaybeXS',
        options => sub { 
            # arguments $options, $serialize
            my $options = shift; 
            my %groomed;
            $groomed{pretty} = $options->{pretty} if defined $options->{pretty};

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

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Serialize - DWIM file serialization/deserialization

=head1 VERSION

version 0.0.1

=head1 SYNOPSIS

    use File::Serialize { pretty => 1 };

    my $data = { foo => 'bar' };

    serialize_file '/path/to/file.json' => $data;

    ...;

    $data_copy = deserialize_file '/path/to/file.json';

=head1 DESCRIPTION

I<File::Serialize> provides a common, simple interface to
file serialization -- you provide the file path, the data to serialized, and 
the module takes care of the rest. Even the serialization format, unless 
specified
explicitly as part of the options, is detected from the file extension.

=head1 IMPORT

I<File::Serialize> imports the two functions 
C<serialize_file> and C<deserialize_file> into the current namespace.
A default set of options can be set for both by passing a hashref as
an argument to the 'use' statement.

    use File::Serialize { pretty => 1 };

=head1 SUPPORTED SERIALIZERS

=head2 YAML

=over

=item extensions

yaml, yml

=item module used

L<YAML>

=item supported options

None

=back

=head2 JSON

=over

=item extensions

json, js

=item module used

L<JSON::MaybeXS>

=item supported options

pretty

=back

=head2 TOML

=over

=item extensions

toml 

=item module used

L<TOML>

=item supported options

None

=back

=head1 OPTIONS

I<File::Serialize> recognizes a set of options that, if applicable,
will be passed to the serializer.

=over

=item format => $serializer

Explicitly provides the serializer to use.

    my $data = deserialize_file $path, { format => 'json' };

=item pretty => $boolean

The serialization will be formatted for human consumption.

=back

=head1 FUNCTIONS

=head2 serialize_file $path, $data, $options

    my $data = { foo => 'bar' };

    serialize_file '/path/to/file.json' => $data;

=head2 deserialize_file $path, $options

    my $data = deserialize_file '/path/to/file.json';

=head1 ADDING A SERIALIZER

    $File::Serialize::serializers{'MySerializer'} = {
        extensions => [ 'myser' ],
        init => 'My::Serializer',
        serialize   => sub { my($data,$options) = @_; ...; },
        deserialize => sub { my($data,$options) = @_; ...; },
        options => sub { my( $raw_options, $serialize ) = @_; ...; },
    };

Serializers can be added via the C<$File::Serialize::serializers> hash. 
The key is the name of the serializer, and the value is an hashref of its
configuration parameters, which can be:

=over

=item extensions

Arrayref of the file extensions associated with this serializer.
The first extension is considered to be the canonical extension 
for this serialization format.

=item init 

Optional. A module to source when this serializer is used.

=item serialize

The serialization function to use. Will receive the data structure and the groomed
options as arguments, is expected to return the serialized data.

=item deserialize

The deserialization function to use. Will receive the serialized data and the groomed
options as arguments, is expected to return the deserialized data structure.

=item options 

Function that takes the options as passed to C<serialize_file>/C<deserialize_file> 
and convert them to something palatable to the current serializer. Gets the raw options
and a C<is_serialize> boolean (will be C<1> for a serializer call, C<undef> for the deserializer).

=back

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
