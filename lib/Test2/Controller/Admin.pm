package Test2::Controller::Admin;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::SQLite;
use Db::MyDB;
use Digest;

sub main {
  my $self = shift;

  $self->render();
}

sub users {
  my $self = shift;

  my $query = "select T1.id, T1.email, T2.name as role_name from users as T1 left join roles as T2 on T1.role_id = T2.id";
  my $results = $self->db->query($query);

  $self->render(list => $results);
}

sub articles {
  my $self = shift;

  my $query = "select T1.id, T1.title as title, T2.email as author,
  datetime(T1.date_create) as date_create, datetime(T1.date_update) as date_update,
  T1.url, T1.draft from articles as T1 left join users as T2 on T1.author = T2.id";
  my $results = $self->db->query($query);

  $self->render(list => $results);
}

sub menus {
  my $self = shift;

  my $query = 'select id, name from menus';
  my $results = $self->db->query($query);

  $self->render(list => $results);
}

sub comments {
  my $self = shift;

  my $query = 'SELECT T1.id, T1.body, datetime(T1.date) as date, T2.email as author,
  T3.title as article, T3.url as article_url FROM comments
  AS T1 LEFT JOIN users AS T2 ON T1.author_id=T2.id LEFT JOIN articles AS T3 on
  T1.article_id=T3.id';
  my $results = $self->db->query($query);

  $self->render(comment_list => $results);
}

1;
