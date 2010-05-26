DELIMITER ;;
USE ublip_prod;;

DROP FUNCTION IF EXISTS distance;;
CREATE FUNCTION distance (	
	lat1 FLOAT,
	lng1 FLOAT,
	lat2 FLOAT,
	lng2 FLOAT
) RETURNS FLOAT
DETERMINISTIC
COMMENT 'Calculate distance between two points in miles'
BEGIN
	RETURN (((acos(sin((lat1*pi()/180)) * sin((lat2*pi()/180)) + cos((lat1*pi()/180)) * cos((lat2*pi()/180)) 
   * cos(((lng1 - lng2)*pi()/180))))*180/pi())*60*1.1515);
END;;

/*comment to make netbeans sql editor happy*/


DROP PROCEDURE IF EXISTS insert_stop_event;;
CREATE PROCEDURE insert_stop_event(
	_latitude DECIMAL(15,10),
	_longitude DECIMAL(15,10),
	_modem VARCHAR(22),
	_created DATETIME,
	_reading_id INT(11)
)
BEGIN
	DECLARE deviceID INT(11);
	DECLARE latestStopID INT(11);
    DECLARE duplicateStopID INT(11);

	SELECT id INTO deviceID FROM devices WHERE imei=_modem;
    SELECT id INTO duplicateStopID FROM stop_events WHERE reading_id=_reading_id LIMIT 1;

	IF deviceID IS NOT NULL AND duplicateStopID IS NULL THEN
		SELECT id INTO latestStopID FROM stop_events WHERE device_id=deviceID AND created_at <= _created ORDER BY created_at desc limit 1;
		IF (SELECT id FROM stop_events WHERE id=latestStopID AND duration IS NULL and distance(_latitude, _longitude, latitude, longitude) < 0.1) IS NULL THEN
			INSERT INTO stop_events (latitude, longitude, created_at, device_id, reading_id)
		   		VALUES (_latitude, _longitude, _created, deviceID, _reading_id);
		END IF;
	END IF;
END;;

DROP PROCEDURE IF EXISTS insert_idle_event;;
CREATE PROCEDURE insert_idle_event(
	_latitude DECIMAL(15,10),
	_longitude DECIMAL(15,10),
	_modem VARCHAR(22),
	_created DATETIME,
	_reading_id INT(11)
)
BEGIN
	DECLARE deviceID INT(11);
	DECLARE previousIdleID INT(11);
    DECLARE previousIdleDuration INT(11);
    DECLARE distanceFromPreviousIdle INT(11);
    DECLARE subsequentIdleID INT(11);
    DECLARE intermediateNonIdleReadingCount INT(11);
    DECLARE subsequentIdleTime DATETIME;
	
	SELECT id INTO deviceID FROM devices WHERE imei=_modem;
	
	IF deviceID IS NOT NULL THEN
		SELECT id INTO previousIdleID FROM idle_events WHERE device_id=deviceID AND created_at <= _created ORDER BY created_at desc limit 1;
        IF previousIdleID IS NOT NULL THEN
            SELECT duration,distance(_latitude, _longitude, latitude, longitude) INTO previousIdleDuration,distanceFromPreviousIdle
                FROM idle_events WHERE id=previousIdleID;
        END IF;

        SELECT id,created_at INTO subsequentIdleID,subsequentIdleTime FROM idle_events where device_id=deviceID AND created_at > _created ORDER BY created_at asc limit 1;
        SELECT COUNT(*) INTO intermediateNonIdleReadingCount FROM readings where device_id=deviceID AND created_at BETWEEN _created AND subsequentIdleTime AND (ignition=FALSE OR speed>0);

        IF (subsequentIdleID IS NOT NULL) AND (intermediateNonIdleReadingCount=0) THEN
            UPDATE idle_events SET created_at=_created WHERE id=subsequentIdleID;
		ELSEIF (previousIdleID IS NULL) OR (previousIdleDuration IS NOT NULL) OR (distanceFromPreviousIdle>0.1)  THEN
			INSERT INTO idle_events (latitude, longitude, created_at, device_id, reading_id)
		   		VALUES (_latitude, _longitude, _created, deviceID, _reading_id);
		END IF;
	END IF;
END;;

DROP PROCEDURE IF EXISTS insert_runtime_event;;
CREATE PROCEDURE insert_runtime_event(
	_latitude DECIMAL(15,10),
	_longitude DECIMAL(15,10),
	_modem VARCHAR(22),
	_created DATETIME,
	_reading_id INT(11)
)
BEGIN
	DECLARE deviceID INT(11);
	DECLARE latestRuntimeID INT(11);
	
	SELECT id INTO deviceID FROM devices WHERE imei=_modem;
	
	IF deviceID IS NOT NULL THEN
		SELECT id INTO latestRuntimeID FROM runtime_events WHERE device_id=deviceID AND created_at <= _created ORDER BY created_at desc limit 1;
		IF (SELECT id FROM runtime_events WHERE id=latestRuntimeID AND duration IS NULL) IS NULL THEN
			INSERT INTO runtime_events (latitude, longitude, created_at, device_id, reading_id)
		   		VALUES (_latitude, _longitude, _created, deviceID, _reading_id);
		END IF;
	END IF;
END;;

DROP PROCEDURE IF EXISTS insert_engine_off_event;;
CREATE PROCEDURE insert_engine_off_event(
	_latitude DECIMAL(15,10),
	_longitude DECIMAL(15,10),
	_modem VARCHAR(22),
	_created DATETIME,
	_reading_id INT(11)
)
BEGIN
	
END;;


DROP PROCEDURE IF EXISTS insert_reading;;
CREATE PROCEDURE insert_reading(
	_latitude DECIMAL(15,10),
	_longitude DECIMAL(15,10),
	_altitude  FLOAT,
	_speed FLOAT,
	_heading float,
	_modem VARCHAR(22),
	_created DATETIME,
	_event_type VARCHAR(25)
)
BEGIN
	DECLARE deviceID INT(11);
	
	SELECT id INTO deviceID FROM devices WHERE imei=_modem;
	INSERT INTO readings (device_id, latitude, longitude, altitude, speed, direction, event_type, created_at)
		VALUES (deviceID, _latitude, _longitude, _altitude, _speed, _heading, _event_type, _created);
END;;

DROP PROCEDURE IF EXISTS insert_reading_with_io;;
CREATE PROCEDURE insert_reading_with_io(
	_latitude DECIMAL(15,10),
	_longitude DECIMAL(15,10),
	_altitude  FLOAT,
	_speed FLOAT,
	_heading float,
	_modem VARCHAR(22),
	_created DATETIME,
	_event_type VARCHAR(25),
	_ignition TINYINT(1),
	_gpio1 TINYINT(1),
	_gpio2 TINYINT(1)
)
BEGIN
	DECLARE deviceID INT(11);

	SELECT id INTO deviceID FROM devices WHERE imei=_modem;
	INSERT INTO readings (device_id, latitude, longitude, altitude, speed, direction, event_type, created_at, ignition, gpio1, gpio2)
		VALUES (deviceID, _latitude, _longitude, _altitude, _speed, _heading, _event_type, _created, _ignition, _gpio1, _gpio2);
END;;

DROP PROCEDURE IF EXISTS insert_reading_with_io_returnval;;
CREATE PROCEDURE insert_reading_with_io_returnval(
	_latitude DECIMAL(15,10),
	_longitude DECIMAL(15,10),
	_altitude  FLOAT,
	_speed FLOAT,
	_heading float,
	_modem VARCHAR(22),
	_created DATETIME,
	_event_type VARCHAR(25),
	_ignition TINYINT(1),
	_gpio1 TINYINT(1),
	_gpio2 TINYINT(1),
	OUT _rails_reading_id INT(11)
) 
BEGIN
	SELECT id INTO @deviceID FROM devices WHERE imei=_modem;
	INSERT INTO readings (device_id, latitude, longitude, altitude, speed, direction, event_type, created_at, ignition, gpio1, gpio2)
		VALUES (@deviceID, _latitude, _longitude, _altitude, _speed, _heading, _event_type, _created, _ignition, _gpio1, _gpio2);
	SET _rails_reading_id = LAST_INSERT_ID();
END;;

DROP PROCEDURE IF EXISTS process_stop_events;;
DROP PROCEDURE IF EXISTS process_idle_events;;

DROP PROCEDURE IF EXISTS process_runtime_events;;
CREATE PROCEDURE process_runtime_events()
BEGIN
	DECLARE num_events_to_check INT;
	CREATE TEMPORARY TABLE open_runtime_events(runtime_event_id INT(11), checked BOOLEAN);
	INSERT INTO open_runtime_events SELECT id, FALSE FROM runtime_events where duration IS NULL;
	SELECT COUNT(*) INTO num_events_to_check FROM open_runtime_events WHERE checked=FALSE;
	WHILE num_events_to_check>0 DO BEGIN
		DECLARE eventID INT;
		DECLARE first_off_after_runtime_id INT;
		DECLARE runtimeDuration INT;
		DECLARE deviceID INT;
		DECLARE runtimeTime DATETIME;
		
		SELECT runtime_event_id INTO eventID FROM open_runtime_events WHERE checked=FALSE limit 1;
		SELECT device_id, created_at into deviceID, runtimeTime FROM runtime_events where id=eventID;
		UPDATE open_runtime_events SET checked=TRUE WHERE runtime_event_id=eventId;
		
		SELECT id INTO first_off_after_runtime_id FROM readings  
		  WHERE device_id=deviceID AND ignition=0 AND created_at>runtimeTime ORDER BY created_at ASC LIMIT 1;
		  
		IF first_off_after_runtime_id IS NOT NULL THEN	 
			SELECT TIMESTAMPDIFF(MINUTE, runtimeTime, created_at) INTO runtimeDuration FROM readings where id=first_off_after_runtime_id;
			UPDATE runtime_events SET duration = runtimeDuration where id=eventID;
		END IF;
		
		SELECT COUNT(*) INTO num_events_to_check FROM open_runtime_events WHERE checked=FALSE;
	END;
	END WHILE;
END;;

DROP PROCEDURE IF EXISTS create_stop_events;;
DROP PROCEDURE IF EXISTS migrate_stop_data;;

DROP TRIGGER IF EXISTS trig_readings_after_insert;;
CREATE TRIGGER trig_readings_after_insert AFTER INSERT ON readings FOR EACH ROW BEGIN
	DECLARE last_reading_time DATETIME;
	IF NEW.created_at IS NOT NULL THEN
	IF NEW.event_type IN ('engine on','engine off','GPS Lock') THEN
		INSERT INTO spanning_event_hits (id,device_id,event_type,ignition,speed,created_at) VALUES (NEW.id,NEW.device_id,NEW.event_type,NEW.ignition,NEW.speed,NEW.created_at);
	ELSE
		SET @time_delay = 1; -- assure that no match is neither "delayed", "tardy" or "duplicate"
		SELECT TIME_TO_SEC(TIMEDIFF(NEW.created_at,MAX(r.created_at))) INTO @time_delay FROM readings r WHERE r.device_id = NEW.device_id AND r.created_at >= NEW.created_at AND r.id < NEW.id;
		IF @time_delay < -5 * 60 THEN
			INSERT INTO spanning_event_hits (id,device_id,event_type,ignition,speed,created_at) VALUES (NEW.id,NEW.device_id,'delayed',NEW.ignition,NEW.speed,NEW.created_at);
		ELSEIF @time_delay < 0 THEN
			INSERT INTO spanning_event_hits (id,device_id,event_type,ignition,speed,created_at) VALUES (NEW.id,NEW.device_id,'tardy',NEW.ignition,NEW.speed,NEW.created_at);
		ELSEIF @time_delay = 0 THEN
			INSERT INTO spanning_event_hits (id,device_id,event_type,ignition,speed,created_at) VALUES (NEW.id,NEW.device_id,'duplicate',NEW.ignition,NEW.speed,NEW.created_at);
		ELSE
			SELECT NULL,NULL,NULL,NULL INTO @last_event_type,@last_ignition,@last_speed,@last_created_at;
			SELECT r.event_type,r.ignition,r.speed,r.created_at
				INTO @last_event_type,@last_ignition,@last_speed,@last_created_at
				FROM readings r
				WHERE r.device_id = NEW.device_id AND r.id < NEW.id AND r.created_at BETWEEN ADDDATE(NEW.created_at,INTERVAL -5 MINUTE) AND NEW.created_at
				ORDER BY created_at DESC,id DESC
				LIMIT 1;
			IF @last_created_at IS NULL THEN
				INSERT INTO spanning_event_hits (id,device_id,event_type,ignition,speed,created_at) VALUES (NEW.id,NEW.device_id,'alone',NEW.ignition,NEW.speed,NEW.created_at);
			ELSEIF @last_event_type = 'GPS Lock' OR
				@last_ignition IS NULL OR NEW.ignition IS NULL OR
				(@last_speed > 0 AND NEW.speed = 0) OR (@last_speed = 0 AND NEW.speed > 0) OR
				(NEW.ignition IS NOT NULL AND @last_ignition IS NOT NULL AND NEW.ignition != @last_ignition) THEN
				INSERT INTO spanning_event_hits (id,device_id,event_type,ignition,speed,created_at) VALUES (NEW.id,NEW.device_id,'other',NEW.ignition,NEW.speed,NEW.created_at);
			END IF;
		END IF;
	END IF;

	SELECT r.created_at INTO last_reading_time FROM devices d,readings r WHERE d.id=NEW.device_id AND r.id=d.recent_reading_id;
	IF NEW.created_at >= last_reading_time OR last_reading_time IS NULL THEN
		UPDATE devices SET recent_reading_id=NEW.id WHERE id=NEW.device_id;
	END IF;
END IF;

END;;

DROP PROCEDURE IF EXISTS insert_trip_event;;

DROP TRIGGER IF EXISTS `trig_outbound_after_insert` ;;
CREATE TRIGGER `trig_outbound_after_insert` AFTER INSERT ON `commands` FOR EACH ROW BEGIN
	DECLARE dbName varchar(30);
	DECLARE deviceId varchar(30);
	DECLARE smsxDeviceRecordId int(11);

	SET dbName=DATABASE();
	SELECT imei INTO deviceId FROM devices WHERE id=NEW.device_id LIMIT 1;
	SELECT id INTO smsxDeviceRecordId FROM smsx.devices WHERE device_id=deviceId or imei=deviceId or iccid=deviceId or imsi=deviceId ORDER BY TIMESTAMP DESC LIMIT 1;

	IF smsxDeviceRecordId is NULL THEN
		INSERT INTO smsx.devices (device_id, gateway) VALUES (deviceId, dbName);
	ELSE
		UPDATE smsx.devices SET gateway=dbName where device_id=deviceId;
	END IF;

	insert into smsx.outbound(device_id, gateway_outbound_id, command, start_date_time, status) values (deviceId, NEW.id, NEW.command, NEW.start_date_time, NEW.status);
END;;

DROP TRIGGER IF EXISTS `trig_outbound_after_update` ;;
CREATE TRIGGER `trig_outbound_after_update` AFTER UPDATE ON `commands` FOR EACH ROW BEGIN
	IF NEW.status='Processing' THEN
		UPDATE smsx.outbound SET status=NEW.status, end_date_time=NEW.end_date_time WHERE gateway_outbound_id=NEW.id;
	END IF;
END;;
