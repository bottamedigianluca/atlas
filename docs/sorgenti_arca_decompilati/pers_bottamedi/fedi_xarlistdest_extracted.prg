*** Extracted Visual FoxPro Source Code from fedi_xarlistdest.vcx ***

*** CLASS / OBJECT: xARListDest (BaseClass: textbox, Parent: de) ***
*** PROPERTIES ***
Name = "xARListDest"

*** METHODS ***
PROCEDURE Init
Text To This.Stmt NoShow

	Select 
		xARListDest.*,
		AR.Descrizione As Ds_AR,
		CF.Descrizione As Ds_CF,
		CFDest.Descrizione As Ds_CFDest
		/*CIP*/
		
	From
		xARListDest
		Inner Join AR On AR.Cd_AR = xARListDest.Cd_AR
		Inner Join CF On CF.Cd_CF = xARListDest.Cd_CF
		Inner Join CFDest On CFDest.Cd_CF = xARListDest.Cd_CF AND CFDest.Cd_CFDest = xARListDest.Cd_CFDest
		/*TIP*/
		
	<WHERE>
	<ORDERBY>

EndText
DoDefault()


ENDPROC
PROCEDURE initcolsinfo
DoDefault()
**
This.aColsInfo('Ds_AR').RemoteFullName	= 'AR.Descrizione'
This.aColsInfo('Ds_CF').RemoteFullName	= 'CF.Descrizione'
This.aColsInfo('Ds_CFDest').RemoteFullName	= 'CFDest.Descrizione'

ENDPROC

*======================================================================

*** CLASS / OBJECT: fedi (BaseClass: form, Parent: ) ***
*** PROPERTIES ***
Top = 3
Left = 0
Height = 331
Width = 577
DoCreate = .T.
Caption = (oApp.AppName)
Name = "fedi"
statusbar.Top = 311
statusbar.Left = 0
statusbar.Height = 20
statusbar.Width = 577
statusbar.Name = "statusbar"
timer4ExecAsync.Name = "timer4ExecAsync"
title_bar.BtnLabel.Name = "BtnLabel"
title_bar.lblLabel.Name = "lblLabel"
title_bar.Top = 26
title_bar.Width = 568
title_bar.Name = "title_bar"
SCMenu.Name = "SCMenu"
tbenabler.Name = "tbenabler"
imgRecInfo.Height = 16
imgRecInfo.Width = 16
imgRecInfo.Name = "imgRecInfo"
PF.ErasePage = .T.
PF.PageCount = 2
PF.pgElenco.Name = "pgElenco"
PF.pgGenerale.Name = "pgGenerale"
PF.Top = 28
PF.Left = 0
PF.Width = 576
PF.Height = 284
PF.Name = "PF"

*** METHODS ***
PROCEDURE xalreadyexists
PARAMETERS myCd_CF, myCd_CFDest, myCd_AR
LOCAL cSql
LOCAL oRec
LOCAL RecExists

RecExists = .F.

IF !IsEmpty(myCd_CF) And !IsEmpty(myCd_CFDest) And !IsEmpty(myCd_AR) THEN 
	TEXT TO cSQL TEXTMERGE PRETEXT 7		
		SELECT COUNT(*) As Num FROM xARListDest
		WHERE Cd_CF = <<Format4SPT(myCd_CF)>>
		AND Cd_CFDest = <<Format4SPT(myCd_CFDest)>>
		AND Cd_AR = <<Format4SPT(myCd_AR)>>
	ENDTEXT
	oRec = xSQLExec2Obj(cSQL, .T.)
	IF VARTYPE(oRec) = 'O' THEN 
		IF oRec.Num > 0 THEN
			RecExists = .T.
		ENDIF
	ENDIF
ENDIF

RETURN RecExists
ENDPROC
PROCEDURE edit
Lparameters lInsert, oRecDup

DoDefault(lInsert, oRecDup)

This.PF.pgGenerale.txtCd_CF.Enabled 	= lInsert
This.PF.pgGenerale.txtCFDest.Enabled 	= lInsert
This.PF.pgGenerale.txtCd_AR.Enabled 	= lInsert
 
IF VARTYPE(oRecDup) = 'O' THEN

	REPLACE Cd_CF 		WITH oRecDup.Cd_CF 		IN xARListDest
	REPLACE Cd_CFDest 	WITH oRecDup.Cd_CFDest 	IN xARListDest
	REPLACE Cd_AR 		WITH oRecDup.Cd_AR 		IN xARListDest

	This.PF.pgGenerale.txtCFDest.Field.FKSelect = Textmerge("Select * From CFDest Where CFDest.Cd_CF = '<<xARListDest.Cd_CF>>' And CFDest.Cd_CFDest = <TEXT>")

	This.PF.pgGenerale.txtCd_CF.Refresh()
	This.PF.pgGenerale.txtCFDest.Refresh()
	This.PF.pgGenerale.txtCd_AR.Refresh()
 
ENDIF



ENDPROC
PROCEDURE querysave
LPARAMETERS lInsertMode
LOCAL lAccept

lAccept = .T.

IF !DODEFAULT(lInsertMode)
	lAccept = .F.
ENDIF

IF lAccept THEN 
	&& Cliente
	WITH THISFORM.PF.pgGenerale			
		IF IsEmpty(xARListDest.Cd_CF)
				xMessageBox("Il codice cliente è obbligatorio.", 16       + 0       )
				IF .txtCd_CF.Enabled THEN 
					.txtCd_CF.Field.SetFocus()
				ENDIF
			lAccept = .F.
		ENDIF	
	ENDWITH	

	IF lAccept THEN 
		&& Sede operativa, Destinazione merce
		WITH THISFORM.PF.pgGenerale			
			IF IsEmpty(xARListDest.Cd_CFDest)
					xMessageBox("Il codice delle sede operativa (destinazione merce) è obbligatoria.", 16       + 0       )
					IF .txtCFDest.Enabled THEN 
						.txtCFDest.Field.SetFocus()
					ENDIF
				lAccept = .F.
			ENDIF	
		ENDWITH		
	ENDIF

	IF lAccept THEN 
		&& Articolo
		WITH THISFORM.PF.pgGenerale			
			IF IsEmpty(xARListDest.Cd_AR)
					xMessageBox("Il codice articolo è obbligatorio.", 16       + 0       )
					IF .txtCd_AR.Enabled THEN 
						.txtCd_AR.Field.SetFocus()
					ENDIF
				lAccept = .F.
			ENDIF	
		ENDWITH		
	ENDIF

	IF lAccept THEN 
		&& Combinazione Cliente/Destinazione/Articolo già presente ?
		IF This.xalreadyexists(xARListDest.Cd_CF, xARListDest.Cd_CFDest, xARListDest.Cd_AR) THEN
			xMessageBox("Listino già inserito.", 16       + 0       )
			lAccept = .F.
		ENDIF	
	ENDIF

ENDIF

RETURN lAccept

ENDPROC
PROCEDURE onrecordchange
This.PF.pgGenerale.txtCFDest.Field.FKSelect = Textmerge("Select * From CFDest Where CFDest.Cd_CF = '<<xARListDest.Cd_CF>>' And CFDest.Cd_CFDest = <TEXT>")
ENDPROC

*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: fedi.PF.pgGenerale.txtCd_CF) ***
*** PROPERTIES ***
ControlSource = "xARListDest.Cd_CF"
Left = 1
TabIndex = 1
Top = 14
fkhasdisplay = .T.
required = .T.
Name = "Field"

*** METHODS ***
PROCEDURE LostFocus

DoDefault()

*!*	** se sono in inserimento,           					 ho selezionato un Cd_CF valido,			non c'è alcuna tipologia selezionata
*!*	If Bitand(FEDIMODE_INS_DUP, Thisform.Mode) > 0 And !IsEmpty(This.FKRecord.Descrizione) And IsEmpty(CFContatto.Id_CFContattoTipo)
*!*		
*!*		This.Parent.Parent.txtCFContattoTipo.link.Click()
*!*		Do While IsEmpty(CFContatto.Id_CFContattoTipo)
*!*			xMessageBox('È necessario selezionare una Tipologia Contatto!')	
*!*			This.Parent.Parent.txtCFContattoTipo.link.Click()
*!*		EndDo
*!*		
*!*		** a questo punto posso rendere visibile il link (lo avevo reso invisibile nel onmodechange)
*!*		This.Parent.Parent.txtCFContattoTipo.link.Visible = .T.
*!*		This.Parent.Parent.txtCFContattoTipo.link.Enabled = .T.
*!*	EndIf 

This.Parent.Parent.txtCFDest.Field.FKSelect = Textmerge("Select * From CFDest Where CFDest.Cd_CF = '<<This.Value>>' And CFDest.Cd_CFDest = <TEXT>")
ENDPROC
PROCEDURE readonly_assign
LParameters lReadOnly

If !lReadOnly And IsEmpty(This.Value)
	This.SetValue('')
EndIf
Return DoDefault(lReadOnly)


ENDPROC

*======================================================================

*** CLASS / OBJECT: Field (BaseClass: textbox, Parent: fedi.PF.pgGenerale.txtCFDest) ***
*** PROPERTIES ***
ControlSource = "xARListDest.Cd_CFDest"
Format = "!"
Left = 1
Top = 14
Width = 35
fkselect = SELECT * FROM CFDest WHERE CFDest.Cd_CFDest = <TEXT> AND CFDest.Cd_CF = 'X'
fktabledesc = Destinazioni
fkhasdisplay = .T.
builder = Development\ArcaBuilder.prg
fkdecodedfield = Descrizione
Name = "Field"

*** METHODS ***
PROCEDURE Init
If !DoDefault()
	Return .F.
EndIf

This.AddProperty('AnagraficheObsolete', 0)
ENDPROC
PROCEDURE fkselect_access
Local cWhere
cWhere = ''
If (This.AnagraficheObsolete != 2)
	cWhere = ' And CFDest.Obsoleto = ' + Transform(This.AnagraficheObsolete)
EndIf

Return This.FKSelect + cWhere

ENDPROC
PROCEDURE contextmenuproc
Lparameters nCBMId, xPar1, xPar2

Do Case

	Case nCBMId == CMM_ADD_ITEMS_TO_CONTEXT_MENU

		Local oMenu
		
		DoDefault(nCBMId, xPar1)		
		
		oMenu = xPar1
		If This.Enabled And !This.ReadOnly And !Empty(This.FKSelect)
			**	Anagrafiche Obsolete / Normali
			oMenu.AddMenuBar('\-',,,MB_EDIT_SEP_SEARCH2)		
			oMenu.AddMenuBar(TM_(,"C2B7ED92-487B-458F-8B1A-7C4F1CA8FF99", "Includi \<Obsoleti"),, 'Key Alt+0, ""',	MB_EDIT_SRCHSPEC0, This.AnagraficheObsolete == 2)
		EndIf

		Return .T.

	Case nCBMId == CMM_ADD_ITEMS_TO_EDIT_PAD
		
		Local cPopupName, cOnSelCmd
		
		DoDefault(nCBMId, xPar1) 	
		
		cPopupName = xPar1
		If This.Enabled And !This.ReadOnly And !Empty(This.FKSelect)
		
			cOnSelCmd =  Sys(1272, This) + '.ContextMenuProc(' + Transform(CMM_PROCESS_CHOICE) + ', Bar())'
						
			**	Anagrafiche Obsolete / Normali
			Define Bar          (MB_EDIT_SEP_SEARCH2) Of (cPopupName) Prompt "\-"
			
			Define Bar          (MB_EDIT_SRCHSPEC0 ) Of (cPopupName) Prompt TM_(,"C2B7ED92-487B-458F-8B1A-7C4F1CA8FF99", "Includi \<Obsoleti") Key Alt+0, ""
			Set Mark Of Bar     (MB_EDIT_SRCHSPEC0 ) Of (cPopupName) To This.AnagraficheObsolete == 2
			On Selection Bar    (MB_EDIT_SRCHSPEC0 ) Of (cPopupName) &cOnSelCmd
			
		EndIf
		
		Return .T.
		
	Case nCBMId == CMM_PROCESS_CHOICE

		Local nChoiceId

		nChoiceId  = xPar1
		
		Do Case	
			Case nChoiceId == MB_EDIT_SRCHSPEC0	&& Toggle Filtro per Anagrafiche Obsolete
				If This.Enabled And !This.ReadOnly And !Empty(This.FKSelect)
					This.AnagraficheObsolete  = Iif(This.AnagraficheObsolete == 0, 2, 0)
					This.FKLastValidatedValue = .F.
				EndIf 
				Return .T.

			Otherwise
				Return DoDefault(nCBMId, nChoiceId)
		
		EndCase

EndCase
ENDPROC
PROCEDURE isvalid
LParameters lIsChanged, xOldValue

If !DoDefault(lIsChanged, xOldValue)
	Return .F.
EndIf 
 
*!*	If !IsEmpty(This.Value) And CFContatto.Id_CFContattoTipo = -5
*!*		** Controllo che non esista già un contatto "Destinazione Diversa" per questa S.O.
*!*		Local lExist
*!*		lExist = xSqlExec2Var('If Exists(Select * From CFContatto Where Id_CFContattoTipo = -5 And Cd_CF = ' + FormatC4Spt(CFContatto.Cd_CF) + ' And Cd_CFDest = ' + FormatC4Spt(This.Value) + ') Select 1 Else Select 0')
*!*		If !IsEmpty(lExist)
*!*			xMessageBox('Esiste già un contatto "Destinazione Diversa" per la Sede Operativa [' + This.Value + ']', 16)
*!*			Return .F.
*!*		EndIf 
*!*	EndIf 




ENDPROC

*======================================================================

*** CLASS / OBJECT: elenco (BaseClass: container, Parent: ) ***
*** PROPERTIES ***
Name = "elenco"
Grid.ColumnCount = 6
Grid.Colbase1.FontSize = 8
Grid.Colbase1.ControlSource = "xARListDest.Cd_CF"
Grid.Colbase1.Width = 70
Grid.Colbase1.ReadOnly = .F.
Grid.Colbase1.Name = "ColCd_CF"
Grid.Colbase2.FontSize = 8
Grid.Colbase2.ControlSource = "xARListDest.Cd_CFDest"
Grid.Colbase2.Width = 30
Grid.Colbase2.ReadOnly = .F.
Grid.Colbase2.Name = "ColCd_CFDest"
Grid.Colbase3.FontSize = 8
Grid.Colbase3.ControlSource = "xARListDest.Cd_AR"
Grid.Colbase3.Width = 200
Grid.Colbase3.ReadOnly = .F.
Grid.Colbase3.Name = "ColCd_AR"
Grid.Colbase4.FontSize = 8
Grid.Colbase4.ControlSource = "xARListDest.Prezzo"
Grid.Colbase4.Width = 200
Grid.Colbase4.ReadOnly = .F.
Grid.Colbase4.InputMask = "###,###.##"
Grid.Colbase4.Name = "ColPrezzo"
Grid.Colbase5.FontSize = 8
Grid.Colbase5.ControlSource = "xARListDest.Sconto"
Grid.Colbase5.Width = 200
Grid.Colbase5.ReadOnly = .F.
Grid.Colbase5.Name = "ColSconto"
Grid.Colbase6.FontSize = 8
Grid.Colbase6.ControlSource = "xARListDest.Descrizione"
Grid.Colbase6.Width = 800
Grid.Colbase6.ReadOnly = .F.
Grid.Colbase6.Visible = .F.
Grid.Colbase6.Name = "ColDescrizione"
Grid.ReadOnly = .F.
Grid.RecordSource = "xARListDest"
Grid.Name = "Grid"

*** METHODS ***
PROCEDURE Grid.Init
Local oCol1, oCol2, oCol3
	
	** Grid.Init
	** Campo Descrizione cliente
	oCol1 = This.newColumn('xColDsCF', 'xARListDest.Ds_CF', 'Descrizione cliente', 100)
	oCol1.enabled = .F.
	oCol1.ReadOnly = .T.
	
	** Campo Descrizione destinatario/sede operativa
	oCol2 = This.newColumn('xColDsCFDest', 'xARListDest.Ds_CFDest', 'Descrizione sede operativa', 100)
	oCol2.enabled = .F.
	oCol2.ReadOnly = .T.
	
	** Campo Descrizione articolo
	oCol3 = This.newColumn('xColDsAR', 'xARListDest.Ds_AR', 'Descrizione articolo', 100)
	oCol3.enabled = .F.
	oCol3.ReadOnly = .T.

DODEFAULT()
ENDPROC

*======================================================================

