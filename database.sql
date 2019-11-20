create domain t_email varchar(30) not null 
constraint CHK_email check (value similar to '[A-z]%@[A-z]%.[A-z]%');

------------------------------------------------------------------------------ TABLES ----------------------------------------------------------------------------------
CREATE TABLE users
(
	id_administrator SERIAL NOT NULL,
	user_name character varying(30) NOT NULL,
	email t_email NOT NULL,
	CONSTRAINT pk_id_users PRIMARY KEY (id_administrator)
);

CREATE TABLE models
(
	id_model SERIAL NOT NULL,
	device_model character varying(20) NOT NULL,
	CONSTRAINT pk_id_models PRIMARY KEY (id_model)
);

CREATE TABLE devices
(
	id_device SERIAL NOT NULL,
	id_administrator INTEGER NOT NULL,
	id_model INTEGER NOT NULL,
	device_name CHARACTER VARYING(25) NOT NULL,
	ip cidr NOT NULL,
	CONSTRAINT pk_id_devices PRIMARY KEY (id_device),
	CONSTRAINT fk_id_administrator FOREIGN KEY (id_administrator) REFERENCES users (id_administrator),
	CONSTRAINT fk_id_model FOREIGN KEY (id_model) REFERENCES models (id_model)
);

CREATE TABLE oids
(
	id SERIAL NOT NULL,
	id_model integer NOT NULL,
	description character varying(40) NOT NULL,
	mib character varying(30) NOT NULL,
	CONSTRAINT pk_id_oids PRIMARY KEY (id),
	CONSTRAINT fk_id_model FOREIGN KEY (id_model) REFERENCES public.models (id_model)
);

------------------------------------------------------------------------ FUNCTIONS -----------------------------------------------------------------------------------
-- Obtain device ip, administrator name and email
CREATE OR REPLACE FUNCTION obtain_device_information(i_target INTEGER) RETURNS JSON
AS
$body$
	SELECT JSON_AGG(src) AS my_json_array
	FROM (
	  SELECT devices.ip, users.user_name, users.email 
	  FROM devices, users WHERE devices.id_device = i_target AND devices.id_administrator = users.id_administrator
	) src
	;
$body$
LANGUAGE sql;

-- Obtain device ip, administrator name and email
CREATE OR REPLACE FUNCTION obtain_mibs(i_target INTEGER) RETURNS JSON
AS
$body$
	SELECT JSON_AGG(src) AS my_json_array
	FROM (
	  SELECT oids.description, oids.mib FROM oids, devices WHERE oids.id_model = devices.id_model AND devices.id_device = i_target ORDER BY oids.id
	) src
	;
$body$
LANGUAGE sql;

-- Get all users 
CREATE OR REPLACE FUNCTION get_users()  
RETURNS JSON
AS
$body$
	
	SELECT JSON_AGG(src) AS my_json_array
	FROM (
	  SELECT 
	    users.id_administrator, users.user_name
	  FROM users
	) src
	;
$body$
LANGUAGE sql;

--Get all models 
CREATE OR REPLACE FUNCTION get_models()  
RETURNS JSON
AS
$body$
	
	SELECT JSON_AGG(src) AS my_json_array
	FROM (
	  SELECT models.id_model, models.device_model FROM models
	) src
	;
$body$
LANGUAGE sql;

-- Insert new device
CREATE OR REPLACE FUNCTION insert_new_model(i_device_model character varying(20)) RETURNS INTEGER AS
$body$
BEGIN
	INSERT INTO models (device_model) VALUES (i_device_model);
	RETURN (SELECT MAX(id_model) FROM models);
END;
$body$
LANGUAGE plpgsql;

-- Insert new device
CREATE OR REPLACE FUNCTION insert_new_device(i_id_administrator INTEGER, i_device_name character varying(25), i_ip cidr, i_model INTEGER) RETURNS INTEGER AS
$body$
BEGIN
	INSERT INTO devices (id_administrator, device_name, ip, id_model) VALUES (i_id_administrator, i_device_name, i_ip, i_model);
	RETURN (SELECT MAX(id_device) FROM devices);
END;
$body$
LANGUAGE plpgsql;

-- Insert new oids
CREATE OR REPLACE FUNCTION insert_new_oids(i_model INTEGER, i_description character varying(40), i_mib character varying(30)) RETURNS BOOLEAN AS
$body$
BEGIN
	INSERT INTO oids (id_model, description, mib) VALUES (i_model, i_description, i_mib);
	RETURN TRUE;
END;
$body$
LANGUAGE plpgsql;

--INSERTS
INSERT INTO users (user_name, email) VALUES ('Nathalie Rojas','nathalieroarce08@gmail.com');
INSERT INTO users (user_name, email) VALUES ('Keslerth Calderón','keslerthc@gmail.com');
INSERT INTO users (user_name, email) VALUES ('Steven Peraza','sjpp8448@gmail.com');
INSERT INTO users (user_name, email) VALUES ('Vinicio Rodríguez','viniciorodriguez97@gmail.com');
INSERT INTO users (user_name, email) VALUES ('Rogelio Gonzáles','rojo@tec.ac.cr');
INSERT INTO models (device_model) VALUES ('2900'),('2960'),('1200');
SELECT insert_new_device(1,'Switch1', '198.162.1.1'::inet::cidr,3);
SELECT insert_new_device(2,'Router1', '198.162.1.101'::inet::cidr,1);
SELECT insert_new_device(3,'Router2', '198.162.1.2'::inet::cidr,2);
SELECT insert_new_oids(1, 'Port trafic', '1.3.6.1.2.1.2.2.1.11');
SELECT insert_new_oids(1, 'Port description', '1.3.6.1.2.1.2.2.1.2');
SELECT insert_new_oids(2, 'Port trafic', '1.3.6.1.2.1.2.2.1.11');
SELECT insert_new_oids(2, 'Port description', '1.3.6.1.2.1.2.2.1.2');
SELECT insert_new_oids(3, 'Port trafic', '1.3.6.1.2.1.2.2.1.11');
SELECT insert_new_oids(3, 'Port description', '1.3.6.1.2.1.2.2.1.2');
