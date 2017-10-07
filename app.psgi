# vim: ft=perl
use strict;
use warnings;
use utf8;

use File::Temp qw/tempfile/;
use JSON;
use Plack::Builder;
use Plack::Request;

use lib "lib/";
use CwUploader;

my $handle = CwUploader->new(
    username => $ENV{CW_USERNAME},
    password => $ENV{CW_PASSWORD},
    cookie_jar => $ENV{COOKIE_JAR},
    room_id  => $ENV{CW_ROOMID},
);

$handle->login;

my $app = sub {
    my $req = Plack::Request->new(shift);
    my $json = decode_json($req->content);

    my ($room_id) = $req->path_info =~ m|(\d+)$|;

    my (undef, $filename) = tempfile();

    $handle->{ua}->get(
        $json->{attachments}[0]{image_url},
        ":content_file" => $filename
    );

    my %info = (
        name => "mackerel.png",
        size => -s($filename),
        filename => $filename,
        message => $json->{attachments}[0]{text},
    );

    $info{room_id} = $room_id if $room_id;

    $handle->upload(%info);
    [200, [], ["ok"]];
};

builder {
    $app;
};

__END__

POST ..../(room_id)

convert slack type payload to post chatwork

