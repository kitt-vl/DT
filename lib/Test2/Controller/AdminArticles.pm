package Test2::Controller::AdminArticles;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::SQLite;
use Db::MyDB;
use Digest;
use DateTime;
use Mojo::Upload;

sub create {
  my $self = shift;

  if($self->req->method eq 'POST') {
    my $title = $self->param('title');
    my $body = $self->param('body');
    my $email = $self->session('user');
    my $date_update = '';
    my $url = $self->param('url');

    return $self->render(msg => 'Файл слишком большой')
      if $self->req->is_limit_exceeded;
    my $upload = $self->param('image');

    my $date_temp = DateTime->now;
    my $date = $date_temp->datetime();

    my $query = 'select id from users where email=?';
    my $results = $self->db->query($query, $email);
    my $row = $results->hash;
    my $author = $row->{id};

    my $validation = $self->_validation;
    $validation->input({url => $url});
    $validation->required('url', 'trim')->like(qr/^\/articles\/.+$/)->uniqueURL;

    return $self->render(msg => '')
      if $validation->has_error;

    $query = 'insert into articles values(NULL, ?, ?, ?, ?, ?, ?)';
    my $id = $self->db->query($query, $title, $body, $author, $date, $date_update, $url)->last_insert_id;

    my $filename = $upload->filename;
    if($filename) {
      $upload->move_to('public/img/'.$filename);

      $query = 'INSERT INTO files VALUES(NULL,?,?,?,?)';
      $self->db->query($query, $filename, $id, 'articles', '/img/'.$filename);
    }

    return $self->redirect_to('/admin/articles');
  }

  $self->render(msg => '');
}

sub deleteAll {
  my $self = shift;

  my $query = 'delete from articles';
  $self->db->query($query);

  $self->redirect_to('/admin/articles');
}

sub delete {
  my $self = shift;
  my $id = $self->param('id');

  return $self->redirect_to('/admin/articles')
    if ! $self->itemExist('articles',$id);

  my $query = 'delete from articles where id=?';
  $self->db->query($query, $id);

  $query = 'SELECT id, name FROM files WHERE owner_id=? AND owner_type=?';
  my $results = $self->db->query($query, $id, 'articles');
  my $img_row = $results->hash;
  if(exists $img_row->{name}) {
    my $name = $img_row->{name};
    unlink "c:\\Users\\Darina\\work\\test2\\public\\img\\$name";
    $query = 'DELETE FROM files WHERE id=?';
    $self->db->query($query, $img_row->{id});
  }

  $self->redirect_to('/admin/articles');
}

sub edit {
  my $self = shift;
  my $id = $self->param('id');

  return $self->redirect_to('/admin/articles')
    if ! $self->itemExist('articles',$id);

  my $query = 'select title, body from articles where id=?';
  my $results = $self->db->query($query, $id);
  my $row = $results->hash;

  $self->render(id => $id, title => $row->{title}, body => $row->{body});
}

sub update {
  my $self = shift;

  my $id = $self->param('id');
  my $title = $self->param('title');
  my $body = $self->param('body');
  my $date_temp = DateTime->now;
  my $date_update = $date_temp->datetime();

  return $self->render(msg => 'Файл слишком большой')
    if $self->req->is_limit_exceeded;
  my $upload = $self->param('image');

  return $self->redirect_to('/admin/articles')
    if ! $self->itemExist('articles',$id);

  my $query = "update articles set title=?, body=?, date_update=? where id=?";
  $self->db->query($query, $title, $body, $date_update, $id);

  my $filename = $upload->filename;
  if($filename) {
    $query = 'SELECT id, name FROM files WHERE owner_id=? AND owner_type=?';
    my $results = $self->db->query($query, $id, 'articles');
    my $img_row = $results->hash;
    if(exists $img_row->{name}) {
      my $name = $img_row->{name};
      unlink "c:\\Users\\Darina\\work\\test2\\public\\img\\$name";
      $query = 'DELETE FROM files WHERE id=?';
      $self->db->query($query, $img_row->{id});
    }

    $upload->move_to('public/img/'.$filename);
    $query = 'INSERT INTO files VALUES(NULL,?,?,?,?)';
    $self->db->query($query, $filename, $id, 'articles', '/img/'.$filename);
  }

  $self->redirect_to('/admin/articles');
}

1;
