create table Player_Private_Information (
 account_ID VARCHAR(15) NOT NULL PRIMARY KEY,
 CONSTRAINT lengthOfAccountID CHECK (length(account_ID) > 5 and length(account_ID) <= 15),   
 password VARCHAR(20) NOT NULL,
 CONSTRAINT lengthOfPassword  CHECK (length(password) > 10 AND length(password) < 21),  
 dateOfRegitration DATE NOT NULL,
 emailAddress VARCHAR(40) NOT NULL,
 CONSTRAINT chk_email CHECK (emailAddress like '%_@__%.__%'),
 firstName VARCHAR(30) NOT NULL,
 lastName VARCHAR(30) NOT NULL,
 gender CHAR(1) NOT NULL,
 CHECK (gender IN ('M', 'F')), 
 country VARCHAR(20) WITH DEFAULT 'Not_Provided',
 city VARCHAR(20) WITH DEFAULT 'Not_Provided',
 street VARCHAR(20) WITH DEFAULT 'Not_Provided',
 accomodation_Number VARCHAR(15) WITH DEFAULT 'Not_Provided',
 is_Verified_by_email CHAR(1) NOT NULL,
 CHECK (is_Verified_by_email IN ('Y','N')), 
 date_Of_Birth DATE NOT NULL
); 

CREATE TABle Players_Account_In_Game_Information (
 account_ID VARCHAR(15) NOT NULL PRIMARY KEY REFERENCES Player_Private_Information(account_ID),
 kills INT,
 deaths INT,
 assists INT,
 level_of_Account INT WITH DEFAULT 1,
 K_D_rate DECIMAL (5,2),
 numberOfBans INT,
 CONSTRAINT lengthOfNumOfBans CHECK (numberOfBans <= 3), 
 rankPoints int WITH DEFAULT 1000,
 tier_ID INT NOT NULL REFERENCES Tier_Group(tier_ID),
 CONSTRAINT TierOne CHECK (tier_ID = 'Tier1' AND (rankPoints >= 3500)),
 CONSTRAINT TierTwo CHECK (tier_ID = 'Tier2' AND (rankPoints >= 2500 AND rankPoints <= 2999)),
 CONSTRAINT TierThree CHECK (tier_ID = 'Tier3' AND (rankPoints >= 2000 AND rankPoints <= 2499)),
 CONSTRAINT TierFour CHECK (tier_ID = 'Tier4' AND (rankPoints >= 1500 AND rankPoints <= 1999)),
 CONSTRAINT TierFive CHECK (tier_ID = 'Tier5' AND (rankPoints <= 1499))
);


CREATE TABLE Tier_Group (
 tier_ID INT NOT NULL PRIMARY KEY,
 tier_Name varchar (20) NOT NULL,
 CONSTRAINT checkTierName CHECK (tier_Name in ('Tier1','Tier2','Tier3','Tier4','Tier5')),
 min_Rank_Points INT NOT NULL,
 max_Rank_Points INT NOT NULL,
 CONSTRAINT checkRankPoints CHECK (min_Rank_Points <= max_Rank_Points)
);

CREATE TABLE Map_Info (
map_ID INT NOT NULL PRIMARY KEY,
map_Name varchar(20) NOT NULL,
map_Size INT NOT NULL
);

CREATE TABLE Mod_Info (
mod_ID INT NOT NULL PRIMARY KEY,
mod_Name VARCHAR(20) NOT NULL
);

CREATE TABLE Server_Information (
server_ID INT NOT NULL PRIMARY KEY,
name_Of_Server VARCHAR(20) NOT NULL,
k_D_RateMinRequired decimal(5,2) NOT NULL,
k_D_RateMaxRequired DECIMAL(5,2) NOT NULL,
CONSTRAINT checkKDRates CHECK (k_D_RateMaxRequired >= k_D_RateMinRequired),
min_Level_Required int NOT NULL,
max_Level_Required int NOT NULL,
CONSTRAINT checkLevels CHECK (min_Level_Required <= max_Level_Required)
);

CREATE TABLE Room_Information(
room_ID INT NOT NULL PRIMARY KEY,
map_ID INT NOT NULL REFERENCES Map_Info(map_ID), 
server_ID INTEGER NOT NULL REFERENCES Server_Information(server_ID), 
mod_ID INTEGER NOT NULL REFERENCES Mod_Info(mod_ID), 
name_Of_Host VARCHAR(15) NOT NULL REFERENCES Players_Account_In_Game_Information(account_ID),
number_Of_Players INTEGER NOT NULL,
creation_Time TIMESTAMP NOT NULL,
expr_Time TIMESTAMP NOT NULL,
class_Of_Winners CHAR(1) NOT NULL REFERENCES Classes(class_Letter)
);


CREATE TABLE Total_Players_Statistics_In_Room (
 room_ID INT NOT NULL PRIMARY KEY REFERENCES Room_Information(room_ID),
 total_Kills INT,
 total_Deaths INT,
 total_Assists INT
);

CREATE TABLE Particular_Player_Statistics_In_Room (
room_ID INT NOT NULL REFERENCES Room_Information(room_ID),
account_ID VARCHAR(15) NOT NULL REFERENCES Player_Private_Information(account_ID), 
kills INTEGER,
deaths INTEGER,
assists INTEGER,
character_ID INTEGER NOT NULL REFERENCES Class_Characters(character_ID), 
in_Which_class CHAR(1) NOT NULL REFERENCES Classes(class_Letter),
weapon_ID INTEGER NOT NULL REFERENCES Weapons(weapon_ID), 
is_Banned CHAR(1) NOT NULL, 
CONSTRAINT checkBanned CHECK (is_Banned in ('Y','N')),
PRIMARY KEY(room_ID, account_ID)
);


CREATE TABLE Banlist (
account_ID VARCHAR(15) NOT NULL REFERENCES Player_Private_Information(account_ID), 
room_ID INTEGER NOT NULL REFERENCES Room_Information(room_ID), 
ban_Length VARCHAR(25),
reason VARCHAR(100),
start_Date TIMESTAMP,
end_Date TIMESTAMP,
PRIMARY KEY (account_ID, room_ID)
);


CREATE TABLE Classes (
class_Letter CHAR(1) NOT NULL PRIMARY KEY,
class_Name VARCHAR(20) NOT NULL,
color_Of_Map_Icons VARCHAR(20) NOT NULL,
which_Country_For VARCHAR(20) NOT NULL
);

CREATE TABLE Weapons (
weapon_ID INTEGER NOT NULL PRIMARY KEY,
name_Of_Weapon VARCHAR(20) NOT NULL,
weapon_Type VARCHAR(20) NOT NULL,
which_Class_Can_Buy CHAR(1) NOT NULL REFERENCES Classes(class_Letter), 
weight INTEGER NOT NULL,
cartridge INTEGER NOT NULL,
firing_Range INTEGER NOT NULL,
length_Of_Weapon INTEGER NOT NULL,
accuracy INTEGER NOT NULL,
fire_Power INTEGER NOT NULL,
produced_Date DATE NOT NULL
);

CREATE TABLE Class_Characters (
character_ID INTEGER NOT NULL PRIMARY KEY,
which_Class CHAR(1) NOT NULL REFERENCES Classes(class_Letter),
name_Of_character VARCHAR(100),
country_Of_Birth VARCHAR(100),
war_Paint VARCHAR(20)
);


									/*TRIGGERS*/

/*==================================Trigger #1=============================*/
	create or replace trigger dob_trigger /*Date of birthday of player*/
before insert on Player_Private_Information
referencing new as n
for each row
	when (year(n.date_Of_Birth) + 13 >= year(current_date))
		SIGNAL SQLSTATE '75002' SET MESSAGE_TEXT = 'not 13!';
/*=========================================================================*/

/*==================================Trigger #2=============================*/
	CREATE TRIGGER Player_Private_Information /*Length of account ID*/
BEFORE INSERT ON Player_Private_Information 
REFERENCING NEW AS d
FOR EACH ROW
	WHEN (length(d.account_ID) > 15 and length(d.account_ID) < 6)
		SIGNAL SQLSTATE '75001' SET MESSAGE_TEXT = 'Length of accound ID must be between 6-15';
/*=========================================================================*/

/*==================================Trigger #3=============================*/
	CREATE TRIGGER Player_Private_Information /*Length of password*/
BEFORE INSERT ON Player_Private_Information 
REFERENCING NEW AS d
FOR EACH ROW
	WHEN (length(d.password) > 20 AND length(d.password) < 10)
		SIGNAL SQLSTATE '75001' SET MESSAGE_TEXT = 'Password must be between 6-15';	
/*=========================================================================*/

/*==================================Trigger #4=============================*/
CREATE TRIGGER Ban_Info  /*Player can't be inserted more than 4 times*/
BEFORE Insert ON BanList
REFERENCING NEW AS n
FOR EACH ROW
	WHEN( 4 < (SELECT COUNT (*) FROM BanList WHERE account_ID = n.account_ID))
		SIGNAL SQLSTATE '23423' SET MESSAGE_TEXT = 'If person has 3 bans, the last one will be permanent (number of bans cannot be higher 4';
/*=========================================================================*/
		
/*=================================Trigger #5==============================*/
CREATE OR REPLACE TRIGGER Match_Making_System
BEFORE INSERT ON Particular_Player_Statistics_In_Room
REFERENCING NEW AS p
	FOR EACH ROW
		WHEN( 
			 ( 
				(SELECT 
					MAX(level_of_Account) 
						FROM Players_Account_In_Game_Information,Particular_Player_Statistics_In_Room,Server_Information
							WHERE 
								Server_Information.name_Of_Server = 'Rank Server' 
								AND Particular_Player_Statistics_In_Room.room_ID = (select MAX(room_ID) FROM Particular_Player_Statistics_In_Room)) >
				( 5 + (SELECT
						MIN(level_of_Account) 
							FROM Players_Account_In_Game_Information,Particular_Player_Statistics_In_Room, Server_Information
								WHERE 
									Server_Information.name_Of_Server = 'Rank Server' 
									AND Particular_Player_Statistics_In_Room.room_ID = (select MAX(room_ID) from Particular_Player_Statistics_In_Room)))
			 )
			OR
			 (
				(SELECT 
					MAX(rankPoints) 
						FROM Players_Account_In_Game_Information,Particular_Player_Statistics_In_Room, Server_Information
							WHERE 
								Server_Information.name_Of_Server = 'Rank Server'
								AND Particular_Player_Statistics_In_Room.room_ID = (select MAX(room_ID) FROM Particular_Player_Statistics_In_Room)) >
				( 350 + (SELECT
							MIN(rankPoints)
								FROM Players_Account_In_Game_Information,Particular_Player_Statistics_In_Room,Server_Information
									WHERE 
										Server_Information.name_Of_Server = 'Rank Server' 
										AND Particular_Player_Statistics_In_Room.room_ID = (select MAX(room_ID) FROM Particular_Player_Statistics_In_Room)))
			 )
			OR
			 (	
				(SELECT 
					MAX(K_D_rate) 
						FROM Players_Account_In_Game_Information,Particular_Player_Statistics_In_Room, Server_Information
							WHERE
								Server_Information.name_Of_Server = 'Rank Server'
								AND Particular_Player_Statistics_In_Room.room_ID = (select MAX(room_ID) FROM Particular_Player_Statistics_In_Room)) >
				( 0.05 + (SELECT 
							MIN(K_D_rate) 
								FROM Players_Account_In_Game_Information,Particular_Player_Statistics_In_Room, Server_Information
									WHERE 
									Server_Information.name_Of_Server = 'Rank Server'
									AND Particular_Player_Statistics_In_Room.room_ID = (select MAX(room_ID) FROM Particular_Player_Statistics_In_Room)))
			 )
			)
	SIGNAL SQLSTATE '72344' SET MESSAGE_TEXT = 'Big difference between statistics of players on Rank Server is impossible!';
/*=========================================================================*/

/*==================================Trigger #6=============================*/
CREATE TRIGGER Player_Tier_and_Rank_Checking_Information /*Check the right choice of tier group in reference to rank points of player*/
BEFORE UPDATE ON Players_Account_In_Game_Information
REFERENCING NEW AS c
FOR EACH ROW
	WHEN (
			(c.rankPoints >= 3500 AND c.tier_ID <> 'Tier1')
		 OR
			(c.rankPoints >= 2500 AND c.rankPoints <= 2999 AND c.tier_ID <> 'Tier2')
		 OR 
			(c.rankPoints >= 2000 AND c.rankPoints <= 2499 AND c.tier_ID <> 'Tier3')
		 OR 
		    (c.rankPoints >= 1500 AND c.rankPoints <= 1999 AND c.tier_ID <> 'Tier4')
		 OR 
			(c.rankPoints <= 1500 OR c.tier_ID = 'Tier5')
		 )
SIGNAL SQLSTATE '12412' SET MESSAGE_TEXT = 'Disbalance between Tier ID and Rank Points of the player';
/*=========================================================================*/