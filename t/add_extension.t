use strict;
use warnings;

use Test::More tests => 1;

use Test::Requires;

use Path::Tiny;

use File::Serialize {
    format => 'yaml',
    add_extension => 1,
};

test_requires 'YAML';


serialize_file 't/corpus/add_ext' => { a => 'b' };

my $file = path('t/corpus/add_ext.yml');

ok $file->exists, 'the right file is created';
like $file->slurp => qr/a:\s+b/, 'has the right content';

is_deeply deserialize_file( 't/corpus/add_ext' ), { a => 'b' }, 
    "can deserialize too";








