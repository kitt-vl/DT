package Test2::Controller::User;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::SQLite;
use Db::MyDB;
use Digest;

sub login {
  my $self = shift;

  if($self->req->method eq 'POST') {
    my $email = $self->param('email');
    my $password = $self->param('password');

    my $validation = $self->_validation;
    $validation->input({em => $email, pas => $password});
    $validation->required('em', 'trim')->size(5, 30)->emailCheck->emailExist;
    $validation->required('pas', 'trim')->size(5, 30)->passwordCheck;
    $validation->passwordRight($email)
      if $validation->is_valid('em');

    return $self->render()
      if $validation->has_error;

    my $query = 'SELECT id, email, role_id FROM users WHERE email=?';
    my $user_hash = $self->db->query($query, $email)->hash;

    $self->session(
      user => $email,
      id => $user_hash->{id},
      role_id => $user_hash->{role_id}
    );
    return $self->redirect_to('/');
  }

  $self->render();
}

sub logout {
  my $self = shift;

  $self->session(expires => 1);
  $self->redirect_to('/');
}

sub signup {
  my $self = shift;

  if($self->req->method eq 'POST') {
    my $email = $self->param('email');
    my $password = $self->param('password');
    my $password2 = $self->param('password2');

    my $validation = $self->_validation;
    $validation->input({em => $email, pas => $password, pas2 => $password2});
    $validation->required('em', 'trim')->size(5, 30)->emailCheck->uniqueEmail;
    $validation->required('pas', 'trim')->equal_to('pas2')->size(5, 30)->passwordCheck;

    return $self->render()
      if $validation->has_error;

    my $user = MyUser->new(
      email     => $email,
      password  => $self->hashBcrypt($password),
      role_id => 2
    )->create;

    $self->session(user => $email);
    $self->redirect_to('/');
  }

  $self->render();
}

1;
