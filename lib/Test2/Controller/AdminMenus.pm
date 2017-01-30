package Test2::Controller::AdminMenus;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::SQLite;
use Db::MyDB;
use Digest;

sub edit {
  my $self = shift;
  my $id = $self->param('id');

  return $self->redirect_to('/admin/menus')
    if ! $self->itemExist('menus',$id);

  if($self->req->method eq 'POST') {
    my $name = $self->param('title');
    my $query = 'update menus set name=? where id=?';
    $self->db->query($query, $name, $id);

    return $self->redirect_to('/admin/menus/edit/'.$id);
  }

  my $query = 'select name from menus where id=?';
  my $results = $self->db->query($query, $id);
  my $row = $results->hash;

  $query = 'select T1.id, T1.name, T1.url, T2.name as role_name from menu_items
  as T1 left join roles as T2 on T1.role_id = T2.id where T1.menu_id=?';
  $results = $self->db->query($query, $id);

  $self->render(name => $row->{name}, id => $id, list => $results);
}

sub newItem {
  my $self = shift;
  my $id = $self->param('id');
  my $query;
  my $results;

  return $self->redirect_to('/admin/menus')
    if ! $self->itemExist('menus',$id);

  if($self->req->method eq 'POST') {
    my $name = $self->param('name');
    my $url = $self->param('url');
    my $role = $self->param('role');

    $query = 'insert into menu_items values(NULL,?,?,?,?)';
    $self->db->query($query, $id, $name, $url, $role);

    return $self->redirect_to('/admin/menus/edit/'.$id);
  }

  $query = 'select name from menus';
  $results = $self->db->query($query);
  my $menu_names = $results->arrays;

  $query = 'select id, name from roles';
  $results = $self->db->query($query);

  $self->render(id => $id, menus => $menu_names, roles_list => $results);
}

sub deleteItem {
  my $self = shift;
  my $menu_id = $self->param('menu_id');
  my $item_id = $self->param('item_id');

  return $self->redirect_to('/admin/menus')
    if ! $self->itemExist('menus',$menu_id);
  return $self->redirect_to('/admin/menus/edit/'.$menu_id)
    if ! $self->itemExist('menu_items',$item_id);

  my $query = 'DELETE FROM menu_items WHERE menu_id=? AND id=?';
  $self->db->query($query, $menu_id, $item_id);

  $self->redirect_to('/admin/menus/edit/'.$menu_id);
}

sub editItem {
  my $self = shift;
  my $menu_id = $self->param('menu_id');
  my $item_id = $self->param('item_id');

  return $self->redirect_to('/admin/menus')
    if ! $self->itemExist('menus',$menu_id);
  return $self->redirect_to('/admin/menus/edit/'.$menu_id)
    if ! $self->itemExist('menu_items',$item_id);

  if($self->req->method eq 'POST') {
    my $name = $self->param('name');
    my $url = $self->param('url');
    my $role = $self->param('role');

    my $query = 'UPDATE menu_items SET name=?, url=?, role_id=? WHERE id=?';
    $self->db->query($query, $name, $url, $role, $item_id);

    $self->redirect_to('/admin/menus/edit/'.$menu_id);
  }

  my $query = 'SELECT name, url, role_id FROM menu_items WHERE id=?';
  my $results = $self->db->query($query, $item_id);
  my $row = $results->hash;

  $query = 'SELECT id, name FROM roles';
  $results = $self->db->query($query);

  $self->render(menu_id => $menu_id, item_id => $item_id, name => $row->{name},
  url => $row->{url}, role => $row->{role_id}, roles_list => $results);
}

sub create {
  my $self = shift;

  if($self->req->method eq 'POST') {
    my $name = $self->param('name');
    my $query = 'INSERT INTO menus VALUES(NULL,?)';
    $self->db->query($query, $name);

    $self->redirect_to('/admin/menus');
  }

  $self->render();
}

sub delete {
  my $self = shift;
  my $id = $self->param('id');

  return $self->redirect_to('/admin/menus')
    if ! $self->itemExist('menus',$id);

  my $query = 'DELETE FROM menus WHERE id=?';
  $self->db->query($query, $id);

  $query = 'DELETE FROM menu_items WHERE menu_id=?';
  $self->db->query($query, $id);

  $self->redirect_to('/admin/menus');
}

1;
