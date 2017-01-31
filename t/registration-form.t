use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::SQLite;
use FindBin;

BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

my $sql = Mojo::SQLite->new('sqlite:db/test.db');
my $db = $sql->db;
my $query;

my $t = Test::Mojo->new('Test2');
$t->ua->max_redirects(10);

say "Registration form check start:\n\n";

say "Check empty fields\n";
$t->post_ok('/signup' => form => {email => '', password => ''})
  ->status_is(200)
  ->element_exists('p[id="emailError"] span[id="empty"]')
  ->element_exists('p[id="passwordError"] span[id="empty"]');

say "\nCheck length < 5\n";
$t->post_ok('/signup' => form => {email => '123', password => '123', password2 => '123'})
  ->status_is(200)
  ->element_exists('p[id="emailError"] span[id="size"]')
  ->element_exists('p[id="passwordError"] span[id="size"]');

say "\nCheck length > 30\n";
$t->post_ok('/signup' => form => {email => 'dgrhdnghcbdjrythgjfnckfjghthdjh',
password => 'dgrhdnghcbdjrythgjfnckfjghthdjh',
password2 => 'dgrhdnghcbdjrythgjfnckfjghthdjh'})
  ->status_is(200)
  ->element_exists('p[id="emailError"] span[id="size"]')
  ->element_exists('p[id="passwordError"] span[id="size"]');

say "\nCheck equal of password and password 2\n";
$t->post_ok('/signup' => form => {email => '123', password => '123', password2 => '0'})
  ->status_is(200)
  ->element_exists('p[id="passwordError"] span[id="repeat"]');

say "\nCheck regular expressions\n";
$t->post_ok('/signup' => form => {email => 'notmail', password => 'not*/password',
password2 => 'not*/password'})
  ->status_is(200)
  ->element_exists('p[id="emailError"] span[id="regular"]')
  ->element_exists('p[id="passwordError"] span[id="regular"]');

say "\nCheck right fields\n";
$t->post_ok('/signup' => form => {email => 'example@mail.ru', password => '12345',
password2 => '12345'})
  ->status_is(200)
  ->text_is('a[href="#cabinet"]' => 'example@mail.ru');
$t->reset_session;

say "\nCheck uniqie user\n";
$t->post_ok('/signup' => form => {email => 'example@mail.ru', password => '12345',
password2 => '12345'})
  ->status_is(200)
  ->element_exists('p[id="emailError"] span[id="registr"]')
  ->element_exists_not('p[id="passwordError"]');

$query = 'DELETE FROM users WHERE email=?';
$db->query($query, 'example@mail.ru');

say "\n\nRegistration field check over\n\n";

done_testing();
