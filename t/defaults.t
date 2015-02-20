use strict;

use Test::More tests => 3;

use Test::Requires 'JSON::MaybeXS';

use Path::Tiny;

my $file;
sub Path::Tiny::spew { $file = $_[1]; }

{
    package Foo;

    use Test::More;

    use File::Serialize {
        pretty => 1,
    };

    serialize_file( "foo.json" => { a => 'b' } );

    like $file => qr/\n/, "pretty-printed";

    serialize_file "foo.json" => { a => 'b' }, { pretty => 0 };

    unlike $file => qr/\n/, "default overridden";
}

{
    package Bar;

    use Test::More;

    use File::Serialize; 

    serialize_file( "foo.json" => { a => 'b' } );

    unlike $file => qr/\n/, "not pretty-printed";
}

