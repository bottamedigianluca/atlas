*** Extracted Visual FoxPro Source Code from cmd_xlschange.vcx ***

*** CLASS / OBJECT: cmd (BaseClass: form, Parent: ) ***
*** PROPERTIES ***
Top = 0
Left = 1
Height = 387
Width = 400
DoCreate = .T.
Caption = "Modifica listini"
xcd_ls1 = ''
xcd_ls2 = ''
xcd_ls3 = ''
xlscolprezzipr = .F.
xlsmoddesc = .F.
xcd_ls4 = Codice listino 4
xiddatfilter = 0
Name = "cmd"
statusbar.Top = 367
statusbar.Left = 0
statusbar.Height = 20
statusbar.Width = 400
statusbar.Name = "statusbar"
title_bar.BtnLabel.Name = "BtnLabel"
title_bar.lblLabel.Name = "lblLabel"
title_bar.Name = "title_bar"
timer4ExecAsync.Name = "timer4ExecAsync"
SCMenu.Name = "SCMenu"
tbenabler.Name = "tbenabler"
PF.ErasePage = .T.
PF.PageCount = 2
PF.Pgbase1.Caption = "Filtro"
PF.Pgbase1.Name = "pgFilter"
PF.Pgbase2.Caption = "Selezione"
PF.Pgbase2.Name = "pgSelezione"
PF.Top = 28
PF.Left = 0
PF.Width = 402
PF.Height = 332
PF.Name = "PF"

*** METHODS ***
PROCEDURE queryls
LPARAMETERS cWhere

LOCAL xMyCd_LS1
LOCAL xMyCd_LS2
LOCAL xMyCd_LS3
LOCAL xMyCd_LS4
LOCAL xMyIDFilter
LOCAL xMyDefaultFilter

xMyDefaultFilter = '1=1'

IF !VARTYPE(cWhere) = 'L' THEN
	IF THIS.xIDdatfilter> 0 THEN 
		xMyDefaultFilter = "AR.Attributi.exist('/rows[ (row/@attributo = " + ALLTRIM(STR(THIS.xIDdatfilter)) + ")]') = 1"
	ENDIF
ENDIF

xMyCd_LS1 = THIS.xCd_Ls1

IF !IsEmpty(THIS.xCd_Ls2) THEN 
	xMyCd_LS2 = THIS.xCd_Ls2 
	ELSE
	xMyCd_LS2 = THIS.xCd_Ls1 && Uso il primo listino (obbligatorio) per poter creare il cursore corretto 
ENDIF

IF !IsEmpty(THIS.xCd_Ls3) THEN 
	xMyCd_LS3 = THIS.xCd_Ls3
	ELSE
	xMyCd_LS3 = THIS.xCd_Ls1 && Uso il primo listino (obbligatorio) per poter creare il cursore corretto 
ENDIF

IF !IsEmpty(THIS.xCd_Ls4) THEN 
	xMyCd_LS4 = THIS.xCd_Ls4
	ELSE
	xMyCd_LS4 = THIS.xCd_Ls1 && Uso il primo listino (obbligatorio) per poter creare il cursore corretto 
ENDIF

IF VARTYPE(cWhere) = 'L'
	cWhere = '1=0'
ENDIF

IF xMyDefaultFilter <> '1=1' THEN 
	cWhere = cWhere + ' AND ' + xMyDefaultFilter 
ENDIF

cWhere = xDefault(cWhere, xMyDefaultFilter)
LOCAL cStmt
&& 1. Selezione elenco articoli e creazione del cursore base
&& (CostoStandard-CostoStandard) ovviamente restituisce 0 ma viene eseguita per ottenere
&& campi con la tipologia Numeric (18,6) che è necessaria per un corretto input dei listini

TEXT TO cStmt NOSHOW TEXTMERGE
	Declare @Cd_LS1 Char(7)
	Declare @Cd_LS2 Char(7)
	Declare @Cd_LS3 Char(7)
	Declare @Cd_LS4 Char(7)
	Declare @Id_LSRevisione1 as Integer
	Declare @Id_LSRevisione2 as Integer
	Declare @Id_LSRevisione3 as Integer
	Declare @Id_LSRevisione4 as Integer

	Select @Cd_LS1 = <<Format4Spt(xMyCd_LS1)>>
	Select @Cd_LS2 = <<Format4Spt(xMyCd_LS2)>>
	Select @Cd_LS3 = <<Format4Spt(xMyCd_LS3)>>
	Select @Cd_LS4 = <<Format4Spt(xMyCd_LS4)>>

	Select Top 1 @Id_LSRevisione1 = Id_LSRevisione
	From LSRevisione
	Where Cd_LS = @Cd_LS1 And DaData <= GetDate()
	Order By DaData Desc

	Select Top 1 @Id_LSRevisione2 = Id_LSRevisione
	From LSRevisione
	Where Cd_LS = @Cd_LS2 And DaData <= GetDate()
	Order By DaData Desc

	Select Top 1 @Id_LSRevisione3 = Id_LSRevisione
	From LSRevisione
	Where Cd_LS = @Cd_LS3 And DaData <= GetDate()
	Order By DaData Desc	
	
	Select Top 1 @Id_LSRevisione4 = Id_LSRevisione
	From LSRevisione
	Where Cd_LS = @Cd_LS4 And DaData <= GetDate()
	Order By DaData Desc	

	SELECT
		CONVERT(BIT, 1) AS Selected
		, AR.Cd_AR
		, AR.Descrizione AS DSBase_AR
		, AR.Descrizione
		, ARARMISURA.Cd_ARMisura
		, COALESCE(LS1.Prezzo,0) AS LSBase1
		, COALESCE(LS1.Prezzo,0) AS LSMod1
		, COALESCE(LS2.Prezzo,0) AS LSBase2
		, COALESCE(LS2.Prezzo,0) AS LSMod2
		, COALESCE(LS3.Prezzo,0) AS LSBase3
		, COALESCE(LS3.Prezzo,0) AS LSMod3
		, COALESCE(LS4.Prezzo,0) AS LSBase4
		, COALESCE(LS4.Prezzo,0) AS LSMod4
	FROM AR
	Left Join ARARMisura ON AR.Cd_AR = ARARMisura.Cd_AR AND ARARMisura.DefaultMisura = 1
	Left Join LSArticolo LS1 On  AR.Cd_AR = LS1.Cd_AR And LS1.Id_LSRevisione = @Id_LSRevisione1
	Left Join LSArticolo LS2 On  AR.Cd_AR = LS2.Cd_AR And LS2.Id_LSRevisione = @Id_LSRevisione2
	Left Join LSArticolo LS3 On  AR.Cd_AR = LS3.Cd_AR And LS3.Id_LSRevisione = @Id_LSRevisione3
	Left Join LSArticolo LS4 On  AR.Cd_AR = LS4.Cd_AR And LS4.Id_LSRevisione = @Id_LSRevisione4	
	WHERE <<cWhere>>		
ENDTEXT

_ClipText = cStmt 

xSqlExec(cStmt, 'myLS')

ENDPROC
PROCEDURE wcgetwhereselection
LPARAMETERS lCheckOnCF
LOCAL cWhere
LOCAL lAll
lAll = .T.
IF lCheckOnCF
	IF SEEK(.F., 'myLS', 'Sel')
		cWhere = ''
		SELECT myLS
		SCAN FOR Selected
			cWhere = cWhere + ", " + "'" + Cd_AR + "'"
		ENDSCAN
		IF !EMPTY(cWhere)
			cWhere = ' Cd_AR IN (' + SUBSTR(cWhere, 3) + ')' && Tolgo la prima virgola ...
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
PROCEDURE xgetidrevisione
LPARAMETERS cCd_LS
LOCAL myIDRev

myIDRev = -1
IF !IsEmpty(cCd_LS) THEN
	TEXT TO cStmt NOSHOW TEXTMERGE

		Select Top 1 Id_LSRevisione
		From LSRevisione
		Where Cd_LS = <<Format4Spt(cCd_LS)>> And DaData <= GetDate()
		Order By DaData Desc

	ENDTEXT

	xSqlExec(cStmt, 'myRev')
	myIDRev = myRev.Id_LSRevisione

	USE IN myRev
ENDIF

RETURN myIDRev && ID Revisione del listino

ENDPROC
PROCEDURE xgetidlsarticolo
LPARAMETERS cCd_AR, nIDRevisione
LOCAL myIDLS

myIDLS = 0

TEXT TO cStmt NOSHOW TEXTMERGE

	Select Id_LSArticolo
	From LSArticolo
	Where Cd_AR = <<Format4Spt(cCd_AR)>> 
	And Id_LSRevisione = <<Format4Spt(nIDRevisione)>> 

ENDTEXT

xSqlExec(cStmt, 'myLSArticolo')
myIDLS = myLSArticolo.Id_LSArticolo

USE IN myLSArticolo

RETURN myIDLS && ID Record LSArticolo 


ENDPROC
PROCEDURE xlsinsert
LPARAMETERS cCd_AR, nIDRevisione, nPrezzo
LOCAL lResult 

TEXT TO cStmt NOSHOW TEXTMERGE

	INSERT INTO LSArticolo (Cd_AR, id_LSRevisione, Prezzo)
	VALUES (<<Format4Spt(cCd_AR)>>, <<Format4Spt(nIDRevisione)>>,  <<Format4Spt(nPrezzo)>>)

ENDTEXT

IF xSqlExec(cStmt, , .T.) > 0 THEN 
	lResult = .T.
	ELSE
	lResult = .F.
ENDIF

RETURN lResult

ENDPROC
PROCEDURE xlsupdate
LPARAMETERS nLSArticolo, nPrezzo
LOCAL lResult 

TEXT TO cStmt NOSHOW TEXTMERGE

	UPDATE LSArticolo 
	SET Prezzo = <<Format4Spt(nPrezzo)>>
	WHERE Id_LSArticolo = <<Format4Spt(nLSArticolo)>>

ENDTEXT

IF xSqlExec(cStmt, , .T.) > 0 THEN 
	lResult = .T.
	ELSE
	lResult = .F.
ENDIF

RETURN lResult

ENDPROC
PROCEDURE xlsmodifcati
LOCAL lModified

lModified = .F.

SELECT myLS
SCAN

	IF !lModified THEN
		&& 1° Listino
		IF myLS.LSBase1 <> myLS.LSMod1 THEN
			lModified = .T.
		ENDIF	
	ENDIF
	
	IF !lModified THEN
		&& 2° Listino
		IF myLS.LSBase2 <> myLS.LSMod2 THEN
			lModified = .T.
		ENDIF	
	ENDIF

	IF !lModified THEN
		&& 2° Listino
		IF myLS.LSBase3 <> myLS.LSMod3 THEN
			lModified = .T.
		ENDIF	
	ENDIF
	
ENDSCAN

RETURN lModified 
ENDPROC
PROCEDURE Init
DODEFAULT()
cStmt = "SELECT TOP 1 xCd_LSMod1, xCd_LSMod2, xCd_LSMod3, xCd_LSMod4, xLSDettPr, xLSModDesc, xLSFltAtt FROM Preferenza"
oPref = xSqlExec2Obj(cStmt)
THIS.xCd_ls1 = oPref.xCd_LSMod1
THIS.xCd_ls2 = oPref.xCd_LSMod2
THIS.xCd_ls3 = oPref.xCd_LSMod3
THIS.xCd_ls4 = oPref.xCd_LSMod4
THIS.xLScolprezzipr	= oPref.xLSDettPr
THIS.xLSModDesc 	= oPref.xLSModDesc 
THIS.xIDdatfilter	= NVL(oPref.xLSFltAtt,0) 


TEXT TO mySQLBase 
	select VL.PicSepPrzUn 
	from LS INNER JOIN VL ON LS.Cd_VL = VL.CD_VL
	Where LS.Cd_LS =
ENDTEXT

TEXT TO mySQL TEXTMERGE
	<<mySQLBase>>  <<Format4Spt(THIS.xcd_ls1)>>
ENDTEXT
oRec1 = xSqlExec2Obj(mySQL)

IF !IsEmpty(THIS.xcd_ls2) THEN 
	TEXT TO mySQL TEXTMERGE
		<<mySQLBase>>  <<Format4Spt(THIS.xcd_ls2)>>
	ENDTEXT
	oRec2 = xSqlExec2Obj(mySQL)
ENDIF

IF !IsEmpty(THIS.xcd_ls3) THEN 
	TEXT TO mySQL TEXTMERGE
		<<mySQLBase>>  <<Format4Spt(THIS.xcd_ls3)>>
	ENDTEXT
	oRec3 = xSqlExec2Obj(mySQL)
ENDIF

IF !IsEmpty(THIS.xcd_ls4) THEN 
	TEXT TO mySQL TEXTMERGE
		<<mySQLBase>>  <<Format4Spt(THIS.xcd_ls4)>>
	ENDTEXT
	oRec4 = xSqlExec2Obj(mySQL)
ENDIF

WITH THIS.PF.pgSelezione.Grid 
	
	.ColLsBase1.Header1.Caption = ALLTRIM(UPPER(THIS.xcd_ls1))
	.ColLSBase1.InputMask = oRec1.PicSepPrzUn	
	.ColLSBase1.Visible = THIS.xLScolprezzipr 
	.ColLsMod1.Header1.Caption = ALLTRIM(UPPER(THIS.xcd_ls1)) + ' *'
	.ColLSMod1.InputMask = oRec1.PicSepPrzUn
	.ColLSMod1.SelectOnEntry = .T.
	.ColLSMod1.BackColor = oApp.ColorGridBackOrange
	.ColLSMod1.ReadOnly = .F.	
	
	IF THIS.xLSModDesc THEN 
		.ColAR_Descrizione.ReadOnly = .F.	
		ELSE
		.ColAR_Descrizione.ReadOnly = .T.	
	ENDIF

	IF !IsEmpty(THIS.xcd_ls2) THEN 	
		.ColLsBase2.Header1.Caption = ALLTRIM(UPPER(THIS.xcd_ls2))	
		.ColLSBase2.InputMask = oRec2.PicSepPrzUn
		.ColLSBase2.Visible = THIS.xLScolprezzipr 
		.ColLsMod2.Header1.Caption = ALLTRIM(UPPER(THIS.xcd_ls2)) + ' *'
		.ColLSMod2.InputMask = oRec2.PicSepPrzUn
		.ColLSMod2.SelectOnEntry = .T.
		.ColLSMod2.BackColor = oApp.ColorGridBackOrange
		.ColLSMod2.ReadOnly = .F.	
		ELSE
		.ColLsBase2.Visible = .F.
		.ColLSMod2.Visible = .F.
	ENDIF
	
	IF !IsEmpty(THIS.xcd_ls3) THEN 			
		.ColLsBase3.Header1.Caption = ALLTRIM(UPPER(THIS.xcd_ls3))
		.ColLSBase3.InputMask = oRec3.PicSepPrzUn
		.ColLSBase3.Visible = THIS.xLScolprezzipr 
		.ColLsMod3.Header1.Caption = ALLTRIM(UPPER(THIS.xcd_ls3)) + ' *'
		.ColLSMod3.InputMask = oRec3.PicSepPrzUn
		.ColLSMod3.SelectOnEntry = .T.
		.ColLSMod3.BackColor = oApp.ColorGridBackOrange
		.ColLSMod3.ReadOnly = .F.			
		ELSE
		.ColLsBase3.Visible = .F.
		.ColLSMod3.Visible = .F.
	ENDIF
		
	IF !IsEmpty(THIS.xcd_ls4) THEN 			
		.ColLsBase4.Header1.Caption = ALLTRIM(UPPER(THIS.xcd_ls4))
		.ColLSBase4.InputMask = oRec3.PicSepPrzUn
		.ColLSBase4.Visible = THIS.xLScolprezzipr 
		.ColLsMod4.Header1.Caption = ALLTRIM(UPPER(THIS.xcd_ls4)) + ' *'
		.ColLSMod4.InputMask = oRec3.PicSepPrzUn
		.ColLSMod4.SelectOnEntry = .T.
		.ColLSMod4.BackColor = oApp.ColorGridBackOrange
		.ColLSMod4.ReadOnly = .F.			
		ELSE
		.ColLsBase4.Visible = .F.
		.ColLSMod4.Visible = .F.
	ENDIF

ENDWITH









ENDPROC
PROCEDURE querynavigate
LPARAMETERS nCurActivePage, nNewActivePage

IF !DODEFAULT(nCurActivePage, nNewActivePage)
RETURN .F.
ENDIF
If nCurActivePage = 2 AND nCurActivePage > nNewActivePage  THEN
	IF THIS.xLSModifcati() THEN 
		idResult = xMessageBox("Sono stati variati alcuni prezzi: annullare le modifiche?", MB_YESNO + MB_DEFBUTTON2, "ATTENZIONE")
		IF idResult = 7 THEN 
			Return .F.
		ENDIF
	ENDIF		
ENDIF   


** Inizio Codice d'esempio
** Tornando .T. o .F. da questo metodo si può impedire il passaggio da uno step ad un altro
** Tentativo di attivare la pagina tre da uno step precedente
** Le pagine eventualmente disabilitate verranno ignorate
** IF nNewActivePage = 3 AND nCurActivePage < nNewActivePage 
**     xMessageBox('Non posso continuare')
**     RETURN .F.
** ENDIF
** Fine Codice d'esempio


ENDPROC
PROCEDURE cmdfine
LOCAL xidRev1, xidRev2, xidRev3, xidRev4
LOCAL xIdLSArticolo
LOCAL cStmt 
LOCAL xUpd, xIns, xDescUpd
LOCAL xIsChanged
LOCAL lContinue

idResult = xMessageBox("Procedere con l'aggiornamento dei listini modificati?", MB_YESNO + MB_DEFBUTTON1, "ATTENZIONE")
IF idResult = 6 THEN 
   lContinue = .T.
   ELSE
   lContinue =.F.
ENDIF
IF lContinue
	xidRev1 = THIS.xgetidrevisione(THIS.xCd_ls1)
	xidRev2 = THIS.xgetidrevisione(THIS.xCd_ls2)
	xidRev3 = THIS.xgetidrevisione(THIS.xCd_ls3)
	xidRev4 = THIS.xgetidrevisione(THIS.xCd_ls4)

	xUpd 	= 0
	xIns 	= 0
	xDescUpd= 0

	SELECT myLS
	SCAN
		&& Descrizione
		IF UPPER(ALLTRIM(myLS.Descrizione))<>UPPER(ALLTRIM(myLS.DSBase_AR)) THEN 
			TEXT TO cStmt NOSHOW TEXTMERGE

				UPDATE AR
				SET Descrizione = <<Format4Spt(myLS.Descrizione)>>
				WHERE Cd_AR = <<Format4Spt(myLS.Cd_AR)>>

			ENDTEXT

			IF xSqlExec(cStmt, , .T.) > 0 THEN 
				xDescUpd = xDescUpd + 1
			ENDIF
		ENDIF

		&& 1° Listino
		IF xIdRev1 > 0 THEN
			IF myLS.LSBase1 <> myLS.LSMod1 THEN
				xIdLSArticolo = THIS.xgetidlsarticolo(myLS.Cd_AR, xidRev1)		
				IF xIdLSArticolo > 0 THEN 
					IF THIS.xLSUpdate(xIdLSArticolo, myLS.LSMod1) THEN 
						xUpd = xUpd +1
					ENDIF			
					ELSE
					IF THIS.xLSInsert(myLS.Cd_AR, xidRev1, myLS.LSMod1) THEN 				
						xIns = xIns +1
					ENDIF						
				ENDIF
			ENDIF	
			SELECT myLS
		ENDIF
				
		&& 2° Listino
		IF xIdRev2 > 0 THEN
			IF myLS.LSBase2 <> myLS.LSMod2 THEN
				xIdLSArticolo = THIS.xgetidlsarticolo(myLS.Cd_AR, xidRev2)		
				IF xIdLSArticolo > 0 THEN 
					IF THIS.xLSUpdate(xIdLSArticolo, myLS.LSMod2) THEN 				
						xUpd = xUpd +1
					ENDIF			
					ELSE
					IF THIS.xLSInsert(myLS.Cd_AR, xidRev2, myLS.LSMod2) THEN 
						xIns = xIns +1
					ENDIF						
				ENDIF
			ENDIF	
			SELECT myLS
		ENDIF
		
		&& 3° Listino
		IF xIdRev3 > 0 THEN
			IF myLS.LSBase3 <> myLS.LSMod3 THEN
				xIdLSArticolo = THIS.xgetidlsarticolo(myLS.Cd_AR, xidRev3)		
				IF xIdLSArticolo > 0 THEN 
					IF THIS.xLSUpdate(xIdLSArticolo, myLS.LSMod3) THEN 
						xUpd = xUpd +1
					ENDIF			
					ELSE
					IF THIS.xLSInsert(myLS.Cd_AR, xidRev3, myLS.LSMod3) THEN 				
						xIns = xIns +1
					ENDIF						
				ENDIF
			ENDIF	
			SELECT myLS
		ENDIF

		&& 4° Listino
		IF xIdRev4 > 0 THEN
			IF myLS.LSBase4 <> myLS.LSMod4 THEN
				xIdLSArticolo = THIS.xgetidlsarticolo(myLS.Cd_AR, xidRev4)		
				IF xIdLSArticolo > 0 THEN 
					IF THIS.xLSUpdate(xIdLSArticolo, myLS.LSMod4) THEN 
						xUpd = xUpd +1
					ENDIF			
					ELSE
					IF THIS.xLSInsert(myLS.Cd_AR, xidRev4, myLS.LSMod4) THEN 				
						xIns = xIns +1
					ENDIF						
				ENDIF
			ENDIF	
			SELECT myLS
		ENDIF
				
	ENDSCAN

	&& USE IN myLS
	TEXT TO myMsg TEXTMERGE PRETEXT 3
		Modifica listini terminata
		<<STR(xIns, 5,0)>> inseriti
		<<STR(xUpd, 5,0)>> aggiornati	
		<<IIF(xDescUpd > 0,  CHR(13) + STR(xDescUpd, 5,0) + ' descrizioni articolo modificate', '')>>
	ENDTEXT
	xMessageBox(myMsg)

	RELEASE THISFORM  
	** Fine Codice d'esempio
ENDIF
ENDPROC
PROCEDURE Load
DODEFAULT()
THIS.QUERYLS()

ENDPROC
PROCEDURE inittoolbar
DODEFAULT()

*!*	WITH THISFORM.TOOLBAR
*!*		.BUTTONS('ROWSEL').Enabled		= .T.
*!*		.BUTTONS('ROWUNSEL').Enabled	= .T.
*!*	ENDWITH
ENDPROC
PROCEDURE cmdrowsel
LOCAL nRec

nRec = 0

IF !EOF('myLS') AND !BOF('myLS')
	nRec = RECNO('myLS')
ENDIF

REPLACE ALL Selected WITH .T. IN myLS
THISFORM.PF.pgSelezione.Grid.Refresh()
IF nRec > 0
	GO (nRec) IN myLS
ENDIF
ENDPROC
PROCEDURE cmdrowunsel
LOCAL nRec

nRec = 0

IF !EOF('myLS') AND !BOF('myLS')
	nRec = RECNO('myLS')
ENDIF

REPLACE ALL Selected WITH .F. IN myLS
THISFORM.PF.pgSelezione.Grid.Refresh()
IF nRec > 0
	GO (nRec) IN myLS
ENDIF
ENDPROC
PROCEDURE PF.onpageactivate
Lparameters oPage, nOldpage, lJustRefreshed
DoDefault(oPage, nOldpage, lJustRefreshed)
Local cPageName
cPageName = Lower(oPage.Name)
*!*	Thisform.Toolbar.Buttons('ROWSEL').Visible	= (cPageName == 'pgselezione')
*!*	Thisform.Toolbar.Buttons('ROWUNSEL').Visible = (cPageName == 'pgselezione')

If cPageName == 'pgselezione'
	oPage.Grid.SaveRecordSource()
	Tablerevert(.T., 'myLS')
	Thisform.QueryLS(Thisform.wcgetWhereSelection())
	Index On Selected Tag Sel Collate "Machine"
	Set Order To 0
	Go Top
	oPage.Grid.RestoreRecordSource()
*!*		oPage.Grid.ColLSMod1.ReadOnly = .F.	
*!*		oPage.Grid.ColLSMod2.ReadOnly = .F.	
*!*		oPage.Grid.ColLSMod3.ReadOnly = .F.			
ENDIF

If cPageName == 'pgfilter'
	&& Impostazioni per filtri

ENDIF


ENDPROC

*======================================================================

*** CLASS / OBJECT: txtCd_CF_For (BaseClass: container, Parent: cmd.PF.pgFilter) ***
*** PROPERTIES ***
Top = 77
Left = 47
Width = 415
Height = 19
TabIndex = 4
Name = "txtCd_CF_For"
Label.Comment = "C3232B37-B3B4-4C1E-AD7F-081BBA3528F6"
Label.Caption = "Fornitore"
Label.Left = 0
Label.Top = 3
Label.Name = "Label"

*** METHODS ***
PROCEDURE wcgetwhere
LParameters cAlias

Local cStmt

If !This.Field.wcIsEmpty()
	cStmt = DoDefault(cAlias)
	cStmt = ' And AR.Cd_AR In (Select Cd_AR From ARCodCF Where 1=1 ' + cStmt + ')'
Else
	cStmt = ''
EndIf
Return cStmt


ENDPROC

*======================================================================

*** CLASS / OBJECT: GRID (BaseClass: grid, Parent: cmd.PF.pgSelezione) ***
*** PROPERTIES ***
ColumnCount = 12
Comment = "781C3FAC-8EAD-4FA8-8716-CED417F660E5"
Anchor = 15
Height = 303
Left = 1
Panel = 1
RecordSource = "myLS"
RowHeight = 17
Top = 1
Width = 396
Name = "GRID"
Stdcolumn1.Comment = "64AB12F7-F75A-47DD-A63A-F2E7D2F235AE"
Stdcolumn1.FontName = "Segoe UI"
Stdcolumn1.FontSize = 8
Stdcolumn1.Alignment = 2
Stdcolumn1.ControlSource = "myLS.Selected"
Stdcolumn1.CurrentControl = ""
Stdcolumn1.Enabled = .F.
Stdcolumn1.Width = 19
Stdcolumn1.Sparse = .F.
Stdcolumn1.Visible = .T.
Stdcolumn1.Name = "ColSelected"
Stdcolumn2.Comment = "7182D41F-E208-4C32-B60B-D946941B51FF"
Stdcolumn2.FontName = "Segoe UI"
Stdcolumn2.FontSize = 8
Stdcolumn2.ControlSource = "myLS.Cd_AR"
Stdcolumn2.Width = 115
Stdcolumn2.Name = "ColCd_AR"
Stdcolumn3.Comment = "3F29CFBF-B69D-427A-9A77-4D22D6D626EF"
Stdcolumn3.FontName = "Segoe UI"
Stdcolumn3.FontSize = 8
Stdcolumn3.ControlSource = "myLS.Descrizione"
Stdcolumn3.Width = 197
Stdcolumn3.DynamicFontBold = ( IIF(NVL(myLS.LsMod1,0)<>NVL(myLS.LsBase1,0), .T., .F.))
Stdcolumn3.Name = "ColAR_Descrizione"
Stdcolumn4.Comment = "06CA1313-60B7-42BC-9A06-EAF79F508AF0"
Stdcolumn4.FontName = "Segoe UI"
Stdcolumn4.FontSize = 8
Stdcolumn4.ColumnOrder = 5
Stdcolumn4.ControlSource = "myLS.LSBase1"
Stdcolumn4.Width = 80
Stdcolumn4.Name = "ColLSBase1"
Stdcolumn5.Comment = "20A4303F-E1A4-42D6-8481-DA5A1499ADEF"
Stdcolumn5.FontName = "Segoe UI"
Stdcolumn5.FontSize = 8
Stdcolumn5.ColumnOrder = 6
Stdcolumn5.ControlSource = "myLS.LSMod1"
Stdcolumn5.Width = 80
Stdcolumn5.DynamicFontBold = ( IIF(NVL(myLS.LsMod1,0)<>NVL(myLS.LsBase1,0), .T., .F.))
Stdcolumn5.Name = "ColLSMod1"
Stdcolumn6.FontName = "Segoe UI"
Stdcolumn6.FontSize = 8
Stdcolumn6.ColumnOrder = 7
Stdcolumn6.ControlSource = "myLS.LSBase2"
Stdcolumn6.Width = 80
Stdcolumn6.Name = "ColLSBase2"
Stdcolumn7.FontName = "Segoe UI"
Stdcolumn7.FontSize = 8
Stdcolumn7.ColumnOrder = 8
Stdcolumn7.ControlSource = "myLS.LSMod2"
Stdcolumn7.Width = 80
Stdcolumn7.Name = "ColLSMod2"
Stdcolumn8.FontName = "Segoe UI"
Stdcolumn8.FontSize = 8
Stdcolumn8.ColumnOrder = 9
Stdcolumn8.ControlSource = "myLS.LSBase3"
Stdcolumn8.Width = 80
Stdcolumn8.Name = "ColLSBase3"
Stdcolumn9.FontName = "Segoe UI"
Stdcolumn9.FontSize = 8
Stdcolumn9.ColumnOrder = 10
Stdcolumn9.ControlSource = "myLS.LSMod3"
Stdcolumn9.Width = 80
Stdcolumn9.Name = "ColLSMod3"
Stdcolumn10.FontName = "Segoe UI"
Stdcolumn10.FontSize = 8
Stdcolumn10.ColumnOrder = 4
Stdcolumn10.ControlSource = "myLS.Cd_ARMisura"
Stdcolumn10.Width = 47
Stdcolumn10.Name = "ColAR_UM"
Stdcolumn11.FontName = ""
Stdcolumn11.FontSize = 9
Stdcolumn11.ControlSource = "myLS.LSBase3"
Stdcolumn11.Name = "ColLSBase4"
Stdcolumn12.FontName = "Segoe UI"
Stdcolumn12.FontSize = 8
Stdcolumn12.ControlSource = "myLS.LSMod4"
Stdcolumn12.Name = "ColLSMod4"

*** METHODS ***
PROCEDURE Init
DODEFAULT()
THIS.SetAll('READONLY', .T.)
THIS.ColSelected.READONLY = .F.
THIS.SetAll('DynamicBackColor', 'THIS.DynamicBackColor()')
THIS.ColLSMod1.DynamicFontBold = "IIF(myLS.LsMod1<>myLS.LsBase1, .T., .F.)"
THIS.ColLSMod2.DynamicFontBold = "IIF(myLS.LsMod2<>myLS.LsBase2, .T., .F.)"
THIS.ColLSMod3.DynamicFontBold = "IIF(myLS.LsMod3<>myLS.LsBase3, .T., .F.)"
THIS.ColLSMod4.DynamicFontBold = "IIF(myLS.LsMod4<>myLS.LsBase4, .T., .F.)"
THIS.ColAR_Descrizione.DynamicFontBold = "IIF((ALLTRIM(myLS.Descrizione)<>ALLTRIM(myLS.DSBase_AR)), .T., .F.)"

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

*** CLASS / OBJECT: Text1 (BaseClass: textbox, Parent: cmd.PF.pgSelezione.GRID.ColAR_Descrizione) ***
*** PROPERTIES ***
Comment = "8C088A51-E71C-432E-9F21-AD1C0C396CA4"
FontSize = 8
Seconds = 2
BorderStyle = 0
Margin = 0
SelectOnEntry = .F.
TabIndex = 1
Name = "Text1"

*** METHODS ***
PROCEDURE LostFocus
DODEFAULT()

ENDPROC

*======================================================================

