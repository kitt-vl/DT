use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use FindBin;

BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

my $t = Test::Mojo->new('Test2');
$t->ua->max_redirects(10);

say "\n\nLogin form check start:\n\n";

say "Check empty fields\n";
$t->post_ok('/login' => form => {email => '', password => ''})
  ->status_is(200)
  ->element_exists('p[id="emailError"] span[id="empty"]')
  ->element_exists('p[id="passwordError"] span[id="empty"]');

say "\nCheck length < 5\n";
$t->post_ok('/login' => form => {email => '123', password => '123'})
  ->status_is(200)
  ->element_exists('p[id="emailError"] span[id="size"]')
  ->element_exists('p[id="passwordError"] span[id="size"]');

say "\nCheck length > 30\n";
$t->post_ok('/login' => form => {email => 'dgrhdnghcbdjrythgjfnckfjghthdjh',
password => 'dgrhdnghcbdjrythgjfnckfjghthdjh'})
  ->status_is(200)
  ->element_exists('p[id="emailError"] span[id="size"]')
  ->element_exists('p[id="passwordError"] span[id="size"]');

say "\nCheck regular expressions\n";
$t->post_ok('/login' => form => {email => 'email', password => 'not*/password'})
  ->status_is(200)
  ->element_exists('p[id="emailError"] span[id="regular"]')
  ->element_exists('p[id="passwordError"] span[id="regular"]');

say "\nCheck email, that not exist\n";
$t->post_ok('/login' => form => {email => 'notexist@mail.ru', password => 'notexist'})
  ->status_is(200)
  ->element_exists('p[id="emailError"] span[id="registr"]')
  ->element_exists_not('p[id="passwordError"]');

say "\nCheck wrong password\n";
$t->post_ok('/login' => form => {email => 'admin@mail.ru', password => 'notexist'})
  ->status_is(200)
  ->element_exists_not('p[id="emailError"]')
  ->element_exists('p[id="passwordError"] span[id="registr"]');

say "\nCheck right user and session\n";
$t->post_ok('/login' => form => {email => 'admin@mail.ru', password => '32167'})
  ->status_is(200)
  ->text_is('a[href="#cabinet"]' => 'admin@mail.ru');

say "\nCheck logout\n";
$t->get_ok('/logout')
  ->status_is(200)
  ->element_exists('a[href="/login"]');

say "\n\nLogin form check over\n\n";

done_testing();
