package Test2::Controller::AdminArticles;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::SQLite;
use Db::MyDB;
use Digest;
use DateTime;
use Mojo::Upload;
use Data::Printer;
use File::Spec "catdir catfile";

sub create {
  my $self = shift;

  if($self->req->method eq 'POST') {
    my $title = $self->param('title');
    my $body = $self->param('body');
    my $date_update = '';
    my $url = $self->param('url');
    my $upload = $self->param('image');
    my $email = $self->session('user');
    my $query = 'select id from users where email=?';
    my $author = $self->db->query($query, $email)->hash->{id};
    my $date = DateTime->now->datetime();

    say 'Upload: '.np $upload;

    my $validation = $self->_validation;
    $validation->input({url => $url});
    $validation->required('url', 'trim')->like(qr/^\/articles\/.+$/)->uniqueURL;

    return $self->render(msg => '')
      if $validation->has_error;

    my $filename = $upload->filename;
    if($filename) {
      my $id = $self->param('id');
      say 'id = '.$id;
      $query = 'UPDATE articles SET title=?, body=?, url=?, draft=0 WHERE id=?';
      $self->db->query($query, $title, $body, $url, $id);
    } else {
      $query = 'insert into articles values(NULL, ?, ?, ?, ?, ?, ?, 0)';
      my $id = $self->db->query($query, $title, $body, $author, $date, '', $url)->last_insert_id;
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
    if ! $self->itemExist('articles','id',$id);

  my $query = 'delete from articles where id=?';
  $self->db->query($query, $id);

  $query = 'SELECT id, name FROM files WHERE owner_id=? AND owner_type=?';
  my $images = $self->db->query($query, $id, 'articles');
  while(my $next = $images->hash) {
    my $path = File::Spec->catfile($self->app->home, 'public','img', $next->{name});
    unlink $path;
    $query = 'DELETE FROM files WHERE id=?';
    $self->db->query($query, $next->{id});
  }

  $self->redirect_to('/admin/articles');
}

sub edit {
  my $self = shift;
  my $id = $self->param('id');

  return $self->redirect_to('/admin/articles')
    if ! $self->itemExist('articles','id',$id);

  my $query = 'select title, body, url from articles where id=?';
  my $results = $self->db->query($query, $id);
  my $row = $results->hash;

  $query = 'SELECT id, source FROM files WHERE owner_id=? AND owner_type=?';
  $results = $self->db->query($query,$id,'articles');
  my $check = $results;
  $check = $check->hash;
  if(exists $check->{id}) {
    $check = 1;
  } else {
    $check = 0;
  }

  $self->render(id => $id, title => $row->{title}, body => $row->{body},
  url => $row->{url}, file_list => $results, check => $check);
}

sub update {
  my $self = shift;

  my $id = $self->param('id');
  my $title = $self->param('title');
  my $body = $self->param('body');
  my $date_update = DateTime->now->datetime();
  my $url = $self->param('url');

  return $self->redirect_to('/admin/articles')
    if ! $self->itemExist('articles','id',$id);

  my $validation = $self->_validation;
  $validation->input({url => $url});
  $validation->required('url', 'trim')->like(qr/^\/articles\/.+$/);

  my $query = 'SELECT url FROM articles WHERE id=?';
  my $old_url = $self->db->query($query, $id)->hash->{url};

  if($old_url ne $url) {
    $validation->uniqueURL;
  }

  $query = 'SELECT id, source FROM files WHERE owner_id=? AND owner_type=?';
  my $results = $self->db->query($query,$id,'articles');
  my $check = $results;
  $check = $check->hash;
  if(exists $check->{id}) {
    $check = 1;
  } else {
    $check = 0;
  }

  return $self->render(template => 'admin_articles/edit', msg => '', id => $id,
  title => $title, body => $body, url => $url, file_list => $results, check =>
  $check)
    if $validation->has_error;

  $query = "update articles set title=?, body=?, date_update=?, url=?, draft=0
  where id=?";
  $self->db->query($query, $title, $body, $date_update, $url, $id);

  $self->redirect_to('/admin/articles');
}

1;
