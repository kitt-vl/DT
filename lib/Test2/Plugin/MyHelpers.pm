package Test2::Plugin::MyHelpers;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ($self, $app) = @_;

  $app->helper(hashBcrypt => sub {
    my ($c, @args) = @_;
    my $bcrypt = Digest->new('Bcrypt', cost => 12, salt => 'abcdefgh*stuff!!');
    $bcrypt->add($args[0]);
    my $hashPassword  = $bcrypt->hexdigest;
    return $hashPassword;
  });

  $app->helper(db => sub {
    my ($c, @args) = @_;

    my $sql = Mojo::SQLite->new('sqlite:db/test.db');
    my $db = $sql->db;

    return $db;
  });

  $app->helper(_validation => sub {
    my ($c, @args) = @_;

    my $validation = $c->validation;
    my $validator = $validation->validator;

    $validator->add_check(emailCheck => sub {
      my ($validation, $name, $value) = @_;

      return ! ($value =~ qr/^[\w-]+@\w+\.\w+$/);
    });

    $validator->add_check(passwordCheck => sub {
      my ($validation, $name, $value) = @_;

      return ! ($value =~ qr/^\w+$/);
    });

    $validator->add_check(emailExist => sub {
      my ($validation, $name, $value) = @_;
      my $users = MyUser->new;
      my @resultQuery = $users->table->find(where => ['email' => $value]);

      return ! scalar @resultQuery;
    });

    $validator->add_check(passwordRight => sub {
      my ($validation, $name, $value, $email) = @_;

      my $users = MyUser->new;
      my @resultQuery = $users->table->find(where => ['email' => $email]);
      my $row = shift @resultQuery;

      return ! ($row->column('password') eq $c->hashBcrypt($value));
    });

    $validator->add_check(uniqueEmail => sub {
      my ($validation, $name, $value, $email) = @_;

      my $users = MyUser->new;
      my @resultQuery = $users->table->find(where => ['email' => $value]);

      return scalar @resultQuery;
    });

    $validator->add_check(userAdmin => sub {
      my ($validation, $name, $value, $email) = @_;

      my $query = "select role_id from users where email=?";
      my $results = $c->db->query($query, $value);
      my $next = $results->hash;
      return ! ($next->{role_id} == 1);
    });

    $validator->add_check(uniqueURL => sub {
      my ($validation, $name, $value, $email) = @_;

      my $query = 'select id from articles where url=?';
      my $results = $c->db->query($query, $value);
      my $row = $results->hash;

      return $row->{id};
    });

    return $validation;
  });

  $app->helper(role => sub {
    my ($c, @args) = @_;
    my $user = $c->session('user');

    return 0
      if(!$user);

    my $query = "select role_id from users where email=?";
    my $results = $c->db->query($query, $user);
    my $role = $results->hash->{role_id};

    return $role;
  });

  $app->helper(itemExist => sub {
    my ($c, $table, $column, $value, @args) = @_;

    my $query = 'SELECT * FROM '.$table.' WHERE '.$column.'=?';
    my $results = $c->db->query($query, $value);
    my $hash = $results->hash;

    return 1
      if exists $hash->{id};
    return 0;
  });
}

1;
