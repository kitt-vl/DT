package Test2::Controller::Main;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::SQLite;
use Db::MyDB;
use Digest;
use Data::Printer;
use DateTime;
use utf8;

sub main {
  my $self = shift;

  $self->render();
}

sub article {
  my $self = shift;
  my $url = '/articles/' . $self->param('url');
  my $source = '';

  my $query = "select T1.id, T1.title, T2.email as author, datetime(T1.date_create)
  as date, T1.body, datetime(T1.date_update) as date_update from articles as T1
  left join users as T2 on T1.author = T2.id where T1.url=?";
  my $results = $self->db->query($query, $url);
  my $row = $results->hash;

  $query = 'SELECT source FROM files WHERE owner_id=? AND owner_type=?';
  $results = $self->db->query($query, $row->{id}, 'articles');
  my $source_row = $results->hash;
  $source = $source_row->{source}
    if exists $source_row->{source};

  $self->render(title => $row->{title}, author => $row->{author}, date => $row->{date},
  body => $row->{body}, update => $row->{date_update}, source => $source);
}

sub error {
  my $self = shift;

  $self->render();
}

1;
