##############################################################################################
################################## DESCRIPTION###################################
#This file contains following sections:
-- CREATE AND USE DATABASE
-- CREATE TABLES
-- PROCEDURES & TRIGGERS 
-- INSERT INTO TABLES 
-- CREATE VIEWS
-- QUERIES

##############################################################################################
################################## CREATE AND USE DATABASE ###################################
drop database  if exists project_19200134 ;
create database project_19200134;
use project_19200134;

##############################################################################################
################################## CREATE TABLES ##############################################
##### TABLE STREAM #####
CREATE TABLE Stream (
    stream_id VARCHAR(10),
    stream_title VARCHAR(20) NOT NULL,
    stream_description VARCHAR(40) NOT NULL,
    PRIMARY KEY (stream_id)
);

##### TABLE STUDENT #####
CREATE TABLE Student (
    student_id VARCHAR(10) NOT NULL,
    student_name VARCHAR(40) NOT NULL,
    stream_id VARCHAR(10) NOT NULL,
    GPA DECIMAL(3,2) NOT NULL,
    DOB DATE,
    gender VARCHAR(6),
    nationality VARCHAR(10),
    PRIMARY KEY (student_id),
    FOREIGN KEY (stream_id) REFERENCES Stream (stream_id)
); 

##### TABLE SUPERVISOR #####
CREATE TABLE Supervisor (
    supervisor_id VARCHAR(10) NOT NULL,
    supervisor_name VARCHAR(40) NOT NULL,
    specialisation_streamID VARCHAR(10) NOT NULL,
    email VARCHAR(40) NOT NULL,
    DOB DATE,
    gender VARCHAR(6),
    nationality VARCHAR(10),
    PRIMARY KEY (supervisor_id),
	FOREIGN KEY (specialisation_streamID) REFERENCES Stream (stream_id)
);

##### TABLE PROJECTS #####
CREATE TABLE projects (
    project_id VARCHAR(10) NOT NULL,
    project_title VARCHAR(60) NOT NULL,
    stream_designator VARCHAR(10) NOT NULL,
    supervisor_id VARCHAR(10) NOT NULL,
    proposed_studentID VARCHAR(10),
    PRIMARY KEY (project_id),
    FOREIGN KEY (supervisor_id)   REFERENCES Supervisor (supervisor_id),
    UNIQUE (project_title)
);

##### TABLE STUDENT PREFERENCES #####
CREATE TABLE Student_Preferences (
    student_id VARCHAR(10) NOT NULL,
    pref1 VARCHAR(10) NOT NULL,
    pref2 VARCHAR(10),
    pref3 VARCHAR(10),
    pref4 VARCHAR(10),
    pref5 VARCHAR(10),
    pref6 VARCHAR(10),
    pref7 VARCHAR(10),
    pref8 VARCHAR(10),
    pref9 VARCHAR(10),
    pref10 VARCHAR(10),
    pref11 VARCHAR(10),
    pref12 VARCHAR(10),
    pref13 VARCHAR(10),
    pref14 VARCHAR(10),
    pref15 VARCHAR(10),
    pref16 VARCHAR(10),
    pref17 VARCHAR(10),
    pref18 VARCHAR(10),
    pref19 VARCHAR(10),
    pref20 VARCHAR(10),
    PRIMARY KEY (student_id),
    FOREIGN KEY (student_id) REFERENCES Student (student_id)
);

##### TABLE STUDENT_PROJECT_MAPPING #####
CREATE TABLE Student_Project_Mapping (
    student_id VARCHAR(10),
    project_id VARCHAR(10) NOT NULL,
    prefAllocated INT,
    PRIMARY KEY (project_id),
    UNIQUE (student_id),
    FOREIGN KEY (student_id) REFERENCES Student (student_id),
    FOREIGN KEY (project_id) REFERENCES Projects (project_id)
);

##### TABLE STUDENT_SATISFACTION #####
CREATE TABLE Student_Satisfaction (
    student_id VARCHAR(10) NOT NULL,
    satisfaction_score INT,
    PRIMARY KEY (student_id),
    FOREIGN KEY (student_id) REFERENCES Student (student_id)
);

##############################################################################################
################################## PROCEDURES & TRIGGERS #####################################
 
####### Validate the gpa
DROP PROCEDURE IF EXISTS  student_gpa_check;
DELIMITER //
CREATE PROCEDURE validate_Student(
	IN GPA DECIMAL	
)
DETERMINISTIC
BEGIN
	IF (SELECT FLOOR(GPA-0)) <= 0.00 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID INSERT! GPA should be greater than 0';
	END IF;
    IF GPA > 4.20 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID INSERT! GPA should be less than 4.2';
	END IF;
END //
DELIMITER ;

####### TRIGGER #######
DELIMITER //
CREATE TRIGGER validate_gpa_insert
BEFORE INSERT ON Student FOR EACH ROW
BEGIN
	CALL validate_Student(NEW.GPA);
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER validate_Student_update
BEFORE UPDATE ON Student FOR EACH ROW
BEGIN
	CALL validate_Student( NEW.GPA);
END //
DELIMITER 

###### Invalid GPA insert-- Uncomment below to see the error
##insert into STUDENT (student_id, student_name, stream_id, GPA, DOB,  gender, nationality) values (2011, 'Cathy Parker', 'CS01', '5.90', '1996-02-02', 'Female', 'Australian');

-- ----------------------------------------------------------------------------------------
###########Validate the age of the student
DROP PROCEDURE IF EXISTS validate_age;
DELIMITER //
CREATE PROCEDURE validate_age(
    IN DOB date
)
DETERMINISTIC
BEGIN
	IF (SELECT FLOOR(DATEDIFF(CURDATE(), DATE(DOB))/365)) < 18 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID student age!!';
	END IF;
END //
DELIMITER ;

####### TRIGGER #######

DELIMITER //
CREATE TRIGGER validate_age_insert
BEFORE INSERT ON Student FOR EACH ROW
BEGIN
	CALL validate_age(NEW.DOB);
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER validate_age_update
BEFORE UPDATE ON Student FOR EACH ROW
BEGIN
	CALL validate_age(NEW.DOB);
END //
DELIMITER ;

###### Invalid Age insert-- Uncomment below to see the error
## insert into STUDENT (student_id, student_name, stream_id, GPA, DOB,  gender, nationality) values (2011, 'Cathy Parker', 'CS01', '3.90', '2010-02-02', 'Female', 'Australian');

-- ----------------------------------------------------------------------------------------
######Validate project exists in the system
DROP PROCEDURE IF EXISTS validate_project_exists;
DELIMITER //
CREATE PROCEDURE validate_project_exists(
    IN projectID VARCHAR(6)
)
DETERMINISTIC
BEGIN
	
	IF (select count(*)from projects p where p.project_id=projectID) =0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Project not found in the system';
	END IF;
END //
DELIMITER ;

####### TRIGGER #######
DELIMITER //
CREATE TRIGGER check_project_exists
BEFORE INSERT ON Student_Project_Mapping FOR EACH ROW
BEGIN
	CALL validate_project_exists(NEW.project_id);
END //
DELIMITER ;

###### Invalid Project insert in student project mapping-- Uncomment below to see the error
#insert into Student_Project_Mapping (student_id, project_id, prefAllocated) values ('2001','PR056',1);

-- --------------------------------------------------------------------------------------
######Validate each student is assigned a project aligned with the stream
DROP PROCEDURE IF EXISTS validate_project;
DELIMITER //
CREATE PROCEDURE validate_project(
	IN studentID VARCHAR(6),
    IN projectID VARCHAR(6)
)
DETERMINISTIC
BEGIN
	
	IF (select stream_designator from projects where project_id=projectID)='ALL' THEN
    SIGNAL SQLSTATE '01000';
	ELSEIF (select count(*) from student where student_id=studentID and stream_id=(select (CASE stream_designator when 'CS' then 'CS01' when 'CS+DS' then 'DS01'  END) from projects where project_id=projectID) 
) =0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid Insert! Possible Project and Student stream mismatch!';
	END IF;
END //
DELIMITER ;

####### TRIGGER #######
DROP TRIGGER IF EXISTS check_project;
DELIMITER //
CREATE TRIGGER check_project
BEFORE INSERT ON Student_Project_Mapping FOR EACH ROW
BEGIN
	CALL validate_project(NEW.student_id,NEW.project_id);
END //
DELIMITER ;

###### Invalid preference insert in student project mapping-- Uncomment below to see the error after creating entries in the student table and project table with below insert statements
#insert into Student_Project_Mapping (student_id, project_id, prefAllocated) values ('2002','PR004',20);


-- ----------------------------------------------------------------------------------------
########## Check if Preference not greater than 20
DROP PROCEDURE IF EXISTS validate_preference;
DELIMITER //
CREATE PROCEDURE validate_preference(
    IN prefAllocated INT
)
DETERMINISTIC
BEGIN
	IF (SELECT prefAllocated) > 20 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID Preference number';
	END IF;
END //
DELIMITER ;

####### TRIGGER #######

DELIMITER //
CREATE TRIGGER validate_preference_insert
BEFORE INSERT ON Student_Project_Mapping FOR EACH ROW
BEGIN
	CALL validate_preference(NEW.prefAllocated);
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER validate_preference_update
BEFORE UPDATE ON Student_Project_Mapping FOR EACH ROW
BEGIN
	CALL validate_preference(NEW.prefAllocated);
END //
DELIMITER ;

###### Invalid preference insert in student project mapping-- Uncomment below to see the error
## insert into Student_Project_Mapping (student_id, project_id, prefAllocated) values ('2001','PR007',50);



##############################################################################################
################################## INSERT INTO TABLES ########################################
##### TABLE STREAM #####
insert into Stream (stream_id,stream_title,stream_description) values
('CS01','CS','Cthulhu Studies'),
('DS01','CS+DS','Dagon Studies');

##### TABLE STUDENT #####
insert into STUDENT (student_id, student_name, stream_id, GPA, DOB,  gender, nationality) values 
(2001, 'Urbain Lyhane', 'CS01', '3.90', '1992-02-02', 'Male', 'Australian'),
(2002, 'Elsie Leadbeater','DS01', '2.0', '1995-12-20', 'Female', 'Irishwoman'),
(2003, 'Con Oliver', 'DS01', '3.10', '1992-07-19','Female', 'Irishwoman'),
(2004, 'Gar Iacovelli', 'DS01', '4.19', '1990-05-03', 'Male','Italian'),
(2005, 'Mandy Ilive', 'CS01', '3.57', '1990-10-22', 'Female','Irishwoman'),
(2006, 'Samuele Arber', 'DS01', '3.97',  '1996-02-06', 'Male','Indian'),
(2007, 'Morty McCobb', 'CS01', '2.9', '1995-04-23', 'Male', 'Mexican'),
(2008, 'Elden Bard', 'DS01', '2.8',  '1991-01-24', 'Male','Australian'),
(2009, 'Conni Di Giacomettino', 'CS01', '2.50', '1991-05-29',  'Female','Irishwoman'),
(2010, 'Cathi Braley', 'DS01', '4.0', '1992-01-11','Female','Indian');

##### TABLE SUPERVISOR #####
insert into Supervisor (supervisor_id, supervisor_name, specialisation_streamID, email,DOB, gender, nationality) values
('SU001', 'Dr.Henry Armitage', 'CS01','henry.armitage@miskatonic.edu','1965-12-27', 'Male', 'Irishman'),
('SU002', 'Allen Halsey','DS01','allen.halsey@miskatonic.edu', '1987-09-01', 'Female', 'Indian'),
('SU003', 'Alley Anscombe', 'CS01','alley.anscombe@miskatonic.edu','1982-03-07', 'Male', 'Irishwoman'),
('SU004', 'Cairistiona McIlory', 'DS01', 'cairistiona.mcilory@miskatonic.edu','1964-01-04', 'Female', 'Indian'),
('SU005', 'Dr. Carl Hill', 'CS01','carl.hill@miskatonic.edu','1985-04-06', 'Female', 'Indian'),
('SU006', 'Rozelle Diviny', 'DS01','rozelle.diviny@miskatonic.edu','1966-07-16', 'Female', 'Indian'),
('SU007', 'Dr. Dan Cain', 'DS01','dan.cain@miskatonic.edu','1979-10-05', 'Female', 'Portugal'),
('SU008', 'Innis Predohl', 'CS01','innis.predohl@miskatonic.edu','1966-09-25', 'Male', 'Japanese'),
('SU009', 'Farris Adame', 'DS01','farris.adame@miskatonic.edu','1974-11-17', 'Male', 'Japanese'),
('SU010', 'Adrien Madle', 'CS01','adrien.madle@miskatonic.edu','1987-12-26', 'Male', 'Australian');

##### TABLE PROJECTS #####
insert into Projects (project_id, project_title, stream_designator,supervisor_id, proposed_studentID) values 
('PR001', 'The Shadow Out of Time', 'CS','SU001', NULL),
('PR002', 'The Thing on the Doorstep', 'CS+DS','SU002',NULL),
('PR003', 'House by the Cemetery', 'CS','SU003',NULL),
('PR004', 'The Evil Dead', 'CS', 'SU004','2001'),
('PR005', 'Forever Evil', 'CS+DS','SU005',NULL),
('PR006', 'The Shadow Over Innsmouth', 'All','SU006',NULL),
('PR007', 'Transylvania Twist', 'All','SU007',NULL),
('PR008', 'The Final Descendant', 'CS+DS','SU008',NULL),
('PR009', 'Dark Heritage', 'CS+DS','SU009',NULL),
('PR010', 'Bride of Re-Animator', 'CS','SU010',NULL),
('PR011', 'The Unnamable', 'CS+DS','SU001',NULL),
('PR012', 'The Curse', 'CS+DS','SU002','2004'),
('PR013', 'Pulse Pounders', 'CS','SU003',NULL),
('PR014', 'Evil Dead','All','SU004',NULL),
('PR015', 'From Beyond','CS','SU005',NULL),
('PR016', 'Gramma', 'CS+DS','SU006','2010'),
('PR017', 'The Thing', 'All','SU007',NULL),
('PR018', 'The Gates of Hell', 'CS','SU008','2005'),
('PR019', '7 Doors of Death', 'CS+DS','SU009',NULL),
('PR020', 'Dark Corners of the Earth', 'CS','SU010',NULL),
('PR021', 'City of the Damned', 'CS','SU001',NULL),
('PR022', 'Dunwich','ALL','SU002',NULL),
('PR023', 'Other Gods', 'CS','SU003',NULL),
('PR024', 'Terrible Old Man','All','SU004',NULL),
('PR025', ' Outsider,', 'CS','SU005',NULL),
('PR026', 'Stringtough', 'ALL','SU006',NULL),
('PR027', 'Halfway House', 'CS+DS','SU007',NULL),
('PR028', 'Rats in the Walls','CS','SU008',NULL),
('PR029', 'Lurking Fear','All','SU009',NULL),
('PR030', 'In the Vault', 'CS','SU010',NULL);


##### TABLE STUDENT_PREFERENCES #####
insert into Student_Preferences (student_id,pref1,pref2,pref3,pref4,pref5,pref6,pref7,pref8,pref9,pref10,pref11,pref12,pref13,pref14,
pref15,pref16,pref17,pref18,pref19,pref20) values
('2001','PR004','PR009','PR015','PR002','PR019','PR006','PR003','PR005','PR028','PR07','PR001','PR027','PR026','PR008','PR011','PR013','PR017','PR022','PR025','PR030'),
('2002','PR005','PR005','PR005','PR005','PR005','PR005','PR005','PR005','PR005','PR005','PR005','PR005','PR005','PR005','PR005','PR005','PR005','PR005','PR005','PR005'),
('2003','PR008','PR009','PR011','PR014','PR013','PR017','PR020','PR021','PR023','PR025','PR026','PR027','PR028','PR029',NULL,NULL,NULL,NULL,NULL,NULL),
('2004','PR012','PR003','PR005','PR006','PR007','PR008','PR009','PR011','PR012','PR013','PR014','PR015','PR002','PR017','PR001','PR019','PR020','PR021','PR029','PR026'),
('2005','PR018','PR009','PR008','PR007','PR006','PR002','PR017','PR019','PR025','PR026','PR027',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('2006','PR008','PR007','PR025','PR027','PR080',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('2007','PR003','PR030','PR021','PR0025','PR013','PR015','PR002','PR006','PR017','PR019','PR020','PR009',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('2008','PR009',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('2009','PR008','PR024','PR023','PR022','PR021','PR020','PR019','PR012','PR017','PR002','PR015','PR014','PR013','PR005','PR011','PR010','PR009','PR008','PR007','PR06'),
('2010','PR016','PR011','PR027','PR017','PR021','PR016','PR019',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);


##### TABLE STUDENT_PROJECT_MAPPING #####
insert into Student_Project_Mapping (student_id, project_id, prefAllocated) values
('2001','PR004',1),
('2002','PR005',1),
('2003','PR011',3),
('2004','PR012',1),
('2005','PR018',1),
('2006','PR008',1),
('2007','PR003',1),
('2008','PR027',0),
('2009','PR024',2),
('2010','PR016',1);

##### TABLE STUDENT_SATISFACTION #####
insert into Student_Satisfaction(student_id,satisfaction_score) values
('2001','100'),
('2002',100),
('2003',90),
('2004',100),
('2005',100),
('2006',100),
('2007',100),
('2008',0),
('2009',95),
('2010',100);

##############################################################################################
################################## CREATE VIEWS ##############################################
#### VIEW 1:Create a view of professors in case students want to know the supervisors of the project
CREATE VIEW Supervisor_details
  AS  SELECT 
        supervisor_name, specialisation_streamID, email
    FROM
        Supervisor;
        

#### VIEW 2: Create a view to access students ordered by name in alphabetical order
CREATE VIEW student_grades
  AS  SELECT 
        student_id, student_name, gpa
    FROM
        student ORDER BY student_name;


#### VIEW 3:Create project_view for all the staff proposed projects
CREATE VIEW Project_List AS
    SELECT 
        p.project_id, p.project_title, s.supervisor_name
    FROM
        projects p
            INNER JOIN
        supervisor s ON s.supervisor_id = p.supervisor_id
    WHERE
        p.proposed_studentID IS NULL;
        

#### VIEW 4:Projects for CS Students Only
CREATE VIEW CS_Projects AS
    SELECT 
        project_id, project_title, s.supervisor_name
    FROM
        projects p
            INNER JOIN
        supervisor s ON s.supervisor_id = p.supervisor_id
    WHERE
        p.proposed_studentID IS NULL
            AND p.stream_designator IN ('CS' , 'ALL');


#### VIEW 5:Projects for CS+DS Students only
CREATE VIEW DS_Projects AS
    SELECT 
        project_id, project_title, s.supervisor_name
    FROM
        projects p
            INNER JOIN
        supervisor s ON s.supervisor_id = p.supervisor_id
    WHERE
        p.proposed_studentID IS NULL
            AND p.stream_designator IN ('CS+DS' , 'ALL');



##############################################################################################
################################ QUERIES #####################################################
    
#### QUERY 1 :Find the number of students in each stream
SELECT 
    s2.stream_description, COUNT(*) as total_students
FROM
    student s1, stream s2
    where s1.stream_id =s2.stream_id
GROUP BY s1.stream_id;


#### QUERY 2 :Find top three students can be done through Union also
SELECT 
    student_name, gpa
FROM
    student_grades  a
WHERE
    3 >= (SELECT 
            COUNT(gpa)
        FROM
            student_grades  b
        WHERE
            a.gpa <= b.gpa)
ORDER BY gpa DESC;

#### QUERY 3 : List all the students in the system which got their first preferences
SELECT 
    student_name, gpa AS grades
FROM
    student
WHERE
    student_id IN (SELECT 
            student_id
        FROM
            student_project_mapping
        WHERE
            prefAllocated = 1) order by grades desc;

#### QUERY 4 :Write a query to check if the student who got the project they proposed
select  s.student_id, s.student_name , sp.project_id as alloted_project,
p.proposed_studentID, p.project_id as proposed_project
from Student_Project_Mapping sp
inner join student s on s.student_id =sp.student_id
inner join projects p on p.project_id =sp.project_id
where p.proposed_studentID is not null;


#### QUERY 5 : Display the number of projects assigned to each of the supervisor
select s.supervisor_id, s.supervisor_name, p.project_count
from supervisor s join 
(select count(1) as project_count,supervisor_id from projects 
group by supervisor_id
 ) p on s.supervisor_id=p.supervisor_id;  

#### QUERY 6 : List all the students which were assigned projects not aligned with their stream
select s.student_name, (CASE s.stream_id when 'CS01' then 'CS' when 'DS01' then 'CS+DS'  END) AS student_stream, p.project_title, p.stream_designator as project_stream
from  student_project_mapping sp
inner join student s on sp.student_id =s.student_id
inner join projects p on sp.project_id= p.project_id
where  (s.stream_id != (CASE p.stream_designator when 'CS' then 'CS01' when 'CS+DS' then 'DS01'  else 'ALL' END))
 AND p.stream_designator != 'ALL';

#### QUERY 7: List the Top 3 Most Prefered Projects by the students
SELECT p.project_id, p.project_title, p2.preference_count 
FROM projects p inner join 
(SELECT projectID , COUNT(*) as preference_count 
FROM ((SELECT pref1 as projectID FROM Student_Preferences ) UNION ALL
(SELECT pref2 as projectID FROM Student_Preferences) UNION ALL
(SELECT pref3 as projectID FROM Student_Preferences)) p1 GROUP BY projectID
) as p2 on p.project_id=p2.projectID order by p2.preference_count DESC limit 3;


#### QUERY 8 :List the names of students who have tried to cheat the system
#THIS QUERY SHOULD RETURN ZERO RECORDS
SELECT 
    a.student_id,a.pref1,a.pref2, a.pref3,a.pref4,a.pref5,a.pref6,a.pref7,a.pref8,
    a.pref9,a.pref10,a.pref11,a.pref12,a.pref13,a.pref14,a.pref15,a.pref16,
    a.pref17,a.pref18,a.pref19,a.pref20
FROM
    Student_Preferences a,
    Student_Preferences b
WHERE
    a.student_id = b.student_id
        AND ((a.pref1 IN (b.pref2 , b.pref3,
        b.pref4,
        b.pref5,
        b.pref6,
        b.pref7,
        b.pref8,
        b.pref9,
        b.pref10,
        b.pref11,
        b.pref12,
        b.pref13,
        b.pref14,
        b.pref15,
        b.pref16,
        b.pref17,
        b.pref18,
        b.pref19,
        b.pref20))
        OR (a.pref2 IN (b.pref1 , b.pref3,
        b.pref4,
        b.pref4,
        b.pref5,
        b.pref6,
        b.pref7,
        b.pref8,
        b.pref9,
        b.pref10,
        b.pref11,
        b.pref12,
        b.pref13,
        b.pref14,
        b.pref15,
        b.pref16,
        b.pref17,
        b.pref18,
        b.pref19,
        b.pref20))
        OR (a.pref3 IN (b.pref1 , b.pref2,
        b.pref4,
        b.pref5,
        b.pref6,
        b.pref7,
        b.pref8,
        b.pref9,
        b.pref10,
        b.pref11,
        b.pref12,
        b.pref13,
        b.pref14,
        b.pref15,
        b.pref16,
        b.pref17,
        b.pref18,
        b.pref19,
        b.pref20))
        OR (a.pref4 IN (b.pref1 , b.pref2,
        b.pref3,
        b.pref5,
        b.pref6,
        b.pref7,
        b.pref8,
        b.pref9,
        b.pref10,
        b.pref11,
        b.pref12,
        b.pref13,
        b.pref14,
        b.pref15,
        b.pref16,
        b.pref17,
        b.pref18,
        b.pref19,
        b.pref20))
        OR (a.pref5 IN (b.pref1 , b.pref2,
        b.pref3,
        b.pref4,
        b.pref6,
        b.pref7,
        b.pref8,
        b.pref9,
        b.pref10,
        b.pref11,
        b.pref12,
        b.pref13,
        b.pref14,
        b.pref15,
        b.pref16,
        b.pref17,
        b.pref18,
        b.pref19,
        b.pref20))
        OR (a.pref6 IN (b.pref1 , b.pref2,
        b.pref3,
        b.pref4,
        b.pref5,
        b.pref7,
        b.pref8,
        b.pref9,
        b.pref10,
        b.pref11,
        b.pref12,
        b.pref13,
        b.pref14,
        b.pref15,
        b.pref16,
        b.pref17,
        b.pref18,
        b.pref19,
        b.pref20))
        OR (a.pref7 IN (b.pref1 , b.pref2,
        b.pref3,
        b.pref4,
        b.pref5,
        b.pref6,
        b.pref8,
        b.pref9,
        b.pref10,
        b.pref11,
        b.pref12,
        b.pref13,
        b.pref14,
        b.pref15,
        b.pref16,
        b.pref17,
        b.pref18,
        b.pref19,
        b.pref20))
        OR (a.pref8 IN (b.pref1 , b.pref2,
        b.pref3,
        b.pref4,
        b.pref4,
        b.pref5,
        b.pref6,
        b.pref7,
        b.pref9,
        b.pref10,
        b.pref11,
        b.pref12,
        b.pref13,
        b.pref14,
        b.pref15,
        b.pref16,
        b.pref17,
        b.pref18,
        b.pref19,
        b.pref20))
        OR (a.pref9 IN (b.pref1 , b.pref2,
        b.pref3,
        b.pref4,
        b.pref4,
        b.pref5,
        b.pref6,
        b.pref7,
        b.pref8,
        b.pref10,
        b.pref11,
        b.pref12,
        b.pref13,
        b.pref14,
        b.pref15,
        b.pref16,
        b.pref17,
        b.pref18,
        b.pref19,
        b.pref20))
        OR (a.pref10 IN (b.pref1 , b.pref2,
        b.pref3,
        b.pref4,
        b.pref4,
        b.pref5,
        b.pref6,
        b.pref7,
        b.pref8,
        b.pref9,
        b.pref11,
        b.pref12,
        b.pref13,
        b.pref14,
        b.pref15,
        b.pref16,
        b.pref17,
        b.pref18,
        b.pref19,
        b.pref20))
        OR (a.pref11 IN (b.pref1 , b.pref2,
        b.pref3,
        b.pref4,
        b.pref5,
        b.pref6,
        b.pref7,
        b.pref8,
        b.pref9,
        b.pref10,
        b.pref12,
        b.pref13, 
        b.pref14,
        b.pref15,
        b.pref16,
        b.pref17,
        b.pref18,
        b.pref19,
        b.pref20))
        OR (a.pref12 IN (b.pref1 , b.pref2,
        b.pref3,
        b.pref4,
        b.pref5,
        b.pref6,
        b.pref7,
        b.pref8,
        b.pref9,
        b.pref10,
        b.pref11,
        b.pref13,
        b.pref14,
        b.pref15,
        b.pref16,
        b.pref17,
        b.pref18,
        b.pref19,
        b.pref20))
        OR (a.pref13 IN (b.pref1 , b.pref2,
        b.pref3,
        b.pref4,
        b.pref5,
        b.pref6,
        b.pref7,
        b.pref8,
        b.pref9,
        b.pref10,
        b.pref11,
        b.pref12,
        b.pref14,
        b.pref15,
        b.pref16,
        b.pref17,
        b.pref18,
        b.pref19,
        b.pref20))
        OR (a.pref14 IN (b.pref1 , b.pref2,
        b.pref3,
        b.pref4,
        b.pref5,
        b.pref6,
        b.pref7,
        b.pref8,
        b.pref9,
        b.pref10,
        b.pref11,
        b.pref12,
        b.pref13,
        b.pref15,
        b.pref16,
        b.pref17,
        b.pref18,
        b.pref19,
        b.pref20))
        OR (a.pref15 IN (b.pref1 , b.pref2,
        b.pref3,
        b.pref4,
        b.pref5,
        b.pref6,
        b.pref7,
        b.pref8,
        b.pref9,
        b.pref10,
        b.pref11,
        b.pref12,
        b.pref13,
        b.pref14,
        b.pref16,
        b.pref17,
        b.pref18,
        b.pref19,
        b.pref20))
        OR (a.pref16 IN (b.pref1 , b.pref2,
        b.pref3,
        b.pref4,
        b.pref5,
        b.pref6,
        b.pref7,
        b.pref8,
        b.pref9,
        b.pref10,
        b.pref11,
        b.pref12,
        b.pref13,
        b.pref14,
        b.pref15,
        b.pref17,
        b.pref18,
        b.pref19,
        b.pref20))
        OR (a.pref17 IN (b.pref1 , b.pref2,
        b.pref3,
        b.pref4,
        b.pref5,
        b.pref6,
        b.pref7,
        b.pref8,
        b.pref9,
        b.pref10,
        b.pref11,
        b.pref12,
        b.pref13,
        b.pref14,
        b.pref15,
        b.pref16,
        b.pref18,
        b.pref19,
        b.pref20))
        OR (a.pref18 IN (b.pref1 , b.pref2,
        b.pref3,
        b.pref4,
        b.pref5,
        b.pref6,
        b.pref7,
        b.pref8,
        b.pref9,
        b.pref10,
        b.pref11,
        b.pref12,
        b.pref13,
        b.pref14,
        b.pref15,
        b.pref16,
        b.pref17,
        b.pref19,
        b.pref20))
        OR (a.pref19 IN (b.pref1 , b.pref2,
        b.pref3,
        b.pref4,
        b.pref5,
        b.pref6,
        b.pref7,
        b.pref8,
        b.pref9,
        b.pref10,
        b.pref11,
        b.pref12,
        b.pref13,
        b.pref14,
        b.pref15,
        b.pref16,
        b.pref17,
        b.pref18,
        b.pref20))
        OR (a.pref20 IN (b.pref1 , b.pref2,
        b.pref3,
        b.pref4,
        b.pref5,
        b.pref6,
        b.pref7,
        b.pref8,
        b.pref9,
        b.pref10,
        b.pref11,
        b.pref12,
        b.pref13,
        b.pref14,
        b.pref15,
        b.pref16,
        b.pref17,
        b.pref18,
        b.pref19)));


