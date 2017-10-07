package CwUploader;

use strict;
use warnings;
use utf8;

use JSON;
use JSON::XS;
use URI;
use HTTP::Cookies;
use HTTP::Headers;
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;

sub new {
    my ($class, %args) = @_;

    my %cookie_arg => (hide_cookie2 => 1);
    if ($args{cookie_jar}) {
        $cookie_arg{file} = $args{cookie_jar};
    }
    my $cookie_jar = HTTP::Cookies->new(%cookie_arg);
    my $ua = LWP::UserAgent->new(
        cookie_jar => $cookie_jar,
    );

    bless {
        username => $args{username},
        password => $args{password},
        room_id  => $args{room_id},
        ua => $ua,
        cookie_jar => $cookie_jar,
        setting => {},
    }, $class;
}

sub login {
    my $self = shift;

    my $login_url = 'https://www.chatwork.com/login.php?args=';
    $self->{ua}->get($login_url);
    my $res = $self->{ua}->post($login_url, {
        email => $self->{username},
        password => $self->{password},
    });
    my $res2 = $self->{ua}->get($res->header('location'));
    my $page = $res2->content;
    my %setting = $page =~ m/var\s+?(.*?)\s+?=\s*?'(.*?)\s*?';/gx;
    $self->{ua}->cookie_jar->save;
    $self->{setting} = \%setting;
}

sub upload {
    my ($self, %args) = @_;

    my $room_id = $args{room_id} || $self->{room_id};
    my $payload = {
        room_id => "" . $room_id,
        list => [
        {
            key => 0,
            name => $args{name},
            size => $args{size},
            message => ($args{message} || ""),
        }
        ],
        noredirect => JSON::true,
        region => "tokyo",
        _t => $self->{setting}{ACCESS_TOKEN},
    };

    my $url  = sprintf "https://www.chatwork.com/gateway.php?cmd=get_s3_post_object&myid=%s&_v=%s&_av=5&ln=ja",
       $self->{setting}{MYID}, $self->{setting}{CLIENT_VER};

    $self->{ua}->default_header("X-Requested-With" => "XMLHttpRequest");
    my $res = $self->{ua}->post($url, {pdata => encode_json($payload)});

    my $json = decode_json $res->content;

    $self->{ua}->default_header("X-Requested-With" => "XMLHttpRequest");
    $self->{ua}->default_header("Origin" => "https://www.chatwork.com");

    my $info = $json->{result}{upload_info}[0];

    my $s3req = POST $self->{setting}{S3_PATH},
        Content_Type => 'form-data',
        Content      => [
            key                             => $info->{uri},
            AWSAccessKeyId                  => $info->{accesskey},
            acl                             => $info->{acl},
            policy                          => $info->{policy},
            signature                       => $info->{signature},
            "Content-Type"                  => "application/octet-stream",
            "Content-Disposition"           => $info->{disposition},
            "x-amz-server-side-encryption"  => "AES256",
            "x-amz-security-token"          => $info->{auth_token},
            file                            => [$args{filename}],
    ];

    $self->{ua}->request($s3req);

    my $redirect = URI->new_abs($info->{redirect}, $self->{setting}{CHATWORK_HOME})->as_string;
    $self->{ua}->get($redirect);
}

1;

