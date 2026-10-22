LOCAL nOldWA
LOCAL xId_Testa
LOCAL xIdCol 
LOCAL xField
LOCAL xTemp

PUBLIC xCd_Aliquote(9)
PUBLIC xDesAliquote(9)

LOCAL xInfoDoc

xInfoDoc = "'D.D.T. ' + Alltrim(xDoTes.Cd_Do) + ' ' + Alltrim(xDoTes.NumeroDoc) + ' del ' + Dtoc(xDoTes.DataDoc)"

** Questa procedura ricrea il cursore DoRigAll dopo averlo analizzato per calcolare
** il castelletto IVA di ogni singolo documento prelevato
** 								4%			5%			10%			22%
**	D.D.T. nr ..del ..		10,50		99.25		 0,00		112.21
**	D.D.T. nr ..del ..		 0,50		69.18		55,00		327.46
**
** Le colonne sono impostate in 
**		xCd_Aliquote()	(Codici IVA)
**		xDesAliquote()	(Descrizioni IVA)
**
** I dati dei castelletti (Matrice aliquote) sono memorizzati nel cursore xTotIVA 
** ( un record per ogni testata )
** Le aliquote non definite in xAliquote vengono sommate nella colonna 0 (Varie/Altro) 

nOldWA = SELECT(0)
CREATE CURSOR xTotIVA (Id_DoTes N(10), Tot0 B(8), Tot1 B(8), Tot2 B(8), Tot3 B(8), Tot4 B(8), Tot5 B(8), Tot6 B(8), Tot7 B(8), Tot8 B(8), Tot9 B(8))
INDEX ON Id_DoTes TAG Testa 

&& Tabella aliquote IVA
xCd_Aliquote(1) ='04'
	xDesAliquote(1) ='4 %'

xCd_Aliquote(2) ='05'
	xDesAliquote(2) ='5 %'

xCd_Aliquote(3) ='10'
	xDesAliquote(3) ='10 %'

xCd_Aliquote(4) ='22'
	xDesAliquote(4) ='22 %'

xCd_Aliquote(5) ='--'
	xDesAliquote(5) =''

xCd_Aliquote(6) ='--'
	xDesAliquote(6) =''

xCd_Aliquote(7) ='--'
	xDesAliquote(7) =''
	
xCd_Aliquote(8) ='--'
	xDesAliquote(8) =''
	
xCd_Aliquote(9) ='--'
	xDesAliquote(9) =''
	
&& Resoconto per Aliquota IVA
SELECT DoRigAll
SCAN
	
	IF !IsEmpty(DoRigAll.Id_DoRig_Evade) AND !EMPTY(DoRigAll.Cd_Aliquota) THEN
		xId_Testa = xGetIdTesta_R(DoRigAll.Id_DoRig_Evade) && Funzione per ottenere ID_Testa in base all'ID_Riga
		IF !IsEmpty(xId_Testa) THEN  && ID Documento prelevato
			&& Individuo la colonna IVA
			xIdCol = ASCAN(xCd_Aliquote, TRIM(Cd_Aliquota)) && Cerca la colonna dell'aliquota (0=Varie)
			xField = 'Tot' + ALLTRIM(STR(xIdCol, 2,0))
			&& Mi posiziono sul record opportuno
			SELECT xTotIVA 
			LOCATE FOR Id_DoTes = xId_Testa
			IF xTotIVA.Id_DoTes = xId_Testa THEN
				REPLACE &xField WITH &xField + DoRigAll.PrezzoTotaleV
				ELSE
				APPEND BLANK
				REPLACE Id_DoTes WITH xId_Testa 
				FOR A = 0 TO 9
					xTemp = 'Tot' + ALLTRIM(STR(A, 2,0))	
					REPLACE &xTemp WITH 0
				NEXT
				REPLACE &xField WITH DoRigAll.PrezzoTotaleV				
			ENDIF			
			
		ENDIF
	ENDIF
	SELECT DoRigAll 
ENDSCAN
SELECT DoRigAll
DELETE From DoRigAll
SELECT xTotIVA
nRiga = 0
SCAN
		TEXT TO sqlStmt TEXTMERGE
			SELECT * FROM DoTes WHERE Id_DoTes = <<Format4Spt(xTotIVA.Id_Dotes)>>
		ENDTEXT
		xDoTes = xSQLExec2Obj(sqlStmt)

		nRiga = nRiga + 1
		SELECT DoRigAll
		APPEND BLANK
		REPLACE Riga 			WITH nRiga
		REPLACE Descrizione		WITH &xInfoDoc 
		REPLACE Id_DoRig_Evade	WITH xTotIVA.Id_Dotes	
		REPLACE TipoRigaRif		WITH 'R'
		SELECT xTotIVA
ENDSCAN

&& Relazione
SET RELATION TO Id_DoRig_Evade INTO xTotIVA IN DoRigAll ADDITIVE

SELECT (nOldWA)