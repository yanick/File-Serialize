package File::Serialize;
BEGIN {
  $File::Serialize::AUTHORITY = 'cpan:YANICK';
}
# ABSTRACT: DWIM file serialization/deserialization
$File::Serialize::VERSION = '0.4.1';
use 5.16.0;

use feature 'current_sub';

use strict;
use warnings;

use Class::Load qw/ load_class /;
use List::Util 1.41 qw/ pairgrep first none any pairmap /;
use Path::Tiny;

use parent 'Exporter::Tiny';

our @EXPORT = qw/ serialize_file deserialize_file transerialize_file /;

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
        # default to utf8 => 1
        $options->{utf8} //= 1;

        $file = path($file);

        my $method = $options->{utf8} ? 'spew_utf8' : 'spew';

        my $serializer = _serializer($file, $options);

        $file = path( join '.', $file, $serializer->{extensions}[0] )
            if $options->{add_extension};

        $options = $_->($options, 1) for
                    first { $_ }
                    map( { $serializer->{$_} } qw/ options / ), sub { +{} };
        

        $file->$method($serializer->{serialize}->($content, $options));
    }
}

sub _generate_deserialize_file {
    my( undef, undef, undef, $global ) = @_;

    return sub {
        my( $file, $options ) = @_;

        $file = path($file);

        $options = { %$global, %{ $options||{} } } if $global;
        $options->{utf8} //= 1;

        my $method = 'slurp' . ( '_utf8' ) x !! $options->{utf8};

        my $serializer = _serializer($file, $options);

        $file = path( join '.', $file, $serializer->{extensions}[0] )
            if $options->{add_extension};

        ($options) = map { $_->($options) }
                    first { $_ }
                    map( { $serializer->{$_} } qw/ options / ), sub { +{} };

        return $serializer->{deserialize}->($file->$method, $options);
    }
}

sub _generate_transerialize_file {

    my $serialize_file = _generate_serialize_file(@_);
    my $deserialize_file = _generate_deserialize_file(@_);


    return sub {
        my( $in, @chain ) = @_;
        my $data = ref($in) ? $in : $deserialize_file->($in);

        while( my $step = shift @chain) {
            if ( ref $step eq 'CODE' ) {
                local $_ = $data;
                $data = $step->($data);
            }
            elsif ( ref $step eq 'ARRAY' ) {
                die "subranch step can only be the last step of the chain"
                    if @chain;
                for my $branch( @$step ) {
                    __SUB__->($data,@$branch);
                }
            }
            elsif ( not ref $step or ref($step) =~ /Path::Tiny/ ) {
                die "filename '$step' not at the end of the chain"
                    unless @chain <= 1;

                $serialize_file->(  $step, $data, shift @chain );
            }
            elsif ( ref $step eq 'HASH' ) {
                while( my ($f,$o) = each %$step ) {
                    $serialize_file->($f,$data,$o);
                }
            }
        }

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

version 0.4.1

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

I<File::Serialize> imports the three functions 
C<serialize_file>, C<deserialize_file> and C<transerialize_file> into the current namespace.
A default set of options can be set for both by passing a hashref as
an argument to the 'use' statement.

    use File::Serialize { pretty => 1 };

=head1 SUPPORTED SERIALIZERS

=head2 YAML

=over

=item extensions

yaml, yml

=item module used

L<YAML::Tiny>

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

pretty, canonical

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

=item add_extension => $boolean

If true, the canonical extension of the serializing format will be 
appended to the file. Requires the parameter C<format> to be given as well.

    # will create 'foo.yml', 'foo.json' and 'foo.toml'
    serialize_file 'foo', $data, { format => $_, add_extension => 1 } 
        for qw/ yaml json toml /;

=item pretty => $boolean

The serialization will be formatted for human consumption.

=item canonical => $boolean

Serializes the data using its canonical representation.

=item utf8 => $boolean

If set to a C<true> value, file will be read/written out using L<Path::Tiny>'s C<slurp_utf8> and C<spew_utf8>
method ( which sets a C<binmode> of C<:encoding(UTF-8)>). Otherwise,
L<Path::Tiny>'s C<slurp> and C<spew> methods are used.

Defaults to being C<true> because, after all, it is 2015.

=back

=head1 FUNCTIONS

=head2 serialize_file $path, $data, $options

    my $data = { foo => 'bar' };

    serialize_file '/path/to/file.json' => $data;

=head2 deserialize_file $path, $options

    my $data = deserialize_file '/path/to/file.json';

=head2 transerialize_file $input, @transformation_chain

C<transerialize_file> is a convenient wrapper that allows you to
deserialize a file, apply any number of transformations to its 
content and re-serialize the result.

C<$input> can be a filename, a L<Path::Tiny> object or the raw data 
structure to be worked on.

    transerialize_file 'foo.json' => 'foo.yaml';
    
    # equivalent to
    serialize_file 'foo.yaml' => deserialize_file 'foo.json'

Each element of the C<@transformation_chain> can be

=over

=item $coderef

A transformation step. The current data is available both via C<$_> and
as the first argument to the sub,
and the transformed data is going to be whatever the sub returns.

    my $data = {
        tshirt => { price => 18 },
        hoodie => { price => 50 },
    };

    transerialize_file $data => sub {
        my %inventory = %$_;

        +{ %inventory{ grep { $inventory{$_}{price} <= 20 } keys %inventory } }

    } => 'inexpensive.json';

    # chaining transforms
    transerialize_file $data 
        => sub { 
            my %inventory = %$_; 
            +{ map { $_ => $inventory{$_}{price} } keys %inventory } }
        => sub {
            my %inventory = %$_;
            +{ %inventory{ grep { $inventory{$_} <= 20 } keys %inventory } }
        } => 'inexpensive.json';

    # same as above, but with Perl 5.20 signatures and List::Util pair*
    # helpers
    transerialize_file $data 
        => sub($inventory) { +{ pairmap  { $a => $b->{price} } %$inventory } }
        => sub($inventory) { +{ pairgrep { $b <= 20 }          %$inventory } } 
        => 'inexpensive.json';

=item \%destinations

A hashref of destination file with their options. The current state of the data will
be serialized to those destination. If no options need to be passed, the 
value can be C<undef>.

    transerialize_file $data => { 
        'beginning.json' => { pretty => 1 },
        'beginning.yml'  => undef
    } => sub { ... } => {
        'end.json' => { pretty => 1 },
        'end.yml'  => undef
    };

=item [ \@subchain1, \@subchain2, ... ] 

Run the subchains given in C<@branches> on the current data. Must be the last
step of the chain.

    my @data = 1..10;

    transerialize_file \@data 
        => { 'all.json' => undef }
        => [
           [ sub { [ grep { $_ % 2 } @$_ ] }     => 'odd.json'  ],
           [ sub { [ grep { not $_ % 2 } @$_ ] } => 'even.json' ],
        ];

=item ( $filename, $options )

Has to be the final step(s) of the chain. Just like the arguments
of C<serialize_file>. C<$filename> can be a string or a L<Path::Tiny> object.
C<$options> is optional.

=back

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
