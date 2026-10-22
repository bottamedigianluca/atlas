*** Extracted Visual FoxPro Source Code from cmd_xexportgastropool.vcx ***

*** CLASS / OBJECT: cmd (BaseClass: form, Parent: ) ***
*** PROPERTIES ***
Top = 0
Left = 1
Height = 360
Width = 475
DoCreate = .T.
Comment = "9D4E2F7C-DBA5-4F9C-94BB-D52135FD9D86"
Caption = "Export Documenti (GASTROPOOL)"
Name = "cmd"
StatusBar.Comment = "0F96C282-B07C-4B60-8266-5F1285F67F68"
StatusBar.Top = 340
StatusBar.Left = 0
StatusBar.Height = 20
StatusBar.Width = 475
StatusBar.Name = "StatusBar"
title_bar.BtnLabel.Name = "BtnLabel"
title_bar.lblLabel.Name = "lblLabel"
title_bar.Comment = "AD1D1BC3-5CA9-4D68-A89A-7F504D2E98FE"
title_bar.Top = 26
title_bar.Width = 475
title_bar.caption = ('Titolo')
title_bar.Name = "title_bar"
timer4ExecAsync.Comment = "4FDB0264-8956-49EE-B98F-CF2C5E9084E5"
timer4ExecAsync.Name = "timer4ExecAsync"
SCMenu.Comment = "23555C86-6556-4F9F-B541-EA406276F871"
SCMenu.Name = "SCMenu"
tbenabler.Comment = "9DA918FF-68C6-45A9-BE67-AA46C6BA3FA4"
tbenabler.Name = "tbenabler"
PF.ErasePage = .T.
PF.PageCount = 3
PF.Pgbase1.Comment = "6047B241-C131-4629-AFBC-0EE0BF1E45E3"
PF.Pgbase1.Caption = "Generale"
PF.Pgbase1.PageOrder = 1
PF.Pgbase1.Name = "pgGenerale"
PF.Pgbase2.Comment = "CB81C782-808E-4FA9-B05E-DC5C17C0C7E4"
PF.Pgbase2.Caption = "Filtri / Opzioni"
PF.Pgbase2.PageOrder = 2
PF.Pgbase2.Name = "pgOpzioni"
PF.Pgbase3.Comment = "99A7A6E4-FB13-4BDF-A97F-1D950FBD1D4D"
PF.Pgbase3.Caption = "Selezione"
PF.Pgbase3.PageOrder = 3
PF.Pgbase3.Name = "pgSelezione"
PF.Comment = "D63490EE-F9C2-4AED-899B-0D59C6D1D08F"
PF.ActivePage = 1
PF.Top = 28
PF.Width = 477
PF.Height = 311
PF.Name = "PF"

*** METHODS ***
PROCEDURE functionondotes
LPARAMETERS nHandle
**	WITH THISFORM.ExportCF
**		.wcOnCF = 'CD_CF = ' + FORMAT4SPT(EVALUATE(THIS.ExportDocumenti.ExportAlias + '.Cd_CF'))
**		.Export(nHandle)
**	ENDWITH
*!*	THISFORM.progBarAdvance(, 'Export Documenti')
RETURN .T.
ENDPROC
PROCEDURE functionondorig
LPARAMETERS nHandle
**	WITH THISFORM.ExportAR
**		IF !IsEMPTY(EVALUATE(THIS.ExportDocumenti.ExportAlias + '.Cd_AR'))
**			.wcOnAR = 'CD_AR = ' + FORMAT4SPT(EVALUATE(THIS.ExportDocumenti.ExportAlias + '.Cd_AR'))
**			.Export(nHandle)
**		ENDIF
**	ENDWITH
RETURN .T.
ENDPROC
PROCEDURE querydot
LPARAMETERS cWhere

IF VARTYPE(cWhere) = 'L'
	cWhere = '1=0'
ENDIF

cWhere = xDefault(cWhere, '1=1')
LOCAL cStmt

TEXT TO cStmt NOSHOW TEXTMERGE
	SELECT
		CONVERT(BIT, 1) AS Selected,
		CF.Descrizione AS CF_Descrizione,
		CF.xCd_Exp AS CF_xCdExp,
		DOTES.*
	FROM DOTES 
		INNER JOIN CF ON DOTES.Cd_CF = CF.Cd_CF
	WHERE <<cWhere>>
		
ENDTEXT

xSqlExec(cStmt, 'DOT')

ENDPROC
PROCEDURE wcgetwhereselection
LPARAMETERS lCheckOnDot
LOCAL cWhere
LOCAL lAll
lAll = .T.
IF lCheckOnDot
	IF SEEK(.F., 'DOT', 'Sel')
		cWhere = ''
		SELECT DOT
		SCAN FOR Selected
			cWhere = cWhere + ', ' + TRANSFORM(ID_DOTES)
		ENDSCAN
		IF !EMPTY(cWhere)
			cWhere = ' DoTes.Id_DoTes IN (' + SUBSTR(cWhere, 3) + ')'
		ENDIF
		lAll = .F.	
	ENDIF	
ENDIF

IF lAll	
	cWhere = THISFORM.PF.wcGetWhere()
	IF !EMPTY(cWhere)
		cWhere = SUBSTR(cWhere, 6)
	ENDIF
ENDIF

_cliptext = cWhere
RETURN cWhere
ENDPROC
PROCEDURE functionondototali
LPARAMETERS nHandle

RETURN .T.
ENDPROC
PROCEDURE functionondoiva
LPARAMETERS nHandle
*!*	THISFORM.progBarAdvance(, 'Export DoIva')
RETURN .T.
ENDPROC
PROCEDURE xgetrighedoc
LPARAMETERS iID_Testa

cWhere = 'dorig.ID_DOTes = ' + STR(iID_Testa)

LOCAL cStmt

&& Estraggo un cursore/dataset con le righe del documento 
&& arricchite con l'eventuale riferimento della testa del 
&& documento prelevato
&& In Dorig c'è solo il riferimento alla riga prelevata (Id_Dorig_Evade)
&& In arca Professional c'erano sia quelli di testa che quelli di riga
&&     (RifFromR e RifFromT)

TEXT TO cStmt NOSHOW TEXTMERGE
	SELECT dorig.* 
	       , dotesevade.id_dotes as id_dotes_Evade
	FROM dorig
	LEFT JOIN dorig dorigevade on dorig.id_dorig_evade = dorigevade.id_dorig
	LEFT JOIN dotes dotesevade on dorigevade.id_dotes = dotesevade.id_dotes
	WHERE <<cWhere>>		
	and ((dorig.Cd_AR is not null) or (doRig.PrezzoUnitarioV <>0))
	ORDER BY dotesevade.id_dotes	
ENDTEXT

xSqlExec(cStmt, 'DOR')

ENDPROC
PROCEDURE xgetinfoprel
LPARAMETERS iID_Testa
LOCAL cStmt

iID_From = iID_Testa
IF ISNULL(iID_From) THEN 
	iID_From = -1
ENDIF        	

&& Via Id_DoTes
cWhere = 'DOTes.ID_DOTes = ' + STR(iID_From)
TEXT TO cStmt NOSHOW TEXTMERGE
	SELECT DOTes.Cd_Do, DOTes.NumeroDoc, DOTes.DataDoc, DOTes.Cd_CF, DOTes.Cd_CFDest
	      , CFDest.xCd_Exp
	      , CFDest.Descrizione As RagioneSoc 
		  , CFDest.Indirizzo
		  , CFDest.Localita
	FROM   DOTes
	   LEFT JOIN CFDest ON DOTes.Cd_CF = CFDest.Cd_CF AND DOTes.Cd_CFDest = CFDest.Cd_CFDest
	WHERE <<cWhere>>		
ENDTEXT

xSqlExec(cStmt, 'INFOPR') && Cursore con N./Data Cliente/Destinazione merce del documento prelevato 

ENDPROC
PROCEDURE xgetcodalt
PARAMETERS cCodice_CF, cCodice_AR
LOCAL cStmt
LOCAL cCodAlt
LOCAL oRec 

cCodAlt = ''
IF !IsEmpty(cCodice_CF) AND !IsEmpty(cCodice_AR) THEN 
	cWhere = "Cd_CF = '" + ALLTRIM(cCodice_CF) + "' AND Cd_AR = '" + ALLTRIM(cCodice_AR) + "'"
	TEXT TO cStmt NOSHOW TEXTMERGE
		SELECT  [CodiceAlternativo]
		FROM    ARCodCF
		WHERE <<cWhere>>		
	ENDTEXT

	oRec = xSqlExec2OBJ(cStmt)

	IF !ISNULL(oRec) AND !ISNULL(oRec.CodiceAlternativo) THEN 
		cCodAlt = oRec.CodiceAlternativo 
	ENDIF
ENDIF

RETURN cCodAlt
ENDPROC
PROCEDURE xgetinfodestft
LPARAMETERS iID_Testa
LOCAL cStmt

imyID = iID_Testa
IF ISNULL(imyID) THEN 
	imyID  = -1
ENDIF        	

&& Via Id_DoTes
cWhere = 'DOTes.ID_DOTes = ' + STR(imyID)
TEXT TO cStmt NOSHOW TEXTMERGE
	SELECT DOTes.Cd_Do, DOTes.NumeroDoc, DOTes.DataDoc, DOTes.Cd_CF, DOTes.Cd_CFDest
	      , CFDest.xCd_Exp
	      , CFDest.Descrizione As RagioneSoc 
		  , CFDest.Indirizzo
		  , CFDest.Localita
	FROM   DOTes
	   INNER JOIN CFDest ON DOTes.Cd_CF = CFDest.Cd_CF AND DOTes.Cd_CFDest = CFDest.Cd_CFDest
	WHERE <<cWhere>>		
ENDTEXT

xSqlExec(cStmt, 'INFODEST') && Cursore con info angrafica destinazione del documento fattura

ENDPROC
PROCEDURE cmdrowsel
LOCAL nRec

nRec = 0

IF !EOF('DOT') AND !BOF('DOT')
	nRec = RECNO('DOT')
ENDIF

REPLACE ALL Selected WITH .T. IN DOT
THISFORM.PF.pgSelezione.Grid.Refresh()
IF nRec > 0
	GO (nRec) IN DOT
ENDIF
ENDPROC
PROCEDURE cmdrowunsel
LOCAL nRec

nRec = 0

IF !EOF('DOT') AND !BOF('DOT')
	nRec = RECNO('DOT')
ENDIF

REPLACE ALL Selected WITH .F. IN DOT
THISFORM.PF.pgSelezione.Grid.Refresh()
IF nRec > 0
	GO (nRec) IN DOT
ENDIF
ENDPROC
PROCEDURE inittoolbar
DODEFAULT()

WITH THISFORM.TOOLBAR
	.BUTTONS('ROWSEL').Enabled		= .T.
	.BUTTONS('ROWUNSEL').Enabled	= .T.
ENDWITH
ENDPROC
PROCEDURE querynavigate
LPARAMETERS nCurActivePage, nNewActivePage

IF !DODEFAULT(nCurActivePage, nNewActivePage)
	RETURN .F.
ENDIF


ENDPROC
PROCEDURE Init
RETURN DODEFAULT()
ENDPROC
PROCEDURE cmdfine
LOCAL iID_Testa, iID_From

LOCAL CodSocio, CodDitta
LOCAL sCodeArti, sCodALT
LOCAL NumRecs, NumTeste
LOCAL RifDocFT, RifDocBO as Character
LOCAL RifFT, RifBO as Character
LOCAL fiHandle
LOCAL fiString
LOCAL TempString
LOCAL TempDate
LOCAL fTop
LOCAL RifTesta
LOCAL PrzScontato, TotScontato
LOCAL TempStr, LenCode

** Range date fattura contenute nel file per Hogast
LOCAL DataMin, DataMax
LOCAL sDataMin, sDataMax, sDataDoc

** Tipo tracciato
LOCAL bNuovoTracciato

&& Castelletto IVA
LOCAL I
LOCAL IDAliq 
LOCAL ARRAY Aliquota [100]
LOCAL ARRAY Totale [100]

** Da fare 
**   - Controllo per note di credito
**   - Fattura immediata (senza prelievo)
	IF THISFORM.pf.pggenerale.chknewformat.Value = .T. THEN 
		bNuovoTracciato = .T.
		iLenRifDDT 		= 20
		sTipoDett  		= '6'
		ELSE
		bNuovoTracciato = .F.
		iLenRifDDT 		= 10
		sTipoDett  		= '3'
	ENDIF

	** Creazione file HoGast
	fiHandle = FCREATE(THISFORM.pf.pggenerale.txtdbfilename.field.Value)
	fTop = FSEEK(fiHandle, 0) && Vai a BOF
	
	
    ** INIT Variabili 
    RecTeste  = 0    
    NumRecs   = 0
    RifBO = 'XX'
    RifFT = 'XX'
    
    && Data Minima/massima delle fatture/note di credito contenute nel file 
	DataMin = CTOD('31/12/2099')
	DataMax = CTOD('01/01/1980')

	SELECT DOT
	SCAN
		IF DOT.DataDoc > DataMax then
			DataMax = DOT.DataDoc
		ENDIF
		IF DOT.DataDoc < DataMin then
			DataMin = DOT.DataDoc
		ENDIF	
	ENDSCAN
	&& 2. Record di tipo 1 (date di fatturazione)
	tmp = DTOC(DataMin)
	sDataMin = LEFT(tmp, 2) + '.' + SUBSTR(tmp, 4,2) + '.' + RIGHT(tmp,4) 
	tmp = DTOC(DataMax)
	sDataMax = LEFT(tmp, 2) + '.' + SUBSTR(tmp, 4,2) + '.' + RIGHT(tmp,4) 
	tempString = '1' + sDataMin + sDataMax
	FWRITE (fiHandle, tempString + CHR(13)+CHR(10))
    && Controllo documenti
    SELECT DOT
	SCAN	   
	   iID_Testa = DOT.ID_DOTes
	   RifDocFT = DOT.Cd_DO + ALLTRIM(DOT.NumeroDoc)
       RifTesta = DOT.Cd_DO + DOT.NumeroDoc	
       THISFORM.xGetRigheDoc(iID_Testa)	&& Creo un cursore con le righe documento (DOR)
       && Castelletto IVA		
		&& Calcolo totali [codice IVA]/[Imponibile]
		numAliq = 0
		SELECT DOR
		SCAN
		    IF DOT.TipoDocumento = 'N' THEN && Controllo se si tratta di una nota di credito
				Segno = -1
			    ELSE 
				Segno = 01
			ENDIF 
			CodIVA = ALLTRIM(NVL(DOR.Cd_Aliquota, ""))
			Imponibile = DOR.PrezzoTotaleE * Segno
			IF !EMPTY(codIVA) THEN 
				IDAliq = 0
				FOR I = 1 TO numAliq
					IF Aliquota[I] = CodIVA THEN
						IDAliq = I
					ENDIF	
				NEXT
				IF IDAliq > 0 THEN
				   Totale[IDAliq] = Totale[IDAliq] + Imponibile
				   ELSE
				   numAliq = numAliq + 1
				   Aliquota[numAliq] = CodIVA && NB Codice IVA = Aliquota IVA (es. '22' oppure '10')
				   Totale[numAliq] = Imponibile
				ENDIF        	
	        ENDIF
	        SELECT DOR
		ENDSCAN		
		&& Salvataggio castelletto
		CodCliente = NVL(DOT.CF_xCdExp, "")
		tmp = DTOC(DOT.DataDoc)
		sDataDoc = LEFT(tmp, 2) + '.' + SUBSTR(tmp, 4,2) + '.' + RIGHT(tmp,4) 
		IF bNuovoTracciato THEN 
			** Nuovo tracciato (Tipo record = 7)		
			** Modifica del 01.12.2016
			** Tolto il riferimento del tipo documento
			** xTipoDoc = ALLTRIM(DOT.CD_Do) + '-'
			xTipoDoc = ''
			tempString = '7' + PADL(CodCliente, 6, '0')+ PADR(ALLTRIM(xTipoDoc + ALLTRIM(DOT.NumeroDoc)), 25, " ") + sDataDoc + '15'
			FOR I = 1 TO 6
				IF I <= numAliq THEN
				   tmpIMP = ALLTRIM(STR(Totale[I], 11, 2))
				   tmpNum = ROUND((Totale[I] * VAL(Aliquota[I]) / 100), 2)
				   tmpIVA = ALLTRIM(STR(tmpNum, 11, 2))
				   tempString = tempString + PADL(Aliquota[I], 4, '0') + CHRTRAN(PADL(tmpImp, 11, '0'), '.', ',') + CHRTRAN(PADL(tmpIVA, 11, '0'), '.', ',')
				   ELSE
				   tempString = tempString + PADL('0', 4, '0') + PADL('0,00', 11, '0') + PADL('0,00', 11, '0')
				ENDIF					
			NEXT	
			ELSE
			** Vecchio tracciato (Tipo record = 2 o 5)
			tempString = '5' + PADL(CodCliente, 6, '0')+ PADL(ALLTRIM(DOT.NumeroDoc), 12, "0") + sDataDoc + '15'
			FOR I = 1 TO 6
				IF I <= numAliq THEN
				   tmpIMP = ALLTRIM(STR(Totale[I], 11, 2))
				   tmpNum = ROUND((Totale[I] * VAL(Aliquota[I]) / 100), 2)
				   tmpIVA = ALLTRIM(STR(tmpNum, 11, 2))
				   tempString = tempString + PADL(Aliquota[I], 4, '0') + CHRTRAN(PADL(tmpImp, 11, '0'), '.', ',') + CHRTRAN(PADL(tmpIVA, 11, '0'), '.', ',')
				   ELSE
				   tempString = tempString + PADL('0', 4, '0') + PADL('0,00', 11, '0') + PADL('0,00', 11, '0')
				ENDIF		
			NEXT	
		ENDIF
		FWRITE (fiHandle, tempString + CHR(13)+CHR(10))
       
       && Dettagli documento
	** Righe documento / riferimenti DDT
	LastRif = -1
	LastDoc = -1
	SELECT DOR
	SCAN
		IF DOT.TipoDocumento = 'N' THEN && Nota di credito?
			Segno = -1
		   ELSE 
			Segno = 01
		ENDIF 
		&& Dati di testa (TIPO 3/6) Dettagli DDT
		IF !IsEmpty(DOR.id_dotes_Evade) THEN && se la riga è prelevata uso i riferimenti del documento prelevato 
			ThisRif = DOR.id_dotes_Evade
			IF ThisRif <> LastRif THEN 
				THISFORM.xGetInfoPrel(ThisRif) && Creo un cursore con i riferimenti del documento prelevato
				LastRif = ThisRif				
				tmp = DTOC(INFOPR.DataDoc) && data del documento/intervento prelevato
				sDataDoc = LEFT(tmp, 2) + '.' + SUBSTR(tmp, 4,2) + '.' + RIGHT(tmp,4) 
				CodCliente   = ALLTRIM(NVL(INFOPR.xCd_Exp, ""))
				IF !EMPTY(CodCliente) THEN && C'è il codice cliente nella destinazione del documento prelevato?
					NomeCliente  = ALLTRIM(INFOPR.RagioneSoc)
					ViaCliente   = ALLTRIM(INFOPR.Indirizzo)
					LuogoCliente = ALLTRIM(INFOPR.Localita)
					IF bNuovoTracciato THEN 
						sRifDoc = PADR(ALLTRIM(InfoPR.Cd_Do) + '-' + ALLTRIM(InfoPR.NumeroDoc), iLenRifDDT, " ") && Codice e numero DDT
						ELSE
						sRifDoc = PADL(ALLTRIM(InfoPR.NumeroDoc), iLenRifDDT, "0")
					ENDIF
					tempString = sTipoDett + PADL(CodCliente, 6, '0') + sRifDoc + sDataDoc + PADR(NomeCliente, 30, ' ') + PADR(ViaCliente, 30, ' ') + PADR(LuogoCliente, 30, ' ') 		
					FWRITE (fiHandle, tempString + CHR(13)+CHR(10))
				  ELSE && Uso i dati del documento prelevante
					** (Variante specifica x PCS/AtcWin)
					** 1) Se il documento prelevato non ha la destinazione diversa
					** utilizzo i dati della destinazione diversa e riferimenti della fattura
					** 2) Per gli interventi (AtcWin)
					** 		Non indicare il numero del documento
					** 		Indicare la data del documento/intervento
					** 		Indicare la destinazione diversa della fattura
					**					
					** Questa modifica è necessaria perchè gli interventi eseguiti con AtcWin 
					** non hanno destinazione diversa, sono prelevati manualmente e sono documenti fittizi
					THISFORM.xGetInfoDestft(DOR.Id_DoTes) && Creo un cursore con i dati relativi alla destinazione del documento ft/nc
					CodCliente   = ALLTRIM(NVL(INFODEST.xCd_Exp, ""))
					IF !EMPTY(CodCliente) THEN 
						NomeCliente  = ALLTRIM(INFODEST.RagioneSoc) && ALLTRIM(DOR.Nome)
						ViaCliente   = ALLTRIM(INFODEST.Indirizzo) && ALLTRIM(DOR.Indirizzo)
						LuogoCliente = ALLTRIM(INFODEST.Localita) && ALLTRIM(DOR.Localita)
						IF bNuovoTracciato THEN 
							sRifDoc = PADR(" ", iLenRifDDT, " ") && Non indico il numero del documento 
							&& sRifDoc = PADR(_DocTes.TipoDoc + '-' + ALLTRIM(DOR.NumeroDoc), iLenRifDDT, " ")
							ELSE
							sRifDoc = PADL("0", iLenRifDDT, "0") && Non indico il numero del documento 
							&& sRifDoc = PADL(ALLTRIM(DOR.NumeroDoc), iLenRifDDT, "0")
						ENDIF
						tempString = sTipoDett + PADL(CodCliente, 6, '0') + sRifDoc + sDataDoc + PADR(NomeCliente, 30, ' ') + PADR(ViaCliente, 30, ' ') + PADR(LuogoCliente, 30, ' ') 		
						FWRITE (fiHandle, tempString + CHR(13)+CHR(10))
					ENDIF					
				ENDIF
			ENDIF
		ELSE 
		    && Riferimenti documento nel caso non abbia prelevato DDT o altro (es. fattura accompagnatoria)
			DocRif = DOT.id_dotes
			&& xMessageBox('DocRif = ' + STR(DocRif))
		    IF DocRif <> LastDoc THEN  && se il documento non preleva 		    
		    	LastDoc = DocRif			
		    	THISFORM.xGetInfoDestft(DocRif) && Creo un cursore con info della destinazione del documento
				CodCliente   = ALLTRIM(NVL(INFODEST.xCd_Exp, ""))  &&& devo prenderlo comunque dalla destinazione diversa della nota di accredito o fattura immediata
				NomeCliente  = ALLTRIM(INFODEST.RagioneSoc) && ALLTRIM(DOR.Nome)
				ViaCliente   = ALLTRIM(INFODEST.Indirizzo) && ALLTRIM(DOR.Indirizzo)
				LuogoCliente = ALLTRIM(INFODEST.Localita) && ALLTRIM(DOR.Localita)
				tmp = DTOC(DOT.Datadoc)
				sDataDoc = LEFT(tmp, 2) + '.' + SUBSTR(tmp, 4,2) + '.' + RIGHT(tmp,4) 
				IF bNuovoTracciato THEN 
					sRifDoc = PADR(ALLTRIM(DOT.Cd_Do) + '-' + ALLTRIM(DOT.Numerodoc), iLenRifDDT, " ")
					ELSE
					sRifDoc = PADL(ALLTRIM(DOT.Numerodoc), iLenRifDDT, "0")
				ENDIF
				tempString = sTipoDett + PADL(CodCliente, 6, '0') + sRifDoc + sDataDoc + PADR(NomeCliente, 30, ' ') + PADR(ViaCliente, 30, ' ') + PADR(LuogoCliente, 30, ' ') 		
				FWRITE (fiHandle, tempString + CHR(13)+CHR(10))
			ENDIF 		
		ENDIF

		&& Dati di riga (TIPO 4) Dettagli di riga
		CodIVA 		= ALLTRIM(NVL(DOR.Cd_Aliquota, ""))
		Imponibile = DOR.PrezzoTotaleV * segno
		Quantita   = DOR.Qta 
		CodiceArticolo = THISFORM.xgetcodalt(DOT.Cd_CF, DOR.Cd_AR)
		IF IsEmpty(CodiceArticolo) THEN
			CodiceArticolo 		= ALLTRIM(DOR.Cd_AR)
		ENDIF
		IF IsEmpty(CodiceArticolo) THEN 
			CodiceArticolo 		= 'UKWN'		
		ENDIF
		DescrizioneArticolo = ALLTRIM(LEFT(DOR.Descrizione, 30))
		** Modifica del 01.12.2016
		** Quantita a tre decimali con virgola, la versione a due senza virgola è normalmente utilizzata per i servizi
		** ma Hogast accetta comunque i tre decimali ...
		** tmpQuantita 		= ALLTRIM(STR(ROUND((Quantita * 100) * Segno, 0), 9))
		tmpQuantita 		= CHRTRAN(ALLTRIM(STR(ROUND(Quantita*Segno,3), 11, 3)), '.', ',')
		tmpImponibile 		= CHRTRAN(ALLTRIM(STR(Imponibile, 11, 2)), '.', ',')

		tempString	= '4' + PADL(CodIVA, 4, '0') + PADL(tmpQuantita, 9, '0') + PADL(tmpImponibile, 11, '0') + PADR(CodiceArticolo, 13, ' ') + PADR(DescrizioneArticolo, 30, ' ')
		FWRITE (fiHandle, tempString + CHR(13)+CHR(10))
        SELECT DOR
	ENDSCAN

       SELECT DOT
	ENDSCAN
	** Chiusura file di EXPORT
	FCLOSE(fiHandle) 
	xMessageBox("Operazione terminata!") && : sono stati esportati " + str(RecTeste) + " documenti")
THIS.CmdExit()



ENDPROC
PROCEDURE Load
DODEFAULT()
THIS.QUERYDOT()
ENDPROC
PROCEDURE StatusBar.Refresh
*** ActiveX Control Method ***

ENDPROC
PROCEDURE PF.pgGenerale.Init
Local cFileName

DoDefault()
cFileName = This.txtDBFileName.Field.Value
If !IsEmpty(cFileName)
	If Lower(JustExt(cFileName)) == 'txt'
		This.optDBType.Value = 1
	EndIf
	If Lower(JustExt(cFileName)) == 'csv'
		This.optDBType.Value = 2
	EndIf
EndIf

ENDPROC
PROCEDURE PF.onpageactivate
Lparameters oPage, nOldpage, lJustRefreshed
DoDefault(oPage, nOldpage, lJustRefreshed)
Local cPageName
cPageName = Lower(oPage.Name)
Thisform.Toolbar.Buttons('ROWSEL').Visible	= (cPageName == 'pgselezione')
Thisform.Toolbar.Buttons('ROWUNSEL').Visible = (cPageName == 'pgselezione')

If cPageName == 'pgselezione'
	oPage.Grid.SaveRecordSource()
	Tablerevert(.T., 'Dot')
	Thisform.QueryDot(Thisform.wcgetWhereSelection())
	Index On Selected Tag Sel Collate "Machine"
	Set Order To 0
	Go Top
	oPage.Grid.RestoreRecordSource()
Endif

ENDPROC

*======================================================================

*** CLASS / OBJECT: Field (BaseClass: control, Parent: cmd.PF.pgGenerale.txtDBFileName) ***
*** PROPERTIES ***
Comment = "E5354863-9694-4F41-8C47-F2E7A7469E14"
Anchor = 10
Top = 12
Left = 0
Width = 416
Height = 16
pickmode = 2
addallfiles = .F.
Name = "Field"
field.Alignment = 0
field.Name = "field"

*** METHODS ***
PROCEDURE Init
Local cFileName

DoDefault()
cFileName = ThisForm.UserPrefGetProperty(This, UP_SCOPE_COMPUSER, 'Value', '')
This.SetValue(cFileName)


ENDPROC
PROCEDURE Destroy
ThisForm.UserPrefSetProperty(This, UP_SCOPE_COMPUSER, 'Value', This.Value)
DoDefault()

ENDPROC

*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: cmd.PF.pgOpzioni.txtCd_DO) ***
*** PROPERTIES ***
Left = 98
wccolumnname = DOTes.Cd_DO
fkhasdisplay = .T.
wcoperator = 11
Name = "Field"

*** METHODS ***
PROCEDURE Init
Local cWhereValue

DoDefault()
** cCodeValue = ThisForm.UserPrefGetProperty(This, UP_SCOPE_COMPUSER, 'Value', '')
** This.SetValue(cCodeValue)
cWhereValue = ThisForm.UserPrefGetProperty(This, UP_SCOPE_COMPUSER, 'wcInListWhere', '')
This.wcInListWhere = cWhereValue

ENDPROC
PROCEDURE Destroy
** ThisForm.UserPrefSetProperty(This, UP_SCOPE_COMPUSER, 'Value', This.Value)
ThisForm.UserPrefSetProperty(This, UP_SCOPE_COMPUSER, 'wcInListWhere', This.wcInListWhere)
DoDefault()

ENDPROC
PROCEDURE wcgetwhere
Lparameters cColumnName
LOCAL cValue, cValue2, cType, cRet

cValue = THIS.WcGetValue()
cValue2=cValue
cType  = Vartype(cValue)

If cType == 'C' And InList(THIS.WcOperator, WC_OP_K, WC_OP_NK)
	** Senza questo trucco in caso di like ci mette una vitra per grandi quantiotà di documenti
	** o va in time out
	IF AT('\%', cValue) = 0 And At('_', cValue) = 0
		cValue = RTrim(cValue) + '%'
		THIS.Value = 'SOSTITUIRE\%'
	ELSE
		THIS.Value = 'SOSTITUIRE'
	ENDIF
	cRet = DODEFAULT(cColumnName)
	cRet = STRTRAN(cRet, "'" + THIS.Value + "'", "(SELECT '" + cValue + "')")
	THIS.Value = cValue2
ELSE
	cRet = DODEFAULT(cColumnName)
ENDIF 

RETURN cRet
ENDPROC

*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: cmd.PF.pgOpzioni.txt_CD_CF) ***
*** PROPERTIES ***
ControlSource = ""
Height = 19
InputMask = "CXXXXXX"
Left = 98
MaxLength = 3
Top = 0
Width = 57
fkselect = SELECT * FROM CFCli WHERE Cd_CF = <TEXT>
fktabledesc = Clienti
wccolumndesc = Cd_CF
wccolumnname = DOTes.Cd_CF
fkhasdisplay = .T.
fkacceptinvalid = .F.
fkalias = CFCli
fkdecodedfield = Descrizione
Name = "Field"

*** METHODS ***
PROCEDURE Init
Local cCodeValue

DoDefault()
cCodeValue = ThisForm.UserPrefGetProperty(This, UP_SCOPE_COMPUSER, 'Value', '')
This.SetValue(cCodeValue)
ENDPROC
PROCEDURE Destroy
ThisForm.UserPrefSetProperty(This, UP_SCOPE_COMPUSER, 'Value', This.Value)
DoDefault()

ENDPROC

*======================================================================

*** CLASS / OBJECT: optDBType (BaseClass: optiongroup, Parent: cmd.PF.pgGenerale) ***
*** PROPERTIES ***
Comment = "109E57D3-20E7-4D1A-9AD4-B0FEC46783F2"
BorderStyle = 0
Height = 40
Left = 21
Top = 26
Width = 233
TabIndex = 1
Name = "optDBType"
Option1.Caption = "File di testo (*.txt)"
Option1.Value = 1
Option1.Left = 5
Option1.Top = 5
Option1.Name = "Option1"
Option2.Caption = "File CSV (*.csv)"
Option2.Left = 5
Option2.Top = 23
Option2.Name = "Option2"

*** METHODS ***
PROCEDURE onrefresh
LParameters xOldValue

DoDefault(xOldValue)
If This.Value == 1	&&--> TXT
	This.Parent.txtDBFileName.Field.OpenFileDialogExt = "Files di Export (*.txt):*.txt"
	If !IsEmpty(This.Parent.txtDBFileName.Field.Value)
		This.Parent.txtDBFileName.Field.SetValue(ForceExt(This.Parent.txtDBFileName.Field.Value, 'txt'))
	EndIf
EndIf
If This.Value == 2	&&--> CSV
	This.Parent.txtDBFileName.Field.OpenFileDialogExt = "Files di Export (*.csv):*.csv"
	If !IsEmpty(This.Parent.txtDBFileName.Field.Value)	
		This.Parent.txtDBFileName.Field.SetValue(ForceExt(This.Parent.txtDBFileName.Field.Value, 'csv'))	
	EndIf
EndIf

ENDPROC

*======================================================================

*** CLASS / OBJECT: GRID (BaseClass: grid, Parent: cmd.PF.pgSelezione) ***
*** PROPERTIES ***
ColumnCount = 8
Comment = "781C3FAC-8EAD-4FA8-8716-CED417F660E5"
Anchor = 15
Height = 282
Left = 0
Panel = 1
RecordSource = "DOT"
RowHeight = 17
Top = 0
Width = 472
Name = "GRID"
Stdcolumn1.Comment = "64AB12F7-F75A-47DD-A63A-F2E7D2F235AE"
Stdcolumn1.FontName = "Segoe UI"
Stdcolumn1.FontSize = 8
Stdcolumn1.Alignment = 2
Stdcolumn1.ControlSource = "Dot.Selected"
Stdcolumn1.CurrentControl = ""
Stdcolumn1.Width = 19
Stdcolumn1.Sparse = .F.
Stdcolumn1.Name = "ColSelected"
Stdcolumn2.Comment = "7182D41F-E208-4C32-B60B-D946941B51FF"
Stdcolumn2.FontName = "Segoe UI"
Stdcolumn2.FontSize = 8
Stdcolumn2.ControlSource = "Dot.Cd_CF"
Stdcolumn2.Width = 48
Stdcolumn2.Name = "ColCd_CF"
Stdcolumn3.Comment = "3F29CFBF-B69D-427A-9A77-4D22D6D626EF"
Stdcolumn3.FontName = "Segoe UI"
Stdcolumn3.FontSize = 8
Stdcolumn3.ControlSource = "Dot.CF_Descrizione"
Stdcolumn3.Width = 100
Stdcolumn3.Name = "ColCF_Descrizione"
Stdcolumn4.Comment = "06CA1313-60B7-42BC-9A06-EAF79F508AF0"
Stdcolumn4.FontName = "Segoe UI"
Stdcolumn4.FontSize = 8
Stdcolumn4.ControlSource = "Dot.Cd_DO"
Stdcolumn4.Width = 35
Stdcolumn4.Name = "ColCd_DO"
Stdcolumn5.Comment = "20A4303F-E1A4-42D6-8481-DA5A1499ADEF"
Stdcolumn5.FontName = "Segoe UI"
Stdcolumn5.FontSize = 8
Stdcolumn5.ControlSource = "DoT.NumeroDoc"
Stdcolumn5.Width = 61
Stdcolumn5.Name = "ColNumeroDoc"
Stdcolumn6.Comment = "50D6425C-F774-4CF7-96C8-7B7A70C3B48B"
Stdcolumn6.FontName = "Segoe UI"
Stdcolumn6.FontSize = 8
Stdcolumn6.ControlSource = "TTOD(DoT.DataDoc)"
Stdcolumn6.Width = 58
Stdcolumn6.Name = "ColDataDoc"
Stdcolumn7.Comment = "53D8C6B2-85B8-4029-AF02-831CADB73FFD"
Stdcolumn7.FontName = "Segoe UI"
Stdcolumn7.FontSize = 8
Stdcolumn7.ControlSource = "DoT.NumeroDocRif"
Stdcolumn7.Width = 79
Stdcolumn7.Name = "ColNumeroDocRif"
Stdcolumn8.Comment = "13489E24-26C9-43AE-A496-A9D1CD9921C5"
Stdcolumn8.FontName = "Segoe UI"
Stdcolumn8.FontSize = 8
Stdcolumn8.ControlSource = "TTOD(DoT.dataDocRif)"
Stdcolumn8.Width = 78
Stdcolumn8.Name = "ColdataDocRif"

*** METHODS ***
PROCEDURE dynamicbackcolor
RETURN IIF(Selected, oApp.ColorInfoBK, oApp.ColorWindow)
ENDPROC
PROCEDURE Init
DODEFAULT()
THIS.SetAll('READONLY', .T.)
THIS.ColSelected.READONLY = .F.
THIS.SetAll('DynamicBackColor', 'THIS.DynamicBackColor()')
ENDPROC
PROCEDURE oncolumnheaderclick
**	Autogenerated code start -- don't touch
LPARAMETERS ocol
OnColClickMakeIndex(oCol)
**	Autogenerated code end   -- don't touch

ENDPROC

*======================================================================

*** CLASS / OBJECT: Stdcheck1 (BaseClass: checkbox, Parent: cmd.PF.pgSelezione.GRID.ColSelected) ***
*** PROPERTIES ***
Comment = "DD001AE9-57CE-42A4-BE1F-5C5BF73C024A"
Top = 70
Left = 7
FontSize = 8
AutoSize = .F.
Alignment = 0
Centered = .T.
Caption = ""
Name = "Stdcheck1"

*** METHODS ***
PROCEDURE onvaluechange
LPARAMETERS xOldValue
THIS.Parent.Parent.Refresh()
ENDPROC

*======================================================================

