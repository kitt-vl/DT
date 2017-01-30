package Test2;
use Mojo::Base 'Mojolicious';
use Mojo::SQLite;
use Mojo::SQLite::Migrations;

# This method will run once at server start
sub startup {
  my $self = shift;

  $self->plugin('Test2::Plugin::MyHelpers');
  $self->plugin('Test2::Plugin::MyTags');
  $self->plugin('TagHelpers');

  # База данных
  my $sql = Mojo::SQLite->new('sqlite:db/test.db');
  my $migrations = Mojo::SQLite::Migrations->new(sqlite => $sql);
  $migrations->from_file('db/init.sql')->migrate;

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer');

  # Router
  my $r = $self->routes;

  $r->add_condition(
			isAdmin => sub {
				my ($route, $c, $captures, $pattern) = @_;

				return $c->role == 1;
			}
	);

  # Normal route to controller
  $r->get('/')->to('Main#main');
  $r->get('/articles/:url')->to('Main#article');

  $r->any('/login')->to('User#login');
  $r->get('/logout')->to('User#logout');
  $r->any('/signup')->to('User#signup');

  $r->get('/admin')->over(isAdmin => 1)->to('Admin#main');
  $r->get('/admin/users')->over(isAdmin => 1)->to('Admin#users');
  $r->get('/admin/articles')->over(isAdmin => 1)->to('Admin#articles');
  $r->get('/admin/menus')->over(isAdmin => 1)->to('Admin#menus');

  $r->get('/admin/users/edit/:id')->over(isAdmin => 1)->to('AdminUsers#edit');
  $r->get('/admin/users/remove/:id')->over(isAdmin => 1)->to('AdminUsers#remove');
  $r->post('/admin/users/edit')->over(isAdmin => 1)->to('AdminUsers#update');

  $r->any('/admin/articles/new')->over(isAdmin => 1)->to('AdminArticles#create');
  $r->get('/admin/articles/delete')->over(isAdmin => 1)->to('AdminArticles#deleteAll');
  $r->get('/admin/articles/delete/:id')->over(isAdmin => 1)->to('AdminArticles#delete');
  $r->get('/admin/articles/edit/:id')->over(isAdmin => 1)->to('AdminArticles#edit');
  $r->post('/admin/articles/edit')->over(isAdmin => 1)->to('AdminArticles#update');

  $r->any('/admin/menus/edit/:id')->over(isAdmin => 1)->to('AdminMenus#edit');
  $r->any('/admin/menus/edit/:id/new')->over(isAdmin => 1)->to('AdminMenus#newItem');
  $r->get('/admin/menus/remove/:menu_id/:item_id')->over(isAdmin => 1)->to('AdminMenus#deleteItem');
  $r->any('/admin/menus/edit/:menu_id/:item_id')->over(isAdmin => 1)->to('AdminMenus#editItem');
  $r->any('/admin/menus/new')->over(isAdmin => 1)->to('AdminMenus#create');
  $r->get('/admin/menus/remove/:id')->over(isAdmin => 1)->to('AdminMenus#delete');

  $r->any('/(*everything')->to('Main#error');
}

1;
