package Test2::Plugin::MyTags;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ($self, $app) = @_;

  $app->helper(menu => sub {
    my ($c,$menu_name,@args) = @_;
    my $template = '<div class="collapse navbar-collapse"><ul class="nav navbar-nav">';
    my $menu_id = 0;

    my $query = 'select id from menus where name=?';
    my $results = $c->db->query($query, $menu_name);
    my $hash = $results->hash;
    if (exists $hash->{id}) {
      $menu_id = $hash->{id};
    }

    if($menu_id) {
      $query = 'select name, url, role_id from menu_items where menu_id=?';
      $results = $c->db->query($query, $menu_id);

      while(my $next = $results->hash) {
        my $role = $next->{role_id};
        if( ($role == 4) || ($role == 5 && !$c->session('user')) ||
            ($role == 6 && $c->session('user')) || ($role == $c->role) ) {
          $template .= '<li><a href="'.$next->{url}.'">';
          if($next->{name} eq 'Cabinet') {
            $template .= $c->session('user');
          } else {
            $template .= $next->{name};
          }
          $template .= '</a></li>';
        }
      }
    }

    $template .= '</ul></div>';

    return $template;
  });
}

1;
