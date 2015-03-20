package File::Serialize;
# ABSTRACT: DWIM file serialization/deserialization

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
    XML => {
        extensions => [ 'xml' ],
        init => 'XML::Simple',
        serialize => sub { XML::Simple->new->XMLout(shift) },
        deserialize => sub { XML::Simple->new->XMLin(shift) },
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
            elsif ( ref $step eq 'SCALAR' ) {
                $$step = $data;
            }
            else {
                die "wrong chain argument";
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
