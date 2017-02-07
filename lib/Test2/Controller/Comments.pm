package Test2::Controller::Comments;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::SQLite;
use Db::MyDB;
use Digest;
use DateTime;
use Mojo::Upload;
use Data::Printer;
use File::Spec "catdir catfile";

sub add {
  my $self = shift;

  my $article_id = $self->param('id');

  return $self->render(template => 'main/error')
    if ! $self->itemExist('articles','id',$article_id);

  my $body = $self->param('body');

  my $query = 'SELECT id FROM users WHERE email=?';
  my $author_id = $self->db->query($query,$self->session('user'))->hash->{id};

  $query = 'INSERT INTO comments VALUES(NULL,?,?,?)';
  $self->db->query($query,$body,$author_id,$article_id);

  $query = 'SELECT url FROM articles WHERE id=?';
  my $article_url = $self->db->query($query,$article_id)->hash->{url};

  $self->redirect_to($article_url);
}

1;
