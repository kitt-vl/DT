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
$t->ua->max_redirects(10);

say "\n\n Check menu start \n\n";
say "Check menus list\n";
$t->post_ok('/login' => form => {email =>'admin@mail.ru', password => '32167'})
  ->status_is(200)
  ->get_ok('/admin/menus')
  ->status_is(200)
  ->element_exists('div[id="menu-list"]');

say "\nCheck create menu\n";
$t->post_ok('/admin/menus/new' => form => {name => 'Test menu'})
  ->status_is(200)
  ->element_exists('span[id="Test menu"]');

$query = 'SELECT id FROM menus WHERE name=?';
$results = $db->query($query, 'Test menu');
my $menu_id = $results->hash->{id};

say "\nCheck menu view\n";
$t->get_ok('/admin/menus/edit/'.$menu_id)
  ->status_is(200)
  ->element_exists('div[id="menu-edit-'.$menu_id.'"]');

say "\nCheck change name\n";
$t->post_ok('/admin/menus/edit/'.$menu_id => form => {title => 'test'})
  ->status_is(200)
  ->element_exists('input[name="title"][value="test"]')
  ->element_exists('div[id="menu-item-list"]');

say "\nCheck create menu-item\n";
$t->post_ok('/admin/menus/edit/'.$menu_id.'/new' => form => {name => 'test-item',
url => '#test', role => 1})
  ->status_is(200)
  ->element_exists('span[id="test-item"]');

$query = 'SELECT id FROM menu_items WHERE name=?';
$results = $db->query($query, 'test-item');
my $item_id = $results->hash->{id};

say "\nCheck menu-item edit\n";
$t->post_ok('/admin/menus/edit/'.$menu_id.'/'.$item_id => form => {name => "test-item 2",
url => '#test', role => 1})
  ->status_is(200)
  ->element_exists('span[id="test-item 2"]');

say "\nCheck menu-item delete\n";
$t->get_ok('/admin/menus/remove/'.$menu_id.'/'.$item_id)
  ->status_is(200)
  ->element_exists_not('div[id="'.$item_id.'"]');

say "\nCheck menu-item edit that not exist\n";
$t->get_ok('/admin/menus/edit/'.$menu_id.'/'.$item_id)
  ->status_is(200)
  ->element_exists('div[id="menu-item-list"]');

say "\nCheck menu delete\n";
$t->get_ok('/admin/menus/remove/'.$menu_id)
  ->status_is(200)
  ->element_exists_not('span[id="test"]');

say "\nCheck menu view that not exist\n";
$t->get_ok('/admin/menus/edit/'.$menu_id)
  ->status_is(200)
  ->element_exists('div[id="menu-list"]');

done_testing();
