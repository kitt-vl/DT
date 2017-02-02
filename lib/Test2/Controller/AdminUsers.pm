package Test2::Controller::AdminUsers;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::SQLite;
use Db::MyDB;
use Digest;

sub edit {
  my $self = shift;
  my $id = $self->param('id');

  return $self->redirect_to('/admin/users')
    if ! $self->itemExist('users','id',$id);

  my $query = "select T1.email, T2.name as role_name from users as T1 left join
  roles as T2 on T1.role_id = T2.id where T1.id = ?";
  my $results = $self->db->query($query, $id);
  my $row = $results->hash;

  $self->render(id => $id, email => $row->{email}, role => $row->{role_name});
}

sub remove {
  my $self = shift;
  my $id = $self->param('id');

  return $self->redirect_to('/admin/users')
    if ! $self->itemExist('users','id',$id);

  my $query = "delete from users where id = ?";
  $self->db->query($query, $id);

  $self->redirect_to('/admin/users');
}

sub update {
  my $self = shift;
  my $id = $self->param('id');
  my $email = $self->param('email');
  my $password = $self->param('password');
  my $role_id = $self->param('role');
  my $query;

  return $self->redirect_to('/admin/users')
    if ! $self->itemExist('users','id',$id);

  my $validation = $self->_validation;
  $validation->input({em => $email, pas => $password});
  $validation->required('em', 'trim');
  $validation->required('pas', 'trim');

  if($validation->is_valid('em')) {
    $query = "update users set email=? where id=?";
    $self->db->query($query, $email, $id);
  }

  if($validation->is_valid('pas')) {
    $query = "update users set password=? where id=?";
    $self->db->query($query, $self->hashBcrypt($password), $id);
  }

  $query = "update users set role_id=? where id=?";
  $self->db->query($query, $role_id, $id);

  $self->redirect_to('/admin/users');
}

1;
