use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::SQLite;
use FindBin;

use File::Basename;
use Mojo::Asset::File;

BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

my $sql = Mojo::SQLite->new('sqlite:db/test.db');
my $db = $sql->db;
my $query;
my $results;

my $t = Test::Mojo->new('Test2');
$t->ua->max_redirects(10);

say "\n\nArticle test start\n\n";
say "Check page with articles\n";
$t->post_ok('/login' => form => {email => 'admin@mail.ru', password => '32167'})
  ->status_is(200)
  ->get_ok('/admin/articles')
  ->status_is(200)
  ->element_exists('div[id="article-list"]');

say "\nCheck validation url: empty field\n";
$t->post_ok('/admin/articles/new' => form => {title => '', body => '', url => ''})
  ->status_is(200)
  ->element_exists('span[id="empty"]');

say "\nCheck validation url: regular expression\n";
$t->post_ok('/admin/articles/new' => form => {title => '', body => '', url => '/article/'})
  ->status_is(200)
  ->element_exists('span[id="regular"]');

say "\nCheck creating new article\n";
$t->post_ok('/admin/articles/new' => form => {title => 'new', body => 'new',
url => '/articles/new', image => {
  filename => '',
  content => ''
}})
  ->status_is(200);

say "\nCheck validation url: unique URL\n";
$t->post_ok('/admin/articles/new' => form => {title => '', body => '',
url => '/articles/new'})
  ->status_is(200)
  ->element_exists('span[id="unique"]');

$query = 'SELECT id FROM articles WHERE url=?';
$results = $db->query($query, '/articles/new');
my $id = $results->hash->{id};

say "\nCheck new article in list\n";
$t->get_ok('/admin/articles')
  ->status_is(200)
  ->text_is('a[id="'.$id.'"]' => 'new');

say "\nCheck page of article\n";
$t->get_ok('/articles/new')
  ->status_is(200)
  ->text_is('h1[id="title"]' => 'new');

say "\nCheck edit article\n";
$t->get_ok('/admin/articles/edit/'.$id)
  ->status_is(200)
  ->element_exists('input[name="title"][value="new"]');

say "\nCheck edit not exist article\n";
$t->get_ok('/admin/articles/edit/0')
  ->status_is(200)
  ->element_exists('div[id="article-list"]');

say "\nCheck update article\n";
$t->post_ok('/admin/articles/edit' => form => {id => $id, title => 'new2',
body => 'new2', url => '/articles/new'})
  ->status_is(200)
  ->text_is('a[id="'.$id.'"]' => 'new2');

say "\nCheck delete article\n";
$t->get_ok('/admin/articles/delete/'.$id)
  ->status_is(200)
  ->element_exists_not('span[id="'.$id.'"]');

say "\n\nArticle test over\n\n";

done_testing();
