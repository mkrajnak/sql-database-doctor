-- Project: skript pro vytvoreni databaze
-- Authors: xkondu00, xkrajn02

-- smazani puvodnich tabulek

DROP TABLE POJISTOVNA CASCADE CONSTRAINT;
DROP TABLE PACIENT CASCADE CONSTRAINT;
DROP TABLE EXTERNI CASCADE CONSTRAINT;
DROP TABLE VYKON CASCADE CONSTRAINT;
DROP TABLE TERMIN CASCADE CONSTRAINT;
DROP TABLE FAKTURA CASCADE CONSTRAINT;
DROP TABLE LEK CASCADE CONSTRAINT;
DROP TABLE TERMIN_VYKON CASCADE CONSTRAINT;
DROP TABLE TERMIN_LEK CASCADE CONSTRAINT;

--- smazani puvodnich counteru

DROP SEQUENCE extern_seq;
DROP SEQUENCE vykon_seq;
DROP SEQUENCE termin_seq;
DROP SEQUENCE faktura_seq;
DROP SEQUENCE lek_seq;

--- inicializace counteru

CREATE SEQUENCE extern_seq;
CREATE SEQUENCE vykon_seq;
CREATE SEQUENCE termin_seq;
CREATE SEQUENCE faktura_seq;
CREATE SEQUENCE lek_seq;

-- vytvoreni tabulek
CREATE TABLE PACIENT (
	ID_RC			CHAR(10) NOT NULL,
	JMENO			VARCHAR(30) NOT NULL,
	PRIJMENI		VARCHAR(30) NOT NULL,
	ULICE			VARCHAR(50) NOT NULL,
	CISLO_POPISNE	INT NOT NULL,
	MESTO			VARCHAR(30) NOT NULL,
	PSC				CHAR(5) NOT NULL,
	DATUM_NAROZENI	DATE NOT NULL,
	EVIDOVAN_OD		DATE NOT NULL,
	ID_POJISTOVNA	CHAR(3) NOT NULL,
	CHECK( round(ID_RC/11.0) = ID_RC/11.0 )
);

CREATE TABLE POJISTOVNA (
	ID_CP			CHAR(3) NOT NULL,
	JMENO			VARCHAR(50) NOT NULL
);

CREATE TABLE EXTERNI (
	ID_VYSETRENI	INT NOT NULL,
	DATUM 			DATE NOT NULL,
	NAZEV			VARCHAR(50) NOT NULL,
	VYSLEDKY		VARCHAR(1024) NOT NULL,
	ID_PACIENT		CHAR(10) NOT NULL
);

CREATE TABLE VYKON (
	ID_VYKONU		INT NOT NULL,
	NAZEV_VYKONU	VARCHAR(30) NOT NULL,
	EXPIRACE		INT NULL
);

CREATE TABLE TERMIN (
	ID_TERMINU		INT NOT NULL,
	DATUM_CAS 		TIMESTAMP NOT NULL,
	VYKONANE 		CHAR(1) NOT NULL,
	ZPRAVA			VARCHAR(1024) NOT NULL,
	ID_PACIENT		CHAR(10) NOT NULL,
	CHECK (VYKONANE in (0,1))
);

CREATE TABLE LEK (
	ID_LEKU			INT NOT NULL,
	NAZEV			VARCHAR(30) NOT NULL,
	DRUH			VARCHAR(30) NOT NULL,
	POPIS 			VARCHAR(256) NOT NULL
);

CREATE TABLE FAKTURA (
	ID_FAKTURY		INT NOT NULL,
	DATUM 			DATE NOT NULL,
	CENA			INT NULL,
	DOPLATEK		INT NULL,
	ID_TERMINU		INT NOT NULL
);

CREATE TABLE TERMIN_VYKON (
	ID_TERMINU		INT NOT NULL,
	ID_VYKONU		INT NOT NULL
);

CREATE TABLE TERMIN_LEK (
	ID_TERMINU		INT NOT NULL,
	ID_LEKU			INT NOT NULL,
	POCET_BALENI	INT NOT NULL
);
-- -----------------------------------
-- -----------TRIGGERY----------------
-- -----------------------------------
-- rodne cislo
CREATE OR REPLACE TRIGGER RODNE_CISLO
  BEFORE INSERT OR UPDATE OF ID_RC ON PACIENT
  FOR EACH ROW
DECLARE
  RC PACIENT.ID_RC%TYPE;
  FIRST_SIX INTEGER;
  ALL_TEN INTEGER;
  MESIC INTEGER;
  DATE_CHECH DATE;
BEGIN
  RC:= :NEW.ID_RC;
  FIRST_SIX:= TO_NUMBER(SUBSTR(RC, 1, 6));
  MESIC:= TO_NUMBER(SUBSTR(RC, 3, 2));
  ALL_TEN:= TO_NUMBER(RC); -- FAIL: kdyz nejsou vse cisla
  IF(MESIC > 49) THEN -- pro zeny se odecte 50 na porovnani data
    FIRST_SIX:= FIRST_SIX - 5000;
  END IF;
  DATE_CHECH:= TO_DATE(FIRST_SIX,'YYMMDD'); -- FAIL: kdyz kdyz neni validni datum
  IF(round(RC/11.0) <> RC/11.0) THEN
	  -- FAIL: kdyz neni delitelne 11
    Raise_Application_Error (-20001, 'Rodne cislo neni delitelne 11');
  END IF;
END RODNE_CISLO ;
/
-- AUTOINKREMENTACE ID v tabulce LEK
-- pouze pokud NULL, kdyz zadana tak se pouzije
CREATE OR REPLACE TRIGGER ID_LEKU_INC
  BEFORE INSERT OR UPDATE OF ID_LEKU ON LEK
  FOR EACH ROW
DECLARE
  ID_NEW INTEGER;
BEGIN
  ID_NEW:= :NEW.ID_LEKU;
  IF (ID_NEW is NULL) THEN
     :new.ID_LEKU := lek_seq.nextval;
  END IF;
END ID_LEKU_INC;
/

-- vytvoreni primarnich klicu
ALTER TABLE PACIENT ADD CONSTRAINT PK_PACIENT PRIMARY KEY (ID_RC);
ALTER TABLE POJISTOVNA ADD CONSTRAINT PK_POJISTOVNA PRIMARY KEY (ID_CP);
ALTER TABLE EXTERNI ADD CONSTRAINT PK_EXTERNI PRIMARY KEY (ID_VYSETRENI);
ALTER TABLE VYKON ADD CONSTRAINT PK_VYKON PRIMARY KEY (ID_VYKONU);
ALTER TABLE TERMIN ADD CONSTRAINT PK_TERMIN PRIMARY KEY (ID_TERMINU);
ALTER TABLE LEK ADD CONSTRAINT PK_LEK PRIMARY KEY (ID_LEKU);
ALTER TABLE FAKTURA ADD CONSTRAINT PK_FAKTURA PRIMARY KEY (ID_FAKTURY);

-- zarizeni unikatnich hodnot
ALTER TABLE TERMIN ADD CONSTRAINT UQ_DATUM_TERMINU UNIQUE (DATUM_CAS);

-- pridani cizich klicu 1:N
ALTER TABLE PACIENT ADD CONSTRAINT FK_POJISTOVNA_PACIENT FOREIGN KEY (ID_POJISTOVNA) REFERENCES POJISTOVNA(ID_CP);
ALTER TABLE EXTERNI ADD CONSTRAINT FK_PACIENT_EXTERNI FOREIGN KEY (ID_PACIENT) REFERENCES PACIENT;
ALTER TABLE TERMIN ADD CONSTRAINT FK_PACIENT_TERMIN  FOREIGN KEY (ID_PACIENT) REFERENCES PACIENT;
ALTER TABLE FAKTURA ADD CONSTRAINT FK_TERMIN_FAKTURA FOREIGN KEY (ID_TERMINU) REFERENCES TERMIN;

-- pridani cizich klicu N:M
ALTER TABLE TERMIN_VYKON ADD CONSTRAINT FK_TERMIN_VYKON FOREIGN KEY (ID_TERMINU) REFERENCES TERMIN;
ALTER TABLE TERMIN_VYKON ADD CONSTRAINT FK_VYKON_TERMIN FOREIGN KEY (ID_VYKONU) REFERENCES VYKON;
--
ALTER TABLE TERMIN_LEK ADD CONSTRAINT FK_LEK_TERMIN FOREIGN KEY (ID_LEKU) REFERENCES LEK;
ALTER TABLE TERMIN_LEK ADD CONSTRAINT FK_TERMIN_LEK FOREIGN KEY (ID_TERMINU) REFERENCES TERMIN;

-- vkladani zaznamu do tabulek
INSERT INTO POJISTOVNA VALUES('111','Všeobecná zdravotní pojišťovna ČR');
INSERT INTO POJISTOVNA VALUES('201','Vojenská zdravotní pojišťovna');
INSERT INTO POJISTOVNA VALUES('205','Česká průmyslová zdravotní pojišťovna');
INSERT INTO POJISTOVNA VALUES('207','Oborová zdravotní poj. zam. bank, poj. a stav.');
INSERT INTO POJISTOVNA VALUES('209','Zaměstnanecká pojišťovna Škoda');
INSERT INTO POJISTOVNA VALUES('211','Zdravotní pojišťovna ministerstva vnitra ČR');
INSERT INTO POJISTOVNA VALUES('213','Revírní bratrská pokladna, zdrav. pojišťovna');

INSERT INTO PACIENT VALUES ('8811050622', 'John', 'Doe', 'Kolejní', 9, 'Brno', '61205', TO_DATE('05111998','DD-MM-YYYY'), TO_DATE('05052001','DD-MM-YYYY'),'111');
INSERT INTO PACIENT VALUES ('8811090629', 'Will', 'Smith', 'Palackého', 12, 'Praha', '61342',TO_DATE('09111998','DD-MM-YYYY'),TO_DATE('09022002','DD-MM-YYYY'),'201');
INSERT INTO PACIENT VALUES ('8860030619', 'Jane', 'Doe', 'Kolejní', 9, 'Brno', '61205', TO_DATE('03101998','DD-MM-YYYY'), TO_DATE('10052001','DD-MM-YYYY'),'111');
INSERT INTO PACIENT VALUES ('8660030621', 'Marge', 'Smith', 'Palackého', 12, 'Praha', '61342',TO_DATE('03101986','DD-MM-YYYY'),TO_DATE('09022002','DD-MM-YYYY'),'211');

INSERT INTO EXTERNI VALUES(extern_seq.nextval, SYSDATE, 'Oční vyšetrení' ,'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.','8811050622' );
INSERT INTO EXTERNI VALUES(extern_seq.nextval, SYSDATE, 'Röntgen' ,'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.','8811090629' );
INSERT INTO EXTERNI VALUES(extern_seq.nextval, SYSDATE, 'Počítačová tomografie' ,'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.','8811050622' );
INSERT INTO EXTERNI VALUES(extern_seq.nextval, SYSDATE, 'Odběr plazmy' ,'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.','8660030621' );

INSERT INTO VYKON VALUES(vykon_seq.nextval, 'Očkování', 365);
INSERT INTO VYKON VALUES(vykon_seq.nextval, 'Prohlídka', 365);
INSERT INTO VYKON VALUES(vykon_seq.nextval, 'Odběr krve', 182);
INSERT INTO VYKON VALUES(vykon_seq.nextval, 'Předpis léku', NULL );

INSERT INTO TERMIN VALUES(termin_seq.nextval, TIMESTAMP '2016-04-01 09:00:00', 1, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.','8811050622');
INSERT INTO TERMIN VALUES(termin_seq.nextval, TIMESTAMP '2016-04-01 10:00:00', 1, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.','8660030621');
INSERT INTO TERMIN VALUES(termin_seq.nextval, TIMESTAMP '2016-04-02 07:00:00', 1, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.','8860030619');
INSERT INTO TERMIN VALUES(termin_seq.nextval, TIMESTAMP '2016-04-02 08:00:00', 1, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.','8660030621');
INSERT INTO TERMIN VALUES(termin_seq.nextval, TIMESTAMP '2016-04-02 09:00:00', 1, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.','8811090629');
INSERT INTO TERMIN VALUES(termin_seq.nextval, TIMESTAMP '2016-04-02 09:30:00', 1, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.','8811090629');
INSERT INTO TERMIN VALUES(termin_seq.nextval, TIMESTAMP '2016-04-02 10:00:00', 0, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.','8860030619');
INSERT INTO TERMIN VALUES(termin_seq.nextval, TIMESTAMP '2016-04-03 10:00:00', 0, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.','8660030621');
INSERT INTO TERMIN VALUES(termin_seq.nextval, TIMESTAMP '2016-04-04 09:00:00', 0, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.','8860030619');


INSERT INTO LEK VALUES(lek_seq.nextval, 'ASPIRIN PROTECT 100','Analgetikum', 'tbl flm 4x2,5 mg');
INSERT INTO LEK VALUES(lek_seq.nextval, 'UNASYN','Antibiotikum', 'tbl obd 12x375 mg');
INSERT INTO LEK VALUES(lek_seq.nextval, 'Avandamet','Antidiabetikum', 'tbl flm 112 (4 mg/1000 mg)');
INSERT INTO LEK VALUES(lek_seq.nextval, 'Dietetické potraviny','APROMIX','1x1000 g');
INSERT INTO LEK VALUES(lek_seq.nextval, 'KLACID 500','Antibiotikum', 'tbl flm 14x500 mg');
INSERT INTO LEK VALUES(lek_seq.nextval, 'OSPEN 1000','Antibiotikum', 'tbl obd 12x375 mg');
INSERT INTO LEK VALUES(lek_seq.nextval, 'LEKOPTIN','Gynekologiká ', 'tbl flm 112 (4 mg/1000 mg)');
-- test triggeru
INSERT INTO LEK VALUES(NULL, 'FRAMYKOIN','Antibiotikum','1x1000 g');

INSERT INTO FAKTURA VALUES(faktura_seq.nextval, TO_DATE('01042016','DD-MM-YYYY'), 800, 0, 1);
INSERT INTO FAKTURA VALUES(faktura_seq.nextval, TO_DATE('02042016','DD-MM-YYYY'), 600, 300, 2);
INSERT INTO FAKTURA VALUES(faktura_seq.nextval, TO_DATE('02042016','DD-MM-YYYY'), 200, 0, 3);
INSERT INTO FAKTURA VALUES(faktura_seq.nextval, TO_DATE('02042016','DD-MM-YYYY'), 1000, 150, 4);
INSERT INTO FAKTURA VALUES(faktura_seq.nextval, TO_DATE('02042016','DD-MM-YYYY'), 900, 0, 5);
INSERT INTO FAKTURA VALUES(faktura_seq.nextval, TO_DATE('03042016','DD-MM-YYYY'), 600, 300, 6);
INSERT INTO FAKTURA VALUES(faktura_seq.nextval, TO_DATE('03042016','DD-MM-YYYY'), 400, 300, 7);
INSERT INTO FAKTURA VALUES(faktura_seq.nextval, TO_DATE('04042016','DD-MM-YYYY'), 1000, 150, 8);
INSERT INTO FAKTURA VALUES(faktura_seq.nextval, TO_DATE('04042016','DD-MM-YYYY'), 1000, 150, 9);

INSERT INTO TERMIN_VYKON VALUES(1,3);
INSERT INTO TERMIN_VYKON VALUES(2,1);
INSERT INTO TERMIN_VYKON VALUES(3,4);
INSERT INTO TERMIN_VYKON VALUES(4,2);
INSERT INTO TERMIN_VYKON VALUES(5,3);
INSERT INTO TERMIN_VYKON VALUES(6,1);
INSERT INTO TERMIN_VYKON VALUES(7,4);
INSERT INTO TERMIN_VYKON VALUES(8,2);
INSERT INTO TERMIN_VYKON VALUES(9,3);

INSERT INTO TERMIN_LEK VALUES(1,3,1);
INSERT INTO TERMIN_LEK VALUES(2,4,2);
INSERT INTO TERMIN_LEK VALUES(3,2,4);
INSERT INTO TERMIN_LEK VALUES(5,4,2);
INSERT INTO TERMIN_LEK VALUES(6,2,4);
INSERT INTO TERMIN_LEK VALUES(7,3,1);
INSERT INTO TERMIN_LEK VALUES(8,4,2);
INSERT INTO TERMIN_LEK VALUES(9,2,4);

-- potvrzeni zmen
COMMIT;

-- vypis tabulek
SELECT * FROM POJISTOVNA;
SELECT * FROM PACIENT;
SELECT * FROM EXTERNI;
SELECT * FROM VYKON;
SELECT * FROM TERMIN;
SELECT * FROM FAKTURA;
SELECT * FROM LEK;
SELECT * FROM TERMIN_VYKON;
SELECT * FROM TERMIN_LEK;


-- vypis poctu navstev jednotlivych pacientu
SELECT p.jmeno AS "Jméno", p.prijmeni AS "Příjmení", COUNT(n.id_pacient) navstevy
FROM PACIENT P LEFT JOIN termin n ON n.id_pacient = p.id_rc
GROUP BY p.jmeno, p.prijmeni
ORDER BY navstevy DESC;

-- vypis pacientu kterym byli predepsany 2 a vice baleni antibiotik
SELECT p.jmeno AS "Jméno", p.prijmeni AS "Příjmení", l.pocet_baleni AS "Počet balení"
FROM PACIENT p JOIN termin n ON n.id_pacient = p.id_rc join TERMIN_LEK l on l.id_terminu = n.id_terminu join LEK lek on lek.id_leku = l.id_leku
WHERE (l.pocet_baleni >= 2 AND lek.druh = 'Antibiotikum');

-- vypis pacientu, ktery byli ockovani spolu s datumem ockovani a expiraci
SELECT p.jmeno AS "Jméno", p.prijmeni AS "Příjmení", t.datum_cas AS "Datum a čas", v.expirace AS "Expirace"
FROM PACIENT p JOIN termin t ON t.id_pacient = p.id_rc join TERMIN_VYKON tv on tv.id_terminu = t.id_terminu join vykon v on v.id_vykonu = tv.id_vykonu
WHERE EXISTS (SELECT * FROM VYKON WHERE v.NAZEV_VYKONU LIKE 'Očkování');

-- vypise lek ktereho se predepsalo nejvice krabicek
SELECT lek.nazev AS "Název léku" , SUM(pocet_baleni) AS Pocet_baleni
FROM PACIENT p, TERMIN n, TERMIN_LEK tl, LEK lek
WHERE n.id_pacient = p.id_rc AND n.id_terminu = tl.id_terminu AND tl.id_leku = lek.id_leku
GROUP BY lek.nazev
HAVING SUM(pocet_baleni) >= ALL
  (   SELECT SUM(pocet_baleni) AS hypochonder
      FROM PACIENT p, TERMIN n, TERMIN_LEK tl, LEK lek
      WHERE n.id_pacient = p.id_rc AND n.id_terminu = tl.id_terminu AND tl.id_leku = lek.id_leku
      GROUP BY lek.nazev
  );

-- vypise pacienty narozene v 10 mesici, za ucelem dostaveni na rocni prehlidku
SELECT p.jmeno AS "Jméno", p.prijmeni AS "Příjmení"
FROM PACIENT p
WHERE  EXTRACT (MONTH FROM p.datum_narozeni) = 10;

-- vypis pacientu, ktery za soucasny rok neabsolvovaly prohlidku
SELECT DISTINCT p.jmeno AS "Jméno", p.prijmeni AS "Příjmení"
FROM PACIENT p, TERMIN n, TERMIN_VYKON tv, VYKON v
WHERE n.id_pacient = p.id_rc AND tv.id_vykonu = v.id_vykonu AND tv.id_terminu = n.id_terminu AND EXTRACT(YEAR FROM n.datum_cas) = EXTRACT(YEAR FROM CURRENT_DATE) AND p.id_rc NOT IN
(	SELECT DISTINCT p.id_rc
	FROM PACIENT p, TERMIN n, TERMIN_VYKON tv, VYKON v
	WHERE n.id_pacient = p.id_rc AND tv.id_vykonu = v.id_vykonu AND tv.id_terminu = n.id_terminu AND v.nazev_VYKONU LIKE 'Prohlídka'
);

-- PROJEKT 4
-- -------------------------------------------------------------
-- ------------------EXPLAIN PLAN ------------------------------
-- --------------------INDEX------------------------------------
----------------------------------------------------------------
-- smazat index pokud existuje
-- DROP INDEX INDEX_MESTA;

-- klasicky vypis:
-- pocet pacientu jednotlivych pojistoven v praze
EXPLAIN PLAN SET STATEMENT_ID 'without_index' FOR
SELECT POJ.JMENO, COUNT(PAC.MESTO) FROM POJISTOVNA POJ, PACIENT PAC
WHERE POJ.ID_CP = PAC.ID_POJISTOVNA AND
PAC.MESTO = 'Praha'
GROUP BY POJ.JMENO;

-- vypis defaultniho planu na select
SELECT * FROM TABLE(DBMS_XPLAN.display('plan_table', 'without_index', 'typical'));

-- vytvoreni indexu pro mesta
CREATE INDEX INDEX_MESTA ON PACIENT (MESTO);

-- novy plan s vyuzitim indexu
EXPLAIN PLAN SET STATEMENT_ID 'with_index'FOR
SELECT /* INDEX(PACIENT INDEX_MESTA)*/ POJ.JMENO, COUNT(PAC.MESTO) FROM POJISTOVNA POJ, PACIENT PAC
WHERE POJ.ID_CP = PAC.ID_POJISTOVNA AND
PAC.MESTO = 'Praha'
GROUP BY POJ.JMENO;

-- vypis planu pri uziti indexu
-- sice se zvysil pocet operace ale narocnost novych operaci je nizsi
--   predevsim pro plnejsi tabulky
SELECT * FROM TABLE(DBMS_XPLAN.display('plan_table', 'with_index', 'typical'));

-- -------------------------------------------------------------
-- ------------------UDELENI PRAV-------------------------------
-- -------------------------------------------------------------
GRANT ALL ON POJISTOVNA TO xkrajn02;
GRANT ALL ON PACIENT TO xkrajn02;
GRANT ALL ON EXTERNI TO xkrajn02;
GRANT ALL ON VYKON TO xkrajn02;
GRANT ALL ON TERMIN TO xkrajn02;
GRANT ALL ON FAKTURA TO xkrajn02;
GRANT ALL ON LEK TO xkrajn02;
GRANT ALL ON TERMIN_VYKON TO xkrajn02;
GRANT ALL ON TERMIN_LEK TO xkrajn02;


-- -------------------------------------------------------------
-- -------------MATERIALIZOVANY POHLED -------------------------
-- -------------------------------------------------------------
-- smazani logu pro materializovany pohled
DROP MATERIALIZED VIEW pojistovnaNahled;
-- DROP MATERIALIZED VIEW LOG ON FAKTURA;
-- DROP MATERIALIZED VIEW LOG ON TERMIN;
-- DROP MATERIALIZED VIEW LOG ON PACIENT;

-- vytvoreni logu pro materializovany pohled
CREATE MATERIALIZED VIEW LOG ON PACIENT
   WITH ROWID, SEQUENCE (ID_RC)
   INCLUDING NEW VALUES;
CREATE MATERIALIZED VIEW LOG ON TERMIN
   WITH ROWID, SEQUENCE (ID_TERMINU)
   INCLUDING NEW VALUES;
CREATE MATERIALIZED VIEW LOG ON FAKTURA
   WITH ROWID, SEQUENCE (ID_FAKTURY)
   INCLUDING NEW VALUES;

-- ucel materializovaneho pohledu:
--     Vseobecna zdravotni pojistovna (pro nas uzivatel: xkrajn02) ma prehled o
--     vsech fakturach na svoje klienty vystavene v nasi ordinaci.
--     Pohled se zmeni pri kazdem commitu (tzn. po pridani faktury)
CREATE MATERIALIZED VIEW pojistovnaNahled
   LOGGING
   CACHE
   BUILD IMMEDIATE
   REFRESH ON COMMIT
   ENABLE QUERY REWRITE
AS
SELECT
   P.ID_RC AS "Rodne cislo",
	 P.JMENO, P.PRIJMENI,
   F.ID_FAKTURY AS "ID Faktury",
   F.DATUM , F.CENA, F.DOPLATEK
FROM  PACIENT P, FAKTURA F, TERMIN T
WHERE
   P.ID_RC = T.ID_PACIENT AND
   F.ID_TERMINU = T.ID_TERMINU AND
   P.ID_POJISTOVNA = '111';

-- pridani prav uzivateli xkrajn02 (pojistovne)
-- uzivatel xkrajn02 pristupuje k pohledu:
--    SELECT * FROM xkondu00.pojistovnaNahled;
GRANT ALL ON pojistovnaNahled to XKRAJN02;
-- vypis materializovaneho pohledu
SELECT * FROM pojistovnaNahled;
-- pridani nove faktury
INSERT INTO FAKTURA VALUES(faktura_seq.nextval, TO_DATE('08082016','DD-MM-YYYY'), 500, 200, 9);
COMMIT;
-- znovu vypis materializovaneho pohledu, mel by byt pridan zaznam
SELECT * FROM pojistovnaNahled;
-- -------------------------------------------------------------
-- ------------------PROCEDURY----------------------------------
-- -------------------------------------------------------------
-- ucelom procedury je vykonanie rocneho zuctovania cien a doplatkov za vysetrenia
-- parametrami procedury su cislo pojistovne a rok
SET serveroutput ON;
CREATE OR REPLACE PROCEDURE rocniZuctovani(cislo_pojistovny IN VARCHAR2, rok in VARCHAR2 )
is
  cursor zaznam is
    SELECt *
    FROM POJISTOVNA JOIN PACIENT ON POJISTOVNA.ID_CP = pacient.id_pojistovna
      JOIN TERMIN  ON PACIENT.ID_RC = TERMIN.ID_PACIENT
      JOIN FAKTURA ON TERMIN.ID_TERMINU = FAKTURA.ID_TERMINU
      WHERE cislo_pojistovny = POJISTOVNA.ID_CP AND
        EXTRACT (YEAR FROM TERMIN.DATUM_CAS) = rok;
    p_zaznam zaznam%ROWTYPE;
    rocni_doplatky NUMBER;
    rocni_ceny NUMBER;
    jmeno_pojistovny POJISTOVNA.JMENO%TYPE;
BEGIN
  SELECT JMENO INTO jmeno_pojistovny FROM POJISTOVNA WHERE ID_CP = cislo_pojistovny;
  rocni_doplatky := 0;
  rocni_ceny := 0;
  OPEN zaznam;
  LOOP
    FETCH ZAZNAM INTO P_ZAZNAM;
    EXIT WHEN zaznam%NOTFOUND;
    rocni_doplatky := rocni_doplatky + P_ZAZNAM.DOPLATEK;
    rocni_ceny := rocni_ceny + P_ZAZNAM.CENA;
  END LOOP;
  CLOSE zaznam;
  dbms_output.put_line('Pojistovna: '|| jmeno_pojistovny || '.');
  dbms_output.put_line('Cena vysetreni pro rok ' || rok || ' je ' || rocni_ceny || '.');
  dbms_output.put_line('Doplatek za vysetreni pro rok ' || rok || ' je ' || rocni_doplatky || '.');
EXCEPTION
	  WHEN NO_DATA_FOUND THEN --neexistujuce id poistovne
	    dbms_output.put_line('Zaznam pre ' || cislo_pojistovny || ' neexistuje!');
	  WHEN OTHERS THEN
	    Raise_Application_Error (-20206, 'Error!');
END;
/
-- demonstracia procedury
GRANT EXECUTE ON rocniZuctovani TO xkrajn02;
exec rocniZuctovani('111','2016');

-----------------------------PROCEDURA 2---------------------------------------
-- parametrom je druh lieku, procedura vypise vykony ku ktorym bol liek predpisanych
-- a spocita ake % zastupenie ma tato skupina medzi vsetkymi predpisanymi liekmi
SET serveroutput ON;
CREATE OR REPLACE PROCEDURE analyzaDruhuLeku(druh_leku IN VARCHAR2)
is
  cursor zaznam is
    SELECt * FROM LEK JOIN TERMIN_LEK ON LEK.id_leku = TERMIN_LEK.id_leku
      JOIN TERMIN_VYKON ON TERMIN_LEK.id_terminu = TERMIN_VYKON.id_terminu
      JOIN VYKON ON TERMIN_VYKON.id_vykonu = VYKON.id_vykonu;
    p_zaznam zaznam%ROWTYPE;
    leky NUMBER;
    druh NUMBER;
    jmeno_vykonu VYKON.NAZEV_VYKONU%TYPE;
BEGIN
  leky := 0;
  druh := 0;
  dbms_output.put_line('Lieky zo skupiny: ' || druh_leku || ' boli predpisane pre vykony:');
  OPEN zaznam;
  LOOP
    FETCH ZAZNAM INTO P_ZAZNAM;
    EXIT WHEN zaznam%NOTFOUND;
    IF (p_zaznam.druh = druh_leku) THEN --cielova skupina
      SELECT nazev_vykonu INTO jmeno_vykonu FROM VYKON WHERE P_ZAZNAM.nazev_vykonu = VYKON.nazev_vykonu;
      dbms_output.put_line(jmeno_vykonu);
      druh := druh + 1;
    END IF;
    leky := leky + 1;
  END LOOP;
  CLOSE zaznam;
  dbms_output.put_line('Lieky zo skupiny: ' || druh_leku || ' tvoria v databaze ' || (druh * 100)/leky || '% predpisanych liekov.');
EXCEPTION
    WHEN ZERO_DIVIDE THEN
      dbms_output.put_line('Lieky zo skupiny: ' || druh_leku || ' tvoria v databaze 0 % predpisanych liekov.');
	  WHEN OTHERS THEN
	    Raise_Application_Error (-20206, 'Error!');
END;
/
-- demostracia procedury
GRANT EXECUTE ON analyzaDruhuLeku TO xkrajn02;
exec analyzaDruhuLeku('Antibiotikum');
-------------------------------------------------------------------------------
