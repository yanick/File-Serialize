package File::Serialize;
# ABSTRACT: DWIM file serialization/deserialization

use 5.16.0;

use feature 'current_sub';

use strict;
use warnings;

use Class::Load qw/ load_class /;
use List::AllUtils qw/ uniq /;
use List::Util 1.41 qw/ pairgrep first none any pairmap /;
use Path::Tiny;

use Module::Pluggable 
   require => 1,
   sub_name => '_all_serializers',
   search_path => __PACKAGE__ . '::Serializer'
;

use parent 'Exporter::Tiny';

our @EXPORT = qw/ serialize_file deserialize_file transerialize_file /;

sub _generate_serialize_file {
    my( undef, undef, undef, $global )= @_;

    return sub {
        my( $file, $content, $options ) = @_;

        $options = { format => $options } if $options and not ref $options;

        $options = { %$global, %{ $options||{} } } if $global;
        # default to utf8 => 1
        $options->{utf8} //= 1;
        $options->{allow_nonref} //= 1;

        $file = path($file) unless $file eq '-';

        my $serializer = _serializer($file, $options);

        $file = path( join '.', $file, $serializer->extension )
            if $options->{add_extension} and $file ne '-';

        my $method = $options->{utf8} ? 'spew_utf8' : 'spew';

        my $serialized = $serializer->serialize($content,$options);

        return print $serialized if $file eq '-';

        $file->$method($serialized);
    }
}

sub _generate_deserialize_file {
    my( undef, undef, undef, $global ) = @_;

    return sub {
        my( $file, $options ) = @_;

        $file = path($file) unless $file eq '-';

        $options = { %$global, %{ $options||{} } } if $global;
        $options->{utf8} //= 1;
        $options->{allow_nonref} //= 1;

        my $method = 'slurp' . ( '_utf8' ) x !! $options->{utf8};

        my $serializer = _serializer($file, $options);

        $file = path( join '.', $file, $serializer->extension )
            if $options->{add_extension} and $file ne '-';

        return $serializer->deserialize(
            $file eq '-' ? do { local $/ = <STDIN> } : $file->$method, 
            $options
        );
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

sub _all_operative_formats {
    my $self = shift;
    return uniq map { $_->extension } $self->_all_operative_formats;
}

sub _all_operative_serializers {
    grep { $_->is_operative } sort __PACKAGE__->_all_serializers;
}

sub _serializer {
    my( $self, $options ) = @_;

    no warnings qw/ uninitialized /;

    my @serializers = __PACKAGE__->_all_operative_serializers;

    my $format = $options->{format} || ( $self->basename =~ /\.(\w+)$/ )[0];

    return( first { $_->does_extension($format) } @serializers
            or die "no serializer found for $format"
    );
}

1;
