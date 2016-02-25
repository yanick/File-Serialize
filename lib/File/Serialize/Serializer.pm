package File::Serialize::Serializer;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Role for defining File::Serialize serializers
$File::Serialize::Serializer::VERSION = '1.0.0';

use strict;
use warnings;

use List::Util qw/ reduce/;
use List::MoreUtils qw/ any /;
use Module::Info;
use Module::Runtime qw/ use_module /;

use Moo::Role;

requires 'extensions';  # first extension is the canonical one

requires 'serialize', 'deserialize';

sub required_modules {
    my $package = shift;
    $package =~ s/^File::Serialize::Serializer:://r;
}

sub extension { ($_[0]->extensions)[0] }

sub does_extension {
   my( $self, $ext ) = @_;
   return unless $ext;
   return any { $_ eq $ext } $self->extensions;
}

sub is_operative {
    reduce { $a and Module::Info->new_from_module($b)->file  } 1, $_[0]->required_modules;
}

sub groom_serialize_options {
    my $self = shift;
    $self->groom_options(@_);
}

sub groom_deserialize_options {
    my $self = shift;
    $self->groom_options(@_);
}

sub groom_options {
    my $self = shift;
    @_;
}

before serialize => \&init;
before deserialize => \&init;

around serialize => sub {
    my( $orig, $self, $data, $options ) = @_;
    $orig->( $self, $data, $self->groom_serialize_options($options) );
};

around deserialize => sub {
    my( $orig, $self, $data, $options ) = @_;
    $orig->( $self, $data, $self->groom_deserialize_options($options) );
};

sub init {
    my $self = shift;
    use_module($_) for $self->required_modules;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Serialize::Serializer - Role for defining File::Serialize serializers

=head1 VERSION

version 1.0.0

=head1 SYNOPSIS

    package File::Serialize::Serializer::MySerializer;

    use Module::Runtime qw/ use_module /;

    use Moo;

    with 'File::Serialize::Serializer';

    sub extensions { 'mys' }

    sub init { use_module('SomeThing') }

    sub serialize { ...}
    sub deserialize { ...}

    1;

=head1 DESCRIPTION

This role is used to define serializers for L<File::Serialize>.

As all the serializer plugins are typically loaded to figure out which one
should be used to serialize/deserialize a specific file, it's important that
the modules on which the serializer depends are not just C<use>d, but are rather
marked for import via the C<required_modules> and C<init> functions.

A serializer should implement the following class methods:

=over

=item extensions

Required. Must return a list of all extensions that this serializer can deal with. 

The first
extension of the list will be considered the canonical extension.

=item required_modules

Returns the list of modules that this serializer needs to operate.

If not provided, the required module will be extracted from the package name.
I.e., the serializer L<File::Serialize::Serializer::YAML::Tiny> will assume
that it requires L<YAML::Tiny>.

=item serialize( $data, $options )

Required. Returns the serialized C<$data>. 

=item deserialize

Required. Returns the deserialized C<$data>. 

=item groom_options( $options )

Takes in the generic serializer options and groom them for 
this specific one.

=item groom_serialize_options( $options )

Groom the options for this specific serializer. If not
provided, C<groom_options> is used.

=item groom_deserialize_options( $options )

Groom the options for this specific serializer. If not
provided, C<groom_options> is used.

=back

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
