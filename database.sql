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
	id_device integer NOT NULL,
	description character varying(40) NOT NULL,
	mib character varying(30) NOT NULL,
	CONSTRAINT pk_id_oids PRIMARY KEY (id),
	CONSTRAINT fk_id_device FOREIGN KEY (id_device) REFERENCES public.devices (id_device)
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
CREATE OR REPLACE FUNCTION obtain_mibs(i_target INTEGER, i_description character varying(40)) RETURNS JSON
AS
$body$
	SELECT JSON_AGG(src) AS my_json_array
	FROM (
	  SELECT oids.mib FROM oids WHERE oids.id_device = i_target AND oids.description = i_description
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
CREATE OR REPLACE FUNCTION insert_new_device(i_id_administrator INTEGER, i_device_name character varying(25), i_ip cidr, i_model INTEGER) RETURNS INTEGER AS
$body$
BEGIN
	INSERT INTO devices (id_administrator, device_name, ip, id_model) VALUES (i_id_administrator, i_device_name, i_ip, i_model);
	RETURN (SELECT MAX(id_device) FROM devices);
END;
$body$
LANGUAGE plpgsql;

-- Insert new oids
CREATE OR REPLACE FUNCTION insert_new_oids(i_target INTEGER, i_description character varying(40), i_mib character varying(30)) RETURNS BOOLEAN AS
$body$
BEGIN
	INSERT INTO oids (id_device, description, mib) VALUES (i_target, i_description, i_mib);
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
INSERT INTO models (device_model) VALUES ('Cisco_Catalyst_2950');
SELECT insert_new_device(1,'SwitchTest', '198.162.1.1'::inet::cidr,1);
SELECT insert_new_oids(1, 'Port trafic', '1.3.6.1.2.1.2.2.1.11');
SELECT insert_new_oids(1, 'Port description', '1.3.6.1.2.1.2.2.1.2');
