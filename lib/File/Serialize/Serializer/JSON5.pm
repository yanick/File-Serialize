package File::Serialize::Serializer::JSON5;
#ABSTRACT: JSON5 serializer for File::Serialize

use strict;
use warnings;

use Module::Runtime qw/ use_module /;

use Moo;
extends 'File::Serialize::Serializer::JSON::MaybeXS';

sub extensions { qw/ json5 / };

sub required_modules {
    qw/ JSON5 JSON::MaybeXS /
}

sub deserialize {
    my( $self, $data, $options ) = @_;
    use_module('JSON5');
    return JSON5::decode_json5($data,$options);
}

1;

__END__

=head1 DESCRIPTION

=over

=item B<extensions>

C<json5>.

=item B<precedence>

100


=item B<module used>

L<JSON5>, L<JSON::MaybeXS>

=item B<supported options>

pretty (default: true), canonical (default: true), allow_nonref (default: true)

=back
