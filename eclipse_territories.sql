CREATE TABLE IF NOT EXISTS `eclipse_territories` (
    `zone` varchar(50) NOT NULL DEFAULT '',
    `control` varchar(50) NOT NULL DEFAULT '',
    `influence` float NOT NULL DEFAULT 0
);

INSERT INTO `territories` (`zone`, `control`, `influence`) VALUES
	('Groove', 'dpls', 100),
	('ForumDrive', 'dpls', 100),
	('Rancho', 'dpls', 100);
