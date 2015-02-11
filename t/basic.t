use strict;
use warnings;

use Test::More tests => 1;                      # last test to print

use File::Serialize qw/ serialize_file deserialize_file /;

{  package Path::Tiny; Path::Tiny::Serialize->import; }

for my $ext ( qw/ yml json / ) {
    subtest $ext => sub {
        my $x = deserialize_file "t/corpus/foo.$ext";

        is_deeply $x => { foo => 'bar' };

        my $time = scalar localtime;

        my $path = "t/corpus/time.$ext";
        serialize_file $path => {time => $time};

        is deserialize_file($path)->{time} => $time;
    }
}
