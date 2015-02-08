package Path::Tiny::Serialize;
# ABSTRACT: 

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use strict;
use warnings;

use Class::Load qw/ load_class /;

use parent 'Exporter';

our @EXPORT = qw/ serialize deserialize /;

our %serializers = (
    yml => [
        'YAML',
        sub { YAML::Dump(shift) },
        sub { YAML::Load(shift) },
    ],
    json => [
        'JSON::XS',
        sub { JSON::XS->new( %{ $_[1] || {} })->encode($_[0]) },
        sub { JSON::XS->new( %{ $_[1] || {} })->decode($_[0]) },
    ],
);

sub serialize {
    my( $self, $content, $options, $format ) = @_;

    my $serializer = _serializer($self, $format);
    
    $self->spew($serializer->[1]->($content, $options));
    return $self;
}

sub deserialize {
    my( $self, $options, $format ) = @_;

    my $serializer = _serializer($self, $format);
    
    return $serializer->[2]->($self->slurp, $options);
}

sub _serializer {
    my( $self, $format ) = @_;

    $format ||= ( $self->basename =~ /\.(.*?)$/ )[0];
    my $serializer = $serializers{$format};
    load_class( $serializer->[0] );

    return $serializer;
}

# Monkey patching is bad, mmm-kay. 
# No pushing to CPAN till this is changed

{  package Path::Tiny; Path::Tiny::Serialize->import; }

1;
