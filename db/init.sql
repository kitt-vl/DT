-- 1 up
CREATE TABLE users (id integer primary key autoincrement, email text, password
text, role_id integer, foreign key(role_id) references roles(id));
INSERT INTO `users` VALUES (NULL,'admin@mail.ru','f4b42813c7ffa6b505312cc29aa7d840d587d65aa3580e',1),
 (NULL,'user@mail.ru','f4b42813c7ffa6b505312cc29aa7d840d587d65aa3580e',2);
-- 1 down
DROP TABLE users;

-- 2 up
CREATE TABLE roles (id integer primary key autoincrement, name text);
INSERT INTO `roles` VALUES (NULL,'administrator'),
 (NULL,'user'),
 (NULL,'editor'),
 (NULL,'any'),
 (NULL,'unauthorized'),
 (NULL,'authorized');
-- 2 down
DROP TABLE users;

-- 3 up
CREATE TABLE menus (id integer primary key autoincrement, name text);
INSERT INTO `menus` VALUES (NULL, 'Main menu');
-- 3 down
DROP TABLE menus;

-- 4 up
CREATE TABLE menu_items (id integer primary key autoincrement, menu_id integer,
name text, url text, role_id integer, foreign key(menu_id) references menus(id),
foreign key(role_id) references roles(id));
INSERT INTO `menu_items` VALUES (NULL,1,'Home','/',4),
 (NULL,1,'About','#about',4),
 (NULL,1,'Contact','#contact',4),
 (NULL,1,'Admin panel','/admin',1),
 (NULL,1,'Log in','/login',5),
 (NULL,1,'Cabinet','#cabinet',6),
 (NULL,1,'Log out','/logout',6);
-- 4 down
DROP TABLE menu_items;

-- 5 up
CREATE TABLE articles (id integer primary key autoincrement, title text, body text,
author integer, date_create text, date_update text, url text unique, foreign key(author)
references users(id));
INSERT INTO `articles` VALUES (NULL,'Example title','Example body',1,'2017-01-12T12:47','','/articles/1');
-- 5 down
DROP TABLE articles;

-- 6 up
CREATE TABLE files (id integer primary key autoincrement, name text, owner_id integer,
owner_type text, source text);
-- 6 down
DROP TABLE files;
