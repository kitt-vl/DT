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

  $self->render(id => $id, title => $row->{title}, body => $row->{body}, url => $row->{url}, file_list => $results);
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
  $validation->required('url', 'trim')->like(qr/^\/articles\/.+$/)->uniqueURL;

  return $self->render(template => 'admin_articles/edit', msg => '')
    if $validation->has_error;

  my $query = "update articles set title=?, body=?, date_update=?, url=?, draft=0 where id=?";
  $self->db->query($query, $title, $body, $date_update, $url, $id);

  $self->redirect_to('/admin/articles');
}

sub upload {
  #/admin/articles/upload
  my $self = shift;

  return $self->render(msg => 'Файл слишком большой')
    if $self->req->is_limit_exceeded;

  my $error = "";
  my @result;
  my @id;
  my $query;

  my $id = $self->param('id');
  if(!$id) {
    my $title = $self->param('title');
    my $body = $self->param('body');
    my $email = $self->session('user');
    $query = 'select id from users where email=?';
    my $author = $self->db->query($query, $email)->hash->{id};
    my $date = DateTime->now->datetime();

    $query = 'INSERT INTO articles VALUES (NULL,?,?,?,?,?,?,1)';
    $id = $self->db->query($query,$title,$body,$author,$date,'','')->last_insert_id;
  }
  #if(-e $path)
  for my $upload ( @{$self->req->uploads('image')} ) {
    my $filename = $upload->filename;
    my $file_path = File::Spec->catfile($self->app->home, 'public','img', $filename);
    my $i = 1;
    while (-f $file_path) {
      my @file = split(/\./, $filename);
      $file[0] .= $i;
      $filename = join('.', @file);
      $file_path = File::Spec->catfile($self->app->home, 'public','img', $filename);
      $i++;
    }
    eval { $upload->move_to($file_path) };

    if ($@) {
      $error .= "Не удалось загрузить файл " . $upload->filename . " : " . $@ ."\n"
    }else {
      my $url = $self->url_for('/img/' . $filename)->to_abs;
      push(@result, $url);

      $query = 'INSERT INTO files VALUES (NULL,?,?,?,?)';
      my $file_id = $self->db->query($query,$filename,$id,'articles',$url)->last_insert_id;

      push(@id, $file_id);
    }
  }

  say "result : " .np(@result);
  if($error) {
    $self->render(json => {
      message => $error,
      error => $error
    });
  }else {
    $self->render( json => {
      message => 'Файлы успешно загружены на сервер',
      error => 'undefined',
      result => \@result,
      file_id => \@id,
      id => $id
    });
  }

}

sub deleteImage {
  my $self = shift;

  my $article_id = $self->param('article_id');
  my $image_id = $self->param('image_id');

  return $self->redirect_to('/admin/articles/edit/'.$article_id)
    if ! $self->itemExist('files','id',$image_id);

  my $query = 'SELECT name FROM files WHERE id=?';
  my $name = $self->db->query($query, $image_id)->hash->{name};
  my $path = File::Spec->catfile($self->app->home, 'public','img', $name);
  unlink $path;

  $query = 'DELETE FROM files WHERE id=?';
  $self->db->query($query, $image_id);

  $self->redirect_to('/admin/articles/edit/'.$article_id);
}

1;
