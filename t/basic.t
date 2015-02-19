use strict;
use warnings;

use Test::More tests => 5; 
use Test::Exception;
use Test::Requires;

use Path::Tiny;
use File::Serialize;

for my $serializer ( keys %File::Serialize::serializers ) {
    subtest $serializer => sub {
        my $value =  $File::Serialize::serializers{$serializer};

        test_requires $value->{init};

        my $ext = $value->{extensions}[0];
        my $x = deserialize_file( "t/corpus/foo.$ext" );

        is_deeply $x => { foo => 'bar' };

        my $time = scalar localtime;

        my $path = "t/corpus/time.$ext";
        serialize_file( $path => {time => $time} );

        is deserialize_file($path)->{time} => $time;
    }
}

throws_ok {
    serialize_file 't/corpus/meh' => [ 1..5 ];
} qr/no serializer found/, 'no serializer found';

subtest "explicit format" => sub {
    test_requires 'YAML';

    serialize_file 't/corpus/mystery' => [1..5], { format => 'yaml' };

    like path('t/corpus/mystery')->slurp => qr'- 1', 'right format';
};
