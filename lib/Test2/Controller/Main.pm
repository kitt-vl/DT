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

  my $query = 'SELECT url FROM menu_items WHERE main_page=1 AND menu_id=1';
  my $url = $self->db->query($query)->hash->{url};

  return $self->render()
    if($url eq '/');

  $self->redirect_to($url);
}

sub article {
  my $self = shift;
  my $url = '/articles/' . $self->param('url');
  my $source = '';

  return $self->render(template => 'main/error')
    if ! $self->itemExist('articles','url',$url);

  my $query = "select T1.id, T1.title, T2.email as author, datetime(T1.date_create)
  as date, T1.body, datetime(T1.date_update) as date_update, T1.draft from articles
  as T1 left join users as T2 on T1.author = T2.id where T1.url=?";
  my $results = $self->db->query($query, $url);
  my $row = $results->hash;

  return $self->render(template => 'main/error')
    if $row->{draft};

  $self->render(title => $row->{title}, author => $row->{author}, date => $row->{date},
  body => $row->{body}, update => $row->{date_update});
}

sub error {
  my $self = shift;

  $self->render();
}

1;
