package MyDB;
use base 'ObjectDB';
use DBI;

sub init_db {
  my $dbh = DBI->connect("dbi:SQLite:dbname=db/test.db", "", "");
  return $dbh;
}

package Role;
use base 'MyDB';

__PACKAGE__->meta(
  table => 'roles',
  columns => [qw/id name/],
  primary_key => 'id',
  auto_increment => 'id'
);

package MyUser;
use base 'MyDB';

__PACKAGE__->meta(
  table           => 'users',
  columns         => [qw/id email password role_id/],
  primary_key     => 'id',
  auto_increment  => 'id',
  relationships   => {
    roles => {
      type  => 'many to one',
      class => 'Role',
      map   => {role_id => 'id'}
    }
  }
);

package Article;
use base 'MyDB';

__PACKAGE__->meta(
  table           => 'articles',
  columns         => [qw/id title body author date_create date_update url/],
  primary_key     => 'id',
  auto_increment  => 'id',
  relationships   => {
    roles => {
      type => 'many to one',
      class => 'MyUser',
      map => {author => 'id'}
    }
  }
);

1;
