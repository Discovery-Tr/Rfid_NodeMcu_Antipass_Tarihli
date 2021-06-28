
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for Cards
-- ----------------------------
DROP TABLE IF EXISTS `Cards`;
CREATE TABLE `Cards`  (
  `id` bigint(50) UNSIGNED NOT NULL AUTO_INCREMENT,
  `CardId` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `Name` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `Surname` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `Phone` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `Active` int(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Compact;

-- ----------------------------
-- Table structure for Logs
-- ----------------------------
DROP TABLE IF EXISTS `Logs`;
CREATE TABLE `Logs`  (
  `Id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `Name` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `CardId` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `Date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `Sure` time NULL DEFAULT NULL,
  `Route` int(10) NOT NULL DEFAULT 0 COMMENT '0 - Giriş, 1 - Çıkış',
  `Status` int(1) NULL DEFAULT NULL COMMENT '0 - Hatali, 1 - Doğru',
  PRIMARY KEY (`Id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 53 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Compact;

-- ----------------------------
-- Table structure for Settings
-- ----------------------------
DROP TABLE IF EXISTS `Settings`;
CREATE TABLE `Settings`  (
  `Item` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `Value` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  PRIMARY KEY (`Item`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Compact;

-- ----------------------------
-- Procedure structure for CheckCard
-- ----------------------------
DROP PROCEDURE IF EXISTS `CheckCard`;
delimiter ;;
CREATE PROCEDURE `CheckCard`(IN `crd` varchar(40),IN `rou` int)
BEGIN
	DECLARE rtr INTEGER;
	DECLARE antiPass VARCHAR(50);
  DECLARE lastRoute INTEGER;
	DECLARE logCount INTEGER;
	DECLARE n VARCHAR(200);
	DECLARE lastDate TIMESTAMP;
	DECLARE suAn TIMESTAMP;
	DECLARE fark TIME;
	
	SET suAn = (SELECT NOW());

	SELECT COUNT(*) INTO rtr FROM Cards WHERE CardId = crd AND Active = 1;
	
	IF rtr > 0 THEN
		SELECT CONCAT(`Name`,' ',`Surname`) INTO n FROM Cards WHERE CardId = crd;

		SELECT `Value` INTO antiPass FROM Settings WHERE Item = 'AntiPass';
			IF AntiPass = '1' THEN
				SET lastRoute = (SELECT `Route` FROM `Logs` WHERE CardId = crd AND `Status` = 1 ORDER BY Id DESC LIMIT 1);
				SET logCount = (SELECT COUNT(*) FROM `Logs` WHERE CardId = crd AND `Status` = 1 ORDER BY Id DESC LIMIT 1);
				IF logCount = 0 THEN
					INSERT INTO Logs (`Name`, CardId, Date, Route, `Status`) VALUES (n, crd, suAn, rou, rtr);
					SELECT n AS `Name`;
				ELSEIF rou = lastRoute THEN
					INSERT INTO Logs (`Name`, CardId, Date, Route, `Status`) VALUES (CONCAT(n,' - AntiPass'), crd, suAn, rou, 0);
					SELECT '0' AS `Name`;
				ELSE
				IF rou = '1' THEN 
				  SET lastDate = (SELECT Date FROM `Logs` WHERE CardId = crd AND `Status` = 1 AND Route = 0 ORDER BY Id DESC LIMIT 1); 
					SET fark = SEC_TO_TIME(UNIX_TIMESTAMP(suAn) - UNIX_TIMESTAMP(lastDate));
					INSERT INTO Logs (`Name`, CardId, Date, Sure, Route, `Status`) VALUES (n, crd, suAn, fark, rou, rtr);
					SELECT CONCAT(n,'|',fark) AS `Name`;
				ELSE
					INSERT INTO Logs (`Name`, CardId, Date, Route, `Status`) VALUES (n, crd, suAn, rou, rtr);
					SELECT n AS `Name`;
			  END IF;
					
				END IF;
			ELSE
					INSERT INTO Logs (`Name`, CardId, Date, Route, `Status`) VALUES (n, crd, suAn, rou, rtr);
					SELECT n AS `Name`;
			END IF;
	ELSE
		INSERT INTO Logs (`Name`, CardId, Date, Route, `Status`) VALUES ('Tanımsız Kart', crd, suAn, rou, rtr);
		SELECT '0' AS `Name`;
	END IF;
END
;;
delimiter ;

SET FOREIGN_KEY_CHECKS = 1;
