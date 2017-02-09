package Test2::Controller::AdminImages;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::SQLite;
use Db::MyDB;
use Digest;
use DateTime;
use Mojo::Upload;
use Data::Printer;
use File::Spec "catdir catfile";

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
