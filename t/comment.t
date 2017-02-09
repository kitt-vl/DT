use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::SQLite;
use FindBin;

use File::Basename;
use Mojo::Asset::File;

BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

my $db = Mojo::SQLite->new('sqlite:db/test.db')->db;
my $query;
my $results;

my $t = Test::Mojo->new('Test2');
$t->ua->max_redirects(10);

say "\n\nComments test start\n\n";
say "Login as admin\n";
$t->post_ok('/login' => form => {email=>'admin@mail.ru',password=>'32167'})
  ->status_is(200);

say "\nCreating article for testing comments\n";
$t->post_ok('/admin/articles/new' => form => {title => 'new', body => 'new',
url => '/articles/new', image => {
  filename => '',
  content => ''
}})
  ->status_is(200);

$query = 'SELECT id FROM articles WHERE url=?';
my $id = $db->query($query,'/articles/new')->hash->{id};

say "\nTesting create new comment\n";
$t->post_ok('/articles/'.$id.'/add' => form => {body => 'new comment'})
  ->status_is(200)
  ->text_is('li.comment div.comment-content' => 'new comment')
  ->text_is('li.comment div.author b' => 'admin@mail.ru');

$query = 'SELECT id FROM comments WHERE article_id=?';
my $comment_id = $db->query($query,$id)->hash->{id};

say "\nTesting delete comment from page with article\n";
$t->get_ok('/articles/'.$id.'/delete/'.$comment_id)
  ->status_is(200)
  ->element_exists_not('li.comment');

say "\nCreating another comments for testing\n";
$t->post_ok('/articles/'.$id.'/add' => form => {body => 'new comment'})
  ->status_is(200);

$comment_id = $db->query($query,$id)->hash->{id};

say "\nCheck page with list of comments\n";
$t->get_ok('/admin/comments')
  ->status_is(200)
  ->text_is('div#comment-'.$comment_id.' p#comment-body' => 'new comment');

say "\nTesting edit comment\n";
$t->post_ok('/admin/comments/edit/'.$comment_id => form => {body => 'edit comment'})
  ->status_is(200)
  ->text_is('div#comment-'.$comment_id.' p#comment-body' => 'edit comment');

say "\nTesting delete comment\n";
$t->get_ok('/admin/comments/delete/'.$comment_id)
  ->status_is(200)
  ->element_exists_not('div#comment-'.$comment_id);

say "\nDelete article\n";
$t->get_ok('/admin/articles/delete/'.$id)
  ->status_is(200);

say "\n\nComment testing over\n\n";

done_testing();
