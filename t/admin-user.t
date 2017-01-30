use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::SQLite;
use FindBin;

BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

my $sql = Mojo::SQLite->new('sqlite:db/test.db');
my $db = $sql->db;
my $query;
my $results;

my $t = Test::Mojo->new('Test2');
$t->ua->max_redirects(1);

say "\n\nUser check start\n\n";
say "\nUser role\n";
$t->post_ok('/signup' => form => {email => 'example@mail.ru', password => '12345',
password2 => '12345'})
  ->status_is(200)
  ->get_ok('/admin')
  ->status_is(200)
  ->element_exists('h1[id="error"]');
$t->reset_session;

say "\nAdmin role\n";
$t->post_ok('/login' => form => {email => 'admin@mail.ru', password => '32167'})
  ->status_is(200)
  ->element_exists('a[href="/admin"]')
  ->get_ok('/admin')
  ->status_is(200)
  ->element_exists('div[id="admin-action"]');

$query = 'SELECT id FROM users WHERE email=?';
$results = $db->query($query, 'example@mail.ru');
my $id = $results->hash->{id};

say "\nUsers' list\n";
$t->get_ok('/admin/users')
  ->status_is(200)
  ->element_exists('div[id="user-list"]')
  ->text_is('span[id="'.$id.'"]' => 'example@mail.ru');

say "\nUser update\n";
$t->post_ok('/admin/users/edit' => form => {id => $id, email => 'example2@mail.ru',
password => '', role => 2})
  ->status_is(200)
  ->text_is('span[id="'.$id.'"]' => 'example2@mail.ru');

say "\nTry update not exist user\n";
$t->get_ok('/admin/users/edit/'.($id+1))
  ->status_is(200)
  ->element_exists_not('div[id="user-update"]');

say "\nUser delete\n";
$t->get_ok('/admin/users/remove/'.$id)
  ->status_is(200)
  ->element_exists_not('span[id="'.$id.'"]');
$t->reset_session;

say "\n\nUser check over\n\n";

done_testing();
