CREATE TABLE interface (
  id INT UNSIGNED NOT NULL auto_increment PRIMARY KEY,
  name VARCHAR(255) not null,
  interface ENUM('REST') not null,
  type ENUM('search','get','add','update') not null,
  url VARCHAR(255) not null,
  port smallint not null
) ENGINE = InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE parameter (
  id INT UNSIGNED NOT NULL auto_increment PRIMARY KEY,
  interface_id int UNSIGNED NOT NULL,
  name VARCHAR(255),
  CONSTRAINT `fk_parameter_interface`
		FOREIGN KEY (interface_id) REFERENCES interface (id)
		ON DELETE CASCADE
		ON UPDATE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE merge (
  id INT UNSIGNED NOT NULL auto_increment PRIMARY KEY,
  localnumber int UNSIGNED NOT NULL,
  remotenumber int UNSIGNED NOT NULL,
  type ENUM('new','update'),
  timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE = InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;