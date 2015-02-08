use strict;
use warnings;

use Test::More tests => 1;                      # last test to print

use Path::Tiny;
use Path::Tiny::Serialize;

{  package Path::Tiny; Path::Tiny::Serialize->import; }

for my $ext ( qw/ yml json / ) {
    subtest $ext => sub {
        my $x = path("t/corpus/foo.$ext")->deserialize;

        is_deeply $x => { foo => 'bar' };

        my $time = scalar localtime;

        my $path =path("t/corpus/time.$ext");
        $path->serialize({time => $time});

        is $path->deserialize->{time} => $time;
    }
}
