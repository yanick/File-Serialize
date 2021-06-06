package File::Serialize::Serializer::Markdown;
#ABSTRACT: Markdown (with frontmatter) serializer for File::Serialize

use strict;
use warnings;

use File::Serialize qw/ deserialize_file serialize_file /;
use Moo;
with 'File::Serialize::Serializer';

sub required_modules { return qw//; }

sub extensions { qw/ md markdown / };

sub serialize {
    my( $self, $data, $options ) = @_;

    my $content = delete $data->{_content};

    my $yaml = '';

    return $content unless keys %$data;

    serialize_file \$yaml, $data, { format => 'yaml' };

    return join "---\n", $yaml, $content//'';
}


sub deserialize {
    my( $self, $data, $options ) = @_;

    # remote the potential leading `---`
    $data =~ s/^---\n//;


    return { _content => $data } if $data !~ /^---\n?$/m;

    my( $frontmatter, $content ) = split /^---\n?$/m, $data, 2;

    my $struct = deserialize_file( \$frontmatter, { format => 'yml' } );

    $struct->{_content} = $content if $content =~ /\S/;

    return $struct;
}

1;

__END__

=head1 DESCRIPTION

Converts Markdown files with YAML frontmatter. This is a file format that looks like

    ---
    slug: benchmark
    title: Benchmarking all the things
    tags:
        - test
        - benchmark
        - perl
    ---

    # Benchmarking all the things

    Blah blah blah...


The markdown content of the file is assigned the key C<_content>.

=over

=item B<extensions>

C<md>

=item B<precedence>

100


=item B<module used>

L<TOML>

=item B<supported options>

None

=back
